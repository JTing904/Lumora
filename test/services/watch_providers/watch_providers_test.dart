import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/watch_providers/watch_providers.dart';
import 'package:zplay/services/watch_providers/watch_providers_service.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(
          File('test/fixtures/watch_providers/$name.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  group('WatchProvidersParser (recorded TMDb answers)', () {
    test('groups MY into free / ads / subscription, each service once', () {
      final p = WatchProvidersParser.parse(
        _fixture('movie_10331_night_of_the_living_dead'),
        regions: const ['MY'],
      )!;
      expect(p.region, 'MY');
      expect(p.tmdbLink, contains('locale=MY'));
      // Bloodstream is listed as both free and flatrate: it shows once, free.
      expect(p.groups[WatchOfferKind.free]!.map((e) => e.name), [
        'Bloodstream',
      ]);
      expect(p.groups[WatchOfferKind.ads]!.map((e) => e.name), ['Plex']);
      expect(p.groups[WatchOfferKind.subscription], isEmpty);
      expect(p.groups[WatchOfferKind.rentBuy], isEmpty);
      expect(
        p.groups[WatchOfferKind.free]!.single.logoUrl(),
        startsWith('https://image.tmdb.org/t/p/w92/'),
      );
    });

    test('WeTV subscription for 知否知否 in MY', () {
      final p = WatchProvidersParser.parse(
        _fixture('tv_81502_story_of_ming_lan'),
        regions: const ['MY'],
      )!;
      expect(p.groups[WatchOfferKind.subscription]!.map((e) => e.id), [623]);
      expect(p.offers.length, 1);
    });

    test('falls back to the next region when MY lists nothing', () {
      final json = _fixture('tv_106449_mortals_journey');
      expect(WatchProvidersParser.parse(json, regions: const ['MY']), isNull);
      final tw = WatchProvidersParser.parse(json, regions: const ['MY', 'TW']);
      expect(tw?.region, 'TW');
      expect(tw!.isEmpty, isFalse);
    });

    test('garbage in, null out', () {
      expect(WatchProvidersParser.parse(null, regions: const ['MY']), isNull);
      expect(
        WatchProvidersParser.parse({'results': 3}, regions: const ['MY']),
        isNull,
      );
      expect(
        WatchProvidersParser.parse(
          {
            'results': {
              'MY': {
                'flatrate': [
                  {'provider_id': 'x', 'provider_name': 'Bad'},
                  {'provider_id': 8},
                ],
              },
            },
          },
          regions: const ['MY'],
        ),
        isNull,
      );
    });
  });

  group('WatchProviderLinks', () {
    WatchProvider p(int id, String name) => WatchProvider(id: id, name: name);

    test('known services open their own https app link with the title', () {
      final wetv = WatchProviderLinks.forProvider(
        p(623, 'WeTV'),
        title: '知否知否应是绿肥红瘦',
        tmdbLink: 'https://www.themoviedb.org/tv/81502/watch?locale=MY',
      )!;
      expect(wetv.service, isTrue);
      expect(wetv.uri.host, 'wetv.vip');
      expect(Uri.decodeComponent(wetv.uri.path), contains('知否知否应是绿肥红瘦'));

      final cases = {
        8: 'www.netflix.com',
        581: 'www.iq.com',
        158: 'www.viu.com',
        337: 'www.disneyplus.com',
        122: 'www.disneyplus.com',
        119: 'www.primevideo.com',
        192: 'www.youtube.com',
        344: 'www.viki.com',
      };
      for (final MapEntry(key: id, value: host) in cases.entries) {
        final link = WatchProviderLinks.forProvider(
          p(id, 'X'),
          title: 'Hidden Love',
        );
        expect(link?.uri.host, host, reason: 'provider $id');
        expect(link!.uri.scheme, 'https');
      }
      expect(
        WatchProviderLinks.forProvider(
          p(9999, 'Bilibili'),
          title: 'x',
        )?.uri.host,
        'www.bilibili.tv',
      );
    });

    test('unknown services and stores go to TMDb\'s page', () {
      const tmdb = 'https://www.themoviedb.org/movie/10331/watch?locale=MY';
      for (final provider in [p(2555, 'Bloodstream'), p(2, 'Apple TV Store')]) {
        final link = WatchProviderLinks.forProvider(
          provider,
          title: 'x',
          tmdbLink: tmdb,
        )!;
        expect(link.service, isFalse);
        expect(link.uri.toString(), tmdb);
      }
      expect(
        WatchProviderLinks.forProvider(p(2555, 'Bloodstream'), title: 'x'),
        isNull,
      );
    });
  });

  group('WatchProvidersService', () {
    test('resolves an IMDb id through /find, then reads MY', () async {
      final paths = <String>[];
      final service = WatchProvidersService(
        read: (path, params) async {
          paths.add(path);
          if (path == '/find/tt0063350') return _fixture('find_tt0063350');
          if (path == '/movie/10331/watch/providers') {
            return _fixture('movie_10331_night_of_the_living_dead');
          }
          return null;
        },
      );
      final p = await service.forTitle(
        id: 'tt0063350',
        type: 'movie',
        deviceRegion: 'US',
      );
      expect(paths, ['/find/tt0063350', '/movie/10331/watch/providers']);
      expect(p?.region, 'MY');
    });

    test('uses a tmdb: id directly and the tv path for a series', () async {
      final paths = <String>[];
      final service = WatchProvidersService(
        read: (path, params) async {
          paths.add(path);
          return _fixture('tv_106449_mortals_journey');
        },
      );
      final p = await service.forTitle(
        id: 'tmdb:tv:106449',
        type: 'series',
        deviceRegion: 'TW',
      );
      expect(paths, ['/tv/106449/watch/providers']);
      expect(p?.region, 'TW');
    });

    test('a failed read is null, not an exception', () async {
      final service = WatchProvidersService(
        read: (path, params) async => throw const SocketException('offline'),
      );
      expect(
        await service.forTitle(id: 'tt1', type: 'movie', deviceRegion: 'MY'),
        isNull,
      );
    });

    test('regions: MY first, the device region after, no duplicates', () {
      expect(WatchProvidersService.regionsFor('sg'), ['MY', 'SG']);
      expect(WatchProvidersService.regionsFor('MY'), ['MY']);
      expect(WatchProvidersService.regionsFor(null), ['MY']);
    });
  });
}
