import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';
import '../../models/addon/addon.dart';
import '../../models/movie/movie.dart';
import '../../models/movie/movie_section.dart';
import '../metadata/tmdb_catalog.dart';
import '../metadata/tmdb_service.dart';
import 'taste_profile.dart';
import 'taste_store.dart';

/// "为你推荐": rows of titles of the kinds the viewer watches most.
///
/// The profile ([TasteProfile]) says which kinds - 国漫, 港剧, films - and
/// TMDb's discover endpoint fills each with popular titles of that kind the
/// viewer has not touched. Facts for history entries are looked up once and
/// kept on the entry. Without a TMDb key, or without history, there are no
/// rows; Home's other rails stand on their own.
abstract final class Recommender {
  static const String _cinemeta = 'https://v3-cinemeta.strem.io';
  static const int _rowLength = 20;

  /// How many kinds get a row.
  static const int maxRows = 2;

  /// Looks up [TasteFacets] for every history entry that has none yet.
  static Future<void> fillFacets() async {
    if (!TmdbService.hasScraperKey) return;
    final missing = TasteStore.entries.value.values
        .where((e) => e.facets == null && e.id.startsWith('tt'))
        .take(40)
        .toList();
    for (final e in missing) {
      final facets = await facetsFor(e.id, series: e.series);
      if (facets != null) TasteStore.setFacets(e.id, facets);
    }
  }

  /// What TMDb says [imdbId] is.
  static Future<TasteFacets?> facetsFor(
    String imdbId, {
    required bool series,
  }) async {
    try {
      final found = await TmdbService.getScraperJson('/find/$imdbId', {
        'external_source': 'imdb_id',
      });
      if (found == null) return null;
      final tv = found['tv_results'] as List? ?? const [];
      final movies = found['movie_results'] as List? ?? const [];
      final isTv = series ? tv.isNotEmpty || movies.isEmpty : tv.isNotEmpty && movies.isEmpty;
      final hit = (isTv ? tv : movies).firstOrNull ?? (isTv ? movies : tv).firstOrNull;
      if (hit is! Map) return null;
      final id = hit['id'];
      if (id is! int) return null;
      final detail = await TmdbService.getScraperJson(
        '/${isTv ? 'tv' : 'movie'}/$id',
      );
      final countries = <String>[
        for (final c in (detail?['origin_country'] as List? ?? const []))
          c.toString(),
        for (final c in (detail?['production_countries'] as List? ?? const []))
          if (c is Map && c['iso_3166_1'] != null) c['iso_3166_1'].toString(),
      ];
      final genres = <int>[
        for (final g in (hit['genre_ids'] as List? ?? const []))
          if (g is int) g,
      ];
      return TasteFacets(
        region: countries.isEmpty ? '' : countries.first,
        animated: genres.contains(16),
        series: isTv,
        genres: genres,
      );
    } catch (e) {
      debugPrint('[Recommender] facts for $imdbId failed: $e');
      return null;
    }
  }

  /// One row per top kind, best kind first.
  static Future<List<MovieSection>> sections({DateTime? now}) async {
    if (!TmdbService.hasScraperKey) return const [];
    await fillFacets();
    final profile = TasteProfile.build(TasteStore.entries.value.values, now: now);
    if (profile.isEmpty) return const [];

    final rows = <MovieSection>[];
    for (final kind in profile.kinds.take(maxRows)) {
      final movies = await _discover(kind.key, profile);
      if (movies.length < 4) continue;
      final zh = l10nCurrent().localeName == 'zh';
      final name = tasteKindName(kind.key, zh: zh);
      final series = kind.key.endsWith('|tv');
      rows.add(
        MovieSection(
          title: l10nCurrent().recommendFor(name),
          subtitle: l10nCurrent().recommendBecause(name),
          contentType: series ? 'series' : 'movie',
          addonBaseUrl: _cinemeta,
          catalog: AddonCatalog(
            type: series ? 'series' : 'movie',
            id: 'taste_${kind.key}',
            name: name,
          ),
          movies: movies,
        ),
      );
    }
    return rows;
  }

  /// Popular titles of [kindKey] the viewer has not touched, with IMDb ids so
  /// the app can play them.
  static Future<List<Movie>> _discover(String kindKey, TasteProfile profile) {
    final parts = kindKey.split('|');
    return TmdbCatalog.row(
      TmdbQuery.discover(
        series: parts[2] == 'tv',
        region: parts[0].isEmpty ? null : parts[0],
        animated: parts[1] == 'anim',
      ),
      limit: _rowLength,
      exclude: profile.seen,
    );
  }
}
