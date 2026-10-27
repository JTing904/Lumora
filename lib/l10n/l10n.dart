import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import '../services/settings/locale_settings.dart';

/// The app's strings, with English as the fallback when a widget is pumped
/// without the app's localization delegates.
///
/// Production always has the delegates from `main.dart`. A widget test that
/// pumps a page in a plain `MaterialApp` does not, and a generated
/// `AppLocalizations.of(context)` would throw there; the English bundle keeps
/// those tests meaningful without making every test host carry the delegates.
AppLocalizations l10nOf(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('en'));

/// The strings for the app's current language, for code with no
/// [BuildContext] - the services that name Home's rails, say. Follows the
/// language picked in Settings, else the device's, else English.
AppLocalizations l10nCurrent() {
  final chosen =
      LocaleSettings.locale.value ?? PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.supportedLocales
      .any((l) => l.languageCode == chosen.languageCode);
  return lookupAppLocalizations(
    supported ? Locale(chosen.languageCode) : const Locale('en'),
  );
}

/// Addon catalogs name themselves in English ("Popular", "Featured"). The
/// common ones are translated; any other name is shown as the addon wrote it.
String localizedCatalogName(String name) {
  if (l10nCurrent().localeName != 'zh') return name;
  const zh = <String, String>{
    'popular': '热门',
    'featured': '精选',
    'new': '最新',
    'top': '排行',
    'top rated': '高分',
    'trending': '热门趋势',
    'latest': '最新',
    'recently added': '最近上架',
    'last videos': '最新剧集',
    'calendar videos': '播出日历',
  };
  return zh[name.trim().toLowerCase()] ?? name;
}
