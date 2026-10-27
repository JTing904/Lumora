import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../stream_scraper.dart';
import '../../../models/stream/stream_model.dart';
import '../title_match.dart';

/// Pure-Dart FSonic Stream Scraper for ZPlayHTTP.
///
/// Ported 1-to-1 from Vyla FSonic provider.
/// Resolves movies from fsonic.net and fsharetv.co.
class FSonicScraper extends StreamScraper {
  @override
  String get name => 'ZPlayHTTP';

  static const _baseUrl = 'https://www.fsonic.net';
  static const _fshareBase = 'https://fsharetv.co';
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  static const _headers = {
    'User-Agent': _ua,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  /// The `/watch/<slug>` link in [links] whose slug is [title] (within a
  /// year of [year] when the slug carries one), best name match first and a
  /// same-year slug before one a year off; null when none is.
  @visibleForTesting
  static String? pickWatchLink(List<String> links, String title, int? year) {
    String? best;
    var bestScore = 0;
    for (final link in links) {
      final slug = link.substring('/watch/'.length).split(RegExp(r'[/?#]')).first;
      // Slugs read "the-bear-2022-123": the name is what precedes the year.
      final yearMatch = RegExp(r'(?:^|-)((?:19|20)\d{2})(?=-|$)').firstMatch(slug);
      final name = slug.substring(0, yearMatch?.start ?? slug.length).replaceAll('-', ' ');
      final slugYear = yearMatch == null ? null : int.parse(yearMatch.group(1)!);
      // A name ending in a number ("Blade Runner 2049") may carry no year, so
      // the whole slug also counts when it is exactly the title.
      final nameScore = isSameTitle(title, name, wantedYear: year, candidateYear: slugYear)
          ? titleMatchScore(title, name)
          : (titleMatchScore(title, slug.replaceAll('-', ' ')) == 3 ? 3 : 0);
      if (nameScore == 0) continue;
      final score = nameScore * 2 + (year != null && slugYear == year ? 1 : 0);
      if (score > bestScore) {
        best = link;
        bestScore = score;
      }
    }
    return best;
  }

  @override
  Stream<StreamSource> scrapeStream({
    required String type,
    required String title,
    int? year,
    int? season,
    int? episode,
    String? imdbId,
  }) async* {
    if (type == 'tv' || type == 'series' || season != null) return;

    try {
      final client = http.Client();
      try {
        final sRes = await client.get(
          Uri.parse('$_baseUrl/movie/search/${Uri.encodeComponent(title)}'),
          headers: _headers,
        ).timeout(const Duration(seconds: 8));

        if (sRes.statusCode != 200) return;
        final sHtml = sRes.body;

        final links = <String>[];
        var idx = 0;

        while ((idx = sHtml.indexOf('href="/watch/', idx)) != -1) {
          final start = idx + 6;
          final end = sHtml.indexOf('"', start);
          if (end == -1) break;
          links.add(sHtml.substring(start, end));
          idx = end;
        }

        // No "first /watch/ link" fallback: when the title is not listed the
        // first hit is some other film, so play nothing instead.
        final watchSlug = pickWatchLink(links, title, year);
        if (watchSlug == null) return;

        final wRes = await client.get(
          Uri.parse('$_baseUrl$watchSlug'),
          headers: _headers,
        ).timeout(const Duration(seconds: 8));

        if (wRes.statusCode != 200) return;
        final wHtml = wRes.body;

        final match = RegExp(r'''init\('([^']+)',\s*(?:'[^']*',\s*)?'([^']+)'\)''').firstMatch(wHtml);
        if (match == null || match.group(1) == null) return;

        final token = match.group(1)!;
        final trailer = match.group(2) ?? '';

        final jsonRes = await client.get(
          Uri.parse('$_baseUrl/api/source/$token?trailer=$trailer&type=watch'),
          headers: {
            ..._headers,
            'Accept': 'application/json, text/plain, */*',
            'Referer': '$_baseUrl$watchSlug',
          },
        ).timeout(const Duration(seconds: 8));

        if (jsonRes.statusCode != 200) return;
        final json = jsonDecode(jsonRes.body);
        if (json is! Map || json['status'] != 'ok') return;

        final allGroups = <List>[];
        if (json['data']?['file']?['sources'] is List) {
          allGroups.add(json['data']['file']['sources'] as List);
        }
        if (json['data']?['file']?['alternatives'] is List) {
          for (final g in json['data']['file']['alternatives'] as List) {
            if (g is List) allGroups.add(g);
          }
        }

        final seen = <String>{};
        for (final group in allGroups) {
          for (final item in group) {
            if (item is! Map || item['src'] == null) continue;
            final rawSrc = item['src'].toString();
            final srcUrl = rawSrc.startsWith('http') ? rawSrc : '$_fshareBase$rawSrc';

            if (seen.add(srcUrl)) {
              final quality = item['quality']?.toString() ?? '1080';
              final label = item['label']?.toString().trim() ?? '';
              final isHls = srcUrl.contains('.m3u8');

              final titleParts = [
                'FSonic',
                if (label.isNotEmpty) label,
                '${quality}p',
              ];

              final descParts = [
                'FSonic Stream',
                if (label.isNotEmpty) label,
                isHls ? 'HLS' : 'MP4',
              ];

              final reqHeaders = {
                ..._headers,
                'Referer': '$_fshareBase/',
              };

              yield StreamSource(
                name: 'ZPlayHTTP',
                addonName: 'ZPlayHTTP',
                title: titleParts.join(' · '),
                description: descParts.join(' · '),
                url: srcUrl,
                headers: reqHeaders,
                behaviorHints: {
                  'notWebReady': false,
                  'proxyHeaders': {
                    'request': reqHeaders,
                  },
                },
              );
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FSonicScraper] error: $e');
    }
  }
}
