/// The shell and settings chrome in Chinese, Lumora's default language.
///
/// The shell has to say its destinations in the app's language, and a fresh
/// install has to open in Chinese without the user choosing it.
///
/// The English case is asserted too, because the fallback used by every widget
/// pumped without the app's delegates must keep the words the rest of the suite
/// searches for.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/l10n/generated/app_localizations.dart';
import 'package:zplay/l10n/l10n.dart';
import 'package:zplay/pages/settings/diagnostics_page.dart';
import 'package:zplay/services/diagnostics/diagnostics_export.dart';
import 'package:zplay/services/layout/device_profile.dart';
import 'package:zplay/services/settings/locale_settings.dart';
import 'package:zplay/shell/app_shell.dart';
import 'package:zplay/shell/shell_rail.dart';

const _zh = Locale('zh');

Widget _app(Locale locale, Widget home) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Widget _rail() => Scaffold(
  body: ShellRail(
    current: ShellSlot.home,
    onSelect: (_) {},
    onLiveTv: () {},
  ),
);

/// A page that reports the bundle it sees, for asserting the delegate wiring
/// itself rather than a widget's rendering.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Text(l10nOf(context).navHome),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    LocaleSettings.locale.value = null;
    DeviceProfile.debugSetTelevision(value: false);
  });

  tearDown(() {
    LocaleSettings.locale.value = null;
    DeviceProfile.debugSetTelevision(value: false);
  });

  testWidgets('Chinese shell names every destination in Chinese', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_zh, _rail()));
    await tester.pump();

    final context = tester.element(find.byType(ShellRail));
    expect(Directionality.of(context), TextDirection.ltr);

    for (final label in <String>['首页', '电视剧', '电影', '动漫', '直播', '我的片单']) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: 'the shell must draw "$label" in Chinese',
      );
    }
  });

  testWidgets('English stays the default copy', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const Locale('en'), _rail()));
    await tester.pump();

    final context = tester.element(find.byType(ShellRail));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My List'), findsOneWidget);
    expect(find.text('Live TV'), findsOneWidget);
  });

  testWidgets('a plain MaterialApp still sees English through l10nOf', (
    tester,
  ) async {
    // No delegates: the situation every older widget test is in.
    await tester.pumpWidget(const MaterialApp(home: _Probe()));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('diagnostics page renders its Chinese chrome', (tester) async {
    await tester.pumpWidget(
      _app(
        _zh,
        Scaffold(body: DiagnosticsPage(export: _FakeDiagnostics())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('诊断'), findsOneWidget);
    expect(find.text('复制报告'), findsOneWidget);
    expect(find.text('保存报告'), findsOneWidget);
    expect(find.textContaining('共 2 条'), findsOneWidget);
  });

  test('a fresh install opens in Chinese', () async {
    await LocaleSettings.initialize();
    expect(LocaleSettings.locale.value, _zh);
  });

  test('LocaleSettings persists each choice and initialize restores it', () async {
    final prefs = await SharedPreferences.getInstance();

    await LocaleSettings.setLocale('en');
    expect(prefs.getString('zplay_locale'), 'en');
    LocaleSettings.locale.value = null;
    await LocaleSettings.initialize();
    expect(LocaleSettings.locale.value, const Locale('en'));

    // "Follow the system" is stored as its own value, so it survives a
    // restart instead of falling back to the Chinese default.
    await LocaleSettings.setLocale(LocaleSettings.systemCode);
    expect(LocaleSettings.locale.value, isNull);
    expect(prefs.getString('zplay_locale'), LocaleSettings.systemCode);
    await LocaleSettings.initialize();
    expect(LocaleSettings.locale.value, isNull);
  });
}

class _FakeDiagnostics extends DiagnosticsExport {
  @override
  Future<Map<String, Object?>> collect() async => <String, Object?>{
    'app': <String, Object?>{'version': '9.9.9'},
    'device': <String, Object?>{'formFactor': 'television'},
    'player': <String, Object?>{'engine': 'media3'},
    'breadcrumbs': <String, Object?>{
      'count': 2,
      'entries': <Object?>[
        <String, Object?>{
          'at': '2026-10-19T10:00:00.000Z',
          'category': 'route',
          'message': 'push DetailsPage',
        },
        <String, Object?>{
          'at': '2026-10-19T10:00:01.000Z',
          'category': 'stream',
          'message': 'stream.open',
        },
      ],
    },
  };

  @override
  Future<String> copyText() async => '{"fake":true}';

  @override
  Future<String?> saveReport() async => null;
}
