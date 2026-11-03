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

  group('page', () {
    test('the last page is the one total_pages names', () {
      expect(
        TmdbCatalog.isLastPage(page: 3, totalPages: 7, results: 20),
        isFalse,
      );
      expect(
        TmdbCatalog.isLastPage(page: 7, totalPages: 7, results: 20),
        isTrue,
      );
      // Ten titles on a page is not the end when TMDb says more follow:
      // the grid used to stop there, or after page ten.
      expect(
        TmdbCatalog.isLastPage(page: 11, totalPages: 40, results: 9),
        isFalse,
      );
    });

    test('without total_pages a short or empty page is the end', () {
      expect(
        TmdbCatalog.isLastPage(page: 2, totalPages: null, results: 20),
        isFalse,
      );
      expect(
        TmdbCatalog.isLastPage(page: 2, totalPages: null, results: 19),
        isTrue,
      );
      expect(
        TmdbCatalog.isLastPage(page: 2, totalPages: 9, results: 0),
        isTrue,
      );
    });

    test('a failure is null; an empty page past the end is the end', () async {
      var fail = true;
      TmdbService.client = MockClient((req) async {
        if (fail) return http.Response('', 503);
        return http.Response(
          jsonEncode({'page': 6, 'results': [], 'total_pages': 5}),
          200,
        );
      });
      const query = TmdbQuery('/discover/tv', {'page': '6', 'n': 'end-test'});
      expect(await TmdbCatalog.page(query, resolveImdb: false), isNull);
      fail = false;
      final page = await TmdbCatalog.page(query, resolveImdb: false);
      expect(page?.movies, isEmpty);
      expect(page?.last, isTrue);
    });

    test('a page reads its number from the query', () async {
      TmdbService.client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'page': int.parse(req.url.queryParameters['page']!),
            'results': [
              for (var i = 0; i < 20; i++) {'id': i + 1, 'name': 'Show $i'},
            ],
            'total_pages': 3,
          }),
          200,
        );
      });
      Future<bool?> last(int n) async => (await TmdbCatalog.page(
        TmdbQuery('/discover/tv', {'page': '$n', 'n': 'number-test'}),
        resolveImdb: false,
      ))?.last;
      expect(await last(2), isFalse);
      expect(await last(3), isTrue);
    });
  });

  group('seasonsToRead', () {
    test('specials are skipped and the newest seasons kept', () {
      expect(TmdbCatalog.seasonsToRead([0, 1, 2, 3]), [1, 2, 3]);
      final long = [0, for (var n = 1; n <= 20; n++) n];
      expect(TmdbCatalog.seasonsToRead(long), [
        for (var n = 9; n <= 20; n++) n,
      ]);
    });
  });
}
