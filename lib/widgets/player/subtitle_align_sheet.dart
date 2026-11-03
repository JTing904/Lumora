import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/subtitles/subtitle_parser.dart';
import '../../ui/lu_theme.dart';

/// "现在画面里在说哪一句？": the viewer taps the line being spoken and the
/// subtitle moves to match. Quicker than nudging a delay a tenth of a second
/// at a time, and it works on both engines because it only needs the cues
/// and the position.
abstract final class SubtitleAlign {
  /// About [count] lines around what is on screen at [nowSec] with the
  /// current [delaySec], in time order.
  static List<SubCue> nearby(
    List<SubCue> cues,
    double nowSec,
    double delaySec, {
    int count = 5,
  }) {
    if (cues.isEmpty) return const [];
    final t = nowSec - delaySec;
    var closest = 0;
    var best = double.infinity;
    for (var i = 0; i < cues.length; i++) {
      final d = (cues[i].start - t).abs();
      if (d < best) {
        best = d;
        closest = i;
      }
    }
    final from = (closest - count ~/ 2).clamp(0, cues.length);
    final to = (from + count).clamp(0, cues.length);
    return cues.sublist((to - count).clamp(0, from), to);
  }

  /// The delay that starts [cue] at [nowSec]: the line just picked is being
  /// spoken now.
  static double delayFor(SubCue cue, double nowSec) =>
      ((nowSec - cue.start) * 10).round() / 10;
}

class SubtitleAlignSheet extends StatelessWidget {
  const SubtitleAlignSheet({
    super.key,
    required this.cues,
    required this.nowSec,
    required this.delaySec,
    required this.onPick,
    required this.onBack,
    required this.onClose,
  });

  final List<SubCue> cues;
  final double nowSec;
  final double delaySec;

  /// The new delay, in seconds.
  final ValueChanged<double> onPick;

  /// Go back a few seconds and listen again.
  final VoidCallback onBack;
  final VoidCallback onClose;

  static String _clock(double sec) {
    final s = sec.clamp(0, double.infinity).floor();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final r = (s % 60).toString().padLeft(2, '0');
    return h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:$r'
        : '${m.toString().padLeft(2, '0')}:$r';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final lines = SubtitleAlign.nearby(cues, nowSec, delaySec);
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Material(
            color: const Color(0xF0141418),
            borderRadius: LuRadius.card,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.subAlignTitle, style: LuText.heading),
                  const SizedBox(height: 6),
                  Text(
                    l10n.subAlignBody(_clock(nowSec)),
                    style: LuText.bodySoft,
                  ),
                  const SizedBox(height: 16),
                  for (final cue in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _LineButton(
                        time: _clock(cue.start + delaySec),
                        text: cue.text.replaceAll('\n', ' '),
                        autofocus: identical(cue, lines[lines.length ~/ 2]),
                        onTap: () =>
                            onPick(SubtitleAlign.delayFor(cue, nowSec)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: onBack,
                        child: Text(l10n.subAlignBack),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onClose,
                        child: Text(l10n.commonCancel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineButton extends StatelessWidget {
  const _LineButton({
    required this.time,
    required this.text,
    required this.onTap,
    this.autofocus = false,
  });

  final String time;
  final String text;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        autofocus: autofocus,
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(width: 64, child: Text(time, style: LuText.caption)),
              Expanded(child: Text(text, style: LuText.body)),
            ],
          ),
        ),
      ),
    );
  }
}
