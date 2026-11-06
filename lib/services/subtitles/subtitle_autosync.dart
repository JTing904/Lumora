import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import '../player/engine/audio_level.dart';
import 'subtitle_parser.dart';

/// Where the film is audibly speech, on a 0.1 s grid.
///
/// What the speech mask hands to [SubtitleAutoSync]: one flag per bin for
/// "someone is talking", one for "the player actually heard this bin". The
/// second matters because the viewer skips around: a bin that was never
/// played says nothing about the subtitle, so it must not count as silence.
class SpeechMask {
  SpeechMask._(this.firstBin, this.speech, this.observed)
    : observedBins = _count(observed),
      speechBins = _count(speech);

  /// The bin [speech] and [observed] start at (bin n covers n * 0.1 s).
  final int firstBin;

  /// 1 where the bin is observed and speech.
  final Uint8List speech;

  /// 1 where the bin was heard at all.
  final Uint8List observed;

  final int observedBins;
  final int speechBins;

  int get length => speech.length;
  double get observedSec => observedBins * audioLevelStepSec;

  /// The time span between the first and last observed bin.
  double get firstSec => firstBin * audioLevelStepSec;
  double get lastSec => (firstBin + length) * audioLevelStepSec;

  /// A reference subtitle as a speech mask: bins inside a line are speech,
  /// and the bins from the first line to the last count as heard, except
  /// across a gap of more than [maxHeardGapSec] between two lines. That is
  /// where a reference gathered while watching had a seek in it, or where
  /// nothing was said for long enough that it says little either way.
  static SpeechMask? fromCues(List<SubCue> cues) {
    final valid = [
      for (final c in cues)
        if (c.start.isFinite &&
            c.end.isFinite &&
            c.end > c.start &&
            c.start >= 0)
          c,
    ]..sort((a, b) => a.start.compareTo(b.start));
    if (valid.isEmpty) return null;
    final lo = _bin(valid.first.start);
    var hi = 0;
    for (final c in valid) {
      hi = math.max(hi, _bin(c.end) + 1);
    }
    if (hi - lo > SubtitleAutoSync.maxGridBins) return null;
    final speech = Uint8List(hi - lo);
    final heard = Uint8List(hi - lo);
    final maxGap = (maxHeardGapSec / audioLevelStepSec).round();
    var heardUpTo = lo;
    for (final c in valid) {
      final a = _bin(c.start);
      final b = math.max(_bin(c.end), a + 1);
      if (a - heardUpTo <= maxGap) {
        for (var i = math.max(heardUpTo, lo); i < a; i++) {
          heard[i - lo] = 1;
        }
      }
      for (var i = a; i < b && i - lo < speech.length; i++) {
        speech[i - lo] = 1;
        heard[i - lo] = 1;
      }
      heardUpTo = math.max(heardUpTo, b);
    }
    return SpeechMask._(lo, speech, heard);
  }

  /// The longest silence in a reference subtitle still taken as heard.
  static const double maxHeardGapSec = 20;

  static int _count(Uint8List v) {
    var n = 0;
    for (final b in v) {
      n += b;
    }
    return n;
  }
}

int _bin(double sec) => (sec / audioLevelStepSec).round();

/// Collects the audio levels the player reports and turns them into a
/// [SpeechMask].
///
/// Samples carry media time, so they may arrive out of order, repeat after
/// a seek back, or skip stretches. Only the newest [maxObservedBins] bins
/// are kept (20 minutes by default), so a long film cannot grow it without
/// bound; the ones dropped are the longest ago heard, not the earliest in
/// the film.
class SpeechTimeline {
  SpeechTimeline({this.maxObservedBins = 12000});

  final int maxObservedBins;

  /// Bin -> loudest level reported for it. Insertion order is recency:
  /// a bin heard again moves to the back.
  final LinkedHashMap<int, double> _levels = LinkedHashMap<int, double>();

  /// The quietest level that can still be speech, whatever the film's own
  /// quiet is: below this it is room tone or digital silence.
  static const double _absoluteFloorDb = -65;

  /// Bins per block the adaptive threshold is worked out over (30 s).
  static const int _blockBins = 300;

  /// A block needs this many heard bins to have a threshold of its own.
  static const int _blockMinBins = 100;

  int get observedBins => _levels.length;
  double get observedSec => _levels.length * audioLevelStepSec;
  bool get isEmpty => _levels.isEmpty;

  void clear() => _levels.clear();

  void add(AudioLevelSample sample) {
    final t = sample.timeSec;
    final db = sample.rmsDb;
    if (!t.isFinite || t < 0 || t > 86400 || db.isNaN) return;
    final bin = _bin(t);
    // Digital silence reports as -infinity; keep it a number.
    final level = db.clamp(-120.0, 0.0);
    final before = _levels.remove(bin);
    _levels[bin] = before == null ? level : math.max(before, level);
    if (_levels.length > maxObservedBins) {
      _levels.remove(_levels.keys.first);
    }
  }

