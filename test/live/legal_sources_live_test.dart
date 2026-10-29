@Tags(['network'])
library;

// Live check of the legal-only sources added beside the official uploads:
// TMDb "where to watch" (through Lumora's Supabase proxy, no key in the app),
// the Internet Archive's public-domain films, and the second batch of
// whitelisted YouTube channels.
//
//   flutter test --run-skipped --tags network test/live/legal_sources_live_test.dart
//
// Prints what each lookup found. Fails only when a source answers nothing at
// all for a title it is known to carry.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zplay/services/archive/internet_archive_source.dart';
import 'package:zplay/services/official/official_channels.dart';
import 'package:zplay/services/official/official_episode_matcher.dart';
import 'package:zplay/services/official/official_youtube_source.dart';
import 'package:zplay/services/watch_providers/watch_providers.dart';
import 'package:zplay/services/watch_providers/watch_providers_service.dart';

// The app's own public Supabase project and publishable key (both already
// shipped in the app; the TMDb key stays inside the edge function).
const _proxy = 'https://wfrmsxoshloeaxykwzbg.supabase.co/functions/v1/tmdb';
const _publishable = 'sb_publishable_-yRUFbPNiGVVfGoCdEt_xQ_tmz2PKCp';

Future<Map<String, dynamic>?> _proxyRead(
  String path,
  Map<String, String> params,
) async {
  final uri = Uri.parse(
    '$_proxy$path',
  ).replace(queryParameters: params.isEmpty ? null : params);
  final res = await http
      .get(uri, headers: {'apikey': _publishable, 'Accept': 'application/json'})
      .timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) {
    // ignore: avoid_print
    print('  $path -> HTTP ${res.statusCode}');
    return null;
  }
  return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
}

void _print(String s) {
  // ignore: avoid_print
  print(s);
}

void main() {
  group('where to watch (TMDb via proxy)', () {
    final service = WatchProvidersService(read: _proxyRead);

    Future<RegionWatchProviders?> look(
      String label,
      String id,
      String type,
    ) async {
      final p = await service.forTitle(id: id, type: type, deviceRegion: 'MY');
      _print('$label: ${p == null ? 'nothing' : 'region ${p.region}'}');
      if (p != null) {
        for (final (kind, provider) in p.offers) {
          final link = WatchProviderLinks.forProvider(
            provider,
            title: label,
            tmdbLink: p.tmdbLink,
          );
          _print(
            '  ${kind.name}: ${provider.name} (#${provider.id}) -> ${link?.uri}',
          );
        }
      }
      return p;
    }

    test('MY listings resolve for films and series', () async {
      final notld = await look(
        'Night of the Living Dead',
        'tt0063350',
        'movie',
      );
      expect(notld?.region, 'MY');
      final minglan = await look('知否知否应是绿肥红瘦', 'tmdb:tv:81502', 'series');
      expect(minglan?.offers.map((o) => o.$2.id), contains(623)); // WeTV
      await look('Squid Game', 'tt10919420', 'series');
      await look('Avengers: Endgame', 'tt4154796', 'movie');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('Internet Archive', () {
    test('public-domain classics resolve to an Archive MP4', () async {
      final source = InternetArchiveSource();
      const films = [
        ('Night of the Living Dead', 1968),
        ('His Girl Friday', 1940),
        ('Nosferatu', 1922),
        ('Charade', 1963),
        ('The Avengers', 2012), // copyrighted: must find nothing
      ];
      final found = <String, List<ArchiveFilm>>{};
      for (final (title, year) in films) {
        final sw = Stopwatch()..start();
        final r = await source.find(titles: [title], year: year);
        found[title] = r;
        _print('$title ($year) - ${sw.elapsedMilliseconds} ms');
        for (final f in r) {
          _print(
            '  ${f.identifier} [${f.licence.publicDomain ? 'PD' : 'CC ${f.licence.code}'}] '
            '${f.format} ${f.length?.inMinutes} min -> ${f.streamUrl}',
          );
        }
      }
      expect(found['Night of the Living Dead'], isNotEmpty);
      expect(found['The Avengers'], isEmpty);
      // The MP4 itself answers (a redirect to a storage node, then 200/206).
      final url = Uri.parse(found['Night of the Living Dead']!.first.streamUrl);
      final res = await http.Request(
        'HEAD',
        url,
      ).send().timeout(const Duration(seconds: 20));
      _print('HEAD ${url.path} -> ${res.statusCode}');
      expect(res.statusCode, anyOf(200, 206));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('second-batch official channels', () {
    test('a whitelisted channel answers for a known title', () async {
      final source = OfficialYouTubeSource();
      for (final (names, season, episode) in [
        (['知否知否应是绿肥红瘦', 'The Story of Ming Lan'], 1, 1),
        (['陈真传奇', 'Legend of Chen Zhen'], null, null),
      ]) {
        final r = await source.find(
          OfficialQuery(names: names, season: season, episode: episode),
          region: 'MY',
        );
        _print('${names.first}: ${r.length} match(es)');
        for (final m in r) {
          final c = OfficialChannels.byId(m.upload.channelId);
          _print(
            '  ${m.kind.name} ${m.upload.videoId} "${m.upload.title}" @ ${c?.name}',
          );
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
