/// The EPUB reader only scrolls, so the customisation sheet offers no
/// paginated mode, and a stored paginated value loads as scroll.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/pages/books/widgets/reader_customization_sheet.dart';
import 'package:zplay/services/books/reader_settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReaderSettings.settingsNotifier.value = const ReaderSettingsData();
  });

  for (final size in const [Size(360, 740), Size(1280, 800)]) {
    testWidgets(
      'the layout tab offers no reading mode at ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: ReaderCustomizationSheet())),
        );
        await tester.pump();
        await tester.tap(find.text('Layout'));
        await tester.pumpAndSettle();

        expect(find.text('Page Margins'), findsOneWidget);
        expect(find.text('Paginated Turns'), findsNothing);
        expect(find.text('Reading Mode'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('a stored paginated mode loads as scroll', () async {
    SharedPreferences.setMockInitialValues({
      'zplay_reader_settings_v3': jsonEncode(<String, dynamic>{
        'fontSize': 20.0,
        'mode': 'paginated',
      }),
    });

    await ReaderSettings.init();

    expect(ReaderSettings.current.fontSize, 20.0);
    expect(ReaderSettings.current.mode, ReaderMode.scroll);
    expect(ReaderMode.values.byName('paginated'), ReaderMode.paginated);
  });

  test('paginated is never stored', () {
    ReaderSettings.updateMode(ReaderMode.paginated);
    expect(ReaderSettings.current.mode, ReaderMode.scroll);
  });
}
