import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/movie/video.dart';
import 'tmdb_service.dart';

/// One TMDb episode: its still, its name and synopsis, when it aired.
@immutable
class TmdbEpisode {
  const TmdbEpisode({
    required this.season,
    required this.episode,
    this.airDate,
    this.still,
    this.name,
    this.overview,
  });

  final int season;
  final int episode;
  final DateTime? airDate;
  final String? still;
  final String? name;
  final String? overview;
}

/// Puts TMDb's episode stills, names and synopses on a series the addons
/// describe with bare placeholders.
///
/// Cinemeta's episode images (`episodes.metahub.space/<id>/<s>/<e>`) exist
/// only for some episodes; the rest answer 404 and the card falls back to the
/// show's logo, so a long donghua showed real art on season 1 and a wall of
/// logos after it. Its names are often "Episode 4". TMDb usually has both, in
/// the viewer's language.
///
/// The two often split a show differently - 凡人修仙传 is eight seasons on
/// Cinemeta and one 209-episode season on TMDb, with four episodes Cinemeta
/// files as specials - so the episodes are aligned by air date, not by
/// number: each addon season is anchored where TMDb has an episode airing on
/// (or within a few days of) that season's first air date, and its episodes
/// follow from there in order. A season with no anchor is left as it is,
/// unless both sides number it the same way. Only the display fields change;
/// every [Video.id] stays the addon's.
abstract final class EpisodeArt {
  static final Map<String, Future<List<TmdbEpisode>?>> _cache = {};

  /// How far apart two sources' dates for the same airing may be.
  static const int anchorToleranceDays = 3;

  /// [detail] with TMDb's art and text filled in; [detail] itself when there
  /// is nothing to add or anything failed.
  static Future<MovieDetail> enrich(MovieDetail detail) async {
    final series = detail.type == 'series' || detail.type == 'tv';
    // A `tmdb:` detail was built from TMDb's own episodes already.
    if (!series || detail.videos.isEmpty || detail.id.startsWith('tmdb:')) {
      return detail;
    }
    try {
      final tmdbId = await _tmdbIdFor(detail);
      if (tmdbId == null) return detail;
      final zh = l10nCurrent().localeName == 'zh';
      final episodes = await _episodes(tmdbId, zh ? 'zh-CN' : 'en-US');
      if (episodes == null || episodes.isEmpty) return detail;
      final videos = apply(detail.videos, episodes, preferTmdbText: zh);
      return identical(videos, detail.videos)
          ? detail
          : detail.copyWith(videos: videos);
    } catch (e) {
      debugPrint('[EpisodeArt] ${detail.id}: $e');
      return detail;
    }
  }

  static Future<int?> _tmdbIdFor(MovieDetail detail) async {
    final known = int.tryParse(detail.tmdbId ?? '');
    if (known != null) return known;
    if (!detail.id.startsWith('tt')) return null;
    final found = await TmdbService.getScraperJson('/find/${detail.id}', {
      'external_source': 'imdb_id',
    });
    final tv = found?['tv_results'] as List? ?? const [];
    final hit = tv.isEmpty ? null : tv.first;
    return hit is Map && hit['id'] is int ? hit['id'] as int : null;
  }

  static Future<List<TmdbEpisode>?> _episodes(int tmdbId, String language) {
    final key = '$tmdbId|$language';
    final known = _cache[key];
    if (known != null) return known;
    final lookup = () async {
      final show = await TmdbService.getScraperJson('/tv/$tmdbId', {
        'language': language,
      });
      if (show == null) return null;
      final seasons = [
        for (final s in show['seasons'] as List? ?? const [])
          if (s is Map && s['season_number'] is int) s['season_number'] as int,
      ];
      final pages = await Future.wait([
        for (final n in seasons.take(30))
          TmdbService.getScraperJson('/tv/$tmdbId/season/$n', {
            'language': language,
          }),
      ]);
      return [
        for (final page in pages)
          for (final e in page?['episodes'] as List? ?? const [])
            if (e is Map &&
                e['season_number'] is int &&
                e['episode_number'] is int)
              TmdbEpisode(
                season: e['season_number'] as int,
                episode: e['episode_number'] as int,
                airDate: DateTime.tryParse(e['air_date']?.toString() ?? ''),
                still: e['still_path'] == null
                    ? null
                    : 'https://image.tmdb.org/t/p/w300${e['still_path']}',
                name: _text(e['name']),
                overview: _text(e['overview']),
              ),
      ];
    }();
    _cache[key] = lookup;
    // A miss (offline, a slow start) is asked again next time.
    lookup.then(
      (list) {
        if (list == null) _cache.remove(key);
      },
      onError: (Object _) {
        _cache.remove(key);
      },
    );
    return lookup;
  }

