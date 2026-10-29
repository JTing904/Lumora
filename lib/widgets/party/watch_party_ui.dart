import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../services/party/watch_party_service.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';

/// The emoji a viewer can send with one tap.
const List<String> partyEmoji = ['😂', '❤️', '👍', '😮', '😢', '🔥', '👏'];

/// The room sheet from the player: start a room for [current], or, in one,
/// its code, who is in it, the host's control switch and leaving.
Future<void> showWatchPartySheet(
  BuildContext context, {
  required PartyMedia? Function() current,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Theme(
      data: luTheme(),
      child: Dialog(
        backgroundColor: LuColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: _PartySheet(current: current),
          ),
        ),
      ),
    ),
  );
}

class _PartySheet extends StatefulWidget {
  const _PartySheet({required this.current});

  final PartyMedia? Function() current;

  @override
  State<_PartySheet> createState() => _PartySheetState();
}

class _PartySheetState extends State<_PartySheet> {
  final _service = WatchPartyService.instance;
  bool _busy = false;
  String? _error;

  Future<void> _create() async {
    final media = widget.current();
    if (media == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.create(media);
    } catch (e) {
      _error = l10nCurrent().partyServiceDown;
      debugPrint('[WatchParty] create: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return ValueListenableBuilder<PartyRoom?>(
      valueListenable: _service.room,
      builder: (context, room, _) {
        if (room == null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.partyTitle, style: LuText.heading),
              const SizedBox(height: 8),
              Text(l10n.partyCreateBody, style: LuText.bodySoft),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: LuText.caption.copyWith(color: LuColors.danger),
                ),
              ],
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerRight,
                child: LuButton(
                  label: l10n.partyCreate,
                  icon: Icons.groups_rounded,
                  compact: true,
                  busy: _busy,
                  autofocus: true,
                  onPressed: widget.current() == null ? null : _create,
                ),
              ),
            ],
          );
        }
        return _RoomInfo(room: room);
      },
    );
  }
}

class _RoomInfo extends StatelessWidget {
  const _RoomInfo({required this.room});

  final PartyRoom room;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final service = WatchPartyService.instance;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.partyTitle, style: LuText.heading),
        const SizedBox(height: 16),
        Text(l10n.partyCode, style: LuText.caption),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                room.code,
                style: LuText.title.copyWith(
                  fontFamily: LuFonts.display,
                  letterSpacing: 6,
                  color: LuColors.gold,
                ),
              ),
            ),
            LuButton(
              label: l10n.partyCopy,
              icon: Icons.copy_rounded,
              kind: LuButtonKind.secondary,
              compact: true,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: room.code));
                ScaffoldMessenger.maybeOf(
                  context,
                )?.showSnackBar(SnackBar(content: Text(l10n.partyCopied)));
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(l10n.partyMembers('${room.members.length}'), style: LuText.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in room.members)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: LuColors.surfaceHigh,
                  borderRadius: LuRadius.pill,
                  border: Border.all(
                    color: m.host ? LuColors.gold : LuColors.line,
                  ),
                ),
                child: Text(
                  m.host ? '${m.name} · ${l10n.partyHost}' : m.name,
                  style: LuText.caption.copyWith(color: LuColors.textSoft),
                ),
              ),
          ],
        ),
        if (room.isHost) ...[
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: !room.guestsCanControl,
            activeThumbColor: LuColors.gold,
            title: Text(l10n.partyOnlyHostControls, style: LuText.body),
            onChanged: (v) => service.setGuestsCanControl(!v),
          ),
        ],
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: LuButton(
            label: room.isHost ? l10n.partyEnd : l10n.partyLeave,
            icon: Icons.logout_rounded,
            kind: LuButtonKind.secondary,
            compact: true,
            onPressed: () {
              service.leave();
              Navigator.of(context).maybePop();
            },
          ),
        ),
      ],
    );
  }
}

/// The room's chat, as a drawer on the right of the player.
class PartyChatPanel extends StatefulWidget {
  const PartyChatPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<PartyChatPanel> createState() => _PartyChatPanelState();
}

