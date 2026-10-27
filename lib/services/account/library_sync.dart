import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../continue_watching/continue_watching_service.dart';
import '../continue_watching/watched_episodes.dart';
import '../my_list/my_list_service.dart';
import '../recommend/taste_store.dart';
import 'account_scope.dart';
import 'account_service.dart';

/// One library document: how to read it out of its service and put it back.
class _Doc {
  const _Doc(this.export, this.import, this.reload);

  /// The service's current document, JSON-shaped.
  final Object? Function() export;

  /// Replaces the service's document with one from the account, saving it
  /// locally without reporting it back as a change.
  final Future<void> Function(Object? data) import;

  /// Re-reads the signed-in account's local copy.
  final Future<void> Function() reload;
}

/// Mirrors each account's library to the server (`public.user_documents`),
/// so Continue Watching, My List, finished episodes and taste follow the
/// account to another device.
///
/// Whole documents, newest wins: a change is pushed a few seconds after it
/// happens, and on start, sign-in and return to the app the server copy
/// replaces the local one when it is newer. Two devices changed while both
/// offline keep the later one.
abstract final class LibrarySync {
  static const Map<String, _Doc> _docs = {
    'continue_watching': _Doc(
      ContinueWatchingService.exportDocument,
      ContinueWatchingService.importDocument,
      ContinueWatchingService.reloadLocal,
    ),
    'my_list': _Doc(
      MyListService.exportDocument,
      MyListService.importDocument,
      MyListService.reloadLocal,
    ),
    'watched_episodes': _Doc(
      WatchedEpisodes.exportDocument,
      WatchedEpisodes.importDocument,
      WatchedEpisodes.initialize,
    ),
    'taste': _Doc(
      TasteStore.exportDocument,
      TasteStore.importDocument,
      TasteStore.initialize,
    ),
  };

  static String? _userId;
  static bool _started = false;
  static final Map<String, Timer> _pending = {};
  static DateTime _lastPull = DateTime.fromMillisecondsSinceEpoch(0);

  static SupabaseClient get _client => Supabase.instance.client;

  /// After the library services have loaded: follow account changes and
  /// bring the signed-in account's copy up to date.
  static void start() {
    if (_started || !AccountService.configured) return;
    _started = true;
    _userId = AccountScope.userId;
    AccountService.session.addListener(_onSession);
    unawaited(pull());
  }

  static void _onSession() {
    final id = AccountScope.userId;
    if (id == _userId) return;
    _userId = id;
    for (final t in _pending.values) {
      t.cancel();
    }
    _pending.clear();
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
    _lastPull = DateTime.fromMillisecondsSinceEpoch(0);
    await pull();
  }

  /// The services call this after saving [name]; the push waits a moment so
  /// a run of progress saves goes up once.
  static void changed(String name) {
    final uid = AccountScope.userId;
    if (!_started || uid == null || !_docs.containsKey(name)) return;
    unawaited(_setStamp(name, uid, DateTime.now().toUtc()));
    _pending[name]?.cancel();
    _pending[name] = Timer(const Duration(seconds: 5), () {
      _pending.remove(name);
      unawaited(_push(name, uid));
    });
  }

  /// Takes the server copies that are newer than this device's, and sends up
  /// the ones this device changed since. At most once a minute unless an
  /// account change asks for it.
  static Future<void> pull({bool force = false}) async {
    final uid = AccountScope.userId;
    if (!_started || uid == null) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastPull) < const Duration(minutes: 1)) {
      return;
    }
    _lastPull = now;
    try {
      final rows = await _client
          .from('user_documents')
          .select('doc, data, client_updated_at')
          .eq('user_id', uid);
      final remote = {for (final r in rows) r['doc'] as String: r};
      for (final entry in _docs.entries) {
        if (AccountScope.userId != uid) return;
        final name = entry.key;
        final local = await _stamp(name, uid);
        final row = remote[name];
        final remoteAt = row == null
            ? null
            : DateTime.tryParse(row['client_updated_at'].toString());
        if (remoteAt != null && (local == null || remoteAt.isAfter(local))) {
          await entry.value.import(row!['data']);
          await _setStamp(name, uid, remoteAt);
        } else if (local != null &&
            (remoteAt == null || local.isAfter(remoteAt))) {
          await _push(name, uid);
        } else if (local == null && remoteAt == null) {
          // Never synced either way: this device's copy is the first.
          await _setStamp(name, uid, DateTime.now().toUtc());
          await _push(name, uid);
        }
      }
    } catch (e) {
      debugPrint('[LibrarySync] pull: $e');
    }
  }

  static Future<void> _push(String name, String uid) async {
    if (AccountScope.userId != uid) return;
    final doc = _docs[name];
    final at = await _stamp(name, uid);
    if (doc == null || at == null) return;
    try {
      await _client.from('user_documents').upsert({
        'user_id': uid,
        'doc': name,
        'data': doc.export(),
        'client_updated_at': at.toIso8601String(),
      }, onConflict: 'user_id,doc');
    } catch (e) {
      debugPrint('[LibrarySync] push $name: $e');
    }
  }

  static String _stampKey(String name, String uid) =>
      'lumora_sync_at_$name@$uid';

  static Future<DateTime?> _stamp(String name, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stampKey(name, uid));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<void> _setStamp(String name, String uid, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stampKey(name, uid), at.toIso8601String());
  }
}
