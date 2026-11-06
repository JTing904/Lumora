import 'package:flutter/material.dart';

import '../../services/subtitles/subtitle_parser.dart';

/// The subtitle line on screen at [seconds] of the video, with the viewer's
/// [delaySec] applied (positive shows lines later). Null between lines.
///
/// [ratio] stretches the subtitle's own clock (a line at `t` shows at
/// `t * ratio + delaySec`), for a subtitle cut for another frame rate.
String? activeCueText(
  List<SubCue> cues,
  double seconds, {
  double delaySec = 0,
  double ratio = 1,
}) {
  final t = (seconds - delaySec) / ratio;
  var lo = 0;
  var hi = cues.length - 1;
  // The last cue starting at or before t; cues are in time order.
  var found = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (cues[mid].start <= t) {
      found = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  if (found < 0) return null;
  // Overlapping cues: show every one still on screen, earliest first.
  final lines = <String>[];
  for (var i = found; i >= 0 && i > found - 4; i--) {
    final c = cues[i];
    if (c.start <= t && t < c.end) lines.insert(0, c.text);
  }
  return lines.isEmpty ? null : lines.join('\n');
}

/// Draws a downloaded subtitle over the video.
///
/// The phone's Media3 engine cannot load a subtitle file, so on it the app
/// draws the lines itself from the parsed cues. That is also what lets the
/// viewer's timing apply there.
class SubtitleCueOverlay extends StatelessWidget {
  const SubtitleCueOverlay({
    super.key,
    required this.cues,
    required this.seconds,
    required this.delaySec,
    this.ratio = 1.0,
    this.scale = 1.0,
    this.raised = false,
  });

  final List<SubCue> cues;
  final double seconds;
  final double delaySec;

  /// The subtitle's clock against the video's; see [activeCueText].
  final double ratio;
  final double scale;

  /// The controls are up: sit above them.
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final text = activeCueText(cues, seconds, delaySec: delaySec, ratio: ratio);
    if (text == null) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final base = width < 680 ? 17.0 : 26.0;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, raised ? 120 : 36),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: base * scale,
            fontWeight: FontWeight.w500,
            height: 1.3,
            shadows: const [
              Shadow(blurRadius: 4, color: Colors.black),
              Shadow(blurRadius: 1, color: Colors.black, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}
