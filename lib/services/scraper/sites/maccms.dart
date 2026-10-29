import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../models/stream/stream_model.dart';
import '../../content/adult_guard.dart';
import '../../metadata/localized_meta.dart';
import '../../metadata/tmdb_service.dart';
import '../stream_scraper.dart';

/// One 苹果CMS v10 采集 site: a name for the source row and its API.
class MacCmsSite {
  const MacCmsSite(this.name, this.api);

  final String name;
  final String api;
}

/// Chinese-language 资源站 that speak the 苹果CMS v10 采集 API: films, dramas,
/// donghua, variety and short dramas, searched by their Chinese title, so a
/// new donghua that has no IMDb id is found as readily as anything else.
///
/// The list is the overlap of the open-source players that publish one
/// (LibreTV, KatelyaTV, hafrey1/LunaTV-config) and that the latter's daily
/// health report shows answering. All free; none needs a key.
class MacCmsScraper extends StreamScraper {
  MacCmsScraper({this.animationOnly = false});
  final bool animationOnly;
  @override
  String get name => 'ZPlayHTTP';

  @override
  String get providerName => '中文资源站';

  static const sites = <MacCmsSite>[
    MacCmsSite('非凡', 'https://api.ffzyapi.com/api.php/provide/vod'),
    MacCmsSite('量子', 'https://cj.lziapi.com/api.php/provide/vod'),
    MacCmsSite('暴风', 'https://bfzyapi.com/api.php/provide/vod'),
    MacCmsSite('如意', 'https://cj.rycjapi.com/api.php/provide/vod'),
    MacCmsSite('最大', 'https://api.zuidapi.com/api.php/provide/vod'),
    MacCmsSite('无尽', 'https://api.wujinapi.me/api.php/provide/vod'),
    MacCmsSite('极速', 'https://jszyapi.com/api.php/provide/vod'),
    MacCmsSite('iKun', 'https://ikunzyapi.com/api.php/provide/vod'),
    MacCmsSite('360', 'https://360zyzz.com/api.php/provide/vod'),
    MacCmsSite('爱奇艺资源', 'https://iqiyizyapi.com/api.php/provide/vod'),
    MacCmsSite('红牛', 'https://www.hongniuzy2.com/api.php/provide/vod'),
    MacCmsSite('魔都动漫', 'https://caiji.moduapi.cc/api.php/provide/vod'),
    MacCmsSite('樱花', 'https://m3u8.apiyhzy.com/api.php/provide/vod'),
  ];

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'Accept': 'application/json',
  };

  static const _timeout = Duration(seconds: 8);

  @visibleForTesting
  static http.Client client = http.Client();

  /// Categories these sites file adult material under. Withheld unless the
  /// viewer is allowed it, like every other adult path in the app.
  static const _adultTypes = [
    '伦理',
    '福利',
    '擦边',
    '里番',
    '写真',
    '无码',
    '有码',
    '三级',
    '情色',
    '色情',
    '同性',
    '主播',
    '自拍',
    '偷拍',
    '传媒',
  ];

  @override
  Stream<StreamSource> scrapeStream({
    required String type,
    required String title,
    int? year,
    int? season,
    int? episode,
    String? imdbId,
  }) async* {
    final names = await _searchNames(title, imdbId, type);
    if (names.isEmpty) return;
    final series = type == 'series' || type == 'tv' || type == 'anime';

    final found = StreamController<StreamSource>();
    var pending = sites.length;
    for (final site in sites) {
      _searchSite(
            site,
            names,
            series: series,
            year: year,
            season: season,
            episode: episode,
          )
          .then((sources) {
            if (!found.isClosed) {
              for (final source in sources) {
                found.add(source);
              }
            }
          })
          .whenComplete(() {
            if (--pending == 0) found.close();
          });
    }
    yield* found.stream;
  }

  /// The names to search under: the Chinese one first (what these sites
  /// file under), then the title as given.
  static Future<List<String>> _searchNames(
    String title,
    String? imdbId,
    String type,
  ) async {
    final names = <String>[];
    if (imdbId != null && imdbId.startsWith('tt')) {
      try {
        final local = await LocalizedMeta.forImdbId(
          imdbId,
          series: type != 'movie',
        ).timeout(const Duration(seconds: 6));
        final zh = local?.name?.trim();
        if (zh != null && zh.isNotEmpty) names.add(zh);
      } catch (_) {}
    } else if (imdbId != null && imdbId.startsWith('tmdb:')) {
      // A TMDb-only title comes with the viewer's-language name, English
      // for an English UI: ask TMDb for the Chinese one.
      try {
        final zh = await _tmdbChineseName(
          imdbId,
        ).timeout(const Duration(seconds: 6));
        if (zh != null) names.add(zh);
      } catch (_) {}
    }
    final t = title.trim();
    if (t.isNotEmpty && !names.contains(t)) names.add(t);
    return names;
  }

  /// The zh-CN name TMDb gives a `tmdb:kind:id` title, else its original
  /// name when that is Chinese; null when neither is.
  static Future<String?> _tmdbChineseName(String id) async {
    final parts = id.split(':');
    if (parts.length < 3 || (parts[1] != 'movie' && parts[1] != 'tv')) {
      return null;
    }
    final tmdbId = int.tryParse(parts[2]);
    if (tmdbId == null) return null;
    final body = await TmdbService.getScraperJson('/${parts[1]}/$tmdbId', {
      'language': 'zh-CN',
    });
    if (body == null) return null;
    const keys = ['title', 'name', 'original_title', 'original_name'];
    for (final key in keys) {
      final v = body[key]?.toString().trim() ?? '';
      if (v.isNotEmpty && _hasCjk(v)) return v;
    }
    return null;
  }

  static bool _hasCjk(String s) => RegExp(r'[一-鿿]').hasMatch(s);

  Future<List<StreamSource>> _searchSite(
    MacCmsSite site,
    List<String> names, {
    required bool series,
    int? year,
    int? season,
    int? episode,
  }) async {
    for (final query in names) {
      try {
        final uri = Uri.parse(
          site.api,
        ).replace(queryParameters: {'ac': 'videolist', 'wd': query});
        final res = await client.get(uri, headers: _headers).timeout(_timeout);
        if (res.statusCode != 200) continue;
        final body = jsonDecode(
          utf8.decode(res.bodyBytes, allowMalformed: true),
        );
        final list = body is Map ? body['list'] : null;
        if (list is! List) continue;
        final items = pickAll(
          list,
          query,
          series: series,
          year: year,
          season: season,
          animationOnly: animationOnly,
        );
        final sources = <StreamSource>[];
        for (final item in items) {
          final url = playUrlFor(
            item['vod_play_url']?.toString() ?? '',
            series: series,
            episode: episode,
          );
          if (url == null) continue;
          final vodName = item['vod_name']?.toString() ?? query;
          final remarks = item['vod_remarks']?.toString().trim() ?? '';
          sources.add(
            StreamSource(
              addonName: 'ZPlayHTTP',
              name: site.name,
              title: '$vodName${remarks.isEmpty ? '' : ' · $remarks'}',
              url: url,
              description: '${site.name} · HLS',
              providerId: 'maccms',
              providerName: '中文资源站',
            ),
          );
        }
        if (sources.isNotEmpty) return sources;
      } catch (e) {
        debugPrint('[MacCms] ${site.name}: $e');
      }
    }
    return [];
  }

  /// The listing that is the title asked for, or null.
  ///
  /// The name has to match once punctuation and spaces are gone, allowing a
  /// season suffix for a later season ("凡人修仙传 第二季", "斗罗大陆2"). A
  /// film has to be filed under a film category and a series under any other;
  /// a year, when both sides give one, has to agree within a year (first
  /// seasons and films only - a later season airs later).
  @visibleForTesting
  static Map? pick(
    List list,
    String query, {
    required bool series,
    int? year,
    int? season,
  }) {
    final matches = pickAll(
      list,
      query,
      series: series,
      year: year,
      season: season,
    );
    return matches.isEmpty ? null : matches.first;
  }

  @visibleForTesting
  static List<Map> pickAll(
    List list,
    String query, {
    required bool series,
    int? year,
    int? season,
    bool animationOnly = false,
  }) {
    final want = _matchName(query);
    if (want.isEmpty) return [];
    final s = season ?? 1;
    final best = <Map>[];
    var bestScore = 0;
    for (final raw in list) {
      if (raw is! Map) continue;
      final name = raw['vod_name']?.toString() ?? '';
      final typeName = raw['type_name']?.toString() ?? '';
      if (animationOnly &&
          !RegExp(r'动漫|動畫|动画|anime', caseSensitive: false).hasMatch(typeName)) {
        continue;
      }
      if (!AdultGuard.allowed &&
          (_adultTypes.any(typeName.contains) ||
              AdultGuard.looksAdult([name, typeName], flagged: false))) {
        continue;
      }
      // Any 片 category is a film (动画片 included); a 纪录片 listing can
      // also be a documentary series.
      final isFilm =
          typeName.endsWith('片') ||
          typeName.contains('电影') ||
          typeName.contains('電影');
      final isDoc = typeName.contains('纪录');
      if (typeName.isNotEmpty && (series ? isFilm && !isDoc : !isFilm)) {
        continue;
      }

      final got = _matchName(name);
      // A film has no seasons, and a title that itself ends in a number
      // ("流浪地球2") is not that number's season.
      final tagged = !series || got == want ? null : seasonOf(name);
      var score = 0;
      if (!series) {
        score = got == want ? 3 : 0;
      } else if (got == want && (s == 1 || seasonOf(query) == s)) {
        // An untagged listing is the first season, never a later one.
        score = 3;
      } else if (got.startsWith(want) && tagged == s && s > 1) {
        score = 3;
      } else if (got.startsWith(want) && tagged == 1 && s == 1) {
        score = 2;
      }
      if (score == 0) continue;

      final y = int.tryParse(raw['vod_year']?.toString() ?? '');
      if (year != null &&
          y != null &&
          y > 0 &&
          s == 1 &&
          (y - year).abs() > 1) {
        continue;
      }
      if (score > bestScore) {
        best.clear();
        bestScore = score;
      }
      if (score == bestScore) best.add(raw);
    }
    return best;
  }

  static bool _isHttp(String url) =>
      RegExp(r'^https?://', caseSensitive: false).hasMatch(url);

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s\p{P}\p{S}]+', unicode: true), '');

  static String _matchName(String name) =>
      _norm(name).replaceFirst(RegExp(r'(国语|粤语|普通话|国語|粵語)版?$'), '');

  static const _cnDigits = '零一二三四五六七八九';

  /// The season a listing names: 第二季, 第2季, or a trailing number
  /// ("斗罗大陆2"); null when it names none.
  static int? seasonOf(String name) {
    final m = RegExp(r'第\s*([0-9]+|[一二两三四五六七八九十]+)\s*[季部]').firstMatch(name);
    if (m != null) return _number(m.group(1)!);
    final tail = RegExp(r'(?<![0-9])([2-9])$').firstMatch(name.trim());
    if (tail != null) return int.parse(tail.group(1)!);
    return null;
  }

  static int? _number(String s) {
    final n = int.tryParse(s);
    if (n != null) return n;
    final t = s.replaceAll('两', '二');
    if (t == '十') return 10;
    if (t.startsWith('十')) return 10 + _cnDigits.indexOf(t.substring(1));
    if (t.contains('十')) {
      final parts = t.split('十');
      return _cnDigits.indexOf(parts[0]) * 10 +
          (parts[1].isEmpty ? 0 : _cnDigits.indexOf(parts[1]));
    }
    final i = _cnDigits.indexOf(t);
    return i <= 0 ? null : i;
  }

  /// The episode's stream from a `vod_play_url`: groups split by `$$$`,
  /// episodes by `#`, each `name$url`. The m3u8 group is preferred; the
  /// episode is found by the number in its name (第03集, 03, EP3), then by
  /// position. Only an http(s) entry is ever returned.
  @visibleForTesting
  static String? playUrlFor(
    String playUrl, {
    required bool series,
    int? episode,
  }) {
    if (playUrl.isEmpty) return null;
    final groups = [
      for (final g in playUrl.split(r'$$$'))
        [
          for (final e in g.split('#'))
            if (e.contains(r'$'))
              (
                e.substring(0, e.indexOf(r'$')).trim(),
                e.substring(e.indexOf(r'$') + 1).trim(),
              ),
        ],
    ].where((g) => g.any((e) => _isHttp(e.$2))).toList();
    if (groups.isEmpty) return null;
    groups.sort(
      (a, b) => (b.any((e) => e.$2.contains('.m3u8')) ? 1 : 0).compareTo(
        a.any((e) => e.$2.contains('.m3u8')) ? 1 : 0,
      ),
    );
    if (!series) {
      for (final group in groups) {
        final url = group.where((e) => _isHttp(e.$2)).firstOrNull?.$2;
        if (url != null) return url;
      }
      return null;
    }
    final want = episode ?? 1;
    if (want < 1) return null;
    for (final group in groups) {
      int? number(String label) {
        final episodeMatch = RegExp(
          r'(?:第\s*(\d+)\s*集|[Ee][Pp]?\s*(\d+)|^\s*(\d+)\s*$)',
        ).firstMatch(label);
        final n =
            episodeMatch?.group(1) ??
            episodeMatch?.group(2) ??
            episodeMatch?.group(3);
        return n == null ? null : int.tryParse(n);
      }

      for (final entry in group) {
        if (number(entry.$1) == want && _isHttp(entry.$2)) return entry.$2;
      }
      // Only unnumbered lists can safely use positional lookup.
      if (group.every((e) => !RegExp(r'\d').hasMatch(e.$1)) &&
          want <= group.length) {
        final url = group[want - 1].$2;
        if (_isHttp(url)) return url;
      }
    }
    return null;
  }
}
