import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/theme/design_tokens.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';

/// The Lumora settings kit: the theme, group card and rows the Me hub draws,
/// shared so every settings page underneath it looks like the hub.

/// Puts a settings page on the Lumora theme: true gold controls on the
/// near-black ground, and ZPlay tokens derived from the same colours so the
/// older token reads in a page body follow along.
class LuSettingsTheme extends StatelessWidget {
  const LuSettingsTheme({super.key, required this.child});

  final Widget child;

  static ThemeData data() {
    final base = luTheme();
    final tokens = ZplayTokens.derive(
      accent: LuColors.gold,
      bg: LuColors.bg,
      surface: LuColors.surface,
      surfaceRaised: LuColors.surfaceHigh,
    );
    WidgetStateProperty<Color?> track(Color on, Color off) =>
        WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? on : off,
        );
    // The app theme's focus styling for Material buttons, which `luTheme()`
    // does not carry: without it a remote user moving onto "Check for
    // updates", "Pair" or a save button sees no change at all, because the
    // default 8% overlay is invisible on the near-black ground. The overlay
    // is a strong gold tint rather than solid gold, because these buttons
    // draw gold labels and a solid overlay would swallow them.
    WidgetStateBorderSide focusRing([BorderSide? rest]) =>
        WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? const BorderSide(color: LuColors.gold, width: 2)
              : rest,
        );
    final focusOverlay = WidgetStateProperty.resolveWith<Color?>((s) {
      if (s.contains(WidgetState.focused)) return const Color(0x47F2B544);
      if (s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed)) {
        return const Color(0x29F2B544);
      }
      return null;
    });
    return base.copyWith(
      extensions: [tokens],
      // A filled button is usually gold already, so a gold ring would vanish
      // into it: focus there is a light ring and a light lift instead.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((s) {
            if (s.contains(WidgetState.focused)) return const Color(0x33FFFFFF);
            if (s.contains(WidgetState.hovered) ||
                s.contains(WidgetState.pressed)) {
              return const Color(0x1FFFFFFF);
            }
            return null;
          }),
          side: WidgetStateBorderSide.resolveWith(
            (s) => s.contains(WidgetState.focused)
                ? const BorderSide(color: LuColors.text, width: 3)
                : null,
          ),
        ),
      ),
      // The back chevron and other round icon buttons: a gold ring a remote
      // user can see, where Material's default is a faint grey disc.
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(overlayColor: focusOverlay, side: focusRing()),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          overlayColor: focusOverlay,
          side: focusRing(const BorderSide(color: LuColors.line)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(overlayColor: focusOverlay, side: focusRing()),
      ),
      dividerTheme: const DividerThemeData(color: LuColors.lineSoft, space: 1),
      switchTheme: SwitchThemeData(
        trackColor: track(LuColors.gold, const Color(0x1FFFFFFF)),
        thumbColor: track(LuColors.onGold, LuColors.textMuted),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 3,
        activeTrackColor: LuColors.gold,
        inactiveTrackColor: LuColors.line,
        thumbColor: LuColors.gold,
        overlayColor: Color(0x22F2B544),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? LuColors.gold : null,
        ),
        checkColor: const WidgetStatePropertyAll(LuColors.onGold),
      ),
      radioTheme: const RadioThemeData(
        fillColor: WidgetStatePropertyAll(LuColors.gold),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: LuColors.surface,
        selectedColor: const Color(0x29F2B544),
        side: const BorderSide(color: LuColors.line),
        shape: const StadiumBorder(),
        labelStyle: LuText.caption.copyWith(color: LuColors.text),
        checkmarkColor: LuColors.gold,
      ),
      cardTheme: const CardThemeData(
        color: LuColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: LuColors.lineSoft),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: LuColors.gold,
        textColor: LuColors.text,
        titleTextStyle: LuText.body.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: LuText.caption.copyWith(color: LuColors.textMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LuColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: LuText.body,
        actionTextColor: LuColors.gold,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: LuColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: LuRadius.card),
        titleTextStyle: LuText.title,
        contentTextStyle: LuText.bodySoft,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: LuColors.surface,
        modalBackgroundColor: LuColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: LuColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        textStyle: LuText.body,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: LuColors.text,
        unselectedLabelColor: LuColors.textMuted,
        indicatorColor: LuColors.gold,
        dividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(data: data(), child: child);
}

