import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../models/my_list/my_list_item.dart';
import '../account/account_scope.dart';
import '../continue_watching/continue_watching_service.dart';
import '../continue_watching/watched_episodes.dart';
import '../metadata/tmdb_service.dart';
import 'my_list_service.dart';
import 'new_episode_logic.dart';

export 'new_episode_logic.dart' show EpisodeRef;

/// What TMDb says about one show in My List, and whether it has an episode
/// the viewer has not seen.
@immutable
class NewEpisodeInfo {
  const NewEpisodeInfo({
    required this.itemKey,
    required this.tmdbId,
    required this.title,
    required this.isNew,
    this.imdbId,
    this.poster,
    this.year,
    this.latest,
    this.next,
    this.upcoming = const [],
    this.network,
  });

  /// [MyListItem.uniqueKey] of the saved show.
  final String itemKey;
  final int tmdbId;
  final String? imdbId;
  final String title;
  final String? poster;
  final int? year;

  /// The latest episode that has aired.
  final EpisodeRef? latest;

  /// The next episode to air, when TMDb knows one.
  final EpisodeRef? next;

  /// Episodes airing from today on (next one first), for 追剧日历.
  final List<EpisodeRef> upcoming;
  final String? network;

  /// [latest] is newer than what the viewer has watched.
  final bool isNew;

  /// `S2 E5` for [latest].
  String? latestCode(AppLocalizations l10n) {
    final e = latest;
    return e == null ? null : l10n.newEpCode('${e.season}', '${e.episode}');
  }

  /// `11/3 更新` for the next episode, when it airs today or later.
  String? nextAirLabel(AppLocalizations l10n) {
    final d = next?.airDate;
    if (d == null) return null;
    final n = DateTime.now();
    if (d.isBefore(DateTime(n.year, n.month, n.day))) return null;
    return l10n.newEpAirsNext(l10n.newEpMonthDay('${d.month}', '${d.day}'));
  }

  /// The id the details page opens this show by.
  String get detailsId =>
      (imdbId != null && imdbId!.isNotEmpty) ? imdbId! : 'tmdb:tv:$tmdbId';
}

/// The facts fetched for one TMDb show, cached for [_ttl].
class _ShowFacts {
  _ShowFacts({
    required this.fetchedAt,
    this.latest,
    this.next,
    this.upcoming = const [],
    this.network,
    this.imdbId,
  });

  final DateTime fetchedAt;
  final EpisodeRef? latest;
  final EpisodeRef? next;
  final List<EpisodeRef> upcoming;
  final String? network;

  /// TMDb's `external_ids.imdb_id` for the show, when it has one.
  final String? imdbId;

  Map<String, Object?> toJson() => {
    'at': fetchedAt.millisecondsSinceEpoch,
    if (latest != null) 'last': latest!.toJson(),
    if (next != null) 'next': next!.toJson(),
    'up': [for (final e in upcoming) e.toJson()],
    if (network != null) 'net': network,
    if (imdbId != null) 'imdb': imdbId,
  };

  static _ShowFacts? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final at = raw['at'];
    if (at is! int) return null;
    return _ShowFacts(
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(at),
      latest: EpisodeRef.fromTmdb(raw['last']),
      next: EpisodeRef.fromTmdb(raw['next']),
      upcoming: [
        for (final e in (raw['up'] is List ? raw['up'] as List : const []))
          ?EpisodeRef.fromTmdb(e),
      ],
      network: raw['net'] is String ? raw['net'] as String : null,
      imdbId: raw['imdb'] is String ? raw['imdb'] as String : null,
    );
  }
}

/// 有新集: for each series in My List, asks TMDb (through the app's proxy)
/// for its latest aired and next episode, and marks the ones newer than what
/// the viewer has watched.
///
/// Runs in the background and never blocks a frame: requests go one at a
/// time, at most one a second (the proxy allows about 120 a minute per IP),
/// and each show is asked again only after [_ttl]. Started lazily by the
/// pages that show it ([ensureStarted]); after that it follows My List (which
/// the account load and LibrarySync replace), the watched record and
/// Continue Watching, and checks again when the app comes back to the
/// foreground.
abstract final class NewEpisodeService {
  static const _cacheKey = 'lumora_new_episode_cache_v1';
  static const Duration _ttl = Duration(hours: 6);
  static const Duration _gap = Duration(milliseconds: 1500);
  static const Duration _backoff = Duration(minutes: 10);

