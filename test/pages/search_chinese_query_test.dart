/// A query typed in Chinese reaches TMDb in Chinese: the addons know titles
/// by their English names, so 庆余年 found next to nothing through them.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/pages/search/search_page.dart';
import 'package:zplay/services/metadata/tmdb_service.dart';

void main() {
  late List<Uri> asked;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    asked = [];
    TmdbService.buildTimeApiKeyOverrideForTesting = 'test-key';
    TmdbService.client = MockClient((request) async {
      asked.add(request.url);
      final path = request.url.path;
      final Object body = path.endsWith('/external_ids')
          ? {'imdb_id': 'tt9055008'}
          : path.contains('/search/multi')
          ? {
              'results': [
                {
                  'id': 94664,
                  'media_type': 'tv',
                  'name': '庆余年',
                  'first_air_date': '2019-11-26',
                  'poster_path': '/q.jpg',
                },
                {'id': 1, 'media_type': 'person', 'name': '张若昀'},
              ],
            }
          : {'results': []};
      return http.Response(
        jsonEncode(body),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
  });

  tearDown(() {
    TmdbService.buildTimeApiKeyOverrideForTesting = null;
    TmdbService.client = http.Client();
  });

  testWidgets('庆余年 is found through TMDb', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '庆余年');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final multi = asked.where((u) => u.path.contains('/search/multi'));
    expect(multi, isNotEmpty);
    expect(multi.first.queryParameters['query'], '庆余年');
    expect(find.text('庆余年'), findsWidgets);
  });

  testWidgets('an English query does not ask TMDb search', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Joy of Life');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(asked.where((u) => u.path.contains('/search/multi')), isEmpty);
  });
}
