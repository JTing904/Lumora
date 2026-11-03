import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Esc and the mouse's back button close the page [child] is on, as they do
/// in any desktop app.
///
/// Heard from the keyboard itself rather than through focus: a page pushed
/// over the shell often has nothing focused while it loads, and a key
/// handler on the focus path then never sees the key. Only while the page's
/// route is the one in front, so a dialog or the player opened over it keeps
/// Esc for itself. Android's own back is not handled here; it already pops
/// the route.
///
/// Without a [child] it is an empty layer to lay over a page in a `Stack`:
/// it hears the mouse there and lets every pointer through to the page.
class PageBackKeys extends StatefulWidget {
  const PageBackKeys({super.key, this.child});

  final Widget? child;

  @override
  State<PageBackKeys> createState() => _PageBackKeysState();
}

class _PageBackKeysState extends State<PageBackKeys> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool get _inFront => mounted && (ModalRoute.isCurrentOf(context) ?? false);

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        !_inFront) {
      return false;
    }
    Navigator.maybePop(context);
    return true;
  }

  @override
  Widget build(BuildContext context) => Listener(
    // Translucent, so the press still reaches whatever is under it.
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) {
      if (event.buttons & kBackMouseButton != 0 && _inFront) {
        Navigator.maybePop(context);
      }
    },
    child: widget.child ?? const SizedBox.expand(),
  );
}
