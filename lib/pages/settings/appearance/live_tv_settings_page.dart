import '../../../l10n/l10n.dart';
import 'package:flutter/material.dart';
import '../../../services/theme/app_theme_service.dart';
import '../../../services/theme/design_tokens.dart';
import '../../../services/home/home_page_settings.dart';
import '../../../services/iptv/iptv_settings.dart';
import '../../../widgets/common/animated_ambient_background.dart';
import '../../../widgets/common/segmented_tabs.dart';
import '../../../widgets/settings/settings_app_bar.dart';

class LiveTvSettingsPage extends StatefulWidget {
  const LiveTvSettingsPage({super.key});

  @override
  State<LiveTvSettingsPage> createState() => _LiveTvSettingsPageState();
}

class _LiveTvSettingsPageState extends State<LiveTvSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppThemeService.currentPalette.value;

    return AnimatedAmbientBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: SettingsAppBar(title: l10nCurrent().stgcLiveTvSportsUi),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // ── 1. Hero Spotlight Carousel ──
              Text(
                l10nCurrent().stgbLiveSpotlightHero,
                style: ZplayType.overline.toStyle(color: tokens.textMuted),
              ),
              const SizedBox(height: 12),
              _buildHeroSpotlightCard(palette),

              const SizedBox(height: 28),

              // ── 2. Card Layout & Poster Density ──
              Text(
                l10nCurrent().stgbChannelCardsDensity,
                style: ZplayType.overline.toStyle(color: tokens.textMuted),
              ),
              const SizedBox(height: 12),
              _buildCardDensityCard(palette),

              const SizedBox(height: 28),

              // ── 3. Category Visibility & Ordering ──
              Text(
                l10nCurrent().stgbSectionsCategoryManager,
                style: ZplayType.overline.toStyle(color: tokens.textMuted),
              ),
              const SizedBox(height: 12),
              _buildCategoryManagerCard(palette),

              const SizedBox(height: 28),

              // ── 4. Portals Modal Customization ──
              Text(
                l10nCurrent().stgbPortalsPlaylistsModal,
                style: ZplayType.overline.toStyle(color: tokens.textMuted),
              ),
              const SizedBox(height: 12),
              _buildPortalsModalCustomizerCard(palette),

              const SizedBox(height: 28),

              // ── 5. Portal Browser Customization ──
              Text(
                l10nCurrent().stgbPortalBrowserGuide,
                style: ZplayType.overline.toStyle(color: tokens.textMuted),
              ),
              const SizedBox(height: 12),
              _buildPortalBrowserCustomizerCard(palette),

              const SizedBox(height: 28),

              // ── 6. Public Stream Sources ──
              Text(
                l10nCurrent().stgbStreamSources,
                style: ZplayType.overline.toStyle(color: tokens.textMuted),
              ),
              const SizedBox(height: 12),
              _buildFreeSourcesCard(palette),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildHeroSpotlightCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return ValueListenableBuilder<bool>(
      valueListenable: IptvSettings.enableSpotlight,
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
              // Master Toggle
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.primaryColor.withValues(alpha: ZplayOpacity.overlayHover),
                      borderRadius: ZplayRadius.smAll,
                    ),
                    child: Icon(
                      Icons.tv_rounded,
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
                          l10nCurrent().stgbShowLiveSpotlight,
                          style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowLiveSpotlightDesc,
                          style: ZplayType.bodySmall.toStyle(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    activeColor: palette.primaryColor,
                    onChanged: (val) {
                      IptvSettings.setEnableSpotlight(val);
                      setState(() {});
                    },
                  ),
                ],
              ),

              if (enabled) ...[
                const SizedBox(height: 16),
                Divider(color: tokens.borderSubtle),
                const SizedBox(height: 12),

                // Style Selection
                Text(
                  l10nCurrent().stgbHeroBannerStyle,
                  style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<HeroStyle>(
                  valueListenable: IptvSettings.heroStyle,
                  builder: (context, currentStyle, _) {
                    return SegmentedTabs<HeroStyle>(
                      selected: currentStyle,
                      onSelected: (style) {
                        IptvSettings.setHeroStyle(style);
                        setState(() {});
                      },
                      options: [
                        for (final style in HeroStyle.values)
                          SegmentedTabOption(value: style, label: style.label),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
                Divider(color: tokens.borderSubtle),
                const SizedBox(height: 12),

                // Auto Rotate
                ValueListenableBuilder<bool>(
                  valueListenable: IptvSettings.heroAutoRotate,
                  builder: (context, autoRotate, _) {
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10nCurrent().stgbAutoRotateChannels,
                                style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10nCurrent().stgbAutoRotateChannelsDesc,
                                style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: autoRotate,
                          activeColor: palette.primaryColor,
                          onChanged: (val) => IptvSettings.setHeroAutoRotate(val),
                        ),
                      ],
                    );
                  },
                ),

                // Rotate Timer Slider
                ValueListenableBuilder<bool>(
                  valueListenable: IptvSettings.heroAutoRotate,
                  builder: (context, autoRotate, _) {
                    if (!autoRotate) return const SizedBox.shrink();
                    return ValueListenableBuilder<int>(
                      valueListenable: IptvSettings.heroRotateSeconds,
                      builder: (context, seconds, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10nCurrent().stgbRotationInterval,
                                  style: ZplayType.label.toStyle(color: tokens.textEmphasis),
                                ),
                                Text(
                                  l10nCurrent().stgcNSeconds(seconds),
                                  style: ZplayType.labelNumeric.toStyle(color: palette.primaryColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: palette.primaryColor,
                                inactiveTrackColor: Colors.white.withValues(alpha: ZplayOpacity.borderMedium),
                                thumbColor: palette.primaryColor,
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: seconds.toDouble(),
                                min: 3,
                                max: 15,
                                divisions: 12,
                                onChanged: (val) => IptvSettings.setHeroRotateSeconds(val.round()),
                              ),
                            ),
                          ],
                        );
                      },
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

  Widget _buildCardDensityCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Density Choice
          Text(
            l10nCurrent().stgbChannelCardSize,
            style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<CardDensity>(
            valueListenable: IptvSettings.cardDensity,
            builder: (context, currentDensity, _) {
              return SegmentedTabs<CardDensity>(
                selected: currentDensity,
                onSelected: (density) {
                  IptvSettings.setCardDensity(density);
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

          // Hover Zoom Slider
          ValueListenableBuilder<double>(
            valueListenable: IptvSettings.cardHoverZoom,
            builder: (context, zoom, _) {
              final percent = ((zoom - 1.0) * 100).round();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10nCurrent().stgbCardHoverZoom,
                        style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
                      ),
                      Text(
                        '+$percent%',
                        style: ZplayType.labelNumeric.toStyle(color: palette.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: palette.primaryColor,
                      inactiveTrackColor: Colors.white.withValues(alpha: ZplayOpacity.borderMedium),
                      thumbColor: palette.primaryColor,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: zoom,
                      min: 1.00,
                      max: 1.15,
                      divisions: 15,
                      onChanged: (val) => IptvSettings.setCardHoverZoom(val),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          // HD Badge Toggle
          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showHdBadge,
            builder: (context, showHd, _) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbShowLiveHdBadge,
                          style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowLiveHdBadgeDesc,
                          style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showHd,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowHdBadge(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          // Category Tag Toggle
          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showCategoryTag,
            builder: (context, showTag, _) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbShowChannelCategoryTag,
                          style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowChannelCategoryTagDesc,
                          style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showTag,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowCategoryTag(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          // Feed Health Toggle
          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showHealthBadge,
            builder: (context, showHealth, _) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbShowFeedHealthBadge,
                          style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowFeedHealthBadgeDesc,
                          style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showHealth,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowHealthBadge(val),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryManagerCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return ValueListenableBuilder<List<String>>(
      valueListenable: IptvSettings.visibleCategories,
      builder: (context, visibleList, _) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10nCurrent().stgbChannelCategoriesSections,
                        style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10nCurrent().stgbToggleLiveTvRows,
                        style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => IptvSettings.resetCategories(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(l10nCurrent().stgbResetAll, style: ZplayType.label.toStyle()),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: tokens.borderSubtle),
              const SizedBox(height: 6),

              ...IptvSettings.defaultCategories.map((cat) {
                final isVisible = visibleList.contains(cat);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    cat,
                    style: ZplayType.subtitle.toStyle(color: isVisible ? tokens.textPrimary : tokens.textMuted),
                  ),
                  value: isVisible,
                  activeColor: palette.primaryColor,
                  checkColor: tokens.textPrimary,
                  onChanged: (val) {
                    IptvSettings.toggleCategoryVisibility(cat);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortalsModalCustomizerCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10nCurrent().stgbPortalCardStyle,
            style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<PortalCardStyle>(
            valueListenable: IptvSettings.portalCardStyle,
            builder: (context, style, _) {
              return SegmentedTabs<PortalCardStyle>(
                selected: style,
                onSelected: (s) {
                  IptvSettings.setPortalCardStyle(s);
                  setState(() {});
                },
                options: [
                  for (final s in PortalCardStyle.values)
                    SegmentedTabOption(value: s, label: s.label),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showPortalExpiry,
            builder: (context, showExpiry, _) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbShowPortalExpiry,
                          style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowPortalExpiryDesc,
                          style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showExpiry,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowPortalExpiry(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showPortalConnections,
            builder: (context, showConn, _) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbShowMaxConnections,
                          style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowMaxConnectionsDesc,
                          style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showConn,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowPortalConnections(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          Text(
            l10nCurrent().stgbDefaultStartingTab,
            style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: IptvSettings.defaultPortalTab,
            builder: (context, tabIdx, _) {
              return SegmentedTabs<int>(
                selected: tabIdx,
                onSelected: IptvSettings.setDefaultPortalTab,
                options: [
                  SegmentedTabOption(value: 0, label: l10nCurrent().stgcXtreamPanels),
                  SegmentedTabOption(value: 1, label: l10nCurrent().stgcM3uPlaylists),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPortalBrowserCustomizerCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10nCurrent().stgbChannelStreamLayout,
            style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<PortalBrowserLayout>(
            valueListenable: IptvSettings.browserLayout,
            builder: (context, layout, _) {
              return SegmentedTabs<PortalBrowserLayout>(
                selected: layout,
                onSelected: (l) {
                  IptvSettings.setBrowserLayout(l);
                  setState(() {});
                },
                options: [
                  for (final l in PortalBrowserLayout.values)
                    SegmentedTabOption(value: l, label: l.label),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          ValueListenableBuilder<PortalBrowserLayout>(
            valueListenable: IptvSettings.browserLayout,
            builder: (context, layout, _) {
              if (layout != PortalBrowserLayout.grid) return const SizedBox.shrink();
              return ValueListenableBuilder<int>(
                valueListenable: IptvSettings.browserGridColumns,
                builder: (context, cols, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10nCurrent().stgbGridStreamColumns,
                            style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
                          ),
                          Text(
                            l10nCurrent().stgcNColumns(cols),
                            style: ZplayType.labelNumeric.toStyle(color: palette.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: palette.primaryColor,
                          inactiveTrackColor: Colors.white.withValues(alpha: ZplayOpacity.borderMedium),
                          thumbColor: palette.primaryColor,
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: cols.toDouble(),
                          min: 2,
                          max: 6,
                          divisions: 4,
                          onChanged: (val) => IptvSettings.setBrowserGridColumns(val.round()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: tokens.borderSubtle),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
          ),

          ValueListenableBuilder<double>(
            valueListenable: IptvSettings.sidebarWidth,
            builder: (context, width, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10nCurrent().stgbCategorySidebarWidth,
                        style: ZplayType.subtitle.toStyle(color: tokens.textEmphasis),
                      ),
                      Text(
                        '${width.round()} px',
                        style: ZplayType.labelNumeric.toStyle(color: palette.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: palette.primaryColor,
                      inactiveTrackColor: Colors.white.withValues(alpha: ZplayOpacity.borderMedium),
                      thumbColor: palette.primaryColor,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: width,
                      min: 200.0,
                      max: 340.0,
                      divisions: 14,
                      onChanged: (val) => IptvSettings.setSidebarWidth(val),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showStreamLogos,
            builder: (context, showLogos, _) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbShowChannelLogos,
                          style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowChannelLogosDesc,
                          style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showLogos,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowStreamLogos(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showEpgSnippet,
            builder: (context, showEpg, _) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbShowEpgNowPlaying,
                          style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowEpgNowPlayingDesc,
                          style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showEpg,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowEpgSnippet(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showCategoryCount,
            builder: (context, showCount, _) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nCurrent().stgbShowCategoryCounts,
                          style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10nCurrent().stgbShowCategoryCountsDesc,
                          style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showCount,
                    activeColor: palette.primaryColor,
                    onChanged: (val) => IptvSettings.setShowCategoryCount(val),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// The free/public M3U family is a second source of hits beyond the user's
  /// own portals, so it gets its own switch rather than riding another: a user
  /// who only wants their verified panels to fill the Boxing row can say so.
  Widget _buildFreeSourcesCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: ValueListenableBuilder<bool>(
        valueListenable: IptvSettings.includeFreeSources,
        builder: (context, includeFree, _) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10nCurrent().stgbIncludeFreePublicSources,
                      style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10nCurrent().stgbIncludeFreePublicSourcesDesc,
                      style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: includeFree,
                activeColor: palette.primaryColor,
                onChanged: (val) => IptvSettings.setIncludeFreeSources(val),
              ),
            ],
          );
        },
      ),
    );
  }
}
