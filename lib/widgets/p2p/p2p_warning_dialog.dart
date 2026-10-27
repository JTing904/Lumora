import '../../l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/layout/form_factor.dart';
import '../../services/p2p/p2p_settings_service.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_theme.dart';
import '../common/whole_line_viewport.dart';

class P2pWarningDialog extends StatefulWidget {
  const P2pWarningDialog({super.key});

  @override
  State<P2pWarningDialog> createState() => _P2pWarningDialogState();
}

class _P2pWarningDialogState extends State<P2pWarningDialog> {
  /// Holds focus inside the dialog so a remote cannot escape to the chrome
  /// behind it.
  ///
  /// The Material buttons in here were already focus nodes, but the dialog had
  /// no scope of its own, so directional traversal walked straight past them
  /// and out to the shell rail. Verified on a Chromecast with Google TV: with
  /// the dialog up, two `DPAD_DOWN` presses left the focus ring on the rail's
  /// Home icon *behind* the dialog, and the only thing on screen that changed
  /// was the hero carousel rotating. A modal a remote cannot operate is a modal
  /// the user has to dismiss by other means or sit and look at.
  ///
  /// [FocusScope] with a `node` traps traversal between its descendants - down
  /// from the last button cycles to the first rather than leaving - and the
  /// autofocus puts the user on the first action instead of wherever the shell
  /// happened to leave focus. `descendantsAreFocusable` is not used: this
  /// dialog's content is static text, and the buttons are the whole point.
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'P2pDialogScope');

  /// Makes the body reachable from a remote.
  ///
  /// The dialog's only focusable widgets are its three buttons, so arrow keys
  /// went to them and the scroll view was skipped entirely: on a television the
  /// engine comparison stayed sliced off behind the action bar, and the one
  /// thing the dialog exists to explain was the part you could not see. A
  /// focusable scroll view takes the arrows and scrolls; a visible thumb then
  /// shows there is more, which matters because a remote has no cursor to hint
  /// that anything is draggable.
  final FocusNode _bodyFocus = FocusNode(debugLabel: 'P2pDialogBody');
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scope.dispose();
    _bodyFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Lets the body take the D-pad and scroll itself.
  ///
  /// Without this the body takes focus and then eats the arrows without
  /// scrolling, which is worse than not taking focus at all - the focus ring
  /// lands on text and pressing UP appears to do nothing.
  ///
  /// At either end the key is handed on rather than swallowed, so the user can
  /// carry on down to the buttons instead of being trapped on the last line.
  KeyEventResult _onBodyKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final ScrollPosition position = _scrollController.position;
    const double delta = 60;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (position.pixels >= position.maxScrollExtent) {
        return KeyEventResult.ignored;
      }
      _scrollController.jumpTo(
        (position.pixels + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (position.pixels <= position.minScrollExtent) {
        return KeyEventResult.ignored;
      }
      _scrollController.jumpTo(
        (position.pixels - delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _turnOff() async {
    await P2pSettingsService.setP2pEnabled(false);
    await P2pSettingsService.setNeverShowWarning(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10nOf(context).p2pTurnedOff),
        backgroundColor: LuColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _dontShowAgain() async {
    await P2pSettingsService.setNeverShowWarning(true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 500;
    final television = FormFactorService.of(context) == FormFactor.television;

    return Theme(
      data: luTheme(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: FocusScope(
          node: _scope,
          // The first action, not the close button: this dialog exists to
          // make a decision, and the decision is in the actions.
          autofocus: true,
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: size.height * 0.90,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: LuColors.surface,
                    borderRadius: LuRadius.card,
                    border: Border.all(color: LuColors.glassEdge),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x8C000000),
                        blurRadius: 60,
                        offset: Offset(0, 24),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: LuRadius.card,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 24, 12, 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.p2pAdvisory.toUpperCase(),
                                      style: LuText.caption.copyWith(
                                        color: LuColors.gold,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: LuSpace.xs),
                                    Text(l10n.p2pTitle, style: LuText.heading),
                                  ],
                                ),
                              ),
                              // A pointer's way out; a remote has Exit below.
                              ExcludeFocus(
                                excluding: television,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: LuColors.textFaint,
                                  ),
                                  tooltip: l10n.p2pExit,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Scrollable body
                        Flexible(
                          child: WholeLineViewport(
                            child: Scrollbar(
                              // A pointer can drag this; a remote reaches it
                              // through the focusable body (see [_bodyFocus]).
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: Focus(
                                focusNode: _bodyFocus,
                                canRequestFocus: true,
                                skipTraversal: false,
                                onKeyEvent: _onBodyKey,
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    28,
                                    LuSpace.m,
                                    28,
                                    LuSpace.m,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // The question leads, not the legal
                                      // text: on a television the paragraph
                                      // used to push it under the buttons.
                                      Text(
                                        l10n.p2pQuestion,
                                        style: LuText.body.copyWith(
                                          color: LuColors.text,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: LuSpace.m),
                                      Text(
                                        l10n.p2pBody,
                                        style: LuText.bodySoft.copyWith(
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: LuSpace.m),
                                      _choice(
                                        Icons.cloud_done_rounded,
                                        l10n.p2pDirectTitle,
                                        l10n.p2pDirectBody,
                                      ),
                                      const SizedBox(height: LuSpace.s),
                                      _choice(
                                        Icons.hub_rounded,
                                        l10n.p2pTorrentTitle,
                                        l10n.p2pTorrentBody,
                                      ),
                                      const SizedBox(height: LuSpace.m),
                                      Text(
                                        l10n.p2pNote,
                                        style: LuText.caption.copyWith(
                                          color: LuColors.textFaint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 3. Actions
                        Container(
                          padding: const EdgeInsets.fromLTRB(28, 14, 28, 22),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: LuColors.lineSoft),
                            ),
                          ),
                          child: narrow
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    LuButton(
                                      label: l10n.p2pTurnOff,
                                      icon: Icons.check_circle_outline_rounded,
                                      expand: true,
                                      compact: true,
                                      onPressed: _turnOff,
                                    ),
                                    const SizedBox(height: LuSpace.s),
                                    LuButton(
                                      label: l10n.p2pDontShowAgain,
                                      kind: LuButtonKind.secondary,
                                      expand: true,
                                      compact: true,
                                      onPressed: _dontShowAgain,
                                    ),
                                    LuButton(
                                      label: l10n.p2pExit,
                                      kind: LuButtonKind.text,
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ],
                                )
                              // Wraps rather than overflows where the labels
                              // run long (English, a 960 dp television).
                              : Wrap(
                                  alignment: WrapAlignment.end,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: LuSpace.s,
                                  runSpacing: LuSpace.s,
                                  children: [
                                    LuButton(
                                      label: l10n.p2pExit,
                                      kind: LuButtonKind.text,
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                    LuButton(
                                      label: l10n.p2pDontShowAgain,
                                      kind: LuButtonKind.secondary,
                                      compact: true,
                                      onPressed: _dontShowAgain,
                                    ),
                                    LuButton(
                                      label: l10n.p2pTurnOff,
                                      icon: Icons.check_circle_outline_rounded,
                                      compact: true,
                                      onPressed: _turnOff,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One of the two ways to play, side by side in the body.
  Widget _choice(IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(LuSpace.m),
      decoration: BoxDecoration(
        color: LuColors.field,
        borderRadius: LuRadius.field,
        border: Border.all(color: LuColors.lineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: LuColors.gold, size: 22),
          const SizedBox(width: LuSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LuText.label),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: LuText.caption.copyWith(color: LuColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
