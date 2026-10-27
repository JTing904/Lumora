import 'tmdb_service.dart';

/// What a search result is, beyond the movie/series split an addon reports.
class TitleKindFacts {
  const TitleKindFacts({
    required this.isAnimation,
    this.localTitle,
    this.posterUrl,
    this.originalLanguage,
    this.originalTitle,
    this.adult = false,
  });

  /// Animated (anime, donghua, cartoons) as opposed to live action.
  final bool isAnimation;

  /// The title in the viewer's language when TMDb has one that differs from
  /// the name the addon gave, e.g. 凡人修仙传 for "A Mortal's Journey".
  final String? localTitle;

  /// TMDb's poster, for results whose source sent none (the IMDb title lookup
  /// answers with a name and a year only).
  final String? posterUrl;

  /// TMDb's `original_language` ('en', 'zh', 'ja', 'es' ...).
  final String? originalLanguage;

  /// The title in its own language (変態王子と笑わない猫。).
  final String? originalTitle;

  /// TMDb's own adult flag.
  final bool adult;
}

/// Looks up search results on TMDb by IMDb id, so the results page can label
/// each one 动画 or 真人 and show its Chinese name.
///
/// Cinemeta's search answers with a name, a year and movie/series only, and a
/// name is exactly what cannot tell the 2020 donghua from the 2025 drama of the
/// same name. TMDb's `/find` hit carries `genre_ids` (16 is Animation) and,
/// asked in a language, the localised title, so one request per result answers
/// both. Null when there is no TMDb key, TMDb does not know the id, or it
/// cannot be reached; the page then falls back to the addon's own type.
class TitleKindService {
  TitleKindService._();

  static const int _animationGenreId = 16;

  static final Map<String, TitleKindFacts?> _cache = {};

  static Future<TitleKindFacts?> forImdbId(
    String imdbId, {
    required String type,
    String language = 'en-US',
  }) async {
    if (!imdbId.startsWith('tt') || !TmdbService.hasScraperKey) return null;
    final key = '$imdbId|$type|$language';
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final found = await TmdbService.getScraperJson('/find/$imdbId', {
        'external_source': 'imdb_id',
        'language': language,
      });
      if (found == null) return null;
      final isTv = type == 'series' || type == 'tv';
      final preferred = found[isTv ? 'tv_results' : 'movie_results'] as List?;
      final other = found[isTv ? 'movie_results' : 'tv_results'] as List?;
      final hit = (preferred != null && preferred.isNotEmpty)
          ? preferred.first
          : (other != null && other.isNotEmpty ? other.first : null);
      if (hit is! Map) return _cache[key] = null;

      final genres = (hit['genre_ids'] as List? ?? const []).toSet();
      final local = (hit['title'] ?? hit['name'])?.toString().trim();
      final original = (hit['original_title'] ?? hit['original_name'])
          ?.toString()
          .trim();
      final posterPath = hit['poster_path']?.toString();
      return _cache[key] = TitleKindFacts(
        isAnimation: genres.contains(_animationGenreId),
        localTitle: (local == null || local.isEmpty) ? original : local,
        posterUrl: (posterPath == null || posterPath.isEmpty)
            ? null
            : 'https://image.tmdb.org/t/p/w342$posterPath',
        originalLanguage: hit['original_language']?.toString(),
        originalTitle: original,
        adult: hit['adult'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}
