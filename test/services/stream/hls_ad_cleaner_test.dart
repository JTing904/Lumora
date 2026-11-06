import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zplay/services/stream/hls_ad_cleaner.dart';

const _film = 'https://v1.example.test/20240101/film/hls';
const _ad = 'https://v1.example.test/20261031/ad/hls';

String _media({bool ads = true}) {
  final b = StringBuffer(
    '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:4\n'
    '#EXT-X-MEDIA-SEQUENCE:0\n',
  );
  void block(String dir, int count, String tag) {
    for (var i = 0; i < count; i++) {
      b.writeln('#EXTINF:4,\n$dir/$tag$i.ts');
    }
  }

  block(_film, 30, 'a');
  if (ads) {
    b.writeln('#EXT-X-DISCONTINUITY');
    block(_ad, 4, 'x');
    b.writeln('#EXT-X-DISCONTINUITY');
  }
  block(_film, 30, 'b');
  b.writeln('#EXT-X-ENDLIST');
  return b.toString();
}

void main() {
  late Directory temp;
  late List<Uri> requested;
  late List<Map<String, String>> sentHeaders;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('hls_ad_cleaner_test');
    requested = [];
    sentHeaders = [];
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  HlsAdCleaner cleaner(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 4),
  }) {
    return HlsAdCleaner(
      client: MockClient((request) {
        requested.add(request.url);
        sentHeaders.add(request.headers);
        return handler(request);
      }),
      tempDirectory: () async => temp,
      timeout: timeout,
    );
  }

  Future<String> readLocal(String url) async =>
      File.fromUri(Uri.parse(url)).readAsString();

  group('appliesTo', () {
    test('only the 资源站 provider, and only for .m3u8 addresses', () {
      expect(
        HlsAdCleaner.appliesTo('中文资源站', 'https://a.test/x/index.m3u8'),
        isTrue,
      );
      expect(
        HlsAdCleaner.appliesTo('中文资源站', 'https://a.test/x/index.m3u8?t=1'),
        isTrue,
      );
      expect(
        HlsAdCleaner.appliesTo('Torrentio', 'https://a.test/x/index.m3u8'),
        isFalse,
      );
      expect(
        HlsAdCleaner.appliesTo(null, 'https://a.test/x/index.m3u8'),
        isFalse,
      );
      expect(
        HlsAdCleaner.appliesTo('中文资源站', 'https://a.test/x/video.mp4'),
        isFalse,
      );
      expect(HlsAdCleaner.appliesTo('中文资源站', 'magnet:?xt=1'), isFalse);
    });
  });

  group('isCleanedPlaylist', () {
    test('knows its own files and nothing else', () async {
      final c = cleaner((_) async => http.Response(_media(), 200));
      final out = await c.clean('https://site.test/film/index.m3u8');
      expect(HlsAdCleaner.isCleanedPlaylist(out.url), isTrue);
      expect(HlsAdCleaner.isCleanedPlaylist('https://a.test/x.m3u8'), isFalse);
      expect(
        HlsAdCleaner.isCleanedPlaylist('file:///movies/film.mkv'),
        isFalse,
      );
      expect(HlsAdCleaner.isCleanedPlaylist(r'C:\movies\a.m3u8'), isFalse);
    });

    test('the mpv option length prefix matches the list', () {
      final m = RegExp(
        r'protocol_whitelist=%(\d+)%(.*)$',
      ).firstMatch(HlsAdCleaner.mpvDemuxerOptions)!;
      expect(int.parse(m.group(1)!), m.group(2)!.length);
    });
  });

  group('a media playlist', () {
    test(
      'with ads is written to a local file and that is what to open',
      () async {
        final c = cleaner((_) async => http.Response(_media(), 200));
        final out = await c.clean(
          'https://site.test/film/index.m3u8',
          headers: const {'Referer': 'https://site.test/'},
        );

        expect(out.cleaned, isTrue);
        expect(out.removedSeconds, closeTo(16, 0.01));
        expect(out.url, startsWith('file:///'));
        expect(out.url, endsWith('.m3u8'));
        final text = await readLocal(out.url);
        expect(text, isNot(contains('/ad/')));
        expect(text, contains('$_film/b29.ts'));
        expect(sentHeaders.single['Referer'], 'https://site.test/');
      },
    );

    test('opening the same address again overwrites the same file', () async {
      final c = cleaner((_) async => http.Response(_media(), 200));
      final first = await c.clean('https://site.test/film/index.m3u8');
      final second = await c.clean('https://site.test/film/index.m3u8');
      final other = await c.clean('https://site.test/other/index.m3u8');

      expect(second.url, first.url);
      expect(other.url, isNot(first.url));
      final files = Directory(
        '${temp.path}${Platform.pathSeparator}lumora_hls',
      ).listSync().whereType<File>().where((f) => !f.path.endsWith('.tmp'));
      expect(files, hasLength(2));
    });

    test('without ads keeps the original address and writes nothing', () async {
      final c = cleaner((_) async => http.Response(_media(ads: false), 200));
      final out = await c.clean('https://site.test/film/index.m3u8');
      expect(out.url, 'https://site.test/film/index.m3u8');
      expect(out.cleaned, isFalse);
      expect(
        Directory(
          '${temp.path}${Platform.pathSeparator}lumora_hls',
        ).existsSync(),
        isFalse,
      );
    });
  });

  group('never gets in the way', () {
    const url = 'https://site.test/film/index.m3u8';

    test('a server error', () async {
      final c = cleaner((_) async => http.Response('nope', 503));
      expect((await c.clean(url)).url, url);
    });

    test('a page that is not a playlist', () async {
      final c = cleaner((_) async => http.Response('<html></html>', 200));
      expect((await c.clean(url)).url, url);
    });

    test('a network error', () async {
      final c = cleaner((_) async => throw const SocketException('down'));
      expect((await c.clean(url)).url, url);
    });

    test('a site that answers too slowly', () async {
      final c = cleaner(
        (_) => Future<http.Response>.delayed(
          const Duration(seconds: 2),
          () => http.Response(_media(), 200),
        ),
        timeout: const Duration(milliseconds: 100),
      );
      final started = DateTime.now();
      final out = await c.clean(url);
      expect(out.url, url);
      expect(
        DateTime.now().difference(started),
        lessThan(const Duration(seconds: 1)),
      );
    });

    test('a folder that cannot be written to', () async {
      final blocker = File('${temp.path}${Platform.pathSeparator}blocked')
        ..writeAsStringSync('a file where a folder is wanted');
      final c = HlsAdCleaner(
        client: MockClient((_) async => http.Response(_media(), 200)),
        tempDirectory: () async => Directory(blocker.path),
      );
      expect((await c.clean(url)).url, url);
    });

    test('an address that is not http', () async {
      final c = cleaner((_) async => http.Response(_media(), 200));
      expect(
        (await c.clean('magnet:?xt=urn:btih:1')).url,
        'magnet:?xt=urn:btih:1',
      );
      expect(requested, isEmpty);
    });
  });

  group('a master playlist', () {
    test('with one variant gives the cleaned variant itself', () async {
      final c = cleaner((request) async {
        if (request.url.path.endsWith('/index.m3u8') &&
            !request.url.path.contains('/720/')) {
          return http.Response(
            '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=900000\n720/index.m3u8\n',
            200,
          );
        }
        return http.Response(_media(), 200);
      });
      final out = await c.clean('https://site.test/film/index.m3u8');

      expect(out.cleaned, isTrue);
      final text = await readLocal(out.url);
      expect(text, contains('#EXTINF'));
      expect(text, isNot(contains('STREAM-INF')));
      expect(requested.map((u) => u.path), [
        '/film/index.m3u8',
        '/film/720/index.m3u8',
      ]);
    });

    test('with several is a local master over the cleaned ones, and a variant '
        'that failed keeps its own address', () async {
      final c = cleaner((request) async {
        final path = request.url.path;
        if (path.endsWith('/film/index.m3u8')) {
          return http.Response(
            '#EXTM3U\n'
            '#EXT-X-STREAM-INF:BANDWIDTH=900000\n720/index.m3u8\n'
            '#EXT-X-STREAM-INF:BANDWIDTH=2400000\n1080/index.m3u8\n'
            '#EXT-X-STREAM-INF:BANDWIDTH=4800000\n2160/index.m3u8\n',
            200,
          );
        }
        if (path.contains('/2160/')) return http.Response('gone', 404);
        return http.Response(_media(), 200);
      });
      final out = await c.clean('https://site.test/film/index.m3u8');

      expect(out.cleaned, isTrue);
      final master = await readLocal(out.url);
      final lines = master.split('\n').where((l) => l.isNotEmpty).toList();
      expect(
        lines.where((l) => l.startsWith('#EXT-X-STREAM-INF')),
        hasLength(3),
      );
      final uris = lines.where((l) => !l.startsWith('#')).toList();
      expect(uris[0], startsWith('file:///'));
      expect(uris[1], startsWith('file:///'));
      expect(uris[2], 'https://site.test/film/2160/index.m3u8');
      expect(await readLocal(uris[0]), isNot(contains('/ad/')));
    });

    test('with no ads in any variant is left alone', () async {
      final c = cleaner((request) async {
        if (request.url.path.endsWith('/film/index.m3u8')) {
          return http.Response(
            '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=900000\n720/index.m3u8\n'
            '#EXT-X-STREAM-INF:BANDWIDTH=2400000\n1080/index.m3u8\n',
            200,
          );
        }
        return http.Response(_media(ads: false), 200);
      });
      final out = await c.clean('https://site.test/film/index.m3u8');
      expect(out.url, 'https://site.test/film/index.m3u8');
    });
  });
}
