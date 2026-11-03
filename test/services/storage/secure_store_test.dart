import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/services/storage/secret_keys.dart';
import 'package:zplay/services/storage/secure_store.dart';

/// A keystore that is never there, which is what a Linux box without libsecret
/// and a unit test without the plugin both look like.
class _MissingKeystore implements SecureKeyValueStore {
  @override
  Future<String?> read(String key) async => throw StateError('no keystore');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('no keystore');

  @override
  Future<void> delete(String key) async => throw StateError('no keystore');
}

/// A keystore that is there but slow, like the first Android Keystore call
/// on a slow phone. [delay] null means it never answers.
class _SlowKeystore extends InMemorySecureKeyValueStore {
  _SlowKeystore(this.delay);

  final Duration? delay;

  Future<void> _wait() =>
      delay == null ? Completer<void>().future : Future<void>.delayed(delay!);

  @override
  Future<String?> read(String key) async {
    await _wait();
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    await _wait();
    values[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySecureKeyValueStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = InMemorySecureKeyValueStore();
    SecureStore.storeOverride = store;
  });

  tearDown(SecureStore.resetForTesting);

  test('a value written to the keystore is not left in preferences', () async {
    await SecureStore.write(SecretKeys.tmdbApiKey, 'secret-key');

    expect(store.values[SecretKeys.tmdbApiKey], 'secret-key');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(SecretKeys.tmdbApiKey), isFalse);

    expect(await SecureStore.read(SecretKeys.tmdbApiKey), 'secret-key');
  });

  test('a legacy plaintext value migrates on first read', () async {
    SharedPreferences.setMockInitialValues({
      SecretKeys.realDebridToken: 'legacy-token',
    });

    expect(await SecureStore.read(SecretKeys.realDebridToken), 'legacy-token');
    expect(store.values[SecretKeys.realDebridToken], 'legacy-token');

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey(SecretKeys.realDebridToken),
      isFalse,
      reason: 'the plaintext copy must not outlive the migrated one',
    );

    // A second read comes from the keystore alone.
    expect(await SecureStore.read(SecretKeys.realDebridToken), 'legacy-token');
  });

  test('delete removes the value from both stores', () async {
    await SecureStore.write(SecretKeys.simklAccessToken, 'token');
    await SecureStore.delete(SecretKeys.simklAccessToken);

    expect(store.values.containsKey(SecretKeys.simklAccessToken), isFalse);
    expect(await SecureStore.read(SecretKeys.simklAccessToken), isNull);
  });

  group('without a keystore', () {
    setUp(() {
      SecureStore.storeOverride = _MissingKeystore();
    });

    test(
      'a write and read fall back to preferences under the same key',
      () async {
        await SecureStore.write(SecretKeys.torboxApiKey, 'fallback-key');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(SecretKeys.torboxApiKey), 'fallback-key');
        expect(await SecureStore.read(SecretKeys.torboxApiKey), 'fallback-key');
      },
    );

    test('a legacy value stays readable and in place', () async {
      SharedPreferences.setMockInitialValues({
        SecretKeys.allDebridApiKey: 'legacy-key',
      });

      expect(await SecureStore.read(SecretKeys.allDebridApiKey), 'legacy-key');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(SecretKeys.allDebridApiKey),
        'legacy-key',
        reason:
            'nothing could be written to the keystore, so the only '
            'readable copy must be left where it is',
      );
    });

    test('delete still clears the preference', () async {
      SharedPreferences.setMockInitialValues({
        SecretKeys.premiumizeApiKey: 'old-key',
      });

      await SecureStore.delete(SecretKeys.premiumizeApiKey);
      expect(await SecureStore.read(SecretKeys.premiumizeApiKey), isNull);
    });
  });

  group('with a slow keystore', () {
    setUp(() {
      SecureStore.platformTimeout = const Duration(milliseconds: 20);
      SecureStore.slowKeystoreGrace = const Duration(milliseconds: 200);
    });

    test('a read waits for a secret that is only in the keystore', () async {
      final slow = _SlowKeystore(const Duration(milliseconds: 60))
        ..values[SecretKeys.tmdbApiKey] = 'in-keystore';
      SecureStore.storeOverride = slow;

      expect(await SecureStore.read(SecretKeys.tmdbApiKey), 'in-keystore');
    });

    test('a slow write lands in the keystore, never in preferences', () async {
      final slow = _SlowKeystore(const Duration(milliseconds: 60));
      SecureStore.storeOverride = slow;

      await SecureStore.write(SecretKeys.torboxApiKey, 'secret');

      expect(slow.values[SecretKeys.torboxApiKey], 'secret');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(SecretKeys.torboxApiKey), isFalse);
    });

    test('a write that never answers is not put in plaintext', () async {
      SecureStore.storeOverride = _SlowKeystore(null);

      await SecureStore.write(SecretKeys.torboxApiKey, 'secret');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(SecretKeys.torboxApiKey), isFalse);
    });
  });

  test('the secret registry covers tokens, keys and the service prefix', () {
    expect(SecretKeys.isSecret(SecretKeys.traktAccessToken), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.traktRefreshToken), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.simklAccessToken), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.tmdbApiKey), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.realDebridToken), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.allDebridApiKey), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.premiumizeApiKey), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.debridLinkApiKey), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.torboxApiKey), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.qobuzEclipseToken), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.qobuzEclipseEndpoint), isTrue);
    expect(SecretKeys.isSecret(SecretKeys.qobuzEclipseManifestUrl), isTrue);
    expect(SecretKeys.isSecret('service_key_wyzie'), isTrue);
    expect(SecretKeys.isSecret('service_key_trakt_secret'), isTrue);
    expect(SecretKeys.isSecret('debrid_service'), isFalse);
    expect(SecretKeys.isSecret('trakt_username'), isFalse);
    // A per-account copy is as secret as the plain key.
    expect(SecretKeys.isSecret('${SecretKeys.traktAccessToken}@u1'), isTrue);
    expect(SecretKeys.isSecret('trakt_username@u1'), isFalse);
  });
}
