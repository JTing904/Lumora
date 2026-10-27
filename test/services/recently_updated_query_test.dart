import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/metadata/tmdb_catalog.dart';

void main() {
  final now = DateTime(2026, 10, 27);

  test('series: an episode out in the last week', () {
    final q = TmdbQuery.recentlyUpdated(series: true, animated: false, now: now);
    expect(q.path, '/discover/tv');
    expect(q.params['air_date.gte'], '2026-10-20');
    expect(q.params['air_date.lte'], '2026-10-27');
    expect(q.params['without_genres'], '16,10767,10763');
  });

  test('films: out online or on disc in the last three months', () {
    final q = TmdbQuery.recentlyUpdated(series: false, now: now);
    expect(q.path, '/discover/movie');
    expect(q.params['release_date.gte'], '2026-07-29');
    expect(q.params['release_date.lte'], '2026-10-27');
    expect(q.params['with_release_type'], '4|5');
  });
}
