import 'dart:async';

import '../../models/stream/stream_model.dart';
import 'stream_health_checker.dart';

/// Why a source is not worth offering first.
enum SourceDeadReason {
  /// A torrent nobody is seeding: it will sit at 0 B/s.
  noSeeders,

  /// A direct link whose probe failed: refused, expired or an error page.
  unreachable,
}

/// The source "自动" plays, and the ranked rest the player falls back to.
class AutoPick {
  const AutoPick(this.source, this.alternatives);

  final StreamSource source;

  /// Every other playable source in rank order, [source] first, which is the
  /// shape `PlayerScreen.alternatives` walks when a start fails.
  final List<StreamSource> alternatives;
}

/// Picks the fastest source that is known to work, from a list already ranked
/// by the screen (and so already matched to the right title by the scrapers).
///
/// Direct and debrid links are probed as they are [offer]ed, while the
/// scrapers are still answering, and the first to come back alive wins: that
/// answer is the latency the viewer would wait through before the first frame.
/// Deciding from whatever had arrived after a fixed wait picked a torrent for
/// The Godfather Part III with 4 direct links in hand, when 20 arrived in the
/// end. A torrent leads only when there is no link at all, because a
/// torrent's start time is its swarm. A torrent with no seeders is never
/// queued; a link whose probe failed is queued behind the ones that passed,
/// since the probe is a hint and not a verdict (see [pickNow]).
class AutoSourcePicker {
  AutoSourcePicker({
    Future<bool> Function(StreamSource source)? probe,
    this.directProbeCount = 6,
    this.maxProbes = 16,
    this.probeTimeout = const Duration(seconds: 8),
  }) : _probe = probe ?? StreamHealthChecker.isAlive;

  final Future<bool> Function(StreamSource source) _probe;

  /// How many of the top direct sources [pick] races when nothing was offered
  /// before it.
  final int directProbeCount;

  /// The most links probed in all, across every [offer].
  final int maxProbes;

  /// The longest one probe may take before it counts as unreachable.
  final Duration probeTimeout;

  /// Links whose probe failed, keyed by [keyOf]. Used to order the queue,
  /// not to drop or grey anything: the probe is often wrong.
  final Map<String, SourceDeadReason> dead = {};

  final Set<String> _probed = {};
  int _pending = 0;
  StreamSource? _winner;
  Completer<void> _changed = Completer<void>();

  /// The first link that answered alive, once one has.
  StreamSource? get winner => _winner;

  /// Whether a probe is still running.
  bool get probing => _pending > 0;

  /// Completes the next time a probe finishes.
  Future<void> get nextResult => _changed.future;

  /// A stable identity for a source across rebuilds of the list.
  static String keyOf(StreamSource s) =>
      '${s.addonName}|${s.infoHash ?? ''}|${s.fileIdx ?? ''}|${s.url ?? ''}';

  /// Whether [s] is dead without probing it: a torrent reporting 0 seeders.
  static SourceDeadReason? knownDead(StreamSource s) {
    if (s.isTorrent && s.seeders == 0) return SourceDeadReason.noSeeders;
    return null;
  }

  static bool _playable(StreamSource s) {
    final external = s.externalUrl;
    if (external != null && external.isNotEmpty) return false;
    // A provider that reports a block as a row ("⛔ Spammy IP — slowdown")
    // is a message, not a video.
    if ((s.title ?? '').contains('⛔') || (s.name ?? '').contains('⛔')) {
      return false;
    }
    return s.isMagnet || (s.url != null && s.url!.isNotEmpty);
  }

  /// A link worth racing: playable, not a torrent, and not below 720p when
  /// the source says what it is (an unlabelled link is given the benefit).
  static bool _raceable(StreamSource s) {
    if (!_playable(s) || s.isTorrent) return false;
    return s.quality != '480p';
  }

  /// Language words a source names, and the ISO 639-1 language each means.
  /// "VOSTFR" is the original audio with French subtitles in the picture,
  /// which is as foreign to a viewer as French audio.
  static const Map<String, String> _languageWords = {
    'hindi': 'hi', 'kannada': 'kn', 'tamil': 'ta', 'telugu': 'te',
    'malayalam': 'ml', 'bengali': 'bn', 'marathi': 'mr', 'punjabi': 'pa',
    'ita': 'it', 'italian': 'it',
    'latino': 'es', 'castellano': 'es', 'spanish': 'es',
    'vostfr': 'fr', 'vf': 'fr', 'vff': 'fr', 'truefrench': 'fr',
    'french': 'fr',
    'german': 'de', 'deutsch': 'de',
    'russian': 'ru', 'rus': 'ru',
    'portuguese': 'pt', 'dublado': 'pt', 'legendado': 'pt',
    'turkish': 'tr', 'polish': 'pl', 'arabic': 'ar', 'vietsub': 'vi',
    'thai': 'th',
  };

