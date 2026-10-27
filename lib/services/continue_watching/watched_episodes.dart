import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The episodes of each show the viewer has finished (past 90%).
///
/// Continue Watching drops a session once it is finished, so without this the
/// details page forgot that episode 3 was done and offered episode 1 again.
/// Kept per show as `season:episode` keys, with the last one finished.
abstract final class WatchedEpisodes {
  static const _key = 'lumora_watched_episodes';

  /// showId -> finished `season:episode` keys, most recent last.
  static final ValueNotifier<Map<String, List<String>>> shows = ValueNotifier(
    const {},
  );

  static String keyFor(int season, int episode) => '$season:$episode';

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      shows.value = {
        for (final e in decoded.entries)
          e.key: [for (final k in (e.value as List)) k.toString()],
      };
    } catch (e) {
      debugPrint('[WatchedEpisodes] unreadable: $e');
    }
  }

  static bool isWatched(String showId, int? season, int? episode) {
    if (season == null || episode == null) return false;
    return shows.value[showId]?.contains(keyFor(season, episode)) ?? false;
  }

  /// The last episode finished, as (season, episode).
  static (int, int)? lastFinished(String showId) {
    final list = shows.value[showId];
    if (list == null || list.isEmpty) return null;
    final parts = list.last.split(':');
    final s = int.tryParse(parts.first);
    final e = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return s == null || e == null ? null : (s, e);
  }

  static Future<void> markFinished(
    String showId,
    int season,
    int episode,
  ) async {
    final key = keyFor(season, episode);
    final list = [...?shows.value[showId]]
      ..remove(key)
      ..add(key);
    shows.value = {...shows.value, showId: list};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(shows.value));
  }
}
