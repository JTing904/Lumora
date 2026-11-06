import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/player/engine/audio_level.dart';
import 'package:zplay/services/player/engine/exo_player_engine.dart';
import 'package:zplay/services/player/engine/video_engine.dart';

/// The Media3 bridge is a platform channel, so these tests pin the contract
/// between the Dart engine and the Kotlin side: the method names it invokes and
/// the shape of the events it expects back.
///
/// That contract has already broken once, and the failure was silent. A method
/// name that does not exist on the native side throws a MissingPluginException
/// at playback time, on a device, with no test failing. Pinning both directions
/// here is what makes the next rename loud.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  const MethodChannel channel = MethodChannel(
    'io.github.tzero86.zplay/exo_player',
  );
  const EventChannel eventChannel = EventChannel(
    'io.github.tzero86.zplay/exo_player/events',
  );

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// The view id must match `ExoPlayerBridge.VIEW_ID` in Kotlin. These are two
  /// constants in two languages that nothing else ties together.
  test('the platform view id matches the native bridge', () {
    expect(ExoPlayerEngine.viewType, 'io.github.tzero86.zplay/exo_surface');
  });

  test('open sends url, headers and the resume offset', () async {
    final ExoPlayerEngine engine = ExoPlayerEngine();
    addTearDown(engine.dispose);

    await engine.open(
      const EngineRequest(
        url: 'https://cdn.example/movie.mkv',
        headers: <String, String>{'Referer': 'https://example.com'},
        start: Duration(minutes: 12),
      ),
    );

    final MethodCall load = calls.firstWhere(
      (MethodCall c) => c.method == 'load',
    );
    final Map<Object?, Object?> args = load.arguments as Map<Object?, Object?>;
    expect(args['url'], 'https://cdn.example/movie.mkv');
    expect(
      (args['headers'] as Map<Object?, Object?>)['Referer'],
      'https://example.com',
    );
    expect(args['startMs'], 12 * 60 * 1000);
  });

  test(
    'open refuses a torrent rather than failing slowly on the device',
    () async {
      final ExoPlayerEngine engine = ExoPlayerEngine();
      addTearDown(engine.dispose);

      await expectLater(
        engine.open(
          const EngineRequest(url: 'http://127.0.0.1:8080/s', isTorrent: true),
        ),
        throwsA(isA<EngineUnsupported>()),
      );
      // The refusal has to happen before the channel is touched, so the other
      // engine can take over in the same tick.
      expect(calls.where((MethodCall c) => c.method == 'load'), isEmpty);
    },
  );

  test('transport and selection map to distinct native methods', () async {
    final ExoPlayerEngine engine = ExoPlayerEngine();
    addTearDown(engine.dispose);

    await engine.play();
    await engine.pause();
    await engine.playOrPause();
    await engine.seek(const Duration(seconds: 45));
    await engine.setRate(1.5);
    await engine.setVolume(0.4);
    await engine.setSubtitlesVisible(false);
    await engine.setAudioTrack(null);
    await engine.setSubtitleTrack(null);

    expect(
      calls.map((MethodCall c) => c.method),
      containsAll(<String>[
        'play',
        'pause',
        'playOrPause',
        'seek',
        'setRate',
        'setVolume',
        'setSubtitlesVisible',
        'selectAudioTrack',
        'selectSubtitleTrack',
      ]),
    );

    final MethodCall seek = calls.firstWhere(
      (MethodCall c) => c.method == 'seek',
    );
    expect((seek.arguments as Map<Object?, Object?>)['positionMs'], 45000);
  });

  test('the intent to play follows play and pause, not buffering', () async {
    final ExoPlayerEngine engine = ExoPlayerEngine();
    addTearDown(engine.dispose);

    await engine.open(const EngineRequest(url: 'https://cdn.example/a.mp4'));
    expect(engine.playWhenReady, isTrue);
    await engine.pause();
    expect(engine.playWhenReady, isFalse);
    await engine.playOrPause();
    expect(engine.playWhenReady, isTrue);
    // Still buffering, so `playing` says false; the viewer's intent stands.
    expect(engine.state.playing, isFalse);
    await engine.play();
    expect(engine.playWhenReady, isTrue);
  });

  test('the state carries the speed last asked for', () async {
    final ExoPlayerEngine engine = ExoPlayerEngine();
    addTearDown(engine.dispose);

    // Media3 sends no speed event, so a 2x hold used to read 1.0 back and
    // restore the viewer's 1.5x to 1x when the finger lifted.
    await engine.setRate(1.5);
    expect(engine.state.rate, 1.5);
  });

  test(
    'a missing native bridge is an unsupported engine, not a crash',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      final ExoPlayerEngine engine = ExoPlayerEngine();
      addTearDown(engine.dispose);

      await expectLater(engine.play(), throwsA(isA<EngineUnsupported>()));
    },
  );

  test('a fresh engine reports no decoded size, so the watchdog can tell', () {
    final ExoPlayerEngine engine = ExoPlayerEngine();
    addTearDown(engine.dispose);

    // Null rather than zero: this is the only signal that distinguishes a
    // stream that is decoding from one that is decoding without rendering,
    // which is the failure the first spike had.
    expect(engine.state.decodedWidth, isNull);
    expect(engine.state.decodedHeight, isNull);
  });

  group('audio levels', () {
    MockStreamHandlerEventSink? sink;

    setUp(() {
      sink = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            eventChannel,
            MockStreamHandler.inline(
              onListen: (Object? arguments, MockStreamHandlerEventSink events) {
                sink = events;
              },
            ),
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(eventChannel, null);
    });

    List<Object?> enableCalls() => calls
        .where((MethodCall c) => c.method == 'setAudioLevelsEnabled')
        .map(
          (MethodCall c) => (c.arguments as Map<Object?, Object?>)['enabled'],
        )
        .toList();

    test(
      'measuring starts with the first listener and stops with the last',
      () async {
        final ExoPlayerEngine engine = ExoPlayerEngine();
        addTearDown(engine.dispose);

        // Nothing is measured while nobody is listening.
        expect(enableCalls(), isEmpty);

        final StreamSubscription<AudioLevelSample> first = engine.audioLevels
            .listen((_) {});
        await Future<void>.delayed(Duration.zero);
        expect(enableCalls(), <Object?>[true]);

        // A second listener shares the measurement instead of restarting it.
        final StreamSubscription<AudioLevelSample> second = engine.audioLevels
            .listen((_) {});
        await Future<void>.delayed(Duration.zero);
        expect(enableCalls(), <Object?>[true]);

        await first.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(enableCalls(), <Object?>[true]);

        await second.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(enableCalls(), <Object?>[true, false]);
      },
    );

    test('a batched event becomes one sample per pair', () async {
      final ExoPlayerEngine engine = ExoPlayerEngine();
      addTearDown(engine.dispose);
      engine.start();
      await Future<void>.delayed(Duration.zero);

      final List<AudioLevelSample> got = <AudioLevelSample>[];
      final StreamSubscription<AudioLevelSample> sub = engine.audioLevels
          .listen(got.add);
      addTearDown(sub.cancel);

      sink!.success(<String, Object?>{
        'type': 'audioLevels',
        't': <double>[12.0, 12.1, 12.2],
        'db': <double>[-40.5, -22.0, -18.25],
      });
      await Future<void>.delayed(Duration.zero);

      expect(got.map((AudioLevelSample s) => s.timeSec), <double>[
        12.0,
        12.1,
        12.2,
      ]);
      expect(got.map((AudioLevelSample s) => s.rmsDb), <double>[
        -40.5,
        -22.0,
        -18.25,
      ]);
    });

    test(
      'a ragged or malformed batch keeps only the pairs that make sense',
      () async {
        final ExoPlayerEngine engine = ExoPlayerEngine();
        addTearDown(engine.dispose);
        engine.start();
        await Future<void>.delayed(Duration.zero);

        final List<AudioLevelSample> got = <AudioLevelSample>[];
        final StreamSubscription<AudioLevelSample> sub = engine.audioLevels
            .listen(got.add);
        addTearDown(sub.cancel);

        sink!.success(<String, Object?>{
          'type': 'audioLevels',
          // One more time than levels, and a value that is not a number.
          't': <Object?>[1.0, 'x', 3.0, 4.0],
          'db': <Object?>[-30.0, -20.0, double.nan],
        });
        sink!.success(<String, Object?>{'type': 'audioLevels', 't': 5});
        await Future<void>.delayed(Duration.zero);

        expect(got, hasLength(1));
        expect(got.single.timeSec, 1.0);
        expect(got.single.rmsDb, -30.0);
      },
    );

    test('level events leave the playback state alone', () async {
      final ExoPlayerEngine engine = ExoPlayerEngine();
      addTearDown(engine.dispose);
      engine.start();
      await Future<void>.delayed(Duration.zero);
      final EngineState before = engine.state;

      sink!.success(<String, Object?>{
        'type': 'audioLevels',
        't': <double>[1.0],
        'db': <double>[-20.0],
      });
      sink!.success(<String, Object?>{'type': 'isPlaying', 'value': true});
      await Future<void>.delayed(Duration.zero);

      expect(before.playing, isFalse);
      expect(engine.state.playing, isTrue);
    });
  });
}
