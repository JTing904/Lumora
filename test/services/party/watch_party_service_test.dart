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
    expect(back.source!.url, media.source!.url);
    expect(back.source!.addonName, 'Internet Archive');
    expect(back.source!.headers, {'Referer': 'https://archive.org/'});
    expect(back.source!.behaviorHints?['filename'], 'x.mp4');
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

  test(
    'a host on a new episode starts the room over, not at the old end',
    () async {
      final service = WatchPartyService.instance;
      PartyMedia episode(int n) => PartyMedia(
        id: 'tt1',
        type: 'series',
        title: 'X',
        episodeId: 'tt1:1:$n',
        season: 1,
        episode: n,
        source: StreamSource(url: 'https://a/$n.mp4', addonName: 'A'),
      );
      service.room.value = const PartyRoom(code: 'K7QM3X', isHost: true);
      addTearDown(() => service.leave());
      await service.setMedia(episode(1));
      service.reportHostPosition(
        playing: true,
        position: const Duration(minutes: 43),
        rate: 1.25,
      );
      expect(service.hostPlayback!.mediaKey, episode(1).key);

      // Another source for the same episode keeps the place.
      await service.setMedia(
        PartyMedia(
          id: 'tt1',
          type: 'series',
          title: 'X',
          episodeId: 'tt1:1:1',
          season: 1,
          episode: 1,
          source: StreamSource(url: 'https://b/1.mp4', addonName: 'B'),
        ),
      );
      expect(service.hostPlayback!.position, const Duration(minutes: 43));

      // The next episode starts where the host's player opens it.
      await service.setMedia(episode(2), startAt: const Duration(seconds: 90));
      final pb = service.hostPlayback!;
      expect(pb.position, const Duration(seconds: 90));
      expect(pb.playing, isFalse);
      expect(pb.mediaKey, episode(2).key);
      // The room's speed carries over.
      expect(pb.rate, 1.25);
    },
  );
}
