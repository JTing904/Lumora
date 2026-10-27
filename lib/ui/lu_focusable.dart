import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/layout/form_factor.dart';
import 'lu_theme.dart';

/// Hover and focus, the way every Lumora control shows them: a lift to 1.05,
/// a gold outline and a soft glow, in 180 ms. A remote's Select or Enter, a
/// click and a tap all activate it.
///
/// [builder] gets whether the control is highlighted (hovered or focused)
/// so it can change its own fill too; the outline and lift are drawn here.
class LuFocusable extends StatefulWidget {
  const LuFocusable({
    super.key,
    required this.builder,
    this.onTap,
    this.borderRadius = LuRadius.pill,
    this.focusNode,
    this.autofocus = false,
    this.lift = 1.05,
    this.semanticLabel,
    this.button = true,
    this.revealOnFocus = true,
    this.onLongPress,
  });

  final Widget Function(BuildContext context, bool highlighted) builder;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final FocusNode? focusNode;
  final bool autofocus;

  /// How far the control grows when highlighted; 1 for none.
  final double lift;
  final String? semanticLabel;
  final bool button;

  /// Scroll the control into view when it takes focus.
  final bool revealOnFocus;

  /// The control's second action (a menu, Remove...), for every input: a
  /// long press of touch or the mouse, a right click, the remote's or
  /// keyboard's menu key, and Select or Enter held for half a second. With
  /// it set, a key press activates on release rather than on press, so a
  /// held key can be told from a tap.
  final VoidCallback? onLongPress;

  /// How long Select or Enter is held for [onLongPress].
  static const Duration longPressKeyHold = Duration(milliseconds: 500);

  @override
  State<LuFocusable> createState() => _LuFocusableState();
}

class _LuFocusableState extends State<LuFocusable> {
  bool _hovered = false;
  bool _highlight = false;
  bool _hasFocus = false;

  /// Focus as the viewer sees it: the framework's keyboard highlight, or -
  /// on a device driven by a remote, which has no other way to point - plain
  /// focus, so the ring is there from the first frame a page claims it.
  bool get _focused =>
      _highlight || (_hasFocus && FormFactorService.hasRemoteInput);

  void _reveal() {
    if (!widget.revealOnFocus) return;
    // A remote moving through rows: bring the focused item into view, in both
    // its row and the page.
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: LuMotion.page,
      curve: LuMotion.ease,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  bool get _enabled => widget.onTap != null;

  /// When Select or Enter went down on this control, while [onLongPress]
  /// decides between a press and a hold at release.
  DateTime? _keyDownAt;

  void _activate() {
    if (_enabled) widget.onTap!();
  }

  void _longPress() {
    if (_enabled) widget.onLongPress?.call();
  }

  static final Set<LogicalKeyboardKey> _activateKeys = {
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.gameButtonA,
  };

  /// The menu key opens [onLongPress]; with it set, Select and Enter tap on
  /// a short press and open it on a held one, decided at release so a held
  /// key's repeats never reach whatever the long press opens.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onLongPress == null || !_enabled) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.contextMenu) {
      if (event is KeyDownEvent) _longPress();
      return KeyEventResult.handled;
    }
    if (!_activateKeys.contains(key)) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      _keyDownAt = DateTime.now();
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) {
      return _keyDownAt == null
          ? KeyEventResult.ignored
          : KeyEventResult.handled;
    }
    // KeyUpEvent.
    final downAt = _keyDownAt;
    _keyDownAt = null;
    if (downAt == null) return KeyEventResult.ignored;
    if (DateTime.now().difference(downAt) >= LuFocusable.longPressKeyHold) {
      _longPress();
    } else {
      _activate();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = _enabled && (_hovered || _focused);
    final hasLongPress = _enabled && widget.onLongPress != null;
    return Semantics(
      button: widget.button,
      enabled: _enabled,
      label: widget.semanticLabel,
      onLongPress: hasLongPress ? _longPress : null,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: FocusableActionDetector(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: _enabled,
          mouseCursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowHoverHighlight: (v) => setState(() => _hovered = v),
          onShowFocusHighlight: (v) {
            setState(() => _highlight = v);
            if (v) _reveal();
          },
          onFocusChange: (v) {
            final wasShown = _focused;
            setState(() => _hasFocus = v);
            if (v && !wasShown && _focused) _reveal();
          },
          // With a long press the activate keys are read by [_onKey] instead,
          // which tells a press from a hold.
          shortcuts: hasLongPress ? const {} : _activateShortcuts,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _enabled ? _activate : null,
            onLongPress: hasLongPress ? _longPress : null,
            onSecondaryTap: hasLongPress ? _longPress : null,
            child: AnimatedScale(
              scale: highlighted ? widget.lift : 1,
              duration: LuMotion.focus,
              curve: LuMotion.ease,
              child: LuFocusRing(
                focused: _focused && _enabled,
                borderRadius: widget.borderRadius,
                child: widget.builder(context, highlighted),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const Map<ShortcutActivator, Intent> _activateShortcuts = {
    SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  };
}

/// The gold outline and glow around a focused control: the one thing a
/// television viewer reads focus from. Public so a test can ask whether it is
/// drawn.
class LuFocusRing extends StatelessWidget {
  const LuFocusRing({
    super.key,
    required this.focused,
    required this.borderRadius,
    required this.child,
  });

  final bool focused;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: LuMotion.focus,
      curve: LuMotion.ease,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: focused ? LuColors.gold : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          if (focused)
            const BoxShadow(
              color: Color(0x66F2B544),
              blurRadius: 24,
              spreadRadius: 1,
            ),
        ],
      ),
      child: child,
    );
  }
}
