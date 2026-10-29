/// Progress for an official upload played in YouTube's embedded player.
///
/// The embed reports its state and clock through the IFrame Player API; this
/// file decides, from those samples alone, when the watch history is written
/// and where a reopened episode starts. It is pure Dart so every rule is a
/// unit test: the player widget only feeds it samples and hands its saves to
/// `ContinueWatchingService.saveProgress`, the same call the stream player
/// makes, which also marks the episode watched (`WatchedEpisodes`) once the
/// position is at 90% or more.
///
/// **Compilations record nothing.** A multi-episode upload ("EP166-172合集")
/// has one clock for seven episodes: a position in it is not a position in
/// the episode the viewer picked, and reaching its end does not mean the
/// picked episode, or any single one, was watched. Writing either would put a
/// wrong resume point or a wrong "watched" tick on the details page, so the
/// safe choice is to leave the history untouched.
library;

import '../../models/continue_watching/continue_watching_item.dart';

/// YouTube IFrame API player states.
abstract final class YtState {
  static const int unstarted = -1;
  static const int ended = 0;
  static const int playing = 1;
  static const int paused = 2;
  static const int buffering = 3;
  static const int cued = 5;
}

class OfficialProgressTracker {
  OfficialProgressTracker({
    required this.enabled,
    required this.onSave,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// False for a compilation: nothing is ever saved.
  final bool enabled;

  /// Receives `(positionSeconds, durationSeconds)` to persist.
  final void Function(int positionSeconds, int durationSeconds) onSave;

  final DateTime Function() _clock;

  /// How often progress is written while the video plays.
  static const Duration saveInterval = Duration(seconds: 15);

  /// Below this the viewer has not really started; the history keeps its
  /// previous state (the continue-watching store ignores it too).
  static const int minPositionSeconds = 5;

  double? _position;
  double? _duration;
  int _state = YtState.unstarted;
  DateTime? _lastSave;
  int? _lastSavedPosition;
  bool _finished = false;

  /// Whether the end was reached (or 90% passed) and saved as finished.
  bool get finished => _finished;

  /// One report from the page: any of the three may be missing.
  void sample({double? position, double? duration, int? state}) {
    if (position != null && position >= 0) _position = position;
    if (duration != null && duration > 0) _duration = duration;
    final previous = _state;
    if (state != null) _state = state;
    if (!enabled) return;

    if (state == YtState.ended && previous != YtState.ended) {
      _saveEnded();
      return;
    }
    if (state == YtState.paused && previous != YtState.paused) {
      _save();
      return;
    }
    if (_state == YtState.playing) {
      final last = _lastSave;
      if (last == null || _clock().difference(last) >= saveInterval) _save();
    }
  }

  /// The player is closing: write where the viewer stopped.
  void close() {
    if (!enabled) return;
    if (_state == YtState.ended) return;
    _save();
  }

  void _saveEnded() {
    final d = _duration;
    if (d == null) return;
    final secs = d.round();
    _emit(secs, secs);
  }

  void _save() {
    final p = _position;
    final d = _duration;
    if (p == null || d == null || d <= 0) return;
    final pos = p.round().clamp(0, d.round());
    if (pos < minPositionSeconds) return;
    if (pos == _lastSavedPosition) {
      _lastSave = _clock();
      return;
    }
    _emit(pos, d.round());
  }

  void _emit(int pos, int dur) {
    _lastSave = _clock();
    _lastSavedPosition = pos;
    if (isFinishedAt(pos, dur)) _finished = true;
    onSave(pos, dur);
  }

  /// The same 90% rule the continue-watching store marks "watched" with.
  static bool isFinishedAt(int positionSeconds, int durationSeconds) =>
      durationSeconds > 0 && positionSeconds / durationSeconds >= 0.90;

  // ── Resume ────────────────────────────────────────────────────────────

  /// The saved session for this show and episode, played from the same
  /// official upload ([streamTitle]), or null.
  ///
  /// [officialAddonNames] are the row's addon name in every app language,
  /// since the name was saved in whichever language the app had then.
  static ContinueWatchingItem? savedFor(
    Iterable<ContinueWatchingItem> items, {
    required String showId,
    required int? season,
    required int? episode,
    required String streamTitle,
    required Set<String> officialAddonNames,
  }) {
    for (final item in items) {
      if (item.id != showId) continue;
      if (item.season != season || item.episode != episode) continue;
      if (!officialAddonNames.contains(item.addonName)) continue;
      if (item.streamTitle != null && item.streamTitle != streamTitle) continue;
      return item;
    }
    return null;
  }

  /// Where to start: [explicit] (a resume the caller already chose) or the
  /// saved position, unless that is too early to matter or the episode was
  /// finished. Null starts from the beginning.
  static int? resumeSeconds({Duration? explicit, ContinueWatchingItem? saved}) {
    if (explicit != null && explicit.inSeconds >= minPositionSeconds) {
      return explicit.inSeconds;
    }
    if (saved == null) return null;
    if (saved.positionSeconds < minPositionSeconds) return null;
    if (isFinishedAt(saved.positionSeconds, saved.totalDurationSeconds)) {
      return null;
    }
    return saved.positionSeconds;
  }
}
