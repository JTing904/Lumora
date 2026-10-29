import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/movie/video.dart';
import 'package:zplay/pages/details/episode_number_grid.dart';

void main() {
  testWidgets('a phone-wide grid fills its row', (tester) async {
    final eps = [
      for (var i = 1; i <= 24; i++)
        Video(id: 'e$i', title: 'Episode $i', season: 8, episode: i),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 379,
              child: EpisodeNumberGrid(episodes: eps, onTap: (_) {}),
            ),
          ),
        ),
      ),
    );
    final first = tester.getTopLeft(find.text('1'));
    final row = [
      for (var i = 1; i <= 24; i++)
        if ((tester.getTopLeft(find.text('$i')).dy - first.dy).abs() < 4) i,
    ];
    expect(row.length, greaterThanOrEqualTo(5));
  });
}
