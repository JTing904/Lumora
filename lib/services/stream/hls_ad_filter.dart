/// Strips the ads that 苹果CMS 资源站 splice into their HLS playlists.
///
/// The sites that serve `.m3u8` for 中文资源站 add an advert to the film's own
/// playlist, between `#EXT-X-DISCONTINUITY` tags: 17 or 26 seconds of
/// gambling promotion, once after each chunk of the film or at the very end.
/// The advert's segments come from another directory than the film's (a
/// folder dated the day the ad was rotated in, or `/video/adjump/`), the same
/// few URLs repeat in every playlist, and some sites label them outright
/// (`# ppvod-ad-injected`, `#EXT-X-CUE-OUT`). The ads also push the film's
/// timeline late, so subtitles and resume positions miss by their length.
///
/// This file is the pure part: parse a playlist, find those blocks and write
/// the playlist back without them. It never touches the network. A playlist
/// it is unsure of is returned whole, because playing an ad costs seconds and
/// cutting the film costs the film.
library;

/// What [HlsAdFilter.clean] made of a media playlist.
class HlsCleanResult {
  const HlsCleanResult({
    required this.playlist,
    this.removedSeconds = 0,
    this.removedSegments = 0,
    this.removedBlocks = 0,
    this.skipReason,
  });

  /// The playlist to play, every address absolute. The same as the input when
  /// nothing was removed.
  final String playlist;

  final double removedSeconds;
  final int removedSegments;
  final int removedBlocks;

  /// Why ads that were found were left in, for the log; null otherwise.
  final String? skipReason;

  bool get changed => removedSegments > 0;
}

/// One rendition of a master playlist.
class HlsVariant {
  const HlsVariant({required this.uri, this.bandwidth, this.resolution});

  /// Absolute address of the variant's media playlist.
  final String uri;
  final int? bandwidth;
  final String? resolution;
}

class HlsAdFilter {
  const HlsAdFilter._();

  /// An advert is at most this long; anything longer is the film.
  static const double maxAdSeconds = 120;

  /// The most of a playlist that may be cut when the blocks are only odd out
  /// by where they are served from.
  static const double maxRemovedShare = 0.2;

  /// The most that may be cut when every block is also labelled or repeated
  /// verbatim: a short clip carrying two 17 s ads is mostly advert.
  static const double maxCorroboratedShare = 0.35;

  static bool looksLikePlaylist(String text) =>
      text.trimLeft().startsWith('#EXTM3U');

  static bool isMaster(String text) => text.contains('#EXT-X-STREAM-INF');