  static final RegExp _languageWord = RegExp(
    '\\b(${_languageWords.keys.join('|')})\\b',
    caseSensitive: false,
  );

  /// The title's original language (TMDb's `original_language`, e.g. 'en',
  /// 'zh', 'es'), so a Spanish film's "Spanish" source is not taken for a
  /// dub. Null treats every named language as a dub.
  String? originalLanguage;

  /// Whether [s] names a language other than the original: a dub ("[Rive -
  /// Citadel] 720p | Kannada", "iTA-ENG") or foreign subtitles burned into
  /// the picture (Ne Zha 2's "VOSTFR"). Goes behind the original-language
  /// sources.
  bool _isDub(StreamSource s) {
    final text = '${s.title ?? ''} ${s.name ?? ''}';
    for (final m in _languageWord.allMatches(text)) {
      final lang = _languageWords[m.group(1)!.toLowerCase()];
      if (lang != null && lang != originalLanguage) return true;
    }
    return false;
  }

  static final RegExp _variant = RegExp(
    r'alt[ ._-]?universe|commentary|featurette|extras|bonus|behind[ ._-]the[ ._-]scenes|making[ ._-]of|trailer|sample',
    caseSensitive: false,
  );

  /// Whether [s] is something other than the film itself: an alternate cut
  /// that opens with the filmmakers talking ("Spider-Verse Alt-Universe
  /// Cut"), extras, a trailer. Goes behind the regular release.
  static bool _isVariant(StreamSource s) =>
      _variant.hasMatch('${s.title ?? ''} ${s.name ?? ''}');

  /// One step back for each way [s] is not the plain original: dubbed, or
  /// not the film itself.
  int _sideRank(StreamSource s) =>
      (_isDub(s) ? 1 : 0) + (_isVariant(s) ? 1 : 0);

  /// What the connection can sustain, in Mbps (see `NetworkSpeed`); null
  /// until the viewer's own playback has measured it, which is treated as a
  /// connection that carries 1080p and not 4K.
  double? bandwidthMbps;

  /// The title's length, which turns a torrent's size into its bitrate.
  int? runtimeMinutes;

  /// The highest quality the viewer asked for with the player's 画质 button
  /// ('4K', '1080p', '720p'), or null for automatic.
  String? qualityCap;

  static const _qualityOrder = ['480p', '720p', '1080p', '4K'];

  /// The rate [s] needs to play without stopping, in Mbps, or null when it
  /// cannot be told. A file's (a torrent, or a link to one like Vadapav's
  /// 5.75 GB MKV) is its size over the runtime; a stream's is typical for its
  /// label (streaming sites encode lean: 1080p near 4.5).
  double? _neededMbps(StreamSource s) {
    final size = s.sizeBytes;
    final minutes = runtimeMinutes;
    if (size != null && size > 0 && minutes != null && minutes > 0) {
      return size * 8 / (minutes * 60) / 1e6;
    }
    return switch (s.quality) {
      '4K' => 20.0,
      '1080p' => 4.5,
      '720p' => 2.5,
      '480p' => 1.2,
      _ => null,
    };
  }

  /// Whether [s] would play a bit and stop on this connection: it needs more
  /// than 80% of the measured rate (10 Mbps assumed before any measurement),
  /// or it is above the viewer's chosen quality. A 29 GB 4K torrent of a
  /// 145-minute film needs about 27 Mbps; on a 6 Mbps line it played a few
  /// seconds at a time.
  bool tooHeavy(StreamSource s) {
    final cap = qualityCap;
    if (cap != null && s.quality != null) {
      final over = _qualityOrder.indexOf(s.quality!) > _qualityOrder.indexOf(cap);
      if (over) return true;
    }
    final need = _neededMbps(s);
    if (need == null) {
      // Size alone, when the runtime is unknown.
      final size = s.sizeBytes ?? 0;
      return s.isTorrent && size > 15.0 * 1024 * 1024 * 1024;
    }
    return need > (bandwidthMbps ?? 10) * 0.8;
  }

