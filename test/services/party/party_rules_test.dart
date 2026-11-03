import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/stream/stream_model.dart';
import 'package:zplay/services/party/party_rules.dart';
import 'package:zplay/services/party/watch_party_service.dart';

/// 一起看: the rules that keep a room in step and in the right hands.
void main() {
  final t0 = DateTime(2026, 11, 3, 20);
  Duration s(int n) => Duration(seconds: n);

  group('action clock', () {
    test('a heartbeat sent before the host heard a pause is set aside', () {
      final clock = PartyActionClock();
      // The host's heartbeats so far carry the room's count, 0.
      expect(clock.acceptHeartbeat(0, t0), isTrue);
      // This guest pauses: its message carries 1.
      expect(clock.next(t0), 1);
      // A heartbeat the host sent before hearing it still says 0.
      expect(clock.acceptHeartbeat(0, t0.add(s(1))), isFalse);
      // Once the host has applied the pause, its heartbeat says 1.
      expect(clock.acceptHeartbeat(1, t0.add(s(2))), isTrue);
    });

    test('a move that never reached the host does not deafen the guest', () {
      final clock = PartyActionClock(patience: s(6));
      clock.next(t0);
      expect(clock.acceptHeartbeat(0, t0.add(s(5))), isFalse);
      expect(clock.acceptHeartbeat(0, t0.add(s(6))), isTrue);
    });

    test('a late move is not applied over a newer one', () {
      final clock = PartyActionClock();
      expect(clock.acceptMove(3, t0), isTrue);
      expect(clock.acceptMove(2, t0.add(s(1))), isFalse);
      // Two moves made at once carry the same number; both apply, and the
      // host's heartbeat settles which one the room ends on.
      expect(clock.acceptMove(3, t0.add(s(1))), isTrue);
      expect(clock.next(t0.add(s(2))), 4);
    });

    test('another member\'s move also holds back an older heartbeat', () {
      final clock = PartyActionClock();
      expect(clock.acceptMove(5, t0), isTrue);
      expect(clock.acceptHeartbeat(4, t0.add(s(1))), isFalse);
      expect(clock.acceptHeartbeat(5, t0.add(s(2))), isTrue);
    });

    test('messages from an older build carry no count and are followed', () {
      final clock = PartyActionClock();
      clock.next(t0);
      expect(clock.acceptHeartbeat(null, t0), isTrue);
      expect(clock.acceptMove(null, t0), isTrue);
    });
  });

  group('host absence', () {
    test('a host that blinks out and back does not end the room', () {
      final absence = HostAbsence(grace: s(25));
      expect(absence.update(hostHere: true, now: t0), HostPresenceChange.none);
      expect(
        absence.update(hostHere: false, now: t0.add(s(1))),
        HostPresenceChange.away,
      );
      expect(absence.away, isTrue);
      // Another sync while still missing says nothing new.
      expect(
        absence.update(hostHere: false, now: t0.add(s(3))),
        HostPresenceChange.none,
      );
      expect(absence.expired(t0.add(s(10))), isFalse);
      expect(
        absence.update(hostHere: true, now: t0.add(s(12))),
        HostPresenceChange.back,
      );
      expect(absence.expired(t0.add(s(60))), isFalse);
    });

    test('a host missing for the whole grace period has gone', () {
      final absence = HostAbsence(grace: s(25));
      absence.update(hostHere: true, now: t0);
      absence.update(hostHere: false, now: t0.add(s(1)));
      expect(absence.expired(t0.add(s(25))), isFalse);
      expect(absence.expired(t0.add(s(26))), isTrue);
    });

    test('a guest who has not seen the host yet does not wait for it', () {
      final absence = HostAbsence();
      expect(absence.update(hostHere: false, now: t0), HostPresenceChange.none);
      expect(absence.away, isFalse);
      expect(absence.expired(t0.add(const Duration(minutes: 5))), isFalse);
    });
  });

  group('authority', () {
    test('the member that answered the join is the host from then on', () {
      final a = PartyAuthority();
      expect(a.acceptState('HOST'), isTrue);
      expect(a.hostId, 'HOST');
      expect(a.acceptState('GUEST2'), isFalse);
      expect(a.acceptState(null), isFalse);
      expect(a.acceptState('HOST'), isTrue);
    });

    test('only the host can end the room', () {
      final a = PartyAuthority()..acceptState('HOST');
      expect(a.acceptEnd('GUEST2'), isFalse);
      expect(a.acceptEnd(null), isFalse);
      expect(a.acceptEnd('HOST'), isTrue);
      // Before a host is known nobody can end it.
      expect(PartyAuthority().acceptEnd('HOST'), isFalse);
    });

    test('a guest cannot pass as the host to get past 仅房主控制', () {
      final a = PartyAuthority()..acceptState('HOST');
      expect(a.acceptSync('GUEST2', guestsCanControl: false), isFalse);
      expect(a.acceptSync('GUEST2', guestsCanControl: true), isTrue);
      expect(a.acceptSync('HOST', guestsCanControl: false), isTrue);
    });

    test('on the host\'s own device the host is itself', () {
      final a = PartyAuthority()..hostIsMe('ME');
      expect(a.isHost('ME'), isTrue);
      expect(a.isHost('OTHER'), isFalse);
      a.reset();
      expect(a.isHost('ME'), isFalse);
    });
  });

  group('device-local sources', () {
    test('a loopback or private address only plays on its own device', () {
      for (final url in [
        'http://127.0.0.1:53211/v/abc.mp4',
        'http://localhost:8080/x.m3u8',
        'http://[::1]:9000/x',
        'http://192.168.1.20/movie.mkv',
        'http://10.0.0.5/x',
        'http://172.20.3.4/x',
        'http://169.254.1.1/x',
        'http://nas.local/x',
        'http://0.0.0.0:80/x',
      ]) {
        expect(isDeviceLocalUrl(url), isTrue, reason: url);
        expect(isShareableSourceUrl(url), isFalse, reason: url);
      }
    });

    test('a web address can be shared', () {
      for (final url in [
        'https://archive.org/download/x/x.mp4',
        'http://172.32.0.1/x',
        'https://cdn.example.com/hls/index.m3u8',
      ]) {
        expect(isDeviceLocalUrl(url), isFalse, reason: url);
        expect(isShareableSourceUrl(url), isTrue, reason: url);
      }
    });

    test('anything but a web address is never handed to a guest', () {
      expect(isShareableSourceUrl('file:///C:/Users/x/movie.mkv'), isFalse);
      expect(isShareableSourceUrl('magnet:?xt=urn:btih:abc'), isFalse);
      expect(isShareableSourceUrl(null), isFalse);
      expect(isShareableSourceUrl(''), isFalse);
    });

    test('a host on the Mega proxy sends the title, not the link', () {
      final media = PartyMedia(
        id: 'kitsu:1',
        type: 'series',
        title: 'Anime',
        episodeId: 'kitsu:1:3',
        season: 1,
        episode: 3,
        source: StreamSource(
          url: 'http://127.0.0.1:53211/v/abc.mp4',
          addonName: 'Anime Arabic',
        ),
      );
      expect(media.sourceShared, isFalse);
      final json = media.toJson();
      expect(json['source'], isNull);
      expect(json['sourceLocal'], isTrue);
      final back = PartyMedia.fromJson(json)!;
      expect(back.source, isNull);
      expect(back.key, media.key);
    });

    test('a guest does not open a local link a state slipped in', () {
      final back = PartyMedia.fromJson({
        'id': 'tt1',
        'type': 'movie',
        'title': 'X',
        'source': {'url': 'http://192.168.0.1/admin', 'addonName': 'Evil'},
      })!;
      expect(back.source, isNull);
    });
  });

  group('media key', () {
    test('another episode is another key; another source is not', () {
      final src1 = StreamSource(url: 'https://a/1.mp4', addonName: 'A');
      final src2 = StreamSource(url: 'https://b/1.mp4', addonName: 'B');
      final e1 = PartyMedia(
        id: 'tt1',
        type: 'series',
        title: 'X',
        episodeId: 'tt1:1:1',
        source: src1,
      );
      final e1other = PartyMedia(
        id: 'tt1',
        type: 'series',
        title: 'X',
        episodeId: 'tt1:1:1',
        source: src2,
      );
      final e2 = PartyMedia(
        id: 'tt1',
        type: 'series',
        title: 'X',
        episodeId: 'tt1:1:2',
        source: src1,
      );
      expect(e1.key, e1other.key);
      expect(e1.key, isNot(e2.key));
      expect(
        partyMediaKey(id: 'tt1', season: 1, episode: 2),
        isNot(partyMediaKey(id: 'tt1', season: 1, episode: 3)),
      );
      expect(partyMediaKey(id: 'tt9'), 'tt9');
    });
  });
}