  /// The renditions of a master playlist, addresses made absolute against
  /// [base].
  static List<HlsVariant> variants(String text, Uri base) {
    final lines = _lines(text);
    final out = <HlsVariant>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('#EXT-X-STREAM-INF')) continue;
      var j = i + 1;
      while (j < lines.length && lines[j].startsWith('#')) {
        j++;
      }
      if (j >= lines.length) break;
      final bandwidth = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line)?.group(1);
      final resolution = RegExp(
        r'RESOLUTION=([0-9]+x[0-9]+)',
      ).firstMatch(line)?.group(1);
      out.add(
        HlsVariant(
          uri: _absolute(base, lines[j]),
          bandwidth: bandwidth == null ? null : int.tryParse(bandwidth),
          resolution: resolution,
        ),
      );
      i = j;
    }
    return out;
  }

  /// [text] with every address in it (segments, variants, keys, maps, audio
  /// renditions) resolved against [base].
  ///
  /// [replace] may swap an absolute address for another: how a master
  /// playlist is pointed at the cleaned copies of its variants.
  static String absolutize(
    String text,
    Uri base, {
    String? Function(String uri)? replace,
  }) {
    final out = StringBuffer();
    for (final line in _lines(text)) {
      if (line.startsWith('#')) {
        out.writeln(_absoluteTagUris(line, base, replace));
      } else {
        final uri = _absolute(base, line);
        out.writeln(replace?.call(uri) ?? uri);
      }
    }
    return out.toString();
  }

  /// Removes the ad blocks from a media playlist.
  ///
  /// A block is a run of segments between two discontinuities (or the ends of
  /// the playlist, or a labelled ad) that is no longer than [maxAdSeconds] and
  /// either is labelled as an ad, or is served from a directory the film is
  /// not, or repeats word for word elsewhere in the playlist and is named
  /// unlike the film's segments. If the blocks would be more than a fifth of
  /// the playlist, or the film itself is not clearly one directory, nothing
  /// is removed.
  static HlsCleanResult clean(String text, Uri base) {
    final playlist = _Playlist.parse(text, base);
    final entries = playlist.entries;
    final total = playlist.totalSeconds;
    if (entries.isEmpty || total <= 0) {
      return HlsCleanResult(playlist: playlist.write(const <int>{}));
    }

    final found = _findAds(playlist);
    if (found.blocks.isEmpty) {
      return HlsCleanResult(
        playlist: playlist.write(const <int>{}),
        skipReason: found.skipReason,
      );
    }

    var removedSeconds = 0.0;
    var corroborated = true;
    final drop = <int>{};
    for (final block in found.blocks) {
      removedSeconds += block.seconds;
      corroborated &= block.corroborated;
      for (var i = block.start; i < block.end; i++) {
        drop.add(i);
      }
    }
    final limit = corroborated ? maxCorroboratedShare : maxRemovedShare;
    if (removedSeconds > total * limit) {
      return HlsCleanResult(
        playlist: playlist.write(const <int>{}),
        skipReason:
            'ads would be ${(removedSeconds / total * 100).round()}% of the '
            'playlist',
      );
    }
    return HlsCleanResult(
      playlist: playlist.write(drop),
      removedSeconds: removedSeconds,
      removedSegments: drop.length,
      removedBlocks: found.blocks.length,
    );
  }

  // ── Detection ───────────────────────────────────────────────────────────

  static _Found _findAds(_Playlist playlist) {
    final entries = playlist.entries;

    // What the film is made of: the directory most of its running time is
    // served from, and how that directory's files are named.
    final seconds = <String, double>{};
    for (final e in entries) {
      final dir = e.dir;
      if (dir != null) seconds[dir] = (seconds[dir] ?? 0) + e.seconds;
    }
    if (seconds.isEmpty) return const _Found([], 'no segment addresses');
    final main = seconds.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (main.value * 2 <= playlist.totalSeconds) {
      return const _Found([], 'no directory holds most of the playlist');
    }
    final names = <String, double>{};
    for (final e in entries) {
      if (e.dir == main.key) {
        names[e.nameShape] = (names[e.nameShape] ?? 0) + e.seconds;
      }
    }
    final mainNames = names.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final runs = playlist.runs();
    final seen = <String, int>{};
    for (final run in runs) {
      seen.update(run.signature, (n) => n + 1, ifAbsent: () => 1);
    }

    final blocks = <_AdBlock>[];
    for (final run in runs) {
      if (run.seconds > maxAdSeconds) continue;
      final foreignDir = run.entries.every(
        (e) => e.dir != null && e.dir != main.key,
      );
      final foreignName = run.entries.every((e) => e.nameShape != mainNames);
      final labelled = run.entries.any((e) => e.adLabel || e.inCue);
      final repeated = (seen[run.signature] ?? 0) > 1;
      final keyword = run.entries.every((e) => e.adPath);
      final corroborated = labelled || repeated || keyword;
      if (labelled || foreignDir || (corroborated && foreignName)) {
        blocks.add(
          _AdBlock(run.start, run.end, run.seconds, corroborated: corroborated),
        );
      }
    }
    return _Found(blocks, null);
  }

  // ── Small helpers ───────────────────────────────────────────────────────

  static List<String> _lines(String text) => [
    for (final raw in text.split('\n'))
      if (raw.trim().isNotEmpty) raw.trim(),
  ];

  static final _scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*:');

  static String _absolute(Uri base, String ref) {
    final r = ref.trim();
    if (_scheme.hasMatch(r)) return r;
    try {
      return base.resolve(r).toString();
    } on FormatException {
      return base.resolve(Uri.encodeFull(r)).toString();
    }
  }

  static final _uriAttribute = RegExp(r'URI="([^"]*)"');

  static String _absoluteTagUris(
    String line,
    Uri base,
    String? Function(String uri)? replace,
  ) {
    if (!line.contains('URI="')) return line;
    return line.replaceAllMapped(_uriAttribute, (m) {
      final uri = _absolute(base, m.group(1)!);
      return 'URI="${replace?.call(uri) ?? uri}"';
    });
  }
}

