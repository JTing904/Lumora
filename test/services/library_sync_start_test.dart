import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zplay/models/my_list/my_list_item.dart';
import 'package:zplay/services/account/account_service.dart';
import 'package:zplay/services/account/library_sync.dart';
import 'package:zplay/services/my_list/my_list_service.dart';

const String _a = '11111111-1111-4111-8111-111111111111';

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

/// An empty server that notes which accounts were read.
class _Remote implements LibraryRemote {
  final reads = <String>[];

  @override
  Future<Map<String, LibraryRow>> readAll(String uid) async {
    reads.add(uid);
    return {};
  }

  @override
  Future<LibraryRow?> read(String uid, String doc) async => null;

  @override
  Future<LibraryRow?> update(
    String uid,
    String doc,
    Object? data,
    String? seen,
  ) async => null;

  @override
  Future<LibraryRow?> insert(String uid, String doc, Object? data) async =>
      LibraryRow(data, DateTime.now().toUtc().toIso8601String());
}

String _list(String title) => jsonEncode([
  MyListItem(
    imdbId: 'tt1',
    title: title,
    type: 'movie',
    addedAt: DateTime.utc(2026),
  ).toJson(),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Remote remote;

  setUp(() {
    SharedPreferences.setMockInitialValues({'my_list_v1@$_a': _list('Mine')});
    remote = _Remote();
    LibrarySync.remoteForTesting = remote;
  });

  tearDown(() {
    LibrarySync.stopForTesting();
    LibrarySync.remoteForTesting = null;
    AccountService.session.value = null;
    MyListService.items.value = [];
  });

  test('a sign-out while the services loaded is caught up at start', () async {
    AccountService.session.value = _session(_a);
    await MyListService.reloadLocal();
    expect(MyListService.items.value.single.title, 'Mine');

    // The stored session's refresh is rejected before the sync listens.
    AccountService.session.value = null;
    LibrarySync.startForTesting(loadedFor: _a);
    await pumpEventQueue();

    expect(MyListService.items.value, isEmpty);
    expect(remote.reads, isEmpty);
  });

  test('an unchanged account just syncs', () async {
    AccountService.session.value = _session(_a);
    await MyListService.reloadLocal();

    LibrarySync.startForTesting(loadedFor: _a);
    await pumpEventQueue();

    expect(MyListService.items.value.single.title, 'Mine');
    expect(remote.reads, [_a]);
  });
}
