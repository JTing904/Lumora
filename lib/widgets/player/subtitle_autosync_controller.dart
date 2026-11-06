import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/player/engine/audio_level.dart';
import '../../services/subtitles/subtitle_autosync.dart';
import '../../services/subtitles/subtitle_offset_store.dart';
import '../../services/subtitles/subtitle_parser.dart';

/// What the sync bar says about the auto-sync.
enum AutoSyncStatus {
  /// Turned off by the viewer, or no subtitle to line up.
  off,

  /// Nothing this video offers to compare the subtitle with: no own subtitle
  /// to use as a reference and no sound being measured.
  noSource,

  /// Collecting; not enough yet to say.
  listening,

  /// In time (it was found so, or it was moved to be).
  aligned,

  /// Enough to look, not enough to be sure: the timing is left alone.
  unsure,

  /// The viewer moved the timing themselves, or undid a change.
  paused,
}

/// Where an answer came from.
enum AutoSyncSource { streamSubtitle, embeddedSubtitle, audio }

/// A change the auto-sync made, for the snack bar.
class AutoSyncChange {
  const AutoSyncChange({
    required this.delaySec,
    required this.ratio,
    required this.previousDelaySec,
    required this.previousRatio,
    required this.estimate,
    required this.source,
  });

  final double delaySec;
  final double ratio;
  final double previousDelaySec;
  final double previousRatio;
  final SyncEstimate estimate;
  final AutoSyncSource source;

  bool get stretched => (ratio - 1).abs() > 1e-6;
}

