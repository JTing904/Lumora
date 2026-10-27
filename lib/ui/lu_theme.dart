import 'package:flutter/material.dart';

/// Lumora's look, "影院风": a near-black ground, one gold accent, Noto Sans SC
/// for words and Outfit for the wordmark and numerals.
///
/// Every page rewritten for Lumora takes its colours, type, spacing and motion
/// from here and nowhere else; nothing in `lib/ui/` reads the inherited
/// ZPlay tokens.
abstract final class LuColors {
  /// The ground every screen stands on.
  static const Color bg = Color(0xFF0A0A0C);

  /// Cards, sheets, fields.
  static const Color surface = Color(0xFF141418);
  static const Color surfaceHigh = Color(0xFF1C1C22);
  static const Color field = Color(0xFF101013);

  /// Glass over pictures: cards on the poster wall.
  static const Color glass = Color(0xC7141418);
  static const Color glassEdge = Color(0x14FFFFFF);

  static const Color line = Color(0xFF2E2D29);
  static const Color lineSoft = Color(0xFF23221F);

  /// The one accent: buttons, focus, the active tab.
  static const Color gold = Color(0xFFF2B544);
  static const Color goldLight = Color(0xFFFFD27A);
  static const Color goldShadow = Color(0xFF9A6A1C);

  /// Text on gold.
  static const Color onGold = Color(0xFF1A1408);

  static const Color text = Color(0xFFF4F1EA);
  static const Color textSoft = Color(0xFFD8D3C8);
  static const Color textMuted = Color(0xFFB4AFA5);
  static const Color textFaint = Color(0xFF8F8A80);

  static const Color danger = Color(0xFFFF7A6B);
  static const Color success = Color(0xFF7FD6A4);
}

abstract final class LuFonts {
  static const String text = 'NotoSansSC';
  static const String display = 'Outfit';
}

abstract final class LuText {
  static const TextStyle _base = TextStyle(
    fontFamily: LuFonts.text,
    color: LuColors.text,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Page titles on a hero: 76 on desktop, scaled down by the page.
  static final TextStyle hero = _base.copyWith(
    fontSize: 64,
    fontWeight: FontWeight.w900,
    height: 1.05,
    letterSpacing: 2,
  );
  static final TextStyle title = _base.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
  );
  static final TextStyle heading = _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle body = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle bodySoft = body.copyWith(
    fontSize: 15,
    color: LuColors.textMuted,
    height: 1.6,
  );
  static final TextStyle label = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: LuColors.textSoft,
  );
  static final TextStyle caption = _base.copyWith(
    fontSize: 13,
    color: LuColors.textFaint,
  );
  static final TextStyle button = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// The wordmark, "Lumora".
  static const TextStyle wordmark = TextStyle(
    fontFamily: LuFonts.display,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: LuColors.text,
    height: 1.1,
  );
}

abstract final class LuSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 14;
  static const double l = 22;
  static const double xl = 32;
  static const double xxl = 48;

  /// The side margin of a desktop page.
  static const double page = 64;
}

abstract final class LuRadius {
  static const BorderRadius field = BorderRadius.all(Radius.circular(12));
  static const BorderRadius card = BorderRadius.all(Radius.circular(24));
  static const BorderRadius poster = BorderRadius.all(Radius.circular(10));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

abstract final class LuMotion {
  /// A focus or hover change: quick enough to follow a remote held down.
  static const Duration focus = Duration(milliseconds: 180);
  static const Duration page = Duration(milliseconds: 420);
  static const Curve ease = Curves.easeOutCubic;
}

/// The Material theme the Lumora pages run under, so stock widgets (text
/// selection, scrollbars, dialogs) match without per-widget styling.
ThemeData luTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: LuColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: LuColors.gold,
      onPrimary: LuColors.onGold,
      surface: LuColors.surface,
      onSurface: LuColors.text,
      error: LuColors.danger,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: LuFonts.text,
      bodyColor: LuColors.text,
      displayColor: LuColors.text,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: LuColors.gold,
      selectionColor: Color(0x55F2B544),
      selectionHandleColor: LuColors.gold,
    ),
  );
}
