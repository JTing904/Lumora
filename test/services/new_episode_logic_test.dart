/// 有新集: when a saved series counts as having a new episode.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/my_list/new_episode_logic.dart';

void main() {
  final now = DateTime(2026, 10, 28, 20);
  final added = DateTime(2026, 10, 1, 9);

  EpisodeRef aired(int s, int e, DateTime day) =>
      EpisodeRef(s, e, airDate: day);

  group('hasNewEpisode', () {
    test('nothing aired is never new', () {
      expect(
        hasNewEpisode(
          latestAired: null,
          lastSeen: null,
          addedAt: added,
          now: now,
        ),
        isFalse,
      );
    });

    test('newer than the last episode seen is new', () {
      expect(
        hasNewEpisode(
          latestAired: aired(2, 5, DateTime(2026, 10, 27)),
          lastSeen: const EpisodeRef(2, 4),
          addedAt: added,
          now: now,
        ),
        isTrue,
      );
    });

    test('a later season beats a higher episode number', () {
      expect(
        hasNewEpisode(
          latestAired: aired(3, 1, DateTime(2026, 10, 27)),
          lastSeen: const EpisodeRef(2, 10),
          addedAt: added,
          now: now,
        ),
        isTrue,
      );
    });

    test('caught up (or ahead) is not new', () {
      for (final seen in const [EpisodeRef(2, 5), EpisodeRef(2, 6)]) {
        expect(
          hasNewEpisode(
            latestAired: aired(2, 5, DateTime(2026, 10, 27)),
            lastSeen: seen,
            addedAt: added,
            now: now,
          ),
          isFalse,
        );
      }
    });

    test('never watched: new only when it aired after being saved', () {
      expect(
        hasNewEpisode(
          latestAired: aired(1, 3, DateTime(2026, 10, 20)),
          lastSeen: null,
          addedAt: added,
          now: now,
        ),
        isTrue,
      );
      expect(
        hasNewEpisode(
          latestAired: aired(1, 3, DateTime(2026, 9, 20)),
          lastSeen: null,
          addedAt: added,
          now: now,
        ),
        isFalse,
      );
      // Saved the same day it aired: already there when saved.
      expect(
        hasNewEpisode(
          latestAired: aired(1, 3, DateTime(2026, 10, 1)),
          lastSeen: null,
          addedAt: added,
          now: now,
        ),
        isFalse,
      );
    });

    test('never watched and no air date is not new', () {
      expect(
        hasNewEpisode(
          latestAired: const EpisodeRef(1, 3),
          lastSeen: null,
          addedAt: added,
          now: now,
        ),
        isFalse,
      );
    });

    test('an air date still ahead is not new yet', () {
      expect(
        hasNewEpisode(
          latestAired: aired(2, 6, DateTime(2026, 10, 30)),
          lastSeen: const EpisodeRef(2, 5),
          addedAt: added,
          now: now,
        ),
        isFalse,
      );
    });

    test('catching up on an old show does not light it up', () {
      // Watched S1E1 of a show that ended years before it was saved.
      expect(
        hasNewEpisode(
          latestAired: aired(5, 16, DateTime(2013, 9, 29)),
          lastSeen: const EpisodeRef(1, 1),
          addedAt: added,
          now: now,
        ),
        isFalse,
      );
      // Aired the day it was saved: already there, watched or not.
      expect(
        hasNewEpisode(
          latestAired: aired(2, 5, DateTime(2026, 10, 1)),
          lastSeen: const EpisodeRef(2, 4),
          addedAt: added,
          now: now,
        ),
        isFalse,
      );
      // Watched and no air date: cannot tell it is new.
      expect(
        hasNewEpisode(
          latestAired: const EpisodeRef(2, 5),
          lastSeen: const EpisodeRef(2, 4),
          addedAt: added,
          now: now,
        ),
        isFalse,
      );
    });

    test('airing today counts from the next local day', () {
      final today = aired(2, 6, DateTime(2026, 10, 28));
      expect(
        hasNewEpisode(
          latestAired: today,
          lastSeen: const EpisodeRef(2, 5),
          addedAt: added,
          now: now,
        ),
        isFalse,
      );
      expect(
        hasNewEpisode(
          latestAired: today,
          lastSeen: const EpisodeRef(2, 5),
          addedAt: added,
          now: DateTime(2026, 10, 29, 0, 5),
        ),
        isTrue,
      );
    });

    test('specials never count', () {
      expect(
        hasNewEpisode(
          latestAired: aired(0, 2, DateTime(2026, 10, 27)),
          lastSeen: const EpisodeRef(0, 1),
          addedAt: added,
          now: now,
        ),
        isFalse,
      );
    });
  });

  test('latestAiredOf counts a cached next episode whose day has come', () {
    final last = aired(2, 4, DateTime(2026, 10, 21));
    final nextToday = aired(2, 5, DateTime(2026, 10, 28));
    final nextPast = aired(2, 5, DateTime(2026, 10, 27));
    final nextAhead = aired(2, 5, DateTime(2026, 11, 4));
    expect(latestAiredOf(last, nextPast, now: now), nextPast);
    expect(latestAiredOf(last, nextToday, now: now), nextToday);
    expect(latestAiredOf(last, nextAhead, now: now), last);
    expect(latestAiredOf(null, nextPast, now: now), nextPast);
    expect(latestAiredOf(last, const EpisodeRef(2, 5), now: now), last);
    expect(latestAiredOf(last, null, now: now), last);
    // A stale next that airs today is not new until tomorrow.
    expect(
      hasNewEpisode(
        latestAired: latestAiredOf(last, nextToday, now: now),
        lastSeen: const EpisodeRef(2, 4),
        addedAt: added,
        now: now,
      ),
      isFalse,
    );
    expect(
      hasNewEpisode(
        latestAired: latestAiredOf(last, nextPast, now: now),
        lastSeen: const EpisodeRef(2, 4),
        addedAt: added,
        now: now,
      ),
      isTrue,
    );
  });

  test('furthestEpisode picks the latest, not the last listed', () {
    expect(
      furthestEpisode([
        const EpisodeRef(3, 2),
        null,
        const EpisodeRef(1, 1),
        const EpisodeRef(2, 9),
      ]),
      const EpisodeRef(3, 2),
    );
    expect(furthestEpisode(const []), isNull);
  });

  test('EpisodeRef reads TMDb episode objects', () {
    final e = EpisodeRef.fromTmdb({
      'season_number': 2,
      'episode_number': 5,
      'air_date': '2026-10-27',
      'name': 'Pilot',
    })!;
    expect(e, const EpisodeRef(2, 5));
    expect(e.airDate, DateTime(2026, 10, 27));
    expect(e.name, 'Pilot');
    expect(EpisodeRef.fromTmdb({'season_number': 1}), isNull);
    expect(EpisodeRef.fromTmdb(null), isNull);
    expect(EpisodeRef.fromTmdb(e.toJson()), e);
    expect(parseEpisodeKey('3:7'), const EpisodeRef(3, 7));
    expect(parseEpisodeKey('bad'), isNull);
  });
}
