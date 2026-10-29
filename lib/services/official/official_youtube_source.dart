/// Finds a picked episode (or film) among the full uploads of the rights
/// holders' own YouTube channels ([OfficialChannels]).
///
/// What it does, and what it never does:
/// * It **searches**: YouTube's InnerTube `search` and channel-`browse`
///   endpoints, the same public endpoints the YouTube website calls, with no
///   API key in the app. It reads titles, lengths and channel ids.
/// * It checks each pick with YouTube's public oEmbed endpoint, which answers
///   401/403 for a video whose owner turned embedding off and 404 for one that
///   is gone, so the list never offers a row that cannot play.
/// * It never fetches a stream, a manifest or a player response. Playback is
///   YouTube's own embedded player (`OfficialYouTubePlayer`), so the
///   channel's ads, geo-blocks and view counts all stay the channel's.
/// * Anything uploaded by a channel that is not on the whitelist is dropped,
///   whatever its title says.
///
/// Every failure - offline, a timeout, YouTube changing its JSON - ends in an
/// empty list. The source list simply does not show the row.
///
/// Pure Dart (no Flutter import), so the live check in `test/live` and the
/// unit tests can drive it directly.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'official_channels.dart';
import 'official_episode_matcher.dart';

class OfficialYouTubeSource {
  OfficialYouTubeSource({http.Client? client, DateTime Function()? clock})
    : _client = client,
      _clock = clock ?? DateTime.now;

  /// The app's shared instance, so its cache outlives a watch screen.
  static final OfficialYouTubeSource instance = OfficialYouTubeSource();

  /// `StreamSource.providerId` of a row this source produced.
  static const String providerId = 'official-youtube';

  static const Duration hitTtl = Duration(hours: 4);
  static const Duration missTtl = Duration(hours: 1);
  static const Duration requestTimeout = Duration(seconds: 8);
  static const Duration overallTimeout = Duration(seconds: 20);

  /// Channels searched one by one when the global search did not settle it.
  static const int maxChannelSearches = 3;

  static const String _clientVersion = '2.20250217.03.00';
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36';

  /// The channel-search tab of a channel's `browse` page.
  static const String _channelSearchParams = 'EgZzZWFyY2jyBgQKAloA';

  final http.Client? _client;
  final DateTime Function() _clock;

  final Map<String, ({DateTime at, List<OfficialMatch> matches})> _cache = {};
  final Map<String, Future<List<OfficialMatch>>> _inFlight = {};

  /// The watch URL of [videoId], which a row carries as its external URL.
  static String watchUrl(String videoId) =>
      'https://www.youtube.com/watch?v=$videoId';

  /// Matches for [query], best first; empty when there are none or anything
  /// failed. [region] is the viewer's ISO country code (`MY`), used both as
  /// YouTube's `gl` and to skip channels that do not play there.
  Future<List<OfficialMatch>> find(
    OfficialQuery query, {
    String? region,
  }) async {
    final names = OfficialEpisodeMatcher.usableNames(query.names);
    if (names.isEmpty) return const <OfficialMatch>[];
    final key = [
      ...names.map(OfficialEpisodeMatcher.normalise),
      query.season,
      query.episode,
      query.previousSeasonsEpisodes,
      region,
    ].join('|');

    final cached = _cache[key];
    if (cached != null) {
      final ttl = cached.matches.isEmpty ? missTtl : hitTtl;
      if (_clock().difference(cached.at) < ttl) return cached.matches;
      _cache.remove(key);
    }
    final running = _inFlight[key];
    if (running != null) return running;

    final future = () async {
      try {
        final run = _Run();
        final found = await runZoned(
          () => _find(query, names, region),
          zoneValues: {_Run: run},
        ).timeout(overallTimeout);
        // A miss is only remembered when every request was answered: an
        // empty list from a dropped connection must not hide the row for an
        // hour.
        if (found.isNotEmpty || !run.failed) {
          _cache[key] = (at: _clock(), matches: found);
        }
        return found;
      } catch (_) {
        // Offline, timed out, or YouTube answered something unexpected. Not
        // cached, so the next open tries again.
        return const <OfficialMatch>[];
      } finally {
        _inFlight.remove(key);
      }
    }();
    _inFlight[key] = future;
    return future;
  }

