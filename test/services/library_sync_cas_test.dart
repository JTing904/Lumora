import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zplay/models/my_list/my_list_item.dart';
import 'package:zplay/services/account/account_service.dart';
import 'package:zplay/services/account/library_sync.dart';
import 'package:zplay/services/my_list/my_list_service.dart';

/// The `user_documents` table of one account: `updated_at` is stamped on
/// every write, and a write that names a stale one finds no row.
class _FakeRemote implements LibraryRemote {
  _FakeRemote({this.serverAhead = Duration.zero});

  final Duration serverAhead;
  final rows = <String, LibraryRow>{};
  int conflicts = 0;
  int _tick = 0;

  /// Runs just before each write lands, as another device writing first.
  void Function()? beforeWrite;

  String _stamp() => DateTime.now()
      .toUtc()
      .add(serverAhead)
      .add(Duration(microseconds: ++_tick))
      .toIso8601String();

  /// Another device's write.
  void put(String doc, Object? data) =>
      rows[doc] = LibraryRow(jsonDecode(jsonEncode(data)), _stamp());

  @override
  Future<Map<String, LibraryRow>> readAll(String uid) async => {...rows};

  @override
  Future<LibraryRow?> read(String uid, String doc) async => rows[doc];

  @override
  Future<LibraryRow?> update(
    String uid,
    String doc,
    Object? data,
    String? seen,
  ) async {
    beforeWrite?.call();
    final row = rows[doc];
    if (row == null || row.updatedAt != seen) {
      conflicts++;
      return null;
    }
    put(doc, data);
    return rows[doc];
  }

  @override
  Future<LibraryRow?> insert(String uid, String doc, Object? data) async {
    beforeWrite?.call();
    if (rows.containsKey(doc)) {
      conflicts++;
      return null;
    }
    put(doc, data);
    return rows[doc];
  }
}

Map<String, dynamic> _entry(String id) => MyListItem(
  imdbId: id,
  title: id,
  type: 'movie',
  addedAt: DateTime.utc(2026, 10, 1),
).toJson();

List<String> _serverIds(_FakeRemote remote) => [
  for (final m in (remote.rows['my_list']!.data as Map)['items'] as List)
    (m as Map)['imdbId'] as String,
]..sort();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeRemote remote;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountService.session.value = Session(
      accessToken: 'test',
      tokenType: 'bearer',
      user: const User(
        id: 'u1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
      ),
    );
    MyListService.items.value = [MyListItem.fromJson(_entry('tt2'))];
    remote = _FakeRemote();
    LibrarySync.remoteForTesting = remote;
    LibrarySync.clockOffsetForTesting = Duration.zero;
  });

  tearDown(() {
    LibrarySync.remoteForTesting = null;
    LibrarySync.clockOffsetForTesting = Duration.zero;
    AccountService.session.value = null;
  });

  test(
    'a write that loses the race is merged again, not overwritten',
    () async {
      remote.put('my_list', {
        'items': [_entry('tt1')],
        'removed': <String, String>{},
      });
      // Between this device's read and its write, another device adds tt3.
      remote.beforeWrite = () {
        remote.beforeWrite = null;
        remote.put('my_list', {
          'items': [_entry('tt1'), _entry('tt3')],
          'removed': <String, String>{},
        });
      };
      await LibrarySync.syncForTesting('my_list', 'u1');
      expect(remote.conflicts, 1);
      expect(_serverIds(remote), ['tt1', 'tt2', 'tt3']);
      expect(MyListService.items.value.map((i) => i.imdbId).toSet(), {
        'tt1',
        'tt2',
        'tt3',
      });
    },
  );

  test('a row created meanwhile by another device is merged into', () async {
    remote.beforeWrite = () {
      remote.beforeWrite = null;
      remote.put('my_list', {
        'items': [_entry('tt3')],
        'removed': <String, String>{},
      });
    };
    await LibrarySync.syncForTesting('my_list', 'u1');
    expect(remote.conflicts, 1);
    expect(_serverIds(remote), ['tt2', 'tt3']);
  });

  test('a write that keeps losing gives up after a few rounds', () async {
    remote.put('my_list', {
      'items': [_entry('tt1')],
      'removed': <String, String>{},
    });
    remote.beforeWrite = () => remote.put('my_list', {
      'items': [_entry('tt1')],
      'removed': <String, String>{},
    });
    await LibrarySync.syncForTesting('my_list', 'u1');
    expect(remote.conflicts, 3);
    // Nothing is lost here: the merged copy waits for the next sync.
    expect(MyListService.items.value.map((i) => i.imdbId).toSet(), {
      'tt1',
      'tt2',
    });
  });

  test('the server clock offset is measured from a write', () async {
    remote = _FakeRemote(serverAhead: const Duration(hours: 1));
    LibrarySync.remoteForTesting = remote;
    await LibrarySync.syncForTesting('my_list', 'u1');
    final offset = LibrarySync.clockOffsetForTesting;
    expect(
      (offset - const Duration(hours: 1)).abs(),
      lessThan(const Duration(seconds: 5)),
    );
    final drift = LibrarySync.now().difference(
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    expect(drift.abs(), lessThan(const Duration(seconds: 5)));
  });
}
