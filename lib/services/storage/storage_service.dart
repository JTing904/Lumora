import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../account/account_scope.dart';
import 'secret_keys.dart';
import 'secure_store.dart';

/// Trakt and Simkl pairings are kept per Lumora account (see [AccountScope]):
/// on a shared device a second account starts unpaired, so the first one's
/// watchlist and progress never merge into its library.
class StorageService {
  static const _kTraktTokenExpiry = 'trakt_token_expiry_ms';
  static const _kTraktUsername = 'trakt_username';
  static const _kSimklUsername = 'simkl_username';

  static final ValueNotifier<int> movieFinishedRevision = ValueNotifier<int>(0);

  static String _key(String base) => AccountScope.key(base);

  // ── Trakt ─────────────────────────────────────────────────────────────────
  static Future<String?> getTraktAccessToken() =>
      SecureStore.read(_key(SecretKeys.traktAccessToken));

  static Future<void> setTraktAccessToken(String token) =>
      SecureStore.write(_key(SecretKeys.traktAccessToken), token);

  static Future<String?> getTraktRefreshToken() =>
      SecureStore.read(_key(SecretKeys.traktRefreshToken));

  static Future<void> setTraktRefreshToken(String token) =>
      SecureStore.write(_key(SecretKeys.traktRefreshToken), token);

  static Future<int?> getTraktTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(_kTraktTokenExpiry));
  }

  static Future<void> setTraktTokenExpiry(int expiryMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(_kTraktTokenExpiry), expiryMs);
  }

  static Future<String?> getTraktUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(_kTraktUsername));
  }

  static Future<void> setTraktUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(_kTraktUsername), username);
  }

  static Future<bool> clearTraktAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await SecureStore.delete(_key(SecretKeys.traktAccessToken));
    await SecureStore.delete(_key(SecretKeys.traktRefreshToken));
    await prefs.remove(_key(_kTraktTokenExpiry));
    await prefs.remove(_key(_kTraktUsername));
    return true;
  }

  // ── Simkl ─────────────────────────────────────────────────────────────────
  static Future<String?> getSimklAccessToken() =>
      SecureStore.read(_key(SecretKeys.simklAccessToken));

  static Future<void> setSimklAccessToken(String token) =>
      SecureStore.write(_key(SecretKeys.simklAccessToken), token);

  static Future<String?> getSimklUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(_kSimklUsername));
  }

  static Future<void> setSimklUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(_kSimklUsername), username);
  }

  static Future<void> clearSimklAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await SecureStore.delete(_key(SecretKeys.simklAccessToken));
    await prefs.remove(_key(_kSimklUsername));
  }

  /// Once per device (see [AccountScope.adoptUnscopedLibrary]): a pairing
  /// made before pairings were split by account belongs to the account
  /// [userId], unless that account already has its own.
  static Future<void> adoptUnscopedPairing(String userId) async {
    for (final base in const [
      SecretKeys.traktAccessToken,
      SecretKeys.traktRefreshToken,
      SecretKeys.simklAccessToken,
    ]) {
      final value = await SecureStore.read(base);
      if (value == null) continue;
      final scoped = '$base@$userId';
      if (await SecureStore.read(scoped) == null) {
        await SecureStore.write(scoped, value);
      }
      await SecureStore.delete(base);
    }
    final prefs = await SharedPreferences.getInstance();
    for (final base in const [
      _kTraktTokenExpiry,
      _kTraktUsername,
      _kSimklUsername,
    ]) {
      final value = prefs.get(base);
      if (value == null) continue;
      final scoped = '$base@$userId';
      if (!prefs.containsKey(scoped)) {
        if (value is int) await prefs.setInt(scoped, value);
        if (value is String) await prefs.setString(scoped, value);
      }
      await prefs.remove(base);
    }
  }
}
