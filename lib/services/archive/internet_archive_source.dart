/// Public-domain and Creative Commons films from the Internet Archive
/// (archive.org), played as a plain MP4 in the app's own player.
///
/// What it accepts, and nothing else:
/// * an item in one of the Archive's curated film collections
///   ([curatedCollections] - Feature Films, Sci-Fi / Horror, Film Noir,
///   Silent Films ...), never the open "Community Video" uploads;
/// * whose `licenseurl` is a Creative Commons licence or a public-domain
///   mark / dedication ([licenceOf]) - checked on the search hit and again on
///   the item's own metadata;
/// * whose title is the film's title (after folding case, punctuation, a
///   leading article and a trailing "(1968)") and whose year is the film's
///   year exactly - no fuzzy matches, no trailers, no "colorized" or
///   "with Spanish subtitles" variants;
/// * that has a feature-length MP4 the Archive itself serves.
///
/// Both endpoints are public and need no key: `advancedsearch.php` and
/// `/metadata/{identifier}`. Every failure ends in an empty list.
///
/// Pure Dart (no Flutter import) so tests and the live check can drive it.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A licence the Archive item carries.
class ArchiveLicence {
  const ArchiveLicence({
    required this.url,
    required this.publicDomain,
    this.code,
  });

  final String url;

  /// A public-domain mark or CC0 dedication (as opposed to a CC licence).
  final bool publicDomain;

  /// The CC licence code (`BY`, `BY-SA`, `BY-NC-ND` ...), or null for a
  /// public-domain item.
  final String? code;
}

/// A search hit.
class ArchiveDoc {
  const ArchiveDoc({
    required this.identifier,
    required this.title,
    this.year,
    this.licenceUrl,
    this.downloads = 0,
    this.collections = const <String>[],
  });

  final String identifier;
  final String title;
  final int? year;
  final String? licenceUrl;
  final int downloads;
  final List<String> collections;
}

/// A playable film.
class ArchiveFilm {
  const ArchiveFilm({
    required this.identifier,
    required this.title,
    required this.year,
    required this.licence,
    required this.fileName,
    required this.format,
    this.sizeBytes,
    this.length,
  });

  final String identifier;
  final String title;
  final int year;
  final ArchiveLicence licence;
  final String fileName;
  final String format;
  final int? sizeBytes;
  final Duration? length;

  /// The MP4, served by the Archive (it redirects to a storage node).
  String get streamUrl =>
      'https://archive.org/download/${Uri.encodeComponent(identifier)}/'
      '${fileName.split('/').map(Uri.encodeComponent).join('/')}';

  /// The item's page, for attribution.
  String get pageUrl =>
      'https://archive.org/details/${Uri.encodeComponent(identifier)}';
}

class InternetArchiveSource {
  InternetArchiveSource({http.Client? client}) : _client = client;

  static final InternetArchiveSource instance = InternetArchiveSource();

  /// `StreamSource.providerId` of a row this source produced.
  static const String providerId = 'internet-archive';

  /// The Archive's own curated film collections. An item must be in one.
  static const List<String> curatedCollections = [
    'feature_films',
    'film_scifi',
    'SciFi_Horror',
    'Film_Noir',
    'silent_films',
    'Comedy_Films',
    'classic_cartoons',
    'vintage_cartoons',
    'prelinger',
  ];

  static const int maxResults = 2;
  static const int searchRows = 30;
  static const Duration minFeatureLength = Duration(minutes: 40);

  /// Originals larger than this are left for the Archive's own derivative.
  static const int maxFileBytes = 4 * 1024 * 1024 * 1024;

  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration overallTimeout = Duration(seconds: 20);

  final http.Client? _client;
  final Map<String, List<ArchiveFilm>> _cache = {};

  /// Films matching any of [titles] released in [year], best first.
  Future<List<ArchiveFilm>> find({
    required List<String> titles,
    required int year,
  }) async {
    final names = {
      for (final t in titles)
        if (normaliseTitle(t).length >= 2) t.trim(),
    }.toList();
    if (names.isEmpty) return const <ArchiveFilm>[];
    final key = '${names.map(normaliseTitle).join('|')}|$year';
    final cached = _cache[key];
    if (cached != null) return cached;
    try {
      final films = await _find(names, year).timeout(overallTimeout);
      // Only an answer is remembered. A request that failed reads as "no
      // films" here, and caching that hid the film's Internet Archive copy
      // for the rest of the session after one slow moment on the network.
      if (films.isNotEmpty) _cache[key] = films;
      return films;
    } catch (_) {
      return const <ArchiveFilm>[];
    }
  }

