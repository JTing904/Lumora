import '../../../l10n/l10n.dart';
import 'package:flutter/material.dart';
import '../../../services/theme/design_tokens.dart';
import '../../../services/manga/manga_settings.dart';
import '../../../widgets/common/animated_ambient_background.dart';
import '../../../widgets/common/segmented_tabs.dart';
import '../../../widgets/settings/settings_app_bar.dart';
import '../../../ui/lu_theme.dart';
import '../../../widgets/settings/lu_settings_kit.dart';

class MangaSettingsPage extends StatelessWidget {
  const MangaSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const _MangaSettingsBody();
}

class _MangaSettingsBody extends StatefulWidget {
  const _MangaSettingsBody();

  @override
  State<_MangaSettingsBody> createState() => _MangaSettingsPageState();
}

class _MangaSettingsPageState extends State<_MangaSettingsBody> {
  @override
  Widget build(BuildContext context) {
    return LuSettingsTheme(
      child: AnimatedAmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SettingsAppBar(title: l10nCurrent().stgcMangaUiAtmosphere),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  // ── 2. Discovery & Cards ──
                  _buildSectionHeader(l10nCurrent().stgbDiscoveryPosterCards),
                  const SizedBox(height: 12),
                  LuSettingsCard(
                    padding: EdgeInsets.zero,
                    child: _buildCardsConfigCard(),
                  ),

                  const SizedBox(height: 28),

                  // ── 3. Manga Reader Customization ──
                  _buildSectionHeader(l10nCurrent().stgbMangaReaderViewer),
                  const SizedBox(height: 12),
                  LuSettingsCard(
                    padding: EdgeInsets.zero,
                    child: _buildReaderConfigCard(),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final tokens = context.tokens;
    return Text(
      title,
      style: ZplayType.overline.toStyle(color: tokens.textMuted),
    );
  }

  // ── 2. Discovery & Cards Config ──
  Widget _buildCardsConfigCard() {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showContinueReading,
            builder: (context, show, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbShowContinueReading,
                  style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                ),
                subtitle: Text(
                  l10nCurrent().stgbShowContinueReadingDesc,
                  style: ZplayType.bodySmall.toStyle(
                    color: tokens.textSecondary,
                  ),
                ),
                value: show,
                onChanged: (val) => MangaSettings.setShowContinueReading(val),
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderDefault),
          const SizedBox(height: 12),

          Text(
            l10nCurrent().stgbMangaCardDensity,
            style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<MangaCardDensity>(
            valueListenable: MangaSettings.cardDensity,
            builder: (context, currentDensity, _) {
              return SegmentedTabs<MangaCardDensity>(
                selected: currentDensity,
                onSelected: (d) {
                  MangaSettings.setCardDensity(d);
                },
                options: [
                  for (final d in MangaCardDensity.values)
                    SegmentedTabOption(value: d, label: d.label),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showContentTypeBadge,
            builder: (context, show, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbShowContentTypeBadge,
                  style: ZplayType.label.toStyle(color: tokens.textPrimary),
                ),
                value: show,
                onChanged: (val) => MangaSettings.setShowContentTypeBadge(val),
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showScrollTrack,
            builder: (context, show, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbShowDesktopScrollTrack,
                  style: ZplayType.label.toStyle(color: tokens.textPrimary),
                ),
                value: show,
                onChanged: (val) => MangaSettings.setShowScrollTrack(val),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 3. Reader Configuration ──
  Widget _buildReaderConfigCard() {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Default Reading Mode
          Text(
            l10nCurrent().stgbDefaultReadingMode,
            style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<MangaReadingMode>(
            valueListenable: MangaSettings.defaultReadingMode,
            builder: (context, currentMode, _) {
              return SegmentedTabs<MangaReadingMode>(
                selected: currentMode,
                onSelected: (m) {
                  MangaSettings.setDefaultReadingMode(m);
                },
                options: [
                  for (final m in MangaReadingMode.values)
                    SegmentedTabOption(value: m, label: m.label),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Reader Max Width
          Text(
            l10nCurrent().stgbPageWidthConstraint,
            style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<MangaReaderMaxWidth>(
            valueListenable: MangaSettings.readerMaxWidth,
            builder: (context, currentWidth, _) {
              return SegmentedTabs<MangaReaderMaxWidth>(
                selected: currentWidth,
                onSelected: (w) {
                  MangaSettings.setReaderMaxWidth(w);
                },
                options: [
                  for (final w in MangaReaderMaxWidth.values)
                    SegmentedTabOption(value: w, label: w.label),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Reader Background Color
          Text(
            l10nCurrent().stgbReaderBgAtmosphere,
            style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<MangaReaderBackground>(
            valueListenable: MangaSettings.readerBackground,
            builder: (context, currentBg, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MangaReaderBackground.values.map((b) {
                  final isSelected = b == currentBg;
                  return ChoiceChip(
                    avatar: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: b.color,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(
                            color: Colors.white.withValues(
                              alpha: ZplayOpacity.textDisabled,
                            ),
                          ),
                        ),
                      ),
                    ),
                    label: Text(b.label),
                    selected: isSelected,
                    selectedColor: LuColors.gold.withValues(alpha: 0.25),
                    backgroundColor: tokens.surface,
                    labelStyle: ZplayType.label.toStyle(
                      color: isSelected ? LuColors.gold : tokens.textEmphasis,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? LuColors.gold.withValues(alpha: 0.6)
                          : tokens.borderDefault,
                    ),
                    onSelected: (selected) {
                      if (selected) MangaSettings.setReaderBackground(b);
                    },
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16),

          // Page Gap slider (for webtoon mode)
          ValueListenableBuilder<double>(
            valueListenable: MangaSettings.pageGap,
            builder: (context, gap, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10nCurrent().stgbVerticalPageGap,
                        style: ZplayType.subtitle.toStyle(
                          color: tokens.textPrimary,
                        ),
                      ),
                      Text(
                        '${gap.round()} px',
                        style: ZplayType.labelNumeric.toStyle(
                          color: LuColors.gold,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: LuColors.gold,
                      inactiveTrackColor: Colors.white.withValues(
                        alpha: ZplayOpacity.borderStrong,
                      ),
                      thumbColor: LuColors.gold,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: gap,
                      min: 0,
                      max: 24,
                      divisions: 12,
                      onChanged: (val) => MangaSettings.setPageGap(val),
                    ),
                  ),
                ],
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showPageDeck,
            builder: (context, show, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbShowPageThumbnails,
                  style: ZplayType.label.toStyle(color: tokens.textPrimary),
                ),
                subtitle: Text(
                  l10nCurrent().stgbShowPageThumbnailsDesc,
                  style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                ),
                value: show,
                onChanged: (val) => MangaSettings.setShowPageDeck(val),
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showPageScrubber,
            builder: (context, show, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbShowPageScrubber,
                  style: ZplayType.label.toStyle(color: tokens.textPrimary),
                ),
                value: show,
                onChanged: (val) => MangaSettings.setShowPageScrubber(val),
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.enableNextChapterDeck,
            builder: (context, show, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbEnableNextChapterPreview,
                  style: ZplayType.label.toStyle(color: tokens.textPrimary),
                ),
                subtitle: Text(
                  l10nCurrent().stgbEnableNextChapterPreviewDesc,
                  style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                ),
                value: show,
                onChanged: (val) => MangaSettings.setEnableNextChapterDeck(val),
              );
            },
          ),
        ],
      ),
    );
  }
}
