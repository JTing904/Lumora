/// Guards that a phone can reach 电视剧, 电影, 动漫 and 直播.
///
/// They are in the top bar only, and the phone's bottom bar once had no row
/// for any of them, so on a phone (or a desktop window narrower than 600 dp)
/// the four were simply unreachable. The bottom bar now has one 分类 row for
/// all four and a tab header over them moves between them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/pages/category/category_page.dart';
import 'package:zplay/pages/iptv/iptv_page.dart';
import 'package:zplay/services/layout/device_profile.dart';
import 'package:zplay/shell/app_shell.dart';
import 'package:zplay/shell/app_shell_scope.dart';
import 'package:zplay/shell/shell_rail.dart';

AppShellController _shell(WidgetTester tester) =>
    tester.widget<AppShellScope>(find.byType(AppShellScope)).controller;

Future<void> _pumpShell(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'zplay_p2p_warning_never_show': true,
  });
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: AppShell()));
  await tester.pump(const Duration(seconds: 2));
}

Finder _barRow(IconData icon) =>
    find.descendant(of: find.byType(ShellRail), matching: find.byIcon(icon));

void main() {
  tearDown(() => DeviceProfile.debugSetTelevision(value: false));

  test('every category slot is reachable from the phone bar', () {
    // The bar's category row stands for the whole group.
    expect(ShellRail.bottomSlots, hasLength(5));
    expect(
      ShellRail.bottomSlots.where(ShellRail.categorySlots.contains),
      hasLength(1),
    );
    for (final slot in ShellRail.topSlots) {
      expect(
        ShellRail.bottomSlots.contains(slot) ||
            ShellRail.categorySlots.contains(slot),
        isTrue,
        reason: '$slot is in the top bar, so a phone needs a way to it too',
      );
    }
  });

  for (final size in const [Size(390, 844), Size(900, 560)]) {
    testWidgets('分类 opens the categories and the tabs move between them '
        '(${size.width.toInt()}x${size.height.toInt()})', (tester) async {
      // 900 x 560 is a desktop window dragged short: its shortest side puts
      // it in the phone band, so it gets the same bar.
      await _pumpShell(tester, size);

      expect(find.byType(ShellCategoryTabs), findsNothing);
      await tester.tap(_barRow(Icons.video_library_rounded));
      await tester.pump();
      expect(_shell(tester).current.value, ShellSlot.series);
      expect(find.byType(ShellCategoryTabs), findsOneWidget);
      expect(find.byType(CategoryPage), findsOneWidget);

      Finder tab(String name) => find.descendant(
        of: find.byType(ShellCategoryTabs),
        matching: find.text(name),
      );
      await tester.tap(tab('Movies'));
      await tester.pump();
      expect(_shell(tester).current.value, ShellSlot.movies);

      await tester.tap(tab('Live TV'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_shell(tester).current.value, ShellSlot.live);
      expect(find.byType(IptvPage), findsOneWidget);

      // Home and back: 分类 returns to the category last shown.
      await tester.tap(_barRow(Icons.home_rounded));
      await tester.pump();
      expect(find.byType(ShellCategoryTabs), findsNothing);
      await tester.tap(_barRow(Icons.video_library_rounded));
      await tester.pump();
      expect(_shell(tester).current.value, ShellSlot.live);
    });
  }

  testWidgets('a television keeps the top bar and draws no category tabs', (
    tester,
  ) async {
    DeviceProfile.debugSetTelevision(value: true);
    await _pumpShell(tester, const Size(960, 540));
    _shell(tester).go(ShellSlot.movies);
    await tester.pump();
    expect(find.byType(ShellCategoryTabs), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ShellRail),
        matching: find.text('Movies'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a slot is built only once it is shown', (tester) async {
    await _pumpShell(tester, const Size(390, 844));
    expect(find.byType(IptvPage, skipOffstage: false), findsNothing);
    expect(find.byType(CategoryPage, skipOffstage: false), findsNothing);
    _shell(tester).go(ShellSlot.live);
    await tester.pump();
    expect(find.byType(IptvPage, skipOffstage: false), findsOneWidget);
    // And kept once it has been: leaving it does not tear it down.
    _shell(tester).go(ShellSlot.home);
    await tester.pump();
    expect(find.byType(IptvPage, skipOffstage: false), findsOneWidget);
  });
}