  Future<List<ArchiveFilm>> _find(List<String> names, int year) async {
    final docs = <String, ArchiveDoc>{};
    // Latin names only: the Archive's catalogue titles are in English.
    final searchNames = names
        .where((n) => !RegExp(r'[぀-ヿ㐀-鿿]').hasMatch(n))
        .take(2);
    for (final name in searchNames) {
      final json = await _getJson(searchUri(name, year));
      for (final d in parseSearch(json)) {
        docs.putIfAbsent(d.identifier, () => d);
      }
    }
    final candidates = filterDocs(docs.values, names: names, year: year);
    final films = <ArchiveFilm>[];
    for (final doc in candidates.take(maxResults + 1)) {
      final meta = await _getJson(
        Uri.parse(
          'https://archive.org/metadata/${Uri.encodeComponent(doc.identifier)}',
        ),
      );
      final film = filmFromMetadata(meta, names: names, year: year);
      if (film != null) films.add(film);
      if (films.length >= maxResults) break;
    }
    return films;
  }

  Future<Object?> _getJson(Uri uri) async {
    final client = _client ?? http.Client();
    try {
      final res = await client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(requestTimeout);
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    } finally {
      if (_client == null) client.close();
    }
  }

  // ── Query ─────────────────────────────────────────────────────────────

  /// The advancedsearch query for [title] in [year], inside the curated
  /// collections.
  static Uri searchUri(String title, int year) {
    final safe = title.replaceAll(RegExp(r'["\\]'), ' ').trim();
    final q =
        'title:("$safe") AND mediatype:(movies) AND year:($year) AND '
        'collection:(${curatedCollections.join(' OR ')})';
    return Uri.https('archive.org', '/advancedsearch.php', {
      'q': q,
      'fl[]': [
        'identifier',
        'title',
        'year',
        'licenseurl',
        'downloads',
        'collection',
      ],
      'sort[]': 'downloads desc',
      'rows': '$searchRows',
      'output': 'json',
    });
  }

  // ── Parsing ───────────────────────────────────────────────────────────

  static List<ArchiveDoc> parseSearch(Object? json) {
    if (json is! Map) return const <ArchiveDoc>[];
    final response = json['response'];
    if (response is! Map) return const <ArchiveDoc>[];
    final docs = response['docs'];
    if (docs is! List) return const <ArchiveDoc>[];
    final out = <ArchiveDoc>[];
    for (final d in docs) {
      if (d is! Map) continue;
      final id = d['identifier'];
      final title = _string(d['title']);
      if (id is! String || id.isEmpty || title == null) continue;
      final collection = d['collection'];
      out.add(
        ArchiveDoc(
          identifier: id,
          title: title,
          year: _int(d['year']),
          licenceUrl: _string(d['licenseurl']),
          downloads: _int(d['downloads']) ?? 0,
          collections: collection is List
              ? [for (final c in collection) c.toString()]
              : (collection is String ? [collection] : const <String>[]),
        ),
      );
    }
    return out;
  }

  /// The hits that pass every rule, most downloaded first.
  static List<ArchiveDoc> filterDocs(
    Iterable<ArchiveDoc> docs, {
    required List<String> names,
    required int year,
  }) {
    final list = [
      for (final d in docs)
        if (d.year == year &&
            licenceOf(d.licenceUrl) != null &&
            isCurated(d.collections) &&
            !looksRipped(d.identifier) &&
            !looksRipped(d.title) &&
            titleMatches(d.title, names))
          d,
    ]..sort((a, b) => b.downloads.compareTo(a.downloads));
    return list;
  }

  /// The film in an item's `/metadata` answer, or null when the item fails a
  /// rule or has no feature-length MP4.
  static ArchiveFilm? filmFromMetadata(
    Object? json, {
    required List<String> names,
    required int year,
  }) {
    if (json is! Map) return null;
    if (json['is_dark'] == true) return null;
    final meta = json['metadata'];
    if (meta is! Map) return null;
    final id = _string(meta['identifier']);
    final title = _string(meta['title']);
    if (id == null || title == null) return null;
    if (_string(meta['mediatype']) != 'movies') return null;
    final restricted = _string(meta['access-restricted-item']);
    if (restricted == 'true') return null;
    if (_int(meta['year']) != year && _yearOfDate(meta['date']) != year) {
      return null;
    }
    if (!titleMatches(title, names)) return null;
    if (looksRipped(id) || looksRipped(title)) return null;
    final collection = meta['collection'];
    final collections = collection is List
        ? [for (final c in collection) c.toString()]
        : [if (collection is String) collection];
    if (!isCurated(collections)) return null;
    final licence = licenceOf(_string(meta['licenseurl']));
    if (licence == null) return null;

    final file = pickFile(json['files']);
    if (file == null) return null;
    return ArchiveFilm(
      identifier: id,
      title: title,
      year: year,
      licence: licence,
      fileName: file.name,
      format: file.format,
      sizeBytes: file.size,
      length: file.length,
    );
  }