/// Keeps the downloaded subtitle in time with the film by itself.
///
/// It gathers evidence of when people really speak (a reference subtitle
/// known to be in time, or the sound's speech level), asks
/// [SubtitleAutoSync] how the subtitle has to move, and applies the answer
/// through [onApply], the same path as the viewer's own timing, only when it
/// is sure. It stops for the rest of a subtitle when the viewer touches the
/// timing, and it checks again now and then because a cut or an ad break
/// can change the timing midway.
class SubtitleAutoSyncController extends ChangeNotifier {
  SubtitleAutoSyncController({
    required this.onApply,
    this.onAligned,
    this.checkEvery = const Duration(seconds: 10),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Sets the subtitle's timing (delay, stretch) and remembers it for the
  /// title. [auto] is false when the viewer's undo puts the old one back.
  final Future<void> Function(
    double delaySec,
    double ratio, {
    required bool auto,
  })
  onApply;

  /// Told after a change the auto-sync made, so the player can say so.
  final void Function(AutoSyncChange change)? onAligned;

  /// How often the evidence is looked at; each source has its own, longer,
  /// interval on top of that.
  final Duration checkEvery;

  final DateTime Function() _clock;

  /// Changes smaller than this are left alone.
  static const double minChangeSec = 0.35;

  /// A saved timing the viewer set is only overruled by an answer this much
  /// further, and very sure.
  static const double overruleSavedBySec = 1.0;

  /// A jump this big needs the very sure answer.
  static const double bigJumpSec = 20;

  /// How long each source waits before looking again.
  static const Duration recheckEvery = Duration(seconds: 60);

  /// Auto changes per subtitle; more than that is the search flip-flopping
  /// and the viewer is better off with what they have.
  static const int maxChanges = 4;

  /// When the sound is checked again, only this many of the newest bins
  /// (5 minutes) are used so a change partway through shows.
  static const int recentBins = 3000;

  /// The same for a reference gathered while watching: its newest lines.
  static const int recentLines = 80;

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _refreshStatus();
  }

  AutoSyncStatus _status = AutoSyncStatus.off;
  AutoSyncStatus get status => _status;

  // ── What is being synced ─────────────────────────────────────────────────

  List<SubCue> _cues = const [];
  double _delay = 0;
  double _ratio = 1;
  bool _stopped = false;
  bool _savedByViewer = false;
  int _changes = 0;
  AutoSyncChange? _lastChange;
  int _generation = 0;

  bool get hasSubtitle => _cues.isNotEmpty;

  // ── Evidence ─────────────────────────────────────────────────────────────

  final SpeechTimeline _timeline = SpeechTimeline();
  StreamSubscription<AudioLevelSample>? _audioSub;
  bool _audioAttached = false;

  List<SubCue> _streamRef = const [];
  bool _streamRefPending = false;
  bool _streamRefUsed = false;

  List<SubCue> _liveRef = const [];
  bool _liveRefAvailable = false;
  int _liveRefCountAtLastLook = 0;
  DateTime? _lastLiveLook;
  int _liveLooks = 0;

  DateTime? _lastAudioLook;
  int _audioLooks = 0;

  Timer? _timer;
  bool _busy = false;

  /// How much of the film's sound was measured.
  double get listenedSec => _timeline.observedSec;

  // ── Inputs ───────────────────────────────────────────────────────────────

  /// A subtitle came on. [savedTiming] is what was remembered for it, if
  /// anything; [streamReference] loads the lines of a subtitle the stream
  /// brought (cut for this video), when there is one other than this.
  void begin({
    required List<SubCue> cues,
    required double delaySec,
    double ratio = 1,
    SubtitleTiming? savedTiming,
    Future<List<SubCue>?> Function()? streamReference,
  }) {
    _generation++;
    final generation = _generation;
    _cues = List<SubCue>.of(cues);
    _delay = delaySec;
    _ratio = ratio;
    _stopped = false;
    _savedByViewer = savedTiming != null && !savedTiming.auto;
    _changes = 0;
    _lastChange = null;
    _streamRef = const [];
    _streamRefUsed = false;
    _streamRefPending = streamReference != null;
    _lastLiveLook = null;
    _liveLooks = 0;
    _liveRefCountAtLastLook = 0;
    _lastAudioLook = null;
    _audioLooks = 0;
    _timer?.cancel();
    _timer = Timer.periodic(checkEvery, (_) => unawaited(tick()));
    // What the last subtitle found says nothing about this one.
    _status = AutoSyncStatus.off;
    _refreshStatus();
    if (streamReference != null) {
      unawaited(() async {
        List<SubCue>? lines;
        try {
          lines = await streamReference();
        } catch (e) {
          debugPrint('[SubAutoSync] stream reference failed: $e');
        }
        if (generation != _generation) return;
        _streamRefPending = false;
        _streamRef = lines ?? const [];
        _refreshStatus();
        unawaited(tick());
      }());
    }
    unawaited(tick());
  }

  /// The subtitle went away (turned off, or another kind chosen).
  void end() {
    _generation++;
    _cues = const [];
    _timer?.cancel();
    _timer = null;
    _lastChange = null;
    _refreshStatus();
  }

  /// A different video: what was measured of the last one means nothing.
  void newSource() {
    end();
    _timeline.clear();
    _streamRef = const [];
    _streamRefPending = false;
    _liveRef = const [];
  }

  /// Whether a sound level is being followed.
  bool get audioAttached => _audioAttached;

  /// Follows the player's speech level (Media3, or the app's own output on
  /// Windows), or nothing for null.
  void attachAudio(Stream<AudioLevelSample>? levels) {
    _audioSub?.cancel();
    _audioSub = null;
    _audioAttached = levels != null;
    if (levels != null) {
      _audioSub = levels.listen(_timeline.add);
    }
    _refreshStatus();
  }

  /// The lines of the video's own subtitle gathered so far (mpv).
  void setLiveReference(List<SubCue> cues) {
    _liveRef = cues;
    if (_liveRef.length >= SubtitleAutoSync.minCues &&
        _status != AutoSyncStatus.aligned) {
      unawaited(tick());
    }
  }

  /// Whether the video's own subtitle is being read at all.
  void setLiveReferenceAvailable(bool available) {
    if (_liveRefAvailable == available) return;
    _liveRefAvailable = available;
    if (!available) _liveRef = const [];
    _refreshStatus();
  }

  /// The viewer set the timing: leave it alone for this subtitle.
  void viewerMoved(double delaySec) {
    _delay = delaySec;
    if (_cues.isEmpty) return;
    _stopped = true;
    _savedByViewer = false;
    _lastChange = null;
    _refreshStatus();
  }

  /// Takes back the last change and stops for this subtitle.
  Future<void> undo() async {
    final change = _lastChange;
    if (change == null) return;
    _lastChange = null;
    _stopped = true;
    _delay = change.previousDelaySec;
    _ratio = change.previousRatio;
    _refreshStatus();
    await onApply(change.previousDelaySec, change.previousRatio, auto: false);
  }

  // ── Looking ──────────────────────────────────────────────────────────────

  /// One look at the evidence. The timer calls it; it is public so a test
  /// (and the moment new evidence arrives) can too.
  Future<void> tick() async {
    if (_busy || !_enabled || _stopped || _cues.isEmpty) return;
    _busy = true;
    final generation = _generation;
    try {
      final now = _clock();

      if (!_streamRefUsed && _streamRef.length >= SubtitleAutoSync.minCues) {
        _streamRefUsed = true;
        await _consider(
          SubtitleAutoSync.alignToReference(
            _cues,
            _streamRef,
            currentDelaySec: _delay,
          ),
          AutoSyncSource.streamSubtitle,
          generation,
        );
      }

      if (_liveRef.length >= SubtitleAutoSync.minCues &&
          _liveRef.length != _liveRefCountAtLastLook &&
          _due(_lastLiveLook, now)) {
        _lastLiveLook = now;
        _liveRefCountAtLastLook = _liveRef.length;
        final lines = _liveLooks == 0 || _liveRef.length <= recentLines
            ? _liveRef
            : _liveRef.sublist(_liveRef.length - recentLines);
        _liveLooks++;
        await _consider(
          SubtitleAutoSync.alignToReference(
            _cues,
            lines,
            currentDelaySec: _delay,
          ),
          AutoSyncSource.embeddedSubtitle,
          generation,
        );
      }

      if (_timeline.observedSec >= SubtitleAutoSync.minObservedSec &&
          _due(_lastAudioLook, now)) {
        _lastAudioLook = now;
        final timeline =
            _audioLooks == 0 || _timeline.observedBins <= recentBins
            ? _timeline
            : _timeline.newest(recentBins);
        _audioLooks++;
        await _consider(
          SubtitleAutoSync.estimate(_cues, timeline, currentDelaySec: _delay),
          AutoSyncSource.audio,
          generation,
        );
      }
    } finally {
      _busy = false;
    }
  }

  bool _due(DateTime? last, DateTime now) =>
      last == null || now.difference(last) >= recheckEvery;

  Future<void> _consider(
    SyncEstimate? estimate,
    AutoSyncSource source,
    int generation,
  ) async {
    if (generation != _generation || _stopped) return;
    if (estimate == null) return;
    if (!estimate.isConfident) {
      if (_status != AutoSyncStatus.aligned) _setStatus(AutoSyncStatus.unsure);
      return;
    }
    final offset = (estimate.offsetSec * 10).round() / 10;
    final diff = (offset - _delay).abs();
    final ratioChanged = (estimate.ratio - _ratio).abs() > 1e-4;
    if (diff <= minChangeSec && !ratioChanged) {
      _setStatus(AutoSyncStatus.aligned);
      return;
    }
    // Timing the viewer set is theirs unless it is clearly wrong, and a big
    // jump is only believed when the answer is beyond doubt.
    if (_savedByViewer && diff <= overruleSavedBySec && !ratioChanged) {
      _setStatus(AutoSyncStatus.aligned);
      return;
    }
    if ((_savedByViewer || diff > bigJumpSec) && !estimate.isVeryConfident) {
      _setStatus(AutoSyncStatus.unsure);
      return;
    }
    if (_changes >= maxChanges) {
      _setStatus(AutoSyncStatus.unsure);
      return;
    }
    final change = AutoSyncChange(
      delaySec: offset,
      ratio: estimate.ratio,
      previousDelaySec: _delay,
      previousRatio: _ratio,
      estimate: estimate,
      source: source,
    );
    _changes++;
    _savedByViewer = false;
    _delay = offset;
    _ratio = estimate.ratio;
    _lastChange = change;
    _setStatus(AutoSyncStatus.aligned);
    await onApply(offset, estimate.ratio, auto: true);
    if (generation != _generation) return;
    onAligned?.call(change);
  }

  void _refreshStatus() {
    if (!_enabled || _cues.isEmpty) {
      _setStatus(AutoSyncStatus.off);
    } else if (_stopped) {
      _setStatus(AutoSyncStatus.paused);
    } else if (_status == AutoSyncStatus.aligned ||
        _status == AutoSyncStatus.unsure) {
      // Keep what a look found until the next look.
      notifyListeners();
    } else if (_hasEvidenceSource) {
      _setStatus(AutoSyncStatus.listening);
    } else {
      _setStatus(AutoSyncStatus.noSource);
    }
  }

  bool get _hasEvidenceSource =>
      _audioAttached ||
      _liveRefAvailable ||
      _streamRefPending ||
      _streamRef.length >= SubtitleAutoSync.minCues;

  void _setStatus(AutoSyncStatus value) {
    if (_status == value) return;
    _status = value;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _audioSub?.cancel();
    super.dispose();
  }
}
