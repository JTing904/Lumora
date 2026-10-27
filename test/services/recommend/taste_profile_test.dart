import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/services/recommend/taste_profile.dart';
import 'package:zplay/services/recommend/taste_store.dart';

final _now = DateTime(2026, 10, 27);

const _donghua = TasteFacets(region: 'CN', animated: true, series: true, genres: [16]);
const _hkDrama = TasteFacets(region: 'HK', animated: false, series: true, genres: [18]);
const _usFilm = TasteFacets(region: 'US', animated: false, series: false, genres: [28]);

TasteEntry _entry(
  String id,
  TasteFacets facets, {
  double progress = 0,
  bool finished = false,
  bool listed = false,
  int rating = 0,
  int daysAgo = 1,
}) => TasteEntry(
  id: id,
  title: id,
  series: facets.series,
  progress: progress,
  finished: finished,
  listed: listed,
  rating: rating,
  firstSeen: _now.subtract(Duration(days: daysAgo)),
  lastSeen: _now.subtract(Duration(days: daysAgo)),
  facets: facets,
);

void main() {
  test('a viewer who finishes donghua gets 国漫 first', () {
    final profile = TasteProfile.build([
      _entry('tt1', _donghua, finished: true),
      _entry('tt2', _donghua, progress: 0.6),
      _entry('tt3', _usFilm, progress: 0.2),
    ], now: _now);
    expect(profile.kinds.first.key, 'CN|anim|tv');
    expect(tasteKindName(profile.kinds.first.key, zh: true), '国漫');
  });

  test('three viewers, three different first rows', () {
    final me = TasteProfile.build([_entry('a', _donghua, finished: true)], now: _now);
    final friendA = TasteProfile.build([_entry('b', _hkDrama, finished: true)], now: _now);
    final friendB = TasteProfile.build([_entry('c', _usFilm, finished: true)], now: _now);
    expect(tasteKindName(me.kinds.first.key, zh: true), '国漫');
    expect(tasteKindName(friendA.kinds.first.key, zh: true), '港剧');
    expect(tasteKindName(friendB.kinds.first.key, zh: true), '好莱坞电影');
  });

  test('a 👎 outweighs having watched some of it', () {
    final profile = TasteProfile.build([
      _entry('tt1', _hkDrama, progress: 0.6, rating: -1),
    ], now: _now);
    expect(profile.isEmpty, isTrue);
  });

  test('a title given up early, a week ago, counts against its kind', () {
    final e = _entry('tt1', _hkDrama, progress: 0.1, daysAgo: 10);
    expect(TasteProfile.weightOf(e, _now), lessThan(1));
  });

  test('old history counts for less than new', () {
    final profile = TasteProfile.build([
      _entry('old', _donghua, finished: true, daysAgo: 400),
      _entry('new', _hkDrama, progress: 0.6, daysAgo: 1),
    ], now: _now);
    expect(profile.kinds.first.key, 'HK|live|tv');
  });

  test('everything touched is excluded from recommendations', () {
    final profile = TasteProfile.build([
      _entry('tt1', _donghua, finished: true),
      _entry('tt2', _donghua, rating: -1),
    ], now: _now);
    expect(profile.seen, {'tt1', 'tt2'});
  });

  group('TasteStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TasteStore.resetForTesting();
    });

    test('keeps the furthest progress and marks 90% finished', () {
      TasteStore.recordProgress('tt9', title: 'X', series: true, progress: 0.5);
      TasteStore.recordProgress('tt9', title: 'X', series: true, progress: 0.2);
      expect(TasteStore.entries.value['tt9']!.progress, 0.5);
      TasteStore.recordProgress('tt9', title: 'X', series: true, progress: 0.95);
      expect(TasteStore.entries.value['tt9']!.finished, isTrue);
    });

    test('round-trips through JSON', () {
      final e = _entry('tt5', _hkDrama, listed: true, rating: 1);
      final back = TasteEntry.fromJson(e.toJson())!;
      expect(back.facets!.key, 'HK|live|tv');
      expect(back.rating, 1);
      expect(back.listed, isTrue);
    });
  });
}