/// A group's small heading, above its card.
class LuSettingsLabel extends StatelessWidget {
  const LuSettingsLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      text,
      style: LuText.label.copyWith(color: LuColors.textFaint, letterSpacing: 1),
    ),
  );
}

/// The rounded surface a group's rows sit in.
class LuSettingsCard extends StatelessWidget {
  const LuSettingsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  // A Material rather than a decorated box, so list tiles and ink inside it
  // paint on the card itself.
  Widget build(BuildContext context) => Material(
    color: LuColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      side: BorderSide(color: LuColors.lineSoft),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

/// A labelled card of rows with hairlines between them.
class LuSettingsGroup extends StatelessWidget {
  const LuSettingsGroup({super.key, this.label, required this.rows});

  final String? label;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (label != null) LuSettingsLabel(label!),
      LuSettingsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(color: LuColors.lineSoft, height: 1),
              rows[i],
            ],
          ],
        ),
      ),
    ],
  );
}

class LuSettingsNavRow extends StatelessWidget {
  final IconData icon;

  /// Unused: every row's glyph is gold. Kept so callers need not change.
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? valueText;
  final VoidCallback onTap;

  const LuSettingsNavRow({
    required this.icon,
    super.key,
    this.iconColor,
    required this.title,
    this.subtitle = '',
    this.valueText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The whole row is the control and the ring is the row's own rect: on a
    // television the ring says what a press hits, and the whole row does.
    return LuFocusable(
      onTap: onTap,
      lift: 1,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      builder: (context, hi) => LuSettingsRowBody(
        icon: icon,
        title: title,
        subtitle: subtitle,
        valueText: valueText,
        highlighted: hi,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 22,
          color: LuColors.textFaint,
        ),
      ),
    );
  }
}

/// One settings row's anatomy: a gold glyph in a soft disc, the name and what
/// it does, the value it holds, and the trailing control.
class LuSettingsRowBody extends StatelessWidget {
  const LuSettingsRowBody({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    required this.highlighted,
    required this.trailing,
    this.valueText,
    this.titleTrailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final Widget trailing;
  final String? valueText;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: LuMotion.focus,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0x0FFFFFFF) : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x1FF2B544),
            ),
            child: Icon(icon, size: 19, color: LuColors.gold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: LuText.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: highlighted
                              ? LuColors.goldLight
                              : LuColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 6),
                      titleTrailing!,
                    ],
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: LuText.caption.copyWith(color: LuColors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (valueText?.isNotEmpty ?? false) ...[
            const SizedBox(width: 12),
            // Capped, so on a narrow phone it gives way to the title rather
            // than pushing it to nothing.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width < 600 ? 72 : 220,
              ),
              child: Text(
                valueText!,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: LuText.caption.copyWith(
                  color: highlighted ? LuColors.text : LuColors.textMuted,
                ),
                maxLines: 1,
              ),
            ),
          ],
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Switch Row
// ─────────────────────────────────────────────────────────────────────────────

/// A toggle settings row inside a grouped section. Same anatomy as
/// [LuSettingsNavRow], with the switch at the trailing edge instead of a chevron.
class LuSettingsSwitchRow extends StatelessWidget {
  final IconData icon;

  /// Unused: every row's glyph is gold. Kept so callers need not change.
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? valueText;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onInfoTap;

  const LuSettingsSwitchRow({
    required this.icon,
    super.key,
    this.iconColor,
    required this.title,
    this.subtitle = '',
    this.valueText,
    required this.value,
    required this.onChanged,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    // The row is the focus target and its activation runs the same
    // [onChanged] the switch runs, so a remote and a pointer change the setting
    // identically.
    return LuFocusable(
      onTap: () => onChanged(!value),
      lift: 1,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      builder: (context, hi) => LuSettingsRowBody(
        icon: icon,
        title: title,
        subtitle: subtitle,
        valueText: valueText,
        highlighted: hi,
        titleTrailing: onInfoTap == null
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: LuColors.textMuted,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                tooltip: l10nOf(context).settingsP2pInfoTooltip,
                onPressed: onInfoTap,
              ),
        // `ExcludeFocus`: the row is the focus target; a pointer still lands
        // on the switch itself.
        trailing: ExcludeFocus(
          child: Transform.scale(
            scale: 0.9,
            child: Switch.adaptive(
              value: value,
              activeThumbColor: LuColors.onGold,
              activeTrackColor: LuColors.gold,
              inactiveThumbColor: LuColors.textMuted,
              inactiveTrackColor: const Color(0x1FFFFFFF),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}