  /// Fetches between two [_recompute]s during a run (plus one at its end):
  /// each one rebuilds every row that follows [info].
  static const int _recomputeEvery = 10;
  static DateTime _backoffUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// Every tracked series by [MyListItem.uniqueKey]; see [NewEpisodeInfo.isNew].
  static final ValueNotifier<Map<String, NewEpisodeInfo>> info = ValueNotifier(
    const {},
  );

  /// True while a check is asking TMDb.
  static final ValueNotifier<bool> checking = ValueNotifier(false);

  static final Map<int, _ShowFacts> _facts = {};
  static final Map<String, int> _imdbToTmdb = {};
  static final Set<String> _unresolved = {};
  static bool _started = false;

  /// The [AccountScope.key] the in-memory cache was loaded for; null before
  /// the first load.
  static String? _cacheLoadedFor;
  static bool _running = false;
  static bool _again = false;
  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  static _Resume? _resume;

  static bool isSeries(MyListItem item) =>
      item.type == 'series' || item.type == 'tv' || item.type == 'anime';

  /// Starts following My List; safe to call from every page's initState.
  static void ensureStarted() {
    if (_started) return;
    _started = true;
    MyListService.items.addListener(_onListChanged);
    WatchedEpisodes.shows.addListener(_recompute);
    ContinueWatchingService.activeItems.addListener(_recompute);
    try {
      _resume = _Resume()..attach();
    } catch (_) {
      // No binding (a pure unit test): no resume checks.
    }
    unawaited(refresh());
  }

  static void _onListChanged() {
    _recompute();
    unawaited(refresh());
  }

