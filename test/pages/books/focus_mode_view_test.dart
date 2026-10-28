/// Focus mode sits inside the book reader's route, so a remote's or Android's
/// Back there must leave focus mode, not close the whole book.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zplay/pages/books/widgets/focus_mode_view.dart';
import 'package:zplay/services/books/epub_parser_service.dart';
import 'package:zplay/services/books/reader_settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'zplay_seen_focus_coach_v2': true});
  });

  testWidgets('Back exits focus mode and keeps the book open', (tester) async {
    const chapter = EpubChapterData(
      id: 'c1',
      title: 'One',
      href: 'c1.xhtml',
      htmlContent: '<p>First line of the chapter.</p><p>Second one.</p>',
      orderIndex: 0,
    );
    const book = EpubBookData(
      title: 'Book',
      author: 'Author',
      chapters: [chapter],
      tableOfContents: [],
      images: {},
    );
    var exits = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('library')),
        routes: {
          '/reader': (_) => FocusModeView(
            book: book,
            chapter: chapter,
            settings: const ReaderSettingsData(focusModeActive: true),
            onExit: () => exits++,
          ),
        },
      ),
    );
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/reader');
    await tester.pumpAndSettle();
    expect(find.byType(FocusModeView), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(exits, 1);
    expect(find.byType(FocusModeView), findsOneWidget);
  });
}
