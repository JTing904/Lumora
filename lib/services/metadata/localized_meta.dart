import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';
import '../../models/movie/movie_detail.dart';
import 'tmdb_service.dart';

/// The viewer's-language title, synopsis and genres for a title, from TMDb.
@immutable
class LocalText {
  const LocalText({
    this.name,
    this.overview,
    this.genres = const [],
    this.tmdbId,
    this.isTv = false,
  });

  final String? name;
  final String? overview;
  final List<String> genres;

  /// The TMDb title this text came from, for the cast lookup.
  final int? tmdbId;
  final bool isTv;
}

/// One of a title's cast: the name to show, the name the search pages know
/// them by, and their photo when TMDb has one.
@immutable
class CastMember {
  const CastMember(this.name, {String? searchName, this.photo})
    : searchName = searchName ?? name;

  final String name;
  final String searchName;
  final String? photo;
}

/// Puts Chinese text on the details the addons send in English.
///
/// Cinemeta answers in English only, so a Chinese viewer read "A Record of a
/// Mortal's Journey to Immortality" over a donghua they know as 凡人修仙传.
/// TMDb's `/find` by IMDb id, asked in zh-CN (zh-TW when the mainland text is
/// missing), gives the name and synopsis; the genre names come from TMDb's
/// genre list in the same language. The text goes on the display-only
/// fields ([MovieDetail.localName] ...), never on [MovieDetail.name], which
/// the scrapers search with. Without a TMDb key, for a non-IMDb id, or in
/// English, the detail comes back as it went in.
abstract final class LocalizedMeta {
  static final Map<String, LocalText?> _cache = {};
  static final Map<String, Map<int, String>> _genreNames = {};

  /// TV genres TMDb's zh-CN list leaves in English.
  static const Map<String, String> _untranslated = {
    'Sci-Fi & Fantasy': '科幻奇幻',
    'Action & Adventure': '动作冒险',
    'War & Politics': '战争政治',
    'Kids': '儿童',
    'News': '新闻',
    'Reality': '真人秀',
    'Soap': '肥皂剧',
    'Talk': '脱口秀',
  };

  /// Whether the app is showing Chinese.
  static bool get _wantsChinese => l10nCurrent().localeName == 'zh';

  static Future<MovieDetail> apply(MovieDetail detail) async {
    if (!_wantsChinese || !detail.id.startsWith('tt')) return detail;
    final series = detail.type == 'series' || detail.type == 'tv';
    // The lookup keeps running past the timeout and lands in the cache, so
    // the next read of this detail has it.
    final text = await forImdbId(
      detail.id,
      series: series,
    ).timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (text == null) return detail;
    return detail.copyWith(
      localName: text.name,
      localDescription: text.overview,
      localGenres: text.genres.isEmpty ? null : text.genres,
    );
  }

  static Future<LocalText?> forImdbId(
    String imdbId, {
    required bool series,
  }) async {
    if (!_wantsChinese || !TmdbService.hasScraperKey) return null;
    if (_cache.containsKey(imdbId)) return _cache[imdbId];
    // One request per title however many cards ask at once.
    return _pending[imdbId] ??=
        _lookUp(
          imdbId,
          series: series,
          // A block, not an arrow: `remove` returns this very future, and
          // whenComplete would wait on it - for ever.
        ).whenComplete(() {
          _pending.remove(imdbId);
        });
  }

  static final Map<String, Future<LocalText?>> _pending = {};

  static Future<LocalText?> _lookUp(
    String imdbId, {
    required bool series,
  }) async {
    try {
      var hit = await _find(imdbId, series: series, language: 'zh-CN');
      if (hit == null) return _cache[imdbId] = null;
      var overview = hit['overview']?.toString().trim() ?? '';
      if (overview.isEmpty) {
        final tw = await _find(imdbId, series: series, language: 'zh-TW');
        if (tw != null &&
            (tw['overview']?.toString().trim() ?? '').isNotEmpty) {
          hit = tw;
          overview = tw['overview'].toString().trim();
        }
      }
      final isTv =
          hit['media_type'] == 'tv' || hit.containsKey('first_air_date');
      final names = await _genreNamesFor(isTv ? 'tv' : 'movie');
      final genres = <String>[
        for (final id in (hit['genre_ids'] as List? ?? const []))
          if (id is int && names[id] != null) names[id]!,
      ];
      final name = (hit['title'] ?? hit['name'])?.toString().trim();
      return _cache[imdbId] = LocalText(
        name: (name == null || name.isEmpty) ? null : name,
        overview: overview.isEmpty ? null : overview,
        genres: genres,
        tmdbId: hit['id'] is int ? hit['id'] as int : null,
        isTv: isTv,
      );
    } catch (e) {
      debugPrint('[LocalizedMeta] $imdbId: $e');
      return null;
    }
  }

