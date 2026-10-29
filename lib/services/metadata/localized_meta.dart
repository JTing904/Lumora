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

  static final Map<String, Future<LocalText?>> _byTitle = {};

  /// The viewer's-language name of a title known only by its English
  /// [title] and [year] (the similar-titles rail has no IMDb id): TMDb's
  /// search in zh-CN, kept only when the hit's original or English name is
  /// [title] and its year matches. Null in English or on any doubt.
  static Future<String?> forTitle(
    String title, {
    String? year,
    required bool series,
  }) => textForTitle(title, year: year, series: series).then((t) => t?.name);

  /// [forTitle]'s name with the synopsis of the same TMDb title: AniList's
  /// spotlight has only English text, and TMDb usually has a Chinese
  /// synopsis. A later season ("Season 2") gets that season's synopsis when
  /// TMDb has one, the show's otherwise.
  static Future<LocalText?> textForTitle(
    String title, {
    String? year,
    required bool series,
  }) {
    if (!_wantsChinese) return Future.value(null);
    final key = '${series ? 'tv' : 'movie'}|${title.toLowerCase()}|$year';
    final known = _byTitle[key];
    if (known != null) return known;
    final lookup = () async {
      // "Black Clover Season 2" is not a title TMDb knows; the show is
      // 黑色四叶草, and the season goes back on the end. A later season's
      // year is not the show's, so the year is not asked then. A bare
      // trailing number ("Cyberpunk: Edgerunners 2") is tried as a season
      // too, but only after the whole title, which may end in a number of
      // its own (Mob Psycho 100).
      final asks = <({String base, int? season, String? year})>[];
      final split = _seasonSuffix.firstMatch(title);
      final suffixSeason = split == null
          ? null
          : int.tryParse(split[2] ?? split[3] ?? split[4] ?? '');
      if (suffixSeason != null) {
        asks.add((base: split![1]!.trim(), season: suffixSeason, year: null));
      } else {
        asks.add((base: title, season: null, year: year));
        final numbered = _trailingNumber.firstMatch(title);
        final n = int.tryParse(numbered?[2] ?? '');
        if (numbered != null && n != null && n >= 2 && n <= 30) {
          asks.add((base: numbered[1]!.trim(), season: n, year: null));
        }
      }

      Future<Map<String, dynamic>?> search(
        ({String base, int? season, String? year}) a,
        bool tv,
        String language,
      ) => TmdbService.getScraperJson(tv ? '/search/tv' : '/search/movie', {
        'query': a.base,
        'language': language,
        if (a.year != null && a.year!.length == 4)
          (tv ? 'first_air_date_year' : 'year'): a.year!,
      });

      // The title itself: the result whose English (or original) name is
      // the asked name. TMDb's top hit alone was not enough - "Your Name."
      // in 2016 topped with another film, and Slime's "Season 2" with its
      // spin-off. The similar-titles rail calls some donghua films, so the
      // other kind is asked when the first has nothing. A season is only
      // ever a TV show's.
      ({bool tv, int id})? hit;
      var ask = asks.first;
      for (final a in asks) {
        for (final tv in a.season == null ? [series, !series] : [true]) {
          final body = await search(a, tv, 'en-US');
          for (final r in body?['results'] as List? ?? const []) {
            if (r is! Map || r['id'] is! int) continue;
            final en = (r['name'] ?? r['title'] ?? '').toString();
            final original = (r['original_name'] ?? r['original_title'] ?? '')
                .toString();
            if (_bare(en) == _bare(a.base) ||
                _bare(original) == _bare(a.base)) {
              hit = (tv: tv, id: r['id'] as int);
              break;
            }
          }
          if (hit != null) break;
        }
        if (hit != null) {
          ask = a;
          break;
        }
      }
      // No English match: the Chinese search's own pick ([_pick]) for the
      // title as given.
      if (hit == null) {
        for (final tv in ask.season == null ? [series, !series] : [true]) {
          final r = _pick(await search(ask, tv, 'zh-CN'), ask.base, ask.year);
          if (r != null && r['id'] is int) {
            hit = (tv: tv, id: r['id'] as int);
            break;
          }
        }
      }
      if (hit == null) return null;
      final season = ask.season;
      final want = _bare(ask.base);
      final path = '/${hit.tv ? 'tv' : 'movie'}/${hit.id}';

      String? nameOf(Map? r) {
        final n = (r?['name'] ?? r?['title'])?.toString().trim() ?? '';
        // TMDb answers the English or the original (Japanese, 薬屋のひとりごと)
        // name when it has no Chinese one; neither is a translation.
        return _han.hasMatch(n) && !_kana.hasMatch(n) && _bare(n) != want
            ? n
            : null;
      }

      String? overviewOf(Map? r) {
        final o = r?['overview']?.toString().trim() ?? '';
        return _han.hasMatch(o) && !_kana.hasMatch(o) ? o : null;
      }

      final cn = await TmdbService.getScraperJson(path, {'language': 'zh-CN'});
      var name = nameOf(cn);
      var overview = overviewOf(cn);
      if (name == null || overview == null) {
        final tw = await TmdbService.getScraperJson(path, {
          'language': 'zh-TW',
        });
        name ??= nameOf(tw);
        overview ??= overviewOf(tw);
      }
      if (season != null && hit.tv) {
        final page = await TmdbService.getScraperJson('$path/season/$season', {
          'language': 'zh-CN',
        });
        overview = overviewOf(page) ?? overview;
      }
      if (name == null && overview == null) return null;
      return LocalText(
        name: name == null || season == null ? name : '$name 第$season季',
        overview: overview,
        tmdbId: hit.id,
        isTv: hit.tv,
      );
    }();
    _byTitle[key] = lookup;
    lookup.then(
      (text) {
        if (text == null) _byTitle.remove(key);
      },
      onError: (Object _) {
        _byTitle.remove(key);
      },
    );
    return lookup;
  }

  static final RegExp _kana = RegExp(r'[぀-ヿ]');
  static final RegExp _han = RegExp(r'[一-鿿]');
  static final RegExp _trailingNumber = RegExp(r'^(.+?\D)\s+(\d{1,2})$');

  static final RegExp _seasonSuffix = RegExp(
    r'^(.+?)[\s:]+(?:season\s*(\d{1,2})|(\d{1,2})(?:st|nd|rd|th)\s+season|part\s*(\d{1,2}))\s*$',
    caseSensitive: false,
  );

  /// TMDb's zh-CN record for [title] among search [body]'s results.
  static Map? _pick(Map<String, dynamic>? body, String title, String? year) {
    final want = _bare(title);
    final results = body?['results'] as List? ?? const [];
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      if (r is! Map) continue;
      final original = (r['original_name'] ?? r['original_title'] ?? '')
          .toString();
      final date = (r['first_air_date'] ?? r['release_date'] ?? '').toString();
      if (year != null && year.length == 4 && !date.startsWith(year)) {
        continue;
      }
      final local = (r['name'] ?? r['title'] ?? '').toString().trim();
      // TMDb's zh-CN search answers the English name when it has no
      // Chinese one; only a different name is a translation.
      if (local.isEmpty || _bare(local) == want) continue;
      // The English name a rail shows is often not the original (a donghua
      // is 斗破苍穹 originally), so TMDb's top hit for that name and year
      // also counts; a lower hit only when its original name is the title.
      if (_bare(original) == want || i == 0) return r;
    }
    return null;
  }

  static String _bare(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9一-鿿]'), '');

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
