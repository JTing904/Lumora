import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/widgets/player/player_seek_bar.dart';

/// The timeline answers every drag and tap, not only the first.
void main() {
  Future<List<Duration>> pumpBar(WidgetTester tester) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 800,
              child: PlayerSeekBar(
                position: const Duration(minutes: 10),
                duration: const Duration(minutes: 100),
                onSeek: seeks.add,
              ),
            ),
          ),
        ),
      ),
    );
    return seeks;
  }

  testWidgets('two drags in a row both seek', (tester) async {
    final seeks = await pumpBar(tester);
    final track = find.byType(GestureDetector).first;
    await tester.drag(track, const Offset(150, 0));
    await tester.pumpAndSettle();
    await tester.drag(track, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(seeks, hasLength(2));
  });

  testWidgets('a cancelled press does not leave the bar scrubbing', (
    tester,
  ) async {
    final seeks = await pumpBar(tester);
    final track = find.byType(GestureDetector).first;
    final gesture = await tester.startGesture(tester.getCenter(track));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    // Then an ordinary drag still seeks.
    await tester.drag(track, const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(seeks, hasLength(1));
  });

  testWidgets('a mouse drags it twice', (tester) async {
    final seeks = await pumpBar(tester);
    final track = find.byType(GestureDetector).first;
    for (final dx in [150.0, -200.0]) {
      final g = await tester.startGesture(
        tester.getCenter(track),
        kind: PointerDeviceKind.mouse,
      );
      await g.moveBy(Offset(dx / 4, 0));
      await g.moveBy(Offset(dx, 0));
      await g.up();
      await tester.pumpAndSettle();
    }
    expect(seeks, hasLength(2));
  });

  testWidgets('a click that wobbles a little still seeks', (tester) async {
    final seeks = await pumpBar(tester);
    final track = find.byType(GestureDetector).first;
    for (var i = 0; i < 2; i++) {
      final g = await tester.startGesture(
        tester.getCenter(track),
        kind: PointerDeviceKind.mouse,
      );
      await g.moveBy(const Offset(3, 0));
      await g.up();
      await tester.pumpAndSettle();
    }
    expect(seeks, hasLength(2));
  });
}
