import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global 18+ content switch, available to admins only.
///
/// Single source of truth for whether adult material may surface anywhere in
/// the app: catalog fetches, addon catalogs/search/streams,
/// the WatchHentai / Hentaini extractors, and saved state (Continue
/// Watching, My List, library). Sources read [adultEnabled] at query time.
/// Pages listening to [adultEnabled] evict their adult-sensitive caches
/// (catalog listings, recommendation sections) and reload on toggle, so one
/// flip refreshes visible content with no restart.
///
/// [adultEnabled] can only be true while [isAdmin] is true. Admin status comes
/// from the signed-in account (set server-side, never by the user), and losing
/// it - signing out, switching accounts - forces the switch off. The admin's
/// own preference is kept and comes back the next time they sign in.
abstract final class ContentSettings {
  static const _keyAdultEnabled = 'content_adult_enabled';

  /// Whether the signed-in account may use adult content. False until an
  /// account says otherwise via [setAdmin].
  static final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);

  /// Off by default: the app never surfaces NSFW content unless an admin asks.
  static final ValueNotifier<bool> adultEnabled = ValueNotifier<bool>(false);

  /// Nobody is an admin at startup, so the switch starts off whatever was
  /// stored; [setAdmin] restores the stored preference once the account is
  /// known.
  ///
  /// Only while no admin is known: the account check starts before this runs
  /// and may already have restored an admin's switch.
  static Future<void> initialize() async {
    if (!isAdmin.value) adultEnabled.value = false;
  }

  /// Called by the auth layer whenever the signed-in account changes.
  static Future<void> setAdmin(bool value) async {
    isAdmin.value = value;
    if (!value) {
      adultEnabled.value = false;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      adultEnabled.value = prefs.getBool(_keyAdultEnabled) ?? false;
    } catch (e) {
      debugPrint('[ContentSettings] Error restoring adult content state: $e');
    }
  }

  static Future<void> setAdultEnabled(bool value) async {
    if (value && !isAdmin.value) return;
    adultEnabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAdultEnabled, value);
    } catch (e) {
      debugPrint('[ContentSettings] Error saving adult content state: $e');
    }
  }
}
