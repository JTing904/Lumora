import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'lu_button.dart';
import 'lu_theme.dart';

/// Asks before a destructive action - "Remove from My List?" - and answers
/// true when the viewer confirms.
///
/// The second action of a card (a long press, a right click, the menu key or
/// a held Select; see `LuFocusable.onLongPress`) opens this, so removing works
/// the same from touch, a mouse and a remote. Cancel takes focus first, so a
/// remote's next press cannot remove anything by accident.
Future<bool> showLuConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  IconData confirmIcon = Icons.delete_outline_rounded,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final l10n = l10nOf(ctx);
      return Theme(
        data: luTheme(),
        child: Dialog(
          backgroundColor: LuColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: LuText.heading),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: LuText.bodySoft,
                    ),
                  ],
                  const SizedBox(height: 22),
                  FocusTraversalGroup(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        LuButton(
                          label: l10n.commonCancel,
                          kind: LuButtonKind.secondary,
                          compact: true,
                          autofocus: true,
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                        LuButton(
                          label: confirmLabel,
                          icon: confirmIcon,
                          compact: true,
                          onPressed: () => Navigator.pop(ctx, true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  return confirmed == true;
}