class _Found {
  const _Found(this.blocks, this.skipReason);
  final List<_AdBlock> blocks;
  final String? skipReason;
}

class _AdBlock {
  const _AdBlock(
    this.start,
    this.end,
    this.seconds, {
    required this.corroborated,
  });

  /// Segment indexes, [start, end).
  final int start;
  final int end;
  final double seconds;

  /// Labelled as an ad, repeated verbatim, or on an ad path: evidence beyond
  /// where it is served from.
  final bool corroborated;
}

/// One segment with everything that governs how it plays.
class _Entry {
  _Entry({
    required this.uri,
    required this.extinf,
    required this.seconds,
    required this.index,
    required this.sequence,
  });

  final String uri;
  final String extinf;
  final double seconds;

  /// Position in the playlist, and the media sequence number the player
  /// counts it as: an AES-128 key without an IV derives its IV from that.
  final int index;
  final int sequence;

  bool discontinuity = false;
  String? key;
  String? map;
  String? byteRange;
  int? rangeLength;
  int? rangeOffset;

  /// Other tags and comments that came before the segment, kept as they were.
  final List<String> tags = [];

  /// The line before it said an ad was injected here.
  bool adLabel = false;

  /// Inside an `#EXT-X-CUE-OUT` ... `#EXT-X-CUE-IN` span.
  bool inCue = false;

  /// Starts a new run even without a discontinuity (a cue boundary).
  bool boundary = false;

  late final String? dir = _dirOf(uri);
  late final String nameShape = _nameShapeOf(uri);
  late final bool adPath = _adPath.hasMatch(dir ?? '');

  static final _adPath = RegExp(
    r'(^|/)(adjump|ads?|adv|advert\w*|guanggao|preroll|midroll)(/|$)',
    caseSensitive: false,
  );

  /// The directory part of the address, without the host: a film whose
  /// segments are spread over `v1.` and `v2.` hosts is still one directory.
  static String? _dirOf(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return null;
    final path = parsed.path;
    final slash = path.lastIndexOf('/');
    return slash < 0 ? '' : path.substring(0, slash);
  }

  /// How the file is named, not what: its length, whether it is digits, hex
  /// or mixed letters, and its extension.
  static String _nameShapeOf(String uri) {
    final path = Uri.tryParse(uri)?.path ?? uri;
    final file = path.substring(path.lastIndexOf('/') + 1);
    final dot = file.lastIndexOf('.');
    final stem = dot < 0 ? file : file.substring(0, dot);
    final ext = dot < 0 ? '' : file.substring(dot).toLowerCase();
    final kind = RegExp(r'^[0-9]+$').hasMatch(stem)
        ? 'd'
        : RegExp(r'^[0-9a-f]+$').hasMatch(stem)
        ? 'h'
        : RegExp(r'^[A-Za-z0-9]+$').hasMatch(stem)
        ? 'a'
        : 'o';
    return '$kind${stem.length}$ext';
  }
}

