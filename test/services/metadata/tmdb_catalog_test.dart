import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/movie/movie.dart';
import 'package:zplay/services/metadata/tmdb_catalog.dart';
import 'package:zplay/services/metadata/tmdb_service.dart';

Movie _movie(String id, String type) =>
    Movie(id: id, name: 'x', type: type, addonBaseUrl: '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TmdbService.buildTimeApiKeyOverrideForTesting = 'test-key';
    await TmdbService.initialize();
  });

  tearDown(() {
    TmdbService.buildTimeApiKeyOverrideForTesting = null;
    TmdbService.client = http.Client();
  });

  group('tmdbRef', () {
    test('reads tmdb:kind:id and a bare id with a known type', () {
      expect(TmdbCatalog.tmdbRef(_movie('tmdb:tv:12', 'series')), (
        kind: 'tv',
        id: 12,
      ));
      expect(TmdbCatalog.tmdbRef(_movie('tmdb:34', 'movie')), (
        kind: 'movie',
        id: 34,
      ));
      expect(TmdbCatalog.tmdbRef(_movie('tmdb:34', 'series')), (
        kind: 'tv',
        id: 34,
      ));
    });

    test('rejects what it cannot tell', () {
      expect(TmdbCatalog.tmdbRef(_movie('tmdb:34', '')), isNull);
      expect(TmdbCatalog.tmdbRef(_movie('tmdb:person:34', 'movie')), isNull);
      expect(TmdbCatalog.tmdbRef(_movie('tmdb:tv:abc', 'series')), isNull);
    });

    test('resolve gives null for a malformed tmdb id', () async {
      TmdbService.client = MockClient((_) async => http.Response('{}', 200));
      expect(await TmdbCatalog.resolve(_movie('tmdb:34', '')), isNull);
      final other = _movie('tt123', 'movie');
      expect(await TmdbCatalog.resolve(other), same(other));
    });
  });

  group('row', () {
    test('a failed read is not cached, and people are skipped', () async {
      var fail = true;
      TmdbService.client = MockClient((req) async {
        if (fail) return http.Response('', 503);
        return http.Response(
          jsonEncode({
            'results': [
              {'id': 1, 'media_type': 'person', 'name': 'Someone'},
              {'id': 2, 'media_type': 'tv', 'name': 'Show'},
            ],
          }),
          200,
        );
      });
      const query = TmdbQuery('/trending/all/day', {'n': 'cache-test'});
      expect(await TmdbCatalog.row(query, resolveImdb: false), isEmpty);
      fail = false;
      final row = await TmdbCatalog.row(query, resolveImdb: false);
      expect(row.map((m) => m.id), ['tmdb:tv:2']);
    });

    test('a failed id lookup is asked again', () async {
      var fail = true;
      TmdbService.client = MockClient((req) async {
        if (fail) return http.Response('', 503);
        return http.Response(jsonEncode({'imdb_id': 'tt0000099'}), 200);
      });
      final movie = _movie('tmdb:movie:99', 'movie');
      expect(await TmdbCatalog.resolve(movie), isNull);
      fail = false;
      expect((await TmdbCatalog.resolve(movie))?.id, 'tt0000099');
    });
  });
}
