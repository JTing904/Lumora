import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../services/layout/form_factor.dart';
import '../../../ui/lu_cards.dart';
import '../../../ui/lu_confirm.dart';
import '../../../ui/lu_focusable.dart';
import '../../../ui/lu_theme.dart';

/// The pieces the manga and book pages share on top of the Lumora kit: glyph
/// discs, pill choices, a switch row, a search box, the panel and sheet frames
/// and a portrait "continue" card. Every control here is a [LuFocusable], so a
/// remote reaches it and sees the gold ring.

/// Under a light glyph drawn straight on artwork, so it stays legible on a
/// white page.
const Shadow luGlyphShadow = Shadow(
  color: Color(0x99000000),
  blurRadius: 6,
  offset: Offset(0, 1),
);

/// A round glyph action: a glass disc (or a bare glyph over art), gold while
/// [active]. A null [onTap] dims it and takes it out of focus traversal.
class LuGlyphButton extends StatelessWidget {
  const LuGlyphButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.filled = true,
    this.active = false,
    this.danger = false,
    this.focusNode,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  /// A glass disc; false for a bare glyph with a drop shadow.
  final bool filled;

  /// An "on" state: the deck shown, focus mode running.
  final bool active;
  final bool danger;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = danger
        ? LuColors.danger
        : (active ? LuColors.gold : LuColors.text);
    return Tooltip(
      message: label,
      child: LuFocusable(
        onTap: onTap,
        focusNode: focusNode,
        autofocus: autofocus,
        semanticLabel: label,
        builder: (context, hi) => AnimatedOpacity(
          opacity: enabled ? 1 : 0.38,
          duration: LuMotion.focus,
          child: AnimatedContainer(
            duration: LuMotion.focus,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? (active
                        ? const Color(0x29F2B544)
                        : (hi
                              ? const Color(0x33FFFFFF)
                              : const Color(0x1FFFFFFF)))
                  : (hi ? const Color(0x1FFFFFFF) : Colors.transparent),
              border: filled
                  ? Border.all(
                      color: active ? LuColors.gold : const Color(0x38FFFFFF),
                    )
                  : null,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: fg,
              shadows: filled ? null : const [luGlyphShadow],
            ),
          ),
        ),
      ),
    );
  }
}

/// The height of a pill on this device: a television's targets are bigger.
double luPillHeight(BuildContext context) =>
    FormFactorService.of(context) == FormFactor.television ? 44 : 38;

/// A pill choice: a genre, a format, a font, a reading mode. Selected is a gold
/// tint with gold words; at rest it is an outline.
class LuChoicePill extends StatelessWidget {
  const LuChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.swatch,
    this.trailingIcon,
    this.fontFamily,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// A colour dot, for a choice that stands for a colour.
  final Color? swatch;

  /// A disclosure arrow, for a pill that opens a menu.
  final IconData? trailingIcon;

  /// Draws the label in the face it names (a font choice).
  final String? fontFamily;

  /// Fills its width (a row of equal choices).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? LuColors.gold : LuColors.textSoft;
    return LuFocusable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, hi) => AnimatedContainer(
        duration: LuMotion.focus,
        height: luPillHeight(context),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: LuRadius.pill,
          color: selected
              ? const Color(0x29F2B544)
              : (hi ? const Color(0x1AFFFFFF) : Colors.transparent),
          border: Border.all(
            color: selected ? const Color(0x80F2B544) : LuColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (swatch != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x59FFFFFF)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.body.copyWith(
                  fontSize: 14,
                  height: 1.2,
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: fontFamily,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, size: 18, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

/// A sideways row of [LuChoicePill]s that scrolls, so a long list (genres,
/// formats) stays one line on a phone and the focused pill scrolls into view.
class LuPillRow extends StatelessWidget {
  const LuPillRow({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Room for the focus lift and glow.
      height: luPillHeight(context) + 12,
      child: FocusTraversalGroup(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: padding.copyWith(top: 6, bottom: 6),
          itemCount: children.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => children[i],
        ),
      ),
    );
  }
}

/// A small muted heading over a group of controls.
class LuSectionLabel extends StatelessWidget {
  const LuSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: LuText.label.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: LuColors.textMuted,
      letterSpacing: 0.4,
    ),
  );
}

