import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../../scraper/title_match.dart';

class AniDbEpisode {
  final int number;
  final String id;

  AniDbEpisode({
    required this.number,
    required this.id,
  });
}

class AniDbResult {
  final String url;
  final String quality;
  final Map<String, String> headers;
  final String category; // 'sub' or 'dub'

  AniDbResult({
    required this.url,
    this.quality = 'auto',
    required this.headers,
    required this.category,
  });
}

class AniDbExtractor {
  static final AniDbExtractor instance = AniDbExtractor._internal();
  AniDbExtractor._internal();

  static const String baseUrl = 'https://anidb.app';
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  static const Map<String, String> _defaultHeaders = {
    'User-Agent': _userAgent,
    'Referer': '$baseUrl/',
    'Origin': baseUrl,
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  final http.Client _client = http.Client();

  // Cache: title/id -> anime slug ID (e.g. 'one-piece-3880')
  final Map<String, String> _slugCache = {};

  // Cache: slug -> list of episodes
  final Map<String, List<AniDbEpisode>> _episodesCache = {};

  /// Fetches URL via curl subprocess on desktop or http.Client on mobile/web.
  Future<String> _fetch(String url) async {
    // Embed links come from the site's JSON. Only a web address goes to curl:
    // anything else (`-K file`, `file://`) would be read as a curl option or
    // a local path.
    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return '';
    }
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        final curlCmd = Platform.isWindows ? 'curl.exe' : 'curl';
        final result = await Process.run(
          curlCmd,
          [
            '-sL',
            '-A',
            _userAgent,
            '-e',
            '$baseUrl/',
            '--max-time',
            '10',
            '--proto',
            '=http,https',
            '--',
            url,
          ],
        );
        if (result.exitCode == 0 && (result.stdout as String).isNotEmpty) {
          return result.stdout as String;
        }
      } catch (_) {}
    }

    final response = await _client.get(
      Uri.parse(url),
      headers: _defaultHeaders,
    );
    return response.body;
  }

  /// The id of the search result whose title best matches one of [titles],
  /// or null when none does.
  @visibleForTesting
  static String? pickBestResult(
    List<Map<String, String>> results,
    List<String> titles,
  ) {
    String? best;
    var bestScore = 0;
    for (final r in results) {
      for (final wanted in titles) {
        final score = titleMatchScore(wanted, r['title'] ?? '');
        if (score > bestScore) {
          best = r['id'];
          bestScore = score;
        }
      }
    }
    return best;
  }

  /// The episode numbered [number], or null when the list has none.
  @visibleForTesting
  static AniDbEpisode? findEpisode(List<AniDbEpisode> episodes, int number) {
    for (final e in episodes) {
      if (e.number == number) return e;
    }
    return null;
  }

  /// Searches AniDB for a matching anime and returns its slug identifier.
  Future<String?> mapAnime({
    required List<String> titleCandidates,
  }) async {
    final uniqueTitles = <String>[];
    final seen = <String>{};

    for (final t in titleCandidates) {
      final clean = t.trim().toLowerCase();
      if (clean.isNotEmpty && seen.add(clean)) {
        uniqueTitles.add(t.trim());
      }
    }

    if (uniqueTitles.isEmpty) return null;

    final cacheKey = uniqueTitles.first.toLowerCase();
    if (_slugCache.containsKey(cacheKey)) {
      return _slugCache[cacheKey];
    }

    for (final title in uniqueTitles) {
      try {
        final searchUrl = '$baseUrl/search/suggestions?q=${Uri.encodeComponent(title)}';
        final html = await _fetch(searchUrl);

        if (html.isNotEmpty) {
          final doc = html_parser.parse(html);
          final links = doc.querySelectorAll("a[href*='/anime/']");
          final results = <Map<String, String>>[];

          for (final el in links) {
            final href = el.attributes['href'] ?? '';
            final itemTitle = el.querySelector('p')?.text.trim() ??
                el.attributes['title'] ??
                el.text.trim();

            if (href.isNotEmpty && itemTitle.isNotEmpty) {
              final match = RegExp(r'/anime/([a-z0-9-]+-[0-9]+)', caseSensitive: false)
                  .firstMatch(href);
              if (match != null) {
                results.add({'id': match.group(1)!, 'title': itemTitle});
              }
            }
          }

          // Fallback to browse if suggestions empty
          if (results.isEmpty) {
            final browseUrl = '$baseUrl/browse?q=${Uri.encodeComponent(title)}';
            final browseHtml = await _fetch(browseUrl);

            if (browseHtml.isNotEmpty) {
              final browseDoc = html_parser.parse(browseHtml);
              final browseLinks = browseDoc.querySelectorAll("a[href*='/anime/']");

              for (final el in browseLinks) {
                final href = el.attributes['href'] ?? '';
                final itemTitle = el.attributes['title'] ??
                    el.querySelector('h3, p, span')?.text.trim() ??
                    el.text.trim();

                if (href.isNotEmpty && itemTitle.isNotEmpty) {
                  final match = RegExp(r'/anime/([a-z0-9-]+-[0-9]+)', caseSensitive: false)
                      .firstMatch(href);
                  if (match != null) {
                    results.add({'id': match.group(1)!, 'title': itemTitle});
                  }
                }
              }
            }
          }

          // No first-result fallback: when nothing names the title, try the
          // next candidate title rather than play an unrelated show.
          final slug = pickBestResult(results, uniqueTitles);
          if (slug != null) {
            _slugCache[cacheKey] = slug;
            return slug;
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[AniDb] Error searching for $title: $e');
      }
    }

    return null;
  }

  /// Gets episode list for an AniDB anime slug.
  Future<List<AniDbEpisode>?> getEpisodes(String providerId) async {
    if (providerId.isEmpty) return null;
    if (_episodesCache.containsKey(providerId)) {
      return _episodesCache[providerId];
    }

    try {
      final numericId = providerId.split('-').last;
      if (numericId.isEmpty) return null;

      final episodesUrl = '$baseUrl/api/frontend/anime/$numericId/episodes';
      final jsonStr = await _fetch(episodesUrl);

      if (jsonStr.isNotEmpty) {
        final data = jsonDecode(jsonStr);
        if (data is Map && data['episodes'] is List) {
          final list = (data['episodes'] as List).map((ep) {
            final numVal = ep['number'];
            // -1, not 1: an unreadable number must never pass as episode 1.
            final num = numVal is int ? numVal : int.tryParse(numVal.toString()) ?? -1;
            return AniDbEpisode(
              number: num,
              id: ep['id'].toString(),
            );
          }).toList();

          list.sort((a, b) => a.number.compareTo(b.number));
          _episodesCache[providerId] = list;
          return list;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AniDb] Error fetching episodes: $e');
    }

    return null;
  }

  /// Scrapes the video stream for an episode in SUB or DUB category.
  Future<AniDbResult?> scrapeEpisodeStream({
    required String providerId,
    required int episodeNumber,
    required String category, // 'sub' or 'dub'
  }) async {
    try {
      final episodes = await getEpisodes(providerId);
      if (episodes == null || episodes.isEmpty) return null;

      // Exact episode only: falling back to the first one played episode 1
      // for any episode the site has not listed.
      final ep = findEpisode(episodes, episodeNumber);
      if (ep == null) return null;

      final languagesUrl = '$baseUrl/api/frontend/episode/${ep.id}/languages';
      final langJsonStr = await _fetch(languagesUrl);
      if (langJsonStr.isEmpty) return null;

      final langData = jsonDecode(langJsonStr);
      if (langData is! Map || langData['languages'] is! List) return null;

      final languages = (langData['languages'] as List).cast<Map<String, dynamic>>();
      if (languages.isEmpty) return null;

      Map<String, dynamic>? targetLang;
      if (category.toLowerCase() == 'dub') {
        targetLang = languages.firstWhere(
          (l) =>
              l['code'] == 'eng' ||
              (l['name']?.toString().toLowerCase().contains('english') == true) ||
              (l['name']?.toString().toLowerCase().contains('dub') == true),
          orElse: () => <String, dynamic>{},
        );
      } else {
        targetLang = languages.firstWhere(
          (l) =>
              l['code'] == 'jpn' ||
              (l['name']?.toString().toLowerCase().contains('japanese') == true) ||
              (l['name']?.toString().toLowerCase().contains('sub') == true),
          orElse: () => <String, dynamic>{},
        );
      }

      if (targetLang.isEmpty) {
        targetLang = languages.first;
      }

      final embedUrl = targetLang['embed_url']?.toString();
      if (embedUrl == null || embedUrl.isEmpty) return null;

      final embedHtml = await _fetch(embedUrl);
      if (embedHtml.isEmpty) return null;

      final fileMatch =
          RegExp(r'''file:\s*['"]([^'"]+)['"]''').firstMatch(embedHtml);
      if (fileMatch == null || fileMatch.group(1) == null) return null;

      final masterUrl = fileMatch.group(1)!;
      return AniDbResult(
        url: masterUrl,
        quality: 'auto',
        category: category.toLowerCase(),
        headers: {
          'Referer': '$baseUrl/',
          'Origin': baseUrl,
          'User-Agent': _userAgent,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AniDb] Scrape error: $e');
      return null;
    }
  }

  /// Convenience extractor integrating title mapping, episode lookup, and scraping.
  Future<AniDbResult?> extract({
    required List<String> titleCandidates,
    required int episodeNumber,
    required String category, // 'sub' or 'dub'
  }) async {
    final slug = await mapAnime(titleCandidates: titleCandidates);
    if (slug == null) return null;
    return scrapeEpisodeStream(
      providerId: slug,
      episodeNumber: episodeNumber,
      category: category,
    );
  }
}