  /// A timeline of only the [bins] heard most recently: what the sound is
  /// like now, for noticing that the timing changed partway through.
  SpeechTimeline newest(int bins) {
    final out = SpeechTimeline(maxObservedBins: maxObservedBins);
    final skip = math.max(0, _levels.length - bins);
    var i = 0;
    _levels.forEach((bin, db) {
      if (i++ >= skip) out._levels[bin] = db;
    });
    return out;
  }

  void addAll(Iterable<AudioLevelSample> samples) {
    for (final s in samples) {
      add(s);
    }
  }

  /// The speech mask over everything kept, or null when nothing was heard.
  ///
  /// Speech is "clearly above the film's own quiet": each 30 s block gets a
  /// noise floor (the 15th percentile of its levels) and a loud level (the
  /// 90th), and a bin counts when it is above the floor by 40% of that
  /// spread and at least 4 dB. A block whose spread is under 6 dB is flat
  /// (steady music or hiss) and holds no speech. Speech that is on and off
  /// quicker than 0.2 s is smoothed: blips drop out, gaps of 0.2 s fill.
  SpeechMask? mask() {
    if (_levels.isEmpty) return null;
    var lo = 1 << 30;
    var hi = -1;
    for (final b in _levels.keys) {
      if (b < lo) lo = b;
      if (b > hi) hi = b;
    }
    final len = hi - lo + 1;
    final level = Float64List(len)..fillRange(0, len, double.nan);
    final observed = Uint8List(len);
    final blocks = <int, List<double>>{};
    final all = <double>[];
    _levels.forEach((bin, db) {
      level[bin - lo] = db;
      observed[bin - lo] = 1;
      blocks.putIfAbsent(bin ~/ _blockBins, () => <double>[]).add(db);
      all.add(db);
    });

    final global = _Spread.of(all);
    final spreads = <int, _Spread>{
      for (final e in blocks.entries)
        e.key: e.value.length >= _blockMinBins ? _Spread.of(e.value) : global,
    };

    final speech = Uint8List(len);
    for (var i = 0; i < len; i++) {
      if (observed[i] == 0) continue;
      final db = level[i];
      if (db < _absoluteFloorDb) continue;
      final s = spreads[(i + lo) ~/ _blockBins]!;
      if (s.spread < 6) continue;
      final threshold = s.floor + math.max(4.0, 0.4 * s.spread);
      if (db > threshold) speech[i] = 1;
    }
    _smooth(speech, observed);
    return SpeechMask._(lo, speech, observed);
  }

  /// Fills gaps of up to 2 bins between speech and drops runs of 1 bin,
  /// never marking an unheard bin.
  static void _smooth(Uint8List speech, Uint8List observed) {
    final n = speech.length;
    var i = 0;
    while (i < n) {
      if (speech[i] == 1) {
        i++;
        continue;
      }
      var j = i;
      while (j < n && speech[j] == 0) {
        j++;
      }
      final gap = j - i;
      var heard = true;
      for (var k = i; k < j; k++) {
        if (observed[k] == 0) {
          heard = false;
          break;
        }
      }
      if (heard && gap <= 2 && i > 0 && j < n) {
        for (var k = i; k < j; k++) {
          speech[k] = 1;
        }
      }
      i = j;
    }
    i = 0;
    while (i < n) {
      if (speech[i] == 0) {
        i++;
        continue;
      }
      var j = i;
      while (j < n && speech[j] == 1) {
        j++;
      }
      if (j - i < 2) {
        for (var k = i; k < j; k++) {
          speech[k] = 0;
        }
      }
      i = j;
    }
  }
}

class _Spread {
  _Spread(this.floor, this.peak);

  final double floor;
  final double peak;
  double get spread => peak - floor;

  static _Spread of(List<double> values) {
    final sorted = List<double>.of(values)..sort();
    double at(double q) =>
        sorted[((sorted.length - 1) * q).round().clamp(0, sorted.length - 1)];
    return _Spread(at(0.15), at(0.90));
  }
}

/// What the search found: the subtitle is best shown at
/// `cue * ratio + offsetSec`.
class SyncEstimate {
  const SyncEstimate({
    required this.offsetSec,
    required this.ratio,
    required this.score,
    required this.confidence,
    required this.observedSec,
  });

  /// The delay to give the subtitle, in the viewer's convention: positive
  /// shows lines later. It is the whole delay, not a change to the one in
  /// use now.
  final double offsetSec;

