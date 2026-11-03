import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The storage surface [SecureStore] needs from a platform keystore.
abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [SecureKeyValueStore] backed by the platform keystore. Android uses
/// EncryptedSharedPreferences, Apple the Keychain, Windows DPAPI, Linux
/// libsecret.
class PlatformSecureKeyValueStore implements SecureKeyValueStore {
  PlatformSecureKeyValueStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Credential storage that prefers the platform keystore.
///
/// A keystore is not always there: unit tests have no plugin, a Linux desktop
/// without libsecret cannot open one, and a locked keychain can refuse a read.
/// None of those may make a saved credential disappear, so when the keystore
/// fails every operation degrades to [SharedPreferences] under the same key,
/// and a value found only in preferences is migrated into the keystore on the
/// first successful read. A keystore that is only slow is waited for instead:
/// reading around it would miss a migrated secret, and writing around it would
/// put the secret in plaintext.
abstract final class SecureStore {
  static final SecureKeyValueStore _platformStore =
      PlatformSecureKeyValueStore();

  /// Stands in for the platform keystore in tests.
  @visibleForTesting
  static SecureKeyValueStore? storeOverride;

  static bool _warned = false;

  static SecureKeyValueStore get _store => storeOverride ?? _platformStore;

  /// True under `flutter test` with no explicit fake keystore.
  ///
  /// The plugin has no method handler in a unit test, and the call does not
  /// fail fast there: it leaves a pending future and, with the timeout below,
  /// a pending timer that outlives the widget tree. Tests that need to exercise
  /// the keystore install [storeOverride]; every other test reads and writes
  /// the same preferences the legacy path uses.
  static bool get _isFlutterTest =>
      !kIsWeb && Platform.environment['FLUTTER_TEST'] == 'true';

  static bool get _bypassPlatformStore =>
      storeOverride == null && _isFlutterTest;

  /// Restores the platform keystore and clears the one-time warning, so each
  /// test starts from the same place.
  @visibleForTesting
  static void resetForTesting() {
    storeOverride = null;
    _warned = false;
    _unresponsive = false;
    platformTimeout = _defaultPlatformTimeout;
    slowKeystoreGrace = _defaultSlowKeystoreGrace;
  }

  /// How long a keystore call gets before it counts as slow. The platform
  /// implementations usually answer in milliseconds, but the first call on a
  /// slow phone (Android Keystore unlocking EncryptedSharedPreferences) can
  /// take seconds; the old 500 ms sent those reads to preferences, where a
  /// migrated secret no longer is, and those writes to plaintext.
  static const Duration _defaultPlatformTimeout = Duration(seconds: 5);

  /// How much longer a slow keystore is waited for before giving up. Slow is
  /// not missing: a keystore that is not there throws instead, and only that
  /// falls back to preferences.
  static const Duration _defaultSlowKeystoreGrace = Duration(seconds: 10);

  @visibleForTesting
  static Duration platformTimeout = _defaultPlatformTimeout;

  @visibleForTesting
  static Duration slowKeystoreGrace = _defaultSlowKeystoreGrace;

  /// Set once a call has outlasted the grace as well, cleared by any call
  /// that answers. Startup reads several secrets in a row, so a keystore that
  /// has stopped answering costs the longer wait once, not once per secret
  /// before the first frame.
  static bool _unresponsive = false;

  static Duration get _graceNow =>
      _unresponsive ? Duration.zero : slowKeystoreGrace;

  /// The stored value for [key], or null.
  ///
  /// A legacy plaintext preference is migrated on the first successful read:
  /// the value is written to the keystore, then removed from preferences.
  static Future<String?> read(String key) async {
    if (_bypassPlatformStore) return _legacyRead(key);

    final pending = _store.read(key);
    String? value;
    try {
      value = await pending.timeout(platformTimeout);
    } on TimeoutException {
      // A plaintext copy from before the migration can answer at once.
      // Otherwise the secret may well be in the keystore, so keep waiting for
      // it: answering "no value" here would sign the user out of a session
      // the keystore still holds.
      final legacy = await _legacyRead(key);
      if (legacy != null) {
        unawaited(pending.then<void>((_) {}, onError: (Object _) {}));
        return legacy;
      }
      try {
        value = await pending.timeout(_graceNow);
      } catch (error) {
        if (error is TimeoutException) _unresponsive = true;
        _warn('read', error);
        return null;
      }
    } catch (error) {
      _warn('read', error);
      return _legacyRead(key);
    }
    _unresponsive = false;

    if (value != null) {
      // A plaintext copy left over from before the migration must not
      // outlive the encrypted one.
      await _removeLegacy(key);
      return value;
    }

    return _migrateLegacy(key);
  }

  /// Stores [value] in the keystore, falling back to [SharedPreferences]
  /// only when there is no keystore at all.
  ///
  /// A successful keystore write removes the plaintext preference, so the
  /// secret does not exist in two places at once. A keystore that is merely
  /// slow is waited for and never answered with a plaintext copy: if even the
  /// longer wait runs out, the write is left to finish on its own and nothing
  /// is written to preferences.
  static Future<void> write(String key, String value) async {
    if (_bypassPlatformStore) {
      await _legacyWrite(key, value);
      return;
    }

    final pending = _store.write(key, value);
    try {
      await pending.timeout(platformTimeout + _graceNow);
      _unresponsive = false;
    } on TimeoutException catch (error) {
      _unresponsive = true;
      _warn('write', error);
      // When it does land, the plaintext copy (if any) goes, as on a write
      // that answered in time.
      unawaited(
        pending.then<void>((_) => _removeLegacy(key), onError: (Object _) {}),
      );
      return;
    } catch (error) {
      _warn('write', error);
      await _legacyWrite(key, value);
      return;
    }
    await _removeLegacy(key);
  }

  /// Removes [key] from the keystore and from [SharedPreferences].
  ///
  /// Both locations are cleared because either may hold the only copy, and a
  /// deleted credential must not come back on the next read.
  static Future<void> delete(String key) async {
    if (_bypassPlatformStore) {
      await _removeLegacy(key);
      return;
    }

    try {
      await _store.delete(key).timeout(platformTimeout);
    } catch (error) {
      _warn('delete', error);
    }
    await _removeLegacy(key);
  }

  static Future<String?> _legacyRead(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (error) {
      _warn('read fallback', error);
      return null;
    }
  }

  static Future<void> _legacyWrite(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (error) {
      _warn('write fallback', error);
    }
  }

  static Future<String?> _migrateLegacy(String key) async {
    final String? legacy;
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      legacy = prefs.getString(key);
    } catch (error) {
      _warn('migrate', error);
      return null;
    }
    if (legacy == null) return null;

    try {
      await _store.write(key, legacy).timeout(platformTimeout);
    } catch (error) {
      // The keystore refused the value, so the plaintext copy stays the only
      // readable one and is left where it is.
      _warn('migrate', error);
      return legacy;
    }
    await prefs.remove(key);
    return legacy;
  }

  static Future<void> _removeLegacy(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(key)) await prefs.remove(key);
    } catch (error) {
      _warn('remove legacy copy', error);
    }
  }

  /// One warning per process: a keystore that is missing fails on every
  /// credential at startup, and eight identical stack traces help nobody.
  static void _warn(String operation, Object error) {
    if (_warned) return;
    _warned = true;
    debugPrint('[SecureStore] $operation did not reach the keystore: $error');
  }
}

/// A keystore stand-in for tests, so the secure path can be exercised without
/// a plugin.
@visibleForTesting
class InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
