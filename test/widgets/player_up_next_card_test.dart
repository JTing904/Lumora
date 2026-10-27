import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/widgets/player/player_intro_outro_menu.dart';

void main() {
  testWidgets('the countdown names the episode and offers both answers', (
    tester,
  ) async {
    var played = false;
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayerUpNextCard(
              label: 'E2 · Work Drinks',
              secondsLeft: 7,
              onPlayNow: () => played = true,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Next episode in 7s'), findsOneWidget);
    expect(find.text('E2 · Work Drinks'), findsOneWidget);
    await tester.tap(find.text('Play now'));
    await tester.tap(find.text('Cancel'));
    expect(played, isTrue);
    expect(cancelled, isTrue);
  });
}
