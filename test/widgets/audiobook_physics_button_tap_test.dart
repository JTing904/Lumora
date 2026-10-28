import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/widgets/audiobook/audiobook_interactive_physics_button.dart';

void main() {
  Widget host(VoidCallback onTap) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: AudiobookInteractivePhysicsButton(
          onTap: onTap,
          child: const SizedBox(width: 48, height: 48),
        ),
      ),
    ),
  );

  testWidgets('a real tap fires once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(() => taps++));
    await tester.tap(find.byType(AudiobookInteractivePhysicsButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('focus and the centre key work without errors', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(() => taps++));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(taps, 1);
  });
}
