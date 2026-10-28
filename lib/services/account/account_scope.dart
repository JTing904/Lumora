import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/storage_service.dart';
import 'account_service.dart';

/// Keeps each account's library (Continue Watching, My List, finished
/// episodes, taste) apart on a shared device.
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

  static const _migratedKey = 'lumora_library_scoped_v1';
  static const _pairingMigratedKey = 'lumora_pairing_scoped_v1';

  static String? get userId => AccountService.session.value?.user.id;

  /// [base] for the account signed in now.
  static String key(String base) {
    final id = userId;
    return id == null ? base : '$base@$id';
  }

  /// Once per device: the library it kept before it was split by account
  /// belongs to the first account signed in on this version (on an updated
  /// install, the one that was already signed in).
  ///
  /// The Trakt / Simkl pairing, split by account later, is adopted the same
  /// way under its own flag.
  static Future<void> adoptUnscopedLibrary() async {
    try {
      final id = userId;
      if (id == null) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_migratedKey) != true) {
        for (final base in scopedKeys) {
          final value = prefs.getString(base);
          if (value == null || prefs.containsKey('$base@$id')) continue;
          await prefs.setString('$base@$id', value);
          await prefs.remove(base);
          await prefs.remove('${base}__backup');
        }
        await prefs.setBool(_migratedKey, true);
      }
      if (prefs.getBool(_pairingMigratedKey) != true) {
        await StorageService.adoptUnscopedPairing(id);
        await prefs.setBool(_pairingMigratedKey, true);
      }
    } catch (e) {
      debugPrint('[AccountScope] adopting the device library failed: $e');
    }
  }
}
