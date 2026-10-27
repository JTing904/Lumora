import 'package:flutter/material.dart';

import 'lu_theme.dart';

/// The 明暗 L: an L cut by a diagonal into a lit face and a shadow face, as
/// side light falls in a film. Below 24 px it is a solid gold L, which reads
/// where the two faces would blur together.
class LuLogoMark extends StatelessWidget {
  const LuLogoMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(solid: size < 24),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.solid});

  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    final stem = RRect.fromRectAndRadius(
      Rect.fromLTWH(26 * k, 18 * k, 18 * k, 62 * k),
      Radius.circular(3 * k),
    );
    final foot = RRect.fromRectAndRadius(
      Rect.fromLTWH(26 * k, 62 * k, 50 * k, 18 * k),
      Radius.circular(3 * k),
    );
    final shape = Path()
      ..addRRect(stem)
      ..addRRect(foot);
    if (solid) {
      canvas.drawPath(shape, Paint()..color = LuColors.gold);
      return;
    }
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawRect(Offset.zero & size, Paint()..color = LuColors.goldLight);
    final shadow = Path()
      ..moveTo(110 * k, 0)
      ..lineTo(0, 110 * k)
      ..lineTo(100 * k, 110 * k)
      ..close();
    canvas.drawPath(shadow, Paint()..color = LuColors.goldShadow);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.solid != solid;
}

/// The mark and the wordmark side by side.
class LuLogo extends StatelessWidget {
  const LuLogo({super.key, this.size = 40});

  /// The mark's size; the word follows it.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Lumora',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LuLogoMark(size: size),
          SizedBox(width: size * 0.3),
          Text('Lumora', style: LuText.wordmark.copyWith(fontSize: size * 0.7)),
        ],
      ),
    );
  }
}
