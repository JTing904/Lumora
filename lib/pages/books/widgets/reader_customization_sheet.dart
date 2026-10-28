import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../services/books/reader_settings.dart';
import '../../../ui/lu_focusable.dart';
import '../../../ui/lu_theme.dart';
import 'lu_reading_kit.dart';
import 'reader_design_tokens.dart';

/// The reader's appearance: a live preview, then type, theme and layout. A
/// panel on the right of a wide screen, a bottom sheet on a phone. Every
/// change is written to [ReaderSettings] at once, so the page behind it
/// follows.
class ReaderCustomizationSheet extends StatefulWidget {
  final String? realBookSampleText;

  const ReaderCustomizationSheet({super.key, this.realBookSampleText});

  static Future<void> show(BuildContext context, {String? realBookSampleText}) {
    final isDesktop = MediaQuery.of(context).size.width > 760;

    if (isDesktop) {
      // Right side panel on desktop
      return showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: l10nOf(context).bkCloseSettings,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        transitionDuration: ReaderTokens.motionSheet,
        pageBuilder: (ctx, anim1, anim2) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: ReaderCustomizationSheet(
                realBookSampleText: realBookSampleText,
              ),
            ),
          );
        },
        transitionBuilder: (ctx, anim1, anim2, child) {
          final curved = CurvedAnimation(
            parent: anim1,
            curve: ReaderTokens.curveSheet,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      );
    }

    // Bottom sheet on mobile
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          ReaderCustomizationSheet(realBookSampleText: realBookSampleText),
    );
  }

  @override
  State<ReaderCustomizationSheet> createState() =>
      _ReaderCustomizationSheetState();
}

