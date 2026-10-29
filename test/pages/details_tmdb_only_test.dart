/// A title TMDb lists without an IMDb id still opens: the details come from
/// TMDb, with its episodes.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/movie/movie.dart';
import 'package:zplay/pages/details/details_page.dart';
import 'package:zplay/services/metadata/metadata_service.dart';
import 'package:zplay/services/metadata/tmdb_service.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TmdbService.buildTimeApiKeyOverrideForTesting = 'k';
    TmdbService.client = MockClient((r) async {
      final p = r.url.path;
      if (p.endsWith('/tv/297924/external_ids')) {
        return http.Response(jsonEncode({'imdb_id': 'tt99999999'}), 200);
      }
      if (p.endsWith('/external_ids')) {
        return http.Response(jsonEncode({'imdb_id': null}), 200);
      }
      if (p.endsWith('/tv/297923') || p.endsWith('/tv/297924')) {
        return _json({
          'name': '灵境行者',
          'overview': '少年闯入灵境。',
          'first_air_date': '2026-01-01',
          'seasons': [
            {'season_number': 1},
          ],
        });
      }
      if (p.endsWith('/tv/297923/season/1') ||
          p.endsWith('/tv/297924/season/1')) {
        return _json({
          'episodes': [
            {'season_number': 1, 'episode_number': 1, 'name': '第1集'},
            {'season_number': 1, 'episode_number': 2, 'name': '第2集'},
          ],
        });
      }
      return http.Response('{}', 404);
    });
    MetadataService.client = MockClient((_) async => http.Response('{}', 404));
  });

  tearDown(() {
    TmdbService.buildTimeApiKeyOverrideForTesting = null;
    TmdbService.client = http.Client();
    MetadataService.client = http.Client();
    MetadataService.clearCache();
  });

  testWidgets('opens from TMDb alone', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: DetailsPage(
          movie: Movie(
            id: 'tmdb:tv:297923',
            name: '灵境行者',
            type: 'series',
            addonBaseUrl: 'https://v3-cinemeta.strem.io',
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('灵境行者'), findsWidgets);
    expect(find.text('第1集'), findsWidgets);
  });

  testWidgets('falls back to TMDb when the addons do not know its IMDb id', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: DetailsPage(
          movie: Movie(
            id: 'tmdb:tv:297924',
            name: '灵境行者',
            type: 'series',
            addonBaseUrl: 'https://v3-cinemeta.strem.io',
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('第1集'), findsWidgets);
  });
  testWidgets('legacy CloudStream entries show an unsupported message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetailsPage(
          movie: Movie(
            id: 'cloudstream:old:example',
            name: 'Old entry',
            type: 'movie',
            addonBaseUrl: 'cloudstream',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('This source is no longer supported'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
