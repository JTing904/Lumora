import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether pressing play picks a source by itself, and the highest quality it
/// may pick.
///
/// On (the default), the source list opens and plays the fastest source that
/// is known to work as soon as the scrapers have answered, so the viewer goes
/// from 播放 to the first frame without choosing. Off, the list waits for the
/// viewer to pick, as it always did. The details page toggles it.
abstract final class SourcePickSettings {
  static const String _storageKey = 'lumora_auto_pick_source';
  static const String _qualityKey = 'lumora_quality_cap';

  /// The qualities the player's 画质 button offers, highest first.
  static const List<String> qualities = ['4K', '1080p', '720p', '480p'];

  static final ValueNotifier<bool> autoPick = ValueNotifier<bool>(true);

  /// The viewer's 画质 choice: one of [qualities], or null for 自动, which
  /// picks the best the measured connection carries.
  static final ValueNotifier<String?> qualityCap = ValueNotifier<String?>(null);

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      autoPick.value = prefs.getBool(_storageKey) ?? true;
      final cap = prefs.getString(_qualityKey);
      qualityCap.value = qualities.contains(cap) ? cap : null;
    } catch (_) {
      autoPick.value = true;
      qualityCap.value = null;
    }
  }

  static Future<void> setAutoPick(bool value) async {
    autoPick.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, value);
    } catch (_) {}
  }

  static Future<void> setQualityCap(String? value) async {
    qualityCap.value = qualities.contains(value) ? value : null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (qualityCap.value == null) {
        await prefs.remove(_qualityKey);
      } else {
        await prefs.setString(_qualityKey, qualityCap.value!);
      }
    } catch (_) {}
  }
}
