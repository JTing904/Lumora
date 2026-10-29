import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/movie/video.dart';
import 'package:zplay/services/metadata/episode_art.dart';

Video _v(int s, int e, String date, {String? title, String? thumb}) => Video(
  id: 'tt1:$s:$e',
  title: title ?? 'Episode $e',
  season: s,
  episode: e,
  released: '${date}T11:00:00.000Z',
  thumbnail: thumb ?? 'https://episodes.metahub.space/tt1/$s/$e/w780.jpg',
);

TmdbEpisode _t(int e, String date, String name) => TmdbEpisode(
  season: 1,
  episode: e,
  airDate: DateTime.parse(date),
  still: 'https://image.tmdb.org/t/p/w300/$e.jpg',
  name: name,
  overview: '$name 简介',
);

void main() {
  // The 凡人修仙传 shape: the addon splits into seasons and files two
  // episodes as specials; TMDb has one long season including them.
  final tmdb = [
    _t(1, '2020-07-25', '风起天南1'),
    _t(2, '2020-08-01', '风起天南2'),
    _t(3, '2021-01-31', '燕家堡之战1'),
    _t(4, '2021-02-07', '燕家堡之战2'),
    _t(5, '2021-11-14', '魔道争锋1'),
    _t(6, '2021-11-14', '魔道争锋2'),
    _t(7, '2021-11-21', '魔道争锋3'),
  ];
  final addon = [
    _v(0, 1, '2021-01-31'),
    _v(1, 1, '2020-07-25', title: 'Ordinary man'),
    _v(1, 2, '2020-08-01'),
    _v(2, 1, '2021-11-14'),
    _v(2, 2, '2021-11-14'),
    _v(2, 3, '2021-11-21'),
  ];

  test('a later season is anchored by air date, not by running number', () {
    final m = EpisodeArt.align(addon, tmdb);
    String? name(int s, int e) =>
        m[addon.firstWhere((v) => v.season == s && v.episode == e)]?.name;
    expect(name(1, 1), '风起天南1');
    expect(name(1, 2), '风起天南2');
    expect(name(2, 1), '魔道争锋1', reason: 'not 燕家堡之战1 at running no. 3');
    expect(name(2, 3), '魔道争锋3');
    expect(name(0, 1), isNull, reason: 'TMDb has no season 0 here');
  });

  test('stills replace the addon image; placeholders get the real name', () {
    final out = EpisodeArt.apply(addon, tmdb, preferTmdbText: false);
    final s2e1 = out.firstWhere((v) => v.season == 2 && v.episode == 1);
    expect(s2e1.thumbnail, 'https://image.tmdb.org/t/p/w300/5.jpg');
    expect(s2e1.title, '魔道争锋1');
    expect(s2e1.id, 'tt1:2:1', reason: 'the id the scrapers use is kept');
    final s1e1 = out.firstWhere((v) => v.season == 1 && v.episode == 1);
    expect(s1e1.title, 'Ordinary man', reason: 'a real name is kept in en');
  });

  test('a Chinese viewer gets TMDb names over the English ones', () {
    final out = EpisodeArt.apply(addon, tmdb, preferTmdbText: true);
    final s1e1 = out.firstWhere((v) => v.season == 1 && v.episode == 1);
    expect(s1e1.title, '风起天南1');
    expect(s1e1.overview, '风起天南1 简介');
  });

  test('a season with no dates is left alone unless the numbers agree', () {
    final undated = [
      Video(id: 'tt1:3:1', title: 'Episode 1', season: 3, episode: 1),
    ];
    expect(
      identical(EpisodeArt.apply(undated, tmdb, preferTmdbText: true), undated),
      isTrue,
    );
  });

  test(
    'the running number counts the episodes the addon filed as specials',
    () {
      // Summing the addon's seasons says S2E1 is the 3rd episode; on TMDb it
      // is the 5th, after the two 燕家堡之战 specials.
      expect(EpisodeArt.runningNumberIn(addon, tmdb, season: 2, episode: 1), 5);
      expect(EpisodeArt.runningNumberIn(addon, tmdb, season: 2, episode: 3), 7);
      expect(EpisodeArt.runningNumberIn(addon, tmdb, season: 1, episode: 2), 2);
      expect(
        EpisodeArt.runningNumberIn(addon, tmdb, season: 9, episode: 1),
        isNull,
      );
    },
  );

  test(
    'a show TMDb counts straight through shows that number on the cards',
    () {
      final out = EpisodeArt.apply(addon, tmdb, preferTmdbText: true);
      Video of(int s, int e) =>
          out.firstWhere((v) => v.season == s && v.episode == e);
      expect(of(2, 1).displayNumber, 5);
      expect(of(2, 1).shownNumber, 5);
      expect(of(2, 1).episode, 1, reason: 'sources still get the addon number');
      expect(of(1, 2).displayNumber, isNull, reason: 'same number either way');
    },
  );

  test('a show TMDb splits into seasons keeps the addon numbers', () {
    final split = [
      for (final t in tmdb)
        TmdbEpisode(
          season: t.episode > 4 ? 2 : 1,
          episode: t.episode > 4 ? t.episode - 4 : t.episode,
          airDate: t.airDate,
          still: t.still,
          name: t.name,
        ),
    ];
    final out = EpisodeArt.apply(addon, split, preferTmdbText: true);
    expect(out.every((v) => v.displayNumber == null), isTrue);
  });

  test('placeholder names', () {
    for (final n in [
      'Episode 4',
      'episode 12',
      'EP04',
      'E5',
      '第 4 集',
      '第4话',
      '',
    ]) {
      expect(EpisodeArt.isPlaceholderName(n), isTrue, reason: n);
    }
    for (final n in ['Ordinary man', '风起天南1：七玄门', 'Episode 4: The Return']) {
      expect(EpisodeArt.isPlaceholderName(n), isFalse, reason: n);
    }
  });
}
