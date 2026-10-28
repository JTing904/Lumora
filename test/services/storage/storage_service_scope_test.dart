import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zplay/services/account/account_service.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = InMemorySecureKeyValueStore();
    SecureStore.storeOverride = store;
  });

  tearDown(() {
    SecureStore.resetForTesting();
    AccountService.session.value = null;
  });

  test('a pairing belongs to the account that made it', () async {
    AccountService.session.value = _session('a');
    await StorageService.setTraktAccessToken('trakt-a');
    await StorageService.setSimklAccessToken('simkl-a');
    expect(await StorageService.getTraktAccessToken(), 'trakt-a');

    AccountService.session.value = _session('b');
    expect(await StorageService.getTraktAccessToken(), isNull);
    expect(await StorageService.getSimklAccessToken(), isNull);

    AccountService.session.value = _session('a');
    expect(await StorageService.getSimklAccessToken(), 'simkl-a');
  });

  test('a pairing from before the split is adopted once', () async {
    SharedPreferences.setMockInitialValues({
      'trakt_token_expiry_ms': 123,
      'trakt_username': 'me',
    });
    store.values[SecretKeys.traktAccessToken] = 'old';
    await StorageService.adoptUnscopedPairing('a');

    expect(store.values.containsKey(SecretKeys.traktAccessToken), isFalse);
    AccountService.session.value = _session('a');
    expect(await StorageService.getTraktAccessToken(), 'old');
    expect(await StorageService.getTraktTokenExpiry(), 123);
    expect(await StorageService.getTraktUsername(), 'me');
  });
}
