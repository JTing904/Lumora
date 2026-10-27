import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/stream/stream_model.dart';
import '../debrid/debrid_service.dart';
import '../p2p/p2p_settings_service.dart';
import 'builtin_providers_settings_service.dart';
import 'sites/maccms.dart';

abstract class StreamScraper {
  String get name;
  String get providerId => runtimeType.toString().replaceAll('Scraper', '').toLowerCase();
  String get providerName => runtimeType.toString().replaceAll('Scraper', '');

  /// Whether this source looks episodes up by their TMDb/IMDb season and
  /// episode numbers.
  ///
  /// Those numbers do not always describe the episode the viewer picked: a
  /// catalog can file a show differently from TMDb (Cinemeta lists "A Mortal's
  /// Journey" as seasons 0-8, TMDb as one 209-episode season), and asked for
  /// an episode TMDb does not have, such a source returns whatever its host
  /// serves - an unrelated film, in the case that found this. The manager
  /// skips these sources when TMDb says the requested episode does not exist.
  bool get followsTmdbEpisodes => false;

  /// Yields sources progressively one-by-one as they are resolved.
  Stream<StreamSource> scrapeStream({
    required String type,
    required String title,
    int? year,
    int? season,
    int? episode,
    String? imdbId,
  }) async* {
    final list = await scrape(
      type: type,
      title: title,
      year: year,
      season: season,
      episode: episode,
      imdbId: imdbId,
    );
    for (final s in list) {
      yield s;
    }
  }

  /// Bulk scrape fallback.
  Future<List<StreamSource>> scrape({
    required String type,
    required String title,
    int? year,
    int? season,
    int? episode,
    String? imdbId,
  }) async {
    return [];
  }
}

class ScraperManager {
  ScraperManager._internal();
  static final ScraperManager instance = ScraperManager._internal();

  final List<StreamScraper> _scrapers = [];
  final List<StreamSubscription> _activeSubscriptions = [];
  bool get hasScrapers => _scrapers.isNotEmpty;

  void registerScraper(StreamScraper scraper) {
    if (!_scrapers.any((s) => s.runtimeType == scraper.runtimeType)) {
      _scrapers.add(scraper);
    }
  }

  void unregisterTorrentScrapers() {
    _scrapers.removeWhere((s) => s.name == 'ZPlay');
  }

  /// Cancels all ongoing scraper executions immediately.
  void cancelActiveScrapes() {
    if (_activeSubscriptions.isNotEmpty) {
      debugPrint('[ScraperManager] Cancelling ${_activeSubscriptions.length} active scrapers...');
      final subs = List<StreamSubscription>.from(_activeSubscriptions);
      _activeSubscriptions.clear();
      for (final sub in subs) {
        sub.cancel();
      }
    }
  }

