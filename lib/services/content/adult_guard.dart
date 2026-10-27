import '../../models/movie/movie.dart';
import '../../models/movie/movie_section.dart';
import 'content_settings.dart';

/// Keeps sexual titles out of everyone's lists unless an admin has asked
/// for them ([ContentSettings.adultEnabled]).
///
/// The addons and IMDb's suggestions mark nothing as adult, so a search for
/// "hentai" listed "My Hentai Girlfriend" and 1985 pink films to every
/// account. A title is held back when its source flags it adult (TMDb's
/// `adult`) or when any of its names - the addon's, the Chinese one, the
/// original - carries one of the words below. Better to hide a romcom with
/// 变态 in its name than to show what the switch is there to hide.
abstract final class AdultGuard {
  static final RegExp _latin = RegExp(
    r'\b(hentai|porn|porno|pornographic|erotic|erotica|erotique|eroge|xxx|nsfw|softcore|jav)\b',
    caseSensitive: false,
  );

  static const List<String> _cjk = [
    '色情',
    '情色',
    '成人片',
    '成人电影',
    '成人動畫',
    '成人动画',
    '三级片',
    '三級片',
    '里番',
    '裏番',
    '无码',
    '無碼',
    '调教',
    '調教',
    '变态',
    '變態',
    '痴汉',
    '痴漢',
    'エロ',
    'アダルト',
    '官能',
    'AV女优',
    'AV女優',
    '性爱',
    '性愛',
    '艳情',
    '艷情',
    '春宫',
    '春宮',
    '肉欲',
    '肉慾',
    '淫',
  ];

  /// Whether the switch lets adult titles through right now.
  static bool get allowed =>
      ContentSettings.isAdmin.value && ContentSettings.adultEnabled.value;

  /// Whether a search for [query] is a search for adult titles. Its results
  /// are withheld whole: an erotic film does not always say so in its name
  /// (Malombra), but asking for "erotic" does.
  static bool adultQuery(String query) => !allowed && looksAdult([query]);

  static bool looksAdult(Iterable<String?> names, {bool flagged = false}) {
    if (flagged) return true;
    for (final raw in names) {
      final name = raw?.trim();
      if (name == null || name.isEmpty) continue;
      if (_latin.hasMatch(name)) return true;
      for (final word in _cjk) {
        if (name.contains(word)) return true;
      }
    }
    return false;
  }

  /// [section] without its adult titles, unless [allowed]; the same object
  /// when nothing was taken out.
  static MovieSection filterSection(MovieSection section) {
    final kept = filter(section.movies);
    if (kept.length == section.movies.length) return section;
    return MovieSection(
      title: section.title,
      subtitle: section.subtitle,
      contentType: section.contentType,
      addonBaseUrl: section.addonBaseUrl,
      catalog: section.catalog,
      movies: kept,
    );
  }

  /// [movies] without the adult ones, unless [allowed]. [extraNames] gives
  /// more names for a title by id (its Chinese or original name).
  static List<Movie> filter(
    List<Movie> movies, {
    Iterable<String?> Function(Movie)? extraNames,
    bool Function(Movie)? flagged,
  }) {
    if (allowed) return movies;
    return [
      for (final m in movies)
        if (!looksAdult([
          m.name,
          ...?extraNames?.call(m),
        ], flagged: flagged?.call(m) ?? false))
          m,
    ];
  }
}
