import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/services/account/library_sync.dart';
import 'package:zplay/services/continue_watching/watched_episodes.dart';
import 'package:zplay/services/player/intro_outro_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('marks become an intro and a credits segment', () {
    const marks = IntroOutro(
      introEnd: Duration(seconds: 90),
      outroLength: Duration(minutes: 2),
    );
    final segs = marks.segments(const Duration(minutes: 45));
    expect(segs.map((s) => s.type), ['intro', 'credits']);
    expect(segs.first.endMs, 90000);
    expect(segs.last.startMs, const Duration(minutes: 43).inMilliseconds);
    // No duration yet: the closing cannot be placed.
    expect(marks.segments(Duration.zero).map((s) => s.type), ['intro']);
  });

  test('marks are kept per show', () async {
    await IntroOutroStore.save(
      'tt1',
      const IntroOutro(introEnd: Duration(seconds: 75)),
    );
    expect((await IntroOutroStore.forShow('tt1')).introEnd?.inSeconds, 75);
    expect((await IntroOutroStore.forShow('tt2')).isEmpty, isTrue);
  });

  test('the last finished episode is remembered', () async {
    await WatchedEpisodes.markFinished('tt1', 1, 3);
    await WatchedEpisodes.markFinished('tt1', 1, 2);
    await WatchedEpisodes.markFinished('tt1', 1, 4);
    expect(WatchedEpisodes.lastFinished('tt1'), (1, 4));
    expect(WatchedEpisodes.isWatched('tt1', 1, 2), isTrue);
    expect(WatchedEpisodes.isWatched('tt1', 1, 5), isFalse);
    expect(WatchedEpisodes.lastFinished('tt9'), isNull);
  });

  test('next up follows the furthest episode, not the list order', () async {
    // Another device's copy merged after this one's, as the sync leaves it.
    final merged = LibrarySync.mergeForTesting(
      'watched_episodes',
      {
        'tt1': ['2:1', '2:2'],
      },
      {
        'tt1': ['1:1', '1:2', '1:3'],
      },
      const {},
    );
    await WatchedEpisodes.importDocument(merged);
    expect(WatchedEpisodes.shows.value['tt1']!.last, '1:3');
    expect(WatchedEpisodes.lastFinished('tt1'), (2, 2));

    // An old episode watched again.
    await WatchedEpisodes.markFinished('tt1', 1, 1);
    expect(WatchedEpisodes.lastFinished('tt1'), (2, 2));
  });
}
