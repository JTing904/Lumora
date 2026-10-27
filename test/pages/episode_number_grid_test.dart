import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/movie/video.dart';
import 'package:zplay/pages/details/episode_number_grid.dart';

void main() {
  final eps = [
    for (var i = 1; i <= 45; i++)
      Video(id: 'tt1:1:$i', title: '', season: 1, episode: i),
  ];

  Future<void> pump(
    WidgetTester tester, {
    Video? current,
    ValueChanged<Video>? onTap,
  }) {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EpisodeNumberGrid(
              episodes: eps,
              current: current,
              onTap: onTap ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('thirty to a page, and the page with the current one opens', (
    tester,
  ) async {
    await pump(tester, current: eps[37]);
    expect(find.text('1-30'), findsOneWidget);
    expect(find.text('31-45'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    expect(find.text('5'), findsNothing);

    await tester.tap(find.text('1-30'));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('a number plays its episode', (tester) async {
    Video? played;
    await pump(tester, onTap: (v) => played = v);
    await tester.tap(find.text('12'));
    expect(played?.episode, 12);
  });
}
