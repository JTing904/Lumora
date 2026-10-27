@Tags(['network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/scraper/sites/maccms.dart';

void main() {
  for (final (title, type, season, ep, year) in [
    ('灵境行者', 'series', 1, 3, 2026),
    ('凡人修仙传', 'series', 1, 5, 2020),
    ('繁花', 'series', 1, 1, 2023),
    ('流浪地球2', 'movie', null, null, 2023),
  ]) {
    test('probe $title', () async {
      final sources = await MacCmsScraper()
          .scrapeStream(type: type, title: title, year: year, season: season, episode: ep)
          .toList();
      // ignore: avoid_print
      print('$title -> ${sources.length}: ${sources.map((s) => '${s.name}|${s.title}|${s.url?.substring(0, s.url!.length.clamp(0, 60))}').join('  ;  ')}');
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}
