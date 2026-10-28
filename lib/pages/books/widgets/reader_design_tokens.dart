import 'package:flutter/material.dart';

import '../../../ui/lu_theme.dart';

/// Reader chrome vocabulary for the book reader.
///
/// The reader family draws two different things: the *page* - paper surface,
/// book text metrics, the light/sepia/dark/amoled swatches - and the *chrome*
/// around it - bars, drawer, customisation sheet, zoom and focus controls.
/// Page values are product data and stay on `ReaderSettingsData`; the chrome
/// wears Lumora's cinema look (`lib/ui/lu_theme.dart`): the near-black ground,
/// glass surfaces and the one gold accent. This class is the bridge, so a
/// reader helper without a `BuildContext` still reads the same colours.
class ReaderTokens {
  ReaderTokens._();

  // ──────────────────────────────────────────────────────────────────────────
  // 1. CHROME COLOURS (Lumora)
  // ──────────────────────────────────────────────────────────────────────────
  /// Page background of reader chrome scrims and the comic/AMOLED backdrop.
  static Color get bg => LuColors.bg;

  /// Recessed tiles inside chrome: chips, control fills, cover placeholders.
  static Color get surface => LuColors.surfaceHigh;

  /// Bars sitting on top of the page (reader top/bottom chrome, drawer).
  static Color get surfaceRaised => LuColors.surface;

  /// Floating chrome above the page: focus pills, zoom bar, customisation sheet.
  static Color get surfaceOverlay => LuColors.surface;

  static Color get borderSubtle => LuColors.lineSoft;
  static Color get borderDefault => LuColors.line;
  static Color get borderStrong => const Color(0xFF3A3832);

  static Color get textPrimary => LuColors.text;
  static Color get textEmphasis => LuColors.textSoft;
  static Color get textSecondary => LuColors.textMuted;
  static Color get textMuted => LuColors.textFaint;
  static Color get textDisabled => const Color(0xFF5E5A53);

  static Color get accent => LuColors.gold;
  static Color get accentSubtle => const Color(0x29F2B544);
  static Color get onAccent => LuColors.onGold;

  static Color get success => LuColors.success;
  static Color get danger => LuColors.danger;

  /// 1px hairline in the default border role, for `Border`/`Divider` sides.
  static BorderSide get hairline => const BorderSide(color: LuColors.line);

  /// 1px hairline in the strong divider role.
  static BorderSide get hairlineStrong =>
      const BorderSide(color: Color(0xFF3A3832));

  // ──────────────────────────────────────────────────────────────────────────
  // 2. SPACING SCALE (4pt base)
  // ──────────────────────────────────────────────────────────────────────────
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;
  static const double space64 = 64;

  // ──────────────────────────────────────────────────────────────────────────
  // 3. RADIUS SCALE (Lumora: 12 fields, 24 cards, pills)
  // ──────────────────────────────────────────────────────────────────────────
  static const double radius4 = 6;
  static const double radius8 = 10;
  static const double radius12 = 12;
  static const double radius16 = 16;
  static const double radius24 = 24;
  static const double radius32 = 999;

  static const BorderRadius rounded4 = BorderRadius.all(Radius.circular(6));
  static const BorderRadius rounded8 = BorderRadius.all(Radius.circular(10));
  static const BorderRadius rounded12 = LuRadius.field;
  static const BorderRadius rounded16 = BorderRadius.all(Radius.circular(16));
  static const BorderRadius rounded24 = LuRadius.card;
  static const BorderRadius rounded32 = LuRadius.pill;

  // ──────────────────────────────────────────────────────────────────────────
  // 4. ELEVATION & CUSTOM SOFT SHADOWS
  // ──────────────────────────────────────────────────────────────────────────
  /// Subtle shadow for small floating elements, exit pills, and list cards.
  ///
  /// The reader keeps its own elevation scale: the contract layer carries no
  /// shadow token, and callers place these in `const` shadow lists.
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x0F000000), // alpha 0.06
    blurRadius: 8.0,
    spreadRadius: 0.0,
    offset: Offset(0, 2),
  );

  /// Medium soft shadow for book covers, customization sheet, and floating chevrons
  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x1A000000), // alpha 0.10
    blurRadius: 16.0,
    spreadRadius: 0.0,
    offset: Offset(0, 4),
  );

  /// Ambient spotlight glow for the Focus Mode active line box, tinted with the
  /// active accent so the highlight matches the chrome it sits in.
  static BoxShadow shadowGlow(Color accentColor) {
    return BoxShadow(
      color: accentColor.withValues(alpha: 0.22),
      blurRadius: 20.0,
      spreadRadius: 0.0,
      offset: Offset.zero,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. MOTION TOKENS
  // ──────────────────────────────────────────────────────────────────────────
  // The reader's timings are its own choreography — chrome fade, focus-line
  // slide, per-line dim, sheet and theme crossfade lag each other deliberately —
  // so they stay off the contract's 120/200/320 steps.

  /// Micro feedback (button press, chip select)
  static const Duration motionFast = Duration(milliseconds: 120);
  static const Curve curveFast = Curves.easeOut;

  /// Top and bottom bar chrome fade + slide
  static const Duration motionChrome = Duration(milliseconds: 200);
  static const Curve curveChrome = Curves.easeInOutCubic;

  /// Focus mode highlight box sliding animation
  static const Duration motionFocusLine = Duration(milliseconds: 220);
  static const Curve curveFocusLine = Curves.easeInOutCubic;

  /// Focus mode per-line dim / undim (lags slightly behind box for natural lighting)
  static const Duration motionFocusOpacity = Duration(milliseconds: 260);
  static const Curve curveFocusOpacity = Curves.easeInOut;

  /// Customization sheet / drawer open & close
  static const Duration motionSheet = Duration(milliseconds: 260);
  static const Curve curveSheet = Curves.easeOutCubic;

  /// Theme switch crossfade
  static const Duration motionThemeSwitch = Duration(milliseconds: 300);
  static const Curve curveThemeSwitch = Curves.easeInOut;

  // ──────────────────────────────────────────────────────────────────────────
  // 6. TYPOGRAPHY
  // ──────────────────────────────────────────────────────────────────────────
  /// Reader UI font keys. Chrome text follows the shared type scale and the
  /// ambient theme family; these keys are the reader's own font vocabulary for
  /// book content (`ReaderSettingsData.fontFamily`).
  static const String uiFont = 'Poppins';
  static const String defaultSerifFont = 'Georgia';

  /// Chrome type roles - Lumora's, so reader chrome reads like the shell.
  static TextStyle get caption => LuText.body.copyWith(fontSize: 14);

  static TextStyle get primaryLabel =>
      LuText.body.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get tabLabel =>
      LuText.label.copyWith(fontWeight: FontWeight.w700);
}
