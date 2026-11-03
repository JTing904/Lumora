import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zplay/models/book/reading_progress.dart';
import 'package:zplay/models/music/music_track.dart';
import 'package:zplay/services/account/account_scope.dart';
import 'package:zplay/services/account/account_service.dart';
import 'package:zplay/services/books/continue_reading_service.dart';
import 'package:zplay/services/debrid/providers/real_debrid_service.dart';
import 'package:zplay/services/music/music_library_service.dart';
import 'package:zplay/services/storage/secret_keys.dart';
import 'package:zplay/services/storage/secure_store.dart';

const String _a = '11111111-1111-4111-8111-111111111111';
const String _b = '22222222-2222-4222-8222-222222222222';

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

ReadingProgress _book(String md5) => ReadingProgress(
  md5: md5,
  title: 'Title $md5',
  author: 'Author',
  coverUrl: '',
  filePath: '/books/$md5.epub',
  fileType: 'epub',
  lastReadAt: DateTime.utc(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySecureKeyValueStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = InMemorySecureKeyValueStore();
    SecureStore.storeOverride = store;
    ContinueReadingService.activeItems.value = [];
  });

  tearDown(() {
    SecureStore.resetForTesting();
    AccountService.session.value = null;
  });

  test('an updated install moves its histories and debrid sign-in to the '
      'account signed in, once', () async {
    final liked = jsonEncode([
      {'id': 't1', 'title': 'Song'},
    ]);
    SharedPreferences.setMockInitialValues({
      'continue_reading_sessions_v1': '[]',
      'music_liked_tracks_v3': liked,
      'zplay_anime_history_v2': '[]',
      // Already split: the newer flags are what this version adds.
      'lumora_library_scoped_v1': true,
      'lumora_pairing_scoped_v1': true,
    });
    store.values[SecretKeys.realDebridToken] = 'rd-token';
    store.values[SecretKeys.tmdbApiKey] = 'app-key';

    AccountService.session.value = _session(_a);
    await AccountScope.adoptUnscopedLibrary();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('music_liked_tracks_v3@$_a'), liked);
    expect(prefs.containsKey('music_liked_tracks_v3'), isFalse);
    expect(prefs.containsKey('continue_reading_sessions_v1@$_a'), isTrue);
    expect(prefs.containsKey('zplay_anime_history_v2@$_a'), isTrue);
    expect(store.values['${SecretKeys.realDebridToken}@$_a'], 'rd-token');
    expect(store.values.containsKey(SecretKeys.realDebridToken), isFalse);
    // A key for the app itself stays with the device.
    expect(store.values[SecretKeys.tmdbApiKey], 'app-key');

    // A second account later finds nothing to adopt.
    await prefs.setString('music_liked_tracks_v3', '[]');
    AccountService.session.value = _session(_b);
    await AccountScope.adoptUnscopedLibrary();
    expect(prefs.containsKey('music_liked_tracks_v3@$_b'), isFalse);
  });

  test('a debrid subscription belongs to the account that added it', () async {
    final rd = RealDebridService();
    AccountService.session.value = _session(_a);
    await rd.saveToken('token-a');
    expect(await rd.getToken(), 'token-a');

    AccountService.session.value = _session(_b);
    expect(await rd.getToken(), isNull);

    AccountService.session.value = _session(_a);
    expect(await rd.getToken(), 'token-a');
  });

  test('reading and music history do not follow another account', () async {
    AccountService.session.value = _session(_a);
    await ContinueReadingService.saveProgress(_book('b1'));
    await MusicLibraryService.instance.reload();
    await MusicLibraryService.instance.toggleLikeTrack(
      MusicTrack.fromJson({'id': 't1', 'title': 'Song'}),
    );

    AccountService.session.value = _session(_b);
    await ContinueReadingService.reload();
    await MusicLibraryService.instance.reload();
    expect(ContinueReadingService.activeItems.value, isEmpty);
    expect(MusicLibraryService.instance.likedTracks, isEmpty);

    AccountService.session.value = _session(_a);
    await ContinueReadingService.reload();
    await MusicLibraryService.instance.reload();
    expect(ContinueReadingService.activeItems.value.single.md5, 'b1');
    expect(MusicLibraryService.instance.likedTracks.single.id, 't1');
  });
}
