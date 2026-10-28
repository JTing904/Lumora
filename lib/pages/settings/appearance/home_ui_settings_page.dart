import '../../../l10n/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../l10n/option_labels.dart';
import '../../../services/theme/app_theme_service.dart';
import '../../../services/theme/custom_background_service.dart';
import '../../../services/theme/design_tokens.dart';
import '../../../services/home/home_page_settings.dart';
import '../../../services/collections/collections_service.dart';
import '../../../services/my_list/my_list_service.dart';
import '../../../services/simkl/simkl_service.dart';
import '../../../services/trakt/trakt_service.dart';
import '../../../widgets/common/animated_ambient_background.dart';
import '../../../widgets/common/segmented_tabs.dart';
import '../../../widgets/settings/settings_app_bar.dart';
import 'custom_background_settings_page.dart';
import '../../../widgets/settings/lu_settings_kit.dart';

class HomeUiSettingsPage extends StatefulWidget {
  const HomeUiSettingsPage({super.key});

  @override
  State<HomeUiSettingsPage> createState() => _HomeUiSettingsPageState();
}

class _HomeUiSettingsPageState extends State<HomeUiSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final myListCount = MyListService.items.value.length;

    return LuSettingsTheme(
      child: AnimatedAmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SettingsAppBar(title: l10nCurrent().stgcHomeUiThemes),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  // ── 2. Ambient Background Lighting & Moving Glows ──
                  Text(
                    l10nCurrent().stgbAmbientLightingGlows,
                    style: ZplayType.overline.toStyle(color: tokens.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _buildAmbientLightsCard(),

                  const SizedBox(height: 28),

                  // ── 2b. Custom Wallpaper & Background Photo ──
                  Text(
                    l10nCurrent().stgbCustomBgWallpaperCaps,
                    style: ZplayType.overline.toStyle(color: tokens.textMuted),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<CustomBackgroundData>(
                    valueListenable: CustomBackgroundService.notifier,
                    builder: (context, customBg, _) {
                      final hasWallpaper = customBg.hasCustomBackground;
                      final palette = AppThemeService.currentPalette.value;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CustomBackgroundSettingsPage(),
                            ),
                          );
                        },
                        borderRadius: ZplayRadius.mdAll,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: ZplayRadius.mdAll,
                            border: Border.all(
                              color: hasWallpaper
                                  ? palette.primaryColor.withValues(alpha: 0.40)
                                  : tokens.borderDefault,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: palette.primaryColor.withValues(
                                    alpha: ZplayOpacity.overlayHover,
                                  ),
                                  borderRadius: ZplayRadius.smAll,
                                ),
                                child: Icon(
                                  Icons.wallpaper_rounded,
                                  color: palette.primaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10nCurrent().stgbCustomWallpaperBlend,
                                      style: ZplayType.subtitle.toStyle(
                                        color: tokens.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      hasWallpaper
                                          ? l10nCurrent()
                                                .stgbCustomBgActiveBlend
                                          : l10nCurrent()
                                                .stgbUploadOrChooseWallpaper,
                                      style: ZplayType.bodySmall.toStyle(
                                        color: tokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: tokens.textMuted,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── 3. "Because you have on your list" Section ──
                  Text(
                    l10nCurrent().stgbSmartRecsCaps,
                    style: ZplayType.overline.toStyle(color: tokens.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _buildSimilarRecommendationsCard(myListCount),

                  const SizedBox(height: 28),

                  // ── 3b. Curated Collections ──
                  Text(
                    l10nCurrent().stgbCuratedCollections,
                    style: ZplayType.overline.toStyle(color: tokens.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _buildCollectionsCard(),

                  const SizedBox(height: 28),

                  // ── 4. Hero Carousel & Spotlight ──
                  Text(
                    l10nCurrent().stgbHeroBannerSpotlight,
                    style: ZplayType.overline.toStyle(color: tokens.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _buildHeroControlsCard(),

                  const SizedBox(height: 28),

                  // ── 5. Card Layout & Poster Density ──
                  Text(
                    l10nCurrent().stgbPosterCardsDensity,
                    style: ZplayType.overline.toStyle(color: tokens.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _buildCardDensityCard(),

                  const SizedBox(height: 28),

                  // ── 6. Feature Shortcuts & Buttons ──
                  Text(
                    l10nCurrent().stgbHeaderShortcuts,
                    style: ZplayType.overline.toStyle(color: tokens.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureTogglesCard(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientLightsCard() {
    final tokens = context.tokens;
    final palette = AppThemeService.currentPalette.value;

    return ValueListenableBuilder<bool>(
      valueListenable: HomePageSettings.enableAmbientLights,
      builder: (context, enabled, _) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: ZplayRadius.mdAll,
            border: Border.all(
              color: enabled
                  ? palette.primaryColor.withValues(alpha: 0.35)
                  : tokens.borderDefault,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Interactive Mini Preview
              ClipRRect(
                borderRadius: ZplayRadius.smAll,
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: AnimatedAmbientBackground()),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.bg.withValues(alpha: 0.55),
                            borderRadius: ZplayRadius.smAll,
                            border: Border.all(color: tokens.borderStrong),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_motion_rounded,
                                size: 14,
                                color: palette.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10nCurrent().stgbLiveLightingPreview,
                                style: ZplayType.overline.toStyle(
                                  color: tokens.textEmphasis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Master Switch
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.primaryColor.withValues(
                        alpha: ZplayOpacity.overlayHover,
                      ),
                      borderRadius: ZplayRadius.smAll,
                    ),
                    child: Icon(
                      Icons.blur_linear_rounded,
                      color: palette.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbMovingAmbientLights,
                          style: ZplayType.subtitle.toStyle(
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbMovingAmbientLightsDesc,
                          style: ZplayType.caption.toStyle(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    onChanged: (val) {
                      HomePageSettings.setEnableAmbientLights(val);
                      setState(() {});
                    },
                  ),
                ],
              ),

              if (enabled) ...[
                const SizedBox(height: 16),
                Divider(color: tokens.borderSubtle),
                const SizedBox(height: 12),

                // Lighting Pattern / Position
                Text(
                  l10nCurrent().stgbLightingPatternPosition,
                  style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<AmbientLightPattern>(
                  valueListenable: HomePageSettings.ambientLightPattern,
                  builder: (context, currentPattern, _) {
                    return SegmentedTabs<AmbientLightPattern>(
                      selected: currentPattern,
                      onSelected: (pat) {
                        HomePageSettings.setAmbientLightPattern(pat);
                        setState(() {});
                      },
                      options: [
                        for (final pat in AmbientLightPattern.values)
                          SegmentedTabOption(value: pat, label: pat.label),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
                Divider(color: tokens.borderSubtle),
                const SizedBox(height: 12),

                // Strength / Intensity Slider
                ValueListenableBuilder<double>(
                  valueListenable: HomePageSettings.ambientLightIntensity,
                  builder: (context, intensity, _) {
                    final percent = (intensity * 200).round();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10nCurrent().stgbGlowStrengthIntensity,
                              style: ZplayType.subtitle.toStyle(
                                color: tokens.textEmphasis,
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: ZplayType.labelNumeric.toStyle(
                                color: palette.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: palette.primaryColor,
                            inactiveTrackColor: Colors.white.withValues(
                              alpha: ZplayOpacity.borderMedium,
                            ),
                            thumbColor: palette.primaryColor,
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: intensity,
                            min: 0.05,
                            max: 0.50,
                            divisions: 18,
                            onChanged: (val) =>
                                HomePageSettings.setAmbientLightIntensity(val),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Motion Speed Slider
                ValueListenableBuilder<double>(
                  valueListenable: HomePageSettings.ambientLightSpeed,
                  builder: (context, speed, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10nCurrent().stgbMotionFlowSpeed,
                              style: ZplayType.subtitle.toStyle(
                                color: tokens.textEmphasis,
                              ),
                            ),
                            Text(
                              '${speed.toStringAsFixed(1)}x',
                              style: ZplayType.labelNumeric.toStyle(
                                color: palette.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: palette.primaryColor,
                            inactiveTrackColor: Colors.white.withValues(
                              alpha: ZplayOpacity.borderMedium,
                            ),
                            thumbColor: palette.primaryColor,
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: speed,
                            min: 0.4,
                            max: 2.5,
                            divisions: 21,
                            onChanged: (val) =>
                                HomePageSettings.setAmbientLightSpeed(val),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimilarRecommendationsCard(int myListCount) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppThemeService.currentPalette.value.primaryColor
                      .withValues(alpha: ZplayOpacity.overlayHover),
                  borderRadius: ZplayRadius.smAll,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppThemeService.currentPalette.value.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10nCurrent().stgbSmartRecommendations,
                      style: ZplayType.subtitle.toStyle(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10nCurrent().stgbSmartRecommendationsDesc,
                      style: ZplayType.bodySmall.toStyle(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 8),

          // 1. Because You Have... (My List)
          _buildRecommendationToggleRow(
            title: l10nCurrent().stgbBecauseYouHave,
            subtitle: l10nCurrent().stgbBecauseYouHaveDesc,
            listenable: HomePageSettings.enableSimilar,
            onChanged: (val) {
              HomePageSettings.setEnableSimilar(val);
              setState(() {});
            },
          ),

          // 2. Because You're Watching... (Continue Watching)
          _buildRecommendationToggleRow(
            title: l10nCurrent().stgbBecauseYoureWatching,
            subtitle: l10nCurrent().stgbBecauseYoureWatchingDesc,
            listenable: HomePageSettings.enableWatchingSimilar,
            onChanged: (val) {
              HomePageSettings.setEnableWatchingSimilar(val);
              setState(() {});
            },
          ),

          // Not a recommendation source like the two above, but it belongs with
          // them: it decides which of the addon rails reach the shelf at all.
          _buildRecommendationToggleRow(
            title: localizedOptionLabel('Hide Rails With No Artwork'),
            subtitle: l10nCurrent().stgcDropImagelessRails,
            listenable: HomePageSettings.hideArtlessRails,
            onChanged: (val) {
              HomePageSettings.setHideArtlessRails(val);
              setState(() {});
            },
          ),

          // 3. Trakt Recommendations
          FutureBuilder<bool>(
            future: TraktService.instance.isAuthenticated(),
            builder: (context, snapshot) {
              final isAuthed = snapshot.data ?? false;
              return _buildRecommendationToggleRow(
                title: l10nCurrent().stgbTraktRecommendations,
                subtitle: isAuthed
                    ? l10nCurrent().stgbTraktRecommendationsDesc
                    : l10nCurrent().stgbRequiresTraktLogin,
                listenable: HomePageSettings.enableTraktRecommendations,
                trailingExtra: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isAuthed
                        ? const Color(0xFFED1C24).withValues(alpha: 0.2)
                        : Colors.white.withValues(
                            alpha: ZplayOpacity.borderStrong,
                          ),
                    borderRadius: ZplayRadius.xsAll,
                    border: Border.all(
                      color: isAuthed
                          ? const Color(0xFFED1C24).withValues(alpha: 0.4)
                          : tokens.borderStrong,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isAuthed
                        ? l10nCurrent().stgbConnected
                        : l10nCurrent().stgbDisconnected,
                    style: ZplayType.overline.toStyle(
                      color: isAuthed
                          ? const Color(0xFFFF5252)
                          : tokens.textMuted,
                    ),
                  ),
                ),
                onChanged: (val) {
                  HomePageSettings.setEnableTraktRecommendations(val);
                  setState(() {});
                },
              );
            },
          ),

          // 4. Simkl Recommendations
          FutureBuilder<bool>(
            future: SimklService.instance.isAuthenticated(),
            builder: (context, snapshot) {
              final isAuthed = snapshot.data ?? false;
              return _buildRecommendationToggleRow(
                title: l10nCurrent().stgbSimklRecommendations,
                subtitle: isAuthed
                    ? l10nCurrent().stgbSimklRecommendationsDesc
                    : l10nCurrent().stgbRequiresSimklLogin,
                listenable: HomePageSettings.enableSimklRecommendations,
                trailingExtra: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isAuthed
                        ? const Color(0xFF00B2FF).withValues(alpha: 0.2)
                        : Colors.white.withValues(
                            alpha: ZplayOpacity.borderStrong,
                          ),
                    borderRadius: ZplayRadius.xsAll,
                    border: Border.all(
                      color: isAuthed
                          ? const Color(0xFF00B2FF).withValues(alpha: 0.4)
                          : tokens.borderStrong,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isAuthed
                        ? l10nCurrent().stgbConnected
                        : l10nCurrent().stgbDisconnected,
                    style: ZplayType.overline.toStyle(
                      color: isAuthed
                          ? const Color(0xFF40C4FF)
                          : tokens.textMuted,
                    ),
                  ),
                ),
                onChanged: (val) {
                  HomePageSettings.setEnableSimklRecommendations(val);
                  setState(() {});
                },
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          // Position Dropdown
          Text(
            l10nCurrent().stgbRecSlidersPosition,
            style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<SimilarSectionPosition>(
            valueListenable: HomePageSettings.similarPosition,
            builder: (context, pos, _) {
              return DropdownButtonFormField<SimilarSectionPosition>(
                value: pos,
                dropdownColor: tokens.surfaceOverlay,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: tokens.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: ZplayRadius.smAll,
                    borderSide: BorderSide(color: tokens.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: ZplayRadius.smAll,
                    borderSide: BorderSide(color: tokens.borderDefault),
                  ),
                ),
                style: ZplayType.label.toStyle(color: tokens.textPrimary),
                items: SimilarSectionPosition.values.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p.label));
                }).toList(),
                onChanged: (newPos) {
                  if (newPos != null) {
                    HomePageSettings.setSimilarPosition(newPos);
                    setState(() {});
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationToggleRow({
    required String title,
    required String subtitle,
    required ValueListenable<bool> listenable,
    required ValueChanged<bool> onChanged,
    Widget? trailingExtra,
  }) {
    final tokens = context.tokens;
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, enabled, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: ZplayType.subtitle.toStyle(
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        if (trailingExtra != null) ...[
                          const SizedBox(width: 8),
                          trailingExtra,
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: ZplayType.caption.toStyle(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(value: enabled, onChanged: onChanged),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollectionsCard() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: _buildRecommendationToggleRow(
        title: l10nCurrent().stgbCollections,
        subtitle: l10nCurrent().stgbCollectionsDesc,
        listenable: CollectionsService.showOnHome,
        onChanged: (val) {
          CollectionsService.showOnHome.value = val;
          setState(() {});
        },
      ),
    );
  }

  Widget _buildHeroControlsCard() {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master Spotlight Switch
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.enableSpotlight,
            builder: (context, enabled, _) {
              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppThemeService.currentPalette.value.primaryColor
                          .withValues(alpha: ZplayOpacity.overlayHover),
                      borderRadius: ZplayRadius.smAll,
                    ),
                    child: Icon(
                      Icons.movie_filter_rounded,
                      color: AppThemeService.currentPalette.value.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbShowHeroBanner,
                          style: ZplayType.subtitle.toStyle(
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowHeroBannerDesc,
                          style: ZplayType.caption.toStyle(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    onChanged: (val) {
                      HomePageSettings.setEnableSpotlight(val);
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.enableSpotlight,
            builder: (context, enabled, _) {
              if (!enabled) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Divider(color: tokens.borderSubtle),
                  const SizedBox(height: 12),

                  // Hero Style Selector
                  Text(
                    l10nCurrent().stgbSpotlightStyle,
                    style: ZplayType.subtitle.toStyle(
                      color: tokens.textEmphasis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<HeroStyle>(
                    valueListenable: HomePageSettings.heroStyle,
                    builder: (context, currentStyle, _) {
                      return SegmentedTabs<HeroStyle>(
                        selected: currentStyle,
                        onSelected: (style) {
                          HomePageSettings.setHeroStyle(style);
                          setState(() {});
                        },
                        options: [
                          for (final style in HeroStyle.values)
                            SegmentedTabOption(
                              value: style,
                              label: style.label,
                            ),
                        ],
                      );
                    },
                  ),

                  // Auto-Rotate Switch & Interval
                  ValueListenableBuilder<bool>(
                    valueListenable: HomePageSettings.heroAutoRotate,
                    builder: (context, autoRotate, _) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10nCurrent().stgbAutoRotateSpotlight,
                                      style: ZplayType.subtitle.toStyle(
                                        color: tokens.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10nCurrent().stgbAutoRotateSpotlightDesc,
                                      style: ZplayType.caption.toStyle(
                                        color: tokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: autoRotate,
                                onChanged: (val) {
                                  HomePageSettings.setHeroAutoRotate(val);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          if (autoRotate) ...[
                            const SizedBox(height: 10),
                            ValueListenableBuilder<int>(
                              valueListenable:
                                  HomePageSettings.heroRotateSeconds,
                              builder: (context, seconds, _) {
                                return Row(
                                  children: [
                                    Text(
                                      l10nCurrent().stgcIntervalSeconds(
                                        seconds,
                                      ),
                                      style: ZplayType.labelNumeric.toStyle(
                                        color: tokens.textEmphasis,
                                      ),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: AppThemeService
                                              .currentPalette
                                              .value
                                              .primaryColor,
                                          inactiveTrackColor: Colors.white
                                              .withValues(
                                                alpha:
                                                    ZplayOpacity.borderMedium,
                                              ),
                                          thumbColor: AppThemeService
                                              .currentPalette
                                              .value
                                              .primaryColor,
                                          trackHeight: 3,
                                        ),
                                        child: Slider(
                                          value: seconds.toDouble(),
                                          min: 3,
                                          max: 15,
                                          divisions: 12,
                                          onChanged: (val) =>
                                              HomePageSettings.setHeroRotateSeconds(
                                                val.round(),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  Divider(color: tokens.borderSubtle),
                  const SizedBox(height: 12),

                  // Ambient Glow Switch
                  ValueListenableBuilder<bool>(
                    valueListenable: HomePageSettings.ambientGlow,
                    builder: (context, glow, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10nCurrent().stgbAmbientBackdropLighting,
                                  style: ZplayType.subtitle.toStyle(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10nCurrent().stgbAmbientBackdropLightingDesc,
                                  style: ZplayType.caption.toStyle(
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: glow,
                            onChanged: (val) {
                              HomePageSettings.setAmbientGlow(val);
                              setState(() {});
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardDensityCard() {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10nCurrent().stgbPosterSizeDensity,
            style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<CardDensity>(
            valueListenable: HomePageSettings.cardDensity,
            builder: (context, currentDensity, _) {
              return SegmentedTabs<CardDensity>(
                selected: currentDensity,
                onSelected: (density) {
                  HomePageSettings.setCardDensity(density);
                  setState(() {});
                },
                options: [
                  for (final density in CardDensity.values)
                    SegmentedTabOption(value: density, label: density.label),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          // Rating Badges Switch
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.showRating,
            builder: (context, showRating, _) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbShowImdbBadges,
                          style: ZplayType.subtitle.toStyle(
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowImdbBadgesDesc,
                          style: ZplayType.caption.toStyle(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showRating,
                    onChanged: (val) {
                      HomePageSettings.setShowRating(val);
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          // Card Hover Zoom Strength
          ValueListenableBuilder<double>(
            valueListenable: HomePageSettings.cardHoverZoom,
            builder: (context, zoom, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10nCurrent().stgbPosterHoverZoom,
                          style: ZplayType.subtitle.toStyle(
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${zoom.toStringAsFixed(2)}x',
                        style: ZplayType.labelNumeric.toStyle(
                          color:
                              AppThemeService.currentPalette.value.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:
                          AppThemeService.currentPalette.value.primaryColor,
                      inactiveTrackColor: Colors.white.withValues(
                        alpha: ZplayOpacity.borderMedium,
                      ),
                      thumbColor:
                          AppThemeService.currentPalette.value.primaryColor,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: zoom,
                      min: 1.00,
                      max: 1.15,
                      divisions: 15,
                      onChanged: (val) =>
                          HomePageSettings.setCardHoverZoom(val),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTogglesCard() {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TV Shows Airing Calendar
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.enableCalendar,
            builder: (context, enabled, _) {
              return Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tokens.info.withValues(
                        alpha: ZplayOpacity.overlayHover,
                      ),
                      borderRadius: ZplayRadius.smAll,
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: tokens.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbTvAiringCalendar,
                          style: ZplayType.subtitle.toStyle(
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbTvAiringCalendarDesc,
                          style: ZplayType.bodySmall.toStyle(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    onChanged: (val) => HomePageSettings.setEnableCalendar(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle, height: 1),
          const SizedBox(height: 12),

          // AI Recommendation Quiz
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.enableAiQuiz,
            builder: (context, enabled, _) {
              return Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(
                        alpha: ZplayOpacity.overlayHover,
                      ),
                      borderRadius: ZplayRadius.smAll,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: tokens.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbAiRecQuiz,
                          style: ZplayType.subtitle.toStyle(
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbAiRecQuizDesc,
                          style: ZplayType.bodySmall.toStyle(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    onChanged: (val) => HomePageSettings.setEnableAiQuiz(val),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
