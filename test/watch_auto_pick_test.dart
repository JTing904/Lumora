/// The source list's "自动" pick, mounted on the real screen: it opens the
/// fastest source that answers, never one that does not, and a viewer's own
/// pick wins over it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/movie/movie_detail.dart';
import 'package:zplay/models/movie/video.dart';
import 'package:zplay/models/stream/stream_model.dart';
import 'package:zplay/pages/player/watch_screen.dart';
import 'package:zplay/services/theme/glass_settings.dart';

StreamSource _direct(String title) => StreamSource(
  name: title,
  title: '$title 1080p',
  url: 'https://cdn.example.test/$title.m3u8',
  addonName: 'Torrentio',
);

Widget _screen(List<StreamSource> sources, {bool autoPick = true}) =>
    MaterialApp(
      home: WatchScreen(
        detail: MovieDetail(
          id: 'tt0000001',
          type: 'series',
          name: 'A Show',
          year: '2026',
        ),
        selectedEpisode: Video(
          id: 'tt0000001:1:1',
          title: 'Pilot',
          season: 1,
          episode: 1,
          streams: sources,
        ),
        type: 'series',
        autoPick: autoPick,
      ),
    );

/// Runs out the screen's wait for the scrapers (20 s at most) and the probes.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  late bool glassWasEnabled;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    glassWasEnabled = GlassSettings.enabled.value;
    GlassSettings.enabled.value = false;
    WatchScreen.debugPlayerBuilderForTesting = (source) =>
        Scaffold(body: Center(child: Text('player:${source.name}')));
  });

  tearDown(() {
    GlassSettings.enabled.value = glassWasEnabled;
    WatchScreen.debugPlayerBuilderForTesting = null;
    WatchScreen.debugProbeForTesting = null;
  });

  testWidgets('auto opens the source that answers, skipping a dead one', (
    tester,
  ) async {
    WatchScreen.debugProbeForTesting = (s) async => s.name == 'alive';
    await tester.pumpWidget(_screen([_direct('dead'), _direct('alive')]));
    await _settle(tester);

    expect(find.text('player:alive'), findsOneWidget);
    expect(find.text('player:dead'), findsNothing);
  });

  testWidgets('with every probe failed, auto still plays the first link', (
    tester,
  ) async {
    // The probe fails links that play in the app's own libmpv, so a failed
    // probe orders the queue and the player's first-frame watch decides.
    WatchScreen.debugProbeForTesting = (_) async => false;
    await tester.pumpWidget(_screen([_direct('a'), _direct('b')]));
    await _settle(tester);

    expect(find.text('player:a'), findsOneWidget);
  });

  testWidgets('a failed probe does not grey the row out', (tester) async {
    WatchScreen.debugProbeForTesting = (_) async => false;
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_screen([_direct('a')], autoPick: false));
    await _settle(tester);

    expect(find.text("Can't connect"), findsNothing);
  });

  testWidgets('without auto, the list waits for the viewer', (tester) async {
    WatchScreen.debugProbeForTesting = (_) async => true;
    await tester.pumpWidget(_screen([_direct('a')], autoPick: false));
    await _settle(tester);

    expect(find.textContaining('player:'), findsNothing);
    expect(find.text('Auto (recommended)'), findsOneWidget);
  });
}
