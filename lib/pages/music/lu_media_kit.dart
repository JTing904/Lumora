import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../services/layout/form_factor.dart';
import '../../services/storage/app_image_cache.dart';
import '../../services/theme/design_tokens.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';

/// The Lumora "cinema" look for Music and Audiobooks: [luTheme] plus the
/// inherited token set re-cut from [LuColors], so the shared controls these
/// pages still use (the physics buttons, the seek bars, the old focus ring)
/// paint gold on the near-black ground instead of the studio palettes.
///
/// Stock Material controls are themed here too, so a Switch, a Slider, a
/// dialog or an [IconButton] on these pages reads as Lumora without per-widget
/// styling - and an [IconButton] draws the gold ring when a remote lands on it.
ThemeData luMediaTheme() {
  final base = luTheme();
  const white = Color(0xFFFFFFFF);
  final tokens = ZplayTokens(
    bg: LuColors.bg,
    surface: LuColors.surface,
    surfaceRaised: LuColors.surfaceHigh,
    surfaceOverlay: LuColors.surfaceHigh,
    borderSubtle: LuColors.lineSoft,
    borderDefault: LuColors.line,
    borderStrong: white.withValues(alpha: 0.18),
    textPrimary: LuColors.text,
    textSecondary: LuColors.textMuted,
    textMuted: LuColors.textFaint,
    textDisabled: const Color(0xFF5C584F),
    textEmphasis: LuColors.textSoft,
    accent: LuColors.gold,
    accentHover: LuColors.goldLight,
    accentPressed: LuColors.goldShadow,
    accentSubtle: Color.lerp(LuColors.surface, LuColors.gold, 0.16)!,
    onAccent: LuColors.onGold,
    success: LuColors.success,
    warning: LuColors.goldLight,
    danger: LuColors.danger,
    info: LuColors.success,
  );

  WidgetStateProperty<BorderSide?> focusRing() =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? const BorderSide(color: LuColors.gold, width: 2)
            : null,
      );

  return base.copyWith(
    extensions: [tokens],
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? LuColors.textFaint.withValues(alpha: 0.5)
              : null,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.focused) || s.contains(WidgetState.hovered)
              ? const Color(0x1FFFFFFF)
              : null,
        ),
        side: focusRing(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(LuColors.gold),
        side: focusRing(),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
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
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.focused)
            ? LuColors.gold
            : (s.contains(WidgetState.selected)
                  ? LuColors.gold
                  : LuColors.line),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: LuColors.gold,
      inactiveTrackColor: Color(0x33FFFFFF),
      thumbColor: LuColors.gold,
      overlayColor: Color(0x33F2B544),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: LuColors.gold,
      linearTrackColor: Color(0x26FFFFFF),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: LuColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: LuRadius.card),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LuColors.surfaceHigh,
      contentTextStyle: LuText.label.copyWith(color: LuColors.text),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: LuRadius.field),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: const BoxDecoration(
        color: LuColors.surfaceHigh,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      textStyle: LuText.caption.copyWith(color: LuColors.text),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: LuColors.textMuted,
      textColor: LuColors.text,
      selectedColor: LuColors.gold,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LuColors.field,
      hintStyle: LuText.body.copyWith(color: const Color(0xFF77736B)),
      labelStyle: LuText.label,
      border: const OutlineInputBorder(
        borderRadius: LuRadius.field,
        borderSide: BorderSide(color: LuColors.line),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: LuRadius.field,
        borderSide: BorderSide(color: LuColors.line),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: LuRadius.field,
        borderSide: BorderSide(color: LuColors.gold, width: 1.5),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: LuColors.surfaceHigh,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

/// The page's side gutter: the same three steps the category pages use.
double luMediaPad(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return 16;
  if (FormFactorService.of(context) == FormFactor.television) return 48;
  return width < 1100 ? 32 : LuSpace.page;
}

bool luMediaIsTv(BuildContext context) =>
    FormFactorService.of(context) == FormFactor.television;

/// Artwork from the network, a local file, or the ground with an icon while
/// there is neither.
class LuMediaArt extends StatelessWidget {
  const LuMediaArt({
    super.key,
    this.url,
    this.filePath,
    this.cacheWidth = 400,
    this.icon = Icons.music_note_rounded,
    this.httpHeaders,
  });

  final String? url;
  final String? filePath;
  final int cacheWidth;
  final IconData icon;
  final Map<String, String>? httpHeaders;

  @override
  Widget build(BuildContext context) {
    final blank = ColoredBox(
      color: LuColors.surfaceHigh,
      child: Center(child: Icon(icon, color: LuColors.textFaint, size: 32)),
    );
    final path = filePath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => blank,
      );
    }
    final u = url?.trim();
    if (u == null || u.isEmpty) return blank;
    if (!u.startsWith('http')) {
      if (File(u).existsSync()) {
        return Image.file(
          File(u),
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          errorBuilder: (_, __, ___) => blank,
        );
      }
      return blank;
    }
    return CachedNetworkImage(
      imageUrl: u,
      cacheManager: AppImageCache.manager,
      memCacheWidth: cacheWidth,
      httpHeaders: httpHeaders,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, __) => blank,
      errorWidget: (_, __, ___) => blank,
    );
  }
}

