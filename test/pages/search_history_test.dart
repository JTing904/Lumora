/// Typing searches as it goes, but only a search the viewer meant is kept
/// in 最近搜索: "hen", "hent", "henta" are not searches anybody made.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/pages/search/search_page.dart';

void main() {
  testWidgets('typing is not remembered; Enter is', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'supe');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.enterText(find.byType(TextField), 'superman');
    await tester.pump(const Duration(milliseconds: 700));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('search_history') ?? const [], isEmpty);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('search_history'), ['superman']);
  });
}
