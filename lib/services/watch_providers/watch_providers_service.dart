/// Fetches "where to watch" for a title through Lumora's TMDb proxy.
///
/// The app carries no TMDb key: every read goes through
/// [TmdbService.getScraperJson] (the Supabase `tmdb` function, whose path
/// allowlist already covers `/(movie|tv)/{id}/watch/providers`). Fails
/// quietly: null means "show nothing".
library;

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import '../metadata/tmdb_service.dart';
import 'watch_providers.dart';

/// A TMDb read: path relative to the v3 API, query parameters.
typedef TmdbRead =
    Future<Map<String, dynamic>?> Function(
      String path,
      Map<String, String> params,
    );

class WatchProvidersService {
  WatchProvidersService({TmdbRead? read, DateTime Function()? clock})
    : _read = read ?? TmdbService.getScraperJson,
      _clock = clock ?? DateTime.now;

  static final WatchProvidersService instance = WatchProvidersService();

  /// The region Lumora is built for; the device's region is the fallback
  /// when TMDb lists nothing here.
  static const String primaryRegion = 'MY';

  static const Duration ttl = Duration(hours: 6);
  static const Duration timeout = Duration(seconds: 8);

  final TmdbRead _read;
  final DateTime Function() _clock;
  final Map<String, ({DateTime at, RegionWatchProviders? value})> _cache = {};
  final Map<String, Future<RegionWatchProviders?>> _inFlight = {};

  /// Regions to try, in order: [primaryRegion], then [deviceRegion].
  static List<String> regionsFor(String? deviceRegion) => [
    primaryRegion,
    if (deviceRegion != null &&
        deviceRegion.trim().length == 2 &&
        deviceRegion.trim().toUpperCase() != primaryRegion)
      deviceRegion.trim().toUpperCase(),
  ];

  /// The TMDb numeric id in an app id (`tmdb:123`, `tmdb:tv:123`), or null.
  static int? tmdbIdFromAppId(String id) {
    if (!id.startsWith('tmdb:')) return null;
    return int.tryParse(id.split(':').last);
  }

  /// Whether an app type means a TMDb tv show.
  static bool isTvType(String type) =>
      type == 'series' || type == 'tv' || type == 'anime';

  /// The services for a title. [id] is the app's id (`tt…` or `tmdb:…`),
  /// [tmdbId] TMDb's id when the detail already carries it.
  Future<RegionWatchProviders?> forTitle({
    required String id,
    required String type,
    String? tmdbId,
    String? deviceRegion,
  }) {
    final regions = regionsFor(
      deviceRegion ?? PlatformDispatcher.instance.locale.countryCode,
    );
    final key = '$id|$type|$tmdbId|${regions.join(',')}';
    final hit = _cache[key];
    if (hit != null && _clock().difference(hit.at) < ttl) {
      return Future.value(hit.value);
    }
    final running = _inFlight[key];
    if (running != null) return running;
    final future = () async {
      try {
        final value = await _load(id, type, tmdbId, regions).timeout(timeout);
        _cache[key] = (at: _clock(), value: value);
        return value;
      } catch (_) {
        return null;
      } finally {
        _inFlight.remove(key);
      }
    }();
    _inFlight[key] = future;
    return future;
  }

  Future<RegionWatchProviders?> _load(
    String id,
    String type,
    String? tmdbId,
    List<String> regions,
  ) async {
    var tv = isTvType(type);
    var numeric = int.tryParse(tmdbId ?? '') ?? tmdbIdFromAppId(id);
    if (numeric == null && id.startsWith('tt')) {
      final found = await _read('/find/$id', const {
        'external_source': 'imdb_id',
      });
      final resolved = resolveFind(found, preferTv: tv);
      if (resolved == null) return null;
      numeric = resolved.id;
      tv = resolved.tv;
    }
    if (numeric == null) return null;
    final json = await _read(
      '/${tv ? 'tv' : 'movie'}/$numeric/watch/providers',
      const {},
    );
    return WatchProvidersParser.parse(json, regions: regions);
  }

  /// TMDb's id from a `/find` answer, the preferred kind first.
  static ({int id, bool tv})? resolveFind(
    Map<String, dynamic>? found, {
    required bool preferTv,
  }) {
    if (found == null) return null;
    ({int id, bool tv})? first(String key, bool tv) {
      final list = found[key];
      if (list is! List || list.isEmpty || list.first is! Map) return null;
      final id = (list.first as Map)['id'];
      return id is int ? (id: id, tv: tv) : null;
    }

    return preferTv
        ? first('tv_results', true) ?? first('movie_results', false)
        : first('movie_results', false) ?? first('tv_results', true);
  }
}