/// A setting that is on or off: the whole row is the control, so a remote
/// lands on it and Select flips it.
class LuSwitchRow extends StatelessWidget {
  const LuSwitchRow({
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
    return LuFocusable(
      onTap: () => onChanged(!value),
      lift: 1.01,
      borderRadius: LuRadius.field,
      semanticLabel: label,
      builder: (context, hi) => AnimatedContainer(
        duration: LuMotion.focus,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: LuRadius.field,
          color: hi ? const Color(0x14FFFFFF) : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: LuText.body.copyWith(fontSize: 15)),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: LuMotion.focus,
              width: 46,
              height: 28,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                borderRadius: LuRadius.pill,
                color: value ? LuColors.gold : LuColors.surfaceHigh,
                border: Border.all(
                  color: value ? LuColors.gold : LuColors.line,
                ),
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? LuColors.onGold : LuColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A search field: the Lumora field with a gold glass, and a clear button once
/// there is something to clear.
class LuSearchBox extends StatefulWidget {
  const LuSearchBox({
    super.key,
    required this.controller,
    required this.hint,
    required this.clearLabel,
    this.onSubmitted,
    this.onChanged,
    this.onClear,
    this.height = 50,
  });

  final TextEditingController controller;
  final String hint;
  final String clearLabel;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final double height;

  @override
  State<LuSearchBox> createState() => _LuSearchBoxState();
}

class _LuSearchBoxState extends State<LuSearchBox> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant LuSearchBox old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  void _onFocus() => setState(() => _focused = _focus.hasFocus);
  void _onText() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    return AnimatedContainer(
      duration: LuMotion.focus,
      height: widget.height,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: LuColors.field,
        borderRadius: LuRadius.pill,
        border: Border.all(
          color: _focused ? LuColors.gold : LuColors.line,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: [
          if (_focused)
            const BoxShadow(
              color: Color(0x40F2B544),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: LuColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              onSubmitted: widget.onSubmitted,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: LuText.body,
              cursorColor: LuColors.gold,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: LuText.body.copyWith(color: LuColors.textFaint),
              ),
            ),
          ),
          if (hasText)
            LuGlyphButton(
              icon: Icons.close_rounded,
              label: widget.clearLabel,
              size: 36,
              iconSize: 18,
              filled: false,
              onTap: () {
                widget.controller.clear();
                widget.onClear?.call();
              },
            ),
        ],
      ),
    );
  }
}

/// A centred panel - a settings dialog - with its title, a gold glyph and a
/// close disc. [builder] draws the body; it is scrolled when it runs long.
Future<T?> showLuPanel<T>(
  BuildContext context, {
  required String title,
  IconData? icon,
  required WidgetBuilder builder,
  double maxWidth = 500,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => Theme(
      data: luTheme(),
      child: Dialog(
        backgroundColor: LuColors.surface,
        insetPadding: const EdgeInsets.all(16),
        shape: const RoundedRectangleBorder(
          borderRadius: LuRadius.card,
          side: BorderSide(color: LuColors.lineSoft),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: LuColors.gold, size: 22),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LuText.heading,
                      ),
                    ),
                    LuGlyphButton(
                      icon: Icons.close_rounded,
                      label: l10nOf(ctx).actionClose,
                      size: 40,
                      iconSize: 18,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: Builder(builder: builder),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The frame of a bottom sheet: the surface, its 24 rounded top and a handle.
class LuSheetFrame extends StatelessWidget {
  const LuSheetFrame({super.key, required this.child, this.maxHeightFactor});

  final Widget child;

  /// Caps the sheet at this share of the screen.
  final double? maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final f = maxHeightFactor;
    return Theme(
      data: luTheme(),
      child: Container(
        constraints: f == null
            ? null
            : BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * f),
        decoration: const BoxDecoration(
          color: LuColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: LuColors.lineSoft)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 6),
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: LuColors.line,
                  borderRadius: LuRadius.pill,
                ),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// A portrait cover with the reader's place along its foot, its title and a
/// caption: 继续阅读 for manga and books. A long press, a right click, the
/// menu key or a held Select asks to remove it, so a remote can too.
class LuCoverContinueCard extends StatelessWidget {
  const LuCoverContinueCard({
    super.key,
    required this.title,
    required this.cover,
    required this.progress,
    required this.caption,
    required this.onTap,
    this.badge,
    this.onRemove,
    this.removeLabel,
    this.width = 140,
  });

  final String title;
  final String? cover;

  /// 0..1.
  final double progress;
  final String caption;
  final String? badge;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final String? removeLabel;
  final double width;

  static double heightFor(
    double width, [
    TextScaler scaler = TextScaler.noScaling,
  ]) => width * 1.5 + 8 + scaler.scale(46);

  Future<void> _askRemove(BuildContext context) async {
    final remove = onRemove;
    if (remove == null) return;
    final l10n = l10nOf(context);
    final ok = await showLuConfirm(
      context,
      title: removeLabel ?? l10n.listRemove,
      message: title,
      confirmLabel: l10n.listRemove,
    );
    if (ok) remove();
  }

  @override
  Widget build(BuildContext context) {
    final pointerRemove = onRemove != null && !FormFactorService.hasRemoteInput;
    return SizedBox(
      width: width,
      child: LuFocusable(
        onTap: onTap,
        onLongPress: onRemove == null ? null : () => _askRemove(context),
        borderRadius: LuRadius.poster,
        semanticLabel: title,
        builder: (context, hi) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: LuRadius.poster,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LuImage(
                      url: cover,
                      cacheWidth: (width * 2.5).round(),
                      fallback: const Icon(
                        Icons.menu_book_rounded,
                        color: LuColors.textFaint,
                        size: 32,
                      ),
                    ),
                    if (badge != null)
                      Positioned(left: 8, top: 8, child: LuBadge(badge!)),
                    AnimatedOpacity(
                      opacity: hi ? 1 : 0,
                      duration: LuMotion.focus,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: Color(0x33000000)),
                        child: Center(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 40,
                            color: LuColors.gold,
                          ),
                        ),
                      ),
                    ),
                    if (pointerRemove && hi)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: ExcludeFocus(
                          child: IconButton(
                            tooltip: removeLabel,
                            onPressed: onRemove,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xB30A0A0C),
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: LuColors.text,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 4,
                        color: const Color(0x40FFFFFF),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.02, 1.0),
                          child: const ColoredBox(color: LuColors.gold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuText.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuText.caption,
            ),
          ],
        ),
      ),
    );
  }
}

