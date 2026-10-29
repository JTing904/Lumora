import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/scraper/sites/maccms.dart';

void main() {
  test('matches language suffixes without matching other titles', () {
    final items = [
      {'vod_name': '璀璨之城粤语', 'vod_year': '2026', 'type_name': '香港剧'},
      {'vod_name': '璀璨人生', 'vod_year': '2026', 'type_name': '香港剧'},
    ];
    expect(
      MacCmsScraper.pick(items, '璀璨之城', series: true, year: 2026)?['vod_name'],
      '璀璨之城粤语',
    );
    expect(MacCmsScraper.pick(items, '璀璨之城', series: true, year: 2020), isNull);
  });
  test('keeps both language variants', () {
    final items = [
      {'vod_name': '璀璨之城国语', 'type_name': '香港剧'},
      {'vod_name': '璀璨之城粤语', 'type_name': '香港剧'},
    ];
    expect(MacCmsScraper.pickAll(items, '璀璨之城', series: true), hasLength(2));
  });
  test(
    'does not select a different episode from an incomplete numbered list',
    () {
      const list = r'第02集$https://a/2.m3u8#第03集$https://a/3.m3u8';
      expect(MacCmsScraper.playUrlFor(list, series: true, episode: 1), isNull);
      expect(
        MacCmsScraper.playUrlFor(list, series: true, episode: 2),
        'https://a/2.m3u8',
      );
      const season = r'第2季第03集$https://a/3.m3u8';
      expect(
        MacCmsScraper.playUrlFor(season, series: true, episode: 3),
        'https://a/3.m3u8',
      );
    },
  );
  test('accepts the movie category', () {
    expect(
      MacCmsScraper.pick(
        [
          {'vod_name': '测试', 'type_name': '电影'},
        ],
        '测试',
        series: false,
      ),
      isNotNull,
    );
  });
  test('anime filter rejects live action with the same title', () {
    final items = [
      {'vod_name': '仙逆', 'type_name': '国产剧'},
      {'vod_name': '仙逆', 'type_name': '国产动漫'},
    ];
    final matches = MacCmsScraper.pickAll(
      items,
      '仙逆',
      series: true,
      animationOnly: true,
    );
    expect(matches, hasLength(1));
    expect(matches.single['type_name'], '国产动漫');
  });
  group('seasonOf', () {
    test('reads 第二季, 第2季 and a trailing number', () {
      expect(MacCmsScraper.seasonOf('凡人修仙传 第二季'), 2);
      expect(MacCmsScraper.seasonOf('斗罗大陆第12季'), 12);
      expect(MacCmsScraper.seasonOf('斗罗大陆2'), 2);
      expect(MacCmsScraper.seasonOf('繁花'), isNull);
    });
  });

  group('pick', () {
    final list = [
      {'vod_name': '凡人修仙传', 'type_name': '国产动漫', 'vod_year': '2020'},
      {'vod_name': '凡人修仙传 第二季', 'type_name': '国产动漫', 'vod_year': '2023'},
      {'vod_name': '凡人修仙传', 'type_name': '国产剧', 'vod_year': '2025'},
      {'vod_name': '流浪地球2', 'type_name': '科幻片', 'vod_year': '2023'},
      {'vod_name': '凡人修仙传', 'type_name': '伦理片', 'vod_year': '2020'},
    ];

    test('the first season by name and year', () {
      final got = MacCmsScraper.pick(list, '凡人修仙传', series: true, year: 2020);
      expect(got?['type_name'], '国产动漫');
      expect(got?['vod_year'], '2020');
    });

    test('a later season by its suffix', () {
      final got = MacCmsScraper.pick(list, '凡人修仙传', series: true, season: 2);
      expect(got?['vod_name'], '凡人修仙传 第二季');
    });

    test('a film whose name ends in a number', () {
      final got = MacCmsScraper.pick(list, '流浪地球2', series: false, year: 2023);
      expect(got?['vod_name'], '流浪地球2');
    });

    test('an untagged listing is never a later season', () {
      final got = MacCmsScraper.pick(
        [list[0]],
        '凡人修仙传',
        series: true,
        season: 2,
      );
      expect(got, isNull);
    });

    test('an animated film is a film; a documentary can be a series', () {
      final films = [
        {'vod_name': '哪吒之魔童闹海', 'type_name': '动画片', 'vod_year': '2025'},
      ];
      expect(
        MacCmsScraper.pick(films, '哪吒之魔童闹海', series: false)?['type_name'],
        '动画片',
      );
      final docs = [
        {'vod_name': '航拍中国', 'type_name': '纪录片', 'vod_year': '2017'},
      ];
      expect(
        MacCmsScraper.pick(docs, '航拍中国', series: true)?['type_name'],
        '纪录片',
      );
    });

    test('a series is never a film listing, nor an adult category', () {
      final got = MacCmsScraper.pick(
        [list[3], list[4]],
        '凡人修仙传',
        series: false,
      );
      expect(got, isNull);
    });
  });

  group('playUrlFor', () {
    const url =
        r'第01集$https://a/1.mp4#第02集$https://a/2.mp4$$$'
        r'第01集$https://b/1/index.m3u8#第02集$https://b/2/index.m3u8';

    test('prefers the m3u8 group and finds the episode by number', () {
      expect(
        MacCmsScraper.playUrlFor(url, series: true, episode: 2),
        'https://b/2/index.m3u8',
      );
    });

    test('a film takes the first entry', () {
      expect(
        MacCmsScraper.playUrlFor(r'正片$https://c/index.m3u8', series: false),
        'https://c/index.m3u8',
      );
    });

    test('never a non-http entry', () {
      const mixed = r'第01集$file:///etc/passwd#第02集$HTTPS://a/2.m3u8';
      expect(MacCmsScraper.playUrlFor(mixed, series: true, episode: 1), isNull);
      expect(
        MacCmsScraper.playUrlFor(mixed, series: true, episode: 2),
        'HTTPS://a/2.m3u8',
      );
      expect(
        MacCmsScraper.playUrlFor(
          r'正片$ftp://x#备用$https://c/1.m3u8',
          series: false,
        ),
        'https://c/1.m3u8',
      );
    });

    test('an episode past the list is none', () {
      expect(MacCmsScraper.playUrlFor(url, series: true, episode: 9), isNull);
    });
  });
}
