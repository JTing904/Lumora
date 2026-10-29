import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/ui/lu_cards.dart';

/// A sideways row on a computer: the mouse can drag it, and the arrows that
/// appear on hover page it. The details page's episode row had neither, so
/// it could not be moved with a mouse at all.
void main() {
  Widget row(ScrollController c) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 600,
        height: 120,
        child: LuSideScroll(
          controller: c,
          child: ListView.builder(
            controller: c,
            scrollDirection: Axis.horizontal,
            itemCount: 30,
            itemBuilder: (_, i) => SizedBox(
              width: 150,
              child: GestureDetector(onTap: () {}, child: Text('$i')),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('a mouse drags the row', (tester) async {
    final c = ScrollController();
    await tester.pumpWidget(row(c));
    final gesture = await tester.startGesture(
      const Offset(400, 60),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(-50, 0));
    await gesture.moveBy(const Offset(-250, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.offset, greaterThan(200));
  });

  testWidgets('hovering shows only the arrow there is more toward', (
    tester,
  ) async {
    final c = ScrollController();
    await tester.pumpWidget(row(c));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(300, 60));
    await tester.pumpAndSettle();

    final left = find.byIcon(Icons.chevron_left_rounded);
    final right = find.byIcon(Icons.chevron_right_rounded);
    double opacityOf(Finder f) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(of: f, matching: find.byType(AnimatedOpacity)),
        )
        .opacity;
    expect(opacityOf(left), 0);
    expect(opacityOf(right), 1);

    await tester.tap(right);
    await tester.pumpAndSettle();
    expect(c.offset, closeTo(480, 1));
    expect(opacityOf(left), 1);
  });
}
