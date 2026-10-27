import '../content/adult_guard.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';
import '../../models/movie/movie.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/movie/video.dart';
import 'tmdb_service.dart';

/// One TMDb list: an endpoint and its query.
@immutable
class TmdbQuery {
  const TmdbQuery(
    this.path, [
    this.params = const {},
    this.liveActionOnly = false,
  ]);

  /// '/discover/tv', '/trending/movie/week', '/movie/now_playing' ...
  final String path;
  final Map<String, String> params;

  /// Drop animated titles from the answer, for lists TMDb cannot filter by
  /// genre itself: trending put 药屋少女的呢喃 at the top of 电视剧.
  final bool liveActionOnly;

  bool get series => path.contains('/tv');

  String get cacheKey =>
      '$path?${(params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}=${e.value}').join('&')}';

  /// Popular titles of one kind, the way the category pages and 为你推荐 ask
  /// for them: by origin country, animated or not, most popular first.
  factory TmdbQuery.discover({
    required bool series,
    String? region,
    String? language,
    bool? animated,
    String sortBy = 'popularity.desc',
    int minVotes = 20,
  }) => TmdbQuery('/discover/${series ? 'tv' : 'movie'}', {
    'sort_by': sortBy,
    'vote_count.gte': '$minVotes',
    'include_adult': 'false',
    if (region != null) 'with_origin_country': region,
    if (language != null) 'with_original_language': language,
    if (animated == true) 'with_genres': '16',
    if (animated == false) 'without_genres': '16',
  });

  /// 最近更新: series with an episode out in the last week, or films out
  /// online or on disc (release types 4 and 5) in the last three months -
  /// what has just become watchable, most popular first.
  factory TmdbQuery.recentlyUpdated({
    required bool series,
    String? region,
    bool? animated,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    final from = today.subtract(Duration(days: series ? 7 : 90));
    return TmdbQuery('/discover/${series ? 'tv' : 'movie'}', {
      'sort_by': 'popularity.desc',
      'include_adult': 'false',
      'vote_count.gte': '5',
      if (series) ...{
        'air_date.gte': day(from),
        'air_date.lte': day(today),
      } else ...{
        'release_date.gte': day(from),
        'release_date.lte': day(today),
        'with_release_type': '4|5',
      },
      if (region != null) 'with_origin_country': region,
      if (animated == true) 'with_genres': '16',
      // Talk shows and news air every night and would fill the row.
      if (animated == false) 'without_genres': series ? '16,10767,10763' : '16',
    });
  }
}

/// TMDb lists as rows the app can play: names, posters and synopses in the
/// viewer's language, and the IMDb id every title is played by.
///
/// The IMDb ids cost one request per title, so they are cached for the
/// session, and a row is cached whole for ten minutes.
abstract final class TmdbCatalog {
  static const String _cinemeta = 'https://v3-cinemeta.strem.io';
  static final Map<String, String?> _imdbIds = {};
  static final Map<String, (DateTime, List<Movie>)> _rows = {};

  static String get _language =>
      l10nCurrent().localeName == 'zh' ? 'zh-CN' : 'en-US';

  /// The titles of [query], up to [limit], skipping any without an IMDb id
  /// and any in [exclude].
  ///
  /// With [resolveImdb] false the titles keep a `tmdb:tv:123` id and cost no
  /// request each; [resolve] turns one into its IMDb id when it is opened.
  /// Category pages list nine rows of twenty, and resolving every one up
  /// front was some two hundred requests per page.
  static Future<List<Movie>> row(
    TmdbQuery query, {
    int limit = 20,
    Set<String> exclude = const {},
    bool resolveImdb = true,
  }) async {
    if (!TmdbService.hasScraperKey) return const [];
    final key =
        '${query.cacheKey}|${query.liveActionOnly}|$_language|$limit|$resolveImdb';
    final cached = _rows[key];
    if (cached != null &&
        DateTime.now().difference(cached.$1) < const Duration(minutes: 10)) {
      return cached.$2.where((m) => !exclude.contains(m.id)).toList();
    }
    try {
      final body = await TmdbService.getScraperJson(query.path, {
        'page': '1',
        ...query.params,
        'language': _language,
      });
      // A failed read is not cached, so the next ask (Home's Retry) reads
      // again instead of serving the empty row for ten minutes.
      if (body == null) return const [];
      final results = [
        for (final r in body['results'] as List? ?? const [])
          if (r is Map &&
              _isTitle(r) &&
              (AdultGuard.allowed ||
                  !AdultGuard.looksAdult([
                    r['title']?.toString(),
                    r['name']?.toString(),
                    r['original_title']?.toString(),
                    r['original_name']?.toString(),
                  ], flagged: r['adult'] == true)))
            if (!query.liveActionOnly ||
                !(r['genre_ids'] as List? ?? const []).contains(16))
              r,
      ];
      final movies = await Future.wait([
        for (final r in results.take(limit + 6))
          if (r['id'] is int)
            toMovie(r, series: _isSeries(r, query), resolveImdb: resolveImdb),
      ]);
      final row = [
        for (final m in movies)
          if (m != null) m,
      ].take(limit).toList();
      // Titles listed but none resolved means the id lookups failed: leave
      // that uncached too.
      if (row.isNotEmpty || results.isEmpty) {
        _rows[key] = (DateTime.now(), row);
      }
      return row.where((m) => !exclude.contains(m.id)).toList();
    } catch (e) {
      debugPrint('[TmdbCatalog] ${query.path}: $e');
      return const [];
    }
  }

