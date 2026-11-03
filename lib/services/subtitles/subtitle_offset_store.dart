import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/subtitle/subtitle_model.dart';

/// Subtitle timing the viewer set by hand, remembered per title and subtitle.
///
/// A subtitle that ran early in one episode runs early in the next when it is
/// the same release from the same provider, so the key leaves the episode
/// number out of the subtitle's name: "Show.S01E02.1080p.WEB-DL" and
/// "Show.S01E03.1080p.WEB-DL" share a timing.
abstract final class SubtitleOffsetStore {
  static const String _key = 'subtitle_offsets_v1';

  /// The most offsets kept; the oldest go first.
  static const int _limit = 300;

  static String keyFor(String titleId, SubtitleVariant variant) {
    final name = variant.title
        .toLowerCase()
        .replaceAll(RegExp(r's\d{1,2}\s*e\d{1,4}'), '')
        .replaceAll(RegExp(r'\b(e|ep|episode)\s*\d{1,4}\b'), '')
        .replaceAll(RegExp(r'第\s*\d+\s*[集话話]'), '')
        .replaceAll(RegExp(r'\b\d{1,3}\b'), '')
        .replaceAll(RegExp(r'[^a-z0-9一-鿿]+'), ' ')
        .trim();
    return '$titleId|${variant.providerName.toLowerCase()}|$name';
  }

  static Future<Map<String, dynamic>> _all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// The offset saved for [key] in seconds, or null.
  static Future<double?> load(String key) async {
    final value = (await _all())[key];
    return value is num ? value.toDouble() : null;
  }

  /// Saves [seconds] for [key]; zero forgets it.
  static Future<void> save(String key, double seconds) async {
    final all = await _all();
    all.remove(key);
    if (seconds.abs() >= 0.05) all[key] = (seconds * 100).round() / 100;
    while (all.length > _limit) {
      all.remove(all.keys.first);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(all));
  }
}
