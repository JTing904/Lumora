import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../scraper/title_match.dart';

class OneTwoThreeAnimeResult {
  final String url;
  final String server;
  final String quality;
  final Map<String, String> headers;

  OneTwoThreeAnimeResult({
    required this.url,
    required this.server,
    required this.quality,
    required this.headers,
  });
}

/// Pure-Dart 123Anime Stream Extractor for AnimeScraperService.
///
/// Ported 1-to-1 from Vyla 123Anime provider.
/// Searches 123animehub.cc and resolves EchoVideo HLS streams.
class OneTwoThreeAnimeExtractor {
  static final OneTwoThreeAnimeExtractor instance = OneTwoThreeAnimeExtractor._internal();
  OneTwoThreeAnimeExtractor._internal();

  static const _baseUrl = 'https://123animehub.cc';
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  /// The `/anime/<slug>` links in search [html] whose slug or link text names
  /// one of [titles], best match first; empty when none does.
  @visibleForTesting
  static List<String> matchingSlugs(String html, List<String> titles) {
    final names = <String, List<String>>{};
    for (final m in RegExp(r'href="/anime/([^"]+)"').allMatches(html)) {
      names.putIfAbsent(m.group(1)!, () => [m.group(1)!.replaceAll('-', ' ')]);
    }
    final linkText = RegExp(r'href="/anime/([^"]+)"[^>]*>([\s\S]*?)</a>');
    for (final m in linkText.allMatches(html)) {
      final text = m.group(2)!.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
      if (text.isNotEmpty) names[m.group(1)!]?.add(text);
    }

    final scored = <MapEntry<String, int>>[];
    for (final entry in names.entries) {
      var best = 0;
      for (final wanted in titles) {
        for (final name in entry.value) {
          final score = titleMatchScore(wanted, name);
          if (score > best) best = score;
        }
      }
      if (best > 0) scored.add(MapEntry(entry.key, best));
    }
    // Ties keep the site's order; List.sort is not stable, so compare indexes.
    final order = scored.map((e) => e.key).toList();
    scored.sort((a, b) => b.value != a.value
        ? b.value.compareTo(a.value)
        : order.indexOf(a.key).compareTo(order.indexOf(b.key)));
    return scored.map((e) => e.key).toList();
  }

  Future<List<OneTwoThreeAnimeResult>> extract({
    required List<String> titleCandidates,
    required int episodeNumber,
    int? season,
  }) async {
    final results = <OneTwoThreeAnimeResult>[];
    final client = http.Client();

    try {
      final slugCandidates = <String>[];

      for (final title in titleCandidates) {
        final clean = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (clean.isEmpty) continue;

        try {
          final sUri = Uri.parse('$_baseUrl/ajax/film/search').replace(queryParameters: {
            'keyword': clean,
            '_': DateTime.now().millisecondsSinceEpoch.toString(),
          });

          final res = await client.get(
            sUri,
            headers: {
              'X-Requested-With': 'XMLHttpRequest',
              'Referer': _baseUrl,
              'Accept': 'application/json',
              'User-Agent': _ua,
            },
          ).timeout(const Duration(seconds: 7));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data is Map && data['html'] != null) {
              final html = data['html'].toString();
              // Only slugs that name the title: the search also lists remakes
              // and spin-offs, and the first one with this episode used to win.
              for (final s in matchingSlugs(html, titleCandidates)) {
                if (!slugCandidates.contains(s)) slugCandidates.add(s);
              }
            }
          }
        } catch (_) {}

        if (slugCandidates.isNotEmpty) break;
      }

      String? targetEmbed;

      for (final slug in slugCandidates) {
        try {
          final eprParam = season != null ? '$slug/$season/$episodeNumber' : '$slug/$episodeNumber';
          final epUri = Uri.parse('$_baseUrl/ajax/episode/info').replace(queryParameters: {
            'epr': eprParam,
            'ts': '1',
            '_': DateTime.now().millisecondsSinceEpoch.toString(),
          });

          final res = await client.get(
            epUri,
            headers: {
              'Referer': '$_baseUrl/anime/$slug',
              'X-Requested-With': 'XMLHttpRequest',
              'Accept': 'application/json, text/javascript, */*; q=0.01',
              'User-Agent': _ua,
            },
          ).timeout(const Duration(seconds: 8));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data is Map && data['target'] != null) {
              targetEmbed = data['target'].toString();
              break;
            }
          }
        } catch (_) {}
      }

      if (targetEmbed == null) return results;

      final embedMatch = RegExp(r'/embed-[^/]+/([A-Za-z0-9+/=]+)$').firstMatch(targetEmbed);
      if (embedMatch == null || embedMatch.group(1) == null) return results;

      final sourceId = embedMatch.group(1)!;
      final origin = Uri.parse(targetEmbed).origin;

      final embedRes = await client.get(
        Uri.parse(targetEmbed),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 8));

      if (embedRes.statusCode != 200) return results;

      final setCookie = embedRes.headers['set-cookie'];
      final reqHeaders = <String, String>{
        'Referer': targetEmbed,
        'Accept': '*/*',
        'User-Agent': _ua,
      };
      if (setCookie != null && setCookie.isNotEmpty) {
        reqHeaders['Cookie'] = setCookie.split(';')[0].trim();
      }

      final srcRes = await client.get(
        Uri.parse('$origin/hs/getSources?id=$sourceId'),
        headers: reqHeaders,
      ).timeout(const Duration(seconds: 8));

      if (srcRes.statusCode != 200) return results;

      final srcData = jsonDecode(srcRes.body);
      if (srcData is! Map) return results;

      String? streamUrl;
      if (srcData['sources'] is String && (srcData['sources'] as String).isNotEmpty) {
        streamUrl = srcData['sources'] as String;
      } else if (srcData['sources'] is List && (srcData['sources'] as List).isNotEmpty) {
        final first = (srcData['sources'] as List).first;
        if (first is Map) {
          streamUrl = first['file']?.toString() ?? first['src']?.toString() ?? first['url']?.toString();
        }
      }

      if (streamUrl != null && streamUrl.isNotEmpty) {
        results.add(OneTwoThreeAnimeResult(
          url: streamUrl,
          server: '123Anime (EchoVideo)',
          quality: '1080p',
          headers: {
            'Referer': 'https://play2.echovideo.ru/',
            'Origin': 'https://play2.echovideo.ru',
            'User-Agent': _ua,
          },
        ));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[OneTwoThreeAnimeExtractor] extract error: $e');
    } finally {
      client.close();
    }

    return results;
  }
}
