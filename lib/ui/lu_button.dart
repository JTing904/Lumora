import 'package:flutter/material.dart';

import '../services/layout/device_profile.dart';
import 'lu_focusable.dart';
import 'lu_theme.dart';

enum LuButtonKind {
  /// Solid gold: the one thing a screen is for.
  primary,

  /// Glass over a picture or the ground.
  secondary,

  /// Gold words, no fill: a link-like action inside a sentence.
  text,
}

/// Lumora's button: a pill, 56 tall (52 when [compact]) on a desktop or a
/// television, and phone-sized on a phone: 44 tall (40 when [compact]), the
/// height Android and iOS buttons have, so a hero or a details page does not
/// read as the ten-foot layout squeezed into a hand.
class LuButton extends StatelessWidget {
  const LuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = LuButtonKind.primary,
    this.icon,
    this.expand = false,
    this.compact = false,
    this.busy = false,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final LuButtonKind kind;
  final IconData? icon;
  final bool expand;
  final bool compact;

  /// Shows a spinner and takes no presses.
  final bool busy;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final phone =
        MediaQuery.sizeOf(context).shortestSide < 600 &&
        !DeviceProfile.isTelevision;
    final height = kind == LuButtonKind.text
        ? 44.0
        : phone
        ? (compact ? 40.0 : 44.0)
        : (compact ? 52.0 : 56.0);
    final fg = switch (kind) {
      LuButtonKind.primary => LuColors.onGold,
      LuButtonKind.secondary => LuColors.text,
      LuButtonKind.text => LuColors.gold,
    };
    return LuFocusable(
      onTap: enabled ? onPressed : null,
      focusNode: focusNode,
      autofocus: autofocus,
      lift: kind == LuButtonKind.text ? 1 : 1.04,
      semanticLabel: label,
      builder: (context, highlighted) {
        final fill = switch (kind) {
          LuButtonKind.primary =>
            highlighted ? LuColors.goldLight : LuColors.gold,
          LuButtonKind.secondary =>
            highlighted ? const Color(0x29FFFFFF) : const Color(0x1AFFFFFF),
          LuButtonKind.text => Colors.transparent,
        };
        final content = Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
              )
            else if (icon != null)
              Icon(icon, size: phone ? 18 : 20, color: fg),
            if (busy || icon != null) SizedBox(width: phone ? 8 : 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.button.copyWith(
                  color: fg,
                  fontSize: kind == LuButtonKind.text
                      ? 14
                      : phone
                      ? (compact ? 14 : 15)
                      : (compact ? 16 : 18),
                ),
              ),
            ),
          ],
        );
        return AnimatedOpacity(
          opacity: enabled || busy ? 1 : 0.45,
          duration: LuMotion.focus,
          child: AnimatedContainer(
            duration: LuMotion.focus,
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: kind == LuButtonKind.text ? 6 : (phone ? 20 : 28),
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: LuRadius.pill,
              border: kind == LuButtonKind.secondary
                  ? Border.all(color: const Color(0x47FFFFFF))
                  : null,
            ),
            child: content,
          ),
        );
      },
    );
  }
}
