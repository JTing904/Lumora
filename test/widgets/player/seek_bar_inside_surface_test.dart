import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/widgets/player/player_seek_bar.dart';

/// The player screen wraps everything in a tap that shows and hides the
/// controls. A tap on the timeline is the timeline's: it seeks and the
/// controls stay up, so the next tap can seek again.
void main() {
  testWidgets('a tap on the timeline seeks and does not toggle the HUD', (
    tester,
  ) async {
    var toggles = 0;
    final seeks = <Duration>[];
    await tester.pumpWidget(
      MaterialApp(
        home: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => toggles++,
          onLongPressStart: (_) {},
          onLongPressEnd: (_) {},
          onVerticalDragStart: (_) {},
          onVerticalDragUpdate: (_) {},
          onVerticalDragEnd: (_) {},
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
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
      ),
    );
    final track = find.byType(GestureDetector).at(1);
    final box = tester.getRect(track);
    await tester.tapAt(Offset(box.left + box.width * 0.3, box.center.dy));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(box.left + box.width * 0.6, box.center.dy));
    await tester.pumpAndSettle();
    expect(seeks, hasLength(2));
    expect(toggles, 0);
  });
}
