import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zplay/services/account/account_service.dart';
import 'package:zplay/services/backup/profile_secrets.dart';
import 'package:zplay/services/config/service_credentials.dart';
import 'package:zplay/services/storage/secret_keys.dart';
import 'package:zplay/services/storage/secure_store.dart';
import 'package:zplay/services/storage/storage_service.dart';

Session _session(String id) => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySecureKeyValueStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = InMemorySecureKeyValueStore();
    SecureStore.storeOverride = store;
    await ServiceCredentials.initialize();
  });

  tearDown(() {
    SecureStore.resetForTesting();
    AccountService.session.value = null;
  });

  test('carries the signed-in account\'s Trakt and Simkl pairing', () async {
    AccountService.session.value = _session('a');
    await StorageService.setTraktAccessToken('trakt-a');
    await StorageService.setTraktRefreshToken('refresh-a');
    await StorageService.setSimklAccessToken('simkl-a');

    final exported = await ProfileSecrets.export();
    expect(exported[SecretKeys.traktAccessToken], 'trakt-a');
    expect(exported[SecretKeys.traktRefreshToken], 'refresh-a');
    expect(exported[SecretKeys.simklAccessToken], 'simkl-a');
    expect(exported.keys.where((key) => key.contains('@')), isEmpty);

    // Restored into another account on a fresh device, the pairing lands
    // where that account's StorageService reads it.
    final fresh = InMemorySecureKeyValueStore();
    SecureStore.storeOverride = fresh;
    AccountService.session.value = _session('b');
    await ProfileSecrets.import(exported);

    expect(await StorageService.getTraktAccessToken(), 'trakt-a');
    expect(await StorageService.getTraktRefreshToken(), 'refresh-a');
    expect(await StorageService.getSimklAccessToken(), 'simkl-a');
    expect(fresh.values['${SecretKeys.traktAccessToken}@b'], 'trakt-a');
    expect(fresh.values[SecretKeys.traktAccessToken], isNull);
  });

  test(
    'an older profile\'s plain pairing names reach the signed-in account',
    () async {
      AccountService.session.value = _session('a');
      await ProfileSecrets.import(<String, dynamic>{
        SecretKeys.traktAccessToken: 'old-trakt',
        SecretKeys.simklAccessToken: 'old-simkl',
      });

      expect(await StorageService.getTraktAccessToken(), 'old-trakt');
      expect(await StorageService.getSimklAccessToken(), 'old-simkl');
      expect(store.values[SecretKeys.traktAccessToken], isNull);
    },
  );

  test(
    'exports and imports the full credential set through the keystore',
    () async {
      await SecureStore.write(SecretKeys.traktAccessToken, 'trakt-token');
      await SecureStore.write(SecretKeys.torboxApiKey, 'torbox-key');
      await ServiceCredentials.save(ServiceCredential.wyzie, 'wyzie-key');

      final exported = await ProfileSecrets.export();
      expect(exported[SecretKeys.traktAccessToken], 'trakt-token');
      expect(exported[SecretKeys.torboxApiKey], 'torbox-key');
      expect(
        exported[ServiceCredentials.storageKeyFor(ServiceCredential.wyzie)],
        'wyzie-key',
      );

      final fresh = InMemorySecureKeyValueStore();
      SecureStore.storeOverride = fresh;
      await ProfileSecrets.import(exported);

      expect(fresh.values[SecretKeys.traktAccessToken], 'trakt-token');
      expect(fresh.values[SecretKeys.torboxApiKey], 'torbox-key');
      expect(
        fresh.values[ServiceCredentials.storageKeyFor(ServiceCredential.wyzie)],
        'wyzie-key',
      );
    },
  );

  test('ignores unknown keys and non-secret names', () async {
    await ProfileSecrets.import(<String, dynamic>{
      'not_a_secret': 'value',
      SecretKeys.tmdbApiKey: 'tmdb-key',
      'service_key_unknown': 'ignored',
    });

    expect(store.values['not_a_secret'], isNull);
    expect(store.values[SecretKeys.tmdbApiKey], 'tmdb-key');
    expect(store.values['service_key_unknown'], isNull);
  });
}
