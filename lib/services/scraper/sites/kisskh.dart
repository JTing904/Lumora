import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../stream_scraper.dart';
import '../../../models/stream/stream_model.dart';
import 'tmdb_helper.dart';

/// Pure-Dart KissKH Stream Scraper for ZPlayHTTP.
///
/// Ported 1-to-1 from Vyla KissKH provider.
/// Resolves Asian dramas and shows from kisskh.do via enc-dec.app decryption.
class KissKhScraper extends StreamScraper {
  @override
  String get name => 'ZPlayHTTP';

  static const _encApi = 'https://enc-dec.app/api';
  static const _base = 'https://kisskh.do';
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  static const _headers = {
    'User-Agent': _ua,
    'Accept': 'application/json',
  };

  static String _cleanTitle(String t) {
    return t.toLowerCase().replaceAll(RegExp(r'\(\d{4}\)'), '').replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// How strongly [itemTitle] identifies [title]; 0 means it names nothing the
  /// caller asked for. Kept at 0 rather than -1 so a result list that scores
  /// all zeros resolves to nothing instead of handing back whichever drama
  /// the search happened to rank first.
  static int _scoreTitleMatch(String target, String itemTitle) {
    final targetClean = _cleanTitle(target);
    // Alternate names are separated by a spaced dash ("Title - Other Title").
    // A bare hyphen is part of a word: splitting "Spider-Man" on it left a
    // "spider" part that every Spider- title contains, and the 8-episode
    // Spider-Noir series played for the Spider-Man film.
    final names = itemTitle.split(RegExp(r'\s+-\s+'));
    final parts = names.map(_cleanTitle).where((p) => p.isNotEmpty);

    if (parts.any((p) => p == targetClean)) return 5;
    // One name inside the other, only when the shorter is most of the longer:
    // "Mortal's Journey" inside "Mortal's Journey Season 2", not "spider"
    // inside "spidermanbrandnewday".
    bool contains(String long, String short) =>
        long.contains(short) && short.length >= long.length * 0.7;
    if (parts.any((p) => contains(p, targetClean) || contains(targetClean, p))) {
      return 3;
    }
    // Every significant word of the request appears in one of the listing's
    // names, in any order: "A Mortal's Journey" against KissKH's "A Record of
    // Mortal's Journey to Immortality Season 3".
    final wanted = _words(target)..removeAll(_fillerWords);
    if (wanted.isNotEmpty && names.any((n) => _words(n).containsAll(wanted))) {
      return 2;
    }
    return 0;
  }

  static const _fillerWords = {'a', 'an', 'the', 'of', 'to', 'and'};

  static Set<String> _words(String t) => RegExp(r'[a-z0-9]+')
      .allMatches(
        t.toLowerCase().replaceAll("'", '').replaceAll(RegExp(r'\(\d{4}\)'), ''),
      )
      .map((m) => m.group(0)!)
      .toSet();

  /// The season a listing names ("Season 3", "3rd Season", even "2th
  /// Season"), or null when it names none - which on KissKH is the first.
  @visibleForTesting
  static int? seasonOf(String title) {
    final match = RegExp(
      r'season\s*(\d+)|(\d+)\s*(?:st|nd|rd|th)\s+season',
      caseSensitive: false,
    ).firstMatch(title);
    final digits = match?.group(1) ?? match?.group(2);
    return digits == null ? null : int.tryParse(digits);
  }

  /// Every listing that names [title], best first: the requested season ahead
  /// of the others, then the stronger title match.
  @visibleForTesting
  static List<Map> rankDramas(List<dynamic> results, String title, {int? season}) {
    final wantSeason = season ?? 1;
    final scored = <(Map, int, bool)>[];
    for (final item in results) {
      if (item is! Map) continue;
      final itemTitle = item['title']?.toString() ?? '';
      final score = _scoreTitleMatch(title, itemTitle);
      if (score == 0) continue;
      final tagged = seasonOf(itemTitle);
      scored.add((item, score, (tagged ?? 1) == wantSeason));
    }
    scored.sort((a, b) {
      if (a.$3 != b.$3) return a.$3 ? -1 : 1;
      return b.$2.compareTo(a.$2);
    });
    return [for (final s in scored) s.$1];
  }

  /// Whether a KissKH detail is the kind of title that was asked for.
  ///
  /// KissKH files the 2020 donghua and the 2025 live-action drama of "A Record
  /// of a Mortal's Journey to Immortality" under near-identical names; its
  /// `type` (`Anime`, `TVSeries`, `Movie`) and the "(Live Action)" tag are what
  /// tell them apart. With no facts from TMDb only the movie/series split is
  /// checked.
  @visibleForTesting
  static bool fitsRequest(
    Map detail, {
    required String type,
    TitleFacts? facts,
    int? year,
  }) {
    final kind = detail['type']?.toString().toLowerCase() ?? '';
    final title = detail['title']?.toString().toLowerCase() ?? '';
    final isAnime = kind == 'anime' && !title.contains('live action');
    if (facts != null && facts.isAnimation != isAnime) return false;
    if (type == 'movie' && kind == 'tvseries') return false;
    // KissKH files Hollywood films and series under one `type`, so a film is
    // told apart by having one episode.
    final episodes = detail['episodes'];
    if (type == 'movie' && episodes is List && episodes.length > 1) {
      return false;
    }
    // A year in the listing's name ("Spider-Noir (2026)") has to be the year
    // asked for, give or take one for festival and regional releases.
    final tagged = RegExp(r'\((\d{4})\)').firstMatch(title)?.group(1);
    final wantYear = year ?? facts?.year;
    if (tagged != null && wantYear != null) {
      if ((int.parse(tagged) - wantYear).abs() > 1) return false;
    }
    return true;
  }

  /// The best-scoring drama for [title], or null when no result names it.
  static Map? pickBestDrama(List<dynamic> results, String title) {
    final ranked = rankDramas(results, title);
    return ranked.isEmpty ? null : ranked.first;
  }

  Future<String?> _encKey(http.Client client, dynamic episodeId, String type) async {
    try {
      final res = await client.get(
        Uri.parse('$_encApi/enc-kisskh?text=$episodeId&type=$type'),
        headers: {'User-Agent': _ua, 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 200) {
          return data['result']?.toString();
        }
      }
    } catch (_) {}
    return null;
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
    try {
      final client = http.Client();
      try {
        final searchRes = await client.get(
          Uri.parse('$_base/api/DramaList/Search?q=${Uri.encodeComponent(title)}'),
          headers: _headers,
        ).timeout(const Duration(seconds: 6));

        if (searchRes.statusCode != 200) return;
        final results = jsonDecode(searchRes.body);
        if (results is! List || results.isEmpty) return;

        final facts = await TmdbHelper.titleFacts(
          imdbId: imdbId,
          title: title,
          type: type,
          year: year,
        );
        final targetEpNum = episode ?? 1;

        // The first listing that is the right kind of title and actually has
        // the requested episode. A listing missing the episode is skipped, not
        // answered with its first episode: that played episode 1 of whatever
        // matched, which is a wrong stream that looks like a right one.
        Map? detail;
        Map? epMatch;
        for (final drama in rankDramas(results, title, season: season).take(6)) {
          final dramaId = drama['id'];
          if (dramaId == null) continue;
          final detailRes = await client.get(
            Uri.parse('$_base/api/DramaList/Drama/$dramaId'),
            headers: _headers,
          ).timeout(const Duration(seconds: 8));
          if (detailRes.statusCode != 200) continue;
          final candidate = jsonDecode(detailRes.body);
          if (candidate is! Map || candidate['episodes'] is! List) continue;
          if (!fitsRequest(candidate, type: type, facts: facts, year: year)) {
            continue;
          }

          for (final ep in candidate['episodes'] as List) {
            if (ep is Map && (ep['number'] as num?)?.toInt() == targetEpNum) {
              epMatch = ep;
              break;
            }
          }
          if (epMatch != null) {
            detail = candidate;
            break;
          }
        }

        if (detail == null || epMatch == null || epMatch['id'] == null) return;
        final episodeId = epMatch['id'];
        final kindLabel =
            detail['type']?.toString().toLowerCase() == 'anime' ? 'Anime' : 'Drama';

        final vidKey = await _encKey(client, episodeId, 'vid');
        if (vidKey == null || vidKey.isEmpty) return;

        final videoRes = await client.get(
          Uri.parse('$_base/api/DramaList/Episode/$episodeId.png?err=false&ts=&time=&kkey=$vidKey'),
          headers: _headers,
        ).timeout(const Duration(seconds: 10));

        if (videoRes.statusCode != 200) return;
        final videoData = jsonDecode(videoRes.body);
        if (videoData is! Map || videoData['Video'] == null) return;

        final streamUrl = videoData['Video'].toString();
        if (streamUrl.isEmpty) return;

        final isHls = streamUrl.contains('.m3u8');
        final reqHeaders = {
          'User-Agent': _ua,
          'Referer': '$_base/',
        };

        yield StreamSource(
          name: 'ZPlayHTTP',
          addonName: 'ZPlayHTTP',
          title: 'KissKH · $kindLabel · 1080p',
          description: 'KissKH Stream · ${isHls ? 'HLS' : 'MP4'}',
          url: streamUrl,
          headers: reqHeaders,
          behaviorHints: {
            'notWebReady': false,
            'proxyHeaders': {
              'request': reqHeaders,
            },
          },
        );
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[KissKhScraper] error: $e');
    }
  }
}
