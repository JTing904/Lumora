import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/secret_keys.dart';
import '../storage/storage_service.dart';
import 'account_service.dart';

/// Keeps each account's library (Continue Watching, My List, finished
/// episodes, taste, reading, listening and music history) and its own
/// service sign-ins apart on a shared device.
///
/// A store saves under [key], which carries the signed-in account's id, so a
/// second account on the same tablet starts empty instead of seeing the first
/// one's history. Signed out, the plain key is used.
abstract final class AccountScope {
  /// The documents kept per account; [LibrarySync] mirrors the same ones to
  /// the account on the server.
  static const List<String> scopedKeys = [
    'continue_watching_sessions_v1',
    'my_list_v1',
    'lumora_watched_episodes',
    'lumora_taste_v1',
  ];

  /// The other histories kept per account. They stay on this device: only
  /// [scopedKeys] go up to the server.
  static const List<String> personalKeys = [
    'continue_reading_sessions_v1',
    'audiobook_continue_listening_v2',
    'music_liked_tracks_v3',
    'music_recent_tracks_v3',
    'music_user_playlists_v3',
    'zplay_anime_watchlist_v2',
    'zplay_anime_history_v2',
  ];

  static const _migratedKey = 'lumora_library_scoped_v1';
  static const _pairingMigratedKey = 'lumora_pairing_scoped_v1';
  static const _personalMigratedKey = 'lumora_personal_scoped_v1';
  static const _debridMigratedKey = 'lumora_debrid_scoped_v1';

  static String? get userId => AccountService.session.value?.user.id;

  /// [base] for the account signed in now.
  static String key(String base) {
    final id = userId;
    return id == null ? base : '$base@$id';
  }

  /// `name@<account id>`: an account id is a UUID, so a key that merely
  /// contains an `@` is not mistaken for one.
  static final RegExp _scopedPattern = RegExp(
    r'^(.+)@([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$',
  );

  /// The plain name and the account of a key saved by [key] while signed in,
  /// or null for a key kept for the whole device.
  static ({String base, String uid})? splitScoped(String prefKey) {
    final match = _scopedPattern.firstMatch(prefKey);
    if (match == null) return null;
    return (base: match.group(1)!, uid: match.group(2)!);
  }

  /// Every preference saved under [key], so a profile file can carry it
  /// under its plain name and an import can put it in the importing account.
  static bool isPerAccount(String base) =>
      scopedKeys.contains(base) ||
      personalKeys.contains(base) ||
      StorageService.pairingPrefKeys.contains(base) ||
      base == 'lumora_new_episode_cache_v1';

  /// The session supabase_flutter keeps (`sb-<project>-auth-token`) and the
  /// PKCE verifier of a sign-in in progress.
  static final RegExp _sessionPattern = RegExp(r'^sb-.+-auth-token');

  /// Preferences that are this device's sign-in rather than anyone's
  /// settings: the account session, a code waiting for its GitHub sign-up,
  /// the server's last word on an invite, the sync's removal records and
  /// clock, and the one-time moves above.
  ///
  /// A profile export or a diagnostics report never carries them and an
  /// import never writes them: a copied session signs the reader in as the
  /// writer, a copied invite answer would let an account past the code page
  /// offline, and a copied removal record would delete titles from the
  /// account the file is imported into.
  static bool isDeviceAccountState(String prefKey) {
    final base = splitScoped(prefKey)?.base ?? prefKey;
    return _sessionPattern.hasMatch(base) ||
        base.startsWith('supabase.auth.') ||
        base == AccountService.pendingInviteKey ||
        base == AccountService.invitedCacheKey ||
        base.startsWith('lumora_removed_') ||
        base == 'lumora_sync_clock_offset_ms' ||
        base == _migratedKey ||
        base == _pairingMigratedKey ||
        base == _personalMigratedKey ||
        base == _debridMigratedKey;
  }

  /// Once per device: the library it kept before it was split by account
  /// belongs to the first account signed in on this version (on an updated
  /// install, the one that was already signed in).
  ///
  /// What was split by account later (the Trakt / Simkl pairing, the
  /// reading, listening and music histories, the debrid subscriptions) is
  /// adopted the same way, each under its own flag, so an updated install
  /// moves it once to the account signed in then and loses none of it.
  static Future<void> adoptUnscopedLibrary() async {
    try {
      final id = userId;
      if (id == null) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_migratedKey) != true) {
        await _adoptDocuments(prefs, scopedKeys, id);
        await prefs.setBool(_migratedKey, true);
      }
      if (prefs.getBool(_pairingMigratedKey) != true) {
        await StorageService.adoptUnscopedPairing(id);
        await prefs.setBool(_pairingMigratedKey, true);
      }
      if (prefs.getBool(_personalMigratedKey) != true) {
        await _adoptDocuments(prefs, personalKeys, id);
        await prefs.setBool(_personalMigratedKey, true);
      }
      if (prefs.getBool(_debridMigratedKey) != true) {
        await StorageService.adoptUnscopedSecrets(id, SecretKeys.debridTokens);
        await prefs.setBool(_debridMigratedKey, true);
      }
    } catch (e) {
      debugPrint('[AccountScope] adopting the device library failed: $e');
    }
  }

  /// Moves each of [bases] to [id]'s copy, unless that account already has
  /// one.
  static Future<void> _adoptDocuments(
    SharedPreferences prefs,
    List<String> bases,
    String id,
  ) async {
    for (final base in bases) {
      final value = prefs.getString(base);
      if (value == null || prefs.containsKey('$base@$id')) continue;
      await prefs.setString('$base@$id', value);
      await prefs.remove(base);
      await prefs.remove('${base}__backup');
    }
  }
}