  /// Whether a result is a film or a series: /search/multi and
  /// /trending/all also answer people (and could answer collections).
  static bool _isTitle(Map r) {
    final mediaType = r['media_type']?.toString();
    return mediaType == null || mediaType == 'movie' || mediaType == 'tv';
  }

  static bool _isSeries(Map r, TmdbQuery query) {
    final mediaType = r['media_type']?.toString();
    if (mediaType != null) return mediaType == 'tv';
    return query.series;
  }

  /// One TMDb result as a playable row item, or null without an IMDb id.
  static Future<Movie?> toMovie(
    Map r, {
    required bool series,
    bool resolveImdb = true,
  }) async {
    final tmdbId = r['id'] as int;
    final kind = series ? 'tv' : 'movie';
    final String id;
    if (resolveImdb) {
      final imdb = await _imdbFor(kind, tmdbId);
      if (imdb == null) return null;
      id = imdb;
    } else {
      id = 'tmdb:$kind:$tmdbId';
    }
    final date = (r['first_air_date'] ?? r['release_date'] ?? '').toString();
    final poster = r['poster_path']?.toString();
    final backdrop = r['backdrop_path']?.toString();
    final vote = (r['vote_average'] as num?)?.toDouble();
    return Movie(
      id: id,
      name: (r['name'] ?? r['title'] ?? '').toString(),
      type: series ? 'series' : 'movie',
      year: date.length >= 4 ? date.substring(0, 4) : null,
      poster: poster == null ? null : 'https://image.tmdb.org/t/p/w342$poster',
      backdrop: backdrop == null
          ? null
          : 'https://image.tmdb.org/t/p/w1280$backdrop',
      imdbRating: vote == null || vote == 0 ? null : vote.toStringAsFixed(1),
      description: r['overview']?.toString(),
      addonBaseUrl: _cinemeta,
    );
  }

  static Future<String?> _imdbFor(String kind, int tmdbId) async {
    final idKey = '$kind/$tmdbId';
    if (_imdbIds.containsKey(idKey)) return _imdbIds[idKey];
    final ids = await TmdbService.getScraperJson('/$kind/$tmdbId/external_ids');
    // A failed read says nothing about the title: only an answer is cached.
    if (ids == null) return null;
    final imdb = ids['imdb_id']?.toString();
    final valid = imdb != null && imdb.startsWith('tt') ? imdb : null;
    _imdbIds[idKey] = valid;
    return valid;
  }

  /// [movie] with its IMDb id, when it still has the `tmdb:kind:id` one a
  /// lazily built row gives it. Null when TMDb lists no IMDb id, which the
  /// app cannot play, or when a `tmdb:` id is malformed.
  static Future<Movie?> resolve(Movie movie) async {
    if (!movie.id.startsWith('tmdb:')) return movie;
    final ref = tmdbRef(movie);
    if (ref == null) return null;
    final imdb = await _imdbFor(ref.kind, ref.id);
    if (imdb == null) return null;
    return Movie(
      id: imdb,
      name: movie.name,
      poster: movie.poster,
      year: movie.year,
      type: movie.type,
      addonBaseUrl: movie.addonBaseUrl,
      imdbRating: movie.imdbRating,
      backdrop: movie.backdrop,
      trailerKey: movie.trailerKey,
      description: movie.description,
    );
  }

