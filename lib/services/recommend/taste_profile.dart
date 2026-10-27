import 'dart:math' as math;

import 'taste_store.dart';

/// How much the viewer likes each kind of title, from their history.
///
/// A kind is [TasteFacets.key]: where it is from, animated or live, series or
/// film. One viewer's top kind is "CN|anim|tv" (国漫), another's "HK|live|tv"
/// (港剧), a third's films from anywhere - the profile is what tells the
/// recommender which of those to fill a row with.
class TasteProfile {
  TasteProfile._(this.kinds, this.genres, this.seen);

  /// Affinity per kind key, highest first. Only positive kinds are kept.
  final List<MapEntry<String, double>> kinds;

  /// Affinity per TMDb genre id.
  final Map<int, double> genres;

  /// Every title the viewer has touched, so recommendations can skip them.
  final Set<String> seen;

  bool get isEmpty => kinds.isEmpty;

  /// How much one entry says about taste, before it ages.
  ///
  /// Finishing says the most, a 👍 more than that, a 👎 the opposite, and
  /// giving up early a little against: a title started and left under a
  /// quarter of the way, untouched for a week, was not to the viewer's taste.
  static double weightOf(TasteEntry e, DateTime now) {
    var w = 0.0;
    if (e.finished) {
      w += 3;
    } else if (e.progress >= 0.5) {
      w += 2;
    } else if (e.progress >= 0.1) {
      w += 1;
    }
    if (e.listed) w += 1;
    w += e.rating * 4;
    final abandoned =
        !e.finished &&
        e.rating == 0 &&
        e.progress > 0 &&
        e.progress < 0.25 &&
        now.difference(e.lastSeen).inDays >= 7;
    if (abandoned) w -= 1;
    return w;
  }

  /// Older signals count for less: half every 90 days.
  static double decayOf(TasteEntry e, DateTime now) {
    final days = now.difference(e.lastSeen).inHours / 24;
    return math.pow(0.5, days / 90).toDouble();
  }

  static TasteProfile build(Iterable<TasteEntry> entries, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final kinds = <String, double>{};
    final genres = <int, double>{};
    final seen = <String>{};
    for (final e in entries) {
      seen.add(e.id);
      final facets = e.facets;
      if (facets == null) continue;
      final w = weightOf(e, at) * decayOf(e, at);
      if (w == 0) continue;
      kinds[facets.key] = (kinds[facets.key] ?? 0) + w;
      for (final g in facets.genres) {
        genres[g] = (genres[g] ?? 0) + w;
      }
    }
    final ranked =
        kinds.entries.where((k) => k.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return TasteProfile._(ranked, genres, seen);
  }
}

/// A kind key ("HK|live|tv") as the name a viewer would use for it: 港剧.
///
/// [zh] picks Chinese; otherwise English. Regions without a common name fall
/// back to the plain kind (剧集, 动画, 电影).
String tasteKindName(String key, {required bool zh}) {
  final parts = key.split('|');
  if (parts.length != 3) return key;
  final region = parts[0];
  final animated = parts[1] == 'anim';
  final series = parts[2] == 'tv';

  if (zh) {
    if (animated) {
      if (!series) return '动画电影';
      return switch (region) {
        'CN' => '国漫',
        'JP' => '日本动漫',
        'KR' => '韩国动画',
        'US' => '美国动画',
        _ => '动画',
      };
    }
    if (series) {
      return switch (region) {
        'CN' => '国产剧',
        'HK' => '港剧',
        'TW' => '台剧',
        'KR' => '韩剧',
        'JP' => '日剧',
        'TH' => '泰剧',
        'US' => '美剧',
        'GB' => '英剧',
        _ => '剧集',
      };
    }
    return switch (region) {
      'CN' => '国产电影',
      'HK' => '港片',
      'TW' => '台湾电影',
      'KR' => '韩国电影',
      'JP' => '日本电影',
      'IN' => '印度电影',
      'US' => '好莱坞电影',
      _ => '电影',
    };
  }

  if (animated) {
    if (!series) return 'Animated films';
    return switch (region) {
      'CN' => 'Chinese animation',
      'JP' => 'Anime',
      _ => 'Animation',
    };
  }
  final place = switch (region) {
    'CN' => 'Chinese',
    'HK' => 'Hong Kong',
    'TW' => 'Taiwanese',
    'KR' => 'Korean',
    'JP' => 'Japanese',
    'TH' => 'Thai',
    'US' => 'American',
    'GB' => 'British',
    'IN' => 'Indian',
    _ => '',
  };
  final kind = series ? 'dramas' : 'films';
  return place.isEmpty ? (series ? 'Series' : 'Films') : '$place $kind';
}
