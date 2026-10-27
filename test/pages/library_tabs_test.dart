/// 我的收藏: two tabs, 收藏 and 下载, that swap the page under them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/pages/downloads/downloads_page.dart';
import 'package:zplay/pages/library/library_page.dart';
import 'package:zplay/pages/my_list/my_list_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the tabs switch between the list and the downloads', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LibraryPage())),
    );
    await tester.pump();

    expect(find.text('My List'), findsWidgets);
    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, 0);
    expect(find.byType(MyListPage), findsOneWidget);

    await tester.tap(find.text('Downloads'));
    await tester.pump();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
    expect(find.byType(DownloadsPage, skipOffstage: false), findsOneWidget);
  });
}