  Stream<StreamSource> scrapeAll({
    required String type,
    required String title,
    int? year,
    int? season,
    int? episode,
    String? imdbId,
    bool skipTmdbNumbered = false,
    // `tmdb:kind:id` for a title TMDb lists without an IMDb id. Only the
    // Chinese sites, which search by name, can use it: they look the Chinese
    // name up by it. Everything else keys on IMDb and gets nothing.
    String? tmdbRef,
  }) {
    final controller = StreamController<StreamSource>();

    // A torrent scraper stays useful when either the local P2P engine can play
    // the magnet or an active Debrid service can resolve it in the cloud.
    final torrentsUsable = P2pSettingsService.isP2pEnabled.value ||
        DebridService.isDebridReady.value;
    final isCustom = BuiltinProvidersSettingsService.instance.isCustom;

    final List<StreamScraper> activeScrapers;
    if (isCustom) {
      final filtered = _scrapers.where((s) {
        if (!torrentsUsable && s.name == 'ZPlay') return false;
        if (s.name == 'ZPlayHTTP') {
          return BuiltinProvidersSettingsService.instance.isProviderEnabled(s.providerId);
        }
        return true;
      }).toList();

      final hasRegisteredHttp = _scrapers.any((s) => s.name == 'ZPlayHTTP');
      final httpScrapersInFiltered = filtered.where((s) => s.name == 'ZPlayHTTP').toList();
      if (hasRegisteredHttp && httpScrapersInFiltered.isEmpty) {
        debugPrint('[ScraperManager] WARNING: Custom mode has 0 ZPlayHTTP scrapers enabled. Falling back to default enabled HTTP scrapers to prevent scraping outage.');
        filtered.addAll(_scrapers.where((s) => s.name == 'ZPlayHTTP'));
      }

      filtered.sort((a, b) {
        if (a.name == 'ZPlayHTTP' && b.name == 'ZPlayHTTP') {
          final rankA = BuiltinProvidersSettingsService.instance.getProviderRank(a.providerId);
          final rankB = BuiltinProvidersSettingsService.instance.getProviderRank(b.providerId);
          return rankA.compareTo(rankB);
        }
        return 0;
      });
      activeScrapers = filtered;
    } else {
      activeScrapers = _scrapers.where((s) {
        if (!torrentsUsable && s.name == 'ZPlay') {
          return false;
        }
        return true;
      }).toList();
    }

    if (skipTmdbNumbered) {
      activeScrapers.removeWhere((s) => s.followsTmdbEpisodes);
    }

    if (activeScrapers.isEmpty) {
      controller.close();
      return controller.stream;
    }

    debugPrint('[ScraperManager] Scraping across ${activeScrapers.length} active scrapers (${activeScrapers.map((s) => s.runtimeType).join(", ")}) for "$title" (Torrents usable: $torrentsUsable, Custom mode: $isCustom)...');

    int pendingScrapers = activeScrapers.length;
    final seenHashes = <String>{};
    final seenUrls = <String>{};
    final List<StreamSubscription> currentRunSubs = [];

    void checkClose() {
      if (pendingScrapers <= 0 && !controller.isClosed) {
        controller.close();
      }
    }

    controller.onCancel = () {
      for (final s in currentRunSubs) {
        s.cancel();
      }
      _activeSubscriptions.removeWhere((s) => currentRunSubs.contains(s));
      currentRunSubs.clear();
    };

    for (final scraper in activeScrapers) {
      final sub = scraper
          .scrapeStream(
        type: type,
        title: title,
        year: year,
        season: season,
        episode: episode,
        imdbId: imdbId ?? (scraper is MacCmsScraper ? tmdbRef : null),
      )
          .listen(
        (rawSource) {
          if (controller.isClosed) return;

          final source = (rawSource.providerId == null || rawSource.providerId!.isEmpty)
              ? rawSource.copyWith(
                  providerId: scraper.providerId,
                  providerName: scraper.providerName,
                )
              : rawSource;

          // Without the local P2P engine and without Debrid, a torrent source
          // could not be played at all, so drop it instead of offering a dead row.
          if (!torrentsUsable &&
              (source.addonName == 'ZPlay' ||
                  (source.infoHash != null && source.infoHash!.isNotEmpty))) {
            return;
          }

          // Torrent sources pass directly with deduplication
          if (source.infoHash != null && source.infoHash!.isNotEmpty) {
            final hashLower = source.infoHash!.toLowerCase();
            if (seenHashes.contains(hashLower)) return;
            seenHashes.add(hashLower);
            controller.add(source);
            return;
          }

          final rawUrl = source.url ?? source.externalUrl;
          if (rawUrl != null && rawUrl.startsWith('http')) {
            if (seenUrls.contains(rawUrl)) return;
            seenUrls.add(rawUrl);
            // Emit immediately as streams are found so the UI displays them progressively!
            controller.add(source);
          } else {
            controller.add(source);
          }
        },
        onError: (_) {},
        onDone: () {
          pendingScrapers--;
          checkClose();
        },
      );
      currentRunSubs.add(sub);
      _activeSubscriptions.add(sub);
    }

    return controller.stream;
  }
}