class _PartyChatPanelState extends State<PartyChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _service = WatchPartyService.instance;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _service.sendChat(text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final width = min(MediaQuery.sizeOf(context).width * 0.9, 380.0);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: const ColoredBox(color: Color(0x55000000)),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: width,
          // Nearly opaque: over the glass tint the transport bar behind
          // showed through the messages.
          child: Material(
            color: const Color(0xF2141418),
            child: SafeArea(
              left: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.partyChat, style: LuText.heading),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: LuColors.text,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ValueListenableBuilder<List<PartyChat>>(
                        valueListenable: _service.chat,
                        builder: (context, lines, _) {
                          if (lines.isEmpty) {
                            return Center(
                              child: Text(
                                l10n.partyChatEmpty,
                                style: LuText.bodySoft,
                              ),
                            );
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scroll.hasClients) {
                              _scroll.jumpTo(_scroll.position.maxScrollExtent);
                            }
                          });
                          return ListView.builder(
                            controller: _scroll,
                            itemCount: lines.length,
                            itemBuilder: (context, i) {
                              final line = lines[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${line.from}  ',
                                        style: LuText.caption.copyWith(
                                          color: LuColors.gold,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: line.text,
                                        style: LuText.body.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: [
                        for (final e in partyEmoji)
                          LuFocusable(
                            onTap: () => _service.sendReaction(e),
                            builder: (context, hi) => Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: hi
                                    ? const Color(0x1FFFFFFF)
                                    : Colors.transparent,
                                borderRadius: LuRadius.field,
                              ),
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            maxLength: 300,
                            style: LuText.body,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: l10n.partyChatHint,
                              counterText: '',
                              isDense: true,
                              filled: true,
                              fillColor: LuColors.field,
                              border: const OutlineInputBorder(
                                borderRadius: LuRadius.field,
                                borderSide: BorderSide(color: LuColors.line),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: l10n.partySend,
                          onPressed: _send,
                          icon: const Icon(
                            Icons.send_rounded,
                            color: LuColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Emoji that float up over the video, and the latest chat line from someone
/// else while the chat is closed. Pointer-transparent.
class PartyOverlay extends StatefulWidget {
  const PartyOverlay({super.key, required this.chatOpen});

  final bool chatOpen;

  @override
  State<PartyOverlay> createState() => _PartyOverlayState();
}

class _Floater {
  _Floater(this.emoji, this.x, this.key);
  final String emoji;
  final double x;
  final Key key;
}

class _PartyOverlayState extends State<PartyOverlay> {
  final _floaters = <_Floater>[];
  final _random = Random();
  StreamSubscription<String>? _reactSub;
  StreamSubscription<PartyChat>? _chatSub;
  PartyChat? _toast;
  Timer? _toastTimer;
  int _n = 0;

  @override
  void initState() {
    super.initState();
    final service = WatchPartyService.instance;
    _reactSub = service.reactions.listen((e) {
      if (!mounted) return;
      final f = _Floater(e, 0.55 + _random.nextDouble() * 0.35, ValueKey(_n++));
      setState(() => _floaters.add(f));
      Future<void>.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _floaters.remove(f));
      });
    });
    _chatSub = service.incomingChat.listen((line) {
      if (!mounted || widget.chatOpen) return;
      _toastTimer?.cancel();
      setState(() => _toast = line);
      _toastTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _toast = null);
      });
    });
  }

  @override
  void dispose() {
    _reactSub?.cancel();
    _chatSub?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            for (final f in _floaters)
              _FloatingEmoji(
                key: f.key,
                emoji: f.emoji,
                left: c.maxWidth * f.x,
                height: c.maxHeight,
              ),
            if (_toast != null && !widget.chatOpen)
              Positioned(
                left: 20,
                bottom: 120,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: c.maxWidth * 0.6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: LuColors.glass,
                      borderRadius: LuRadius.field,
                      border: Border.all(color: LuColors.glassEdge),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${_toast!.from}  ',
                            style: LuText.caption.copyWith(
                              color: LuColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: _toast!.text, style: LuText.body),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingEmoji extends StatelessWidget {
  const _FloatingEmoji({
    super.key,
    required this.emoji,
    required this.left,
    required this.height,
  });

  final String emoji;
  final double left;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2500),
      curve: Curves.easeOut,
      builder: (context, t, child) => Positioned(
        left: left,
        bottom: 90 + t * height * 0.55,
        child: Opacity(
          opacity: t < 0.75 ? 1 : (1 - t) * 4,
          child: Transform.scale(scale: 0.8 + t * 0.5, child: child),
        ),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 40)),
    );
  }
}
