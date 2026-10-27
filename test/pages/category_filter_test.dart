import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/pages/category/category_filter.dart';
import 'package:zplay/pages/category/category_page.dart';
import 'package:zplay/services/metadata/tmdb_service.dart';
import 'package:zplay/ui/lu_cards.dart';

void main() {
  final now = DateTime(2026, 10, 27);

  group('the query a choice makes', () {
    test('香港 喜剧 2024, newest first, for 电视剧', () {
      const f = CategoryFilter(
        region: 'HK',
        genre: '35',
        years: '2024',
        sort: FilterSort.newest,
      );
      final q = f.query(CategoryKind.series, page: 2, now: now);
      expect(q.path, '/discover/tv');
      expect(q.params, containsPair('with_origin_country', 'HK'));
      expect(q.params, containsPair('with_genres', '35'));
      expect(q.params, containsPair('without_genres', '16,10764,10767'));
      expect(q.params, containsPair('first_air_date.gte', '2024-01-01'));
      expect(q.params, containsPair('first_air_date.lte', '2024-12-31'));
      expect(q.params, containsPair('sort_by', 'first_air_date.desc'));
      expect(q.params, containsPair('page', '2'));
    });

    test('动漫 stays animation from China, Japan and Korea', () {
      final q = const CategoryFilter(genre: '10765')
          .query(CategoryKind.anime, now: now);
      expect(q.params, containsPair('with_genres', '16,10765'));
      expect(q.params, containsPair('with_origin_country', 'CN|JP|KR'));
      expect(q.params.containsKey('without_genres'), isFalse);
    });

    test('电影 by rating, nothing not yet released', () {
      final q = const CategoryFilter(sort: FilterSort.rating)
          .query(CategoryKind.movies, now: now);
      expect(q.path, '/discover/movie');
      expect(q.params, containsPair('vote_count.gte', '100'));
      expect(q.params, containsPair('primary_release_date.lte', '2026-10-27'));
    });
  });

  testWidgets('picking a region swaps the rows for a grid of results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final queries = <Map<String, String>>[];
    TmdbService.buildTimeApiKeyOverrideForTesting = 'test-key';
    TmdbService.client = MockClient((request) async {
      queries.add(request.url.queryParameters);
      return http.Response(
        jsonEncode({
          'results': [
            for (var i = 1; i <= 20; i++)
              {
                'id': 500 + i,
                'name': '剧 $i',
                'first_air_date': '2024-01-01',
                'poster_path': '/p$i.jpg',
                'backdrop_path': '/b$i.jpg',
              },
          ],
        }),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
    addTearDown(() {
      TmdbService.buildTimeApiKeyOverrideForTesting = null;
      TmdbService.client = http.Client();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CategoryPage(kind: CategoryKind.series)),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(LuRail), findsWidgets);

    await tester.tap(find.text('Filter'));
    await tester.pump();
    expect(find.byType(CategoryFilterPanel), findsOneWidget);

    await tester.tap(find.text('Hong Kong'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(CategoryFilterResults), findsOneWidget);
    expect(find.byType(LuRail), findsNothing);
    expect(
      queries.any((q) => q['with_origin_country'] == 'HK' && q['page'] == '1'),
      isTrue,
    );

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.byType(CategoryFilterResults), findsNothing);
  });
}
