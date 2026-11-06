import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/player/engine/audio_level.dart';
import 'package:zplay/services/subtitles/subtitle_autosync.dart';
import 'package:zplay/services/subtitles/subtitle_parser.dart';

/// A film's dialogue: lines of 1.5-4 s with 1-6 s between.
List<SubCue> _cues(Random rnd, {double length = 900}) {
  final out = <SubCue>[];
  var t = 5.0;
  var i = 0;
  while (t < length) {
    final dur = 1.5 + rnd.nextDouble() * 2.5;
    out.add(SubCue(start: t, end: t + dur, text: 'line ${i++}'));
    t += dur + 1 + rnd.nextDouble() * 5;
  }
  return out;
}

/// What the player would report: speech where the lines are once timed by
/// `time * ratio + offset`, quiet elsewhere, noisy either way, with some
/// speech that has no line.
List<AudioLevelSample> _audio(
  List<SubCue> cues, {
  required double offset,
  double ratio = 1,
  required double from,
  required double to,
  required Random rnd,
  bool music = false,
}) {
  final speech = <int>{};
  for (final c in cues) {
    final a = ((c.start * ratio + offset) / 0.1).round();
    final b = ((c.end * ratio + offset) / 0.1).round();
    for (var i = a; i < b; i++) {
      speech.add(i);
    }
  }
  final extra = <int>{};
  for (var t = from; t < to; t += 8) {
    if (rnd.nextDouble() < 0.3) {
      final at = ((t + rnd.nextDouble() * 6) / 0.1).round();
      for (var b = 0; b < 15; b++) {
        extra.add(at + b);
      }
    }
  }
  final out = <AudioLevelSample>[];
  for (var b = (from / 0.1).round(); b < (to / 0.1).round(); b++) {
    final talking = speech.contains(b) || extra.contains(b);
    var db = talking ? -28 + rnd.nextDouble() * 8 : -62 + rnd.nextDouble() * 6;
    if (music && (b ~/ 350).isEven) {
      // A score under everything: as loud as speech in long stretches.
      db = max(db, -30 + rnd.nextDouble() * 6);
    }
    out.add(AudioLevelSample(b * 0.1, db));
  }
  return out;
}

