import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/official/official_channels.dart';
import 'package:zplay/services/official/official_episode_matcher.dart';
import 'package:zplay/services/official/official_youtube_source.dart';

/// Recorded with InnerTube on 2026-10-28 (region MY), trimmed to the fields
/// the parser reads. See `test/fixtures/official_youtube/`.
List<OfficialUpload> _fixture(String name, {String? channel}) {
  final json =
      jsonDecode(
            File(
              'test/fixtures/official_youtube/$name.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  return OfficialYouTubeSource.parseResponse(json, fallbackChannelId: channel);
}

const _bilibili = 'UCQFyMGc6h30NMCd6HCk0ZPA';
const _tencentAnimation = 'UCdpiId0eJGnnIvfhpbJIM1w';

OfficialUpload _upload(
  String title, {
  String channel = _bilibili,
  Duration duration = const Duration(minutes: 20),
  String id = 'AAAAAAAAAAA',
  bool membersOnly = false,
}) => OfficialUpload(
  videoId: id,
  title: title,
  channelId: channel,
  duration: duration,
  membersOnly: membersOnly,
);

const _fanren = OfficialQuery(
  names: ['凡人修仙传', "A Mortal's Journey"],
  season: 1,
  episode: 196,
);

void main() {
  group('parseNumbers', () {
    test('第196话 / 第196集 / EP196 / Episode 196', () {
      expect(
        OfficialEpisodeMatcher.parseNumbers('《凡人修仙传》第196话：慕兰之战20').episodes,
        {196},
      );
      expect(OfficialEpisodeMatcher.parseNumbers('凡人修仙传 第196集').episodes, {
        196,
      });
      expect(
        OfficialEpisodeMatcher.parseNumbers(
          'A Mortal’s Journey EP196',
        ).episodes,
        {196},
      );
      expect(
        OfficialEpisodeMatcher.parseNumbers(
          'Frieren - Episode 03 [English Sub]',
        ).episodes,
        {3},
      );
    });

    test('Chinese numerals: 第十八集, 第五十九集, 第一百九十六集', () {
      expect(OfficialEpisodeMatcher.parseNumbers('《元尊》第十八集').episodes, {18});
      expect(OfficialEpisodeMatcher.parseNumbers('西行纪年番 第五十九集').episodes, {59});
      expect(OfficialEpisodeMatcher.parseNumbers('第一百九十六集').episodes, {196});
      expect(OfficialEpisodeMatcher.parseNumbers('凡人修仙传196集').episodes, {196});
      expect(OfficialEpisodeMatcher.parseNumbers('琅琊榜 全54集').episodes, isEmpty);
      expect(OfficialEpisodeMatcher.parseChineseNumber('两百零五'), 205);
      expect(OfficialEpisodeMatcher.parseChineseNumber('十'), 10);
    });

    test('full-width digits and S02E05', () {
      expect(OfficialEpisodeMatcher.parseNumbers('ＥＰ１９６').episodes, {196});
      final n = OfficialEpisodeMatcher.parseNumbers('Show S02E05');
      expect(n.episodes, {5});
      expect(n.season, 2);
    });

    test('ranges are ranges, not two episodes', () {
      final a = OfficialEpisodeMatcher.parseNumbers('《凡人修仙传》EP166 - 172合集');
      expect(a.ranges, [(166, 172)]);
      expect(a.episodes, isEmpty);
      final b = OfficialEpisodeMatcher.parseNumbers(
        '《元尊》EP01-EP26 Full Version',
      );
      expect(b.ranges, [(1, 26)]);
      expect(b.episodes, isEmpty);
      expect(OfficialEpisodeMatcher.parseNumbers('《凡人修仙传》第1-100话合集').ranges, [
        (1, 100),
      ]);
    });

    test('season markers', () {
      expect(
        OfficialEpisodeMatcher.parseNumbers('《斗破苍穹 第二季》S2 EP01').season,
        2,
      );
      expect(
        OfficialEpisodeMatcher.parseNumbers('Season 3 Episode 4').season,
        3,
      );
      expect(
        OfficialEpisodeMatcher.parseNumbers(
          '"A Mortal\'s Journey" S4 EP153–176',
        ).season,
        4,
      );
      expect(
        OfficialEpisodeMatcher.parseNumbers('《凡人修仙传》第196话').season,
        isNull,
      );
    });

    test('TVB "01/25" counts, a date does not', () {
      expect(
        OfficialEpisodeMatcher.parseNumbers('巨塔之后 01/25 | 粵語中字').episodes,
        {1},
      );
      expect(
        OfficialEpisodeMatcher.parseNumbers('2023/10/12 首播').episodes,
        isEmpty,
      );
    });
  });

  group('extras are rejected', () {
    for (final title in [
      '《凡人修仙传》第198话预告：慕兰之战第22集',
      '《凡人修仙传》第196话花絮：魏无涯首次现身！',
      '"A Mortal\'s Journey" EP170 Trailer',
      '"A Mortal\'s Journey" EP170 Clip: Rich Whale',
      '《凡人修仙传》慕兰之战倒计时，仲神师PV上线',
      '早春晴朗 EP01精华版',
      '宮心計｜第1集劇集精華',
      '凡人修仙传 EP196 #shorts',
      '凡人修仙传 EP196 Highlights',
    ]) {
      test(title, () {
        expect(OfficialEpisodeMatcher.isExtra(title), isTrue);
        expect(
          OfficialEpisodeMatcher.match(
            _upload(title, duration: const Duration(minutes: 25)),
            _fanren,
          ),
          isNull,
        );
      });
    }

    test('a real episode title is not an extra', () {
      expect(
        OfficialEpisodeMatcher.isExtra('《凡人修仙传》第196话：慕兰之战20【玄幻 | 热血 | 励志】'),
        isFalse,
      );
      expect(
        OfficialEpisodeMatcher.isExtra('ENG SUB《元尊》第十九集 | 本季最精彩个人战！'),
        isFalse,
      );
    });
  });

  group('match', () {
    test('the episode on a whitelisted channel', () {
      final m = OfficialEpisodeMatcher.match(
        _upload('《凡人修仙传》第196话：慕兰之战20【玄幻 | 热血 | 励志 | Made By Bilibili】'),
        _fanren,
      );
      expect(m?.kind, OfficialMatchKind.episode);
    });

    test('the English title matches the English name', () {
      final m = OfficialEpisodeMatcher.match(
        _upload('"A Mortal\'s Journey" EP196【Fantasy | Made By Bilibili】'),
        _fanren,
      );
      expect(m?.kind, OfficialMatchKind.episode);
    });

    test('the same title on a channel that is not whitelisted is rejected', () {
      for (final channel in [
        'UCfsD-8m3JQzxFZ-EQPcjWZQ', // Lv.99 Animation Club, a re-uploader
        'UCoLp0o-iJEX8D6JTeaHGczQ', // 耳根说漫
        'UCnotarealchannelxxxxxxx',
      ]) {
        expect(
          OfficialEpisodeMatcher.match(
            _upload('【4K完整版】【凡人修仙传】EP196 MultiSub', channel: channel),
            _fanren,
          ),
          isNull,
          reason: channel,
        );
      }
    });

    test('another episode, another show, too short, members-only: no', () {
      expect(
        OfficialEpisodeMatcher.match(_upload('《凡人修仙传》第195话'), _fanren),
        isNull,
      );
      expect(
        OfficialEpisodeMatcher.match(_upload('《斗罗大陆》第196集'), _fanren),
        isNull,
      );
      expect(
        OfficialEpisodeMatcher.match(
          _upload('《凡人修仙传》第196话', duration: const Duration(minutes: 7)),
          _fanren,
        ),
        isNull,
      );
      expect(
        OfficialEpisodeMatcher.match(
          _upload('《凡人修仙传》第196话', membersOnly: true),
          _fanren,
        ),
        isNull,
      );
    });

    test('a sequel with its own entry is not the show', () {
      const douluo = OfficialQuery(names: ['斗罗大陆'], episode: 1);
      expect(
        OfficialEpisodeMatcher.match(_upload('《斗罗大陆2绝世唐门》第1集'), douluo),
        isNull,
      );
      expect(
        OfficialEpisodeMatcher.match(_upload('《斗罗大陆》第1集'), douluo)?.kind,
        OfficialMatchKind.episode,
      );
      // An episode number glued to the name is still an episode number.
      expect(
        OfficialEpisodeMatcher.match(_upload('凡人修仙传196集'), _fanren)?.kind,
        OfficialMatchKind.episode,
      );
    });

    test('a compilation whose range holds the episode', () {
      final m = OfficialEpisodeMatcher.match(
        _upload(
          '【ENGSUB】《凡人修仙传》EP166 - 172合集',
          duration: const Duration(hours: 1, minutes: 49),
        ),
        const OfficialQuery(names: ['凡人修仙传'], episode: 170),
      );
      expect(m?.kind, OfficialMatchKind.compilation);
      expect((m?.rangeStart, m?.rangeEnd), (166, 172));
    });
  });

  group('donghua numbering', () {
    test('年番 EP216 for TMDb S5E216 (plain number past earlier seasons)', () {
      const q = OfficialQuery(
        names: ['斗破苍穹'],
        season: 5,
        episode: 216,
        previousSeasonsEpisodes: 51,
      );
      expect(
        OfficialEpisodeMatcher.match(
          _upload('《斗破苍穹年番》EP216', channel: _tencentAnimation),
          q,
        )?.kind,
        OfficialMatchKind.episode,
      );
    });

    test('年番 EP216 for TMDb S5E12 (absolute = earlier seasons + 12)', () {
      const q = OfficialQuery(
        names: ['斗破苍穹'],
        season: 5,
        episode: 12,
        previousSeasonsEpisodes: 204,
      );
      expect(q.absoluteEpisode, 216);
      expect(
        OfficialEpisodeMatcher.match(
          _upload('《斗破苍穹年番》第216集', channel: _tencentAnimation),
          q,
        )?.kind,
        OfficialMatchKind.episode,
      );
      // ...and S5E12 is not season 1's EP12.
      expect(
        OfficialEpisodeMatcher.match(
          _upload('《斗破苍穹》EP12', channel: _tencentAnimation),
          q,
        ),
        isNull,
      );
    });

    test('a different season named in the title is not this one', () {
      const s1e1 = OfficialQuery(names: ['斗破苍穹'], season: 1, episode: 1);
      expect(
        OfficialEpisodeMatcher.match(
          _upload(
            'ENG SUB《斗破苍穹 第二季》Battle Through the Heavens S2 EP01',
            channel: _tencentAnimation,
          ),
          s1e1,
        ),
        isNull,
      );
      const s2e1 = OfficialQuery(
        names: ['斗破苍穹'],
        season: 2,
        episode: 1,
        previousSeasonsEpisodes: 12,
      );
      expect(
        OfficialEpisodeMatcher.match(
          _upload(
            'ENG SUB《斗破苍穹 第二季》Battle Through the Heavens S2 EP01',
            channel: _tencentAnimation,
          ),
          s2e1,
        )?.kind,
        OfficialMatchKind.episode,
      );
    });

    test('an arc label next to a running number does not block it', () {
      // TMDb: one season, E170. Bilibili: "S4 EP153-176".
      final m = OfficialEpisodeMatcher.match(
        _upload(
          '"A Mortal\'s Journey" S4 EP153–176 Collection',
          duration: const Duration(hours: 6),
        ),
        const OfficialQuery(
          names: ["A Mortal's Journey"],
          season: 1,
          episode: 170,
        ),
      );
      expect(m?.kind, OfficialMatchKind.compilation);
    });

    test('一念永恒: season-relative and running number in one title', () {
      const title = 'ENG SUB《一念永恒》第三季 第五十一集 | A Will Eternal EP157 (S3 EP51)';
      final relative = OfficialEpisodeMatcher.match(
        _upload(title, channel: _tencentAnimation),
        const OfficialQuery(
          names: ['一念永恒'],
          season: 3,
          episode: 51,
          previousSeasonsEpisodes: 106,
        ),
      );
      final running = OfficialEpisodeMatcher.match(
        _upload(title, channel: _tencentAnimation),
        const OfficialQuery(names: ['一念永恒'], season: 1, episode: 157),
      );
      expect(relative?.kind, OfficialMatchKind.episode);
      expect(running?.kind, OfficialMatchKind.episode);
    });
  });

  group('films', () {
    const film = OfficialQuery(names: ['长安三万里']);
    test('a full-length upload with the name and no episode number', () {
      expect(
        OfficialEpisodeMatcher.match(
          _upload('【FULL】长安三万里 Chang An', duration: const Duration(hours: 2)),
          film,
        )?.kind,
        OfficialMatchKind.movie,
      );
    });
    test('shorter than an hour, or numbered, is not the film', () {
      expect(
        OfficialEpisodeMatcher.match(
          _upload('长安三万里 精彩', duration: const Duration(minutes: 30)),
          film,
        ),
        isNull,
      );
      expect(
        OfficialEpisodeMatcher.match(
          _upload('长安三万里 EP01', duration: const Duration(hours: 2)),
          film,
        ),
        isNull,
      );
    });
  });

  group('recorded responses', () {
    test('global search: only Made By Bilibili\'s EP196 survives', () {
      final uploads = _fixture('search_fanren_196');
      expect(uploads, hasLength(20));
      // The re-uploaders' and commentators' "第196集" are all in the response...
      expect(
        uploads.where(
          (u) =>
              !OfficialChannels.isWhitelisted(u.channelId) &&
              u.title.contains('196'),
        ),
        isNotEmpty,
      );
      final ranked = OfficialEpisodeMatcher.rank(uploads, _fanren);
      expect(ranked.map((m) => m.upload.videoId), ['HX_LMf9i_Dc']);
      expect(ranked.single.channel?.handle, '@MadeByBilibili');
    });

    test(
      'channel search: every recent episode, trailers and clips skipped',
      () {
        final uploads = _fixture('browse_bilibili_fanren', channel: _bilibili);
        OfficialMatch? best(int e) => OfficialEpisodeMatcher.rank(
          uploads,
          OfficialQuery(names: const ['凡人修仙传'], season: 1, episode: e),
        ).firstOrNull;

        expect(best(196)?.upload.videoId, 'HX_LMf9i_Dc');
        expect(best(195)?.upload.videoId, 'lqz3jQkVUj0');
        expect(best(190)?.upload.videoId, 'npX4WiRW43w');
        expect(best(178)?.upload.videoId, 'J1-LvSDksNg');
        // 197 and 198 are only trailers so far (the episode is members-only).
        expect(best(197), isNull);
        expect(best(198), isNull);
        // 170 has no single upload; the narrowest compilation holding it wins.
        final c = best(170);
        expect(c?.kind, OfficialMatchKind.compilation);
        expect(c?.upload.videoId, 'DUa62v04CQI');
        // 177 has two single uploads (original and remaster) and compilations;
        // a single episode wins over any compilation, the longer one first.
        final ranked177 = OfficialEpisodeMatcher.rank(
          uploads,
          const OfficialQuery(names: ['凡人修仙传'], season: 1, episode: 177),
        );
        expect(ranked177.first.upload.videoId, '8RQwQvXv70E');
        expect(ranked177.first.kind, OfficialMatchKind.episode);
      },
    );

    test('Tencent Video - Animation: 元尊 第十八集 and a compilation', () {
      final uploads = _fixture(
        'browse_tencent_doupo',
        channel: _tencentAnimation,
      );
      final ranked = OfficialEpisodeMatcher.rank(
        uploads,
        const OfficialQuery(names: ['元尊'], episode: 17),
      );
      expect(ranked.first.upload.videoId, 'QvdqBpMfsjg');
      expect(ranked.first.kind, OfficialMatchKind.episode);
      expect(
        ranked.skip(1).every((m) => m.kind == OfficialMatchKind.compilation),
        isTrue,
      );
      // Shorts in the same response never match.
      expect(
        OfficialEpisodeMatcher.rank(
          uploads,
          const OfficialQuery(names: ['仙逆'], episode: 1),
        ),
        isEmpty,
      );
    });
  });
}
