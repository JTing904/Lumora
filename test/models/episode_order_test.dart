import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/movie/episode_order.dart';
import 'package:zplay/models/movie/video.dart';

Video _ep(int season, int episode) => Video(
  id: 'tt1:$season:$episode',
  title: '',
  season: season,
  episode: episode,
);

void main() {
  final order = episodeOrder([_ep(2, 1), _ep(0, 1), _ep(1, 2), _ep(1, 1)]);

  test('specials are left out and the rest run in order', () {
    expect(order.map((v) => '${v.season}:${v.episode}'), ['1:1', '1:2', '2:1']);
  });

  test('the next episode crosses into the next season', () {
    expect(episodeNeighbour(order, 1, 2, 1)?.season, 2);
    expect(episodeNeighbour(order, 2, 1, 1), isNull);
    expect(episodeNeighbour(order, 1, 1, -1), isNull);
    expect(episodeNeighbour(order, 2, 1, -1)?.episode, 2);
    expect(episodeNeighbour(order, 5, 5, 1), isNull);
  });
}
