import 'package:flutter/material.dart';

import '../../models/movie/movie.dart';
import '../../models/movie/video.dart';
import '../../pages/details/details_page.dart';
import '../../pages/player/watch_screen.dart';
import '../../utils/navigation/route_transitions.dart';
import '../continue_watching/continue_watching_service.dart';
import '../metadata/metadata_service.dart';
import '../metadata/tmdb_catalog.dart';
import '../player/source_pick_settings.dart';

/// "播放" from anywhere that only holds a row item: straight to the source
/// list, picking as the details page would.
///
/// An unfinished title resumes where the viewer stopped; a new series starts
/// at the first episode of its first real season (season 0 is specials).
/// Without details to play from,
/// the details page opens instead, so the button never does nothing.
abstract final class PlayLauncher {
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
    final movie = await playable(row);
    if (!context.mounted) return;
    if (movie == null) {
      // No IMDb id: the details page shows it from TMDb and plays from there.
      openDetails(context, row);
      return;
    }
    // An unfinished session resumes at its position, by the same path as the
    // Continue Watching card.
    final session = ContinueWatchingService.activeItems.value
        .where((s) => s.id == movie.id && !s.isCompleted)
        .firstOrNull;
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
      openDetails(context, movie);
      return;
    }

    final series = movie.type == 'series' || movie.type == 'tv';
    Video? episode;
    if (series && detail.videos.isNotEmpty) {
      final regular = detail.videos.where((v) => (v.season ?? 0) > 0).toList()
        ..sort((a, b) {
          final s = (a.season ?? 0).compareTo(b.season ?? 0);
          return s != 0 ? s : (a.episode ?? 0).compareTo(b.episode ?? 0);
        });
      episode = regular.isNotEmpty ? regular.first : detail.videos.first;
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

  static Future<void> openDetails(BuildContext context, Movie row) async {
    // Without an IMDb id the details page builds the title from TMDb alone,
    // so the row still opens rather than doing nothing.
    final movie = await TmdbCatalog.resolve(row) ?? row;
    if (!context.mounted) return;
    Navigator.push(
      context,
      CinematicSlideRoute(page: DetailsPage(movie: movie)),
    );
  }
}
