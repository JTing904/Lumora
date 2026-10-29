/// Decides whether an upload on a whitelisted channel is the episode (or the
/// film) the viewer picked.
///
/// Pure Dart and network-free, so every rule here is pinned by a unit test.
/// The rules are strict on purpose: a wrong "official" episode is worse than
/// none, because the row is sorted first and labelled as the rights holder's.
///
/// An upload matches only when all of these hold:
/// * it was uploaded by a channel in `OfficialChannels` (checked by id);
/// * it is not members-only, live, upcoming or a Short;
/// * it is at least [OfficialEpisodeMatcher.minEpisodeLength] long (a film: at
///   least [OfficialEpisodeMatcher.minMovieLength]);
/// * its title contains one of the show's names, in any of its languages;
/// * its title is not a trailer, preview, clip, highlight, recap, music video
///   and so on ([OfficialEpisodeMatcher.isExtra]);
/// * its title carries the episode number in a form an uploader actually uses
///   - `EP196`, `Episode 196`, `第196集`, `第196话`, `第一百九十六集`, `S02E05`,
///   TVB's `01/25` - or a compilation range that contains it (`EP166-172合集`).
library;

import 'official_channels.dart';

/// One video as a search returned it.
class OfficialUpload {
  const OfficialUpload({
    required this.videoId,
    required this.title,
    required this.channelId,
    this.channelName,
    this.duration,
    this.membersOnly = false,
    this.live = false,
    this.upcoming = false,
  });

  final String videoId;
  final String title;
  final String channelId;
  final String? channelName;
  final Duration? duration;
  final bool membersOnly;
  final bool live;
  final bool upcoming;
}

/// What the viewer picked.
class OfficialQuery {
  const OfficialQuery({
    required this.names,
    this.season,
    this.episode,
    this.previousSeasonsEpisodes,
  });

  /// The show's names: the addon's English name, TMDb's Chinese (simplified
  /// and traditional) and original titles. Blank and duplicate names are
  /// ignored.
  final List<String> names;

  /// TMDb season and episode. Both null for a film.
  final int? season;
  final int? episode;

  /// How many regular episodes the seasons before [season] have, when known.
  /// Donghua are usually uploaded with one running number, so S5E12 of a show
  /// whose first four seasons have 204 episodes is uploaded as EP216.
  final int? previousSeasonsEpisodes;

  bool get isMovie => episode == null;

  /// The running number across seasons, when it differs from [episode].
  int? get absoluteEpisode {
    final e = episode;
    final prev = previousSeasonsEpisodes;
    if (e == null || prev == null || prev <= 0) return null;
    if ((season ?? 1) <= 1) return null;
    return prev + e;
  }
}

enum OfficialMatchKind {
  /// The single episode.
  episode,

  /// A multi-episode upload whose range contains the episode.
  compilation,

  /// A full film.
  movie,
}

class OfficialMatch {
  const OfficialMatch({
    required this.upload,
    required this.kind,
    this.rangeStart,
    this.rangeEnd,
  });

  final OfficialUpload upload;
  final OfficialMatchKind kind;

  /// The compilation's episode range, for [OfficialMatchKind.compilation].
  final int? rangeStart;
  final int? rangeEnd;

  OfficialChannel? get channel => OfficialChannels.byId(upload.channelId);
}

/// The numbers a title carries.
class TitleNumbers {
  const TitleNumbers({
    this.episodes = const <int>{},
    this.ranges = const <(int, int)>[],
    this.season,
  });

  /// Single episode numbers (`EP196`, `第196集`).
  final Set<int> episodes;

  /// Inclusive ranges (`EP166-172`, `第1-100话`).
  final List<(int, int)> ranges;

  /// An explicit season marker (`第二季`, `Season 2`, `S2`), if any.
  final int? season;

  bool get isEmpty => episodes.isEmpty && ranges.isEmpty;
}

abstract final class OfficialEpisodeMatcher {
  /// Shorter than this is a clip, a trailer or a recap, never an episode.
  static const Duration minEpisodeLength = Duration(minutes: 8);

  /// A film is at least this long; anything shorter is a trailer or a cut.
  static const Duration minMovieLength = Duration(minutes: 60);

  /// A season-relative number restarts at 1, and no restarted season on these
  /// channels runs past a year's 52 episodes. A number above this next to some
  /// other season/arc label ("S4 EP170") is therefore the show's running
  /// number, not a different season's episode.
  static const int absoluteNumberFloor = 52;

  /// At most this many matches are offered.
  static const int maxResults = 3;

  // ── Extras ────────────────────────────────────────────────────────────