  static Future<Map?> _find(
    String imdbId, {
    required bool series,
    required String language,
  }) async {
    final params = {'external_source': 'imdb_id', 'language': language};
    var found = await TmdbService.getScraperJson('/find/$imdbId', params);
    if (found == null) {
      // At start-up every rail and card asks at once and TMDb's answers can
      // miss the client's deadline; one retry, a moment later.
      await Future<void>.delayed(const Duration(seconds: 2));
      found = await TmdbService.getScraperJson('/find/$imdbId', params);
    }
    // No answer is not "no match": thrown, so it is not cached as one and the
    // next ask tries again.
    if (found == null) throw StateError('TMDb did not answer');
    final tv = found['tv_results'] as List? ?? const [];
    final movies = found['movie_results'] as List? ?? const [];
    final first = series
        ? (tv.isNotEmpty ? tv : movies)
        : (movies.isNotEmpty ? movies : tv);
    final hit = first.isEmpty ? null : first.first;
    return hit is Map ? hit : null;
  }

  static Future<Map<int, String>> _genreNamesFor(String kind) async {
    final cached = _genreNames[kind];
    if (cached != null) return cached;
    final body = await TmdbService.getScraperJson('/genre/$kind/list', {
      'language': 'zh-CN',
    });
    final map = <int, String>{
      for (final g in (body?['genres'] as List? ?? const []))
        if (g is Map && g['id'] is int)
          g['id'] as int:
              _untranslated[g['name'].toString()] ?? g['name'].toString(),
    };
    if (map.isNotEmpty) _genreNames[kind] = map;
    return map;
  }

  static final Map<String, Future<List<CastMember>?>> _cast = {};

  /// The leading cast in the viewer's language: TMDb's credits in zh-CN
  /// name 吴秀波 and 汤姆·希德勒斯顿 where Cinemeta has Xiubo Wu and Tom
  /// Hiddleston. Asked only by the details page, so rows cost nothing more.
  /// Null in English, without a TMDb match, or on failure.
  static Future<List<CastMember>?> castFor(
    String imdbId, {
    required bool series,
    int limit = 10,
  }) {
    final known = _cast[imdbId];
    if (known != null) return known;
    final lookup = () async {
      final text = await forImdbId(imdbId, series: series);
      final id = text?.tmdbId;
      if (id == null) return null;
      final body = await TmdbService.getScraperJson(
        '/${text!.isTv ? 'tv' : 'movie'}/$id/credits',
        {'language': 'zh-CN'},
      );
      final names = <CastMember>[
        for (final c in (body?['cast'] as List? ?? const []).take(limit))
          if (c is Map && (c['name']?.toString().trim() ?? '').isNotEmpty)
            CastMember(
              c['name'].toString().trim(),
              searchName: c['original_name']?.toString().trim(),
              photo: c['profile_path'] == null
                  ? null
                  : 'https://image.tmdb.org/t/p/w185${c['profile_path']}',
            ),
      ];
      return names.isEmpty ? null : names;
    }();
    _cast[imdbId] = lookup;
    // A miss (offline, no key, a slow start) is asked again next time.
    lookup.then(
      (names) {
        if (names == null) _cast.remove(imdbId);
      },
      onError: (Object _) {
        _cast.remove(imdbId);
      },
    );
    return lookup;
  }

  @visibleForTesting
  static void clearCache() {
    _cast.clear();
    _cache.clear();
    _genreNames.clear();
  }
}
