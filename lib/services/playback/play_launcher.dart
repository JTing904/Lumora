import 'package:flutter/material.dart';

import '../../models/continue_watching/continue_watching_item.dart';
import '../../models/movie/episode_order.dart';
import '../../models/movie/movie.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/movie/video.dart';
import '../../pages/details/details_page.dart';
import '../../pages/details/episode_number_grid.dart';
import '../../pages/player/watch_screen.dart';
import '../../utils/navigation/route_transitions.dart';
import '../continue_watching/continue_watching_service.dart';
import '../continue_watching/watched_episodes.dart';
import '../metadata/metadata_service.dart';
import '../metadata/tmdb_catalog.dart';
import '../player/source_pick_settings.dart';

/// "播放" from anywhere that only holds a row item: straight to the source
/// list, picking as the details page would.
///
/// An unfinished title resumes where the viewer stopped; a series with
/// episodes finished goes on to the next one, and a new series starts at the
/// first episode of its first real season (season 0 is specials).
/// Without details to play from,
/// the details page opens instead, so the button never does nothing.
abstract final class PlayLauncher {
  /// The row whose 播放 is being worked out, or null.
  ///
  /// 播放 has to find the title's IMDb id and its episodes before the player
  /// can open, which takes seconds on a slow connection, so the button that
  /// started it shows itself busy from this. It is also the guard: one launch
  /// at a time, and a press while one is in flight is ignored, where it used
  /// to open a second player over the first.
  static final ValueNotifier<Movie?> launching = ValueNotifier<Movie?>(null);

  /// [row] under the IMDb id the addons answer to: a TMDb-built row's id is
  /// looked up, and a row from elsewhere (因为你在看…) is found by its
  /// name and year, as the details page does. Null when neither works.
  static Future<Movie?> playable(Movie row) async {
    final movie = await TmdbCatalog.resolve(row);
    if (movie == null || movie.id.startsWith('tt')) return movie;
    final year = int.tryParse(
      (movie.year ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
    );
    return await MetadataService.findMovieByTitle(
          title: movie.name,
          type: movie.type,
          year: year,
        ) ??
        movie;
  }

  static Future<void> play(BuildContext context, Movie row) async {
    if (launching.value != null || !_inFront(context)) return;
    launching.value = row;
    try {
      await _play(context, row);
    } finally {
      launching.value = null;
    }
  }

  static Future<void> _play(BuildContext context, Movie row) async {
    final movie = await playable(row);
    if (!context.mounted) return;
    if (movie == null) {
      // No IMDb id: the details page shows it from TMDb and plays from there.
      _pushDetails(context, row);
      return;
    }
    // An unfinished session resumes at its position, by the same path as the
    // Continue Watching card.
    final session = _unfinished({row.id, movie.id});
    if (session != null) {
      await ContinueWatchingService.resumePlayback(context, session);
      return;
    }

    final detail = await MetadataService.fetchMeta(
      baseUrl: movie.addonBaseUrl,
      type: movie.type,
      imdbId: movie.id,
    );
    if (!context.mounted) return;
    if (detail == null) {
      _pushDetails(context, movie);
      return;
    }

    final series = movie.type == 'series' || movie.type == 'tv';
    final episode = series ? startEpisode(detail) : null;
    if (episode != null && !episodeIsOut(episode)) {
      // Not out yet: the details page says when it airs.
      _pushDetails(context, movie);
      return;
    }

    Navigator.push(
      context,
      CinematicSlideRoute(
        page: WatchScreen(
          detail: detail,
          type: detail.type,
          selectedEpisode: episode,
          autoPick: SourcePickSettings.autoPick.value,
        ),
      ),
    );
  }

  /// The episode 播放 starts [detail] at, as the details page's own 播放
  /// does: the one after the last finished, so a viewer three episodes in
  /// does not start over, or else the first of the first real season.
  @visibleForTesting
  static Video? startEpisode(MovieDetail detail) {
    if (detail.videos.isEmpty) return null;
    final order = episodeOrder(detail.videos);
    final last = WatchedEpisodes.lastFinished(detail.id);
    final next = last == null
        ? null
        : episodeNeighbour(order, last.$1, last.$2, 1);
    return next ?? order.firstOrNull ?? detail.videos.first;
  }

  /// Opens the details page at once. It takes the row as it is, TMDb id and
  /// all, and resolves it while showing its own progress, so a tap answers
  /// immediately instead of after the lookup.
  static Future<void> openDetails(BuildContext context, Movie row) async {
    if (launching.value != null || !_inFront(context)) return;
    _pushDetails(context, row);
  }

  static void _pushDetails(BuildContext context, Movie row) {
    Navigator.push(context, CinematicSlideRoute(page: DetailsPage(movie: row)));
  }

  /// Whether [context]'s page is the one on top. False once a tap has opened
  /// a page over it, so a second tap during that page's slide-in does not
  /// open another copy.
  static bool _inFront(BuildContext context) =>
      ModalRoute.isCurrentOf(context) ?? true;

  /// The viewer's unfinished session for any of [ids].
  static ContinueWatchingItem? _unfinished(Set<String> ids) =>
      ContinueWatchingService.activeItems.value
          .where((s) => ids.contains(s.id) && !s.isCompleted)
          .firstOrNull;
}