/// A run of segments between two boundaries.
class _Run {
  _Run(this.start, this.end, this.entries)
    : seconds = entries.fold(0.0, (s, e) => s + e.seconds),
      signature = entries.map((e) => e.uri).join('\n');

  final int start;
  final int end;
  final List<_Entry> entries;
  final double seconds;

  /// The addresses in order: two runs with the same one are the same ad.
  final String signature;
}

class _Playlist {
  _Playlist(this.header, this.entries, this.footer, this.base);

  final List<String> header;
  final List<_Entry> entries;
  final List<String> footer;
  final Uri base;

  double get totalSeconds => entries.fold(0.0, (s, e) => s + e.seconds);

  /// Playlist-wide tags: they stay at the top (or bottom) whatever happens to
  /// the segments.
  static final _playlistTag = RegExp(
    r'^#(EXTM3U|EXT-X-(VERSION|TARGETDURATION|MEDIA-SEQUENCE|'
    r'DISCONTINUITY-SEQUENCE|PLAYLIST-TYPE|ENDLIST|I-FRAMES-ONLY|'
    r'INDEPENDENT-SEGMENTS|START|ALLOW-CACHE|SERVER-CONTROL|PART-INF|'
    r'DEFINE))(:|$)',
  );

  static final _adLabelComment = RegExp(r'ad-injected', caseSensitive: false);

