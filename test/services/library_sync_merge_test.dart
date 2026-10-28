import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/my_list/my_list_item.dart';
import 'package:zplay/services/account/library_sync.dart';

Map<String, dynamic> _item(String id, String added) => {
  'id': id,
  'imdbId': id,
  'type': 'movie',
  'title': id,
  'addedAt': added,
};

List<String> _ids(Object? merged) => [
  for (final m in merged as List) (m as Map)['id'] as String,
];

void main() {
  const t1 = '2026-10-01T00:00:00.000Z';
  const t2 = '2026-10-02T00:00:00.000Z';
  const t3 = '2026-10-03T00:00:00.000Z';

  test('both devices keep what each added', () {
    final merged = LibrarySync.mergeForTesting(
      'my_list',
      [_item('tt1', t1)],
      [_item('tt2', t2)],
      {},
    );
    expect(_ids(merged)..sort(), ['tt1', 'tt2']);
  });

  test('a fresh, empty device loses nothing from the account', () {
    final merged = LibrarySync.mergeForTesting('my_list', const [], [
      _item('tt1', t1),
      _item('tt2', t2),
    ], {});
    expect(_ids(merged)..sort(), ['tt1', 'tt2']);
  });

  test('a removal sticks against an older copy, not a newer re-add', () {
    final gone = LibrarySync.mergeForTesting(
      'my_list',
      const [],
      [_item('tt1', t1)],
      {'imdb:tt1': t2},
    );
    expect(_ids(gone), isEmpty);

    final readded = LibrarySync.mergeForTesting(
      'my_list',
      [_item('tt1', t3)],
      const [],
      {'imdb:tt1': t2},
    );
    expect(_ids(readded), ['tt1']);
  });

  test('taste keeps, per title, the copy seen last', () {
    Map<String, dynamic> entry(String id, int ls, double p) => {
      'id': id,
      't': id,
      'p': p,
      'fs': 0,
      'ls': ls,
    };
    final merged =
        LibrarySync.mergeForTesting(
              'taste',
              [entry('tt1', 2000, 0.2), entry('tt2', 1000, 0.5)],
              [entry('tt1', 1000, 0.9), entry('tt2', 3000, 0.7)],
              {},
            )
            as List;
    final byId = {for (final m in merged) (m as Map)['id']: m};
    expect(byId['tt1']!['p'], 0.2);
    expect(byId['tt2']!['p'], 0.7);
    // Newest first.
    expect(_ids(merged), ['tt2', 'tt1']);
  });

  test('my list dates are written in UTC and old local ones still read', () {
    final item = MyListItem(
      title: 'x',
      type: 'movie',
      addedAt: DateTime(2026, 10, 1, 12),
    );
    final written = item.toJson()['addedAt'] as String;
    expect(written.endsWith('Z'), isTrue);
    expect(DateTime.parse(written).isAtSameMomentAs(item.addedAt), isTrue);
    final old = MyListItem.fromJson({
      'title': 'x',
      'type': 'movie',
      'addedAt': '2026-10-01T12:00:00.000',
    });
    expect(old.addedAt, DateTime(2026, 10, 1, 12));
  });

  test('tombstone writes in a row keep every removal', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now().toUtc().toIso8601String();
    await Future.wait([
      LibrarySync.addTombsForTesting('my_list', 'u1', {'imdb:tt1': now}),
      LibrarySync.addTombsForTesting('my_list', 'u1', {'imdb:tt2': now}),
    ]);
    final tombs = await LibrarySync.tombsForTesting('my_list', 'u1');
    expect(tombs.keys.toSet(), {'imdb:tt1', 'imdb:tt2'});
  });

  test('a removal reaches the same title kept under another id', () {
    // Device A had the show with both ids and removed it: every alias is
    // tombstoned. Device B only ever knew its TMDb id.
    final both = MyListItem(
      imdbId: 'tt1',
      tmdbId: 5,
      title: 'Show',
      type: 'series',
      addedAt: DateTime.parse(t1),
    );
    expect(both.aliasKeys, ['imdb:tt1', 'tmdb:series:5']);
    final tmdbOnly = {
      'tmdbId': 5,
      'type': 'series',
      'title': 'Show',
      'addedAt': t1,
    };
    final gone = LibrarySync.mergeForTesting(
      'my_list',
      const [],
      [tmdbOnly],
      {for (final k in both.aliasKeys) k: t2},
    );
    expect(gone as List, isEmpty);

    // The other way round: removed where only the TMDb id was known, the copy
    // that also has an IMDb id (keyed imdb:tt1) goes too.
    final gone2 = LibrarySync.mergeForTesting(
      'my_list',
      [both.toJson()],
      const [],
      {'tmdb:series:5': t2},
    );
    expect(gone2 as List, isEmpty);

    // A re-add after the removal still wins.
    final readded = LibrarySync.mergeForTesting(
      'my_list',
      [both.copyWith(addedAt: DateTime.parse(t3)).toJson()],
      const [],
      {'tmdb:series:5': t2},
    );
    expect(readded as List, hasLength(1));
  });

  group('clock skew', () {
    final now = DateTime.utc(2026, 10, 10);
    String iso(DateTime d) => d.toUtc().toIso8601String();

    test('a future-dated removal does not delete a later real edit', () {
      // A device a month fast removed tt1: once merged, its tombstone is
      // stored as at most two minutes ahead of the server's time.
      final tombs = LibrarySync.mergeTombsForTesting(
        {'imdb:tt1': iso(now.add(const Duration(days: 30)))},
        {},
        now: now,
      );
      expect(tombs['imdb:tt1'], iso(now.add(const Duration(minutes: 2))));

      // Another device re-adds it ten minutes later: the re-add stands.
      final merged = LibrarySync.mergeForTesting(
        'my_list',
        [_item('tt1', iso(now.add(const Duration(minutes: 10))))],
        const [],
        tombs,
        now: now.add(const Duration(minutes: 11)),
      );
      expect(_ids(merged), ['tt1']);
    });

    test('a future-dated entry is pulled back so it can still be removed', () {
      final merged = LibrarySync.mergeForTesting(
        'my_list',
        [_item('tt1', iso(now.add(const Duration(days: 30))))],
        const [],
        {},
        now: now,
      );
      final added = DateTime.parse((merged as List).single['addedAt']);
      expect(added, now.add(const Duration(minutes: 2)));

      final gone = LibrarySync.mergeForTesting('my_list', merged, const [], {
        'imdb:tt1': iso(now.add(const Duration(minutes: 5))),
      }, now: now.add(const Duration(minutes: 5)));
      expect(_ids(gone), isEmpty);
    });

    test('times within the allowance are left alone', () {
      final soon = iso(now.add(const Duration(minutes: 1)));
      expect(
        LibrarySync.mergeTombsForTesting({'imdb:tt1': soon}, {}, now: now),
        {'imdb:tt1': soon},
      );
    });
  });

  test('watched episodes are the union of both copies', () {
    final merged =
        LibrarySync.mergeForTesting(
              'watched_episodes',
              {
                'tt9': ['1:1', '1:2'],
              },
              {
                'tt9': ['1:2', '1:3'],
                'tt8': ['2:1'],
              },
              {},
            )
            as Map;
    expect(merged['tt9'], ['1:1', '1:2', '1:3']);
    expect(merged['tt8'], ['2:1']);
  });
}
