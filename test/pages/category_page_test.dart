import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/pages/category/category_page.dart';
import 'package:zplay/services/metadata/tmdb_service.dart';
import 'package:zplay/ui/lu_cards.dart';

/// Every TMDb list answers with the same eight titles.
List<Map<String, Object?>> _results() => [
  for (var i = 1; i <= 8; i++)
    {
      'id': 100 + i,
      'name': '港剧 $i',
      'first_air_date': '2024-01-0$i',
      'overview': '第 $i 部的简介',
      'poster_path': '/p$i.jpg',
      'backdrop_path': '/b$i.jpg',
      'vote_average': 7.5,
    },
];

void main() {
  late List<String> paths;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    paths = [];
    TmdbService.buildTimeApiKeyOverrideForTesting = 'test-key';
    TmdbService.client = MockClient((request) async {
      paths.add(request.url.path);
      return http.Response(
        jsonEncode({'results': _results()}),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
  });

  tearDown(() {
    TmdbService.buildTimeApiKeyOverrideForTesting = null;
    TmdbService.client = http.Client();
  });

  testWidgets('rows of one kind under a featured title', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CategoryPage(kind: CategoryKind.series))),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(LuRail), findsWidgets);
    expect(find.text('Trending series'), findsOneWidget);
    // The featured title: name, synopsis and its two actions.
    expect(find.text('港剧 1'), findsWidgets);
    expect(find.text('第 1 部的简介'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Add to My List'), findsOneWidget);
  });

  testWidgets('a row costs one request, not one per title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CategoryPage(kind: CategoryKind.anime))),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(paths.where((p) => p.contains('external_ids')), isEmpty);
    expect(paths.length, 6, reason: 'six anime rows, one list request each');
  });
}
