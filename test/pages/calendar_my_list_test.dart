/// 追剧日历 follows My List only, and 有新集 marks a saved series whose
/// latest episode is newer than what was watched.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/my_list/my_list_item.dart';
import 'package:zplay/pages/calendar/tv_calendar_page.dart';
import 'package:zplay/pages/my_list/my_list_page.dart';
import 'package:zplay/services/my_list/my_list_service.dart';
import 'package:zplay/services/my_list/new_episode_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    NewEpisodeService.resetForTesting();
    MyListService.items.value = [];
  });
  tearDown(NewEpisodeService.resetForTesting);

  DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  testWidgets('calendar explains itself when My List has no series', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TvCalendarPage()));
    await tester.pump();
    expect(
      find.text('Add series to My List to see their new episodes here'),
      findsOneWidget,
    );
  });

  testWidgets('calendar lists a saved series airing today', (tester) async {
    MyListService.items.value = [
      MyListItem(
        tmdbId: 42,
        title: 'Saved Show',
        type: 'series',
        addedAt: DateTime(2020),
      ),
    ];
    NewEpisodeService.seedForTesting(
      42,
      next: EpisodeRef(1, 3, airDate: today()),
      upcoming: [EpisodeRef(1, 3, airDate: today(), name: 'Third')],
    );
    await tester.pumpWidget(const MaterialApp(home: TvCalendarPage()));
    await tester.pump();
    expect(find.text('Saved Show'), findsOneWidget);
    expect(find.text('S01E03'), findsOneWidget);
  });

  testWidgets('calendar day chips fit a 360 dp phone at 1.3x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    MyListService.items.value = [
      MyListItem(
        tmdbId: 42,
        title: 'Saved Show',
        type: 'series',
        addedAt: DateTime(2020),
      ),
    ];
    NewEpisodeService.seedForTesting(
      42,
      next: EpisodeRef(1, 3, airDate: today()),
      upcoming: [EpisodeRef(1, 3, airDate: today(), name: 'Third')],
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const TvCalendarPage(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
    expect(find.text('Saved Show'), findsOneWidget);
  });

  testWidgets('My List marks a series with a new episode', (tester) async {
    MyListService.items.value = [
      MyListItem(
        tmdbId: 7,
        title: 'Fresh Show',
        type: 'series',
        addedAt: DateTime(2020),
      ),
    ];
    NewEpisodeService.seedForTesting(
      7,
      latest: EpisodeRef(
        2,
        5,
        airDate: today().subtract(const Duration(days: 1)),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: MyListPage()));
    await tester.pump();
    expect(find.text('New'), findsOneWidget);
    expect(find.textContaining('S2 E5'), findsOneWidget);
  });
}
