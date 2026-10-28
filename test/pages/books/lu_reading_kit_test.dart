/// The manga and book pages' shared controls on a television: each is a
/// remote target with the gold focus ring, and Select does what a tap does.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zplay/pages/books/widgets/lu_reading_kit.dart';
import 'package:zplay/ui/lu_focusable.dart';
import 'package:zplay/ui/lu_theme.dart';

import '../../support/tv_nav_harness.dart';

/// Whether a gold ring is drawn anywhere on screen.
bool _ringShown(WidgetTester tester) => tester
    .widgetList<LuFocusRing>(find.byType(LuFocusRing))
    .any((r) => r.focused);

void main() {
  testWidgets('a switch row takes focus, shows the ring and flips on Select', (
    tester,
  ) async {
    var value = false;
    await pumpTelevision(
      tester,
      Theme(
        data: luTheme(),
        child: Material(
          color: LuColors.bg,
          child: StatefulBuilder(
            builder: (context, setState) => Center(
              child: SizedBox(
                width: 400,
                child: LuSwitchRow(
                  label: 'Option',
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_ringShown(tester), isTrue, reason: 'focus must be visible');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  testWidgets('a pill row moves along with the arrows and picks on Select', (
    tester,
  ) async {
    String? picked;
    await pumpTelevision(
      tester,
      Theme(
        data: luTheme(),
        child: Material(
          color: LuColors.bg,
          child: Center(
            child: LuPillRow(
              children: [
                for (final label in const ['One', 'Two', 'Three'])
                  LuChoicePill(
                    label: label,
                    selected: picked == label,
                    onTap: () => picked = label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_ringShown(tester), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(picked, isNotNull);
  });

  testWidgets('a disabled glyph button is out of the remote\'s reach', (
    tester,
  ) async {
    await pumpTelevision(
      tester,
      Theme(
        data: luTheme(),
        child: const Material(
          color: LuColors.bg,
          child: Center(
            child: LuGlyphButton(
              icon: Icons.skip_next_rounded,
              label: 'Next',
              onTap: null,
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_ringShown(tester), isFalse);
  });
}