  /// The kind ('movie' or 'tv') and TMDb id a `tmdb:` id names, or null when
  /// it is malformed. A bare `tmdb:123` (older My List rows) takes its kind
  /// from [Movie.type] when that says which; otherwise it cannot be told.
  @visibleForTesting
  static ({String kind, int id})? tmdbRef(Movie movie) {
    final parts = movie.id.split(':');
    if (parts.isEmpty || parts[0] != 'tmdb') return null;
    if (parts.length == 3) {
      final tmdbId = int.tryParse(parts[2]);
      if (tmdbId == null || (parts[1] != 'movie' && parts[1] != 'tv')) {
        return null;
      }
      return (kind: parts[1], id: tmdbId);
    }
    if (parts.length == 2) {
      final tmdbId = int.tryParse(parts[1]);
      final kind = switch (movie.type) {
        'movie' => 'movie',
        'series' || 'tv' => 'tv',
        _ => null,
      };
      if (tmdbId == null || kind == null) return null;
      return (kind: kind, id: tmdbId);
    }
    return null;
  }

  /// Details for a `tmdb:kind:id` title straight from TMDb, in the viewer's
  /// language: for a title TMDb lists no IMDb id for (new donghua and short
  /// dramas often have none), which the addons cannot describe. Series come
  /// with their seasons' episodes. Null when TMDb does not answer.
  static Future<MovieDetail?> detailFromTmdb(Movie row) async {
    final ref = tmdbRef(row);
    if (ref == null) return null;
    final kind = ref.kind;
    final tmdbId = ref.id;
    final rowId = 'tmdb:$kind:$tmdbId';
    final body = await TmdbService.getScraperJson('/$kind/$tmdbId', {
      'language': _language,
    });
    if (body == null) return null;
    final series = kind == 'tv';
    final videos = <Video>[];
    if (series) {
      final seasons = [
        for (final s in body['seasons'] as List? ?? const [])
          if (s is Map && s['season_number'] is int) s['season_number'] as int,
      ];
      final pages = await Future.wait([
        for (final n in seasons.take(12))
          TmdbService.getScraperJson('/tv/$tmdbId/season/$n', {
            'language': _language,
          }),
      ]);
      for (final page in pages) {
        for (final e in page?['episodes'] as List? ?? const []) {
          if (e is! Map) continue;
          final s = e['season_number'] as int?;
          final n = e['episode_number'] as int?;
          if (s == null || n == null) continue;
          final still = e['still_path']?.toString();
          final name = (e['name'] ?? '').toString();
          videos.add(
            Video(
              id: '$rowId:$s:$n',
              title: name.isEmpty ? 'Episode $n' : name,
              season: s,
              episode: n,
              released: e['air_date']?.toString(),
              thumbnail: still == null
                  ? null
                  : 'https://image.tmdb.org/t/p/w300$still',
              overview: (e['overview']?.toString() ?? '').isEmpty
                  ? null
                  : e['overview'].toString(),
            ),
          );
        }
      }
    }
    final date = (body['first_air_date'] ?? body['release_date'] ?? '')
        .toString();
    final poster = body['poster_path']?.toString();
    final backdrop = body['backdrop_path']?.toString();
    final vote = (body['vote_average'] as num?)?.toDouble();
    final minutes = series
        ? ((body['episode_run_time'] as List?)?.firstOrNull as num?)?.toInt()
        : (body['runtime'] as num?)?.toInt();
    return MovieDetail(
      id: rowId,
      type: series ? 'series' : 'movie',
      name: (body['name'] ?? body['title'] ?? row.name).toString(),
      poster: poster == null
          ? row.poster
          : 'https://image.tmdb.org/t/p/w500$poster',
      background: backdrop == null
          ? row.backdrop
          : 'https://image.tmdb.org/t/p/w1280$backdrop',
      description: body['overview']?.toString(),
      year: date.length >= 4 ? date.substring(0, 4) : row.year,
      imdbRating: vote == null || vote == 0 ? null : vote.toStringAsFixed(1),
      genres: [
        for (final g in body['genres'] as List? ?? const [])
          if (g is Map && g['name'] != null) g['name'].toString(),
      ],
      runtime: minutes == null || minutes == 0 ? null : '$minutes min',
      videos: videos,
      tmdbId: '$tmdbId',
    );
  }
}
