import '../../../l10n/l10n.dart';
import 'package:flutter/material.dart';
import '../../../l10n/option_labels.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../../services/theme/app_theme_service.dart';
import '../../../services/theme/design_tokens.dart';
import '../../../services/audiobook/audiobook_settings.dart';
import '../../../widgets/audiobook/audiobook_interactive_physics_button.dart';
import '../../../widgets/audiobook/audiobook_waveform_seekbar.dart';
import '../../../widgets/common/animated_ambient_background.dart';
import '../../../widgets/common/focusable_card.dart';
import '../../../widgets/common/segmented_tabs.dart';
import '../../../widgets/settings/settings_app_bar.dart';
import '../../music/lu_media_kit.dart';
import 'audiobook_player_studio_page.dart';

class AudiobookSettingsPage extends StatefulWidget {
  const AudiobookSettingsPage({super.key});

  @override
  State<AudiobookSettingsPage> createState() => _AudiobookSettingsPageState();
}

class _AudiobookSettingsPageState extends State<AudiobookSettingsPage> {
  // Mock player states for live interactive studio preview
  bool _previewIsPlaying = false;
  Duration _previewPosition = const Duration(minutes: 14, seconds: 20);
  final Duration _previewDuration = const Duration(minutes: 42, seconds: 15);
  double _previewSpeed = 1.0;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeService.currentPalette.value;

    // The Lumora media look (gold controls on near-black), the same theme
    // the Music and Audiobooks pages themselves are drawn in.
    return Theme(
      data: luMediaTheme(),
      child: AnimatedAmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SettingsAppBar(title: l10nCurrent().stgcAudiobookUiStudio),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  // ── 2. Ambient Background Lighting ──
                  _buildSectionHeader(l10nCurrent().stgbAmbientLightingGlows),
                  const SizedBox(height: 12),
                  _buildAmbientLightsCard(palette),

                  const SizedBox(height: 28),

                  // ── 3. Discovery & Posters ──
                  _buildSectionHeader(
                    l10nCurrent().stgbDiscoveryAudiobookPosters,
                  ),
                  const SizedBox(height: 12),
                  _buildDiscoveryConfigCard(palette),

                  const SizedBox(height: 28),

                  // ── Enter Visual Player Studio Banner ──
                  _buildEnterPlayerStudioBanner(palette),

                  const SizedBox(height: 28),

                  // ── 4. Player Presets ──
                  _buildSectionHeader(l10nCurrent().stgbChooseAudioPreset),
                  const SizedBox(height: 12),
                  _buildPlayerPresetSelector(palette),

                  const SizedBox(height: 28),

                  // ── 5. Make Your Custom Player Studio ──
                  _buildSectionHeader(
                    l10nCurrent().stgbMakeCustomAudiobookPlayer,
                  ),
                  const SizedBox(height: 12),
                  _buildCustomPlayerStudioCard(palette),

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

  // ── 2. Ambient Lighting ──
  Widget _buildAmbientLightsCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: AudiobookSettings.enableAmbientLights,
            builder: (context, enabled, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbEnableMovingAtmosphere,
                  style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                ),
                subtitle: Text(
                  l10nCurrent().stgcAuroraThemedTo(
                    localizedOptionLabel(palette.name),
                  ),
                  style: ZplayType.bodySmall.toStyle(
                    color: tokens.textSecondary,
                  ),
                ),
                value: enabled,
                onChanged: (val) =>
                    AudiobookSettings.setEnableAmbientLights(val),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 3. Discovery & Posters Config ──
  Widget _buildDiscoveryConfigCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: AudiobookSettings.enableSpotlight,
            builder: (context, enabled, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbShowHeroCarousel,
                  style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                ),
                subtitle: Text(
                  l10nCurrent().stgbAudiobookHeroDesc,
                  style: ZplayType.bodySmall.toStyle(
                    color: tokens.textSecondary,
                  ),
                ),
                value: enabled,
                onChanged: (val) => AudiobookSettings.setEnableSpotlight(val),
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: AudiobookSettings.showContinueListening,
            builder: (context, show, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbShowContinueListening,
                  style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                ),
                subtitle: Text(
                  l10nCurrent().stgbContinueListeningDesc,
                  style: ZplayType.bodySmall.toStyle(
                    color: tokens.textSecondary,
                  ),
                ),
                value: show,
                onChanged: (val) =>
                    AudiobookSettings.setShowContinueListening(val),
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: tokens.borderDefault),
          const SizedBox(height: 12),