  static _Playlist parse(String text, Uri base) {
    final header = <String>[];
    final entries = <_Entry>[];
    final footer = <String>[];
    var mediaSequence = 0;
    var discontinuity = false;
    var inCue = false;
    var boundary = false;
    var adLabel = false;
    String? key;
    String? map;
    String? extinf;
    double? seconds;
    String? byteRange;
    final tags = <String>[];
    String? previousUri;
    int? previousEnd;

    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (!line.startsWith('#')) {
        // A segment address. One without an #EXTINF is not a segment.
        if (extinf == null) continue;
        final uri = HlsAdFilter._absolute(base, line);
        final entry = _Entry(
          uri: uri,
          extinf: extinf,
          seconds: seconds ?? 0,
          index: entries.length,
          sequence: mediaSequence + entries.length,
        );
        entry.discontinuity = discontinuity;
        entry.key = key;
        entry.map = map;
        entry.inCue = inCue;
        entry.boundary = boundary || discontinuity;
        entry.adLabel = adLabel;
        entry.tags.addAll(tags);
        if (byteRange != null) {
          final m = RegExp(
            r'^#EXT-X-BYTERANGE:(\d+)(?:@(\d+))?',
          ).firstMatch(byteRange);
          if (m != null) {
            entry.byteRange = byteRange;
            entry.rangeLength = int.parse(m.group(1)!);
            entry.rangeOffset = m.group(2) != null
                ? int.parse(m.group(2)!)
                : (previousUri == uri ? previousEnd : null);
          }
        }
        previousUri = uri;
        previousEnd = entry.rangeOffset != null && entry.rangeLength != null
            ? entry.rangeOffset! + entry.rangeLength!
            : null;
        entries.add(entry);
        tags.clear();
        extinf = null;
        seconds = null;
        byteRange = null;
        discontinuity = false;
        boundary = false;
        adLabel = false;
        continue;
      }

      if (line.startsWith('#EXTINF:')) {
        extinf = line;
        seconds = double.tryParse(
          RegExp(r'^#EXTINF:\s*([0-9.]+)').firstMatch(line)?.group(1) ?? '',
        );
      } else if (line == '#EXT-X-DISCONTINUITY') {
        discontinuity = true;
      } else if (line.startsWith('#EXT-X-KEY:')) {
        key = line;
      } else if (line.startsWith('#EXT-X-MAP:')) {
        map = line;
      } else if (line.startsWith('#EXT-X-BYTERANGE:')) {
        byteRange = line;
      } else if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
        mediaSequence =
            int.tryParse(line.substring('#EXT-X-MEDIA-SEQUENCE:'.length)) ?? 0;
        header.add(line);
      } else if (_playlistTag.hasMatch(line)) {
        (entries.isEmpty ? header : footer).add(line);
      } else {
        if (line.startsWith('#EXT-X-CUE-OUT')) {
          inCue = true;
          boundary = true;
        } else if (line.startsWith('#EXT-X-CUE-IN')) {
          inCue = false;
          boundary = true;
        } else if (!line.startsWith('#EXT') && _adLabelComment.hasMatch(line)) {
          adLabel = true;
          boundary = true;
        }
        tags.add(line);
      }
    }
    // Whatever trailed the last segment (a closing CUE-IN, a comment).
    footer.insertAll(0, tags);
    return _Playlist(header, entries, footer, base);
  }

  /// The segments cut at every boundary.
  List<_Run> runs() {
    final runs = <_Run>[];
    var start = 0;
    for (var i = 1; i <= entries.length; i++) {
      if (i == entries.length || entries[i].boundary) {
        runs.add(_Run(start, i, entries.sublist(start, i)));
        start = i;
      }
    }
    return runs;
  }

  /// The playlist without the segments at the indexes in [drop], every
  /// address absolute.
  ///
  /// What a removed block took with it is put right for the segments after
  /// it: the key and the init section in force are declared again if they
  /// differ from what was last written, a key with no IV gets the IV its
  /// segment would have had (it came from the media sequence number, which
  /// has shifted), a byte range that continued the removed one is made
  /// explicit, and the discontinuity tags of neighbouring blocks collapse
  /// into one.
  String write(Set<int> drop) {
    final out = StringBuffer();
    for (final line in header) {
      out.writeln(HlsAdFilter._absoluteTagUris(line, base, null));
    }
    String? writtenKey;
    String? writtenMap;
    var firstKept = true;
    var shifted = false;
    for (final e in entries) {
      if (drop.contains(e.index)) {
        shifted = true;
        continue;
      }
      for (final tag in e.tags) {
        // The end of an ad span whose start went with the ad.
        if (tag.startsWith('#EXT-X-CUE-IN') && drop.contains(e.index - 1)) {
          continue;
        }
        out.writeln(HlsAdFilter._absoluteTagUris(tag, base, null));
      }
      // A playlist that opens with an ad would otherwise open with a
      // discontinuity.
      final firstOfPlaylist = e.index == 0;
      if (e.discontinuity && (firstOfPlaylist || !firstKept)) {
        out.writeln('#EXT-X-DISCONTINUITY');
      }
      final key = e.key;
      if (key != null) {
        final needsIv =
            shifted &&
            !key.contains('METHOD=NONE') &&
            !key.contains('IV=') &&
            key.contains('METHOD=');
        if (needsIv) {
          final iv = e.sequence.toRadixString(16).padLeft(32, '0');
          writtenKey =
              '${HlsAdFilter._absoluteTagUris(key, base, null)},'
              'IV=0x$iv';
          out.writeln(writtenKey);
        } else {
          final line = HlsAdFilter._absoluteTagUris(key, base, null);
          if (line != writtenKey) {
            out.writeln(line);
            writtenKey = line;
          }
        }
      }
      final map = e.map;
      if (map != null) {
        final line = HlsAdFilter._absoluteTagUris(map, base, null);
        if (line != writtenMap) {
          out.writeln(line);
          writtenMap = line;
        }
      }
      out.writeln(e.extinf);
      final length = e.rangeLength;
      final offset = e.rangeOffset;
      if (e.byteRange != null) {
        out.writeln(
          shifted && length != null && offset != null
              ? '#EXT-X-BYTERANGE:$length@$offset'
              : e.byteRange,
        );
      }
      out.writeln(e.uri);
      firstKept = false;
    }
    for (final line in footer) {
      out.writeln(HlsAdFilter._absoluteTagUris(line, base, null));
    }
    return out.toString();
  }
}
