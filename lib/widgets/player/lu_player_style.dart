import 'package:flutter/material.dart';

import '../../services/theme/design_tokens.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';

/// The token set the player panels and the Live TV pages read, pinned to
/// Lumora's cinema palette.
///
/// These screens were written against `context.tokens`, which follows the
/// accent preset a viewer picks in settings; the rewritten Lumora pages read
/// [LuColors] and do not. Reading this constant instead keeps the player's
/// sheets and the Live TV pages gold-on-near-black like the rest of the app,
/// without renaming the hundreds of `tokens.*` reads they spell.
const ZplayTokens luTokens = ZplayTokens(
  bg: LuColors.bg,
  surface: LuColors.surface,
  surfaceRaised: LuColors.surfaceHigh,
  surfaceOverlay: LuColors.surfaceHigh,
  borderSubtle: Color(0x0FFFFFFF),
  borderDefault: Color(0x17FFFFFF),
  borderStrong: Color(0x24FFFFFF),
  textPrimary: LuColors.text,
  textEmphasis: LuColors.textSoft,
  textSecondary: LuColors.textMuted,
  textMuted: LuColors.textFaint,
  textDisabled: Color(0xFF6E6A62),
  accent: LuColors.gold,
  accentHover: LuColors.goldLight,
  accentPressed: Color(0xFFD99A2B),
  accentSubtle: Color(0xFF382E1F),
  onAccent: LuColors.onGold,
  success: LuColors.success,
  warning: LuColors.goldLight,
  danger: LuColors.danger,
  info: Color(0xFF8EC5E8),
);

/// The one panel look for sheets, side panels and menus over video or over
/// the Live TV page: a dark translucent surface, a faint edge, generous
/// radii, and gold for whatever is selected.
abstract final class LuPanel {
  /// [LuColors.surface] at 92%.
  static const Color fill = Color(0xEB141418);

  /// A row or chip at rest inside a panel.
  static const Color rowFill = Color(0x0DFFFFFF);

  /// A row or chip under the pointer or the remote.
  static const Color rowHover = Color(0x1AFFFFFF);

  /// The selected row: a gold wash under a gold hairline.
  static const Color selectedFill = Color(0x26F2B544);
  static const Color selectedEdge = Color(0x80F2B544);

  static const Color edge = LuColors.glassEdge;

  static const double radius = 20;
  static const double rowRadius = 16;
  static const BorderRadius radiusAll = BorderRadius.all(
    Radius.circular(radius),
  );
  static const BorderRadius rowRadiusAll = BorderRadius.all(
    Radius.circular(rowRadius),
  );

  /// The top of a bottom sheet.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(24),
  );

  static BoxDecoration decoration({
    BorderRadius borderRadius = radiusAll,
    Color color = fill,
  }) => BoxDecoration(
    color: color,
    borderRadius: borderRadius,
    border: Border.all(color: edge),
    boxShadow: const [
      BoxShadow(
        color: Color(0x99000000),
        offset: Offset(0, 18),
        blurRadius: 48,
        spreadRadius: -12,
      ),
    ],
  );

  /// A row's fill for its state, selected beating highlighted.
  static Color rowColor({required bool selected, required bool highlighted}) {
    if (selected) return selectedFill;
    return highlighted ? rowHover : Colors.transparent;
  }
}

/// A round icon action for a panel's or dialog's header (close, settings,
/// back): a [LuFocusable] disc, so a remote sees the gold ring land on it.
class LuIconAction extends StatelessWidget {
  const LuIconAction({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.size = 40,
    this.iconSize = 20,
    this.color,
  });

  final IconData icon;

  /// Read by screen readers and shown as the tooltip.
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 400),
      child: LuFocusable(
        onTap: onPressed,
        semanticLabel: label,
        lift: 1.0,
        builder: (context, highlighted) => AnimatedContainer(
          duration: LuMotion.focus,
          curve: LuMotion.ease,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted ? LuPanel.rowHover : LuPanel.rowFill,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: highlighted ? LuColors.text : (color ?? LuColors.textMuted),
          ),
        ),
      ),
    );
  }
}

/// [luTheme] plus the stock Material controls (icon, text, filled and
/// outlined buttons, chips, fields, switches, dialogs, snack bars) dressed
/// in the panel look, for the Live TV pages, sheets and dialogs that still
/// build some of them. Each gets the gold focus outline a remote reads, as
/// the [LuFocusable] controls draw; a call site's own style still wins
/// property by property.
ThemeData luPanelTheme() {
  final base = luTheme();
  WidgetStateProperty<BorderSide?> focusSide(
    Color focused, {
    BorderSide? rest,
  }) => WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? BorderSide(color: focused, width: 2)
        : rest,
  );
  final focusOverlay = WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.pressed)) return LuPanel.rowHover;
    if (states.contains(WidgetState.focused)) return const Color(0x1FF2B544);
    if (states.contains(WidgetState.hovered)) return LuPanel.rowHover;
    return null;
  });
  const fieldBorder = OutlineInputBorder(
    borderRadius: LuRadius.field,
    borderSide: BorderSide(color: LuColors.line),
  );
  return base.copyWith(
    extensions: const <ThemeExtension<dynamic>>[luTokens],
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        side: focusSide(LuColors.gold),
        overlayColor: focusOverlay,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(LuColors.gold),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        side: focusSide(LuColors.gold),
        overlayColor: focusOverlay,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(LuColors.gold),
        foregroundColor: const WidgetStatePropertyAll(LuColors.onGold),
        elevation: const WidgetStatePropertyAll(0),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        // Gold on gold is no outline: a focused gold button is ringed in ink.
        side: focusSide(LuColors.text),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(LuColors.gold),
        foregroundColor: const WidgetStatePropertyAll(LuColors.onGold),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        side: focusSide(LuColors.text),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(LuColors.text),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        side: focusSide(
          LuColors.gold,
          rest: const BorderSide(color: LuColors.line),
        ),
        overlayColor: focusOverlay,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: LuPanel.rowFill,
      selectedColor: LuPanel.selectedFill,
      checkmarkColor: LuColors.gold,
      side: const BorderSide(color: LuPanel.edge),
      shape: const StadiumBorder(),
      labelStyle: LuText.label,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: LuColors.field,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: LuRadius.field,
        borderSide: BorderSide(color: LuColors.gold, width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? LuColors.onGold
            : LuColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? LuColors.gold
            : LuColors.surfaceHigh,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? LuColors.gold : null,
      ),
      checkColor: const WidgetStatePropertyAll(LuColors.onGold),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: LuColors.surface,
      shape: RoundedRectangleBorder(borderRadius: LuRadius.card),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LuColors.surfaceHigh,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: LuRadius.field),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: LuColors.gold,
    ),
    dividerTheme: const DividerThemeData(color: LuColors.lineSoft),
  );
}