  /// How much the subtitle's clock has to be stretched (1 = not at all);
  /// 25/23.976 is a subtitle cut for 25 fps on a 23.976 fps film.
  final double ratio;

  /// The correlation of the speech with the lines at the best fit, -1 to 1.
  final double score;

  /// 0 to 1: how far the best fit stands out from every other.
  final double confidence;

  /// How much of the film was heard (or, against a reference subtitle, how
  /// long that subtitle runs).
  final double observedSec;

  /// Sure enough to change the timing without asking.
  bool get isConfident => confidence >= SubtitleAutoSync.confidentAt;

  /// Sure enough to overrule timing the viewer set by hand.
  bool get isVeryConfident => confidence >= SubtitleAutoSync.veryConfidentAt;

  bool get hasRatio => (ratio - 1).abs() > 1e-6;

  @override
  String toString() =>
      'SyncEstimate(offset: ${offsetSec.toStringAsFixed(2)}s, '
      'ratio: ${ratio.toStringAsFixed(5)}, score: ${score.toStringAsFixed(3)}, '
      'confidence: ${confidence.toStringAsFixed(2)}, '
      'observed: ${observedSec.toStringAsFixed(0)}s)';
}

/// Finds how a subtitle has to be shifted to fit the film (the ffsubsync
/// idea): lay the times someone speaks beside the times the subtitle shows
/// a line, and slide one over the other until they overlap most.
abstract final class SubtitleAutoSync {
  /// How far either way the delay is searched, in seconds.
  static const double searchRangeSec = 90;

  /// The shortest stretch heard before an answer is given.
  static const double minObservedSec = 120;

  /// Lines that must fall in the heard stretch.
  static const int minCues = 20;

  /// Where an answer is trusted to change the timing, and to overrule the
  /// viewer's own.
  static const double confidentAt = 0.6;
  static const double veryConfidentAt = 0.85;

  /// Peaks closer than this to the best one are the same peak.
  static const double peakWidthSec = 1.5;

  /// The grid is capped so a stray timestamp cannot ask for gigabytes.
  static const int maxGridBins = 1 << 21;

  /// A subtitle cut for another frame rate, as a multiple of its times:
  /// the usual NTSC/PAL/film pairs, both ways round.
  static const double _ntsc = 23.976;
  static final List<double> ratios = [
    1.0,
    25 / _ntsc,
    _ntsc / 25,
    24 / _ntsc,
    _ntsc / 24,
    25 / 24,
    24 / 25,
  ];

  /// How the subtitle should be timed from what was heard of the film, or
  /// null when there is not enough to tell yet.
  ///
  /// [currentDelaySec] is where the search is centred, so an answer is found
  /// even when the viewer already moved the timing far.
  static SyncEstimate? estimate(
    List<SubCue> cues,
    SpeechTimeline timeline, {
    double currentDelaySec = 0,
  }) {
    final mask = timeline.mask();
    if (mask == null) return null;
    return _search(cues, mask, currentDelaySec);
  }

  /// The same answer from a subtitle known to be in time with the film,
  /// for when the stream came with its own: no listening needed.
  static SyncEstimate? alignToReference(
    List<SubCue> cues,
    List<SubCue> referenceCues, {
    double currentDelaySec = 0,
  }) {
    if (referenceCues.length < minCues) return null;
    final mask = SpeechMask.fromCues(referenceCues);
    if (mask == null) return null;
    return _search(cues, mask, currentDelaySec);
  }