  Future<List<OfficialMatch>> _find(
    OfficialQuery query,
    List<String> names,
    String? region,
  ) async {
    final allowed = {
      for (final c in OfficialChannels.availableIn(region)) c.id,
    };
    final searchNames = _searchNames(names);
    final numbers = <int?>[
      if (query.isMovie) null,
      if (query.absoluteEpisode != null) query.absoluteEpisode,
      if (!query.isMovie) query.episode,
    ];

    final uploads = <OfficialUpload>[];

    // 1. One global search per name and number. Official channels usually
    //    rank on the first page for their own show.
    final global = await Future.wait([
      for (final name in searchNames)
        for (final n in numbers)
          _search(_queryText(name, n), hl: _hlFor(name), gl: region),
    ]);
    for (final batch in global) {
      uploads.addAll(batch);
    }

    var ranked = OfficialEpisodeMatcher.rank(
      uploads.where((u) => allowed.contains(u.channelId)),
      query,
    );

    // 2. Not settled: search inside the whitelisted channels that showed up
    //    for this show at all (the newest episode is often not on page one).
    if (!ranked.any((m) => m.kind != OfficialMatchKind.compilation)) {
      var channels = _channelsCarrying(uploads, names, allowed);
      if (channels.isEmpty) {
        final discovery = await Future.wait([
          for (final name in searchNames)
            _search(name, hl: _hlFor(name), gl: region),
        ]);
        final seen = [for (final b in discovery) ...b];
        uploads.addAll(seen);
        channels = _channelsCarrying(seen, names, allowed);
      }
      final perChannel = await Future.wait([
        for (final channel in channels.take(maxChannelSearches))
          for (final name in searchNames)
            for (final n in numbers)
              _searchChannel(
                channel,
                _queryText(name, n),
                hl: _hlFor(name),
                gl: region,
              ),
      ]);
      for (final batch in perChannel) {
        uploads.addAll(batch);
      }
      ranked = OfficialEpisodeMatcher.rank(
        uploads.where((u) => allowed.contains(u.channelId)),
        query,
      );
    }

    // 3. Only offer what can actually be embedded.
    final playable = <OfficialMatch>[];
    for (final m in ranked) {
      if (await _embeddable(m.upload.videoId)) playable.add(m);
    }
    return playable;
  }

  /// At most one CJK and one Latin name: the search engine folds the rest.
  static List<String> _searchNames(List<String> names) {
    final cjk = names.where(_hasCjk).take(1);
    final latin = names.where((n) => !_hasCjk(n)).take(1);
    return [...cjk, ...latin];
  }

  static bool _hasCjk(String s) => RegExp(r'[぀-ヿ㐀-䶿一-鿿]').hasMatch(s);

  static String _hlFor(String name) => _hasCjk(name) ? 'zh-CN' : 'en';

  static String _queryText(String name, int? n) {
    if (n == null) return name;
    return _hasCjk(name) ? '$name 第$n集' : '$name episode $n';
  }

  /// Whitelisted channels that uploaded anything naming the show, in the
  /// whitelist's own order.
  static List<String> _channelsCarrying(
    Iterable<OfficialUpload> uploads,
    List<String> names,
    Set<String> allowed,
  ) {
    final hits = <String>{};
    for (final u in uploads) {
      if (!allowed.contains(u.channelId)) continue;
      if (names.any((n) => OfficialEpisodeMatcher.containsName(u.title, n))) {
        hits.add(u.channelId);
      }
    }
    return [
      for (final c in OfficialChannels.all)
        if (hits.contains(c.id)) c.id,
    ];
  }

  // ── InnerTube ─────────────────────────────────────────────────────────

  Future<List<OfficialUpload>> _search(
    String query, {
    required String hl,
    String? gl,
  }) async {
    final json = await _post('search', {'query': query}, hl: hl, gl: gl);
    return json == null ? const [] : parseResponse(json);
  }

  Future<List<OfficialUpload>> _searchChannel(
    String channelId,
    String query, {
    required String hl,
    String? gl,
  }) async {
    final json = await _post(
      'browse',
      {'browseId': channelId, 'params': _channelSearchParams, 'query': query},
      hl: hl,
      gl: gl,
    );
    return json == null
        ? const []
        : parseResponse(json, fallbackChannelId: channelId);
  }

  Future<Map<String, dynamic>?> _post(
    String endpoint,
    Map<String, Object?> body, {
    required String hl,
    String? gl,
  }) async {
    final uri = Uri.parse(
      'https://www.youtube.com/youtubei/v1/$endpoint?prettyPrint=false',
    );
    final payload = jsonEncode({
      ...body,
      'context': {
        'client': {
          'clientName': 'WEB',
          'clientVersion': _clientVersion,
          'hl': hl,
          'gl': (gl == null || gl.isEmpty) ? 'US' : gl.toUpperCase(),
        },
      },
    });
    final headers = {
      'Content-Type': 'application/json',
      'Accept-Language': hl == 'en' ? 'en-US,en;q=0.9' : 'zh-CN,zh;q=0.9',
      'User-Agent': _userAgent,
      'X-YouTube-Client-Name': '1',
      'X-YouTube-Client-Version': _clientVersion,
      'Origin': 'https://www.youtube.com',
    };
    try {
      final client = _client;
      final resp =
          await (client != null
                  ? client.post(uri, headers: headers, body: payload)
                  : http.post(uri, headers: headers, body: payload))
              .timeout(requestTimeout);
      if (resp.statusCode != 200) {
        _Run.markFailed();
        return null;
      }
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      _Run.markFailed();
      return null;
    }
  }

