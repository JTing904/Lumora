import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/stream/stream_model.dart';
import 'package:zplay/services/party/watch_party_service.dart';

/// 一起看: what a room sends must open the same thing on a friend's device.
void main() {
  test('what the host watches survives the trip to a guest', () {
    final media = PartyMedia(
      id: 'tt0032599',
      type: 'series',
      title: '女友礼拜五',
      year: '1940',
      episodeId: 'tt0032599:1:2',
      season: 1,
      episode: 2,
      source: StreamSource(
        name: 'Internet Archive',
        title: 'His Girl Friday (1940)',
        url: 'https://archive.org/download/x/x.mp4',
        addonName: 'Internet Archive',
        providerId: 'internet_archive',
        headers: {'Referer': 'https://archive.org/'},
        behaviorHints: {'filename': 'x.mp4'},
      ),
    );
    final back = PartyMedia.fromJson(media.toJson())!;
    expect(back.id, media.id);
    expect(back.type, 'series');
    expect(back.title, '女友礼拜五');
    expect(back.episodeId, 'tt0032599:1:2');
    expect(back.season, 1);
    expect(back.episode, 2);
    expect(back.source.url, media.source.url);
    expect(back.source.addonName, 'Internet Archive');
    expect(back.source.headers, {'Referer': 'https://archive.org/'});
    expect(back.source.behaviorHints?['filename'], 'x.mp4');
  });

  test('a message without a playable source is not a room state', () {
    expect(PartyMedia.fromJson(null), isNull);
    expect(PartyMedia.fromJson({'id': 'tt1', 'type': 'movie'}), isNull);
    expect(
      PartyMedia.fromJson({
        'id': 'tt1',
        'type': 'movie',
        'title': 'X',
        'source': {'url': 'https://a/b.mp4'},
      }),
      isNull,
      reason: 'no addon name',
    );
  });

  test('a typed code is read the way it was meant', () {
    expect(WatchPartyService.normalizeCode(' k7q-m3x '), 'K7QM3X');
    expect(WatchPartyService.isValidCode('K7QM3X'), isTrue);
    expect(WatchPartyService.isValidCode('K7QM3'), isFalse);
    // 0, O, 1 and I are left out of codes so they cannot be misread.
    expect(WatchPartyService.isValidCode('K7QM30'), isFalse);
    expect(WatchPartyService.isValidCode('K7QMIX'), isFalse);
  });

  test('a guest controls playback only while the host allows it', () {
    const guest = PartyRoom(code: 'K7QM3X', isHost: false);
    expect(guest.canControl, isTrue);
    expect(guest.copyWith(guestsCanControl: false).canControl, isFalse);
    const host = PartyRoom(
      code: 'K7QM3X',
      isHost: true,
      guestsCanControl: false,
    );
    expect(host.canControl, isTrue);
  });

  test('a guest opens where the room is now, not where it was heard', () {
    final heard = DateTime.now().subtract(const Duration(seconds: 6));
    final playing = PartyPlayback(
      playing: true,
      position: const Duration(minutes: 8),
      from: 'host',
      at: heard,
    );
    expect(
      playing.positionNow.inSeconds,
      inInclusiveRange(8 * 60 + 6, 8 * 60 + 7),
    );
    final paused = PartyPlayback(
      playing: false,
      position: const Duration(minutes: 8),
      from: 'host',
      at: heard,
    );
    expect(paused.positionNow, const Duration(minutes: 8));
  });
}
