import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/theme/design_tokens.dart';
import 'player_glass.dart';

/// One row of the 画质 menu: a quality and how many sources offer it.
class PlayerQualityOption {
  const PlayerQualityOption(this.quality, this.sourceCount);

  /// '4K', '1080p', '720p' or '480p'.
  final String quality;
  final int sourceCount;
}

/// The player's YouTube-style quality menu.
///
/// "自动" picks the best quality the measured connection carries; a quality
/// row switches to the best source of that quality from where the viewer is,
/// and is remembered as the highest the next 自动 pick may choose.
class PlayerQualityMenu extends StatelessWidget {
  const PlayerQualityMenu({
    super.key,
    required this.options,
    required this.currentQuality,
    required this.cap,
    required this.measuredMbps,
    required this.onSelected,
    required this.onClose,
  });

  final List<PlayerQualityOption> options;

  /// The playing source's quality, when it says.
  final String? currentQuality;

  /// The viewer's saved choice; null is 自动.
  final String? cap;

  /// What the connection was measured to carry, null before any playback.
  final double? measuredMbps;

  /// Called with a quality, or null for 自动.
  final ValueChanged<String?> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mbps = measuredMbps;

    Widget row({
      required String label,
      String? note,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return FocusableInkWell(
        borderRadius: ZplayRadius.smAll,
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: ZplaySpacing.s12),
          decoration: BoxDecoration(
            color: selected ? PlayerTheme.raised : Colors.transparent,
            borderRadius: ZplayRadius.smAll,
            border: Border.all(
              color: selected ? PlayerTheme.edge : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: ZplayType.label
                          .copyWith(
                            size: 14,
                            weight: selected ? FontWeight.w600 : FontWeight.w500,
                          )
                          .toStyle(
                            color: selected
                                ? PlayerTheme.ink
                                : PlayerTheme.inkMuted,
                          ),
                    ),
                    if (note != null)
                      Text(
                        note,
                        style: ZplayType.caption.toStyle(
                          color: PlayerTheme.inkSubtle,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 16, color: PlayerTheme.accent),
            ],
          ),
        ),
      );
    }

    return PlayerGlassCard(
      width: (300.0).clamp(240.0, screenWidth - 32),
      padding: const EdgeInsets.all(ZplaySpacing.s12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZplaySpacing.s8,
                  vertical: ZplaySpacing.s4,
                ),
                child: Text(
                  l10n.playerQuality,
                  style: ZplayType.overline
                      .copyWith(size: 11, weight: FontWeight.w700)
                      .toStyle(color: PlayerTheme.inkSubtle),
                ),
              ),
              PlayerIconButton(
                size: 28,
                iconSize: 14,
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.panelClose,
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 6),
          row(
            label: l10n.playerQualityAuto,
            note: mbps == null
                ? l10n.playerQualityAutoNote
                : l10n.playerQualityAutoMeasured(mbps.toStringAsFixed(1)),
            selected: cap == null,
            onTap: () {
              onSelected(null);
              onClose();
            },
          ),
          for (final option in options)
            row(
              label: option.quality,
              note: option.quality == currentQuality
                  ? l10n.playerQualityPlaying
                  : l10n.playerQualitySources(option.sourceCount),
              selected: cap == option.quality,
              onTap: () {
                onSelected(option.quality);
                onClose();
              },
            ),
        ],
      ),
    );
  }
}
