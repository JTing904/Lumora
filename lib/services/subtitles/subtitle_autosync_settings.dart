import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the player lines a subtitle up with the film by itself.
abstract final class SubtitleAutoSyncSettings {
  static const String _key = 'subtitle_autosync_enabled';

  /// On unless the viewer turned it off.
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_key) ?? true;
      _loaded = true;
    } catch (_) {}
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}