  static String? _text(Object? v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  /// `Episode 4`, `第 4 集`, `EP04`: a name that only repeats the number.
  static bool isPlaceholderName(String? name) {
    final s = name?.trim() ?? '';
    if (s.isEmpty) return true;
    return RegExp(
      r'^(?:episode|ep\.?|e)\s*\d+$|^第\s*\d+\s*[集话話]$',
      caseSensitive: false,
    ).hasMatch(s);
  }

  /// [videos] with the aligned TMDb episode's still, name and synopsis.
  /// Returns [videos] itself when nothing aligned.
  ///
  /// A still replaces the addon's image (Cinemeta's are often missing); a
  /// name replaces a placeholder, or any name when [preferTmdbText] (the
  /// viewer reads Chinese and TMDb was asked in Chinese); likewise the
  /// synopsis.
  @visibleForTesting
  static List<Video> apply(
    List<Video> videos,
    List<TmdbEpisode> tmdb, {
    required bool preferTmdbText,
  }) {
    final match = align(videos, tmdb);
    if (match.isEmpty) return videos;
    // TMDb counting the whole show as one season is the audience's own
    // numbering (第194集), so the cards show it instead of the addon's split.
    final straightThrough = _countsStraightThrough(tmdb);
    var changed = false;
    final out = <Video>[
      for (final v in videos)
        if (match[v] case final t?)
          () {
            final name = t.name != null && !isPlaceholderName(t.name)
                ? t.name
                : null;
            final title =
                name != null && (preferTmdbText || isPlaceholderName(v.title))
                ? name
                : v.title;
            final overview =
                t.overview != null &&
                    (preferTmdbText || (v.overview?.trim() ?? '').isEmpty)
                ? t.overview
                : v.overview;
            final thumbnail = t.still ?? v.thumbnail;
            final displayNumber =
                straightThrough && v.season != 0 && t.episode != v.episode
                ? t.episode
                : v.displayNumber;
            if (title == v.title &&
                overview == v.overview &&
                thumbnail == v.thumbnail &&
                displayNumber == v.displayNumber) {
              return v;
            }
            changed = true;
            return Video(
              id: v.id,
              title: title,
              season: v.season,
              episode: v.episode,
              released: v.released,
              thumbnail: thumbnail,
              overview: overview,
              streams: v.streams,
              displayNumber: displayNumber,
            );
          }()
        else
          v,
    ];
    return changed ? out : videos;
  }

  /// Whether TMDb files every regular episode under one season.
  static bool _countsStraightThrough(List<TmdbEpisode> tmdb) =>
      {
        for (final t in tmdb)
          if (t.season > 0) t.season,
      }.length ==
      1;

  /// The show-wide running number of the episode [season]x[episode] of
  /// [detail]: its place in TMDb's air order, aligned the way [align] does.
  ///
  /// This is the number official uploads and Chinese sites title an episode
  /// with. Summing the addon's earlier seasons gets it wrong whenever the
  /// addon files some episodes as specials - 凡人修仙传's four 燕家堡之战
  /// episodes made every later episode four short, so S2E1 played 燕家堡之战1
  /// instead of 魔道争锋1. Null when TMDb cannot place the episode.
  static Future<int?> runningNumber(
    MovieDetail detail, {
    required int season,
    required int episode,
  }) async {
    if (season <= 0) return null;
    try {
      final tmdbId = await _tmdbIdFor(detail);
      if (tmdbId == null) return null;
      final zh = l10nCurrent().localeName == 'zh';
      final tmdb = await _episodes(tmdbId, zh ? 'zh-CN' : 'en-US');
      if (tmdb == null || tmdb.isEmpty) return null;
      return runningNumberIn(
        detail.videos,
        tmdb,
        season: season,
        episode: episode,
      );
    } catch (_) {
      return null;
    }
  }

  /// [runningNumber] over already-fetched TMDb episodes.
  @visibleForTesting
  static int? runningNumberIn(
    List<Video> videos,
    List<TmdbEpisode> tmdb, {
    required int season,
    required int episode,
  }) {
    final match = align(videos, tmdb);
    TmdbEpisode? hit;
    for (final e in match.entries) {
      if (e.key.season == season && e.key.episode == episode) {
        hit = e.value;
        break;
      }
    }
    if (hit == null) return null;
    final flat = _flat(tmdb);
    final i = flat.indexOf(hit);
    return i < 0 ? null : i + 1;
  }

  static List<TmdbEpisode> _flat(List<TmdbEpisode> tmdb) =>
      [
        for (final t in tmdb)
          if (t.season > 0) t,
      ]..sort(
        (a, b) => a.season != b.season
            ? a.season.compareTo(b.season)
            : a.episode.compareTo(b.episode),
      );

  /// Which TMDb episode each addon episode is.
  @visibleForTesting
  static Map<Video, TmdbEpisode> align(
    List<Video> videos,
    List<TmdbEpisode> tmdb,
  ) {
    final result = <Video, TmdbEpisode>{};
    final byNumber = {for (final t in tmdb) (t.season, t.episode): t};

    // Specials: only where TMDb numbers them the same way.
    for (final v in videos) {
      if (v.season == 0 && v.episode != null) {
        final t = byNumber[(0, v.episode!)];
        if (t != null) result[v] = t;
      }
    }

    final flat = _flat(tmdb);
    final seasons = <int, List<Video>>{};
    for (final v in videos) {
      final s = v.season;
      if (s == null || s <= 0 || v.episode == null) continue;
      (seasons[s] ??= []).add(v);
    }
    final order = seasons.keys.toList()..sort();

    var cursor = 0;
    for (final s in order) {
      final eps = seasons[s]!..sort((a, b) => a.episode!.compareTo(b.episode!));
      final anchor = _anchor(eps.first, flat, cursor);
      if (anchor != null) {
        final start = anchor - (eps.first.episode! - 1);
        for (final v in eps) {
          final i = start + v.episode! - 1;
          if (i >= 0 && i < flat.length) result[v] = flat[i];
        }
        cursor = start + eps.last.episode!;
      } else {
        // No date to go by: trust the numbers only when TMDb has this very
        // season with as many episodes.
        final same = flat.where((t) => t.season == s).length;
        if (same == eps.length) {
          for (final v in eps) {
            final t = byNumber[(s, v.episode!)];
            if (t != null) result[v] = t;
          }
        }
      }
    }
    return result;
  }

  /// The index in [flat] (from [from] on) of the episode that aired closest
  /// to [first]'s date, within [anchorToleranceDays]; the earliest of equals.
  static int? _anchor(Video first, List<TmdbEpisode> flat, int from) {
    final date = DateTime.tryParse(first.released ?? '');
    if (date == null) return null;
    final day = DateTime.utc(date.year, date.month, date.day);
    int? best;
    var bestGap = anchorToleranceDays + 1;
    for (var i = from; i < flat.length; i++) {
      final a = flat[i].airDate;
      if (a == null) continue;
      final gap = DateTime.utc(
        a.year,
        a.month,
        a.day,
      ).difference(day).inDays.abs();
      if (gap < bestGap) {
        best = i;
        bestGap = gap;
      }
    }
    return best;
  }

  @visibleForTesting
  static void clearCache() => _cache.clear();
}