  /// The best MP4 in a `files` list: the Archive's own h.264 derivative
  /// first, then an MPEG4 original no larger than [maxFileBytes], then the
  /// 512Kb derivative; the largest of the best kind. Null when none is
  /// feature length.
  static ({String name, String format, int? size, Duration? length})? pickFile(
    Object? files,
  ) {
    if (files is! List) return null;
    int rank(String format, String source) {
      final f = format.toLowerCase();
      if (f == 'h.264' || f == 'h.264 hd') return 0;
      if (f == 'mpeg4' || f == 'h.264 mpeg4') return 1;
      if (f == '512kb mpeg4') return 2;
      return 99;
    }

    ({String name, String format, int? size, Duration? length})? best;
    var bestRank = 99;
    for (final f in files) {
      if (f is! Map) continue;
      final name = _string(f['name']);
      final format = _string(f['format']) ?? '';
      if (name == null || !name.toLowerCase().endsWith('.mp4')) continue;
      if (looksRipped(name)) continue;
      final r = rank(format, _string(f['source']) ?? '');
      if (r == 99) continue;
      final size = _int(f['size']);
      if (size != null && size > maxFileBytes) continue;
      final seconds = double.tryParse(_string(f['length']) ?? '');
      final length = seconds == null
          ? null
          : Duration(milliseconds: (seconds * 1000).round());
      if (length == null || length < minFeatureLength) continue;
      final better =
          best == null ||
          r < bestRank ||
          (r == bestRank && (size ?? 0) > (best.size ?? 0));
      if (better) {
        best = (name: name, format: format, size: size, length: length);
        bestRank = r;
      }
    }
    return best;
  }

  // ── Rules ─────────────────────────────────────────────────────────────

  /// Marks of a ripped commercial release (a scene group's Blu-ray / web
  /// rip). The film may be public domain while that restoration is not, so
  /// an item or file named like one is refused.
  static final RegExp _ripMarks = RegExp(
    r'blu-?ray|remux|bd-?rip|br-?rip|web-?dl|web-?rip|hdtv|dvd-?rip|'
    r'x\.?26[45]|hevc|dts-hd|truehd|\b(?:yify|yts|rarbg)\b|'
    r'framestor|\b\d{3,4}p\b.*-[A-Za-z0-9]{3,}$',
    caseSensitive: false,
  );

  /// Whether [name] (an identifier, title or file name) looks like a rip.
  static bool looksRipped(String name) =>
      _ripMarks.hasMatch(name.replaceAll(RegExp(r'\.(mp4|mkv|avi)$'), ''));

  static bool isCurated(List<String> collections) =>
      collections.any(curatedCollections.contains);

  /// The licence at [url] when it is a Creative Commons licence or a
  /// public-domain mark / CC0; null for anything else (including none).
  static ArchiveLicence? licenceOf(String? url) {
    if (url == null) return null;
    final m = RegExp(
      r'^https?://(?:www\.)?creativecommons\.org/(licenses|publicdomain)/([a-z0-9-]+)',
      caseSensitive: false,
    ).firstMatch(url.trim());
    if (m == null) return null;
    final kind = m.group(1)!.toLowerCase();
    final code = m.group(2)!.toLowerCase();
    if (kind == 'publicdomain' || code == 'publicdomain') {
      return ArchiveLicence(url: url.trim(), publicDomain: true);
    }
    if (!RegExp(r'^by(-(nc|sa|nd))*$').hasMatch(code)) return null;
    return ArchiveLicence(
      url: url.trim(),
      publicDomain: false,
      code: code.toUpperCase(),
    );
  }

  /// Whether an Archive title is one of [names] (see [normaliseTitle]).
  static bool titleMatches(String archiveTitle, List<String> names) {
    final t = normaliseTitle(archiveTitle);
    if (t.isEmpty) return false;
    return names.any((n) => normaliseTitle(n) == t);
  }

  /// Lower case, a trailing "(1968)" / "[1968]" and a leading "the", "a" or
  /// "an" dropped, `&` read as "and", everything but letters and digits
  /// removed.
  static String normaliseTitle(String s) {
    var t = s.toLowerCase().trim();
    t = t.replaceAll(RegExp(r'[\(\[]\s*\d{4}\s*[\)\]]\s*$'), '');
    t = t.replaceAll('&', ' and ');
    t = t.replaceFirst(RegExp(r'^(the|a|an)\s+'), '');
    return t.replaceAll(RegExp(r'[^a-z0-9぀-ヿ㐀-鿿]'), '');
  }

  static String? _string(Object? v) {
    if (v is String) return v.trim().isEmpty ? null : v.trim();
    if (v is List && v.isNotEmpty) return _string(v.first);
    if (v is num) return v.toString();
    return null;
  }

  static int? _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    if (v is List && v.isNotEmpty) return _int(v.first);
    return null;
  }

  static int? _yearOfDate(Object? v) {
    final s = _string(v);
    if (s == null) return null;
    final m = RegExp(r'^(\d{4})').firstMatch(s);
    return m == null ? null : int.parse(m.group(1)!);
  }
}
