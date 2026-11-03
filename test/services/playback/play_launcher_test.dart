/// [PlayLauncher]: a tap answers at once, a second tap while the first is
/// still working opens nothing more, and 播放 on a series carries on from the
/// last episode finished.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/movie/movie.dart';
import 'package:zplay/models/movie/movie_detail.dart';
import 'package:zplay/models/movie/video.dart';
import 'package:zplay/pages/details/details_page.dart';
import 'package:zplay/services/continue_watching/watched_episodes.dart';
import 'package:zplay/services/metadata/metadata_service.dart';
import 'package:zplay/services/playback/play_launcher.dart';

Movie _row() => Movie(
  id: 'tt0903747',
  name: 'Breaking Bad',
  type: 'series',
  addonBaseUrl: 'https://v3-cinemeta.strem.io',
  year: '2008',
);

/// A bare page, and the context to call the launcher from.
Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext host;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          host = context;
          return const SizedBox.expand();
        },
      ),
    ),
  );
  return host;
}

/// Lets the details page finish its lookups and drops the tree, so no timer
/// of its is left running when the test ends.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  late Completer<void> gate;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MetadataService.clearCache();
    gate = Completer<void>();
    // Every metadata read waits on [gate], so a test decides how long a
    // launch is in flight. Nothing is found, which sends 播放 to the details.
    MetadataService.client = MockClient((request) async {
      await gate.future;
      return http.Response('{}', 404);
    });
  });

  tearDown(() {
    if (!gate.isCompleted) gate.complete();
    MetadataService.client = http.Client();
    MetadataService.clearCache();
    WatchedEpisodes.shows.value = {};
  });

  testWidgets('details open at once, and only once for a double tap', (
    tester,
  ) async {
    final host = await _pumpHost(tester);
    PlayLauncher.openDetails(host, _row());
    PlayLauncher.openDetails(host, _row());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    // Before any lookup has answered.
    expect(find.byType(DetailsPage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    PlayLauncher.openDetails(host, _row());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DetailsPage, skipOffstage: false), findsOneWidget);
    gate.complete();
    await _settle(tester);
  });

  testWidgets('a second 播放 while the first is in flight is ignored', (
    tester,
  ) async {
    final host = await _pumpHost(tester);
    final row = _row();
    final first = PlayLauncher.play(host, row);
    expect(PlayLauncher.launching.value, same(row));
    unawaited(PlayLauncher.play(host, _row()));
    PlayLauncher.openDetails(host, _row());
    await tester.pump();
    expect(find.byType(DetailsPage), findsNothing);

    gate.complete();
    // The lookup's own retries run on timers, which only move as the test
    // pumps.
    for (var i = 0; i < 300 && PlayLauncher.launching.value != null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await first;
    expect(PlayLauncher.launching.value, isNull);
    expect(find.byType(DetailsPage, skipOffstage: false), findsOneWidget);
    await _settle(tester);
  });

  group('startEpisode', () {
    MovieDetail detail() => MovieDetail(
      id: 'tt0903747',
      type: 'series',
      name: 'Breaking Bad',
      videos: [
        Video(id: 'sp', title: 'Special', season: 0, episode: 1),
        Video(id: 'e3', title: 'E3', season: 1, episode: 3),
        Video(id: 'e1', title: 'E1', season: 1, episode: 1),
        Video(id: 'e2', title: 'E2', season: 1, episode: 2),
        Video(id: 's2e1', title: 'S2E1', season: 2, episode: 1),
      ],
    );

    test('a new series starts at its first real episode', () {
      expect(PlayLauncher.startEpisode(detail())?.id, 'e1');
    });

    test('a series in progress goes on after the last one finished', () {
      WatchedEpisodes.shows.value = {
        'tt0903747': ['1:1', '1:2'],
      };
      expect(PlayLauncher.startEpisode(detail())?.id, 'e3');
      WatchedEpisodes.shows.value = {
        'tt0903747': ['1:3'],
      };
      expect(PlayLauncher.startEpisode(detail())?.id, 's2e1');
    });
  });
}
