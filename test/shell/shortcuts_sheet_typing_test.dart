/// `?` opens the keyboard reference, except while text is being typed: in a
/// text field `?` and `/` are characters. Search took a pasted magnet link
/// only up to "magnet:" and opened the sheet over it.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/shell/app_shell.dart';
import 'package:zplay/shell/shell_rail.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'zplay_p2p_warning_never_show': true,
    });
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pump(const Duration(seconds: 2));
    // A key reaches the shell's map through whatever has the focus, as a
    // nav button does once the app has been used.
    final rail = find.descendant(
      of: find.byType(ShellRail),
      matching: find.byType(Focus),
    );
    final node = tester
        .widgetList<Focus>(rail)
        .map((f) => f.focusNode)
        .whereType<FocusNode>()
        .firstWhere((n) => n.canRequestFocus);
    node.requestFocus();
    await tester.pump();
  }

  Future<void> pressQuestionMark(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('? opens the sheet when nothing is being typed', (tester) async {
    await pumpShell(tester);
    await pressQuestionMark(tester);
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
  });

  testWidgets('? in a text field is left to the field', (tester) async {
    await pumpShell(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(seconds: 1));

    final field = find.byType(EditableText).first;
    await tester.tap(field);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>(),
      isNotNull,
      reason: 'the search field has the focus',
    );

    await pressQuestionMark(tester);
    expect(find.text('Keyboard shortcuts'), findsNothing);
  });
}
