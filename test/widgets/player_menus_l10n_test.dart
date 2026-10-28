import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/settings/locale_settings.dart';
import 'package:zplay/widgets/player/player_aspect_menu.dart';

void main() {
  tearDown(() => LocaleSettings.locale.value = const Locale('en'));

  test('aspect options follow the app language', () {
    expect(aspectOptions.map((o) => o.label), [
      'Fit to screen (Contain)',
      'Fill screen (Crop/Zoom)',
      'Stretch to fill',
    ]);

    LocaleSettings.locale.value = const Locale('zh');
    final zh = aspectOptions.map((o) => o.label).toList();
    expect(zh, ['适应屏幕（完整显示）', '填满屏幕（裁剪/放大）', '拉伸填满']);
    expect(aspectOptions.map((o) => o.fit),
        [BoxFit.contain, BoxFit.cover, BoxFit.fill]);
  });
}
