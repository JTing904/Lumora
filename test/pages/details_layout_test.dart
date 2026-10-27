/// The new details page at the sizes Lumora runs at: nothing overflows, and
/// the episodes start on the first screen (the design keeps 选集 above the
/// fold, even on a television's 960x540).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/movie/movie.dart';
import 'package:zplay/pages/details/details_page.dart';
import 'package:zplay/services/layout/device_profile.dart';
import 'package:zplay/services/metadata/metadata_service.dart';
import 'package:zplay/ui/lu_focusable.dart';

const _seriesMeta = '''
{"meta":{"id":"tt0903747","type":"series","name":"Breaking Bad",
 "releaseInfo":"2008",
 "description":"A high school chemistry teacher diagnosed with inoperable lung cancer turns to manufacturing and selling methamphetamine in order to secure his family's future, and is drawn deeper into the drug trade with his former student.",
 "genres":["Crime","Drama","Thriller"],"imdbRating":"9.5",
 "videos":[
  {"id":"tt0903747:1:1","season":1,"episode":1,"name":"Pilot"},
  {"id":"tt0903747:1:2","season":1,"episode":2,"name":"Cat's in the Bag"},
  {"id":"tt0903747:1:3","season":1,"episode":3,"name":"And the Bag's in the River"},
  {"id":"tt0903747:2:1","season":2,"episode":1,"name":"Seven Thirty-Seven"}]}}''';

/// The real faces, so heights are what a viewer sees rather than the test
/// font's full-square glyphs.
Future<void> _loadFonts() async {
  for (final (family, files) in [
    ('NotoSansSC', ['400', '500', '700', '900']),
    ('Outfit', ['500', '600', '700']),
  ]) {
    final loader = FontLoader(family);
    for (final w in files) {
      loader.addFont(rootBundle.load('assets/fonts/lumora/$family-$w.ttf'));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MetadataService.clearCache();
    MetadataService.client = MockClient(
      (request) async => http.Response(
        _seriesMeta,
        200,
        headers: const {'content-type': 'application/json'},
      ),
    );
  });

  tearDown(() {
    MetadataService.client = http.Client();
    MetadataService.clearCache();
    DeviceProfile.debugSetTelevision(value: false);
  });

  const sizes = <String, (Size, double, bool)>{
    'desktop 1440x900': (Size(1440, 900), 1, false),
    'desktop 1920x1080': (Size(1920, 1080), 1, false),
    'phone 390x844': (Size(390, 844), 3, false),
    'television 960x540': (Size(960, 540), 2, true),
  };

  for (final entry in sizes.entries) {
    testWidgets('${entry.key}: fits, episodes on the first screen', (
      tester,
    ) async {
      final (size, dpr, tv) = entry.value;
      DeviceProfile.debugSetTelevision(value: tv);
      tester.view.physicalSize = size * dpr;
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: DetailsPage(
            movie: Movie(
              id: 'tt0903747',
              name: 'Breaking Bad',
              type: 'series',
              addonBaseUrl: 'https://v3-cinemeta.strem.io',
            ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(tester.takeException(), isNull);
      expect(find.text('Breaking Bad'), findsOneWidget);
      final episode = find.text('Pilot');
      expect(episode, findsOneWidget);
      final card = find
          .ancestor(of: episode, matching: find.byType(LuFocusable))
          .first;
      expect(
        tester.getRect(card).top,
        lessThan(size.height - 80),
        reason: 'the episode row starts on the first screen',
      );
    });
  }
}
