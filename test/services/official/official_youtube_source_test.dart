import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zplay/services/official/official_episode_matcher.dart';
import 'package:zplay/services/official/official_youtube_source.dart';

String _fixture(String name) =>
    File('test/fixtures/official_youtube/$name.json').readAsStringSync();

http.Response _json(String body) => http.Response.bytes(
  utf8.encode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _fanren196 = OfficialQuery(
  names: ['凡人修仙传', "A Mortal's Journey"],
  season: 1,
  episode: 196,
);

void main() {
  test('resolves from the recorded global search, no network', () async {
    final calls = <String>[];
    final source = OfficialYouTubeSource(
      client: MockClient((req) async {
        calls.add(req.url.path);
        if (req.url.path.endsWith('/search')) {
          return _json(_fixture('search_fanren_196'));
        }
        if (req.url.path == '/oembed') return _json('{}');
        return http.Response('', 404);
      }),
    );
    final found = await source.find(_fanren196, region: 'MY');
    expect(found.map((m) => m.upload.videoId), ['HX_LMf9i_Dc']);
    expect(found.single.kind, OfficialMatchKind.episode);
    // Settled by the global search: no channel browsing needed.
    expect(calls.where((p) => p.endsWith('/browse')), isEmpty);
    expect(calls, contains('/oembed'));
  });

  test(
    'falls back to searching inside the channel that carries the show',
    () async {
      final bodies = <Map<String, dynamic>>[];
      final source = OfficialYouTubeSource(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/search')) {
            return _json(_fixture('search_fanren_196'));
          }
          if (req.url.path.endsWith('/browse')) {
            bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
            return _json(_fixture('browse_bilibili_fanren'));
          }
          return _json('{}');
        }),
      );
      final found = await source.find(
        const OfficialQuery(names: ['凡人修仙传'], season: 1, episode: 195),
        region: 'MY',
      );
      expect(found.first.upload.videoId, 'lqz3jQkVUj0');
      // Only the whitelisted channel that showed up for the show was browsed.
      expect(bodies.map((b) => b['browseId']).toSet(), {
        'UCQFyMGc6h30NMCd6HCk0ZPA',
      });
    },
  );

  test('a video whose owner disabled embedding is not offered', () async {
    final source = OfficialYouTubeSource(
      client: MockClient((req) async {
        if (req.url.path.endsWith('/search')) {
          return _json(_fixture('search_fanren_196'));
        }
        if (req.url.path == '/oembed') {
          return http.Response('Unauthorized', 401);
        }
        return _json('{}');
      }),
    );
    expect(await source.find(_fanren196, region: 'MY'), isEmpty);
  });

  test('fails quietly and does not cache the failure', () async {
    var offline = true;
    var searches = 0;
    final source = OfficialYouTubeSource(
      client: MockClient((req) async {
        if (offline) throw const SocketException('offline');
        if (req.url.path.endsWith('/search')) {
          searches++;
          return _json(_fixture('search_fanren_196'));
        }
        return _json('{}');
      }),
    );
    expect(await source.find(_fanren196), isEmpty);
    offline = false;
    expect(await source.find(_fanren196), isNotEmpty);
    final before = searches;
    // Cached now: a second open makes no request.
    expect(await source.find(_fanren196), isNotEmpty);
    expect(searches, before);
  });

  test('garbage JSON is an empty answer, not an exception', () async {
    final source = OfficialYouTubeSource(
      client: MockClient((req) async => _json('{"contents": [1, "x", null]}')),
    );
    expect(await source.find(_fanren196), isEmpty);
  });

  test('the cache expires', () async {
    var now = DateTime(2026, 10, 28, 12);
    var searches = 0;
    final source = OfficialYouTubeSource(
      clock: () => now,
      client: MockClient((req) async {
        if (req.url.path.endsWith('/search')) {
          searches++;
          return _json(_fixture('search_fanren_196'));
        }
        return _json('{}');
      }),
    );
    await source.find(_fanren196);
    final first = searches;
    now = now.add(OfficialYouTubeSource.hitTtl + const Duration(minutes: 1));
    await source.find(_fanren196);
    expect(searches, greaterThan(first));
  });

  test('parseLength', () {
    expect(
      OfficialYouTubeSource.parseLength('1:14:51'),
      const Duration(hours: 1, minutes: 14, seconds: 51),
    );
    expect(
      OfficialYouTubeSource.parseLength('21:25'),
      const Duration(minutes: 21, seconds: 25),
    );
    expect(OfficialYouTubeSource.parseLength('LIVE'), isNull);
  });
}
