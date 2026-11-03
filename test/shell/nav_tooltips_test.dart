/// Guards that the top bar does not echo a destination's visible name in a
/// tooltip: hovering or clicking 电视剧 put a second "电视剧" right under it.
/// The search and 我的 discs show no name, so they keep theirs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/shell/app_shell.dart';
import 'package:zplay/shell/shell_rail.dart';

void main() {
  testWidgets('named destinations carry no tooltip; the discs do', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'zplay_p2p_warning_never_show': true,
    });
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pump(const Duration(seconds: 2));

    Finder inBar(Finder f) =>
        find.descendant(of: find.byType(ShellRail), matching: f);
    for (final name in const ['Home', 'Series', 'Movies', 'Live TV']) {
      expect(inBar(find.text(name)), findsOneWidget);
      expect(inBar(find.byTooltip(name)), findsNothing, reason: name);
    }
    expect(inBar(find.byTooltip('Search')), findsOneWidget);
  });
}