          Text(
            l10nCurrent().stgbAudiobookCardDensity,
            style: ZplayType.label.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<AudiobookCardDensity>(
            valueListenable: AudiobookSettings.cardDensity,
            builder: (context, currentDensity, _) {
              return SegmentedTabs<AudiobookCardDensity>(
                selected: currentDensity,
                onSelected: (d) {
                  AudiobookSettings.setCardDensity(d);
                },
                options: [
                  for (final d in AudiobookCardDensity.values)
                    SegmentedTabOption(value: d, label: d.label),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          ValueListenableBuilder<bool>(
            valueListenable: AudiobookSettings.showCategoryPills,
            builder: (context, show, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbShowGenreBadges,
                  style: ZplayType.body.toStyle(color: tokens.textPrimary),
                ),
                value: show,
                onChanged: (val) => AudiobookSettings.setShowCategoryPills(val),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 4. Player Presets Selector ──
  Widget _buildPlayerPresetSelector(AppThemePalette palette) {
    final tokens = context.tokens;
    return ValueListenableBuilder<AudiobookPlayerPreset>(
      valueListenable: AudiobookSettings.selectedPlayerPreset,
      builder: (context, selectedPreset, _) {
        return Column(
          children: AudiobookPlayerPreset.values.map((preset) {
            final isSelected = preset == selectedPreset;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.primaryColor.withValues(alpha: 0.12)
                    : null,
                borderRadius: ZplayRadius.mdAll,
                border: Border.all(
                  color: isSelected
                      ? palette.primaryColor
                      : tokens.borderDefault,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  onTap: () =>
                      AudiobookSettings.setSelectedPlayerPreset(preset),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.primaryColor
                          : tokens.borderSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      preset == AudiobookPlayerPreset.modernGlass
                          ? Icons.blur_on_rounded
                          : preset == AudiobookPlayerPreset.vinylStudio
                          ? Icons.album_rounded
                          : preset == AudiobookPlayerPreset.minimalCapsule
                          ? Icons.view_compact_rounded
                          : preset == AudiobookPlayerPreset.immersiveCanvas
                          ? Icons.fullscreen_rounded
                          : Icons.dashboard_customize_rounded,
                      color: isSelected ? tokens.onAccent : tokens.textEmphasis,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    preset.label,
                    style: ZplayType.subtitle.toStyle(
                      color: tokens.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    preset.description,
                    style: ZplayType.bodySmall.toStyle(
                      color: tokens.textSecondary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (preset == AudiobookPlayerPreset.customStudio)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AudiobookPlayerStudioPage(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: palette.primaryColor,
                            ),
                            label: Text(
                              l10nCurrent().stgbOpenStudio,
                              style: ZplayType.label.toStyle(
                                color: palette.primaryColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: palette.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: const RoundedRectangleBorder(
                                borderRadius: ZplayRadius.smAll,
                              ),
                            ),
                          ),
                        ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: palette.primaryColor,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Enter Visual Player Studio Banner ──
  Widget _buildEnterPlayerStudioBanner(AppThemePalette palette) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        borderRadius: ZplayRadius.lgAll,
        gradient: LinearGradient(
          colors: [
            palette.primaryColor.withValues(alpha: 0.28),
            palette.accentColor.withValues(alpha: 0.15),
            tokens.bg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: palette.primaryColor.withValues(alpha: 0.5),
          width: 1.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [palette.primaryColor, palette.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.dashboard_customize_rounded,
                color: tokens.onAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wraps, so the badge drops under the title on a phone.
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10nCurrent().stgbVisualPlayerStudio,
                        style: ZplayType.title.toStyle(
                          color: tokens.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primaryColor.withValues(alpha: 0.3),
                          borderRadius: ZplayRadius.xsAll,
                        ),
                        child: Text(
                          l10nCurrent().stgbFullStudio,
                          style: ZplayType.overline.toStyle(
                            color: palette.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10nCurrent().stgbVisualPlayerStudioDesc,
                    style: ZplayType.bodySmall.toStyle(
                      color: tokens.textEmphasis,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AudiobookPlayerStudioPage(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: tokens.onAccent,
                    ),
                    label: Text(
                      l10nCurrent().stgbEnterPlayerStudio,
                      style: ZplayType.label.toStyle(color: tokens.onAccent),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primaryColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: ZplayRadius.smAll,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 5. Make Your Custom Player Studio ──
  Widget _buildCustomPlayerStudioCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Interactive Player Studio Preview Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: ZplayRadius.mdAll,
              border: Border.all(
                color: palette.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_fix_high_rounded,
                          color: palette.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10nCurrent().stgbInteractiveStudioPreview,
                          style: ZplayType.label.toStyle(
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.primaryColor.withValues(alpha: 0.2),
                        borderRadius: ZplayRadius.xsAll,
                      ),
                      child: Text(
                        l10nCurrent().stgbLiveCaps,
                        style: ZplayType.overline.toStyle(
                          color: palette.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Artwork Preview
                ValueListenableBuilder<AudiobookArtworkStyle>(
                  valueListenable: AudiobookSettings.customArtworkStyle,
                  builder: (context, artStyle, _) {
                    if (artStyle == AudiobookArtworkStyle.hidden) {
                      return const SizedBox.shrink();
                    }
                    if (artStyle == AudiobookArtworkStyle.vinylDisc) {
                      return Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.surface,
                          border: Border.all(
                            color: tokens.textDisabled,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            color: palette.primaryColor,
                            size: 36,
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: ZplayRadius.mdAll,
                        gradient: LinearGradient(
                          colors: [palette.primaryColor, palette.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.headphones_rounded,
                          color: tokens.onAccent,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                Text(
                  'The Way of Kings',
                  style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Brandon Sanderson • Chapter 1: Stormblessed',
                  style: ZplayType.bodySmall.toStyle(
                    color: tokens.textSecondary,
                  ),
                ),

                const SizedBox(height: 14),

                // Live Seekbar Canvas
                ValueListenableBuilder<AudiobookSeekbarStyle>(
                  valueListenable: AudiobookSettings.customSeekbarStyle,
                  builder: (context, seekStyle, _) {
                    return AudiobookWaveformSeekbar(
                      position: _previewPosition,
                      duration: _previewDuration,
                      isPlaying: _previewIsPlaying,
                      style: seekStyle,
                      onSeek: (pos) => setState(() => _previewPosition = pos),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Live Action Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rewind 10s
                    IconButton(
                      icon: Icon(
                        Icons.replay_10_rounded,
                        color: tokens.textEmphasis,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          final p =
                              _previewPosition - const Duration(seconds: 10);
                          _previewPosition = p < Duration.zero
                              ? Duration.zero
                              : p;
                        });
                      },
                    ),
                    const SizedBox(width: 12),

                    // Custom Styled Play/Pause Button
                    ValueListenableBuilder<AudiobookPlayButtonStyle>(
                      valueListenable: AudiobookSettings.customPlayButtonStyle,
                      builder: (context, playBtnStyle, _) {
                        return FocusableCard(
                          onTap: () => setState(
                            () => _previewIsPlaying = !_previewIsPlaying,
                          ),
                          builder: (_, state) => _buildCustomPlayButtonWidget(
                            playBtnStyle,
                            palette,
                            _previewIsPlaying,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    // Forward 10s
                    IconButton(
                      icon: Icon(
                        Icons.forward_10_rounded,
                        color: tokens.textEmphasis,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          final p =
                              _previewPosition + const Duration(seconds: 10);
                          _previewPosition = p > _previewDuration
                              ? _previewDuration
                              : p;
                        });
                      },
                    ),

                    const SizedBox(width: 16),

                    // Speed Pill
                    InkWell(
                      onTap: () {
                        setState(() {
                          _previewSpeed = _previewSpeed >= 2.0
                              ? 1.0
                              : _previewSpeed + 0.25;
                        });
                      },
                      borderRadius: ZplayRadius.smAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.borderDefault,
                          borderRadius: ZplayRadius.smAll,
                          border: Border.all(color: tokens.borderStrong),
                        ),
                        child: Text(
                          '${_previewSpeed.toStringAsFixed(2)}x',
                          style: ZplayType.labelNumeric.toStyle(
                            color: palette.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Customize Seek Bar Style ──
          Text(
            l10nCurrent().stgbSeekBarScrubberStyle,
            style: ZplayType.label.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<AudiobookSeekbarStyle>(
            valueListenable: AudiobookSettings.customSeekbarStyle,
            builder: (context, currentStyle, _) {
              return SegmentedTabs<AudiobookSeekbarStyle>(
                selected: currentStyle,
                onSelected: (s) {
                  AudiobookSettings.setCustomSeekbarStyle(s);
                },
                options: [
                  for (final s in AudiobookSeekbarStyle.values)
                    SegmentedTabOption(value: s, label: s.label),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Customize Play / Pause Button Style ──
          Text(
            l10nCurrent().stgbPlayPauseStyling,
            style: ZplayType.label.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<AudiobookPlayButtonStyle>(
            valueListenable: AudiobookSettings.customPlayButtonStyle,
            builder: (context, currentStyle, _) {
              return SegmentedTabs<AudiobookPlayButtonStyle>(
                selected: currentStyle,
                onSelected: (s) {
                  AudiobookSettings.setCustomPlayButtonStyle(s);
                },
                options: [
                  for (final s in AudiobookPlayButtonStyle.values)
                    SegmentedTabOption(value: s, label: s.label),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Customize Artwork Display ──
          Text(
            l10nCurrent().stgbArtworkDisplayStyle,
            style: ZplayType.label.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<AudiobookArtworkStyle>(
            valueListenable: AudiobookSettings.customArtworkStyle,
            builder: (context, currentStyle, _) {
              return SegmentedTabs<AudiobookArtworkStyle>(
                selected: currentStyle,
                onSelected: (s) {
                  AudiobookSettings.setCustomArtworkStyle(s);
                },
                options: [
                  for (final s in AudiobookArtworkStyle.values)
                    SegmentedTabOption(value: s, label: s.label),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Hover & Touch Physics ──
          Text(
            l10nCurrent().stgbButtonHoverPhysics,
            style: ZplayType.label.toStyle(color: tokens.textEmphasis),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<AudiobookHoverEffect>(
            valueListenable: AudiobookSettings.customHoverEffect,
            builder: (context, currentEffect, _) {
              return SegmentedTabs<AudiobookHoverEffect>(
                selected: currentEffect,
                onSelected: (e) {
                  AudiobookSettings.setCustomHoverEffect(e);
                },
                options: [
                  for (final e in AudiobookHoverEffect.values)
                    SegmentedTabOption(value: e, label: e.label),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: tokens.borderDefault),
          const SizedBox(height: 16),

          // ── Drag & Drop Component Arranger ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10nCurrent().stgbPlayerLayoutComponents,
                style: ZplayType.label.toStyle(color: tokens.textPrimary),
              ),
              Icon(
                Icons.drag_indicator_rounded,
                color: palette.primaryColor,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10nCurrent().stgbPlayerLayoutComponentsDesc,
            style: ZplayType.bodySmall.toStyle(color: tokens.textSecondary),
          ),
          const SizedBox(height: 10),

          ValueListenableBuilder<List<String>>(
            valueListenable: AudiobookSettings.componentOrder,
            builder: (context, order, _) {
              return ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  final list = List<String>.from(order);
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = list.removeAt(oldIndex);
                  list.insert(newIndex, item);
                  AudiobookSettings.setComponentOrder(list);
                },
                children: order.map((key) {
                  final label = _getComponentLabel(key);
                  final icon = _getComponentIcon(key);
                  return Padding(
                    key: ValueKey(key),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        icon,
                        color: palette.primaryColor,
                        size: 18,
                      ),
                      title: Text(
                        label,
                        style: ZplayType.label.toStyle(
                          color: tokens.textPrimary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.drag_handle_rounded,
                        color: tokens.textMuted,
                        size: 18,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: tokens.borderDefault),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AudiobookPlayerStudioPage(),
                  ),
                );
              },
              icon: Icon(
                Icons.dashboard_customize_rounded,
                size: 18,
                color: tokens.onAccent,
              ),
              label: Text(
                l10nCurrent().stgbLaunchFullStudio,
                style: ZplayType.label.toStyle(color: tokens.onAccent),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primaryColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: ZplayRadius.smAll,
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPlayButtonWidget(
    AudiobookPlayButtonStyle style,
    AppThemePalette palette,
    bool isPlaying,
  ) {
    final tokens = context.tokens;
    final icon = isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded;
    final hoverEffect = AudiobookSettings.customHoverEffect.value;

    Widget buttonCore;
    BorderRadius borderRadius;

    if (style == AudiobookPlayButtonStyle.liquidGlassNeo) {
      borderRadius = ZplayRadius.mdAll;
      final glassStyle = LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: 18,
          clipQuality: LiquidGlassClipQuality.exact,
          borderWidth: 1.5,
          lightIntensity: 1.4,
          lightColor: Colors.white.withValues(alpha: ZplayOpacity.textPrimary),
          lightDirection: 115,
          borderType: const OpticalBorder(
            borderSaturation: 1.5,
            ambientIntensity: 1.15,
            borderSolidity: 0.18,
            lightSpread: 0.7,
          ),
        ),
        appearance: LiquidGlassAppearance(
          color: palette.primaryColor.withValues(alpha: 0.15),
          saturation: 1.2,
          blur: const LiquidGlassBlur(sigmaX: 3.0, sigmaY: 3.0),
          shadow: LiquidGlassShadow(
            blur: 14,
            opacity: 0.35,
            color: palette.primaryColor,
          ),
        ),
        refraction: const LiquidGlassRefraction(
          magnification: 1.035,
          chromaticAberration: 0.003,
          refractionType: OpticalRefraction(
            refraction: 1.54,
            refractionWidth: 20,
            depth: 0.75,
          ),
        ),
      );

      buttonCore = LiquidGlassLens(
        style: glassStyle,
        visibility: true,
        useImpellerBackdrop: true,
        child: Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          child: Icon(icon, color: tokens.onAccent, size: 30),
        ),
      );
    } else if (style == AudiobookPlayButtonStyle.roundedSquare) {
      borderRadius = ZplayRadius.mdAll;
      buttonCore = Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: palette.primaryColor,
          borderRadius: borderRadius,
        ),
        child: Icon(icon, color: tokens.onAccent, size: 28),
      );
    } else if (style == AudiobookPlayButtonStyle.accentPill) {
      borderRadius = ZplayRadius.lgAll;
      buttonCore = Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: palette.primaryColor,
          borderRadius: borderRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: tokens.onAccent, size: 22),
            const SizedBox(width: 6),
            Text(
              isPlaying
                  ? l10nCurrent().stgbPauseCaps
                  : l10nCurrent().stgbPlayCaps,
              style: ZplayType.label.toStyle(color: tokens.onAccent),
            ),
          ],
        ),
      );
    } else {
      borderRadius = ZplayRadius.xlAll;
      buttonCore = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.primaryColor,
        ),
        child: Icon(icon, color: tokens.onAccent, size: 32),
      );
    }

    return AudiobookInteractivePhysicsButton(
      effect: hoverEffect,
      glowColor: palette.primaryColor,
      borderRadius: borderRadius,
      child: buttonCore,
    );
  }

  String _getComponentLabel(String key) {
    switch (key) {
      case 'artwork':
        return l10nCurrent().stgbAudiobookCoverDeck;
      case 'title':
        return l10nCurrent().stgbTitleAuthorChapter;
      case 'seekbar':
        return l10nCurrent().stgbSeekBarWaveformScrubber;
      case 'mainControls':
        return l10nCurrent().stgbMainControlsCluster;
      case 'secondaryControls':
        return l10nCurrent().stgbSpeedVolumeControls;
      case 'chaptersButton':
        return l10nCurrent().stgbPremadeChaptersTrigger;
      default:
        return key;
    }
  }

  IconData _getComponentIcon(String key) {
    switch (key) {
      case 'artwork':
        return Icons.image_rounded;
      case 'title':
        return Icons.title_rounded;
      case 'seekbar':
        return Icons.graphic_eq_rounded;
      case 'mainControls':
        return Icons.play_circle_filled_rounded;
      case 'secondaryControls':
        return Icons.speed_rounded;
      case 'chaptersButton':
        return Icons.format_list_bulleted_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }
}
