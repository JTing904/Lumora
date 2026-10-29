import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/movie/video.dart';
import 'package:zplay/pages/details/episode_number_grid.dart';

Video _ep(int n, String? released) => Video(
  id: 'e$n',
  title: 'Episode $n',
  season: 1,
  episode: n,
  released: released,
);

void main() {
  final now = DateTime(2026, 10, 28, 15);

  test('an episode dated today or earlier is out', () {
    expect(episodeIsOut(_ep(1, '2026-10-21'), now: now), isTrue);
    expect(episodeIsOut(_ep(2, '2026-10-28T00:00:00.000Z'), now: now), isTrue);
  });

  test('an episode dated after today is not out yet', () {
    expect(episodeIsOut(_ep(3, '2026-11-04'), now: now), isFalse);
    expect(episodeAirDay(_ep(3, '2026-11-04')), DateTime(2026, 11, 4));
  });

  test('no date counts as out, so nothing playable is hidden', () {
    expect(episodeIsOut(_ep(4, null), now: now), isTrue);
    expect(episodeIsOut(_ep(5, ''), now: now), isTrue);
  });
}