/// A grid of poster cards that fills the width it is given: as many columns
/// of about [targetWidth] as fit, each card as wide as its column and as tall
/// as [LuPosterCard.heightFor] says.
class LuPosterGrid extends StatelessWidget {
  const LuPosterGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.padding,
    this.targetWidth = 160,
    this.spacing = 18,
    this.runSpacing = 24,
    this.heightFor = LuPosterCard.heightFor,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index, double width)
  itemBuilder;
  final double padding;
  final double targetWidth;
  final double spacing;
  final double runSpacing;
  final double Function(double width, [TextScaler scaler]) heightFor;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final avail = constraints.crossAxisExtent - padding * 2;
        // A phone is three posters across, closer together: two left each
        // cover a third of the screen tall, as if the shelf were zoomed in.
        final phone = constraints.crossAxisExtent < 600;
        final gap = phone ? 12.0 : spacing;
        final columns = phone
            ? 3
            : ((avail + gap) / (targetWidth + gap)).floor().clamp(2, 12);
        final w = (avail - gap * (columns - 1)) / columns;
        // The focus lift grows a card by 5%; the extra keeps it off the row
        // below.
        final h = heightFor(w, MediaQuery.textScalerOf(context)) + 6;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: gap,
              mainAxisSpacing: phone ? 18 : runSpacing,
              mainAxisExtent: h,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => Align(
                alignment: Alignment.topLeft,
                child: itemBuilder(context, i, w),
              ),
              childCount: itemCount,
            ),
          ),
        );
      },
    );
  }
}

/// A loading grid of blank posters in the grid's own geometry, so nothing
/// moves when the titles land.
class LuPosterGridSkeleton extends StatelessWidget {
  const LuPosterGridSkeleton({
    super.key,
    required this.padding,
    this.targetWidth = 160,
    this.count = 12,
  });

  final double padding;
  final double targetWidth;
  final int count;

  @override
  Widget build(BuildContext context) {
    return LuPosterGrid(
      itemCount: count,
      padding: padding,
      targetWidth: targetWidth,
      itemBuilder: (context, i, w) => SizedBox(
        width: w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AspectRatio(
              aspectRatio: 2 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: LuColors.surface,
                  borderRadius: LuRadius.poster,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 12,
              width: w * 0.8,
              decoration: const BoxDecoration(
                color: LuColors.surface,
                borderRadius: LuRadius.pill,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: w * 0.5,
              decoration: const BoxDecoration(
                color: LuColors.surface,
                borderRadius: LuRadius.pill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A gentle message in the middle of a page: nothing found, something failed.
class LuEmptyState extends StatelessWidget {
  const LuEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: LuColors.textFaint),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: LuText.heading),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: LuText.bodySoft,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    );
  }
}

/// The side margin of a Lumora page on this device.
double luPagePad(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return 16;
  if (FormFactorService.of(context) == FormFactor.television) return 48;
  return w < 1000 ? 32 : LuSpace.page;
}

/// A synopsis: [lines] lines, with 展开 / 收起 when it runs longer.
class LuExpandableText extends StatefulWidget {
  const LuExpandableText(this.text, {super.key, this.lines = 4});

  final String text;
  final int lines;

  @override
  State<LuExpandableText> createState() => _LuExpandableTextState();
}

class _LuExpandableTextState extends State<LuExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final style = LuText.body.copyWith(
      fontSize: 15,
      height: 1.75,
      color: LuColors.textSoft,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.lines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: box.maxWidth);
        final long = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : widget.lines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (long)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LuFocusable(
                  onTap: () => setState(() => _expanded = !_expanded),
                  lift: 1,
                  builder: (context, hi) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Text(
                      _expanded ? l10n.detailsShowLess : l10n.detailsReadMore,
                      style: LuText.body.copyWith(
                        fontSize: 14,
                        color: hi ? LuColors.goldLight : LuColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A cover picture blown up behind a page's header, darkened towards the
/// ground so the words over it read.
class LuCoverBackdrop extends StatelessWidget {
  const LuCoverBackdrop({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: 0.45, child: LuImage(url: url, cacheWidth: 900)),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x990A0A0C), Color(0xCC0A0A0C), LuColors.bg],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
      ],
    );
  }
}