  static final RegExp _extra = RegExp(
    [
      r'trailer',
      r'teaser',
      r'(?<![a-z])pv(?![a-z])',
      r'(?<![a-z])cm(?![a-z])',
      r'(?<![a-z])mv(?![a-z])',
      r'(?<![a-z])ost(?![a-z])',
      r'preview',
      r'sneak peek',
      r'clip',
      r'highlight',
      r'recap',
      r'reaction',
      r'behind the scenes',
      r'making of',
      r'interview',
      r'countdown',
      r'#shorts?',
      r'(?<![a-z])shorts?(?![a-z])',
      r'(?<![a-z])ncop(?![a-z])',
      r'(?<![a-z])nced(?![a-z])',
      r'预告',
      r'預告',
      r'先导',
      r'先導',
      r'花絮',
      r'精华',
      r'精華',
      r'精彩片段',
      r'精彩看点',
      r'精彩看點',
      r'片段',
      r'幕后',
      r'幕後',
      r'解说',
      r'解說',
      r'混剪',
      r'盘点',
      r'盤點',
      r'采访',
      r'專訪',
      r'专访',
      r'倒计时',
      r'倒數',
      r'特辑',
      r'特輯',
      r'名场面',
      r'名場面',
      r'主题曲',
      r'主題曲',
      r'片头曲',
      r'片頭曲',
      r'片尾曲',
      r'彩蛋',
      r'看点',
      r'看點',
      r'速看',
      r'cosplay',
    ].join('|'),
    caseSensitive: false,
  );

  /// Whether [title] is a trailer, clip, highlight or other extra.
  static bool isExtra(String title) => _extra.hasMatch(title);

  /// Members-only uploads some channels mark in the title rather than with a
  /// badge (`会员专享`, `👑會員專享👑`, Mango's leading `VIP`).
  static final RegExp _membersTitle = RegExp(
    r'会员专享|會員專享|会员专属|會員專屬|会员抢先|會員搶先|^\W*VIP\b',
    caseSensitive: false,
  );

  /// Whether [title] says the upload is for paying channel members only.
  static bool isMembersOnlyTitle(String title) =>
      _membersTitle.hasMatch(title.trim());

  // ── Names ─────────────────────────────────────────────────────────────

  /// Lower case, full-width folded, and stripped of everything that is not a
  /// letter, a digit or a CJK character - so `《凡人修仙传》` and
  /// `A Mortal's Journey` compare as `凡人修仙传` and `amortalsjourney`.
  static String normalise(String s) {
    final folded = _foldWidth(s).toLowerCase();
    return folded.replaceAll(_nonWord, '');
  }

  static final RegExp _nonWord = RegExp(
    r'[^a-z0-9぀-ヿ㐀-䶿一-鿿가-힯]',
    unicode: true,
  );

  static bool _isCjk(String s) => RegExp(r'[぀-ヿ㐀-䶿一-鿿가-힯]').hasMatch(s);