  /// Whether YouTube will play [videoId] in an embed.
  ///
  /// oEmbed answers 401/403 when the owner disabled embedding and 404 when the
  /// video is private or gone. Any other failure (offline, 5xx) is not proof
  /// of anything, so the row is kept and the player reports a real failure.
  Future<bool> _embeddable(String videoId) async {
    final uri = Uri.https('www.youtube.com', '/oembed', {
      'url': watchUrl(videoId),
      'format': 'json',
    });
    try {
      final client = _client;
      final resp = await (client != null ? client.get(uri) : http.get(uri))
          .timeout(requestTimeout);
      return !(resp.statusCode == 401 ||
          resp.statusCode == 403 ||
          resp.statusCode == 404);
    } catch (_) {
      _Run.markFailed();
      return true;
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────────

  /// Every `videoRenderer` in an InnerTube `search` or `browse` response.
  ///
  /// The tree is walked rather than followed by path: the two endpoints, and
  /// YouTube's layout experiments, nest the same renderer at different depths.
  /// [fallbackChannelId] is the browsed channel, for channel-search results
  /// that omit their owner.
  static List<OfficialUpload> parseResponse(
    Map<String, dynamic> json, {
    String? fallbackChannelId,
  }) {
    final out = <OfficialUpload>[];
    void walk(Object? node) {
      if (node is Map) {
        final renderer = node['videoRenderer'];
        if (renderer is Map) {
          final u = _parseRenderer(renderer, fallbackChannelId);
          if (u != null) out.add(u);
        }
        for (final v in node.values) {
          walk(v);
        }
      } else if (node is List) {
        for (final v in node) {
          walk(v);
        }
      }
    }

    walk(json);
    return out;
  }

  static OfficialUpload? _parseRenderer(Map renderer, String? fallback) {
    final id = renderer['videoId'];
    if (id is! String || !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) {
      return null;
    }
    final title = _text(renderer['title']);
    if (title == null || title.isEmpty) return null;

    String? channelId;
    String? channelName;
    for (final field in const [
      'ownerText',
      'longBylineText',
      'shortBylineText',
    ]) {
      final runs = (renderer[field] is Map) ? renderer[field]['runs'] : null;
      if (runs is List && runs.isNotEmpty && runs.first is Map) {
        final run = runs.first as Map;
        final nav = run['navigationEndpoint'];
        final browse = nav is Map ? nav['browseEndpoint'] : null;
        final cid = browse is Map ? browse['browseId'] : null;
        if (cid is String && cid.startsWith('UC')) {
          channelId = cid;
          channelName = run['text']?.toString();
          break;
        }
      }
    }
    channelId ??= fallback;
    if (channelId == null) return null;

    var membersOnly = false;
    var live = false;
    final badges = renderer['badges'];
    if (badges is List) {
      for (final b in badges) {
        final m = b is Map ? b['metadataBadgeRenderer'] : null;
        if (m is! Map) continue;
        final style = m['style']?.toString() ?? '';
        final label = (m['label'] ?? '').toString().toLowerCase();
        if (style.contains('MEMBERS_ONLY') ||
            label.contains('members only') ||
            label.contains('会员专享') ||
            label.contains('會員專屬')) {
          membersOnly = true;
        }
        if (style.contains('LIVE')) live = true;
      }
    }
    final overlays = renderer['thumbnailOverlays'];
    if (overlays is List) {
      for (final o in overlays) {
        final overlay = o is Map
            ? o['thumbnailOverlayTimeStatusRenderer']
            : null;
        final status = overlay is Map ? overlay['style'] : null;
        if (status == 'LIVE') live = true;
        if (status == 'SHORTS') return null;
      }
    }

    return OfficialUpload(
      videoId: id,
      title: title,
      channelId: channelId,
      channelName: channelName,
      duration: parseLength(_text(renderer['lengthText'])),
      membersOnly: membersOnly,
      live: live,
      upcoming: renderer['upcomingEventData'] != null,
    );
  }

  static String? _text(Object? node) {
    if (node is! Map) return null;
    final simple = node['simpleText'];
    if (simple is String) return simple;
    final runs = node['runs'];
    if (runs is List) {
      return runs
          .map((r) => r is Map ? (r['text']?.toString() ?? '') : '')
          .join();
    }
    return null;
  }

  /// `1:14:51` / `21:25` as a duration; null for anything else.
  static Duration? parseLength(String? text) {
    if (text == null) return null;
    final parts = text.trim().split(':');
    if (parts.length < 2 || parts.length > 3) return null;
    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null)) return null;
    if (nums.length == 2) {
      return Duration(minutes: nums[0]!, seconds: nums[1]!);
    }
    return Duration(hours: nums[0]!, minutes: nums[1]!, seconds: nums[2]!);
  }
}

/// One lookup's bookkeeping: whether any request went unanswered. Carried as
/// a zone value, so concurrent lookups for different episodes keep their own.
class _Run {
  bool failed = false;

  static void markFailed() {
    final run = Zone.current[_Run];
    if (run is _Run) run.failed = true;
  }
}
