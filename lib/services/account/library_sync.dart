import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/continue_watching/continue_watching_item.dart';
import '../../models/my_list/my_list_item.dart';
import '../continue_watching/continue_watching_service.dart';
import '../continue_watching/watched_episodes.dart';
import '../my_list/my_list_service.dart';
import '../recommend/taste_store.dart';
import '../simkl/simkl_service.dart';
import '../trakt/trakt_service.dart';
import 'account_scope.dart';
import 'account_service.dart';

/// One library document: how to read it out of its service, put it back, and
/// tell its entries apart when two copies are merged.
class _Doc {
  const _Doc({
    required this.export,
    required this.import,
    required this.reload,
    this.keyOf,
    this.timeOf,
    this.retime,
    this.aliasesOf,
    this.removals = false,
    this.limit,
  });

  /// The service's current document, JSON-shaped: a list of entries, or (for
  /// watched episodes) a map of show id to finished episode keys.
  final Object? Function() export;

  /// Replaces the service's document, saving it locally without reporting it
  /// back as a change.
  final Future<void> Function(Object? data) import;

  /// Re-reads the signed-in account's local copy.
  final Future<void> Function() reload;

  /// For list documents: an entry's identity and when it last changed. Two
  /// copies keep, per identity, the entry that changed last.
  final String Function(Map<String, dynamic> entry)? keyOf;
  final DateTime Function(Map<String, dynamic> entry)? timeOf;

  /// Writes [timeOf] back into an entry, for a time pulled out of the future
  /// (see [LibrarySync._maxLead]).
  final void Function(Map<String, dynamic> entry, DateTime at)? retime;

  /// Every key the same entry may be kept under on another device (an IMDb id
  /// here, a TMDb id there). A removal of any of them removes the entry.
  /// Without it, the entry's only key is [keyOf].
  final List<String> Function(Map<String, dynamic> entry)? aliasesOf;

  /// Whether removing an entry is remembered (a tombstone), so a copy that
  /// still has it cannot bring it back.
  final bool removals;

  /// The most entries kept, newest first, the same on every device.
  final int? limit;
}

/// A document's server row as last seen: its data, and the `updated_at` the
/// server stamped on its last write, which the next write must still find.
@visibleForTesting
class LibraryRow {
  const LibraryRow(this.data, this.updatedAt);

  final Object? data;
  final String? updatedAt;
}

/// The server table, behind an interface so tests can stand in for it.
@visibleForTesting
abstract interface class LibraryRemote {
  /// Every document row of [uid].
  Future<Map<String, LibraryRow>> readAll(String uid);

  /// [doc]'s row, or null when there is none yet.
  Future<LibraryRow?> read(String uid, String doc);

  /// Replaces [doc]'s data only if its `updated_at` is still [seen]. The row
  /// as written, or null when another device wrote it first.
  Future<LibraryRow?> update(
    String uid,
    String doc,
    Object? data,
    String? seen,
  );

  /// Creates [doc]'s row. The row as written, or null when another device
  /// created it first.
  Future<LibraryRow?> insert(String uid, String doc, Object? data);
}

class _SupabaseRemote implements LibraryRemote {
  const _SupabaseRemote();

  SupabaseQueryBuilder get _table =>
      Supabase.instance.client.from('user_documents');

  static LibraryRow _row(Map<String, dynamic> r) =>
      LibraryRow(r['data'], r['updated_at']?.toString());

  static String _stamp() => DateTime.now().toUtc().toIso8601String();

  @override
  Future<Map<String, LibraryRow>> readAll(String uid) async {
    final rows = await _table
        .select('doc, data, updated_at')
        .eq('user_id', uid);
    return {for (final r in rows) r['doc'] as String: _row(r)};
  }

  @override
  Future<LibraryRow?> read(String uid, String doc) async {
    final rows = await _table
        .select('data, updated_at')
        .eq('user_id', uid)
        .eq('doc', doc);
    return rows.isEmpty ? null : _row(rows.first);
  }

