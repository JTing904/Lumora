import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zplay/services/archive/internet_archive_source.dart';

String _fixture(String name) =>
    File('test/fixtures/internet_archive/$name.json').readAsStringSync();

http.Response _json(String body) => http.Response.bytes(
  utf8.encode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _names = ['Night of the Living Dead'];

void main() {
  group('rules', () {
    test('licences: CC and public-domain marks only', () {
      final pd = InternetArchiveSource.licenceOf(
        'http://creativecommons.org/publicdomain/mark/1.0/',
      );
      expect(pd?.publicDomain, isTrue);
      expect(
        InternetArchiveSource.licenceOf(
          'http://creativecommons.org/licenses/publicdomain/',
        )?.publicDomain,
        isTrue,
      );
      expect(
        InternetArchiveSource.licenceOf(
          'https://creativecommons.org/publicdomain/zero/1.0/',
        )?.publicDomain,
        isTrue,
      );
      final by = InternetArchiveSource.licenceOf(
        'https://creativecommons.org/licenses/by-nc-sa/4.0/',
      );
      expect(by?.publicDomain, isFalse);
      expect(by?.code, 'BY-NC-SA');
      expect(InternetArchiveSource.licenceOf(null), isNull);
      expect(InternetArchiveSource.licenceOf('All rights reserved'), isNull);
      expect(
        InternetArchiveSource.licenceOf(
          'https://example.com/creativecommons.org/licenses/by/',
        ),
        isNull,
      );
    });

    test('titles must match exactly after folding', () {
      bool m(String t) => InternetArchiveSource.titleMatches(t, _names);
      expect(m('Night of the Living Dead'), isTrue);
      expect(m('Night Of The Living Dead'), isTrue);
      expect(m('Night of the Living Dead (1968)'), isTrue);
      expect(m('Night of the Living Dead Trailer'), isFalse);
      expect(m('Night Of The Living Dead ( Colorized, 1968)'), isFalse);
      expect(
        m('Night of the Living Dead iPod and Flash video versions'),
        isFalse,
      );
      expect(m('Dawn of the Dead'), isFalse);
    });

    test('ripped commercial releases are refused, Archive names are not', () {
      for (final n in [
        'nosferatu.-1922.-blu-ray.-1080p',
        'Nosferatu.1922.BluRay.1080p.DTS-HD.MA.5.1.AVC.REMUX-FraMeSToR.mp4',
        'Charade.1963.720p.WEB-DL.x264',
        'film-1963-1080p-GROUP',
      ]) {
        expect(InternetArchiveSource.looksRipped(n), isTrue, reason: n);
      }
      for (final n in [
        'Night.Of.The.Living.Dead_1080p',
        'NightOfTheLivingDead_720p.mp4',
        'NightOfTheLivingDead_1080p_512kb.mp4',
        'night-of-the-living-dead-1968_202312',
        'his_girl_friday.mp4',
        'Atmospheric Night',
      ]) {
        expect(InternetArchiveSource.looksRipped(n), isFalse, reason: n);
      }
    });

    test('the search stays inside the curated collections and the year', () {
      final uri = InternetArchiveSource.searchUri(
        'Night of the "Living" Dead',
        1968,
      );
      final q = uri.queryParameters['q']!;
      expect(q, contains('year:(1968)'));
      expect(q, contains('collection:(feature_films OR'));
      expect(q, isNot(contains('opensource_movies')));
      expect(q, isNot(contains('"Living"')));
      expect(uri.queryParametersAll['fl[]'], contains('licenseurl'));
    });
  });

  group('recorded Archive answers', () {
    test(
      'search hits: unlicensed, retitled and off-year items are dropped',
      () {
        final docs = InternetArchiveSource.parseSearch(
          jsonDecode(_fixture('search_night_of_the_living_dead_1968')),
        );
        expect(docs.length, 12);
        final kept = InternetArchiveSource.filterDocs(
          docs,
          names: _names,
          year: 1968,
        ).map((d) => d.identifier);
        expect(kept, [
          'Night.Of.The.Living.Dead_1080p',
          'night_of_the_living_dead_dvd',
          'Night_Of_The_Living_Dead_raw_HD_WS',
          'night-of-the-living-dead_1968',
          'night-of-the-living-dead-1968_202312',
        ]);
        expect(
          kept,
          isNot(contains('NightOfTheLivingDead-MPEG')),
        ); // no licence
        expect(
          InternetArchiveSource.filterDocs(docs, names: _names, year: 1990),
          isEmpty,
        );
      },
    );

    test('metadata: picks the h.264 derivative MP4', () {
      final film = InternetArchiveSource.filmFromMetadata(
        jsonDecode(_fixture('metadata_Night.Of.The.Living.Dead_1080p')),
        names: _names,
        year: 1968,
      )!;
      expect(film.licence.publicDomain, isTrue);
      expect(film.format, 'h.264');
      expect(film.fileName, endsWith('.mp4'));
      expect(film.length!.inMinutes, greaterThan(90));
      expect(film.sizeBytes, lessThan(InternetArchiveSource.maxFileBytes));
      expect(
        film.streamUrl,
        startsWith(
          'https://archive.org/download/Night.Of.The.Living.Dead_1080p/',
        ),
      );
    });

    test('metadata without a licence is refused', () {
      expect(
        InternetArchiveSource.filmFromMetadata(
          jsonDecode(_fixture('metadata_NightOfTheLivingDead-MPEG')),
          names: _names,
          year: 1968,
        ),
        isNull,
      );
    });

    test('find() end to end on the recordings, no network', () async {
      final calls = <String>[];
      final source = InternetArchiveSource(
        client: MockClient((req) async {
          calls.add(req.url.path);
          if (req.url.path == '/advancedsearch.php') {
            return _json(_fixture('search_night_of_the_living_dead_1968'));
          }
          if (req.url.path == '/metadata/Night.Of.The.Living.Dead_1080p') {
            return _json(_fixture('metadata_Night.Of.The.Living.Dead_1080p'));
          }
          return http.Response('', 404);
        }),
      );
      final films = await source.find(
        titles: const ['Night of the Living Dead', '活死人之夜'],
        year: 1968,
      );
      expect(films.map((f) => f.identifier), [
        'Night.Of.The.Living.Dead_1080p',
      ]);
      // One search (the CJK name is not sent), then metadata for the best
      // candidates until enough are found.
      expect(calls.where((c) => c == '/advancedsearch.php').length, 1);
    });

    test('a failed lookup is asked again, not remembered as none', () async {
      var online = false;
      final source = InternetArchiveSource(
        client: MockClient((req) async {
          if (!online) throw const SocketException('slow network');
          if (req.url.path == '/advancedsearch.php') {
            return _json(_fixture('search_night_of_the_living_dead_1968'));
          }
          if (req.url.path == '/metadata/Night.Of.The.Living.Dead_1080p') {
            return _json(_fixture('metadata_Night.Of.The.Living.Dead_1080p'));
          }
          return http.Response('', 404);
        }),
      );
      expect(await source.find(titles: _names, year: 1968), isEmpty);
      online = true;
      expect(await source.find(titles: _names, year: 1968), isNotEmpty);
    });

    test('offline is an empty list', () async {
      final source = InternetArchiveSource(
        client: MockClient((_) async => throw const SocketException('x')),
      );
      expect(await source.find(titles: _names, year: 1968), isEmpty);
    });
  });
}
