import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'engine/audio_level.dart';

/// The speech level of what this app plays on Windows, for the subtitle
/// auto-sync (the counterpart of `ExoPlayerEngine.audioLevels`).
///
/// The libmpv this app ships has no audio filter that could measure the
/// sound, so the runner listens to the app's own audio output instead
/// (WASAPI process loopback, `windows/runner/audio_level_plugin.cpp`): only
/// this process, a copy taken inside the audio engine, so what the viewer
/// hears is untouched. It needs Windows 11 (or 10 build 20348); on anything
/// older [levels] simply never produces anything and [onUnavailable] is told.
///
/// Timing. The native side stamps every 0.1 s window with the wall clock
/// (QueryPerformanceCounter, in microseconds) of its END as it was captured,
/// and sends them in batches about every 300 ms together with its clock now.
/// Here the age of a window is that clock's difference, and its place in the
/// film is the player's position now minus that age (times the speed, since
/// a second of wall clock is `rate` seconds of film):
///
///     media = position(now) - (nowUs - startUs) / 1e6 * rate
///
/// What is captured is what the viewer hears, so it lines up with the picture
/// the way the subtitles do. Two small things are left alone: loopback is
/// tapped inside the audio engine, before the device's own buffer, so on
/// speakers it leads what is heard by roughly 10 to 30 ms (Bluetooth more,
/// up to a couple of hundred), and [mediaPosition] is only as fresh as the
/// player's last position event. Both are well under the 0.35 s the auto-sync
/// needs before it moves anything, so there is no compensation for them.
class WindowsAudioLevels {
  WindowsAudioLevels({
    required this.mediaPosition,
    required this.rate,
    required this.playing,
    this.onUnavailable,
    MethodChannel? method,
    EventChannel? events,
  }) : _method = method ?? const MethodChannel(methodChannelName),
       _events = events ?? const EventChannel(eventChannelName) {
    _controller = StreamController<AudioLevelSample>.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );
  }

  static const String methodChannelName = 'lumora/audio_levels';
  static const String eventChannelName = 'lumora/audio_levels/events';

  /// Where the film is now.
  final Duration Function() mediaPosition;

  /// The playback speed.
  final double Function() rate;

  /// Whether sound is coming out: false while paused, seeking or buffering,
  /// so the silence of a pause is not taken for a stretch without speech.
  final bool Function() playing;

  /// Told once when capture cannot work here (older Windows, no audio
  /// device, the plugin missing), so the caller can stop counting on it.
  final VoidCallback? onUnavailable;

  final MethodChannel _method;
  final EventChannel _events;
  late final StreamController<AudioLevelSample> _controller;

  StreamSubscription<dynamic>? _sub;
  int _listenGeneration = 0;
  int _restarts = 0;
  Timer? _restartTimer;

  // The last batch's clock and position, to notice that the film jumped
  // (a seek, a pause) between two batches.
  int? _lastNowUs;
  double? _lastPosSec;

  /// A capture that ended by itself is started again this many times.
  static const int maxRestarts = 3;
  static const Duration restartDelay = Duration(seconds: 2);

  /// A batch whose position is further than this from where the clock says
  /// the film should be crossed a seek or a pause, and is dropped.
  static const double jumpToleranceSec = 0.5;

  /// Samples, in film time. The native capture only runs while this has a
  /// listener: the first one starts it, the last one leaving stops it.
  Stream<AudioLevelSample> get levels => _controller.stream;

  void _onListen() {
    final generation = ++_listenGeneration;
    _restarts = 0;
    _lastNowUs = null;
    _lastPosSec = null;
    // The sink has to be there before capture starts.
    _sub = _events.receiveBroadcastStream().listen(
      _onEvent,
      onError: (Object error) => _onNativeError(generation, error),
    );
    unawaited(_start(generation));
  }

  void _onCancel() {
    _listenGeneration++;
    _restartTimer?.cancel();
    _restartTimer = null;
    final sub = _sub;
    _sub = null;
    unawaited(sub?.cancel());
    unawaited(_stop());
  }

  Future<void> _start(int generation) async {
    try {
      await _method.invokeMethod<bool>('start');
    } on MissingPluginException {
      _unavailable(generation);
    } on PlatformException catch (e) {
      debugPrint('[WinAudioLevels] start failed: ${e.code}');
      if (e.code == 'unsupported' || e.code == 'failed') {
        _unavailable(generation);
      }
    } catch (e) {
      debugPrint('[WinAudioLevels] start failed: $e');
    }
  }

  Future<void> _stop() async {
    try {
      await _method.invokeMethod<bool>('stop');
    } catch (_) {
      // Nothing was running, or no plugin: either way it is stopped.
    }
  }

  void _unavailable(int generation) {
    if (generation != _listenGeneration) return;
    onUnavailable?.call();
  }

  void _onNativeError(int generation, Object error) {
    if (generation != _listenGeneration) return;
    if (error is PlatformException &&
        error.code == 'capture_lost' &&
        _restarts < maxRestarts) {
      // The device went away or the engine reset; try again shortly.
      _restarts++;
      _restartTimer?.cancel();
      _restartTimer = Timer(restartDelay, () {
        if (generation == _listenGeneration) unawaited(_start(generation));
      });
      return;
    }
    _unavailable(generation);
  }

  void _onEvent(dynamic event) {
    if (_controller.isClosed || !_controller.hasListener) return;
    for (final sample in _samples(event)) {
      _controller.add(sample);
    }
  }

  /// Turns one native batch into samples in film time.
  ///
  /// A batch while the film is not playing is dropped, and so is one whose
  /// position is further than [jumpToleranceSec] from where the previous
  /// batch says the film should be: a seek or a pause happened in between,
  /// and the windows in it cannot be placed. A malformed batch gives nothing.
  List<AudioLevelSample> _samples(dynamic event) {
    if (event is! Map) return const [];
    final nowUs = event['nowUs'];
    final ends = event['endUs'];
    final levels = event['db'];
    if (nowUs is! int || ends is! List || levels is! List) return const [];

    final posSec = mediaPosition().inMicroseconds / 1e6;
    final speed = rate();
    if (!playing() || !posSec.isFinite || !speed.isFinite || speed <= 0) {
      _lastNowUs = null;
      _lastPosSec = null;
      return const [];
    }
    final lastNowUs = _lastNowUs;
    final lastPosSec = _lastPosSec;
    _lastNowUs = nowUs;
    _lastPosSec = posSec;
    if (lastNowUs != null && lastPosSec != null) {
      final expected = lastPosSec + (nowUs - lastNowUs) / 1e6 * speed;
      if ((posSec - expected).abs() > jumpToleranceSec) return const [];
    }

    final count = ends.length < levels.length ? ends.length : levels.length;
    final out = <AudioLevelSample>[];
    for (var i = 0; i < count; i++) {
      final end = ends[i];
      final db = levels[i];
      if (end is! num || db is! num || !db.isFinite) continue;
      final t = mediaTimeOfWindow(
        nowUs: nowUs,
        endUs: end.toInt(),
        positionSec: posSec,
        rate: speed,
      );
      if (t < 0) continue;
      out.add(AudioLevelSample(t, db.toDouble()));
    }
    return out;
  }

  /// Where in the film the window ending at [endUs] (wall clock, microseconds)
  /// starts, given that the film is at [positionSec] at [nowUs].
  @visibleForTesting
  static double mediaTimeOfWindow({
    required int nowUs,
    required int endUs,
    required double positionSec,
    required double rate,
  }) {
    final startUs = endUs - (audioLevelStepSec * 1e6).round();
    // A clock that reads a hair behind the stamp is not a window from the
    // future.
    final ageSec = nowUs > startUs ? (nowUs - startUs) / 1e6 : 0.0;
    return positionSec - ageSec * rate;
  }

  void dispose() {
    _listenGeneration++;
    _restartTimer?.cancel();
    final sub = _sub;
    _sub = null;
    if (sub != null) {
      unawaited(sub.cancel());
      unawaited(_stop());
    }
    if (!_controller.isClosed) unawaited(_controller.close());
  }
}