  @override
  Future<LibraryRow?> update(
    String uid,
    String doc,
    Object? data,
    String? seen,
  ) async {
    var query = _table
        .update({'data': data, 'client_updated_at': _stamp()})
        .eq('user_id', uid)
        .eq('doc', doc);
    // The raw string the server sent, not a parsed DateTime: it keeps the
    // microseconds the comparison needs.
    query = seen == null
        ? query.isFilter('updated_at', null)
        : query.eq('updated_at', seen);
    final rows = await query.select('data, updated_at');
    return rows.isEmpty ? null : _row(rows.first);
  }

  @override
  Future<LibraryRow?> insert(String uid, String doc, Object? data) async {
    try {
      final rows = await _table
          .insert({
            'user_id': uid,
            'doc': doc,
            'data': data,
            'client_updated_at': _stamp(),
          })
          .select('data, updated_at');
      return rows.isEmpty ? null : _row(rows.first);
    } on PostgrestException catch (e) {
      // unique_violation: another device created the row meanwhile.
      if (e.code == '23505') return null;
      rethrow;
    }
  }
}

/// Mirrors each account's library to the server (`public.user_documents`), so
/// Continue Watching, My List, finished episodes and taste follow the account
/// to every device.
///
/// **Copies are merged, never replaced.** Every sync reads the server copy,
/// merges it with this device's (per entry, the one that changed last wins; a
/// removal wins over anything older than it), keeps the result locally and
/// writes it back. A fresh device, a device that was offline, or one whose
/// clock is wrong therefore adds what it has and loses nothing. Removals are
/// remembered for [_removalMemory] so a stale copy cannot resurrect them.
///
/// **Writes are compare-and-swap.** A write only lands if the row's
/// `updated_at` (stamped by the server on every write) is still the one the
/// merge read; if another device wrote in between, the row is read and merged
/// again, up to [_attempts] times, so neither device's change is overwritten.
///
/// **Times are kept honest.** Each write's `updated_at` tells this device how
/// far its clock is from the server's ([now]). Removals are stamped with that
/// corrected clock, and when merging, any time further ahead than [_maxLead]
/// is pulled back to it, so a device whose clock runs fast cannot make its
/// edits or removals beat later real ones.
abstract final class LibrarySync {
  static const Duration _removalMemory = Duration(days: 90);

  /// How far into the server's future a time may be before it is pulled
  /// back: room for the offset's own error, not for a wrong clock.
  static const Duration _maxLead = Duration(minutes: 2);

  /// Merge-and-write rounds per sync while other devices keep winning the
  /// race; after that it waits for the next sync.
  static const int _attempts = 3;

  static final Map<String, _Doc> _docs = {
    'continue_watching': _Doc(
      export: ContinueWatchingService.exportDocument,
      import: ContinueWatchingService.importDocument,
      reload: ContinueWatchingService.reloadLocal,
      keyOf: (m) => ContinueWatchingItem.fromJson(m).sessionKey,
      timeOf: (m) => ContinueWatchingItem.fromJson(m).lastWatchedAt,
      retime: (m, at) => m['lastWatchedAt'] = at.toUtc().toIso8601String(),
      removals: true,
      limit: 50,
    ),
    'my_list': _Doc(
      export: MyListService.exportDocument,
      import: MyListService.importDocument,
      reload: MyListService.reloadLocal,
      keyOf: (m) => MyListItem.fromJson(m).uniqueKey,
      timeOf: (m) => MyListItem.fromJson(m).addedAt,
      retime: (m, at) => m['addedAt'] = at.toUtc().toIso8601String(),
      aliasesOf: (m) => MyListItem.fromJson(m).aliasKeys,
      removals: true,
      limit: MyListService.maxItems,
    ),
    'watched_episodes': const _Doc(
      export: WatchedEpisodes.exportDocument,
      import: WatchedEpisodes.importDocument,
      reload: WatchedEpisodes.initialize,
    ),
    'taste': _Doc(
      export: TasteStore.exportDocument,
      import: TasteStore.importDocument,
      reload: TasteStore.initialize,
      keyOf: (m) => m['id']?.toString() ?? '',
      // [TasteEntry.toJson] keeps the last sighting as epoch ms under 'ls'.
      timeOf: (m) {
        final ls = m['ls'];
        return DateTime.fromMillisecondsSinceEpoch(ls is num ? ls.toInt() : 0);
      },
      retime: (m, at) => m['ls'] = at.millisecondsSinceEpoch,
      limit: TasteStore.maxEntries,
    ),
  };