  /// Asks TMDb about every series whose facts are older than [_ttl] (all of
  /// them with [force]). One run at a time; a call during a run queues one
  /// more after it.
  static Future<void> refresh({bool force = false}) async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    var changed = false;
    try {
      await _loadCache();
      _recompute();
      if (!TmdbService.hasScraperKey) return;
      // Offline or the proxy said "too many": wait before asking again.
      if (DateTime.now().isBefore(_backoffUntil)) return;
      final cacheKey = _cacheLoadedFor;
      final series = MyListService.items.value.where(isSeries).toList();
      var fetched = 0;
      for (final item in series) {
        // Another account signed in: its own run follows this one.
        if (AccountScope.key(_cacheKey) != cacheKey) break;
        if (!MyListService.items.value.contains(item)) continue;
        final found = await _tmdbIdFor(item);
        if (found.failed) {
          _backoffUntil = DateTime.now().add(_backoff);
          break;
        }
        final id = found.id;
        if (id == null) continue;
        final known = _facts[id];
        if (!force &&
            known != null &&
            DateTime.now().difference(known.fetchedAt) < _ttl) {
          continue;
        }
        if (!checking.value) checking.value = true;
        final fresh = await _fetch(id);
        if (fresh == null) {
          _backoffUntil = DateTime.now().add(_backoff);
          break;
        }
        _facts[id] = fresh;
        changed = true;
        if (++fetched % _recomputeEvery == 0) _recompute();
      }
      if (changed &&
          cacheKey != null &&
          AccountScope.key(_cacheKey) == cacheKey) {
        await _saveCache(cacheKey);
      }
    } catch (e) {
      debugPrint('[NewEpisodeService] $e');
    } finally {
      if (changed) _recompute();
      checking.value = false;
      _running = false;
      if (_again) {
        _again = false;
        unawaited(refresh());
      }
    }
  }

  /// The tracked show [id] names: an IMDb id, `tmdb:tv:123`, `tmdb:123` or
  /// a bare TMDb number. Null when it is not a series in My List.
  static NewEpisodeInfo? forId(String id) {
    if (id.isEmpty) return null;
    _index();
    final byImdb = _byImdb[id];
    if (byImdb != null) return byImdb;
    final tmdb = _tmdbFromId(id);
    return tmdb == null ? null : _byTmdb[tmdb];
  }

  /// [info] by IMDb id and by TMDb id, for [forId] (called once per card).
  static Map<String, NewEpisodeInfo>? _indexed;
  static final Map<String, NewEpisodeInfo> _byImdb = {};
  static final Map<int, NewEpisodeInfo> _byTmdb = {};

  static void _index() {
    final current = info.value;
    if (identical(_indexed, current)) return;
    _indexed = current;
    _byImdb.clear();
    _byTmdb.clear();
    for (final i in current.values) {
      final imdb = i.imdbId;
      if (imdb != null && imdb.isNotEmpty) _byImdb.putIfAbsent(imdb, () => i);
      _byTmdb.putIfAbsent(i.tmdbId, () => i);
    }
  }

  /// The shows with a new episode, among the ones My List may show, latest
  /// first.
  static List<NewEpisodeInfo> newEpisodes() {
    final visible = {for (final i in MyListService.visibleItems) i.uniqueKey};
    final list = info.value.values
        .where((i) => i.isNew && visible.contains(i.itemKey))
        .toList();
    list.sort((a, b) {
      final da = a.latest?.airDate, db = b.latest?.airDate;
      if (da == null || db == null) return da == null ? 1 : -1;
      return db.compareTo(da);
    });
    return list;
  }

  /// Every tracked show My List may show (new or not).
  static List<NewEpisodeInfo> visibleShows() {
    final visible = {for (final i in MyListService.visibleItems) i.uniqueKey};
    return info.value.values.where((i) => visible.contains(i.itemKey)).toList();
  }

  // ── internals ──

  static int? _tmdbFromId(String id) {
    if (id.startsWith('tmdb:')) return int.tryParse(id.split(':').last);
    return int.tryParse(id);
  }

  static int? _knownTmdbId(MyListItem item) {
    if (item.tmdbId != null) return item.tmdbId;
    final imdb = item.imdbId;
    if (imdb != null && imdb.isNotEmpty) return _imdbToTmdb[imdb];
    return null;
  }

  /// The TMDb id of [item], asking `/find` for an IMDb-only one. `failed`
  /// when that read did not get through (offline, rate limited).
  static Future<({int? id, bool failed})> _tmdbIdFor(MyListItem item) async {
    final known = _knownTmdbId(item);
    if (known != null) return (id: known, failed: false);
    final imdb = item.imdbId;
    if (imdb == null || !imdb.startsWith('tt') || _unresolved.contains(imdb)) {
      return (id: null, failed: false);
    }
    await _pace();
    final json = await TmdbService.getScraperJson('/find/$imdb', const {
      'external_source': 'imdb_id',
    });
    // A failed read is tried again on a later run, after the backoff.
    if (json == null) return (id: null, failed: true);
    final results = json['tv_results'];
    final first = results is List && results.isNotEmpty ? results.first : null;
    final id = first is Map ? first['id'] : null;
    if (id is int) {
      _imdbToTmdb[imdb] = id;
      return (id: id, failed: false);
    }
    // A definite "no series" answer is not asked again this session.
    _unresolved.add(imdb);
    return (id: null, failed: false);
  }

  static Future<_ShowFacts?> _fetch(int id) async {
    final lang = l10nCurrent().localeName == 'zh' ? 'zh-CN' : 'en-US';
    await _pace();
    final answer = await TmdbService.getScraperJsonWithStatus('/tv/$id', {
      'language': lang,
      'append_to_response': 'external_ids',
    });
    final json = answer.body;
    if (json == null) {
      // TMDb has no such show (removed or merged): remember that for the
      // usual while, so every run does not stop at it. Anything else (no
      // answer, rate limited, a server error) is a failed read.
      if (answer.status == 404) return _ShowFacts(fetchedAt: DateTime.now());
      return null;
    }
    final ids = json['external_ids'];
    final imdbRaw = ids is Map ? ids['imdb_id'] : null;
    final imdbId = imdbRaw is String && imdbRaw.startsWith('tt')
        ? imdbRaw
        : null;
    final latest = EpisodeRef.fromTmdb(json['last_episode_to_air']);
    final next = EpisodeRef.fromTmdb(json['next_episode_to_air']);
    final networks = json['networks'];
    final network =
        networks is List && networks.isNotEmpty && networks.first is Map
        ? (networks.first as Map)['name']?.toString()
        : null;

    final today = _today();
    var upcoming = <EpisodeRef>[?next];
    final nextAir = next?.airDate;
    // The rest of the airing season, for the calendar's next three weeks.
    if (next != null &&
        nextAir != null &&
        nextAir.difference(today) <= const Duration(days: 30)) {
      await _pace();
      final season = await TmdbService.getScraperJson(
        '/tv/$id/season/${next.season}',
        {'language': lang},
      );
      final eps = season?['episodes'];
      if (eps is List) {
        final fromSeason = <EpisodeRef>[
          for (final raw in eps)
            if (EpisodeRef.fromTmdb(raw) case final e?)
              if (e.airDate != null &&
                  !e.airDate!.isBefore(today) &&
                  e.airDate!.difference(today) <= const Duration(days: 45))
                e,
        ];
        if (fromSeason.isNotEmpty) upcoming = fromSeason..sort();
      }
    }
    return _ShowFacts(
      fetchedAt: DateTime.now(),
      latest: latest,
      next: next,
      upcoming: upcoming,
      network: network,
      imdbId: imdbId,
    );
  }

  static Future<void> _pace() async {
    final wait = _gap - DateTime.now().difference(_lastRequest);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    _lastRequest = DateTime.now();
  }

  /// The furthest episode the viewer finished or is in the middle of.
  static EpisodeRef? _lastSeen(MyListItem item, int tmdbId, String? imdbId) {
    final ids = <String>{
      if (item.imdbId != null && item.imdbId!.isNotEmpty) item.imdbId!,
      // A TMDb-only save watched under the show's IMDb id.
      ?imdbId,
      'tmdb:tv:$tmdbId',
      'tmdb:$tmdbId',
      '$tmdbId',
    };
    final seen = <EpisodeRef?>[];
    final watched = WatchedEpisodes.shows.value;
    for (final id in ids) {
      for (final key in watched[id] ?? const <String>[]) {
        seen.add(parseEpisodeKey(key));
      }
    }
    for (final s in ContinueWatchingService.activeItems.value) {
      final base = s.id.startsWith('tt') ? s.id.split(':').first : s.id;
      if (!ids.contains(s.id) && !ids.contains(base)) continue;
      final season = s.season, episode = s.episode;
      if (season != null && episode != null) {
        seen.add(EpisodeRef(season, episode));
      }
    }
    return furthestEpisode(seen);
  }

  static void _recompute() {
    final now = DateTime.now();
    final next = <String, NewEpisodeInfo>{};
    for (final item in MyListService.items.value) {
      if (!isSeries(item)) continue;
      final id = _knownTmdbId(item);
      if (id == null) continue;
      final facts = _facts[id];
      if (facts == null) continue;
      // Cached facts may be up to [_ttl] old: a "next" episode whose day has
      // come has aired since, so it is the latest one now.
      final latest = latestAiredOf(facts.latest, facts.next, now: now);
      final upNext = latest != null && identical(latest, facts.next)
          ? _firstAfter(facts.upcoming, latest, now)
          : facts.next;
      final itemImdb = item.imdbId != null && item.imdbId!.isNotEmpty
          ? item.imdbId
          : null;
      next[item.uniqueKey] = NewEpisodeInfo(
        itemKey: item.uniqueKey,
        tmdbId: id,
        imdbId: itemImdb ?? facts.imdbId,
        title: item.title,
        poster: item.poster,
        year: item.year,
        latest: latest,
        next: upNext,
        upcoming: facts.upcoming,
        network: facts.network,
        isNew: hasNewEpisode(
          latestAired: latest,
          lastSeen: _lastSeen(item, id, facts.imdbId),
          addedAt: item.addedAt,
          now: now,
        ),
      );
    }
    if (!_sameInfo(info.value, next)) info.value = next;
  }

  /// The first of [upcoming] after [after] that has not aired by [now].
  static EpisodeRef? _firstAfter(
    List<EpisodeRef> upcoming,
    EpisodeRef after,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    for (final e in [...upcoming]..sort()) {
      final at = e.airDate;
      if (e.isAfter(after) && at != null && at.isAfter(today)) return e;
    }
    return null;
  }

  static bool _sameInfo(
    Map<String, NewEpisodeInfo> a,
    Map<String, NewEpisodeInfo> b,
  ) {
    if (a.length != b.length) return false;
    for (final e in b.entries) {
      final o = a[e.key];
      final n = e.value;
      if (o == null ||
          o.isNew != n.isNew ||
          o.latest != n.latest ||
          o.latest?.airDate != n.latest?.airDate ||
          o.next != n.next ||
          o.next?.airDate != n.next?.airDate ||
          !listEquals(o.upcoming, n.upcoming) ||
          o.title != n.title ||
          o.poster != n.poster ||
          o.imdbId != n.imdbId) {
        return false;
      }
    }
    return true;
  }

  /// Loads the signed-in account's cache ([AccountScope.key]), dropping the
  /// previous account's from memory first.
  static Future<void> _loadCache() async {
    final key = AccountScope.key(_cacheKey);
    if (_cacheLoadedFor == key) return;
    if (_cacheLoadedFor != null) {
      _facts.clear();
      _imdbToTmdb.clear();
      _unresolved.clear();
    }
    _cacheLoadedFor = key;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final shows = decoded['shows'];
      if (shows is Map) {
        for (final e in shows.entries) {
          final id = int.tryParse(e.key.toString());
          final facts = _ShowFacts.fromJson(e.value);
          if (id != null && facts != null) _facts.putIfAbsent(id, () => facts);
        }
      }
      final imdb = decoded['imdb'];
      if (imdb is Map) {
        for (final e in imdb.entries) {
          if (e.value is int) {
            _imdbToTmdb.putIfAbsent(e.key.toString(), () => e.value as int);
          }
        }
      }
    } catch (e) {
      debugPrint('[NewEpisodeService] cache: $e');
    }
  }

  /// Saves under [key] (the account's [AccountScope.key]) only the shows,
  /// and IMDb ids, still in this account's list.
  static Future<void> _saveCache(String key) async {
    try {
      final items = MyListService.items.value;
      final keep = <int>{for (final item in items) ?_knownTmdbId(item)};
      _facts.removeWhere((id, _) => !keep.contains(id));
      final imdbs = <String>{for (final item in items) ?item.imdbId};
      _imdbToTmdb.removeWhere((imdb, _) => !imdbs.contains(imdb));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode({
          'shows': {
            for (final e in _facts.entries) '${e.key}': e.value.toJson(),
          },
          'imdb': _imdbToTmdb,
        }),
      );
    } catch (e) {
      debugPrint('[NewEpisodeService] save: $e');
    }
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Stands in for TMDb's answer about show [tmdbId], for tests.
  @visibleForTesting
  static void seedForTesting(
    int tmdbId, {
    EpisodeRef? latest,
    EpisodeRef? next,
    List<EpisodeRef> upcoming = const [],
    String? network,
    String? imdbId,
  }) {
    _cacheLoadedFor = AccountScope.key(_cacheKey);
    _facts[tmdbId] = _ShowFacts(
      fetchedAt: DateTime.now(),
      latest: latest,
      next: next,
      upcoming: upcoming,
      network: network,
      imdbId: imdbId,
    );
    _recompute();
  }

  /// Clears the in-memory state, for tests.
  @visibleForTesting
  static void resetForTesting() {
    _backoffUntil = DateTime.fromMillisecondsSinceEpoch(0);
    if (_started) {
      MyListService.items.removeListener(_onListChanged);
      WatchedEpisodes.shows.removeListener(_recompute);
      ContinueWatchingService.activeItems.removeListener(_recompute);
      _resume?.detach();
      _resume = null;
    }
    _started = false;
    _cacheLoadedFor = null;
    _running = false;
    _again = false;
    _facts.clear();
    _imdbToTmdb.clear();
    _unresolved.clear();
    info.value = const {};
    checking.value = false;
  }
}

/// Checks again when the app returns to the foreground (still gated by the
/// six-hour cache).
class _Resume with WidgetsBindingObserver {
  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(NewEpisodeService.refresh());
    }
  }
}
