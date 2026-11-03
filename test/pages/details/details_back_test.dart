/// The details page's way back: Esc and the mouse's back button close it,
/// and the back button stays at the top-left while the page scrolls.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/movie/movie.dart';
import 'package:zplay/pages/details/details_page.dart';
import 'package:zplay/services/metadata/metadata_service.dart';

const _meta = '''
{"meta":{"id":"tt0903747","type":"series","name":"Breaking Bad",
 "releaseInfo":"2008","description":"A chemistry teacher turns to crime.",
 "videos":[
  {"id":"tt0903747:1:1","season":1,"episode":1,"name":"Pilot"},
  {"id":"tt0903747:1:2","season":1,"episode":2,"name":"Two"},
  {"id":"tt0903747:1:3","season":1,"episode":3,"name":"Three"}]}}''';

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DetailsPage(
                  movie: Movie(
                    id: 'tt0903747',
                    name: 'Breaking Bad',
                    type: 'series',
                    addonBaseUrl: 'https://v3-cinemeta.strem.io',
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(find.byType(DetailsPage), findsOneWidget);
}

/// Runs the closing transition through, frame by frame.
Future<void> _pumpClosed(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Lets the page's own lookups finish so no timer outlives the test.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MetadataService.clearCache();
    MetadataService.client = MockClient(
      (request) async => http.Response(
        _meta,
        200,
        headers: const {'content-type': 'application/json'},
      ),
    );
  });

  tearDown(() {
    MetadataService.client = http.Client();
    MetadataService.clearCache();
  });

  testWidgets('Esc closes the page', (tester) async {
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _pumpClosed(tester);
    expect(find.byType(DetailsPage), findsNothing);
    await _settle(tester);
  });

  testWidgets("the mouse's back button closes the page", (tester) async {
    await _open(tester);
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kBackMouseButton,
    );
    await gesture.down(const Offset(640, 500));
    await gesture.up();
    await _pumpClosed(tester);
    expect(find.byType(DetailsPage), findsNothing);
    await _settle(tester);
  });

  testWidgets('the back button stays put while the page scrolls', (
    tester,
  ) async {
    await _open(tester);
    final back = find.bySemanticsLabel('Go Back');
    expect(back, findsOneWidget);
    final before = tester.getRect(back);
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -400),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getRect(back), before);
    await tester.tap(back);
    await _pumpClosed(tester);
    expect(find.byType(DetailsPage), findsNothing);
    await _settle(tester);
  });
}
