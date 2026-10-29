import '../../l10n/l10n.dart';

enum CuratedKind { era, saga }

class CuratedItem {
  final String imdbId;
  final String title;
  final int year;

  const CuratedItem({
    required this.imdbId,
    required this.title,
    required this.year,
  });
}

class CuratedCollection {
  final String id;
  final String title;
  final String subtitle;
  final CuratedKind kind;
  final List<CuratedItem> items;

  const CuratedCollection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.items,
  });

  int get count => items.length;

  /// [title] in the app's language. The packs ship English; Chinese comes
  /// from [_zhTitles], and an untranslated pack keeps its English name.
  String get displayTitle {
    if (l10nCurrent().localeName != 'zh') return title;
    return _zhTitles[title] ?? title;
  }

  /// [subtitle] in the app's language: the packs' two patterns ("3 films,
  /// 1972 to 1990", "10 picks from 1990 to 1999") are reworded, anything
  /// else keeps its English.
  String get displaySubtitle {
    if (l10nCurrent().localeName != 'zh') return subtitle;
    final films = RegExp(
      r'^(\d+) films, (\d{4}) to (\d{4})$',
    ).firstMatch(subtitle);
    if (films != null) {
      return '${films[1]} 部 · ${films[2]}–${films[3]}';
    }
    final picks = RegExp(
      r'^(\d+) picks from (\d{4}) to (\d{4})$',
    ).firstMatch(subtitle);
    if (picks != null) {
      return '精选 ${picks[1]} 部 · ${picks[2]}–${picks[3]}';
    }
    if (title == 'The Marx Brothers') return '格劳乔和他的兄弟们，13 部 · 1929–1949';
    return subtitle;
  }

  static const Map<String, String> _zhTitles = {
    'Godfather Collection': '教父系列',
    'Rocky and Creed': '洛奇与奎迪',
    'Back to the Future': '回到未来',
    'Alien': '异形',
    'Die Hard': '虎胆龙威',
    'Lethal Weapon': '致命武器',
    'The Terminator': '终结者',
    'Predator': '铁血战士',
    'Jurassic Park': '侏罗纪公园',
    'Rambo': '第一滴血',
    'Indiana Jones': '夺宝奇兵',
    'The Marx Brothers': '马克斯兄弟',
    'The 90s: Action': '90 年代 · 动作',
    'The 90s: Comedy': '90 年代 · 喜剧',
    'The 90s: Horror': '90 年代 · 恐怖',
    'The 90s: Sci-Fi': '90 年代 · 科幻',
    'The 90s: Animation': '90 年代 · 动画',
    'The 90s: Thriller': '90 年代 · 惊悚',
    'The 1970s': '70 年代',
    'The 1980s': '80 年代',
    'The 2000s': '2000 年代',
    'The 2010s': '2010 年代',
  };
}
