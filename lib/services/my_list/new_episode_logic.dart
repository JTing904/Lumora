/// The pure part of 有新集: what an episode is, and when one counts as new.
///
/// Kept free of Flutter and storage so the decision can be tested alone.
library;

/// One episode of a show, as TMDb lists it.
class EpisodeRef implements Comparable<EpisodeRef> {
  const EpisodeRef(this.season, this.episode, {this.airDate, this.name});

  final int season;
  final int episode;

  /// The day it airs (or aired), date only; null when TMDb has none yet.
  final DateTime? airDate;
  final String? name;

  /// From a TMDb `last_episode_to_air` / `next_episode_to_air` / season
  /// episode object. Null when the numbers are missing.
  static EpisodeRef? fromTmdb(Object? raw) {
    if (raw is! Map) return null;
    final s = _int(raw['season_number']);
    final e = _int(raw['episode_number']);
    if (s == null || e == null) return null;
    return EpisodeRef(
      s,
      e,
      airDate: parseAirDate(raw['air_date']),
      name: raw['name'] is String && (raw['name'] as String).trim().isNotEmpty
          ? (raw['name'] as String).trim()
          : null,
    );
  }

  static int? _int(Object? v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));

  /// `2026-10-28` as a local date; null for anything else.
  static DateTime? parseAirDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final d = DateTime.tryParse(raw);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  Map<String, Object?> toJson() => {
    'season_number': season,
    'episode_number': episode,
    if (airDate != null) 'air_date': _ymd(airDate!),
    if (name != null) 'name': name,
  };

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  int compareTo(EpisodeRef other) => season != other.season
      ? season.compareTo(other.season)
      : episode.compareTo(other.episode);

  bool isAfter(EpisodeRef other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is EpisodeRef && other.season == season && other.episode == episode;

  @override
  int get hashCode => Object.hash(season, episode);

  @override
  String toString() => 'S${season}E$episode';
}

/// Whether a show in My List has an episode the viewer has not seen yet.
///
/// * [latestAired]: TMDb's `last_episode_to_air`. Nothing aired, no air
///   date, or specials (season 0) → not new.
/// * The air date is the origin country's, so an episode dated today may not
///   be out yet here: it counts from the next local day on.
/// * It must have aired after the show was added to the list ([addedAt],
///   compared by day), watched or not, so saving an old show (or catching up
///   on one that ended years ago) does not light it up.
/// * [lastSeen]: the furthest episode the viewer finished or is watching.
///   When there is one, new also needs [latestAired] to come after it.
bool hasNewEpisode({
  required EpisodeRef? latestAired,
  required EpisodeRef? lastSeen,
  required DateTime addedAt,
  DateTime? now,
}) {
  final latest = latestAired;
  if (latest == null || latest.season <= 0) return false;
  final aired = latest.airDate;
  if (aired == null) return false;
  final today = _day(now ?? DateTime.now());
  if (!_day(aired).isBefore(today)) return false;
  if (!_day(aired).isAfter(_day(addedAt))) return false;
  return lastSeen == null || latest.isAfter(lastSeen);
}

/// The latest aired episode from cached facts: a cached [next] whose air
/// date is today or earlier has aired since the cache was filled, so it
/// stands in for [latest] when it comes after it.
EpisodeRef? latestAiredOf(
  EpisodeRef? latest,
  EpisodeRef? next, {
  DateTime? now,
}) {
  final at = next?.airDate;
  if (next == null || at == null) return latest;
  if (_day(at).isAfter(_day(now ?? DateTime.now()))) return latest;
  return latest == null || next.isAfter(latest) ? next : latest;
}

/// The furthest of [episodes], ignoring nulls; null when there are none.
EpisodeRef? furthestEpisode(Iterable<EpisodeRef?> episodes) {
  EpisodeRef? best;
  for (final e in episodes) {
    if (e == null) continue;
    if (best == null || e.isAfter(best)) best = e;
  }
  return best;
}

/// `season:episode` keys as [WatchedEpisodes] keeps them.
EpisodeRef? parseEpisodeKey(String key) {
  final parts = key.split(':');
  if (parts.length < 2) return null;
  final s = int.tryParse(parts[0]);
  final e = int.tryParse(parts[1]);
  return s == null || e == null ? null : EpisodeRef(s, e);
}

DateTime _day(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}
