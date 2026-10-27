import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app language choice. `null` follows the system.
///
/// Lumora opens in English until the user picks something else, so "follow the
/// system" is stored as its own value rather than as the absence of one.
abstract final class LocaleSettings {
  static const String _storageKey = 'zplay_locale';
  static const String systemCode = 'system';

  static const Locale defaultLocale = Locale('en');

  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(
    defaultLocale,
  );

  /// The stored choice, or [systemCode].
  static String get code =>
      locale.value == null ? systemCode : locale.value!.languageCode;

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      locale.value = switch (stored) {
        'en' => const Locale('en'),
        'zh' => const Locale('zh'),
        systemCode => null,
        _ => defaultLocale,
      };
    } catch (_) {
      locale.value = defaultLocale;
    }
  }

  /// Applies and persists a language. [systemCode] means follow the device.
  static Future<void> setLocale(String code) async {
    final next = switch (code) {
      'en' => const Locale('en'),
      'zh' => const Locale('zh'),
      _ => null,
    };
    locale.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, next?.languageCode ?? systemCode);
    } catch (_) {}
  }
}
