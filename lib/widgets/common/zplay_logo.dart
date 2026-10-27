import 'package:flutter/material.dart';

import '../../services/theme/design_tokens.dart';

/// The Lumora mark: a bold L cut by a diagonal into a lit face and a face in
/// shadow - Luminous + Aura, lit like a film frame.
///
/// Drawn rather than loaded, so it takes its colours from the theme like every
/// other surface. The class keeps its old name because several surfaces
/// already place it (the bar, Home, the player, Addons); only the drawing
/// changed. Below [solidBelow] the two faces are too small to tell apart, so
/// the mark falls back to a single-colour L, the same rule the launcher icons
/// follow at 16-20 px.
class ZplayLogo extends StatelessWidget {
  const ZplayLogo({super.key, this.size = 24});

  /// The width and height of the mark. The geometry is proportional, so there
  /// is one number to get right rather than a set.
  final double size;

  /// The size under which the split is dropped for a solid L.
  static const double solidBelow = 22;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LumoraMarkPainter(
          lit: size < solidBelow ? tokens.accent : tokens.accentHover,
          shadow: size < solidBelow
              ? null
              : Color.lerp(tokens.accent, Colors.black, 0.4)!,
        ),
      ),
    );
  }

  /// The L, as a path in the mark's own coordinates (a 100-unit box scaled to
  /// [size]). Public and static so a test can read the shape, and so the
  /// launcher icons can be generated from the same outline.
  static Path letterPath(Size size) {
    final u = size.shortestSide / 100;
    return Path()
      ..addRRect(RRect.fromLTRBR(26 * u, 18 * u, 44 * u, 80 * u, Radius.circular(3 * u)))
      ..addRRect(RRect.fromLTRBR(26 * u, 62 * u, 76 * u, 80 * u, Radius.circular(3 * u)));
  }

  /// The part of the box in shadow: everything past the diagonal x + y = 110.
  static Path shadowPath(Size size) {
    final u = size.shortestSide / 100;
    return Path()
      ..moveTo(110 * u, 0)
      ..lineTo(0, 110 * u)
      ..lineTo(110 * u, 110 * u)
      ..close();
  }
}

/// The mark followed by the "Lumora" wordmark, for the app's brand corner.
class LumoraWordmark extends StatelessWidget {
  const LumoraWordmark({super.key, this.size = 24});

  /// The mark's side; the wordmark is sized from it.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZplayLogo(size: size),
        SizedBox(width: size * 0.3),
        Text(
          'Lumora',
          maxLines: 1,
          style: ZplayType.titleLarge
              .copyWith(size: size * 0.85, letterSpacing: 0.4)
              .toStyle(color: context.tokens.textPrimary),
        ),
      ],
    );
  }
}

class _LumoraMarkPainter extends CustomPainter {
  const _LumoraMarkPainter({required this.lit, required this.shadow});

  final Color lit;

  /// Null draws the L in [lit] alone.
  final Color? shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final letter = ZplayLogo.letterPath(size);
    canvas.drawPath(letter, Paint()..color = lit);
    final shade = shadow;
    if (shade == null) return;
    canvas.save();
    canvas.clipPath(letter);
    canvas.drawPath(ZplayLogo.shadowPath(size), Paint()..color = shade);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LumoraMarkPainter oldDelegate) =>
      oldDelegate.lit != lit || oldDelegate.shadow != shadow;
}
