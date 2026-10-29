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
  final supported = AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == chosen.languageCode,
  );
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

/// An AniList or TMDb genre name in the app's language. Names it does not
/// know stay as they are.
String localizedGenre(String name) {
  if (l10nCurrent().localeName != 'zh') return name;
  const zh = <String, String>{
    'action': '动作',
    'adventure': '冒险',
    'comedy': '喜剧',
    'drama': '剧情',
    'fantasy': '奇幻',
    'horror': '恐怖',
    'mahou shoujo': '魔法少女',
    'mecha': '机甲',
    'music': '音乐',
    'mystery': '悬疑',
    'psychological': '心理',
    'romance': '爱情',
    'sci-fi': '科幻',
    'slice of life': '日常',
    'sports': '运动',
    'supernatural': '超自然',
    'thriller': '惊悚',
  };
  return zh[name.trim().toLowerCase()] ?? name;
}

/// An AniList format (TV, MOVIE, ONA...) as the app shows it.
String localizedAnimeFormat(String format) {
  final zh = l10nCurrent().localeName == 'zh';
  return switch (format.toUpperCase()) {
    'TV' => zh ? 'TV 动画' : 'TV Series',
    'TV_SHORT' => zh ? '泡面番' : 'TV Short',
    'MOVIE' => zh ? '剧场版' : 'Movie',
    'SPECIAL' => zh ? '特别篇' : 'Special',
    'OVA' => 'OVA',
    'ONA' => zh ? '网络动画' : 'ONA',
    'MUSIC' => zh ? '音乐 MV' : 'Music',
    _ => format,
  };
}

/// An AniList season (WINTER, SPRING...) as the app shows it.
String localizedAnimeSeason(String season) {
  final zh = l10nCurrent().localeName == 'zh';
  return switch (season.toUpperCase()) {
    'WINTER' => zh ? '冬季' : 'Winter',
    'SPRING' => zh ? '春季' : 'Spring',
    'SUMMER' => zh ? '夏季' : 'Summer',
    'FALL' => zh ? '秋季' : 'Fall',
    _ => season,
  };
}
