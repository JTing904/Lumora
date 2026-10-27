import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/env_service.dart';
import '../../metadata/tmdb_service.dart';
import '../title_match.dart';

class TmdbHelper {
  /// Optional keyless TMDb fallback host. There is no default: the upstream
  /// developer's proxy stays off unless `TMDB_PROXY_BASE` names a host, so a
  /// keyless install resolves metadata through a TMDb key or not at all.
  static String? get _tmdbProxy {
    final value = EnvService.tmdbProxyBase;
    return value.isEmpty ? null : value;
  }

  /// Whether a keyed TMDb call is available. Without one the only routes left
  /// are the keyless proxy and a local guess, so we resolve to a negative id
  /// rather than sending `?api_key=` with nothing after it.
  static bool get _hasKey => TmdbService.hasScraperKey;

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'Accept': 'application/json',
  };

  static final Map<String, int> _cache = {};

  /// The bare id a scraper was handed: `tt…` for IMDb, digits for TMDb, or
  /// empty. Accepts `tt123:1:2`, `tmdb:123`, `tmdb:tv:123` and `tv:123`.
  static String _bareId(String? raw) {
    final parts = (raw ?? '').trim().split(':');
    if (parts.first.toLowerCase().startsWith('tt')) return parts.first;
    for (final part in parts) {
      if (RegExp(r'^\d+$').hasMatch(part)) return part;
    }
    return '';
  }

  /// The search hit that is the requested title, or null.
  ///
  /// There is no "first result" fallback: a search for a shared name returns
  /// every title that carries it, and guessing is how a viewer ends up on the
  /// live-action series when they opened the animation.
  @visibleForTesting
  static Map? pickSearchHit(List? results, String title, int? year) {
    Map? best;
    var bestScore = 0;
    for (final item in results ?? const []) {
      if (item is! Map) continue;
      final date = (item['release_date'] ?? item['first_air_date'] ?? '').toString();
      final itemYear = leadingYear(date);
      for (final name in [
        item['title'],
        item['name'],
        item['original_title'],
        item['original_name'],
      ].whereType<String>()) {
        if (!isSameTitle(title, name, wantedYear: year, candidateYear: itemYear)) {
          continue;
        }
        // An exact year outranks a neighbouring one; an exact title outranks
        // a word match.
        final score = titleMatchScore(title, name) * 2 +
            (year != null && itemYear == year ? 1 : 0);
        if (score > bestScore) {
          bestScore = score;
          best = item;
        }
      }
    }
    return best;
  }

  static Future<int?> resolveTmdbId({
    String? imdbId,
    required String title,
    required String type,
    int? year,
  }) async {
    final cacheKey = '${imdbId ?? ""}|$title|$type|${year ?? ""}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    final cleanId = _bareId(imdbId);
    final isTv = (type == 'tv' || type == 'series');
    final endpoint = isTv ? 'tv' : 'movie';
    final resultsKey = isTv ? 'tv_results' : 'movie_results';

    int? remember(int? id) {
      if (id != null) _cache[cacheKey] = id;
      return id;
    }

    // 1. Direct numeric ID
    if (RegExp(r'^\d+$').hasMatch(cleanId)) return remember(int.parse(cleanId));

    // 2. IMDb id through TMDb's find endpoint. Keyed calls go through
    // TmdbService so a v4 read token works as well as a v3 key.
    if (cleanId.startsWith('tt')) {
      if (_hasKey) {
        final found = await TmdbService.getScraperJson('/find/$cleanId', {
          'external_source': 'imdb_id',
        });
        final hits = found?[resultsKey] as List?;
        if (hits != null && hits.isNotEmpty) {
          final id = remember(hits.first['id'] as int?);
          if (id != null) return id;
        }
      }
      final proxy = _tmdbProxy;
      if (proxy != null) {
        try {
          final uri = Uri.parse('$proxy/find/$cleanId?external_source=imdb_id');
          final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));
          if (res.statusCode == 200) {
            final hits = jsonDecode(res.body)[resultsKey] as List?;
            if (hits != null && hits.isNotEmpty) {
              final id = remember(hits.first['id'] as int?);
              if (id != null) return id;
            }
          }
        } catch (_) {}
      }
    }

    // 3. Search by title, accepting only a hit whose title and year agree.
    if (title.isEmpty) return null;
    if (_hasKey) {
      final found = await TmdbService.getScraperJson('/search/$endpoint', {
        'query': title,
        if (year != null) (isTv ? 'first_air_date_year' : 'year'): '$year',
      });
      final hit = pickSearchHit(found?['results'] as List?, title, year);
      final id = remember(hit?['id'] as int?);
      if (id != null) return id;
    }
    final proxy = _tmdbProxy;
    if (proxy != null) {
      try {
        final uri = Uri.parse('$proxy/search/$endpoint?query=${Uri.encodeComponent(title)}');
        final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final hit = pickSearchHit(jsonDecode(res.body)['results'] as List?, title, year);
          final id = remember(hit?['id'] as int?);
          if (id != null) return id;
        }
      } catch (_) {}
    }
    return null;
  }

  static final Map<String, String?> _imdbCache = {};

  /// The IMDb id of a TMDb title (`tmdb:123`, `tmdb:tv:123` or `123`), or null
  /// when TMDb lists none or cannot be reached.
  static Future<String?> imdbIdFor(String id, String type) async {
    final tmdbId = _bareId(id);
    if (!RegExp(r'^\d+$').hasMatch(tmdbId)) return null;
    final endpoint = (type == 'tv' || type == 'series') ? 'tv' : 'movie';
    final key = '$endpoint/$tmdbId';
    if (_imdbCache.containsKey(key)) return _imdbCache[key];
    final ids = await TmdbService.getScraperJson('/$key/external_ids');
    final imdb = ids?['imdb_id']?.toString() ?? '';
    return _imdbCache[key] = imdb.startsWith('tt') ? imdb : null;
  }

  static final Map<String, int?> _seasonSizeCache = {};

  /// Whether TMDb has episode [episode] of season [season] for the series
  /// [id] (an IMDb or TMDb id): true or false when TMDb answered, null when
  /// it could not be asked. Null must not be read as "missing".
  static Future<bool?> hasEpisode(String? id, int season, int episode) async {
    final tmdbId = await resolveTmdbId(imdbId: id, title: '', type: 'series');
    if (tmdbId == null) return null;
    final key = '$tmdbId/$season';
    if (!_seasonSizeCache.containsKey(key)) {
      final show = await TmdbService.getScraperJson('/tv/$tmdbId');
      if (show == null) return null;
      for (final s in (show['seasons'] as List? ?? const [])) {
        if (s is! Map) continue;
        _seasonSizeCache['$tmdbId/${s['season_number']}'] =
            (s['episode_count'] as num?)?.toInt();
      }
      _seasonSizeCache.putIfAbsent(key, () => 0);
    }
    final size = _seasonSizeCache[key];
    if (size == null) return null;
    return episode >= 1 && episode <= size;
  }

  static final Map<String, TitleFacts?> _factsCache = {};

  /// What TMDb says the requested title is, for sources that can only search
  /// by name.
  ///
  /// A name alone cannot tell "A Mortal's Journey" the 2020 donghua from the
  /// 2025 live-action drama, and a source that picks the wrong one plays the
  /// wrong show without any error. Null when TMDb cannot be reached or does
  /// not know the title, so callers fall back to their own matching.
  static Future<TitleFacts?> titleFacts({
    String? imdbId,
    required String title,
    required String type,
    int? year,
  }) async {
    final isTv = type == 'tv' || type == 'series';
    final endpoint = isTv ? 'tv' : 'movie';
    final id = _bareId(imdbId);

    final cacheKey = '$endpoint|$id|$title|${year ?? ''}';
    if (_factsCache.containsKey(cacheKey)) return _factsCache[cacheKey];

    int? tmdbId = int.tryParse(id);
    try {
      if (tmdbId == null && id.startsWith('tt')) {
        final found = await TmdbService.getScraperJson('/find/$id', {
          'external_source': 'imdb_id',
        });
        final hits = found?[isTv ? 'tv_results' : 'movie_results'] as List?;
        if (hits != null && hits.isNotEmpty) tmdbId = hits.first['id'] as int?;
      }
      if (tmdbId == null && title.isNotEmpty) {
        final found = await TmdbService.getScraperJson('/search/$endpoint', {
          'query': title,
          if (year != null) (isTv ? 'first_air_date_year' : 'year'): '$year',
        });
        tmdbId = pickSearchHit(found?['results'] as List?, title, year)?['id']
            as int?;
      }
      if (tmdbId == null) return _factsCache[cacheKey] = null;

      final detail = await TmdbService.getScraperJson('/$endpoint/$tmdbId');
      if (detail == null) return _factsCache[cacheKey] = null;
      final genres = (detail['genres'] as List? ?? const [])
          .map((g) => (g as Map)['id'])
          .toSet();
      final date =
          (detail['first_air_date'] ?? detail['release_date'] ?? '').toString();
      return _factsCache[cacheKey] = TitleFacts(
        tmdbId: tmdbId,
        isAnimation: genres.contains(TitleFacts.animationGenreId),
        year: date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The facts [TmdbHelper.titleFacts] resolves for one title.
class TitleFacts {
  const TitleFacts({
    required this.tmdbId,
    required this.isAnimation,
    this.year,
  });

  /// TMDb's genre id for Animation, the same on movies and TV.
  static const int animationGenreId = 16;

  final int tmdbId;

  /// Animated (anime, donghua, cartoons) as opposed to live action.
  final bool isAnimation;

  /// First air or release year.
  final int? year;
}
