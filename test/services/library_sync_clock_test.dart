import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/my_list/my_list_item.dart';
import 'package:zplay/services/account/library_sync.dart';
import 'package:zplay/services/account/server_clock.dart';

void main() {
  tearDown(() => LibrarySync.clockOffsetForTesting = Duration.zero);

  test('a title added again after another device removed it stays, even on '
      'a device whose clock runs slow', () {
    // This device's clock is ten minutes behind the server's.
    LibrarySync.clockOffsetForTesting = const Duration(minutes: 10);
    // Removed on another device a minute ago, by the server's clock.
    final removedAt = LibrarySync.now().subtract(const Duration(minutes: 1));

    final item = MyListItem.fromMovie(id: 'tt1', name: 'Again', type: 'movie');
    final merged = LibrarySync.mergeForTesting(
      'my_list',
      [item.toJson()],
      const [],
      {item.uniqueKey: removedAt.toIso8601String()},
    );

    expect((merged as List).single['imdbId'], 'tt1');
  });

  test('entries and removals read the same clock', () {
    LibrarySync.clockOffsetForTesting = const Duration(minutes: -7);
    final entry = ServerClock.now();
    final removal = LibrarySync.now();
    expect(removal.difference(entry).inSeconds.abs(), lessThan(2));
  });
}
