import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../services/account/account_service.dart';
import '../../services/theme/design_tokens.dart';
import '../../widgets/common/pill_button.dart';

/// 邀请码管理, for the admin: make one-time codes to hand to friends, and see
/// which were used and by whom. The server refuses anyone else, whatever
/// this page shows.
class InviteCodesPage extends StatefulWidget {
  const InviteCodesPage({super.key, this.create, this.list});

  /// Stand-ins for [AccountService] in tests.
  final Future<List<String>> Function(int howMany, {String? note})? create;
  final Future<List<InviteCode>> Function()? list;

  @override
  State<InviteCodesPage> createState() => _InviteCodesPageState();
}

class _InviteCodesPageState extends State<InviteCodesPage> {
  final _note = TextEditingController();
  List<InviteCode>? _codes;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final codes = await (widget.list ?? AccountService.listInviteCodes)();
      if (mounted) setState(() => _codes = codes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _codes = const [];
          _error = l10nOf(context).invitesLoadFailed;
        });
      }
    }
  }

  Future<void> _create(int howMany) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final note = _note.text.trim();
      final made = await (widget.create ?? AccountService.createInviteCodes)(
        howMany,
        note: note.isEmpty ? null : note,
      );
      _note.clear();
      if (made.length == 1) await _copy(made.first);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = l10nOf(context).invitesCreateFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: formatInviteCode(code)));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(l10nOf(context).invitesCopied(formatInviteCode(code))),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final tokens = context.tokens;
    final codes = _codes;
    final unused = codes?.where((c) => !c.used).length ?? 0;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        title: Text(l10n.invitesTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ZplaySpacing.s24),
        children: [
          Text(
            l10n.invitesIntro,
            style: ZplayType.body.toStyle(color: tokens.textSecondary),
          ),
          const SizedBox(height: ZplaySpacing.s16),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              labelText: l10n.invitesNote,
              filled: true,
              fillColor: tokens.surface.withValues(alpha: 0.7),
              border: const OutlineInputBorder(borderRadius: ZplayRadius.mdAll),
            ),
          ),
          const SizedBox(height: ZplaySpacing.s12),
          Wrap(
            spacing: ZplaySpacing.s12,
            runSpacing: ZplaySpacing.s8,
            children: [
              PillButton(
                label: l10n.invitesGenerate(1),
                icon: Icons.add_rounded,
                onPressed: _busy ? null : () => _create(1),
              ),
              PillButton(
                label: l10n.invitesGenerate(5),
                variant: PillVariant.secondary,
                onPressed: _busy ? null : () => _create(5),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: ZplaySpacing.s12),
            Text(_error!, style: ZplayType.body.toStyle(color: tokens.danger)),
          ],
          const SizedBox(height: ZplaySpacing.s24),
          if (codes == null)
            const Center(child: CircularProgressIndicator())
          else if (codes.isEmpty)
            Text(
              l10n.invitesEmpty,
              style: ZplayType.body.toStyle(color: tokens.textMuted),
            )
          else ...[
            Text(
              l10n.invitesCount(codes.length, unused),
              style: ZplayType.overline.toStyle(color: tokens.textMuted),
            ),
            const SizedBox(height: ZplaySpacing.s8),
            for (final c in codes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  formatInviteCode(c.code),
                  style: ZplayType.subtitle.toStyle(
                    color: c.used ? tokens.textMuted : tokens.textPrimary,
                    tabular: true,
                  ),
                ),
                subtitle: Text(
                  [
                    if (c.note != null && c.note!.isNotEmpty) c.note!,
                    c.used
                        ? l10n.invitesUsedBy(c.usedByEmail ?? '')
                        : l10n.invitesUnused,
                  ].join(' · '),
                  style: ZplayType.caption.toStyle(color: tokens.textSecondary),
                ),
                trailing: c.used
                    ? Icon(Icons.check_circle_rounded, color: tokens.textMuted)
                    : IconButton(
                        tooltip: l10n.invitesCopy,
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () => _copy(c.code),
                      ),
              ),
          ],
        ],
      ),
    );
  }
}
