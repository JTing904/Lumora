import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/official/official_channels.dart';
import 'package:zplay/services/official/official_episode_matcher.dart';

void main() {
  test('every whitelisted channel id is a well-formed, unique UC id', () {
    final ids = OfficialChannels.all.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(RegExp(r'^UC[A-Za-z0-9_-]{22}$').hasMatch(id), isTrue, reason: id);
    }
  });

  test('the second batch is on the list and plays in Malaysia', () {
    final my = OfficialChannels.availableIn('MY').map((c) => c.id).toSet();
    for (final id in [
      'UCZ8ZJNzzIiDQFuGxdGTyWcQ', // 爱奇艺大电影 iQIYI MOVIE THEATER
      'UCE2UHXGOlqotRJgEWl_tiMw', // YOUKU MOVIE
      'UC1pHFqCMAIHP8gr4lYGtNLA', // 湖南卫视芒果TV官方频道
      'UCAYkj2Fz9EvAe2fGJEGMXnQ', // CCTV纪录
      'UCGhGr_hznZxISOI_kaLWpfw', // China Movie Channel ENGLISH
      'UCL9njwWyBqP1JQ9T5kbxTUg', // Mediacorp Classics
      'UCJL8FI5LLq1G_qE5Ny-Zsqw', // TVB Mandarin Drama
    ]) {
      expect(my, contains(id));
    }
    // Still blocked where the channel says so.
    expect(my, isNot(contains('UC-vdzV9IVeIsp0YSCm16CkQ')));
  });

  test('the third batch is on the list and plays in Malaysia', () {
    final my = OfficialChannels.availableIn('MY').map((c) => c.id).toSet();
    for (final id in [
      'UCahKjkez9olNwcpc5pZwzvg', // SMG上海电视台官方频道
      'UC52EYUUSlzcYqHj-qsx0RHg', // Zhejiang STV
      'UC8IHAQMuiJdY6ALuhG7iU8Q', // FilmRise Movies
      'UCVFYikepF-avelvuIaQ_lHA', // Popcornflix
      'UCyJYCQ6WaEMhdZAuPo799bA', // Grjngo - Western Movies
      'UC88lvyJe7aHZmcvzvubDFRg', // Timeline
    ]) {
      expect(my, contains(id));
    }
  });

  test('a licensed film upload matches its film', () {
    const upload = OfficialUpload(
      videoId: 'pH15fIh7xrg',
      title:
          'McLintock | WESTERN MOVIE | John Wayne | Free Cowboy Film | '
          'Full Movie',
      channelId: 'UCyJYCQ6WaEMhdZAuPo799bA',
      duration: Duration(hours: 2, minutes: 6),
    );
    final m = OfficialEpisodeMatcher.match(
      upload,
      const OfficialQuery(names: ['McLintock!']),
    );
    expect(m?.kind, OfficialMatchKind.movie);
  });

  group('members-only titles', () {
    OfficialUpload upload(String title) => OfficialUpload(
      videoId: 'aaaaaaaaaaa',
      title: title,
      channelId: 'UC1pHFqCMAIHP8gr4lYGtNLA',
      duration: const Duration(minutes: 50),
    );
    const query = OfficialQuery(names: ['歌手2024'], season: 1, episode: 5);

    test('are recognised', () {
      for (final t in [
        'VIP《歌手2024》第5期',
        '【会员专享】歌手2024 EP05',
        '👑會員專享👑 歌手2024 EP05',
      ]) {
        expect(OfficialEpisodeMatcher.isMembersOnlyTitle(t), isTrue, reason: t);
        expect(OfficialEpisodeMatcher.match(upload(t), query), isNull);
      }
    });

    test('ordinary titles are not', () {
      for (final t in [
        'FULL《歌手2024》第5期',
        'VIPER EP05',
        'Very Important Person EP05',
      ]) {
        expect(
          OfficialEpisodeMatcher.isMembersOnlyTitle(t),
          isFalse,
          reason: t,
        );
      }
    });
  });
}
