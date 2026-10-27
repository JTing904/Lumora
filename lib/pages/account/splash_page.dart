import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../ui/figure_turntable.dart';
import '../../ui/lu_logo.dart';
import '../../ui/lu_theme.dart';

/// The splash: a figure turns in a pool of gold light while the mark and
/// the tagline come up, then [onDone].
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.onDone,
    this.duration = const Duration(milliseconds: 2200),
  });

  final VoidCallback onDone;
  final Duration duration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _done;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _done = Timer(widget.duration, widget.onDone);
  }

  @override
  void dispose() {
    _done?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final size = MediaQuery.sizeOf(context);
    final figureH = (size.height * 0.62).clamp(220.0, 600.0);
    final fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    return Scaffold(
      backgroundColor: LuColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 0.75,
                colors: [
                  Color(0x33FFD27A),
                  Color(0x0DF2B544),
                  Color(0x000A0A0C),
                ],
                stops: [0, 0.45, 0.7],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: figureH,
                child: const FigureTurntable(
                  figure: LuFigure.grey,
                  secondsPerTurn: 6,
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: fade,
                child: Column(
                  children: [
                    const LuLogo(size: 44),
                    const SizedBox(height: 10),
                    Text(
                      l10n.authTagline,
                      style: LuText.body.copyWith(
                        color: LuColors.textMuted,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 160,
                      child: AnimatedBuilder(
                        animation: _c,
                        builder: (context, _) => ClipRRect(
                          borderRadius: LuRadius.pill,
                          child: LinearProgressIndicator(
                            value: _c.value,
                            minHeight: 3,
                            color: LuColors.gold,
                            backgroundColor: const Color(0x1FFFFFFF),
                            semanticsLabel: l10n.splashLoading,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
