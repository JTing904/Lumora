import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/movie/movie.dart';
import 'package:zplay/services/settings/locale_settings.dart';
import 'package:zplay/ui/lu_button.dart';
import 'package:zplay/ui/lu_cards.dart';
import 'package:zplay/ui/lu_focusable.dart';
import 'package:zplay/ui/lu_hero.dart';
import 'package:zplay/ui/lu_language_toggle.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleSettings.locale.value = const Locale('en'));

  group('LuFocusable.onLongPress', () {
    Future<(List<String>, FocusNode)> pumpCard(WidgetTester tester) async {
      final log = <String>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          Center(
            child: LuFocusable(
              focusNode: node,
              onTap: () => log.add('tap'),
              onLongPress: () => log.add('long'),
              builder: (_, _) => const SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      return (log, node);
    }

    testWidgets('a short Select taps, a held one opens the second action', (
      tester,
    ) async {
      final (log, _) = await pumpCard(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      expect(log, ['tap']);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.runAsync(
        () => Future<void>.delayed(
          LuFocusable.longPressKeyHold + const Duration(milliseconds: 50),
        ),
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      expect(log, ['tap', 'long']);
    });

    testWidgets('the menu key, a long press and a right click', (tester) async {
      final (log, _) = await pumpCard(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      expect(log, ['long']);

      await tester.longPress(find.byType(LuFocusable));
      expect(log, ['long', 'long']);

      await tester.tap(find.byType(LuFocusable), buttons: kSecondaryButton);
      expect(log, ['long', 'long', 'long']);
    });
  });

  testWidgets('Continue Watching: Remove is reachable without hovering', (
    tester,
  ) async {
    var removed = 0;
    await tester.pumpWidget(
      _host(
        Center(
          child: LuContinueCard(
            title: const Text('Show'),
            image: null,
            progress: 0.4,
            caption: 'S1 E2',
            onTap: () {},
            onRemove: () => removed++,
            removeLabel: 'Remove from Continue Watching',
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(LuContinueCard));
    await tester.pumpAndSettle();
    expect(find.text('Remove from Continue Watching'), findsOneWidget);
    // Cancel holds focus first, so a stray press removes nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(removed, 0);

    await tester.longPress(find.byType(LuContinueCard));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(LuButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(removed, 1);
  });

  testWidgets('the language toggle keeps focus on the segment just picked', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const Center(child: LuLanguageToggle())));
    final zh = find.ancestor(
      of: find.text('中文'),
      matching: find.byType(LuFocusable),
    );
    final node = Focus.of(
      tester.element(
        find.descendant(of: zh, matching: find.byType(GestureDetector)).first,
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(LocaleSettings.locale.value, const Locale('zh'));
    expect(node.hasPrimaryFocus, isTrue);
  });

  testWidgets('a remote pages the hero from the edges of its buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final movies = [
      for (var i = 1; i <= 3; i++)
        Movie(id: 'tt$i', name: 'Title $i', type: 'movie', addonBaseUrl: ''),
    ];
    await tester.pumpWidget(
      _host(
        SingleChildScrollView(
          child: LuHeroCarousel(movies: movies, phone: false, pad: 48),
        ),
      ),
    );
    await tester.pump();

    FocusNode buttonNode(String label) => Focus.of(
      tester.element(
        find
            .descendant(
              of: find.widgetWithText(LuButton, label),
              matching: find.byType(GestureDetector),
            )
            .first,
      ),
    );

    final more = buttonNode('More Info');
    more.requestFocus();
    await tester.pump();
    expect(find.text('Title 1'), findsOneWidget);

    // Right on the last button: the next title, focus on its last button.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Title 2'), findsOneWidget);
    expect(buttonNode('More Info').hasPrimaryFocus, isTrue);

    // Left on a control that is not the first leaves the slide alone.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Title 2'), findsOneWidget);

    // Left on the first one (播放) shows the previous title.
    buttonNode('Play').requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Title 1'), findsOneWidget);
    expect(buttonNode('Play').hasPrimaryFocus, isTrue);
  });
}