  /// The usable names: blank, duplicate and too-short names dropped. A Latin
  /// name shorter than 4 letters, or a CJK name of one character, would match
  /// half the channel.
  static List<String> usableNames(Iterable<String> names) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in names) {
      final n = raw.trim();
      final key = normalise(n);
      if (key.isEmpty || !seen.add(key)) continue;
      if (_isCjk(key) ? key.length < 2 : key.length < 4) continue;
      out.add(n);
    }
    return out;
  }

  /// Whether [title] names the show [name].
  ///
  /// A CJK name followed directly by a single sequel digit or a Roman
  /// numeral is a sequel with its own TMDb entry (`斗罗大陆2绝世唐门` is not
  /// `斗罗大陆`), so a title that only names it that way is not a match.
  /// `凡人修仙传196集` and `凡人修仙传2集` are episode numbers, not sequels.
  static bool containsName(String title, String name) {
    final key = normalise(name);
    if (key.isEmpty) return false;
    final folded = _foldWidth(title);
    if (!normalise(folded).contains(key)) return false;
    if (_isCjk(key)) {
      final escaped = RegExp.escape(_foldWidth(name.trim()));
      final all = RegExp(escaped).allMatches(folded).length;
      final sequels = RegExp(
        '$escaped(?:[2-9]|[ⅡⅢⅣⅤⅥⅦⅧⅨⅩ])(?![0-9集话話期回])',
      ).allMatches(folded).length;
      if (all > 0 && sequels == all) return false;
    }
    return true;
  }

  // ── Numbers ───────────────────────────────────────────────────────────

  static const String _cnDigits = '零〇一二两兩三四五六七八九十百千';

  static final RegExp _rangePattern = RegExp(
    r'(?:(?<![a-z])ep(?:isodes?)?\.?|第)\s*([0-9]{1,4})\s*[-–—~～至到]\s*(?:ep\.?\s*)?([0-9]{1,4})',
    caseSensitive: false,
  );
  static final RegExp _sxePattern = RegExp(
    r'(?<![a-z0-9])s([0-9]{1,2})\s*e([0-9]{1,4})(?![0-9])',
    caseSensitive: false,
  );
  static final RegExp _epPattern = RegExp(
    r'(?<![a-z])ep(?:isode)?\.?\s*([0-9]{1,4})(?![0-9])',
    caseSensitive: false,
  );
  static final RegExp _cnEpPattern = RegExp(
    '第\\s*([0-9]{1,4}|[$_cnDigits]{1,6})\\s*[集话話回]',
  );

  /// `196集` with no `第`; `全40集` / `共40集` is a total, not an episode.
  static final RegExp _bareCnEpPattern = RegExp(
    r'(?<![0-9全共])([0-9]{1,4})\s*[集话話](?!数|數)',
  );
  static final RegExp _tvbPattern = RegExp(
    r'(?<![0-9/])([0-9]{1,3})\s*/\s*([0-9]{1,3})(?![0-9/])',
  );
  static final RegExp _cnSeasonPattern = RegExp(
    '第\\s*([0-9]{1,2}|[$_cnDigits]{1,3})\\s*季',
  );
  static final RegExp _enSeasonPattern = RegExp(
    r'season\s*([0-9]{1,2})(?![0-9])',
    caseSensitive: false,
  );
  static final RegExp _ordSeasonPattern = RegExp(
    r'([0-9])(?:st|nd|rd|th)\s+season',
    caseSensitive: false,
  );
  static final RegExp _sPattern = RegExp(
    r'(?<![a-z0-9])s([0-9]{1,2})(?![0-9a-z])',
    caseSensitive: false,
  );

  /// The episode numbers, ranges and season marker in [title].
  static TitleNumbers parseNumbers(String title) {
    var t = _foldWidth(title);
    final ranges = <(int, int)>[];
    for (final m in _rangePattern.allMatches(t)) {
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      if (b > a) ranges.add((a, b));
    }
    // A range's two ends are not single episodes.
    t = t.replaceAll(_rangePattern, ' ');

    final episodes = <int>{};
    int? season;

    for (final m in _sxePattern.allMatches(t)) {
      season ??= int.parse(m.group(1)!);
      episodes.add(int.parse(m.group(2)!));
    }
    for (final m in _epPattern.allMatches(t)) {
      episodes.add(int.parse(m.group(1)!));
    }
    for (final m in _cnEpPattern.allMatches(t)) {
      final n = parseChineseNumber(m.group(1)!);
      if (n != null) episodes.add(n);
    }
    for (final m in _bareCnEpPattern.allMatches(t)) {
      episodes.add(int.parse(m.group(1)!));
    }
    for (final m in _tvbPattern.allMatches(t)) {
      final a = m.group(1)!;
      final b = m.group(2)!;
      final n = int.parse(a);
      final total = int.parse(b);
      // TVB pads the episode to the total's width: "01/25", "07/32".
      if (a.length == b.length && n >= 1 && n <= total && total >= 5) {
        episodes.add(n);
      }
    }

    if (season == null) {
      final cn = _cnSeasonPattern.firstMatch(t);
      if (cn != null) season = parseChineseNumber(cn.group(1)!);
    }
    season ??= int.tryParse(_enSeasonPattern.firstMatch(t)?.group(1) ?? '');
    season ??= int.tryParse(_ordSeasonPattern.firstMatch(t)?.group(1) ?? '');
    season ??= int.tryParse(_sPattern.firstMatch(t)?.group(1) ?? '');

    episodes.removeWhere((n) => n <= 0);
    return TitleNumbers(episodes: episodes, ranges: ranges, season: season);
  }

  /// Arabic digits, or a Chinese numeral up to the thousands (`一百九十六`,
  /// `二十`, `十八`, `两百零五`).
  static int? parseChineseNumber(String s) {
    final digits = int.tryParse(s);
    if (digits != null) return digits;
    const values = {
      '零': 0,
      '〇': 0,
      '一': 1,
      '二': 2,
      '两': 2,
      '兩': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };
    const units = {'十': 10, '百': 100, '千': 1000};
    var total = 0;
    var current = 0;
    var seen = false;
    for (final ch in s.split('')) {
      if (values.containsKey(ch)) {
        current = values[ch]!;
        seen = true;
      } else if (units.containsKey(ch)) {
        total += (current == 0 ? 1 : current) * units[ch]!;
        current = 0;
        seen = true;
      } else {
        return null;
      }
    }
    if (!seen) return null;
    total += current;
    return total == 0 ? null : total;
  }

  static String _foldWidth(String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0xFF01 && r <= 0xFF5E) {
        b.writeCharCode(r - 0xFEE0);
      } else if (r == 0x3000) {
        b.write(' ');
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString();
  }

  // ── Matching ──────────────────────────────────────────────────────────

  /// [upload] as a match for [query], or null when it is not one.
  static OfficialMatch? match(OfficialUpload upload, OfficialQuery query) {
    if (!OfficialChannels.isWhitelisted(upload.channelId)) return null;
    if (upload.membersOnly || upload.live || upload.upcoming) return null;
    if (isMembersOnlyTitle(upload.title)) return null;
    final duration = upload.duration;
    if (duration == null) return null;
    final title = upload.title;
    if (isExtra(title)) return null;
    final names = usableNames(query.names);
    if (!names.any((n) => containsName(title, n))) return null;

    final numbers = parseNumbers(title);

    if (query.isMovie) {
      if (duration < minMovieLength) return null;
      // A numbered upload is an episode of a series of the same name.
      if (!numbers.isEmpty) return null;
      return OfficialMatch(upload: upload, kind: OfficialMatchKind.movie);
    }

    if (duration < minEpisodeLength) return null;
    final wanted = _wantedNumbers(query, numbers.season);
    if (wanted.isEmpty) return null;

    if (numbers.episodes.any(wanted.contains)) {
      return OfficialMatch(upload: upload, kind: OfficialMatchKind.episode);
    }
    for (final (a, b) in numbers.ranges) {
      if (wanted.any((n) => n >= a && n <= b)) {
        return OfficialMatch(
          upload: upload,
          kind: OfficialMatchKind.compilation,
          rangeStart: a,
          rangeEnd: b,
        );
      }
    }
    return null;
  }

  /// The numbers that mean the picked episode in a title whose own season
  /// marker is [titleSeason].
  ///
  /// * The running number (previous seasons' episodes plus this one) always
  ///   counts when no other season is named, and counts next to another
  ///   season/arc label once it is past [absoluteNumberFloor].
  /// * The plain episode number counts when the title names the same season;
  ///   or names none and the pick is in season 1, or the number cannot be an
  ///   earlier season's episode (it is past their total, or that total is
  ///   unknown); or, past [absoluteNumberFloor], whatever the title names.
  static Set<int> _wantedNumbers(OfficialQuery q, int? titleSeason) {
    final e = q.episode;
    if (e == null || e <= 0) return const <int>{};
    final s = q.season ?? 1;
    final abs = q.absoluteEpisode;
    final prev = q.previousSeasonsEpisodes;
    final out = <int>{};

    final sameSeason = titleSeason == null || titleSeason == s;
    if (titleSeason == s) {
      out.add(e);
    } else if (titleSeason == null) {
      if (s <= 1 || prev == null || prev <= 0 || e > prev) out.add(e);
    } else if (e > absoluteNumberFloor) {
      out.add(e);
    }
    if (abs != null && (sameSeason || abs > absoluteNumberFloor)) {
      out.add(abs);
    }
    return out;
  }

  /// Every match in [uploads], best first, at most [maxResults].
  ///
  /// Single episodes before compilations, compilations before nothing; among
  /// single episodes the longest wins (a full episode over a cut-down one),
  /// among compilations the narrowest range wins (the least seeking).
  static List<OfficialMatch> rank(
    Iterable<OfficialUpload> uploads,
    OfficialQuery query,
  ) {
    final byId = <String, OfficialMatch>{};
    for (final u in uploads) {
      if (byId.containsKey(u.videoId)) continue;
      final m = match(u, query);
      if (m != null) byId[u.videoId] = m;
    }
    final list = byId.values.toList()
      ..sort((a, b) {
        final k = _kindRank(a.kind).compareTo(_kindRank(b.kind));
        if (k != 0) return k;
        if (a.kind == OfficialMatchKind.compilation) {
          final wa = (a.rangeEnd ?? 0) - (a.rangeStart ?? 0);
          final wb = (b.rangeEnd ?? 0) - (b.rangeStart ?? 0);
          if (wa != wb) return wa.compareTo(wb);
        }
        return (b.upload.duration ?? Duration.zero).compareTo(
          a.upload.duration ?? Duration.zero,
        );
      });
    return list.take(maxResults).toList(growable: false);
  }

  static int _kindRank(OfficialMatchKind k) => switch (k) {
    OfficialMatchKind.episode => 0,
    OfficialMatchKind.movie => 0,
    OfficialMatchKind.compilation => 1,
  };
}
