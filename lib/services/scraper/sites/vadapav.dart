import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../stream_scraper.dart';
import '../../../models/stream/stream_model.dart';
import '../title_match.dart';
import 'tmdb_helper.dart';

/// Vadapav Stream Scraper for ZPlayHTTP.
///
/// Fetches direct HTTP streams from vadapav.mov Stremio addon:
/// https://stremio.vadapav.mov/manifest.json
/// Whether the release file [release] is [title]: every significant word of
/// the title is in the file name, and for a film whose file names a year,
/// that year is within one of [year].
@visibleForTesting
bool namesRequest(
  String release,
  String title, {
  int? year,
  required bool isTv,
}) {
  if (titleMatchScore(title, release) == 0) return false;
  if (isTv || year == null) return true;
  final years = RegExp(r'(?<!\d)(?:19|20)\d{2}(?!\d)')
      .allMatches(release)
      .map((m) => int.parse(m.group(0)!))
      .toList();
  return years.isEmpty || years.any((y) => (y - year).abs() <= 1);
}

class VadapavScraper extends StreamScraper {
  @override
  String get name => 'ZPlayHTTP';

  @override
  bool get followsTmdbEpisodes => true;

  static const _addonBase = 'https://stremio.vadapav.mov';

  static const _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
  };

  @override
  Stream<StreamSource> scrapeStream({
    required String type,
    required String title,
    int? year,
    int? season,
    int? episode,
    String? imdbId,
  }) {
    final controller = StreamController<StreamSource>();
    final isTv = (type == 'series' || type == 'tv');
    final mediaType = isTv ? 'tv' : 'movie';

    () async {
      try {
        final List<String> targetIds = [];

        // 1. If IMDB ID provided, add as primary query
        if (imdbId != null && imdbId.isNotEmpty && imdbId.startsWith('tt')) {
          targetIds.add(imdbId);
        }

        // 2. Resolve TMDb ID for TMDb query fallback
        final tmdbId = await TmdbHelper.resolveTmdbId(
          imdbId: imdbId,
          title: title,
          type: mediaType,
          year: year,
        );

        if (tmdbId != null && tmdbId > 0) {
          targetIds.add('tmdb:$tmdbId');
        }

        if (targetIds.isEmpty) {
          debugPrint('[Vadapav] No valid IMDB or TMDb ID for "$title"');
          controller.close();
          return;
        }

        final seenUrls = <String>{};

        for (final id in targetIds) {
          final String endpoint;
          if (isTv) {
            final s = season ?? 1;
            final e = episode ?? 1;
            endpoint = '$_addonBase/stream/series/$id:$s:$e.json';
          } else {
            endpoint = '$_addonBase/stream/movie/$id.json';
          }

          try {
            debugPrint('[Vadapav] Fetching streams from $endpoint');
            final res = await http
                .get(Uri.parse(endpoint), headers: _defaultHeaders)
                .timeout(const Duration(seconds: 12));

            if (res.statusCode == 200) {
              final data = jsonDecode(res.body);
              if (data is Map && data['streams'] is List) {
                final streams = data['streams'] as List;
                debugPrint('[Vadapav] Received ${streams.length} streams for $id');

                for (final item in streams) {
                  if (item is! Map) continue;
                  final map = Map<String, dynamic>.from(item);

                  final url = map['url']?.toString();
                  if (url == null || url.isEmpty || !url.startsWith('http')) {
                    continue;
                  }

                  if (seenUrls.contains(url)) continue;
                  seenUrls.add(url);

                  // Extract release title or name
                  final rawTitle = map['title']?.toString() ?? '';
                  final rawName = map['name']?.toString() ?? 'vadapav.mov';

                  // The addon answers an id it does not hold with a file it
                  // does: "The Lion King II (1998)" came back for 凡人修仙传,
                  // 斗破苍穹 and 繁花 alike. Only a file named for the request
                  // is offered.
                  if (!namesRequest(rawTitle, title, year: year, isTv: isTv)) {
                    debugPrint('[Vadapav] Dropped "$rawTitle": not "$title"');
                    continue;
                  }

                  final source = StreamSource(
                    name: rawName.isNotEmpty ? rawName : 'vadapav.mov',
                    title: rawTitle.isNotEmpty ? rawTitle : 'vadapav.mov • Direct Stream',
                    description: rawTitle,
                    url: url,
                    addonName: 'ZPlayHTTP',
                    headers: _defaultHeaders,
                    behaviorHints: map['behaviorHints'] is Map
                        ? Map<String, dynamic>.from(map['behaviorHints'])
                        : null,
                  );

                  if (!controller.isClosed) {
                    controller.add(source);
                  }
                }

                if (streams.isNotEmpty) {
                  break;
                }
              }
            }
          } catch (e) {
            debugPrint('[Vadapav] Error fetching from $endpoint: $e');
          }
        }
      } catch (e) {
        debugPrint('[Vadapav] Global scrape error: $e');
      } finally {
        if (!controller.isClosed) {
          controller.close();
        }
      }
    }();

    return controller.stream;
  }
}