  static SyncEstimate? _search(
    List<SubCue> cues,
    SpeechMask mask,
    double centerSec,
  ) {
    if (cues.length < minCues) return null;
    if (mask.observedSec < minObservedSec) return null;
    final n = mask.observedBins;
    final sx = mask.speechBins;
    // All speech or none: nothing to tell one offset from another.
    if (sx < 100 || sx > n - 100) return null;

    final len = mask.length;
    final base = mask.firstBin;
    final pObs = Int32List(len + 1);
    final pSpeech = Int32List(len + 1);
    for (var i = 0; i < len; i++) {
      pObs[i + 1] = pObs[i] + mask.observed[i];
      pSpeech[i + 1] = pSpeech[i] + mask.speech[i];
    }

    final center = _bin(centerSec.clamp(-3600.0, 3600.0));
    final range = (searchRangeSec / audioLevelStepSec).round();
    final kMin = center - range;
    final kMax = center + range;
    final kCount = kMax - kMin + 1;
    final denomX = n * sx - sx * sx;

    _Fit? baseFit;
    _Fit? bestOther;
    for (final r in ratios) {
      final iv = _intervals(cues, r, base - kMax, base + len - kMin);
      if (iv.isEmpty) continue;
      final scores = Float64List(kCount);
      for (var ki = 0; ki < kCount; ki++) {
        final k = kMin + ki;
        var sy = 0;
        var sxy = 0;
        for (var j = 0; j < iv.length; j += 2) {
          final a = math.max(iv[j] + k - base, 0);
          final b = math.min(iv[j + 1] + k - base, len);
          if (b <= a) continue;
          sy += pObs[b] - pObs[a];
          sxy += pSpeech[b] - pSpeech[a];
        }
        final denomY = n * sy - sy * sy;
        if (denomY <= 0) continue;
        scores[ki] = (n * sxy - sx * sy) / math.sqrt(denomX * denomY);
      }
      var bi = 0;
      for (var ki = 1; ki < kCount; ki++) {
        if (scores[ki] > scores[bi]) bi = ki;
      }
      final fit = _Fit(r, scores, bi);
      if (r == 1.0) {
        baseFit = fit;
      } else if (bestOther == null || fit.best > bestOther.best) {
        bestOther = fit;
      }
    }
    if (baseFit == null) return null;

    // A stretched clock only wins when it is clearly better: over a short
    // listen an offset and a stretch explain the same thing, and the plain
    // one is the likelier.
    var chosen = baseFit;
    if (bestOther != null &&
        bestOther.best >= baseFit.best * 1.15 &&
        bestOther.best - baseFit.best >= 0.04) {
      chosen = bestOther;
    }
    final best = chosen.best;

    // Lines that really fall in the heard stretch at this fit.
    final k = kMin + chosen.index;
    var inHeard = 0;
    for (final c in cues) {
      final a = _bin(c.start * chosen.ratio) + k - base;
      final b =
          math.max(
            _bin(c.end * chosen.ratio),
            _bin(c.start * chosen.ratio) + 1,
          ) +
          k -
          base;
      final lo = a.clamp(0, len);
      final hi = b.clamp(0, len);
      if (hi > lo && pObs[hi] - pObs[lo] > 0) inHeard++;
    }
    if (inHeard < minCues) return null;

    final peakBins = (peakWidthSec / audioLevelStepSec).round();
    var runnerUp = 0.0;
    var sum = 0.0;
    for (var i = 0; i < kCount; i++) {
      final s = chosen.scores[i];
      sum += s;
      if ((i - chosen.index).abs() > peakBins && s > runnerUp) runnerUp = s;
    }
    final mean = sum / kCount;
    var varSum = 0.0;
    for (var i = 0; i < kCount; i++) {
      final d = chosen.scores[i] - mean;
      varSum += d * d;
    }
    final std = math.sqrt(varSum / kCount);
    final z = std > 1e-9 ? (best - mean) / std : 0.0;

    // Two things have to hold: the best fit leads the runner-up by a clear
    // share of itself, and it stands several deviations above the typical
    // fit. Enough listening raises it a little; it never carries it alone.
    final margin = ((best - runnerUp) / best).clamp(0.0, 1.0);
    final marginTerm = (margin / 0.4).clamp(0.0, 1.0);
    final zTerm = ((z - 4) / 2.5).clamp(0.0, 1.0);
    final evidence =
        0.9 + 0.1 * ((mask.observedSec - minObservedSec) / 480).clamp(0.0, 1.0);
    // A fit that barely correlates is no answer, however it compares.
    final confidence = best < 0.08 ? 0.0 : marginTerm * zTerm * evidence;

    return SyncEstimate(
      offsetSec: k * audioLevelStepSec,
      ratio: chosen.ratio,
      score: best,
      confidence: confidence,
      observedSec: mask.observedSec,
    );
  }

  /// The lines' bin intervals `[a, b)` at [ratio], merged where they touch,
  /// flattened to `a0, b0, a1, b1, ...`. Only those that can land inside
  /// `[from, to)` for some offset in the search are kept.
  static Int32List _intervals(
    List<SubCue> cues,
    double ratio,
    int from,
    int to,
  ) {
    final spans = <List<int>>[];
    for (final c in cues) {
      if (!c.start.isFinite || !c.end.isFinite) continue;
      final a = _bin(c.start * ratio);
      final b = math.max(_bin(c.end * ratio), a + 1);
      if (b <= from || a >= to) continue;
      spans.add([a, b]);
    }
    spans.sort((x, y) => x[0].compareTo(y[0]));
    final out = <int>[];
    for (final s in spans) {
      if (out.isNotEmpty && s[0] <= out[out.length - 1]) {
        if (s[1] > out[out.length - 1]) out[out.length - 1] = s[1];
      } else {
        out
          ..add(s[0])
          ..add(s[1]);
      }
    }
    return Int32List.fromList(out);
  }
}

class _Fit {
  _Fit(this.ratio, this.scores, this.index);

  final double ratio;
  final Float64List scores;
  final int index;
  double get best => scores[index];
}
