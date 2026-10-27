import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:zplay/services/settings/locale_settings.dart';

/// Runs every test in English.
///
/// Lumora opens in Chinese by default, and the strings built without a
/// [BuildContext] (`l10nCurrent`, used for Home's rail titles and catalog
/// names) follow that default. Widget tests pumped without the app's
/// delegates already see English through `l10nOf`, and the suite searches for
/// English text, so the default is pinned to English here. Tests about the
/// Chinese default set the locale themselves.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LocaleSettings.locale.value = const Locale('en');
  await testMain();
}
