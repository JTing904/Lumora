import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/widgets/player/player_seek_bar.dart';

/// An arrow on the focused timeline steps from where playback is now, not
/// from where the bar was last built.
void main() {
  Future<List<Duration>> pumpBar(
    WidgetTester tester,
    ValueListenable<Duration> live,
  ) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 800,
              child: PlayerSeekBar(
                // What the bar was built with; mpv has moved on since.
                position: const Duration(minutes: 10),
                positionListenable: live,
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

  Future<void> focusBar(WidgetTester tester) async {
    final focus = tester
        .widgetList<Focus>(find.byType(Focus))
        .firstWhere((f) => f.focusNode?.debugLabel == 'PlayerSeekBar');
    focus.focusNode!.requestFocus();
    await tester.pump();
  }

  testWidgets('an arrow steps from the live position', (tester) async {
    final live = ValueNotifier<Duration>(const Duration(minutes: 30));
    addTearDown(live.dispose);
    final seeks = await pumpBar(tester, live);
    await focusBar(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(seeks.last, const Duration(minutes: 30, seconds: 10));
  });

  testWidgets('two quick presses step twice, not once from the same place', (
    tester,
  ) async {
    final live = ValueNotifier<Duration>(const Duration(minutes: 30));
    addTearDown(live.dispose);
    final seeks = await pumpBar(tester, live);
    await focusBar(tester);

    // The player has not reported the first seek yet when the second press
    // arrives.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(seeks, const [
      Duration(minutes: 30, seconds: 10),
      Duration(minutes: 30, seconds: 20),
    ]);
  });

  testWidgets('a step back is clamped to the start', (tester) async {
    final live = ValueNotifier<Duration>(const Duration(seconds: 4));
    addTearDown(live.dispose);
    final seeks = await pumpBar(tester, live);
    await focusBar(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(seeks.last, Duration.zero);
  });
}