class _ReaderCustomizationSheetState extends State<ReaderCustomizationSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showResetSuccess = false;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTab);
  }

  void _onTab() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _tabController.removeListener(_onTab);
    _tabController.dispose();
    super.dispose();
  }

  void _triggerReset() {
    HapticFeedback.lightImpact();
    ReaderSettings.resetToDefaults();
    setState(() => _showResetSuccess = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showResetSuccess = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Theme(
      data: luTheme(),
      child: ValueListenableBuilder<ReaderSettingsData>(
        valueListenable: ReaderSettings.settingsNotifier,
        builder: (context, settings, _) {
          final size = MediaQuery.sizeOf(context);
          final isDesktop = size.width > 760;
          final tabs = [l10n.bk2Typography, l10n.bk2Theme, l10n.bk2Layout];

          return Container(
            width: isDesktop ? 400 : double.infinity,
            height: isDesktop ? double.infinity : null,
            constraints: isDesktop
                ? null
                : BoxConstraints(maxHeight: size.height * 0.88),
            decoration: BoxDecoration(
              color: LuColors.surface,
              borderRadius: isDesktop
                  ? const BorderRadius.horizontal(left: Radius.circular(24))
                  : const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: LuColors.lineSoft),
            ),
            child: SafeArea(
              left: false,
              top: isDesktop,
              child: Column(
                mainAxisSize: isDesktop ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (!isDesktop)
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: LuColors.line,
                        borderRadius: LuRadius.pill,
                      ),
                    ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          color: LuColors.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(l10n.bkAppearance, style: LuText.heading),
                        ),
                        LuGlyphButton(
                          icon: Icons.close_rounded,
                          label: l10n.bkCloseSettings,
                          size: 40,
                          iconSize: 18,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  _buildLivePreview(settings),

                  // The three pages, as pills.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 2),
                    child: Row(
                      children: [
                        for (var i = 0; i < tabs.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: LuChoicePill(
                              label: tabs[i],
                              expand: true,
                              selected: _tabController.index == i,
                              onTap: () => _tabController.animateTo(i),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  Flexible(
                    fit: isDesktop ? FlexFit.tight : FlexFit.loose,
                    child: SizedBox(
                      height: isDesktop ? null : 360,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                          activeTrackColor: LuColors.gold,
                          inactiveTrackColor: const Color(0x33FFFFFF),
                          thumbColor: LuColors.gold,
                          overlayColor: const Color(0x33F2B544),
                          showValueIndicator:
                              ShowValueIndicator.onlyForContinuous,
                          valueIndicatorColor: LuColors.gold,
                          valueIndicatorTextStyle: LuText.caption.copyWith(
                            color: LuColors.onGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTypographyTab(settings),
                            _buildThemeTab(settings),
                            _buildLayoutTab(settings),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Reset
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LuFocusable(
                        onTap: _triggerReset,
                        lift: 1,
                        borderRadius: LuRadius.pill,
                        builder: (context, hi) => AnimatedContainer(
                          duration: LuMotion.focus,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: LuRadius.pill,
                            color: hi
                                ? const Color(0x1AFFFFFF)
                                : Colors.transparent,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showResetSuccess
                                    ? Icons.check_rounded
                                    : Icons.restart_alt_rounded,
                                size: 18,
                                color: _showResetSuccess
                                    ? LuColors.success
                                    : LuColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _showResetSuccess
                                    ? l10n.bkReset
                                    : l10n.bkResetToDefaults,
                                style: LuText.label.copyWith(
                                  color: _showResetSuccess
                                      ? LuColors.success
                                      : LuColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildLivePreview(ReaderSettingsData settings) {
    final previewText = widget.realBookSampleText?.isNotEmpty == true
        ? widget.realBookSampleText!
        : l10nOf(context).booksPreviewSample;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: settings.borderColor),
      ),
      child: Text(
        previewText,
        textAlign: settings.textAlign,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: settings.fontFamily,
          fontSize: settings.fontSize.clamp(14.0, 20.0),
          height: settings.lineSpacing,
          letterSpacing: settings.letterSpacing,
          color: settings.textColor,
        ),
      ),
    );
  }

  /// A setting's name and its value, over its slider.
  Widget _valueHeader(String title, String value) => Row(
    children: [
      Expanded(child: LuSectionLabel(title)),
      Text(
        value,
        style: LuText.label.copyWith(
          color: LuColors.text,
          fontWeight: FontWeight.w700,
          fontFamily: LuFonts.display,
        ),
      ),
    ],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 1. TYPOGRAPHY TAB
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTypographyTab(ReaderSettingsData settings) {
    final l10n = l10nOf(context);
    final fonts = <(String, String)>[
      ('Georgia', 'Georgia'),
      ('Merriweather', 'Merriweather'),
      ('Inter', 'Inter'),
      ('Poppins', 'Poppins'),
      ('OpenDyslexic', 'OpenDyslexic'),
      (l10n.bkMono, 'Courier New'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      children: [
        LuSectionLabel(l10n.bkFontFamily),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (name, key) in fonts)
              LuChoicePill(
                label: name,
                fontFamily: key,
                selected: settings.fontFamily == key,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ReaderSettings.updateFontFamily(key);
                },
              ),
          ],
        ),
        const SizedBox(height: 24),

        _valueHeader(
          l10n.bkFontSize,
          l10n.booksFontSizePx('${settings.fontSize.round()}'),
        ),
        Row(
          children: [
            Text(
              'A',
              style: LuText.label.copyWith(
                fontWeight: FontWeight.w700,
                color: LuColors.textMuted,
              ),
            ),
            Expanded(
              child: Slider(
                value: settings.fontSize,
                min: 14,
                max: 34,
                divisions: 10,
                label: l10n.booksFontSizePx('${settings.fontSize.round()}'),
                onChanged: (val) => ReaderSettings.updateFontSize(val),
              ),
            ),
            Text(
              'A',
              style: LuText.heading.copyWith(color: LuColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _valueHeader(
          l10n.bkLineHeight,
          '${settings.lineSpacing.toStringAsFixed(2)}×',
        ),
        Slider(
          value: settings.lineSpacing,
          min: 1.2,
          max: 2.2,
          divisions: 10,
          label: '${settings.lineSpacing.toStringAsFixed(2)}×',
          onChanged: (val) => ReaderSettings.updateLineSpacing(val),
        ),
        const SizedBox(height: 12),

        LuSectionLabel(l10n.bkAlignment),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildAlignButton(
              Icons.format_align_left_rounded,
              TextAlign.left,
              settings,
            ),
            const SizedBox(width: 10),
            _buildAlignButton(
              Icons.format_align_justify_rounded,
              TextAlign.justify,
              settings,
            ),
          ],
        ),
        const SizedBox(height: 12),
        LuSwitchRow(
          label: l10n.bkFirstLineIndent,
          value: settings.firstLineIndent,
          onChanged: (val) {
            HapticFeedback.selectionClick();
            ReaderSettings.updateFirstLineIndent(val);
          },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. THEME & BRIGHTNESS TAB
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildThemeTab(ReaderSettingsData settings) {
    final l10n = l10nOf(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      children: [
        LuSectionLabel(l10n.bkReadingThemes),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildThemeSwatchCard(
              label: l10n.bkLight,
              theme: ReaderTheme.light,
              current: settings.theme,
              bg: const Color(0xFFFAFAFA),
              textColor: const Color(0xFF1F2328),
              border: const Color(0xFFD0D7DE),
            ),
            const SizedBox(width: 8),
            _buildThemeSwatchCard(
              label: l10n.bkSepia,
              theme: ReaderTheme.sepia,
              current: settings.theme,
              bg: const Color(0xFFF4ECD8),
              textColor: const Color(0xFF382717),
              border: const Color(0xFFD4C8B0),
            ),
            const SizedBox(width: 8),
            _buildThemeSwatchCard(
              label: l10n.bkDark,
              theme: ReaderTheme.dark,
              current: settings.theme,
              bg: const Color(0xFF141419),
              textColor: const Color(0xFFE6E8ED),
              border: const Color(0xFF2A2E3D),
            ),
            const SizedBox(width: 8),
            _buildThemeSwatchCard(
              label: l10n.bkAmoled,
              theme: ReaderTheme.amoled,
              current: settings.theme,
              bg: Colors.black,
              textColor: const Color(0xFFE5E5E5),
              border: const Color(0xFF262626),
            ),
          ],
        ),
        const SizedBox(height: 28),

        _valueHeader(
          l10n.bkReaderBrightness,
          '${(settings.brightness * 100).round()}%',
        ),
        Row(
          children: [
            const Icon(
              Icons.brightness_low_rounded,
              color: LuColors.textMuted,
              size: 18,
            ),
            Expanded(
              child: Slider(
                value: settings.brightness,
                min: 0.2,
                max: 1.0,
                divisions: 8,
                label: '${(settings.brightness * 100).round()}%',
                onChanged: (val) => ReaderSettings.updateBrightness(val),
              ),
            ),
            const Icon(
              Icons.brightness_high_rounded,
              color: LuColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. LAYOUT TAB
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildLayoutTab(ReaderSettingsData settings) {
    final l10n = l10nOf(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      children: [
        LuSectionLabel(l10n.bkPageMargins),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildMarginChip(l10n.bkCompact, MarginPreset.compact, settings),
            const SizedBox(width: 8),
            _buildMarginChip(l10n.bkBalanced, MarginPreset.balanced, settings),
            const SizedBox(width: 8),
            _buildMarginChip(l10n.bkWide, MarginPreset.wide, settings),
          ],
        ),
        // No reading-mode choice: the EPUB reader only scrolls. A paginated
        // option used to sit here, but nothing read it, so picking it did
        // nothing. A stored paginated value loads as scroll.
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildThemeSwatchCard({
    required String label,
    required ReaderTheme theme,
    required ReaderTheme current,
    required Color bg,
    required Color textColor,
    required Color border,
  }) {
    final isSelected = theme == current;
    return Expanded(
      child: LuFocusable(
        onTap: () {
          HapticFeedback.lightImpact();
          ReaderSettings.updateTheme(theme);
        },
        semanticLabel: label,
        borderRadius: LuRadius.field,
        builder: (context, _) => AnimatedContainer(
          duration: LuMotion.focus,
          height: 68,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: LuRadius.field,
            border: Border.all(
              color: isSelected ? LuColors.gold : border,
              width: isSelected ? 2.4 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  fontFamily: LuFonts.display,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.caption.copyWith(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlignButton(
    IconData icon,
    TextAlign align,
    ReaderSettingsData settings,
  ) {
    final l10n = l10nOf(context);
    return LuGlyphButton(
      icon: icon,
      label: align == TextAlign.justify
          ? l10n.booksAlignJustify
          : l10n.booksAlignLeft,
      active: settings.textAlign == align,
      onTap: () {
        HapticFeedback.selectionClick();
        ReaderSettings.updateTextAlign(align);
      },
    );
  }

  Widget _buildMarginChip(
    String label,
    MarginPreset preset,
    ReaderSettingsData settings,
  ) {
    return Expanded(
      child: LuChoicePill(
        label: label,
        expand: true,
        selected: settings.marginPreset == preset,
        onTap: () {
          HapticFeedback.selectionClick();
          ReaderSettings.updateMarginPreset(preset);
        },
      ),
    );
  }
}
