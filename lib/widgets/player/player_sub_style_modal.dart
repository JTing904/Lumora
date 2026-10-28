import '../../l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../services/player/player_settings.dart';
import '../../services/theme/design_tokens.dart';
import 'player_glass.dart';
import 'lu_player_style.dart';
import '../../ui/lu_theme.dart';

/// Responsive, rich Subtitle Customization Modal with live preview,
/// presets, typography, colors, background boxes, outlines, shadows, and libass options.
class PlayerSubStyleModal extends StatefulWidget {
  final Player? player;
  final VoidCallback onClose;

  const PlayerSubStyleModal({
    super.key,
    this.player,
    required this.onClose,
  });

  @override
  State<PlayerSubStyleModal> createState() => _PlayerSubStyleModalState();
}

class _PlayerSubStyleModalState extends State<PlayerSubStyleModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // User's subtitle colours (player content), not app-palette chrome — each 'hex' is written into the subtitle style, so the swatches keep rendering those exact colours.
  static const List<Map<String, dynamic>> _textColorPalette = [
    {'name': 'White', 'hex': '#FFFFFFFF', 'color': Color(0xFFFFFFFF)},
    {'name': 'Cinema Yellow', 'hex': '#FFFFEB3B', 'color': Color(0xFFFFEB3B)},
    {'name': 'Amber Gold', 'hex': '#FFFFC107', 'color': Color(0xFFFFC107)},
    {'name': 'Electric Cyan', 'hex': '#00E5FF', 'color': Color(0xFF00E5FF)},
    {'name': 'Neon Green', 'hex': '#00E676', 'color': Color(0xFF00E676)},
    {'name': 'Vibrant Orange', 'hex': '#FF9100', 'color': Color(0xFFFF9100)},
    {'name': 'Soft Rose', 'hex': '#FF80AB', 'color': Color(0xFFFF80AB)},
    {'name': 'Light Gray', 'hex': '#D1D5DB', 'color': Color(0xFFD1D5DB)},
  ];

  static const List<Map<String, dynamic>> _boxColorOptions = [
    {'name': 'None', 'hex': '#00000000', 'desc': 'Transparent'},
    {'name': '25% Dark', 'hex': '#40000000', 'desc': 'Subtle'},
    {'name': '50% Dark', 'hex': '#80000000', 'desc': 'Standard Box'},
    {'name': '75% Dark', 'hex': '#BF000000', 'desc': 'High Contrast'},
    {'name': '100% Solid', 'hex': '#FF000000', 'desc': 'Opaque Black'},
    {'name': '50% Indigo', 'hex': '#800F172A', 'desc': 'Slate Tint'},
  ];

  static const List<Map<String, dynamic>> _borderColorPalette = [
    {'name': 'Black', 'hex': '#FF000000', 'color': Color(0xFF000000)},
    {'name': 'Dark Slate', 'hex': '#FF1E293B', 'color': Color(0xFF1E293B)},
    {'name': 'White', 'hex': '#FFFFFFFF', 'color': Color(0xFFFFFFFF)},
    {'name': 'Gold', 'hex': '#FFFFD700', 'color': Color(0xFFFFD700)},
    {'name': 'Crimson', 'hex': '#FFE11D48', 'color': Color(0xFFE11D48)},
    {'name': 'Neon Cyan', 'hex': '#FF00E5FF', 'color': Color(0xFF00E5FF)},
  ];

  /// Display name for a palette or box entry. The English 'name' / 'desc'
  /// stay the lookup keys; what the viewer reads comes from l10n.
  static String _localizedName(String name) {
    final l10n = l10nCurrent();
    return switch (name) {
      'White' => l10n.wgPlySubColorWhite,
      'Cinema Yellow' => l10n.wgPlySubColorCinemaYellow,
      'Amber Gold' => l10n.wgPlySubColorAmberGold,
      'Electric Cyan' => l10n.wgPlySubColorElectricCyan,
      'Neon Green' => l10n.wgPlySubColorNeonGreen,
      'Vibrant Orange' => l10n.wgPlySubColorVibrantOrange,
      'Soft Rose' => l10n.wgPlySubColorSoftRose,
      'Light Gray' => l10n.wgPlySubColorLightGray,
      'Black' => l10n.wgPlySubColorBlack,
      'Dark Slate' => l10n.wgPlySubColorDarkSlate,
      'Gold' => l10n.wgPlySubColorGold,
      'Crimson' => l10n.wgPlySubColorCrimson,
      'Neon Cyan' => l10n.wgPlySubColorNeonCyan,
      'None' => l10n.wgPlySubBoxNone,
      '25% Dark' => l10n.wgPlySubBoxDark('25'),
      '50% Dark' => l10n.wgPlySubBoxDark('50'),
      '75% Dark' => l10n.wgPlySubBoxDark('75'),
      '100% Solid' => l10n.wgPlySubBoxSolid,
      '50% Indigo' => l10n.wgPlySubBoxIndigo,
      'Transparent' => l10n.wgPlySubBoxDescTransparent,
      'Subtle' => l10n.wgPlySubBoxDescSubtle,
      'Standard Box' => l10n.wgPlySubBoxDescStandard,
      'High Contrast' => l10n.wgPlySubBoxDescHighContrast,
      'Opaque Black' => l10n.wgPlySubBoxDescOpaque,
      'Slate Tint' => l10n.wgPlySubBoxDescSlate,
      _ => name,
    };
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _parseColorFromHex(String hex, {Color fallback = Colors.white}) {
    var str = hex.replaceAll('#', '').trim();
    if (str.length == 6) {
      str = 'FF$str';
    }
    if (str.length == 8) {
      final val = int.tryParse(str, radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 600;
    final isLandscapeMobile = screen.height < 500;

    final double cardWidth;
    if (isCompact) {
      cardWidth = (screen.width - 24).clamp(320.0, 560.0);
    } else if (isLandscapeMobile) {
      cardWidth = (screen.width - 32).clamp(440.0, 680.0);
    } else {
      cardWidth = (640.0).clamp(460.0, screen.width - 48);
    }

    final double cardHeight;
    if (isLandscapeMobile) {
      cardHeight = (screen.height - 32).clamp(240.0, screen.height - 20);
    } else if (isCompact) {
      cardHeight = (screen.height * 0.85).clamp(420.0, 660.0);
    } else {
      cardHeight = (screen.height * 0.76).clamp(520.0, 720.0);
    }

    return ValueListenableBuilder<int>(
      valueListenable: PlayerSettings.changeNotifier,
      builder: (context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: PlayerGlassCard(
              width: cardWidth,
              height: cardHeight,
              borderRadius: ZplayRadius.lg,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // 1. Header Bar
                  _buildHeader(context, isCompact || isLandscapeMobile),

                  // 2. Interactive Live Preview
                  _buildLivePreview(isLandscapeMobile),

                  // 3. Quick Presets Carousel
                  _buildPresetsBar(),

                  // 4. Tab Bar Navigation
                  _buildTabBar(),

                  // 5. Scrollable Tab View Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTypographyTab(),
                        _buildColorsAndBoxTab(),
                        _buildOutlinesAndShadowsTab(),
                        _buildPositionAndLayoutTab(),
                        _buildAdvancedTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isSmall) {
    const tokens = luTokens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ZplaySpacing.s16,
        vertical: isSmall ? ZplaySpacing.s8 : ZplaySpacing.s12,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: PlayerTheme.edgeSoft)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: isSmall ? 28 : 34,
                height: isSmall ? 28 : 34,
                decoration: BoxDecoration(
                  color: PlayerTheme.accentSoft,
                  borderRadius: LuRadius.field,
                ),
                child: Icon(
                  Icons.subtitles_rounded,
                  color: PlayerTheme.accent,
                  size: isSmall ? 16 : 19,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10nCurrent().wgPlySubAppearance,
                    style: ZplayType.subtitle
                        .copyWith(
                          size: isSmall ? 13.5 : 15.5,
                          weight: FontWeight.w800,
                        )
                        .toStyle(color: PlayerTheme.ink),
                  ),
                  Text(
                    l10nCurrent().wgPlySubAppearanceSubtitle,
                    style: ZplayType.caption.toStyle(color: PlayerTheme.inkSubtle),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Reset Button
              IconButton(
                icon: Icon(Icons.restart_alt_rounded, size: 19, color: PlayerTheme.inkMuted),
                tooltip: l10nCurrent().wgPlyResetSubDefaults,
                onPressed: () => PlayerSettings.resetSubtitleDefaults(player: widget.player),
              ),
              // Close Button
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: tokens.textPrimary),
                tooltip: l10nCurrent().wgPlySubModalClose,
                onPressed: widget.onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Live Subtitle Preview Area
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildLivePreview(bool isLandscapeMobile) {
    const tokens = luTokens;

    if (isLandscapeMobile) return const SizedBox.shrink();

    final textColor = _parseColorFromHex(PlayerSettings.subColor.value);
    final boxColor = _parseColorFromHex(PlayerSettings.subBackColor.value, fallback: Colors.transparent);
    final borderColor = _parseColorFromHex(PlayerSettings.subBorderColor.value, fallback: Colors.black);
    final shadowColor = _parseColorFromHex(PlayerSettings.subShadowColor.value, fallback: Colors.black54);

    final fontName = PlayerSettings.subFont.value == 'subfont'
        ? 'Poppins'
        : PlayerSettings.subFont.value;

    final fontSize = (PlayerSettings.subFontSize.value * 0.55 * PlayerSettings.subScale.value).clamp(11.0, 32.0);
    final borderSize = (PlayerSettings.subBorderSize.value * 0.75).clamp(0.0, 5.0);
    final shadowOffset = PlayerSettings.subShadowOffset.value * 1.2;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      height: 74,
      decoration: BoxDecoration(
        borderRadius: ZplayRadius.mdAll,
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF020617), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: tokens.textPrimary.withValues(alpha: ZplayOpacity.borderMedium),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.bg.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient grid / video frame simulator
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(
                painter: _VideoGridPainter(),
              ),
            ),
          ),

          // Live Subtitle Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: ZplaySpacing.s12, vertical: ZplaySpacing.s4),
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: ZplayRadius.xsAll,
            ),
            child: Text(
              l10nCurrent().playerSubPreviewSample,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fontName,
                fontSize: fontSize,
                fontWeight: PlayerSettings.subBold.value ? FontWeight.bold : FontWeight.w600,
                fontStyle: PlayerSettings.subItalic.value ? FontStyle.italic : FontStyle.normal,
                color: textColor,
                shadows: [
                  if (borderSize > 0) ...[
                    Shadow(color: borderColor, offset: Offset(-borderSize, -borderSize)),
                    Shadow(color: borderColor, offset: Offset(borderSize, -borderSize)),
                    Shadow(color: borderColor, offset: Offset(borderSize, borderSize)),
                    Shadow(color: borderColor, offset: Offset(-borderSize, borderSize)),
                  ],
                  if (shadowOffset > 0)
                    Shadow(
                      color: shadowColor,
                      offset: Offset(shadowOffset, shadowOffset),
                      blurRadius: shadowOffset * 1.5,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Presets Horizontal Bar
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildPresetsBar() {
    const tokens = luTokens;
    final activePreset = PlayerSettings.subStylePreset.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: PlayerTheme.edgeSoft)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: SubtitleStylePreset.values.map((preset) {
            final isSelected = activePreset == preset;
            return Padding(
              padding: const EdgeInsets.only(right: ZplaySpacing.s8),
              child: FocusableInkWell(
                onTap: () => PlayerSettings.setSubStylePreset(preset, player: widget.player),
                borderRadius: LuRadius.field,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? PlayerTheme.accent : PlayerTheme.raised,
                    borderRadius: LuRadius.field,
                    border: Border.all(
                      color: isSelected ? PlayerTheme.accentGlow : PlayerTheme.edgeSoft,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (preset != SubtitleStylePreset.custom)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: _parseColorFromHex(preset.textColor),
                            shape: BoxShape.circle,
                            border: Border.all(color: tokens.textPrimary.withValues(alpha: 0.30), width: 0.8),
                          ),
                        ),
                      Text(
                        preset.label,
                        style: ZplayType.caption
                            .copyWith(
                              weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            )
                            .toStyle(
                              color: isSelected ? tokens.textPrimary : PlayerTheme.inkMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab Bar Navigation
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    const tokens = luTokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.bg.withValues(alpha: 0.09),
        border: Border(bottom: BorderSide(color: PlayerTheme.edgeSoft)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: PlayerTheme.accent,
        indicatorWeight: 2.5,
        labelColor: tokens.textPrimary,
        unselectedLabelColor: PlayerTheme.inkSubtle,
        labelStyle: ZplayType.bodySmall.copyWith(weight: FontWeight.w700).toStyle(),
        unselectedLabelStyle: ZplayType.bodySmall.copyWith(weight: FontWeight.w500).toStyle(),
        tabs: [
          Tab(text: l10nCurrent().wgPlySubTabTypography, icon: const Icon(Icons.text_fields_rounded, size: 16)),
          Tab(text: l10nCurrent().wgPlySubTabColors, icon: const Icon(Icons.palette_rounded, size: 16)),
          Tab(text: l10nCurrent().wgPlySubTabOutline, icon: const Icon(Icons.border_style_rounded, size: 16)),
          Tab(text: l10nCurrent().wgPlySubTabPosition, icon: const Icon(Icons.vertical_align_bottom_rounded, size: 16)),
          Tab(text: l10nCurrent().wgPlySubTabAdvanced, icon: const Icon(Icons.tune_rounded, size: 16)),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 1: Typography
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildTypographyTab() {
    const tokens = luTokens;

    return ListView(
      padding: const EdgeInsets.all(ZplaySpacing.s16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Font Family Selector
        _buildSectionTitle(l10nCurrent().wgPlySubFontFamily),
        const SizedBox(height: ZplaySpacing.s8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: ZplaySpacing.s12, vertical: ZplaySpacing.s4),
          decoration: BoxDecoration(
            color: PlayerTheme.raised,
            borderRadius: LuRadius.field,
            border: Border.all(color: PlayerTheme.edgeSoft),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: PlayerSettings.popularFonts.contains(PlayerSettings.subFont.value)
                  ? PlayerSettings.subFont.value
                  : 'subfont',
              isExpanded: true,
              dropdownColor: tokens.surfaceOverlay,
              icon: Icon(Icons.arrow_drop_down_rounded, color: tokens.textEmphasis),
              items: PlayerSettings.popularFonts.map((f) {
                final label = f == 'subfont' ? l10nCurrent().wgPlySubDefaultFont : f;
                return DropdownMenuItem<String>(
                  value: f,
                  child: Text(
                    label,
                    style: ZplayType.label
                        .toStyle(color: tokens.textPrimary)
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: f == 'subfont' ? 'Poppins' : f,
                        ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) PlayerSettings.setSubFont(val, player: widget.player);
              },
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Base Font Size Slider
        _buildSectionTitle(l10nCurrent().wgPlySubBaseFontSize(PlayerSettings.subFontSize.value)),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded, size: 20, color: tokens.textEmphasis),
              onPressed: () => PlayerSettings.setSubFontSize(PlayerSettings.subFontSize.value - 2, player: widget.player),
            ),
            Expanded(
              child: SliderTheme(
                data: _sliderTheme(),
                child: Slider(
                  value: PlayerSettings.subFontSize.value.toDouble(),
                  min: 16.0,
                  max: 72.0,
                  divisions: 28,
                  onChanged: (v) => PlayerSettings.setSubFontSize(v.round(), player: widget.player),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: tokens.textEmphasis),
              onPressed: () => PlayerSettings.setSubFontSize(PlayerSettings.subFontSize.value + 2, player: widget.player),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Scale Multiplier Slider
        _buildSectionTitle(l10nCurrent().wgPlySubScaleMultiplier((PlayerSettings.subScale.value * 100).round())),
        SliderTheme(
          data: _sliderTheme(),
          child: Slider(
            value: PlayerSettings.subScale.value,
            min: 0.5,
            max: 2.5,
            divisions: 20,
            onChanged: (v) => PlayerSettings.setSubScale(v, player: widget.player),
          ),
        ),

        const SizedBox(height: 14),

        // Bold and Italic Toggles
        Row(
          children: [
            Expanded(
              child: _buildToggleTile(
                title: l10nCurrent().wgPlySubBold,
                icon: Icons.format_bold_rounded,
                value: PlayerSettings.subBold.value,
                onChanged: (val) => PlayerSettings.setSubBold(val, player: widget.player),
              ),
            ),
            const SizedBox(width: ZplaySpacing.s12),
            Expanded(
              child: _buildToggleTile(
                title: l10nCurrent().wgPlySubItalic,
                icon: Icons.format_italic_rounded,
                value: PlayerSettings.subItalic.value,
                onChanged: (val) => PlayerSettings.setSubItalic(val, player: widget.player),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 2: Colors & Box
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildColorsAndBoxTab() {
    const tokens = luTokens;
    final activeColor = PlayerSettings.subColor.value;
    final activeBox = PlayerSettings.subBackColor.value;

    return ListView(
      padding: const EdgeInsets.all(ZplaySpacing.s16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Text Color Palette
        _buildSectionTitle(l10nCurrent().wgPlySubTextColor),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _textColorPalette.map((item) {
            final isSelected = activeColor.toLowerCase() == (item['hex'] as String).toLowerCase();
            return FocusableInkWell(
              onTap: () => PlayerSettings.setSubColor(item['hex'], player: widget.player),
              borderRadius: LuRadius.field,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? PlayerTheme.accent : PlayerTheme.raised,
                  borderRadius: LuRadius.field,
                  border: Border.all(
                    color: isSelected ? PlayerTheme.accentGlow : PlayerTheme.edgeSoft,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tokens.textPrimary.withValues(alpha: 0.38),
                          width: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: ZplaySpacing.s8),
                    Text(
                      _localizedName(item['name'] as String),
                      style: ZplayType.caption
                          .copyWith(weight: FontWeight.w600)
                          .toStyle(
                            color: isSelected ? tokens.textPrimary : PlayerTheme.inkMuted,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 22),

        // Background Box Style
        _buildSectionTitle(l10nCurrent().wgPlySubBackgroundBox),
        const SizedBox(height: 10),
        Column(
          children: _boxColorOptions.map((opt) {
            final isSelected = activeBox.toLowerCase() == (opt['hex'] as String).toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: FocusableInkWell(
                onTap: () => PlayerSettings.setSubBackColor(opt['hex'], player: widget.player),
                borderRadius: LuRadius.field,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? PlayerTheme.accentSoft : PlayerTheme.raised,
                    borderRadius: LuRadius.field,
                    border: Border.all(
                      color: isSelected ? PlayerTheme.accent : PlayerTheme.edgeSoft,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _parseColorFromHex(opt['hex']),
                              borderRadius: ZplayRadius.xsAll,
                              border: Border.all(color: tokens.textPrimary.withValues(alpha: 0.30)),
                            ),
                          ),
                          const SizedBox(width: ZplaySpacing.s12),
                          Text(
                            _localizedName(opt['name'] as String),
                            style: ZplayType.label.copyWith(weight: FontWeight.w600).toStyle(color: tokens.textPrimary),
                          ),
                        ],
                      ),
                      Text(
                        _localizedName(opt['desc'] as String),
                        style: ZplayType.caption.toStyle(color: PlayerTheme.inkSubtle),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 3: Outlines & Shadows
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildOutlinesAndShadowsTab() {
    const tokens = luTokens;
    final activeBorderColor = PlayerSettings.subBorderColor.value;

    return ListView(
      padding: const EdgeInsets.all(ZplaySpacing.s16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Outline Color Selector
        _buildSectionTitle(l10nCurrent().wgPlySubOutlineColor),
        const SizedBox(height: ZplaySpacing.s8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _borderColorPalette.map((item) {
            final isSelected = activeBorderColor.toLowerCase() == (item['hex'] as String).toLowerCase();
            return FocusableInkWell(
              onTap: () => PlayerSettings.setSubBorderColor(item['hex'], player: widget.player),
              borderRadius: LuRadius.field,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? PlayerTheme.accent : PlayerTheme.raised,
                  borderRadius: LuRadius.field,
                  border: Border.all(
                    color: isSelected ? PlayerTheme.accentGlow : PlayerTheme.edgeSoft,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tokens.textPrimary.withValues(alpha: 0.38),
                          width: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: ZplaySpacing.s8),
                    Text(
                      _localizedName(item['name'] as String),
                      style: ZplayType.caption
                          .copyWith(weight: FontWeight.w600)
                          .toStyle(
                            color: isSelected ? tokens.textPrimary : PlayerTheme.inkMuted,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 18),

        // Outline Thickness Slider
        _buildSectionTitle(l10nCurrent().wgPlySubOutlineThickness(PlayerSettings.subBorderSize.value.toStringAsFixed(1))),
        SliderTheme(
          data: _sliderTheme(),
          child: Slider(
            value: PlayerSettings.subBorderSize.value,
            min: 0.0,
            max: 6.0,
            divisions: 12,
            onChanged: (v) => PlayerSettings.setSubBorderSize(v, player: widget.player),
          ),
        ),

        const SizedBox(height: 18),

        // Drop Shadow Offset Slider
        _buildSectionTitle(l10nCurrent().wgPlySubShadowOffset(PlayerSettings.subShadowOffset.value.toStringAsFixed(1))),
        SliderTheme(
          data: _sliderTheme(),
          child: Slider(
            value: PlayerSettings.subShadowOffset.value,
            min: 0.0,
            max: 6.0,
            divisions: 12,
            onChanged: (v) => PlayerSettings.setSubShadowOffset(v, player: widget.player),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 4: Position & Layout
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildPositionAndLayoutTab() {
    return ListView(
      padding: const EdgeInsets.all(ZplaySpacing.s16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Horizontal Alignment
        _buildSectionTitle(l10nCurrent().wgPlySubHorizontalAlign),
        const SizedBox(height: ZplaySpacing.s8),
        Row(
          children: [
            _buildAlignButton(l10nCurrent().wgPlySubAlignLeft, 'left', Icons.format_align_left_rounded),
            const SizedBox(width: ZplaySpacing.s8),
            _buildAlignButton(l10nCurrent().wgPlySubAlignCenter, 'center', Icons.format_align_center_rounded),
            const SizedBox(width: ZplaySpacing.s8),
            _buildAlignButton(l10nCurrent().wgPlySubAlignRight, 'right', Icons.format_align_right_rounded),
          ],
        ),

        const SizedBox(height: ZplaySpacing.s20),

        // Bottom Margin
        _buildSectionTitle(l10nCurrent().wgPlySubBottomMargin(PlayerSettings.subMarginY.value.round())),
        SliderTheme(
          data: _sliderTheme(),
          child: Slider(
            value: PlayerSettings.subMarginY.value,
            min: 10.0,
            max: 150.0,
            divisions: 28,
            onChanged: (v) => PlayerSettings.setSubMarginY(v, player: widget.player),
          ),
        ),

        const SizedBox(height: ZplaySpacing.s20),

        // Vertical Screen Position
        _buildSectionTitle(l10nCurrent().wgPlySubVerticalPosition(PlayerSettings.subPos.value.round())),
        SliderTheme(
          data: _sliderTheme(),
          child: Slider(
            value: PlayerSettings.subPos.value,
            min: 0.0,
            max: 100.0,
            divisions: 20,
            onChanged: (v) => PlayerSettings.setSubPos(v, player: widget.player),
          ),
        ),
      ],
    );
  }

  Widget _buildAlignButton(String title, String alignVal, IconData icon) {
    const tokens = luTokens;
    final isSelected = PlayerSettings.subAlignX.value == alignVal;
    return Expanded(
      child: FocusableInkWell(
        onTap: () => PlayerSettings.setSubAlignX(alignVal, player: widget.player),
        borderRadius: LuRadius.field,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? PlayerTheme.accent : PlayerTheme.raised,
            borderRadius: LuRadius.field,
            border: Border.all(
              color: isSelected ? PlayerTheme.accentGlow : PlayerTheme.edgeSoft,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? tokens.onAccent : PlayerTheme.inkSubtle,
                size: 18,
              ),
              const SizedBox(height: ZplaySpacing.s4),
              Text(
                title,
                style: ZplayType.caption
                    .copyWith(weight: FontWeight.w600)
                    .toStyle(
                      color: isSelected ? tokens.textPrimary : PlayerTheme.inkMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 5: Advanced / ASS Script Behavior
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildAdvancedTab() {
    const tokens = luTokens;
    final activeOverride = PlayerSettings.subAssOverride.value;

    final overrideModes = [
      {
        'val': 'no',
        'title': l10nCurrent().wgPlyAssPreserveTitle,
        'subtitle': l10nCurrent().wgPlyAssPreserveDesc,
      },
      {
        'val': 'scale',
        'title': l10nCurrent().wgPlyAssScaleTitle,
        'subtitle': l10nCurrent().wgPlyAssScaleDesc,
      },
      {
        'val': 'yes',
        'title': l10nCurrent().wgPlyAssOverrideTitle,
        'subtitle': l10nCurrent().wgPlyAssOverrideDesc,
      },
      {
        'val': 'force',
        'title': l10nCurrent().wgPlyAssForceTitle,
        'subtitle': l10nCurrent().wgPlyAssForceDesc,
      },
    ];

    final useLibass = PlayerSettings.useLibass.value;

    return ListView(
      padding: const EdgeInsets.all(ZplaySpacing.s16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle(l10nCurrent().wgPlySubRenderingEngine),
        const SizedBox(height: 10),
        
        // Flutter Engine Option
        Padding(
          padding: const EdgeInsets.only(bottom: ZplaySpacing.s8),
          child: FocusableInkWell(
            onTap: () => PlayerSettings.setUseLibass(false, player: widget.player),
            borderRadius: LuRadius.field,
            child: Container(
              padding: const EdgeInsets.all(ZplaySpacing.s12),
              decoration: BoxDecoration(
                color: !useLibass ? PlayerTheme.accentSoft : PlayerTheme.raised,
                borderRadius: LuRadius.field,
                border: Border.all(
                  color: !useLibass ? PlayerTheme.accent : PlayerTheme.edgeSoft,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: useLibass,
                    activeColor: PlayerTheme.accent,
                    onChanged: (val) {
                      if (val != null) PlayerSettings.setUseLibass(val, player: widget.player);
                    },
                  ),
                  const SizedBox(width: ZplaySpacing.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().wgPlyFlutterSubEngine,
                          style: ZplayType.label.copyWith(weight: FontWeight.w700).toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10nCurrent().wgPlyFlutterSubEngineDesc,
                          style: ZplayType.caption.toStyle(color: PlayerTheme.inkSubtle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Native libass Option
        Padding(
          padding: const EdgeInsets.only(bottom: ZplaySpacing.s16),
          child: FocusableInkWell(
            onTap: () => PlayerSettings.setUseLibass(true, player: widget.player),
            borderRadius: LuRadius.field,
            child: Container(
              padding: const EdgeInsets.all(ZplaySpacing.s12),
              decoration: BoxDecoration(
                color: useLibass ? PlayerTheme.accentSoft : PlayerTheme.raised,
                borderRadius: LuRadius.field,
                border: Border.all(
                  color: useLibass ? PlayerTheme.accent : PlayerTheme.edgeSoft,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: useLibass,
                    activeColor: PlayerTheme.accent,
                    onChanged: (val) {
                      if (val != null) PlayerSettings.setUseLibass(val, player: widget.player);
                    },
                  ),
                  const SizedBox(width: ZplaySpacing.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().wgPlyMpvLibassEngine,
                          style: ZplayType.label.copyWith(weight: FontWeight.w700).toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10nCurrent().wgPlyMpvLibassEngineDesc,
                          style: ZplayType.caption.toStyle(color: PlayerTheme.inkSubtle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        _buildSectionTitle(l10nCurrent().wgPlyAssOverrideMode),
        const SizedBox(height: 10),
        ...overrideModes.map((m) {
          final isSelected = activeOverride == m['val'];
          return Padding(
            padding: const EdgeInsets.only(bottom: ZplaySpacing.s8),
            child: FocusableInkWell(
              onTap: () => PlayerSettings.setSubAssOverride(m['val']!, player: widget.player),
              borderRadius: LuRadius.field,
              child: Container(
                padding: const EdgeInsets.all(ZplaySpacing.s12),
                decoration: BoxDecoration(
                  color: isSelected ? PlayerTheme.accentSoft : PlayerTheme.raised,
                  borderRadius: LuRadius.field,
                  border: Border.all(
                    color: isSelected ? PlayerTheme.accent : PlayerTheme.edgeSoft,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<String>(
                      value: m['val']!,
                      groupValue: activeOverride,
                      activeColor: PlayerTheme.accent,
                      onChanged: (val) {
                        if (val != null) PlayerSettings.setSubAssOverride(val, player: widget.player);
                      },
                    ),
                    const SizedBox(width: ZplaySpacing.s8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['title']!,
                            style: ZplayType.label.copyWith(weight: FontWeight.w700).toStyle(color: tokens.textPrimary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            m['subtitle']!,
                            style: ZplayType.caption.toStyle(color: PlayerTheme.inkSubtle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helper Component Builders
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: ZplayType.overline
          .copyWith(weight: FontWeight.w700, letterSpacing: 1.1)
          .toStyle(color: PlayerTheme.inkSubtle),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    const tokens = luTokens;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ZplaySpacing.s12,
        vertical: ZplaySpacing.s8,
      ),
      decoration: BoxDecoration(
        color: PlayerTheme.raised,
        borderRadius: LuRadius.field,
        border: Border.all(color: PlayerTheme.edgeSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tokens.textEmphasis),
              const SizedBox(width: ZplaySpacing.s8),
              Text(
                title,
                style: ZplayType.label.copyWith(weight: FontWeight.w600).toStyle(color: tokens.textPrimary),
              ),
            ],
          ),
          Switch.adaptive(
            value: value,
            activeColor: PlayerTheme.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  SliderThemeData _sliderTheme() {
    const tokens = luTokens;

    return SliderTheme.of(context).copyWith(
      trackHeight: 3.5,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      activeTrackColor: PlayerTheme.accent,
      inactiveTrackColor: tokens.borderStrong,
      thumbColor: tokens.textPrimary,
    );
  }
}

class _VideoGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = luTokens.textPrimary.withValues(alpha: 0.24)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
