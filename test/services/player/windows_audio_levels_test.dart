import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/player/engine/audio_level.dart';
import 'package:zplay/services/player/windows_audio_levels.dart';

/// The native side (windows/runner/audio_level_plugin.cpp) stamps every
/// window with the QueryPerformanceCounter time of its end and sends batches
/// with its clock now. These tests pin the method names it answers to, the
/// shape of a batch, and the arithmetic that places a window in the film.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const method = MethodChannel(WindowsAudioLevels.methodChannelName);
  const events = EventChannel(WindowsAudioLevels.eventChannelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> calls;
  MockStreamHandlerEventSink? sink;
  Object? startOutcome;
  late bool eventListening;

  Duration position = Duration.zero;
  double rate = 1.0;
  bool playing = true;
  late int unavailableCalls;

  WindowsAudioLevels make() => WindowsAudioLevels(
    mediaPosition: () => position,
    rate: () => rate,
    playing: () => playing,
    onUnavailable: () => unavailableCalls++,
  );

  setUp(() {
    calls = <String>[];
    sink = null;
    startOutcome = true;
    eventListening = false;
    position = Duration.zero;
    rate = 1.0;
    playing = true;
    unavailableCalls = 0;
    messenger.setMockMethodCallHandler(method, (MethodCall call) async {
      calls.add(call.method);
      final outcome = startOutcome;
      if (call.method == 'start' && outcome is PlatformException) {
        throw outcome;
      }
      return true;
    });
    messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(
        onListen: (Object? arguments, MockStreamHandlerEventSink s) {
          sink = s;
          eventListening = true;
        },
        onCancel: (Object? arguments) {
          sink = null;
          eventListening = false;
        },
      ),
    );
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(method, null);
    messenger.setMockStreamHandler(events, null);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Map<String, Object> batch(int nowUs, List<int> ends, List<double> db) => {
    'nowUs': nowUs,
    'endUs': ends,
    'db': db,
  };

  group('mediaTimeOfWindow', () {
    test('subtracts the age of the window start from the position', () {
      // The window ended 250 ms ago, so it started 350 ms ago.
      final t = WindowsAudioLevels.mediaTimeOfWindow(
        nowUs: 10000000,
        endUs: 9750000,
        positionSec: 100.0,
        rate: 1.0,
      );
      expect(t, closeTo(99.65, 1e-9));
    });

    test('a second of wall clock is rate seconds of film', () {
      final t = WindowsAudioLevels.mediaTimeOfWindow(
        nowUs: 10000000,
        endUs: 9750000,
        positionSec: 100.0,
        rate: 2.0,
      );
      expect(t, closeTo(100.0 - 0.35 * 2, 1e-9));
    });

    test('a stamp from the future does not move the window ahead', () {
      final t = WindowsAudioLevels.mediaTimeOfWindow(
        nowUs: 10000000,
        endUs: 10200000,
        positionSec: 50.0,
        rate: 1.0,
      );
      expect(t, 50.0);
    });
  });

  group('stream', () {
    test('starts on the first listener and stops on the last', () async {
      final levels = make();
      final a = levels.levels.listen((_) {});
      final b = levels.levels.listen((_) {});
      await settle();
      expect(calls, ['start']);
      expect(eventListening, isTrue);

      await a.cancel();
      await settle();
      expect(calls, ['start']);

      await b.cancel();
      await settle();
      expect(calls, ['start', 'stop']);
      expect(eventListening, isFalse);
      levels.dispose();
    });

    test('a batch becomes samples in film time, in order', () async {
      final levels = make();
      final got = <AudioLevelSample>[];
      final sub = levels.levels.listen(got.add);
      await settle();

      position = const Duration(seconds: 60);
      // Windows ended 0.3, 0.2 and 0.1 s before now.
      sink!.success(
        batch(5000000, [4700000, 4800000, 4900000], [-40.0, -20.0, -30.0]),
      );
      await settle();

      expect(got.length, 3);
      expect(got[0].timeSec, closeTo(59.6, 1e-9));
      expect(got[1].timeSec, closeTo(59.7, 1e-9));
      expect(got[2].timeSec, closeTo(59.8, 1e-9));
      expect(got.map((s) => s.rmsDb), [-40.0, -20.0, -30.0]);
      await sub.cancel();
      levels.dispose();
    });

    test('drops a batch while paused or buffering', () async {
      final levels = make();
      final got = <AudioLevelSample>[];
      final sub = levels.levels.listen(got.add);
      await settle();

      position = const Duration(seconds: 30);
      playing = false;
      sink!.success(batch(5000000, [4900000], [-120.0]));
      await settle();
      expect(got, isEmpty);

      playing = true;
      sink!.success(batch(5300000, [5200000], [-25.0]));
      await settle();
      expect(got.length, 1);
      await sub.cancel();
      levels.dispose();
    });

    test('drops the batch after a seek, then carries on', () async {
      final levels = make();
      final got = <AudioLevelSample>[];
      final sub = levels.levels.listen(got.add);
      await settle();

      position = const Duration(seconds: 10);
      sink!.success(batch(1000000, [900000], [-30.0]));
      await settle();
      expect(got.length, 1);

      // 0.3 s later the film is 120 s further on: a seek.
      position = const Duration(seconds: 130);
      sink!.success(batch(1300000, [1200000], [-30.0]));
      await settle();
      expect(got.length, 1);

      // The next one follows on from the new position.
      position = const Duration(milliseconds: 130300);
      sink!.success(batch(1600000, [1500000], [-31.0]));
      await settle();
      expect(got.length, 2);
      expect(got.last.timeSec, closeTo(130.1, 1e-6));
      await sub.cancel();
      levels.dispose();
    });

    test('follows the playback speed when checking continuity', () async {
      final levels = make();
      final got = <AudioLevelSample>[];
      final sub = levels.levels.listen(got.add);
      await settle();

      rate = 2.0;
      position = const Duration(seconds: 10);
      sink!.success(batch(1000000, [900000], [-30.0]));
      await settle();
      // 0.3 s of wall clock is 0.6 s of film at double speed.
      position = const Duration(milliseconds: 10600);
      sink!.success(batch(1300000, [1200000], [-30.0]));
      await settle();
      expect(got.length, 2);
      await sub.cancel();
      levels.dispose();
    });

    test('skips malformed entries and windows before the film began', () async {
      final levels = make();
      final got = <AudioLevelSample>[];
      final sub = levels.levels.listen(got.add);
      await settle();

      position = const Duration(milliseconds: 200);
      sink!.success('nonsense');
      sink!.success(<String, Object>{'nowUs': 'x', 'endUs': [], 'db': []});
      sink!.success(<String, Object>{
        'nowUs': 5000000,
        'endUs': [4000000, 'bad', 4950000, 4990000],
        'db': [-30.0, -30.0, double.nan, -22.0],
      });
      await settle();
      // The first window started 1.1 s ago, before 0: skipped. The bad stamp
      // and the NaN level are skipped too. One sample is left.
      expect(got.length, 1);
      expect(got.single.rmsDb, -22.0);
      await sub.cancel();
      levels.dispose();
    });

    test('reports an unsupported Windows once and produces nothing', () async {
      startOutcome = PlatformException(code: 'unsupported');
      final levels = make();
      final got = <AudioLevelSample>[];
      final sub = levels.levels.listen(got.add);
      await settle();
      await settle();

      expect(unavailableCalls, 1);
      expect(got, isEmpty);
      await sub.cancel();
      levels.dispose();
    });

    test('a missing plugin is just unavailable', () async {
      messenger.setMockMethodCallHandler(method, null);
      final levels = make();
      final sub = levels.levels.listen((_) {});
      await settle();
      await settle();

      expect(unavailableCalls, 1);
      await sub.cancel();
      levels.dispose();
    });
  });
}
