/// Books and a book's sheet lay out on a phone without overflow, and the
/// sheet's round actions stand as tall as the read button beside them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/book/book_result.dart';
import 'package:zplay/pages/books/book_detail_sheet.dart';
import 'package:zplay/pages/books/books_page.dart';
import 'package:zplay/pages/books/widgets/lu_reading_kit.dart';
import 'package:zplay/ui/lu_button.dart';

const _book = BookResult(
  title: 'A Rather Long Book Title That Wraps Onto Several Lines',
  author: 'An Author With A Long Name',
  md5: 'md5-phone-layout',
  link: '',
  bookImage: '',
  bookFiletype: 'epub',
  bookSize: '2.4 MB',
  year: '2019',
  bookLang: 'English',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in const [Size(360, 740), Size(411, 860)]) {
    testWidgets('Books lays out at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BooksPage())),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a book sheet balances its actions at '
        '${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: BookDetailSheet(book: _book),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Rendered heights, focus padding included, so the row lines up.
      final buttonHeight = tester.getSize(find.byType(LuButton).first).height;
      final glyphs = find.byType(LuGlyphButton);
      expect(glyphs, findsWidgets);
      for (var i = 0; i < tester.widgetList(glyphs).length; i++) {
        expect(tester.getSize(glyphs.at(i)).height, buttonHeight);
      }
    });
  }
}
