/// The details page's primary action when the viewer has an unfinished
/// session for the title: it names where they stopped, resumes there, and the
/// episode it stopped on carries the progress.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/l10n/generated/app_localizations.dart';
import 'package:zplay/models/continue_watching/continue_watching_item.dart';
import 'package:zplay/models/movie/movie.dart';
import 'package:zplay/pages/details/details_page.dart';
import 'package:zplay/services/continue_watching/continue_watching_service.dart';
import 'package:zplay/services/layout/device_profile.dart';
import 'package:zplay/services/metadata/metadata_service.dart';
import 'package:zplay/widgets/common/pill_button.dart';

const _seriesMeta = '''
{"meta":{"id":"tt0903747","type":"series","name":"Breaking Bad",
 "releaseInfo":"2008",
 "description":"A chemistry teacher turns to crime.",
 "genres":["Crime","Drama"],
 "videos":[{"id":"tt0903747:1:1","season":1,"episode":1,"name":"Pilot"},
           {"id":"tt0903747:1:2","season":1,"episode":2,"name":"Cat's in the Bag"},
           {"id":"tt0903747:1:3","season":1,"episode":3,"name":"...And the Bag's in the River"}]}}''';

Movie _seriesRow() => Movie(
  id: 'tt0903747',
  name: 'Breaking Bad',
  type: 'series',
  addonBaseUrl: 'https://v3-cinemeta.strem.io',
  year: '2008',
);

/// Stopped at 12:40 of episode 3.
ContinueWatchingItem _session() => ContinueWatchingItem(
  id: 'tt0903747',
  title: 'Breaking Bad',
  type: 'series',
  season: 1,
  episode: 3,
  positionSeconds: 760,
  totalDurationSeconds: 2880,
  lastWatchedAt: DateTime(2026, 10, 1),
  isTorrent: false,
);

Future<void> _pump(WidgetTester tester, {Locale? locale}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: DetailsPage(movie: _seriesRow()),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
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
    DeviceProfile.debugSetTelevision(value: true);
  });

  tearDown(() {
    ContinueWatchingService.activeItems.value = [];
    MetadataService.client = http.Client();
    MetadataService.clearCache();
    DeviceProfile.debugSetTelevision(value: false);
  });

  testWidgets('without a session the page offers to start', (tester) async {
    await _pump(tester);
    expect(find.text('Play Episodes'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('a session turns the action into a resume, above the fold', (
    tester,
  ) async {
    ContinueWatchingService.activeItems.value = [_session()];
    await _pump(tester);

    final label = find.text('Resume E3 · 12:40');
    expect(label, findsOneWidget);
    final pill = find.ancestor(of: label, matching: find.byType(PillButton));
    expect(tester.getRect(pill).bottom, lessThanOrEqualTo(540.0));

    // The episode it stopped on says so, and only that one.
    expect(find.text('Watched to 12:40'), findsOneWidget);
  });

  testWidgets('a session that ends while the page is open drops the resume', (
    tester,
  ) async {
    ContinueWatchingService.activeItems.value = [_session()];
    await _pump(tester);
    expect(find.text('Resume E3 · 12:40'), findsOneWidget);

    ContinueWatchingService.activeItems.value = [];
    await tester.pump();
    expect(find.text('Play Episodes'), findsOneWidget);
    expect(find.text('Watched to 12:40'), findsNothing);
  });

  testWidgets('the resume reads in Chinese', (tester) async {
    ContinueWatchingService.activeItems.value = [_session()];
    await _pump(tester, locale: const Locale('zh'));

    expect(find.text('继续 第 3 集 · 12:40'), findsOneWidget);
    expect(find.text('看到 12:40'), findsOneWidget);
    expect(find.text('片单'), findsOneWidget);
  });
}
