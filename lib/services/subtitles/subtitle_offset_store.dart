import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/subtitle/subtitle_model.dart';

/// Subtitle timing the viewer set by hand, remembered per title and subtitle.
///
/// A subtitle that ran early in one episode runs early in the next when it is
/// the same release from the same provider, so the key leaves the episode
/// number out of the subtitle's name: "Show.S01E02.1080p.WEB-DL" and
/// "Show.S01E03.1080p.WEB-DL" share a timing.
/// A remembered timing: the delay, the stretch of the subtitle's clock
/// (1 = none) and whether the app found it rather than the viewer.
class SubtitleTiming {
  const SubtitleTiming(this.delaySec, {this.ratio = 1, this.auto = false});

  final double delaySec;
  final double ratio;

  /// Set by the auto-sync. One the viewer set by hand is not overruled by it
  /// unless it is clearly wrong.
  final bool auto;
}

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
  static Future<double?> load(String key) async =>
      (await loadTiming(key))?.delaySec;

  /// Everything saved for [key], or null. An entry is a plain number (the
  /// viewer's offset, as before the auto-sync) or a map with the stretch and
  /// who set it, so older saves read the same.
  static Future<SubtitleTiming?> loadTiming(String key) async {
    final value = (await _all())[key];
    if (value is num) return SubtitleTiming(value.toDouble());
    if (value is Map) {
      final d = value['d'];
      final r = value['r'];
      if (d is! num) return null;
      return SubtitleTiming(
        d.toDouble(),
        ratio: r is num && r > 0.5 && r < 2 ? r.toDouble() : 1,
        auto: value['a'] == 1,
      );
    }
    return null;
  }

  /// Saves [seconds] for [key] as the viewer's own; zero forgets it.
  static Future<void> save(String key, double seconds) =>
      saveTiming(key, SubtitleTiming(seconds));

  /// Saves [timing] for [key]; no delay and no stretch forgets it.
  static Future<void> saveTiming(String key, SubtitleTiming timing) async {
    final all = await _all();
    all.remove(key);
    final seconds = timing.delaySec;
    final stretched = (timing.ratio - 1).abs() > 1e-6;
    if (seconds.abs() >= 0.05 || stretched) {
      final d = (seconds * 100).round() / 100;
      all[key] = stretched || timing.auto
          ? {
              'd': d,
              if (stretched) 'r': double.parse(timing.ratio.toStringAsFixed(6)),
              if (timing.auto) 'a': 1,
            }
          : d;
    }
    while (all.length > _limit) {
      all.remove(all.keys.first);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(all));
  }
}