/// A square cover with its name and a line under it: an album, a playlist, a
/// track, an audiobook. [circle] draws an artist's round portrait instead.
class LuMediaCover extends StatelessWidget {
  const LuMediaCover({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
    this.filePath,
    this.width = 160,
    this.circle = false,
    this.showPlay = false,
    this.badge,
    this.icon = Icons.music_note_rounded,
    this.onLongPress,
    this.httpHeaders,
    this.heroTag,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? filePath;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double width;
  final bool circle;

  /// A gold play disc at the corner while the card is highlighted.
  final bool showPlay;

  /// A small label on the art (a source, "torrent").
  final Widget? badge;
  final IconData icon;
  final Map<String, String>? httpHeaders;
  final Object? heroTag;

  static const BorderRadius radius = BorderRadius.all(Radius.circular(16));

  /// The card's height for [width] at the viewer's text size.
  static double heightFor(
    double width, [
    TextScaler scaler = TextScaler.noScaling,
  ]) => width + 10 + scaler.scale(44);

  @override
  Widget build(BuildContext context) {
    final r = circle ? BorderRadius.circular(width / 2) : radius;
    Widget art = LuMediaArt(
      url: imageUrl,
      filePath: filePath,
      cacheWidth: (width * 2.5).round(),
      icon: icon,
      httpHeaders: httpHeaders,
    );
    if (heroTag != null) art = Hero(tag: heroTag!, child: art);
    return SizedBox(
      width: width,
      child: LuFocusable(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: r,
        semanticLabel: title,
        builder: (context, highlighted) => Column(
          crossAxisAlignment: circle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: width,
              child: ClipRRect(
                borderRadius: r,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    art,
                    if (badge != null)
                      Positioned(left: 8, top: 8, child: badge!),
                    AnimatedOpacity(
                      opacity: highlighted ? 1 : 0,
                      duration: LuMotion.focus,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: Color(0x1FFFFFFF)),
                      ),
                    ),
                    if (showPlay)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: AnimatedOpacity(
                          opacity: highlighted ? 1 : 0,
                          duration: LuMotion.focus,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: LuColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: LuColors.onGold,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: circle ? TextAlign.center : TextAlign.start,
              style: LuText.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: circle ? TextAlign.center : TextAlign.start,
                style: LuText.caption,
              ),
          ],
        ),
      ),
    );
  }
}