void main() {
  group('SpeechTimeline', () {
    test('has nothing to say before anything was heard', () {
      expect(SpeechTimeline().mask(), isNull);
    });

    test('marks only the bins it heard and finds the speech in them', () {
      final tl = SpeechTimeline();
      // 60 s: loud for 2 s, quiet for 2 s, repeating; then a hole; then more.
      for (var b = 0; b < 600; b++) {
        tl.add(AudioLevelSample(b * 0.1, (b ~/ 20).isEven ? -25 : -60));
      }
      for (var b = 3000; b < 3200; b++) {
        tl.add(AudioLevelSample(b * 0.1, -60));
      }
      final m = tl.mask()!;
      expect(m.firstBin, 0);
      expect(m.observedBins, 800);
      // Nothing was heard between 60 s and 300 s: not speech, not silence.
      expect(m.observed[1000], 0);
      expect(m.speech[1000], 0);
      expect(m.speech[5], 1);
      expect(m.speech[30], 0);
      expect(m.speechBins, closeTo(300, 10));
    });

    test('takes samples out of order and after a seek back', () {
      final tl = SpeechTimeline();
      final samples = [
        for (var b = 0; b < 400; b++)
          AudioLevelSample(b * 0.1, (b ~/ 20).isEven ? -25 : -60),
      ]..shuffle(Random(3));
      tl.addAll(samples);
      // The same stretch again after seeking back changes nothing.
      tl.addAll(samples.take(100));
      final m = tl.mask()!;
      expect(m.observedBins, 400);
      expect(m.speechBins, closeTo(200, 10));
    });

    test('newest keeps only the most recently heard bins', () {
      final tl = SpeechTimeline();
      for (var b = 0; b < 1000; b++) {
        tl.add(AudioLevelSample(b * 0.1, -50));
      }
      final recent = tl.newest(300);
      expect(recent.observedBins, 300);
      expect(recent.mask()!.firstBin, 700);
      expect(tl.observedBins, 1000);
    });

    test('drops the longest ago heard beyond its bound', () {
      final tl = SpeechTimeline(maxObservedBins: 1000);
      for (var b = 0; b < 3000; b++) {
        tl.add(AudioLevelSample(b * 0.1, -50));
      }
      expect(tl.observedBins, 1000);
      expect(tl.mask()!.firstBin, 2000);
    });

    test('ignores nonsense and treats digital silence as a number', () {
      final tl = SpeechTimeline();
      tl.add(const AudioLevelSample(double.nan, -20));
      tl.add(const AudioLevelSample(-1, -20));
      tl.add(const AudioLevelSample(1, double.nan));
      tl.add(const AudioLevelSample(1, double.negativeInfinity));
      expect(tl.observedBins, 1);
    });

    test('flat sound has no speech in it', () {
      final tl = SpeechTimeline();
      final rnd = Random(1);
      for (var b = 0; b < 1200; b++) {
        tl.add(AudioLevelSample(b * 0.1, -30 + rnd.nextDouble() * 2));
      }
      expect(tl.mask()!.speechBins, 0);
    });
  });

  group('SubtitleAutoSync.estimate', () {
    test('finds a subtitle 2.3 s early (delay +2.3)', () {
      final rnd = Random(7);
      final cues = _cues(rnd);
      final tl = SpeechTimeline()
        ..addAll(_audio(cues, offset: 2.3, from: 100, to: 400, rnd: rnd));
      final e = SubtitleAutoSync.estimate(cues, tl)!;
      expect(e.offsetSec, closeTo(2.3, 0.15));
      expect(e.ratio, 1.0);
      expect(e.isVeryConfident, isTrue, reason: '$e');
    });

    test('finds a subtitle that is late (delay -4.7)', () {
      final rnd = Random(8);
      final cues = _cues(rnd);
      final tl = SpeechTimeline()
        ..addAll(_audio(cues, offset: -4.7, from: 300, to: 560, rnd: rnd));
      final e = SubtitleAutoSync.estimate(cues, tl)!;
      expect(e.offsetSec, closeTo(-4.7, 0.15));
      expect(e.isConfident, isTrue, reason: '$e');
    });

    test('an in-time subtitle comes out near zero', () {
      final rnd = Random(9);
      final cues = _cues(rnd);
      final tl = SpeechTimeline()
        ..addAll(_audio(cues, offset: 0, from: 0, to: 300, rnd: rnd));
      final e = SubtitleAutoSync.estimate(cues, tl)!;
      expect(e.offsetSec.abs(), lessThan(0.2));
      expect(e.isConfident, isTrue, reason: '$e');
    });

    test('finds it with heard stretches either side of a seek', () {
      final rnd = Random(10);
      final cues = _cues(rnd);
      final tl = SpeechTimeline()
        ..addAll(_audio(cues, offset: 1.1, from: 50, to: 130, rnd: rnd))
        ..addAll(_audio(cues, offset: 1.1, from: 500, to: 620, rnd: rnd));
      final e = SubtitleAutoSync.estimate(cues, tl)!;
      expect(e.offsetSec, closeTo(1.1, 0.15));
      expect(e.isConfident, isTrue, reason: '$e');
    });

    test('is centred on the delay in use, so a big one is still found', () {
      final rnd = Random(11);
      final cues = _cues(rnd);
      final tl = SpeechTimeline()
        ..addAll(_audio(cues, offset: 120, from: 200, to: 500, rnd: rnd));
      expect(SubtitleAutoSync.estimate(cues, tl)?.isConfident, isNot(true));
      final e = SubtitleAutoSync.estimate(cues, tl, currentDelaySec: 100)!;
      expect(e.offsetSec, closeTo(120, 0.15));
      expect(e.isConfident, isTrue, reason: '$e');
    });

    test('finds a 25 fps subtitle on a 23.976 fps film', () {
      final rnd = Random(12);
      final cues = _cues(rnd, length: 3000);
      const ratio = 25 / 23.976;
      final tl = SpeechTimeline()
        ..addAll(
          _audio(
            cues,
            offset: 0.4,
            ratio: ratio,
            from: 1500,
            to: 2300,
            rnd: rnd,
          ),
        );
      final e = SubtitleAutoSync.estimate(cues, tl)!;
      expect(e.ratio, closeTo(ratio, 1e-9));
      expect(e.offsetSec, closeTo(0.4, 0.2));
      expect(e.isConfident, isTrue, reason: '$e');
    });

    test('says nothing before two minutes of film were heard', () {
      final rnd = Random(13);
      final cues = _cues(rnd);
      final tl = SpeechTimeline()
        ..addAll(_audio(cues, offset: 2, from: 100, to: 210, rnd: rnd));
      expect(SubtitleAutoSync.estimate(cues, tl), isNull);
    });

    test('says nothing when too few lines fall in what was heard', () {
      final rnd = Random(14);
      final cues = _cues(rnd, length: 900);
      final tl = SpeechTimeline()
        ..addAll(_audio(cues, offset: 0, from: 880, to: 1100, rnd: rnd));
      expect(SubtitleAutoSync.estimate(cues, tl), isNull);
    });

    test('says nothing with too few lines at all', () {
      final rnd = Random(15);
      final cues = _cues(rnd).take(10).toList();
      final tl = SpeechTimeline()
        ..addAll(_audio(cues, offset: 0, from: 0, to: 300, rnd: rnd));
      expect(SubtitleAutoSync.estimate(cues, tl), isNull);
    });

    test(
      'is not confident when the sound has nothing to do with the lines',
      () {
        var confidentWrong = 0;
        for (var seed = 0; seed < 12; seed++) {
          final rnd = Random(100 + seed);
          final cues = _cues(rnd);
          final other = _cues(Random(900 + seed));
          final tl = SpeechTimeline()
            ..addAll(_audio(other, offset: 0, from: 100, to: 500, rnd: rnd));
          final e = SubtitleAutoSync.estimate(cues, tl);
          if (e != null && e.isConfident) confidentWrong++;
        }
        expect(confidentWrong, 0);
      },
    );

    test('loud music does not give a confident wrong answer', () {
      var confidentWrong = 0;
      var right = 0;
      for (var seed = 0; seed < 12; seed++) {
        final rnd = Random(200 + seed);
        final cues = _cues(rnd);
        final tl = SpeechTimeline()
          ..addAll(
            _audio(
              cues,
              offset: 3.0,
              from: 100,
              to: 500,
              rnd: rnd,
              music: true,
            ),
          );
        final e = SubtitleAutoSync.estimate(cues, tl);
        if (e != null && e.isConfident) {
          if ((e.offsetSec - 3.0).abs() <= 0.2) {
            right++;
          } else {
            confidentWrong++;
          }
        }
      }
      expect(confidentWrong, 0);
      // The music costs some answers but not all.
      expect(right, greaterThan(0));
    });

    test('steady music alone is no answer', () {
      final rnd = Random(21);
      final cues = _cues(rnd);
      final tl = SpeechTimeline();
      for (var b = 0; b < 3000; b++) {
        tl.add(AudioLevelSample(b * 0.1, -28 + rnd.nextDouble() * 2));
      }
      expect(SubtitleAutoSync.estimate(cues, tl), isNull);
    });
  });

  group('SubtitleAutoSync.alignToReference', () {
    test('finds how far another subtitle is from one in time', () {
      final rnd = Random(30);
      final reference = _cues(rnd);
      // Another translation: lines cut a little differently, 3.4 s early.
      final other = [
        for (final c in reference)
          SubCue(
            start: c.start - 3.4 + rnd.nextDouble() * 0.3,
            end: c.end - 3.4 - rnd.nextDouble() * 0.3,
            text: c.text,
          ),
      ];
      final e = SubtitleAutoSync.alignToReference(other, reference)!;
      expect(e.offsetSec, closeTo(3.4, 0.4));
      expect(e.ratio, 1.0);
      expect(e.isVeryConfident, isTrue, reason: '$e');
    });

    test('finds a frame rate difference between two subtitles', () {
      final rnd = Random(31);
      final reference = _cues(rnd, length: 3000);
      const ratio = 24 / 25;
      final other = [
        for (final c in reference)
          SubCue(start: c.start * ratio, end: c.end * ratio, text: c.text),
      ];
      final e = SubtitleAutoSync.alignToReference(other, reference)!;
      expect(e.ratio, closeTo(25 / 24, 1e-9));
      expect(e.offsetSec.abs(), lessThan(0.5));
      expect(e.isConfident, isTrue, reason: '$e');
    });

    test('a reference gathered across a seek does not count the gap', () {
      final rnd = Random(33);
      final all = _cues(rnd, length: 1500);
      // Watched 0-300 s and 900-1200 s only.
      final reference = [
        for (final c in all)
          if (c.end < 300 || (c.start > 900 && c.end < 1200)) c,
      ];
      final other = [
        for (final c in all)
          SubCue(start: c.start + 1.7, end: c.end + 1.7, text: c.text),
      ];
      final mask = SpeechMask.fromCues(reference)!;
      // 300 s + 300 s heard, not the 1200 s between the first and last line.
      expect(mask.observedSec, lessThan(650));
      final e = SubtitleAutoSync.alignToReference(other, reference)!;
      expect(e.offsetSec, closeTo(-1.7, 0.15));
      expect(e.isConfident, isTrue, reason: '$e');
    });

    test('gives up on a reference with too few lines', () {
      final rnd = Random(32);
      final cues = _cues(rnd);
      expect(
        SubtitleAutoSync.alignToReference(cues, cues.take(5).toList()),
        isNull,
      );
    });
  });
}
