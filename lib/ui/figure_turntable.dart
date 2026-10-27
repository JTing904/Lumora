import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The user's 3D figures, as rendered by tool/figure_turntable.py: 72 frames
/// a turn, frame 0 facing the viewer.
enum LuFigure {
  grey('grey', '灰色'),
  beige('beige', '米色'),
  plaid('plaid', '蓝色格子');

  const LuFigure(this.folder, this.label);

  final String folder;
  final String label;

  static const int frames = 72;

  String frame(int i) =>
      'assets/figures/$folder/${(i % frames).toString().padLeft(2, '0')}.webp';
}

/// A figure on its turntable: it turns slowly by itself, and a drag (mouse,
/// finger) or the left and right keys (a remote) turn it by hand. Letting
/// go, it carries on turning after a pause.
///
/// Pre-rendered rather than live 3D: the same 72 pictures run on every
/// platform, a television included, at a fraction of the source models' size.
class FigureTurntable extends StatefulWidget {
  const FigureTurntable({
    super.key,
    required this.figure,
    this.autoTurn = true,
    this.secondsPerTurn = 9,
    this.focusNode,
  });

  final LuFigure figure;
  final bool autoTurn;
  final double secondsPerTurn;
  final FocusNode? focusNode;

  @override
  State<FigureTurntable> createState() => _FigureTurntableState();
}

class _FigureTurntableState extends State<FigureTurntable> {
  /// The angle in frames; fractional while dragging.
  double _angle = 0;
  Timer? _ticker;
  Timer? _resume;
  bool _held = false;
  double _dragStart = 0;
  double _angleAtDragStart = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precache(widget.figure);
    _startTurning();
  }

  @override
  void didUpdateWidget(FigureTurntable old) {
    super.didUpdateWidget(old);
    if (old.figure != widget.figure) _precache(widget.figure);
    if (old.autoTurn != widget.autoTurn) _startTurning();
  }

  /// Every frame decoded up front, so the first turn does not stutter.
  void _precache(LuFigure figure) {
    for (var i = 0; i < LuFigure.frames; i++) {
      precacheImage(AssetImage(figure.frame(i)), context).catchError((_) {});
    }
  }

  void _startTurning() {
    _ticker?.cancel();
    _ticker = null;
    // Reduced motion: a still figure, turned only by hand.
    if (!widget.autoTurn || MediaQuery.disableAnimationsOf(context)) return;
    final step = Duration(
      milliseconds: (widget.secondsPerTurn * 1000 / LuFigure.frames).round(),
    );
    _ticker = Timer.periodic(step, (_) {
      if (!_held && mounted) setState(() => _angle += 1);
    });
  }

  void _hold() {
    _held = true;
    _resume?.cancel();
  }

  void _release() {
    _resume?.cancel();
    _resume = Timer(const Duration(milliseconds: 1600), () => _held = false);
  }

  void _turnBy(double frames) => setState(() => _angle += frames);

  @override
  void dispose() {
    _ticker?.cancel();
    _resume?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = _angle.round() % LuFigure.frames;
    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _hold();
          _turnBy(-3);
          _release();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _hold();
          _turnBy(3);
          _release();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            _hold();
            _dragStart = d.localPosition.dx;
            _angleAtDragStart = _angle;
          },
          onHorizontalDragUpdate: (d) {
            final width = math.max(context.size?.width ?? 300, 1.0);
            // A drag across the whole figure is half a turn.
            final frames = (d.localPosition.dx - _dragStart) / width * 36;
            setState(() => _angle = _angleAtDragStart - frames);
          },
          onHorizontalDragEnd: (_) => _release(),
          onHorizontalDragCancel: _release,
          child: Semantics(
            image: true,
            label: '3D 人偶（${widget.figure.label}），底座前有 Instagram 名牌 @jtinnnng',
            child: Image.asset(
              widget.figure.frame(index),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
