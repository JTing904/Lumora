import '../../../l10n/l10n.dart';
import 'package:flutter/material.dart';
import '../../../services/theme/app_theme_service.dart';
import '../../../services/theme/design_tokens.dart';
import '../../../services/music/music_settings.dart';
import '../../../widgets/common/animated_ambient_background.dart';
import '../../../widgets/music/music_waveform_seekbar.dart';
import '../../../widgets/settings/settings_app_bar.dart';
import '../../music/lu_media_kit.dart';
import 'music_player_studio_page.dart';

class MusicSettingsPage extends StatefulWidget {
  const MusicSettingsPage({super.key});

  @override
  State<MusicSettingsPage> createState() => _MusicSettingsPageState();
}

class _MusicSettingsPageState extends State<MusicSettingsPage> {
  final bool _previewIsPlaying = false;
  Duration _previewPos = const Duration(minutes: 1, seconds: 20);

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
          appBar: SettingsAppBar(title: l10nCurrent().stgcMusicUiAtmosphere),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZplaySpacing.s16,
                  vertical: ZplaySpacing.s20,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. Enter Music Player Studio Banner
                  _buildEnterPlayerStudioBanner(palette),
                  const SizedBox(height: 28),

                  // 3. Ambient Moving Background Lights
                  _buildSectionHeader(l10nCurrent().stgbAmbientAtmosphereGlow),
                  const SizedBox(height: 12),
                  _buildAmbientLightsCard(palette),
                  const SizedBox(height: 28),

                  // 4. Discovery & Layout Settings
                  _buildSectionHeader(l10nCurrent().stgbDiscoveryCatalogConfig),
                  const SizedBox(height: 12),
                  _buildDiscoveryConfigCard(palette),
                  const SizedBox(height: 28),

                  // 5. Fullscreen Player Presets
                  _buildSectionHeader(
                    l10nCurrent().stgbFullscreenPlayerPresets,
                  ),
                  const SizedBox(height: 12),
                  _buildFullscreenPlayerPresetSelector(palette),
                  const SizedBox(height: 28),

                  // 6. Custom Player Quick Customizer
                  _buildSectionHeader(
                    l10nCurrent().stgbCustomPlayerEngineDesigner,
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

  Widget _buildAmbientLightsCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: MusicSettings.enableAmbientLights,
            builder: (context, enabled, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbMovingBgAmbientLighting,
                  style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                ),
                subtitle: Text(
                  l10nCurrent().stgbMovingBgAmbientLightingDesc,
                  style: ZplayType.bodySmall.toStyle(
                    color: tokens.textSecondary,
                  ),
                ),
                value: enabled,
                onChanged: (val) => MusicSettings.setEnableAmbientLights(val),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryConfigCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: MusicSettings.enableSpotlight,
            builder: (context, enabled, _) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10nCurrent().stgbShowHeroShowcase,
                  style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
                ),
                subtitle: Text(
                  l10nCurrent().stgbMusicHeroDesc,
                  style: ZplayType.bodySmall.toStyle(
                    color: tokens.textSecondary,
                  ),
                ),
                value: enabled,
                onChanged: (val) => MusicSettings.setEnableSpotlight(val),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenPlayerPresetSelector(AppThemePalette palette) {
    final tokens = context.tokens;
    return ValueListenableBuilder<MusicFullscreenPreset>(
      valueListenable: MusicSettings.selectedFullscreenPreset,
      builder: (context, selectedPreset, _) {
        return Column(
          children: MusicFullscreenPreset.values.map((preset) {
            final isSelected = selectedPreset == preset;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? tokens.accentSubtle : null,
                borderRadius: ZplayRadius.mdAll,
                border: Border.all(
                  color: isSelected
                      ? palette.primaryColor
                      : tokens.borderDefault,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  onTap: () =>
                      MusicSettings.setSelectedFullscreenPreset(preset),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.primaryColor
                          : tokens.borderSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      preset == MusicFullscreenPreset.vinylStudio
                          ? Icons.album_rounded
                          : preset == MusicFullscreenPreset.cyberWaveform
                          ? Icons.graphic_eq_rounded
                          : preset == MusicFullscreenPreset.liquidGlassNeo
                          ? Icons.blur_on_rounded
                          : preset == MusicFullscreenPreset.cinematicArtwork
                          ? Icons.fullscreen_rounded
                          : Icons.dashboard_customize_rounded,
                      color: isSelected
                          ? tokens.textPrimary
                          : tokens.textEmphasis,
                      size: 20,
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
                    style: ZplayType.caption.toStyle(
                      color: tokens.textSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: palette.primaryColor,
                          size: 22,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEnterPlayerStudioBanner(AppThemePalette palette) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        borderRadius: ZplayRadius.lgAll,
        gradient: LinearGradient(
          colors: [palette.primaryColor.withValues(alpha: 0.3), tokens.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: palette.primaryColor.withValues(alpha: 0.45),
          width: 1.5,
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
                color: tokens.textPrimary,
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
                        l10nCurrent().stgbCustomMusicStudio,
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
                          color: palette.primaryColor.withValues(alpha: 0.25),
                          borderRadius: ZplayRadius.xsAll,
                        ),
                        child: Text(
                          l10nCurrent().stgbFullPlayerEngine,
                          style: ZplayType.overline.toStyle(
                            color: palette.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10nCurrent().stgbCustomizeFullscreenDesc,
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
                          builder: (_) => const MusicPlayerStudioPage(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: tokens.textPrimary,
                    ),
                    label: Text(
                      l10nCurrent().stgbEnterPlayerStudio,
                      style: ZplayType.label.toStyle(color: tokens.textPrimary),
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

  Widget _buildCustomPlayerStudioCard(AppThemePalette palette) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Customizer Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10nCurrent().stgbLiveWaveformPreview,
                style: ZplayType.label.toStyle(color: palette.primaryColor),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MusicPlayerStudioPage(),
                    ),
                  );
                },
                child: Text(
                  l10nCurrent().stgbOpenFullStudio,
                  style: ZplayType.label.toStyle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mini preview bar
          MusicWaveformSeekbar(
            position: _previewPos,
            duration: const Duration(minutes: 3, seconds: 30),
            isPlaying: _previewIsPlaying,
            style: MusicSettings.customSeekbarStyle.value,
            onSeek: (p) => setState(() => _previewPos = p),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MusicPlayerStudioPage(),
                ),
              );
            },
            icon: Icon(
              Icons.dashboard_customize_rounded,
              size: 18,
              color: tokens.textPrimary,
            ),
            label: Text(
              l10nCurrent().stgbLaunchFullStudio,
              style: ZplayType.label.toStyle(color: tokens.textPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primaryColor,
              shape: const RoundedRectangleBorder(
                borderRadius: ZplayRadius.smAll,
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    );
  }
}