  static String? _userId;
  static bool _started = false;
  static final Map<String, Timer> _pending = {};
  static DateTime _lastPull = DateTime.fromMillisecondsSinceEpoch(0);

  /// Syncs in flight, one per document, so two never interleave.
  static final Map<String, Future<void>> _running = {};

  /// Tombstone writes in flight, one chain per document (see [_addTombs]).
  static final Map<String, Future<void>> _tombWrites = {};

  static LibraryRemote _remote = const _SupabaseRemote();

  /// The server's clock minus this device's, as last measured (see
  /// [_noteServerTime]); kept across launches.
  static Duration _clockOffset = Duration.zero;
  static const _clockKey = 'lumora_sync_clock_offset_ms';

  /// The time now on the server's clock, as well as this device can tell.
  /// Removals are stamped with it; before the first write it is this
  /// device's own clock.
  static DateTime now() => DateTime.now().toUtc().add(_clockOffset);

  /// After the library services have loaded: follow account changes and
  /// bring the signed-in account's copy up to date.
  static void start() {
    if (_started || !AccountService.configured) return;
    _started = true;
    _userId = AccountScope.userId;
    AccountService.session.addListener(_onSession);
    unawaited(_loadClockOffset().whenComplete(() => pull(force: true)));
  }

  static Future<void> _loadClockOffset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_clockKey);
      if (ms != null) _clockOffset = Duration(milliseconds: ms);
    } catch (_) {}
  }

  /// Measures the clock offset from a write's server stamp: the server set
  /// [stamp] somewhere between [sent] and [received] on this device's clock,
  /// so it is taken to be their midpoint.
  static void _noteServerTime(String? stamp, DateTime sent, DateTime received) {
    final server = DateTime.tryParse(stamp ?? '');
    if (server == null) return;
    final mid = sent.add(received.difference(sent) ~/ 2);
    _clockOffset = server.difference(mid);
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_clockKey, _clockOffset.inMilliseconds);
      } catch (_) {}
    }());
  }

  static void _onSession() {
    final id = AccountScope.userId;
    if (id == _userId) return;
    _userId = id;
    for (final t in _pending.values) {
      t.cancel();
    }
    _pending.clear();
    // Trakt and Simkl pairings are per account too (see [StorageService]):
    // nothing the last account's pairing cached may answer for this one.
    TraktService.instance.resetProfileScope();
    SimklService.instance.resetProfileScope();
    unawaited(_switchAccount());
  }

  static Future<void> _switchAccount() async {
    await AccountScope.adoptUnscopedLibrary();
    for (final doc in _docs.values) {
      try {
        await doc.reload();
      } catch (e) {
        debugPrint('[LibrarySync] reload: $e');
      }
    }
    await pull(force: true);
  }

  /// The services call this after saving [name]; the sync waits a moment so a
  /// run of progress saves goes up once.
  static void changed(String name) {
    final uid = AccountScope.userId;
    if (!_started || uid == null || !_docs.containsKey(name)) return;
    _pending[name]?.cancel();
    _pending[name] = Timer(const Duration(seconds: 4), () {
      _pending.remove(name);
      unawaited(_syncOne(name, uid));
    });
  }

  /// Sends every change still waiting out [changed]'s pause, and waits for
  /// the syncs already running. Sign-out awaits it: once the account is gone
  /// its pending changes can no longer go up.
  static Future<void> flush() async {
    final uid = AccountScope.userId;
    if (!_started || uid == null) return;
    // Removals still being written schedule their own sync when done.
    await Future.wait(_tombWrites.values.toList());
    final names = _pending.keys.toList();
    for (final name in names) {
      _pending.remove(name)?.cancel();
    }
    for (final name in names) {
      unawaited(_syncOne(name, uid));
    }
    await Future.wait(_running.values.toList());
  }

  /// Remembers that [key] was removed from [name] just now, so the merge
  /// drops older copies of it everywhere, then syncs.
  static void removed(String name, String key) => removedMany(name, [key]);

  /// [removed] for several keys at once: one tombstone write. A title kept
  /// under several ids passes every one of them (see [MyListItem.aliasKeys]).
  static void removedMany(String name, Iterable<String> keys) {
    final uid = AccountScope.userId;
    final at = now().toIso8601String();
    final tombs = {
      for (final key in keys)
        if (key.isNotEmpty) key: at,
    };
    if (!_started || uid == null || tombs.isEmpty) return;
    unawaited(
      _addTombs(
        name,
        uid,
        tombs,
        onSaved: () {
          if (AccountScope.userId == uid) changed(name);
        },
      ),
    );
  }

  /// Merges every document with the server copy. At most once a minute
  /// unless [force]d (start, account change).
  static Future<void> pull({bool force = false}) async {
    final uid = AccountScope.userId;
    if (!_started || uid == null) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastPull) < const Duration(minutes: 1)) {
      return;
    }
    _lastPull = now;
    final Map<String, LibraryRow> remote;
    try {
      remote = await _remote.readAll(uid);
    } catch (e) {
      debugPrint('[LibrarySync] pull: $e');
      // Try again on the next chance instead of waiting out the minute.
      _lastPull = DateTime.fromMillisecondsSinceEpoch(0);
      return;
    }
    for (final name in _docs.keys) {
      if (AccountScope.userId != uid) return;
      await _serial(
        name,
        () => _reconcile(name, uid, fetched: true, row: remote[name]),
      );
    }
  }

  static Future<void> _syncOne(String name, String uid) =>
      _serial(name, () => _reconcile(name, uid));

  /// Reads [name]'s row (unless the caller just [fetched] it as [row]),
  /// merges and writes, and starts over from a fresh read while another
  /// device's write keeps landing first.
  static Future<void> _reconcile(
    String name,
    String uid, {
    bool fetched = false,
    LibraryRow? row,
  }) async {
    var current = row;
    var read = !fetched;
    for (var attempt = 0; attempt < _attempts; attempt++) {
      if (AccountScope.userId != uid) return;
      if (read) {
        try {
          current = await _remote.read(uid, name);
        } catch (e) {
          // Offline: nothing is lost locally; the next pull merges it up.
          debugPrint('[LibrarySync] sync $name: $e');
          _lastPull = DateTime.fromMillisecondsSinceEpoch(0);
          return;
        }
      }
      if (!await _merge(name, uid, current)) return;
      read = true;
    }
    // Still losing the race: the merged copy is kept here, and the next
    // pull (on resume, or the next change) sends it.
    debugPrint('[LibrarySync] $name: server busy, left for the next sync');
    _lastPull = DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Future<void> _serial(String name, Future<void> Function() run) {
    final previous = _running[name] ?? Future<void>.value();
    final next = previous.then((_) => run()).catchError((Object e) {
      debugPrint('[LibrarySync] $name: $e');
    });
    _running[name] = next;
    return next;
  }

  /// Merges [remote] (null: no row yet) with this device's copy, keeps the
  /// result here and writes it back to the server when it differs. True when
  /// another device wrote the row first, so it must be read and merged again.
  static Future<bool> _merge(
    String name,
    String uid,
    LibraryRow? remote,
  ) async {
    final doc = _docs[name]!;
    final local = doc.export();
    final localTombs = doc.removals
        ? await _tombs(name, uid)
        : <String, String>{};
    if (AccountScope.userId != uid) return false;

    final at = now();
    final (remoteBody, remoteTombs) = _unwrap(remote?.data);
    final tombs = _mergeTombs(localTombs, remoteTombs, now: at);
    final merged = _mergeBodies(doc, local, remoteBody, tombs, at);

    // A change made here while the server answered is newer than both
    // copies: leave it, and sync again so it is merged and sent.
    if (!_same(doc.export(), local)) {
      changed(name);
      return false;
    }
    if (AccountScope.userId != uid) return false;
    if (!_same(merged, local)) {
      await doc.import(merged);
    }
    // Added to what is stored, not over it: a removal made meanwhile stays.
    if (doc.removals) await _addTombs(name, uid, tombs);

    // What the service kept (it may fold duplicates the merge could not
    // see), so the server copy matches this device's.
    final kept = AccountScope.userId == uid ? doc.export() : merged;
    final payload = doc.removals ? {'items': kept, 'removed': tombs} : kept;
    if (remote != null && _same(payload, remote.data)) return false;
    if (AccountScope.userId != uid) return false;
    final sent = DateTime.now();
    try {
      final written = remote == null
          ? await _remote.insert(uid, name, payload)
          : await _remote.update(uid, name, payload, remote.updatedAt);
      if (written == null) return true;
      _noteServerTime(written.updatedAt, sent, DateTime.now());
    } catch (e) {
      debugPrint('[LibrarySync] push $name: $e');
      _lastPull = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return false;
  }

  /// Equal as JSON, whatever order map keys come in (the server stores
  /// `jsonb`, which reorders them).
  static bool _same(Object? a, Object? b) =>
      jsonEncode(_canon(a)) == jsonEncode(_canon(b));

  static Object? _canon(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: _canon(v[k])};
    }
    if (v is List) return [for (final e in v) _canon(e)];
    return v;
  }

  /// The entries and tombstones of a server copy, in either format: the bare
  /// document of the first sync version, or `{items, removed}`.
  static (Object?, Map<String, String>) _unwrap(Object? data) {
    if (data is Map && data.containsKey('items')) {
      final removed = data['removed'];
      return (
        data['items'],
        removed is Map
            ? {
                for (final e in removed.entries)
                  e.key.toString(): e.value.toString(),
              }
            : <String, String>{},
      );
    }
    return (data, <String, String>{});
  }

  /// Per key, the later removal. One dated further ahead than [_maxLead]
  /// past [now] (a device whose clock runs fast) is stored as that limit, so
  /// it stops outranking edits made after it once real time passes it.
  static Map<String, String> _mergeTombs(
    Map<String, String> a,
    Map<String, String> b, {
    DateTime? now,
  }) {
    final at0 = now ?? LibrarySync.now();
    final cutoff = at0.subtract(_removalMemory);
    final ceiling = at0.add(_maxLead);
    final out = <String, String>{};
    for (final m in [a, b]) {
      for (final e in m.entries) {
        var at = DateTime.tryParse(e.value);
        if (at == null || at.isBefore(cutoff)) continue;
        var value = e.value;
        if (at.isAfter(ceiling)) {
          at = ceiling;
          value = ceiling.toUtc().toIso8601String();
        }
        final had = DateTime.tryParse(out[e.key] ?? '');
        if (had == null || at.isAfter(had)) out[e.key] = value;
      }
    }
    return out;
  }

  @visibleForTesting
  static Map<String, String> mergeTombsForTesting(
    Map<String, String> a,
    Map<String, String> b, {
    DateTime? now,
  }) => _mergeTombs(a, b, now: now);

  @visibleForTesting
  static Object? mergeForTesting(
    String name,
    Object? local,
    Object? remote,
    Map<String, String> tombs, {
    DateTime? now,
  }) => _mergeBodies(
    _docs[name]!,
    local,
    remote,
    tombs,
    now ?? LibrarySync.now(),
  );

  /// [now] is the server's time (see [LibrarySync.now]): entry times further
  /// ahead than [_maxLead] past it are pulled back to that limit, and written
  /// back into the entry so the copy kept is corrected too.
  static Object? _mergeBodies(
    _Doc doc,
    Object? local,
    Object? remote,
    Map<String, String> tombs,
    DateTime now,
  ) {
    // Watched episodes: a show's finished episodes are the union of both.
    if (doc.keyOf == null) {
      final out = <String, List<String>>{};
      for (final side in [local, remote]) {
        if (side is! Map) continue;
        for (final e in side.entries) {
          final list = out.putIfAbsent(e.key.toString(), () => []);
          for (final k in (e.value is List ? e.value as List : const [])) {
            final key = k.toString();
            if (!list.contains(key)) list.add(key);
          }
        }
      }
      return out;
    }

    final ceiling = now.toUtc().add(_maxLead);
    final byKey = <String, Map<String, dynamic>>{};
    final times = <String, DateTime>{};
    for (final side in [local, remote]) {
      if (side is! List) continue;
      for (final raw in side) {
        if (raw is! Map) continue;
        final entry = Map<String, dynamic>.from(raw);
        final String key;
        DateTime at;
        try {
          key = doc.keyOf!(entry);
          at = doc.timeOf!(entry);
        } catch (_) {
          continue;
        }
        if (key.isEmpty) continue;
        if (at.isAfter(ceiling)) {
          at = ceiling;
          doc.retime?.call(entry, ceiling);
        }
        final had = times[key];
        if (had == null || at.isAfter(had)) {
          byKey[key] = entry;
          times[key] = at;
        }
      }
    }
    final kept = [
      for (final e in byKey.entries)
        if (!_removed(doc, e.key, e.value, times[e.key]!, tombs, ceiling)) e,
    ]..sort((a, b) => times[b.key]!.compareTo(times[a.key]!));
    final capped = doc.limit == null ? kept : kept.take(doc.limit!);
    return [for (final e in capped) e.value];
  }

  /// Whether a removal of [entry] under any of its keys is no older than its
  /// change at [changedAt]. Removal times past [ceiling] count as [ceiling].
  static bool _removed(
    _Doc doc,
    String key,
    Map<String, dynamic> entry,
    DateTime changedAt,
    Map<String, String> tombs,
    DateTime ceiling,
  ) {
    List<String> keys;
    try {
      keys = doc.aliasesOf?.call(entry) ?? [key];
    } catch (_) {
      keys = [key];
    }
    for (final k in {key, ...keys}) {
      var at = DateTime.tryParse(tombs[k] ?? '');
      if (at == null) continue;
      if (at.isAfter(ceiling)) at = ceiling;
      if (!at.isBefore(changedAt.toUtc())) return true;
    }
    return false;
  }

  static String _tombKey(String name, String uid) =>
      'lumora_removed_$name@$uid';

  static Future<Map<String, String>> _tombs(String name, String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tombKey(name, uid));
      if (raw == null) return {};
      final map = jsonDecode(raw) as Map;
      return {
        for (final e in map.entries) e.key.toString(): e.value.toString(),
      };
    } catch (_) {
      return {};
    }
  }

  /// Merges [tombs] into the stored tombstones of [name], one write at a time
  /// per document, so two writers never drop each other's removals.
  /// [onSaved] runs once they are stored, still in turn.
  static Future<void> _addTombs(
    String name,
    String uid,
    Map<String, String> tombs, {
    void Function()? onSaved,
  }) {
    final previous = _tombWrites[name] ?? Future<void>.value();
    final next = previous
        .then((_) async {
          final stored = await _tombs(name, uid);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            _tombKey(name, uid),
            jsonEncode(_mergeTombs(stored, tombs)),
          );
          onSaved?.call();
        })
        .catchError((Object e) {
          debugPrint('[LibrarySync] tombstones $name: $e');
        });
    _tombWrites[name] = next;
    return next;
  }

  @visibleForTesting
  static Future<Map<String, String>> tombsForTesting(String name, String uid) =>
      _tombs(name, uid);

  @visibleForTesting
  static Future<void> addTombsForTesting(
    String name,
    String uid,
    Map<String, String> tombs,
  ) => _addTombs(name, uid, tombs);

  /// Swaps the server table for [remote]; null restores the real one.
  @visibleForTesting
  static set remoteForTesting(LibraryRemote? remote) =>
      _remote = remote ?? const _SupabaseRemote();

  @visibleForTesting
  static Duration get clockOffsetForTesting => _clockOffset;

  @visibleForTesting
  static set clockOffsetForTesting(Duration offset) => _clockOffset = offset;

  /// One sync of [name] for [uid], as a change would run it.
  @visibleForTesting
  static Future<void> syncForTesting(String name, String uid) =>
      _syncOne(name, uid);
}
