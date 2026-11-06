import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../account/account_service.dart';
import '../config/env_service.dart';
import '../storage/secret_keys.dart';
import '../storage/secure_store.dart';

enum TmdbKeyResult { ok, rejected, unreachable }

class TmdbMovie {
  const TmdbMovie({
    required this.imdbId,
    required this.title,
    required this.year,
    required this.voteAverage,
    required this.voteCount,
  });

  final String imdbId;
  final String title;
  final int year;
  final double voteAverage;
  final int voteCount;
}

abstract final class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const Duration _timeout = Duration(seconds: 10);

  static bool _hydrating = false;

  static final Map<int, String?> _imdbIdCache = {};

  @visibleForTesting
  static http.Client client = http.Client();

  /// The credential exactly as pasted, empty when unconfigured. Assigning persists it.
  static final ValueNotifier<String> apiKey = _PersistedApiKey('');

  static bool get isConfigured => apiKey.value.trim().isNotEmpty;

  /// Credential the legacy scraper lookups may use: the user's key when set,
  /// otherwise a build-time key. Empty when neither exists.
  ///
  /// The upstream fork's inherited key is gone, so this resolves empty on a
  /// fresh install. A caller must check [hasScraperKey] before putting the
  /// value in a URL: `?api_key=` with nothing after it is a malformed request
  /// to TMDb, not a graceful degrade.
  static String get scraperKey {
    final user = apiKey.value.trim();
    if (user.isNotEmpty) return user;
    return buildTimeApiKeyOverrideForTesting ?? EnvService.tmdbApiKey;
  }

  /// Stands in for the compile-time define in tests, which cannot set one.
  @visibleForTesting
  static String? buildTimeApiKeyOverrideForTesting;

  /// Whether [scraperKey] can be sent. False means the caller resolves nothing
  /// rather than issuing a keyed request with an empty credential.
  static bool get hasScraperKey => scraperKey.isNotEmpty || hasProxy;

  /// Whether [scraperKey] itself is set, for the few scrapers that put the
  /// key straight into a TMDb URL rather than asking through [getScraperJson].
  static bool get hasDirectScraperKey => scraperKey.isNotEmpty;

  /// Lumora's TMDb proxy (a Supabase Edge Function holding the key), used
  /// when this build carries no key of its own.
  static String? get proxyBase {
    if (proxyBaseOverrideForTesting != null) return proxyBaseOverrideForTesting;
    final url = AccountService.projectUrl;
    if (!AccountService.configured || url == null || url.isEmpty) return null;
    return '${url.replaceAll(RegExp(r'/+$'), '')}/functions/v1/tmdb';
  }

  @visibleForTesting
  static String? proxyBaseOverrideForTesting;

  static bool get hasProxy => proxyBase != null;

  /// The read currently in flight, so a caller that arrives while one is
  /// running waits on it instead of starting a second one. Two interleaved
  /// reads would fight over [_hydrating], and the one that finished first
  /// would leave the other's assignment persisting the key back to storage.
  static Future<void>? _reading;

  static Future<void> initialize() =>
      _reading ??= _read().whenComplete(() => _reading = null);

  static Future<void> _read() async {
    try {
      final stored = await SecureStore.read(SecretKeys.tmdbApiKey) ?? '';
      _hydrating = true;
      apiKey.value = stored;
      _hydrating = false;
    } catch (e) {
      debugPrint('[TmdbService] Error initializing: $e');
    }
  }

  /// Re-reads the stored key into [apiKey].
  ///
  /// [initialize] reads it once, at startup. A profile import writes the store
  /// underneath a running app, and without this the notifier keeps serving the
  /// pre-import value: Settings reports the key the export carried as "Not
  /// set", and the ranked rails stay on the offline picks until a restart.
  static Future<void> reload() async {
    // Let the startup read land first, so the value the import just wrote is
    // the last one applied.
    await _reading;
    await initialize();
  }

  /// Does a credential work? Never writes it anywhere.
  static Future<TmdbKeyResult> validate(String raw) async {
    final key = raw.trim();
    if (key.isEmpty) return TmdbKeyResult.rejected;
    final outcome = await _request(key, '/configuration', const {});
    return outcome.status;
  }

  static Future<void> save(String raw) async {
    final key = raw.trim();
    try {
      if (key.isEmpty) {
        await SecureStore.delete(SecretKeys.tmdbApiKey);
      } else {
        await SecureStore.write(SecretKeys.tmdbApiKey, key);
      }
    } catch (e) {
      debugPrint('[TmdbService] Error saving TMDb key: $e');
    }
    _hydrating = true;
    apiKey.value = key;
    _hydrating = false;
  }

  static Future<void> clear() async {
    try {
      await SecureStore.delete(SecretKeys.tmdbApiKey);
    } catch (e) {
      debugPrint('[TmdbService] Error clearing TMDb key: $e');
    }
    _hydrating = true;
    apiKey.value = '';
    _hydrating = false;
  }

  /// A keyed GET against the v3 API, with [path] relative to the base URL.
  ///
  /// Null when no credential is set, when TMDb rejects it, or when the read
  /// fails, so a caller never has to branch on the credential itself.
  static Future<Map<String, dynamic>?> getJson(
    String path, [
    Map<String, String> params = const {},
  ]) async {
    final key = apiKey.value.trim();
    if (key.isEmpty) return null;
    final outcome = await _request(key, path, params);
    return outcome.status == TmdbKeyResult.ok ? outcome.body : null;
  }

  /// [getJson] with [scraperKey]: the user's key, else the build-time one.
  ///
  /// For the stream sources, which need TMDb's facts about a title (its type,
  /// its year) to tell same-named titles apart. Goes through [_request], so a
  /// v4 read token is retried as a bearer instead of failing as `api_key`.
  static Future<Map<String, dynamic>?> getScraperJson(
    String path, [
    Map<String, String> params = const {},
  ]) async {
    return (await getScraperJsonWithStatus(path, params)).body;
  }

  /// [getScraperJson] plus the HTTP status TMDb (or the proxy) answered
  /// with; null when nothing answered. Lets a caller tell "no such title"
  /// (404) from a failed read.
  static Future<({Map<String, dynamic>? body, int? status})>
  getScraperJsonWithStatus(
    String path, [
    Map<String, String> params = const {},
  ]) async {
    final key = scraperKey;
    if (key.isEmpty) return _proxyJson(path, params);
    final outcome = await _request(key, path, params);
    return (
      body: outcome.status == TmdbKeyResult.ok ? outcome.body : null,
      status: outcome.code,
    );
  }

  /// A GET through [proxyBase], signed in as the current user. No body when
  /// there is no proxy or it does not answer.
  ///
  /// The proxy lets each address ask a limited number of times a minute, and
  /// a refused answer used to read as "no Chinese data", so a busy start-up
  /// left titles and synopses in English. Requests are now paced under that
  /// limit, the same request in flight twice is asked once, and a refusal is
  /// waited out and asked again.
  static Future<({Map<String, dynamic>? body, int? status})> _proxyJson(
    String path,
    Map<String, String> params,
  ) {
    final base = proxyBase;
    if (base == null) return Future.value((body: null, status: null));
    final uri = Uri.parse(
      '$base$path',
    ).replace(queryParameters: params.isEmpty ? null : params);
    // The page the viewer is looking at goes ahead of every card title queued
    // at start-up; it doesn't wait behind a shared copy that is still queued.
    if (Zone.current[_urgentKey] == true) return _askProxy(uri, urgent: true);
    final key = uri.toString();
    // A block body: `remove` hands back this very future, and whenComplete
    // waits for a future its callback returns, so an arrow would wait on
    // itself forever.
    return _proxyInFlight[key] ??= _askProxy(uri).whenComplete(() {
      _proxyInFlight.remove(key);
    });
  }

  static final Object _urgentKey = Object();

  /// Whether the code running now is inside [urgently].
  static bool get isUrgent => Zone.current[_urgentKey] == true;

  /// Runs [body] with its TMDb requests ahead of the queue: for what the
  /// viewer is waiting on (a details page), not for card titles filling in.
  static Future<T> urgently<T>(Future<T> Function() body) => urgentZone(body);

  /// [urgently] for work that starts synchronously and keeps going, such as
  /// a source search that hands back a stream.
  static T urgentZone<T>(T Function() body) =>
      runZoned(body, zoneValues: {_urgentKey: true});

  static final Map<String, Future<({Map<String, dynamic>? body, int? status})>>
  _proxyInFlight = {};

  /// Under the proxy's own limit (120 a minute per address), with 30 of them
  /// kept for the page the viewer is looking at.
  static final ProxyPace _proxyPace = ProxyPace(perMinute: 110, reserve: 30);

  /// The first wait after a refusal; doubled each time. Zero in tests.
  @visibleForTesting
  static Duration proxyRetryBase = const Duration(milliseconds: 1500);

  static Future<({Map<String, dynamic>? body, int? status})> _askProxy(
    Uri uri, {
    bool urgent = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    final publishable = AccountService.publishableKey;
    if (publishable != null) headers['apikey'] = publishable;
    final token = AccountService.accessToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    const attempts = 3;
    for (var attempt = 0; ; attempt++) {
      await _proxyPace.take(urgent: urgent);
      try {
        final response = await client
            .get(uri, headers: headers)
            .timeout(_timeout);
        final status = response.statusCode;
        if (status == 429 && attempt + 1 < attempts) {
          final asked = int.tryParse(response.headers['retry-after'] ?? '');
          final backoff = proxyRetryBase * (1 << attempt);
          await Future<void>.delayed(
            asked != null && asked > 0 && proxyRetryBase > Duration.zero
                ? Duration(seconds: asked.clamp(1, 10))
                : backoff,
          );
          continue;
        }
        if (status != 200) return (body: null, status: status);
        final decoded = jsonDecode(response.body);
        return (
          body: decoded is Map<String, dynamic> ? decoded : null,
          status: status,
        );
      } catch (_) {
        return (body: null, status: null);
      }
    }
  }

  /// Top `limit` films of one genre in one decade, most voted first, imdb ids
  /// resolved. Uses the user's credential only: with no key set it returns an
  /// empty list and makes no request, so the rails never spend the built-in
  /// key's quota.
  static Future<List<TmdbMovie>> discover({
    required int fromYear,
    required int toYear,
    required int genreId,
    int limit = 20,
    double minVotes = 500,
    bool includeAdult = false,
  }) async {
    final key = apiKey.value.trim();
    if (key.isEmpty) return const [];

    final outcome = await _request(key, '/discover/movie', {
      'with_genres': '$genreId',
      'primary_release_date.gte': '$fromYear-01-01',
      'primary_release_date.lte': '$toYear-12-31',
      'sort_by': 'vote_count.desc',
      'vote_count.gte': '${minVotes.round()}',
      'include_adult': '$includeAdult',
      'language': 'en-US',
      'page': '1',
    });
    final body = outcome.body;
    if (outcome.status != TmdbKeyResult.ok || body == null) return const [];

    final results = body['results'];
    if (results is! List) return const [];

    final candidates = <_Candidate>[];
    for (final entry in results) {
      if (entry is! Map) continue;
      final id = entry['id'];
      if (id is! int) continue;
      candidates.add(
        _Candidate(
          tmdbId: id,
          title: entry['title']?.toString() ?? '',
          year: _yearOf(entry['release_date']?.toString()),
          voteAverage: (entry['vote_average'] as num?)?.toDouble() ?? 0,
          voteCount: (entry['vote_count'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    final imdbIds = await Future.wait([
      for (final candidate in candidates) _imdbIdFor(key, candidate.tmdbId),
    ]);

    final movies = <TmdbMovie>[];
    for (var i = 0; i < candidates.length && movies.length < limit; i++) {
      final imdbId = imdbIds[i];
      if (imdbId == null || imdbId.isEmpty) continue;
      final candidate = candidates[i];
      movies.add(
        TmdbMovie(
          imdbId: imdbId,
          title: candidate.title,
          year: candidate.year,
          voteAverage: candidate.voteAverage,
          voteCount: candidate.voteCount,
        ),
      );
    }
    return movies;
  }

  static Future<String?> _imdbIdFor(String key, int tmdbId) {
    if (_imdbIdCache.containsKey(tmdbId)) {
      return Future.value(_imdbIdCache[tmdbId]);
    }
    return _resolveImdbId(key, tmdbId);
  }

  static Future<String?> _resolveImdbId(String key, int tmdbId) async {
    final outcome = await _request(key, '/movie/$tmdbId', const {});
    if (outcome.status != TmdbKeyResult.ok || outcome.body == null) return null;
    final raw = outcome.body!['imdb_id'];
    final imdbId = (raw is String && raw.isNotEmpty) ? raw : null;
    _imdbIdCache[tmdbId] = imdbId;
    return imdbId;
  }

  static Future<_HttpOutcome> _request(
    String key,
    String path,
    Map<String, String> params,
  ) async {
    final base = Uri.parse('$_baseUrl$path');

    var response = await _get(
      base.replace(queryParameters: {...params, 'api_key': key}),
    );
    if (response == null) return const _HttpOutcome.unreachable();

    if (response.statusCode == 401) {
      // A v4 read token is rejected when sent as `api_key`, so retry it as a
      // bearer header before calling the credential bad.
      response = await _get(base.replace(queryParameters: params), bearer: key);
      if (response == null) return const _HttpOutcome.unreachable();
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      return _HttpOutcome.rejected(response.statusCode);
    }
    if (response.statusCode != 200) {
      return _HttpOutcome.unreachable(response.statusCode);
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return _HttpOutcome.ok(decoded);
    } catch (_) {}
    return const _HttpOutcome.unreachable(200);
  }

  static Future<http.Response?> _get(Uri uri, {String? bearer}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (bearer != null) headers['Authorization'] = 'Bearer $bearer';
    try {
      return await client.get(uri, headers: headers).timeout(_timeout);
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static int _yearOf(String? date) {
    if (date == null || date.isEmpty) return 0;
    return int.tryParse(date.split('-').first) ?? 0;
  }
}

class _PersistedApiKey extends ValueNotifier<String> {
  _PersistedApiKey(super.initialValue);

  @override
  set value(String next) {
    super.value = next;
    if (!TmdbService._hydrating) unawaited(_persist(next));
  }

  Future<void> _persist(String next) async {
    try {
      if (next.isEmpty) {
        await SecureStore.delete(SecretKeys.tmdbApiKey);
      } else {
        await SecureStore.write(SecretKeys.tmdbApiKey, next);
      }
    } catch (e) {
      debugPrint('[TmdbService] Error saving TMDb key: $e');
    }
  }
}

class _Candidate {
  const _Candidate({
    required this.tmdbId,
    required this.title,
    required this.year,
    required this.voteAverage,
    required this.voteCount,
  });

  final int tmdbId;
  final String title;
  final int year;
  final double voteAverage;
  final int voteCount;
}

class _HttpOutcome {
  const _HttpOutcome.ok(this.body) : status = TmdbKeyResult.ok, code = 200;
  const _HttpOutcome.rejected([this.code])
    : body = null,
      status = TmdbKeyResult.rejected;
  const _HttpOutcome.unreachable([this.code])
    : body = null,
      status = TmdbKeyResult.unreachable;

  final TmdbKeyResult status;
  final Map<String, dynamic>? body;

  /// The HTTP status answered with; null when nothing answered.
  final int? code;
}

/// Spaces requests so that no more than [perMinute] go out in any minute,
/// keeping [reserve] of them for urgent ones: a burst of card titles at
/// start-up can't make the page the viewer opened wait for the next minute.
/// Callers are served in the order they asked, urgent ones first.
class ProxyPace {
  ProxyPace({
    required this.perMinute,
    this.reserve = 0,
    DateTime Function()? now,
    Future<void> Function(Duration)? sleep,
  }) : _now = now ?? DateTime.now,
       _sleep = sleep ?? ((d) => Future<void>.delayed(d));

  final int perMinute;
  final int reserve;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _sleep;
  final ListQueue<DateTime> _sent = ListQueue();
  final List<({bool urgent, Completer<void> turn})> _waiting = [];
  bool _serving = false;

  /// How often a waiting queue looks again, so an urgent request that
  /// arrives meanwhile isn't held behind an ordinary one's long wait.
  static const Duration _tick = Duration(milliseconds: 250);

  /// Waits for a free place in the minute, then holds it. An [urgent] call
  /// goes ahead of every ordinary one still waiting and may use [reserve].
  Future<void> take({bool urgent = false}) {
    final turn = Completer<void>();
    final entry = (urgent: urgent, turn: turn);
    if (urgent) {
      final firstOrdinary = _waiting.indexWhere((w) => !w.urgent);
      _waiting.insert(
        firstOrdinary < 0 ? _waiting.length : firstOrdinary,
        entry,
      );
    } else {
      _waiting.add(entry);
    }
    unawaited(_serve());
    return turn.future;
  }

  Future<void> _serve() async {
    if (_serving) return;
    _serving = true;
    try {
      while (_waiting.isNotEmpty) {
        final head = _waiting.first;
        final wait = _waitFor(head.urgent ? perMinute : perMinute - reserve);
        if (wait == Duration.zero) {
          _sent.addLast(_now());
          _waiting.removeAt(0).turn.complete();
          continue;
        }
        await _sleep(wait < _tick ? wait : _tick);
      }
    } finally {
      _serving = false;
    }
  }

  /// How long until fewer than [limit] requests went out in the last minute.
  Duration _waitFor(int limit) {
    const minute = Duration(minutes: 1);
    final now = _now();
    while (_sent.isNotEmpty && now.difference(_sent.first) >= minute) {
      _sent.removeFirst();
    }
    if (_sent.length < limit) return Duration.zero;
    final freesAt = _sent.elementAt(_sent.length - limit).add(minute);
    final wait = freesAt.difference(now);
    return wait > Duration.zero ? wait : const Duration(milliseconds: 1);
  }
}
