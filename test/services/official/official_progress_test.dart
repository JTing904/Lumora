import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/continue_watching/continue_watching_item.dart';
import 'package:zplay/services/official/official_progress.dart';

void main() {
  late DateTime now;
  late List<(int, int)> saves;
  OfficialProgressTracker tracker({bool enabled = true}) =>
      OfficialProgressTracker(
        enabled: enabled,
        clock: () => now,
        onSave: (p, d) => saves.add((p, d)),
      );

  setUp(() {
    now = DateTime(2026, 10, 28, 20);
    saves = [];
  });

  group('saving', () {
    test('every 15 s while playing, not on every report', () {
      final t = tracker();
      t.sample(position: 30, duration: 1285, state: YtState.playing);
      expect(saves, [(30, 1285)]);
      for (var i = 1; i <= 9; i++) {
        now = now.add(const Duration(milliseconds: 1500));
        t.sample(position: 30 + i * 1.5, state: YtState.playing);
      }
      expect(saves, hasLength(1));
      now = now.add(const Duration(seconds: 2));
      t.sample(position: 46, state: YtState.playing);
      expect(saves.last, (46, 1285));
    });

    test('on pause, once', () {
      final t = tracker();
      t.sample(position: 100, duration: 1285, state: YtState.playing);
      saves.clear();
      t.sample(position: 112.4, state: YtState.paused);
      t.sample(position: 112.4, state: YtState.paused);
      expect(saves, [(112, 1285)]);
    });

    test('on close, where the viewer stopped', () {
      final t = tracker();
      t.sample(position: 100, duration: 1285, state: YtState.playing);
      now = now.add(const Duration(seconds: 5));
      t.sample(position: 105, state: YtState.playing);
      t.close();
      expect(saves.last, (105, 1285));
    });

    test('nothing before 5 s or before the duration is known', () {
      final t = tracker();
      t.sample(position: 3, duration: 1285, state: YtState.playing);
      t.close();
      final u = tracker();
      u.sample(position: 40, state: YtState.paused);
      u.close();
      expect(saves, isEmpty);
    });
  });

  group('watched', () {
    test('the end saves position = duration, which marks it watched', () {
      final t = tracker();
      t.sample(position: 600, duration: 1285, state: YtState.playing);
      t.sample(position: 1284.7, state: YtState.ended);
      expect(saves.last, (1285, 1285));
      expect(t.finished, isTrue);
      // Closing after the end does not write an earlier position over it.
      t.close();
      expect(saves.last, (1285, 1285));
    });

    test('90% is finished, 89% is not', () {
      expect(OfficialProgressTracker.isFinishedAt(1157, 1285), isTrue);
      expect(OfficialProgressTracker.isFinishedAt(1143, 1285), isFalse);
      final t = tracker();
      t.sample(position: 1160, duration: 1285, state: YtState.playing);
      expect(t.finished, isTrue);
    });
  });

  test('a compilation (disabled tracker) records nothing at all', () {
    final t = tracker(enabled: false);
    t.sample(position: 600, duration: 6540, state: YtState.playing);
    t.sample(position: 700, state: YtState.paused);
    t.sample(position: 6540, state: YtState.ended);
    t.close();
    expect(saves, isEmpty);
    expect(t.finished, isFalse);
  });

  group('resume', () {
    ContinueWatchingItem item({
      String id = 'tt100',
      int season = 1,
      int episode = 196,
      int position = 600,
      int duration = 1285,
      String addon = 'YouTube 官方',
      String title = '《凡人修仙传》第196话：慕兰之战20',
    }) => ContinueWatchingItem(
      id: id,
      title: '凡人修仙传',
      type: 'series',
      season: season,
      episode: episode,
      positionSeconds: position,
      totalDurationSeconds: duration,
      lastWatchedAt: DateTime(2026, 10, 28),
      addonName: addon,
      isTorrent: false,
      streamTitle: title,
    );

    const names = {'YouTube 官方', 'Official on YouTube'};
    ContinueWatchingItem? find(List<ContinueWatchingItem> items) =>
        OfficialProgressTracker.savedFor(
          items,
          showId: 'tt100',
          season: 1,
          episode: 196,
          streamTitle: '《凡人修仙传》第196话：慕兰之战20',
          officialAddonNames: names,
        );

    test('the same episode on the same upload, in either language', () {
      expect(find([item()]), isNotNull);
      expect(find([item(addon: 'Official on YouTube')]), isNotNull);
    });

    test('another episode, another show, another source or upload: no', () {
      expect(find([item(episode: 195)]), isNull);
      expect(find([item(id: 'tt200')]), isNull);
      expect(find([item(addon: 'Torrentio')]), isNull);
      expect(find([item(title: '【重置版】《凡人修仙传》第196话')]), isNull);
    });

    test('starts at the saved position, unless finished or barely begun', () {
      expect(OfficialProgressTracker.resumeSeconds(saved: item()), 600);
      expect(
        OfficialProgressTracker.resumeSeconds(saved: item(position: 1200)),
        isNull,
      );
      expect(
        OfficialProgressTracker.resumeSeconds(saved: item(position: 3)),
        isNull,
      );
      expect(OfficialProgressTracker.resumeSeconds(), isNull);
    });

    test('a resume the caller chose wins over the saved one', () {
      expect(
        OfficialProgressTracker.resumeSeconds(
          explicit: const Duration(seconds: 321),
          saved: item(),
        ),
        321,
      );
    });
  });
}
