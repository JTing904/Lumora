/// Back with the audiobook player's chapters drawer open closes the drawer,
/// not the whole player: the drawer is a layer of this route, so the route's
/// own pop has to refuse while it is up.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/audiobook/audiobook_model.dart';
import 'package:zplay/pages/audiobooks/audiobook_player_screen.dart';
import 'package:zplay/widgets/common/focusable_card.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Back closes the chapters drawer before the player', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navKey, home: const Scaffold()),
    );
    navKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => AudiobookPlayerScreen(
          audiobook: Audiobook(
            uuid: 'u',
            audioBookId: 'a',
            dynamicSlugId: 'd',
            title: 'A Book',
            author: 'An Author',
            coverImage: '',
            source: 'Archive',
            pageUrl: 'https://example.invalid',
          ),
          chapters: const [],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(AudiobookPlayerScreen), findsOneWidget);

    // Activated through the button's own handler: what a tap or the remote's
    // select runs. (Driving it by pointer or focus here would test the physics
    // button, not the drawer.)
    tester
        .widget<FocusableCard>(
          find.descendant(
            of: find.byTooltip('Chapters List'),
            matching: find.byType(FocusableCard),
          ),
        )
        .onTap!();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Audiobook Chapters'), findsOneWidget);

    // The press Android (and a TV remote's Back) delivers.
    await navKey.currentState!.maybePop();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Audiobook Chapters'), findsNothing);
    expect(find.byType(AudiobookPlayerScreen), findsOneWidget);

    // With the drawer gone the next press leaves the player as before.
    expect(await navKey.currentState!.maybePop(), isTrue);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(navKey.currentState!.canPop(), isFalse);
  });
}
