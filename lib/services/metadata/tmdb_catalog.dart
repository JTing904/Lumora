import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';
import '../../models/movie/movie.dart';
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
      final results = [
        for (final r in body?['results'] as List? ?? const [])
          if (!query.liveActionOnly ||
              !((r is Map ? r['genre_ids'] : null) as List? ?? const [])
                  .contains(16))
            r,
      ];
      final movies = await Future.wait([
        for (final r in results.take(limit + 6))
          if (r is Map && r['id'] is int)
            toMovie(r, series: _isSeries(r, query), resolveImdb: resolveImdb),
      ]);
      final row = [
        for (final m in movies)
          if (m != null) m,
      ].take(limit).toList();
      _rows[key] = (DateTime.now(), row);
      return row.where((m) => !exclude.contains(m.id)).toList();
    } catch (e) {
      debugPrint('[TmdbCatalog] ${query.path}: $e');
      return const [];
    }
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
    final imdb = ids?['imdb_id']?.toString();
    final valid = imdb != null && imdb.startsWith('tt') ? imdb : null;
    _imdbIds[idKey] = valid;
    return valid;
  }

  /// [movie] with its IMDb id, when it still has the `tmdb:kind:id` one a
  /// lazily built row gives it. Null when TMDb lists no IMDb id, which the
  /// app cannot play.
  static Future<Movie?> resolve(Movie movie) async {
    final parts = movie.id.split(':');
    if (parts.length != 3 || parts[0] != 'tmdb') return movie;
    final tmdbId = int.tryParse(parts[2]);
    if (tmdbId == null) return null;
    final imdb = await _imdbFor(parts[1], tmdbId);
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
}
