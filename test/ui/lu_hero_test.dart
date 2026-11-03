/// The hero carousel on a phone: the slide itself opens the details, since
/// there is no room for 详情 beside 播放 and 加入收藏.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/movie/movie.dart';
import 'package:zplay/pages/details/details_page.dart';
import 'package:zplay/services/metadata/metadata_service.dart';
import 'package:zplay/ui/lu_hero.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MetadataService.clearCache();
    MetadataService.client = MockClient((_) async => http.Response('{}', 404));
  });

  tearDown(() {
    MetadataService.client = http.Client();
    MetadataService.clearCache();
  });

  testWidgets('tapping a phone slide opens its details', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              LuHeroCarousel(
                movies: [
                  Movie(
                    id: 'tt0903747',
                    name: 'Breaking Bad',
                    type: 'series',
                    addonBaseUrl: 'https://v3-cinemeta.strem.io',
                  ),
                ],
                phone: true,
                pad: 16,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('More Info'), findsNothing);

    await tester.tap(find.text('Breaking Bad'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(DetailsPage), findsOneWidget);

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  });
}
