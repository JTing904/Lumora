/// 直播 is its own destination in the bar: tapping it shows the live TV page,
/// and the bar marks it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/pages/iptv/iptv_page.dart';
import 'package:zplay/services/layout/device_profile.dart';
import 'package:zplay/shell/app_shell.dart';
import 'package:zplay/shell/shell_rail.dart';

void main() {
  tearDown(() => DeviceProfile.debugSetTelevision(value: false));

  testWidgets('the bar\'s Live TV destination opens the live TV page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'zplay_p2p_warning_never_show': true,
    });
    DeviceProfile.debugSetTelevision(value: true);
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(960, 540) * 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pump(const Duration(seconds: 2));

    final liveTv = find.descendant(
      of: find.byType(ShellRail),
      matching: find.text('Live TV'),
    );
    expect(liveTv, findsOneWidget, reason: 'the bar names the destination');
    await tester.tap(liveTv);
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<ShellRail>(find.byType(ShellRail)).current,
      ShellSlot.live,
      reason: 'the bar marks the destination that was chosen',
    );
    expect(find.byType(IptvPage), findsOneWidget);
  });
}