/// A round control: quiet glass at rest, gold when [primary], the gold ring
/// on focus. Every transport and chrome glyph on these pages is one of these.
class LuMediaIconButton extends StatelessWidget {
  const LuMediaIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 44,
    this.iconSize,
    this.primary = false,
    this.active = false,
    this.quiet = false,
    this.iconColor,
    this.focusNode,
    this.autofocus = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double? iconSize;

  /// The one gold disc a screen is for: play.
  final bool primary;

  /// A toggle that is on (shuffle, repeat): the glyph turns gold.
  final bool active;

  /// No fill at rest, only the glyph.
  final bool quiet;
  final Color? iconColor;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final button = LuFocusable(
      onTap: onTap,
      focusNode: focusNode,
      autofocus: autofocus,
      lift: primary ? 1.06 : 1.08,
      semanticLabel: tooltip,
      borderRadius: BorderRadius.circular(size / 2),
      builder: (context, highlighted) {
        final Color fill;
        if (primary) {
          fill = highlighted ? LuColors.goldLight : LuColors.gold;
        } else if (quiet) {
          fill = highlighted ? const Color(0x1FFFFFFF) : Colors.transparent;
        } else {
          fill = highlighted
              ? const Color(0x29FFFFFF)
              : const Color(0x14FFFFFF);
        }
        final fg =
            iconColor ??
            (primary
                ? LuColors.onGold
                : (active ? LuColors.gold : LuColors.text));
        return AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: LuMotion.focus,
          child: AnimatedContainer(
            duration: LuMotion.focus,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              boxShadow: primary
                  ? const [
                      BoxShadow(
                        color: Color(0x55F2B544),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: fg, size: iconSize ?? size * 0.5),
          ),
        );
      },
    );
    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// One option of a [LuPillTabs].
class LuPillOption<T> {
  const LuPillOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A row of pill filters: the chosen one gold, the rest glass, scrolling
/// sideways when they do not fit a phone. Arrow keys move along it.
class LuPillTabs<T> extends StatelessWidget {
  const LuPillTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.semanticsLabel,
    this.padding = EdgeInsets.zero,
    this.compact = false,
  });

