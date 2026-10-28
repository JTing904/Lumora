import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../services/layout/form_factor.dart';
import '../../../services/manga/manga_settings.dart';
import '../../../ui/lu_focusable.dart';
import '../../../ui/lu_theme.dart';
import 'manga_labels.dart';

/// The reader's atmosphere and page mode, on the shelf rather than three taps
/// deep in a settings sheet.
///
/// Both controls write real settings the reader honours -
/// [MangaSettings.readerBackground] (the page colour the reader paints) and
/// [MangaSettings.defaultReadingMode] (the mode a chapter opens in).
///
/// The atmosphere is one disclosure pill beside the page-mode pill on every
/// screen: on a phone a row of four atmosphere pills took two lines of the
/// shelf, and on a 540 dp television the banner must stay one 48 dp row.
class MangaReaderControlBar extends StatelessWidget {
  const MangaReaderControlBar({super.key, this.horizontalPadding});

  /// The page's side margin; the bar's own default otherwise.
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final isCompact = FormFactorService.of(context) == FormFactor.compact;
    final pad = horizontalPadding ?? (isCompact ? 16.0 : 24.0);

    return Padding(
      // 6 rather than 8: the focus ring's 2 dp edge sits around each pill,
      // and a television's banner must stay one 64 dp row.
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 6),
      child: const Row(
        children: [
          Flexible(child: MangaAtmosphereChip()),
          SizedBox(width: 12),
          Flexible(child: MangaPageModeChip()),
        ],
      ),
    );
  }
}

/// The atmosphere group on its own, for the reader's own customiser.
class MangaAtmosphereChips extends StatelessWidget {
  const MangaAtmosphereChips({super.key, this.showLabel = true});

  /// The shelf banner names the group; a dialog that already has a heading for
  /// it does not need the name twice.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return ValueListenableBuilder<MangaReaderBackground>(
      valueListenable: MangaSettings.readerBackground,
      builder: (context, current, _) => Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                l10n.mgReaderAtmosphere,
                style: LuText.label.copyWith(color: LuColors.textMuted),
              ),
            ),
          for (final background in MangaReaderBackground.values)
            ReaderChoiceChip(
              label: mangaBackgroundLabel(l10n, background),
              swatch: background.color,
              selected: background == current,
              onTap: () => MangaSettings.setReaderBackground(background),
            ),
        ],
      ),
    );
  }
}

/// One pill in a reader control row. Shared by the atmosphere group and the
/// page-mode selector so both read as the same control: gold tint and gold
/// words when chosen, an outline at rest, the gold ring on focus.
class ReaderChoiceChip extends StatelessWidget {
  const ReaderChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.swatch,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// A colour dot for a chip that stands for a colour, e.g. a page atmosphere.
  final Color? swatch;

  /// A disclosure arrow for a chip that opens a menu rather than toggling.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? LuColors.gold : LuColors.textSoft;
    return LuFocusable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, hi) => AnimatedContainer(
        duration: LuMotion.focus,
        height: FocusMetrics.controlHeight(context),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: LuRadius.pill,
          color: selected
              ? const Color(0x29F2B544)
              : (hi ? const Color(0x1AFFFFFF) : const Color(0x0DFFFFFF)),
          border: Border.all(
            color: selected ? const Color(0x80F2B544) : LuColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (swatch != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x66FFFFFF)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Flexible + ellipsis: "Page Mode: Webtoon Scroll" at 1.3x text
            // on a 328 dp phone row would otherwise overflow the pill.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                // Weight is fixed across states, so choosing never reflows.
                style: LuText.body.copyWith(
                  fontSize: 14,
                  height: 1.2,
                  color: fg,
                  fontWeight: FontWeight.w600,
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

/// Opens [values] as a focusable menu anchored under the chip at [context].
///
/// `PopupMenuItem` rows are focusable and traversable, so a remote moves
/// through the choices and Select picks one.
Future<T?> _openChoiceMenu<T>(
  BuildContext context, {
  required List<T> values,
  required T current,
  required String Function(T value) label,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  final overlayBox =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (box == null || overlayBox == null) return null;

  final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
  final bottomRight = box.localToGlobal(
    box.size.bottomRight(Offset.zero),
    ancestor: overlayBox,
  );

  return showMenu<T>(
    context: context,
    color: LuColors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      side: BorderSide(color: LuColors.line),
    ),
    position: RelativeRect.fromLTRB(
      topLeft.dx,
      bottomRight.dy + 6,
      overlayBox.size.width - bottomRight.dx,
      0,
    ),
    items: [
      for (final value in values)
        PopupMenuItem<T>(
          value: value,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: value == current
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: LuColors.gold,
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                label(value),
                style: LuText.body.copyWith(
                  fontSize: 15,
                  color: value == current ? LuColors.gold : LuColors.text,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// The page-mode pill (`Page mode: Webtoon Scroll ▾`) over the three modes
/// the reader implements. Activating it opens the menu, so the control is one
/// focus target.
class MangaPageModeChip extends StatelessWidget {
  const MangaPageModeChip({super.key});

  Future<void> _openMenu(BuildContext context, MangaReadingMode current) async {
    final l10n = l10nOf(context);
    final picked = await _openChoiceMenu<MangaReadingMode>(
      context,
      values: MangaReadingMode.values,
      current: current,
      label: (mode) => mangaReadingModeLabel(l10n, mode),
    );

    if (picked != null) await MangaSettings.setDefaultReadingMode(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return ValueListenableBuilder<MangaReadingMode>(
      valueListenable: MangaSettings.defaultReadingMode,
      builder: (context, mode, _) => Builder(
        builder: (chipContext) => ReaderChoiceChip(
          label: l10n.mg2PageModeLabel(mangaReadingModeShort(l10n, mode)),
          selected: false,
          trailingIcon: Icons.expand_more_rounded,
          onTap: () => _openMenu(chipContext, mode),
        ),
      ),
    );
  }
}

/// The atmosphere group as one disclosure pill, for the shelf banner away
/// from a phone: it keeps the control, its swatch and its effect on the
/// reader in one 48 dp target.
class MangaAtmosphereChip extends StatelessWidget {
  const MangaAtmosphereChip({super.key});

  Future<void> _openMenu(
    BuildContext context,
    MangaReaderBackground current,
  ) async {
    final l10n = l10nOf(context);
    final picked = await _openChoiceMenu<MangaReaderBackground>(
      context,
      values: MangaReaderBackground.values,
      current: current,
      label: (background) => mangaBackgroundLabel(l10n, background),
    );

    if (picked != null) await MangaSettings.setReaderBackground(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return ValueListenableBuilder<MangaReaderBackground>(
      valueListenable: MangaSettings.readerBackground,
      builder: (context, current, _) => Builder(
        builder: (chipContext) => ReaderChoiceChip(
          label: l10n.mg2AtmosphereLabel(mangaBackgroundLabel(l10n, current)),
          swatch: current.color,
          selected: false,
          trailingIcon: Icons.expand_more_rounded,
          onTap: () => _openMenu(chipContext, current),
        ),
      ),
    );
  }
}

/// The minimum size an actionable control may present, per form factor.
///
/// A television is pointed at from across a room with a five-way pad, so every
/// target on it is at least the 48 dp comfortable minimum; a phone is held.
abstract final class FocusMetrics {
  static double controlHeight(BuildContext context) =>
      FormFactorService.of(context) == FormFactor.compact
      ? 40.0
      : kMinInteractiveDimension;
}
