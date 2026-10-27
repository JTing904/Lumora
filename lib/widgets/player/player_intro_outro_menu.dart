import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/player/intro_outro_store.dart';
import '../../services/theme/design_tokens.dart';
import 'player_glass.dart';

/// 跳过片头片尾: mark where this show's opening ends and where its closing
/// starts, at the playhead, once for every episode.
class PlayerIntroOutroMenu extends StatelessWidget {
  const PlayerIntroOutroMenu({
    super.key,
    required this.marks,
    required this.position,
    required this.duration,
    required this.onChanged,
    required this.onClose,
  });

  final IntroOutro marks;
  final Duration position;
  final Duration duration;
  final ValueChanged<IntroOutro> onChanged;
  final VoidCallback onClose;

  static String clock(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final width = MediaQuery.sizeOf(context).width;
    return PlayerGlassCard(
      width: 340.0.clamp(260.0, width - 32),
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
                  l10n.introOutroTitle,
                  style: ZplayType.overline
                      .copyWith(size: 10.5, weight: FontWeight.w700)
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
          const SizedBox(height: ZplaySpacing.s8),
          ValueListenableBuilder<bool>(
            valueListenable: IntroOutroStore.autoSkip,
            builder: (context, auto, _) => _MarkRow(
              label: l10n.introOutroAuto,
              value: null,
              actions: [
                PlayerToggleChip(
                  active: auto,
                  label: auto ? l10n.introOutroOn : l10n.introOutroOff,
                  onClick: () => IntroOutroStore.setAutoSkip(!auto),
                ),
              ],
            ),
          ),
          _MarkRow(
            label: l10n.introOutroIntro,
            value: marks.introEnd == null ? null : clock(marks.introEnd!),
            actions: [
              PlayerToggleChip(
                active: false,
                label: l10n.introOutroSetHere,
                onClick: () => onChanged(
                  IntroOutro(
                    introEnd: position,
                    outroLength: marks.outroLength,
                  ),
                ),
              ),
              if (marks.introEnd != null)
                PlayerToggleChip(
                  active: false,
                  label: l10n.introOutroClear,
                  onClick: () =>
                      onChanged(IntroOutro(outroLength: marks.outroLength)),
                ),
            ],
          ),
          _MarkRow(
            label: l10n.introOutroOutro,
            value: marks.outroLength == null
                ? null
                : clock(duration - marks.outroLength!),
            actions: [
              PlayerToggleChip(
                active: false,
                label: l10n.introOutroSetHere,
                disabled: duration <= position || duration == Duration.zero,
                onClick: () => onChanged(
                  IntroOutro(
                    introEnd: marks.introEnd,
                    outroLength: duration - position,
                  ),
                ),
              ),
              if (marks.outroLength != null)
                PlayerToggleChip(
                  active: false,
                  label: l10n.introOutroClear,
                  onClick: () =>
                      onChanged(IntroOutro(introEnd: marks.introEnd)),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZplaySpacing.s8,
              ZplaySpacing.s8,
              ZplaySpacing.s8,
              ZplaySpacing.s4,
            ),
            child: Text(
              l10n.introOutroHint,
              style: ZplayType.caption.toStyle(color: PlayerTheme.inkSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkRow extends StatelessWidget {
  const _MarkRow({
    required this.label,
    required this.value,
    required this.actions,
  });

  final String label;
  final String? value;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ZplaySpacing.s8,
        vertical: ZplaySpacing.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (value != null)
                    TextSpan(
                      text: '  $value',
                      style: ZplayType.label.toStyle(
                        color: PlayerTheme.accent,
                        tabular: true,
                      ),
                    ),
                ],
              ),
              style: ZplayType.label
                  .copyWith(size: 13.5)
                  .toStyle(color: PlayerTheme.ink),
            ),
          ),
          for (final a in actions) ...[
            const SizedBox(width: ZplaySpacing.s4),
            a,
          ],
        ],
      ),
    );
  }
}

/// 下一集: the next episode's name and a countdown, with 立即播放 and 取消.
class PlayerUpNextCard extends StatelessWidget {
  const PlayerUpNextCard({
    super.key,
    required this.label,
    required this.secondsLeft,
    required this.onPlayNow,
    required this.onCancel,
  });

  final String label;
  final int secondsLeft;
  final VoidCallback onPlayNow;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return PlayerGlassCard(
      width: 300,
      padding: const EdgeInsets.all(ZplaySpacing.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.upNextIn(secondsLeft),
            style: ZplayType.caption.toStyle(color: PlayerTheme.inkSubtle),
          ),
          const SizedBox(height: ZplaySpacing.s4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ZplayType.subtitle.toStyle(color: PlayerTheme.ink),
          ),
          const SizedBox(height: ZplaySpacing.s12),
          Row(
            children: [
              PlayerToggleChip(
                active: true,
                label: l10n.upNextPlayNow,
                onClick: onPlayNow,
              ),
              const SizedBox(width: ZplaySpacing.s8),
              PlayerToggleChip(
                active: false,
                label: l10n.upNextCancel,
                onClick: onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
