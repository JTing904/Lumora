/// The torrent notice is read once: closing it, by any answer, keeps it from
/// coming back on the next launch. It used to return every time until
/// 不再提示 was pressed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/shell/app_shell.dart';
import 'package:zplay/widgets/p2p/p2p_warning_dialog.dart';

void main() {
  testWidgets('closing the notice once keeps it away', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    // The intro plays first; the notice follows it.
    for (
      var i = 0;
      i < 20 && find.byType(P2pWarningDialog).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(P2pWarningDialog), findsOneWidget);

    await tester.tap(find.text('Exit'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(P2pWarningDialog), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('zplay_p2p_warning_never_show'), isTrue);

    // The next launch.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(P2pWarningDialog), findsNothing);
  });
}