  final List<LuPillOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String? semanticsLabel;
  final EdgeInsets padding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tv = luMediaIsTv(context);
    final height = tv ? 48.0 : (compact ? 36.0 : 40.0);
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: FocusTraversalGroup(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: padding,
          child: Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                _LuPill<T>(
                  option: options[i],
                  selected: options[i].value == selected,
                  height: height,
                  onTap: () => onSelected(options[i].value),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LuPill<T> extends StatelessWidget {
  const _LuPill({
    required this.option,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  final LuPillOption<T> option;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: LuFocusable(
        onTap: onTap,
        lift: 1.04,
        semanticLabel: option.label,
        builder: (context, highlighted) {
          final fg = selected ? LuColors.onGold : LuColors.text;
          return AnimatedContainer(
            duration: LuMotion.focus,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: selected
                  ? (highlighted ? LuColors.goldLight : LuColors.gold)
                  : (highlighted
                        ? const Color(0x29FFFFFF)
                        : const Color(0x12FFFFFF)),
              borderRadius: LuRadius.pill,
              border: selected
                  ? null
                  : Border.all(color: const Color(0x24FFFFFF)),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.icon != null) ...[
                    Icon(option.icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    option.label,
                    maxLines: 1,
                    style: LuText.label.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A section heading at the page gutter, with an optional muted count, a
/// line under it and a control at its end.
class LuMediaSectionTitle extends StatelessWidget {
  const LuMediaSectionTitle({
    super.key,
    required this.title,
    this.count,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final String title;
  final int? count;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final pad = luMediaPad(context);
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuText.heading,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '$count',
                        style: LuText.label.copyWith(
                          color: LuColors.textFaint,
                          fontFamily: LuFonts.display,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: LuText.caption),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A rounded 24 panel on the surface colour: banners, sheets, studio cards.
class LuMediaPanel extends StatelessWidget {
  const LuMediaPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = LuColors.surface,
    this.radius = LuRadius.card,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final BorderRadius radius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: LuColors.lineSoft),
      ),
      child: child,
    );
  }
}

/// A tappable panel: a [LuMediaPanel] that lifts and rings on focus.
class LuMediaTile extends StatelessWidget {
  const LuMediaTile({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.radius = LuRadius.card,
    this.lift = 1.02,
    this.semanticLabel,
    this.onLongPress,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;
  final BorderRadius radius;
  final double lift;
  final String? semanticLabel;

  /// Washed with gold: the row that is playing, the option that is chosen.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return LuFocusable(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: radius,
      lift: lift,
      semanticLabel: semanticLabel,
      builder: (context, highlighted) => AnimatedContainer(
        duration: LuMotion.focus,
        padding: padding,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0x29F2B544)
              : (highlighted ? LuColors.surfaceHigh : LuColors.surface),
          borderRadius: radius,
          border: Border.all(
            color: selected ? const Color(0x66F2B544) : LuColors.lineSoft,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A list row: no fill at rest, a soft wash when highlighted, gold when it is
/// the one playing.
class LuMediaRow extends StatelessWidget {
  const LuMediaRow({
    super.key,
    required this.child,
    required this.onTap,
    this.current = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.semanticLabel,
    this.onLongPress,
    this.minHeight,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool current;
  final EdgeInsets padding;
  final String? semanticLabel;
  final double? minHeight;

  static const BorderRadius radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    return LuFocusable(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: radius,
      lift: 1.01,
      semanticLabel: semanticLabel,
      builder: (context, highlighted) => AnimatedContainer(
        duration: LuMotion.focus,
        constraints: BoxConstraints(
          minHeight: minHeight ?? (luMediaIsTv(context) ? 60 : 52),
        ),
        padding: padding,
        decoration: BoxDecoration(
          color: current
              ? const Color(0x24F2B544)
              : (highlighted ? const Color(0x14FFFFFF) : Colors.transparent),
          borderRadius: radius,
        ),
        child: child,
      ),
    );
  }
}

/// A setting that is on or off, as one focusable row with a gold switch.
class LuMediaSwitchRow extends StatelessWidget {
  const LuMediaSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return LuMediaRow(
      onTap: () => onChanged(!value),
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: LuText.label)),
          const SizedBox(width: 12),
          ExcludeFocus(
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

/// A Lumora dialog: a heading, the body and a row of actions, Cancel first.
Future<T?> showLuMediaDialog<T>({
  required BuildContext context,
  required String title,
  IconData? icon,
  required Widget Function(BuildContext ctx, StateSetter setState) body,
  List<Widget> Function(BuildContext ctx)? actions,
  double maxWidth = 480,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => Theme(
      data: luMediaTheme(),
      child: StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: LuColors.surface,
          shape: const RoundedRectangleBorder(borderRadius: LuRadius.card),
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: LuColors.gold, size: 22),
                        const SizedBox(width: 10),
                      ],
                      Expanded(child: Text(title, style: LuText.heading)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: SingleChildScrollView(child: body(ctx, setState)),
                  ),
                  if (actions != null) ...[
                    const SizedBox(height: 22),
                    FocusTraversalGroup(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: actions(ctx),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A cover blown up and blurred behind a page: the cinema's backdrop, faded
/// into the ground at the foot.
class LuMediaBackdrop extends StatelessWidget {
  const LuMediaBackdrop({
    super.key,
    this.url,
    this.filePath,
    this.opacity = 0.42,
    this.httpHeaders,
  });

  final String? url;
  final String? filePath;
  final double opacity;
  final Map<String, String>? httpHeaders;

  @override
  Widget build(BuildContext context) {
    final hasArt =
        (url?.trim().isNotEmpty ?? false) || (filePath?.isNotEmpty ?? false);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: LuColors.bg),
        if (hasArt)
          Opacity(
            opacity: opacity,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: LuMediaArt(
                url: url,
                filePath: filePath,
                cacheWidth: 200,
                httpHeaders: httpHeaders,
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x660A0A0C), Color(0xCC0A0A0C), LuColors.bg],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
      ],
    );
  }
}

/// The ground's one ornament: a soft gold light from the top of the page.
/// What the "ambient lights" setting draws now.
class LuMediaGlow extends StatelessWidget {
  const LuMediaGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -1.2),
            radius: 1.1,
            colors: [Color(0x26F2B544), Color(0x000A0A0C)],
          ),
        ),
      ),
    );
  }
}

/// The cover-led banner at the top of Music and Audiobooks: the art blurred
/// behind, the square cover, a gold kicker, the title, one line of facts and a
/// row of actions.
class LuMediaHero extends StatelessWidget {
  const LuMediaHero({
    super.key,
    required this.kicker,
    required this.title,
    required this.actions,
    this.meta,
    this.imageUrl,
    this.filePath,
    this.progress,
    this.progressLabel,
    this.heroTag,
    this.httpHeaders,
    this.icon = Icons.music_note_rounded,
  });

  final String kicker;
  final String title;
  final String? meta;
  final String? imageUrl;
  final String? filePath;
  final double? progress;
  final String? progressLabel;
  final List<Widget> actions;
  final Object? heroTag;
  final Map<String, String>? httpHeaders;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 600;
    final pad = luMediaPad(context);
    final coverSize = phone ? 112.0 : (width < 1100 ? 180.0 : 220.0);

    Widget cover = LuMediaArt(
      url: imageUrl,
      filePath: filePath,
      cacheWidth: (coverSize * 2.5).round(),
      icon: icon,
      httpHeaders: httpHeaders,
    );
    if (heroTag != null) cover = Hero(tag: heroTag!, child: cover);
    cover = Container(
      width: coverSize,
      height: coverSize,
      decoration: const BoxDecoration(
        borderRadius: LuRadius.card,
        boxShadow: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: LuRadius.card, child: cover),
    );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          kicker,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LuText.label.copyWith(
            color: LuColors.gold,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: LuText.title.copyWith(fontSize: phone ? 24 : 38, height: 1.15),
        ),
        if (meta != null && meta!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            meta!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuText.label.copyWith(color: LuColors.textMuted),
          ),
        ],
        if (progress != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: LuRadius.pill,
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0),
                    minHeight: 4,
                    color: LuColors.gold,
                    backgroundColor: const Color(0x26FFFFFF),
                  ),
                ),
              ),
              if (progressLabel != null) ...[
                const SizedBox(width: 12),
                Text(progressLabel!, style: LuText.caption),
              ],
            ],
          ),
        ],
        if (!phone) ...[
          const SizedBox(height: 20),
          FocusTraversalGroup(
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
          ),
        ],
      ],
    );

    // A phone's text column is too narrow for a button and its icon
    // buttons, so they take one row of their own under the cover: the first
    // action stretches, the round ones keep their size beside it.
    final phoneActions = actions.isEmpty
        ? null
        : FocusTraversalGroup(
            child: Row(
              children: [
                Expanded(child: actions.first),
                for (final a in actions.skip(1)) ...[
                  const SizedBox(width: 10),
                  a,
                ],
              ],
            ),
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: ClipRRect(
        borderRadius: LuRadius.card,
        child: Stack(
          children: [
            Positioned.fill(
              child: LuMediaBackdrop(
                url: imageUrl,
                filePath: filePath,
                opacity: 0.55,
                httpHeaders: httpHeaders,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: LuRadius.card,
                  border: Border.all(color: LuColors.lineSoft),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(phone ? 18 : 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      cover,
                      SizedBox(width: phone ? 16 : 32),
                      Expanded(child: copy),
                    ],
                  ),
                  if (phone && phoneActions != null) ...[
                    const SizedBox(height: 16),
                    phoneActions,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