  /// Torrents in the order they are worth trying: ones the connection can
  /// carry first, original language before dubs, then by seeders.
  List<StreamSource> _torrentOrder(Iterable<StreamSource> torrents) {
    int rank(StreamSource s) => (tooHeavy(s) ? 4 : 0) + _sideRank(s);

    final list = torrents.toList();
    list.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return (b.seeders ?? 0).compareTo(a.seeders ?? 0);
    });
    return list;
  }

  /// Starts probing every raceable link in [ranked] not probed yet, up to
  /// [maxProbes] in all. Original-language links are probed before dubs.
  void offer(Iterable<StreamSource> ranked) {
    final ordered = [
      for (var side = 0; side <= 2; side++)
        ...ranked.where((s) => _sideRank(s) == side && !tooHeavy(s)),
      ...ranked.where(tooHeavy),
    ];
    for (final s in ordered) {
      if (_winner != null || _probed.length >= maxProbes) return;
      if (!_raceable(s)) continue;
      final key = keyOf(s);
      if (!_probed.add(key)) continue;
      _pending++;
      _probe(s)
          .timeout(probeTimeout, onTimeout: () => false)
          .catchError((_) => false)
          .then((alive) {
            _pending--;
            if (alive) {
              _winner ??= s;
            } else {
              dead[key] = SourceDeadReason.unreachable;
            }
            final changed = _changed;
            _changed = Completer<void>();
            changed.complete();
          });
    }
  }

  /// Waits until a link has won or every probe started so far has finished.
  Future<void> settle() async {
    while (_winner == null && _pending > 0) {
      await nextResult;
    }
  }

  /// The pick from [ranked]: the [winner] if a link has answered, else the
  /// best-seeded torrent, else null when nothing in it can play.
  ///
  /// Probes the top [directProbeCount] links first when none were offered,
  /// and waits for the ones running.
  Future<AutoPick?> pick(List<StreamSource> ranked) async {
    for (final s in ranked) {
      final reason = knownDead(s);
      if (reason != null) dead[keyOf(s)] = reason;
    }
    if (_probed.isEmpty) offer(ranked.where(_raceable).take(directProbeCount));
    await settle();
    return pickNow(ranked);
  }

  /// The pick from [ranked] with what is known now, without waiting.
  ///
  /// The probe decides the order, never the verdict: measured against the
  /// app's own libmpv it failed links that play (VidZee, FSOnline, Rive,
  /// LMScript for Spider-Man: Brand New Day) and passed one that never showed
  /// a frame. So a link it failed stays in the queue, behind the ones it
  /// passed, and the player's own first-frame watch is the judge.
  ///
  /// Order: the first link to answer (when it is the plain original and the
  /// line carries it), then the other links - ones the line carries, then
  /// the original release before dubs and alternate cuts, then probe passed
  /// before failed, as ranked otherwise - then torrents by [_torrentOrder].
  /// A torrent leads only when there is no link.
  AutoPick? pickNow(List<StreamSource> ranked) {
    final playable = [
      for (final s in ranked)
        if (_playable(s) && knownDead(s) == null) s,
    ];
    final links = playable.where((s) => !s.isTorrent).toList();
    int linkRank(StreamSource s) =>
        (tooHeavy(s) ? 8 : 0) +
        _sideRank(s) * 2 +
        (dead.containsKey(keyOf(s)) ? 1 : 0);
    final orderedLinks = [
      for (var i = 0; i < links.length; i++) (i, links[i]),
    ]..sort((a, b) {
        final byRank = linkRank(a.$2).compareTo(linkRank(b.$2));
        return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
      });
    // The fastest answer leads unless the line cannot carry it.
    final lead =
        (_winner != null && !tooHeavy(_winner!) && _sideRank(_winner!) == 0)
        ? _winner
        : null;
    final queue = [
      ?lead,
      for (final (_, s) in orderedLinks)
        if (lead == null || keyOf(s) != keyOf(lead)) s,
      ..._torrentOrder(playable.where((s) => s.isTorrent)),
    ];
    if (queue.isEmpty) return null;
    return AutoPick(queue.first, queue);
  }
}

/// A Cinemeta runtime ("46 min", "1h 30min", "2h") as a duration.
Duration? parseRuntime(String? runtime) {
  if (runtime == null) return null;
  final h = RegExp(r'(\d+)\s*h').firstMatch(runtime);
  final m = RegExp(r'(\d+)\s*m').firstMatch(runtime);
  final minutes =
      (h == null ? 0 : int.parse(h.group(1)!) * 60) +
      (m == null ? 0 : int.parse(m.group(1)!));
  if (minutes == 0) {
    final bare = int.tryParse(runtime.trim());
    return bare == null || bare == 0 ? null : Duration(minutes: bare);
  }
  return Duration(minutes: minutes);
}

/// Whether a stream of [actual] length cannot be a title that runs
/// [expected]: under 40% of it and under a quarter hour. Short titles
/// (under 10 minutes) are not judged.
bool isTooShortForRuntime(Duration actual, Duration expected) =>
    expected >= const Duration(minutes: 10) &&
    actual < const Duration(minutes: 15) &&
    actual.inSeconds < expected.inSeconds * 0.4;
