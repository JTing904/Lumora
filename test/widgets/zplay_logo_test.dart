import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/theme/design_tokens.dart';
import 'package:zplay/widgets/common/zplay_logo.dart';

/// The Lumora mark is drawn, not loaded, so it takes its colours from the
/// theme. These assert the shape and the colour source rather than reading
/// pixels back: `RenderRepaintBoundary.toImage` never completes under the test
/// binding.
void main() {
  testWidgets('the mark fills the size it is given, at every size it is used at',
      (tester) async {
    for (final size in <double>[16, 24, 26, 30, 32, 34, 64]) {
      await tester.pumpWidget(
        MaterialApp(home: Center(child: ZplayLogo(size: size))),
      );
      await tester.pump();

      final box = tester.getSize(find.byType(ZplayLogo));
      expect(box.width, size, reason: 'width at $size');
      expect(box.height, size, reason: 'height at $size');
    }
  });

  test('the L reads as an L: a tall stem and a foot to the right', () {
    const size = Size(100, 100);
    final letter = ZplayLogo.letterPath(size);
    expect(letter.contains(const Offset(35, 25)), isTrue, reason: 'the stem');
    expect(letter.contains(const Offset(70, 72)), isTrue, reason: 'the foot');
    expect(letter.contains(const Offset(65, 30)), isFalse,
        reason: 'the empty upper right of an L');
  });

  test('the diagonal puts the foot in shadow and the top of the stem in light',
      () {
    final shadow = ZplayLogo.shadowPath(const Size(100, 100));
    expect(shadow.contains(const Offset(70, 72)), isTrue);
    expect(shadow.contains(const Offset(35, 25)), isFalse);
  });

  testWidgets('the mark takes its colour from the accent it is given',
      (tester) async {
    Widget build(Color accent) {
      final tokens = ZplayTokens.derive(
        accent: accent,
        bg: const Color(0xFF0A0A0C),
        surface: const Color(0xFF141418),
        surfaceRaised: const Color(0xFF1A1A1F),
      );
      return MaterialApp(
        theme: ThemeData(extensions: <ThemeExtension<dynamic>>[tokens]),
        home: const Center(child: ZplayLogo(size: 32)),
      );
    }

    Future<CustomPainter?> painterFor(Widget tree) async {
      await tester.pumpWidget(tree);
      await tester.pump();
      return tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(ZplayLogo),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter;
    }

    final green = await painterFor(
      KeyedSubtree(key: const ValueKey('a'), child: build(const Color(0xFF00FF00))),
    );
    final red = await painterFor(
      KeyedSubtree(key: const ValueKey('b'), child: build(const Color(0xFFFF0000))),
    );

    expect(red!.shouldRepaint(green!), isTrue,
        reason: 'a different accent must repaint the mark in that accent');
  });
}
