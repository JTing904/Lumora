import 'package:flutter/material.dart';

import '../services/settings/locale_settings.dart';
import 'lu_focusable.dart';
import 'lu_theme.dart';

/// EN | 中文 in one pill: switches the app language in a tap, without a trip
/// to the language page. "Follow the system" lives on that page.
class LuLanguageToggle extends StatelessWidget {
  const LuLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleSettings.locale,
      builder: (context, locale, _) {
        final current =
            (locale ?? Localizations.localeOf(context)).languageCode;
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: LuColors.field,
            borderRadius: LuRadius.pill,
            border: Border.all(color: LuColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Segment(
                label: 'EN',
                semantic: 'English',
                selected: current != 'zh',
                onTap: () => LocaleSettings.setLocale('en'),
              ),
              _Segment(
                label: '中文',
                semantic: '中文',
                selected: current == 'zh',
                onTap: () => LocaleSettings.setLocale('zh'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.semantic,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semantic;
  final bool selected;
  final VoidCallback onTap;

  static void _alreadyChosen() {}

  @override
  Widget build(BuildContext context) {
    // The chosen segment stays enabled (a press does nothing): a disabled
    // one gives up focus, and a remote that just picked it would be left
    // focused on nothing.
    return LuFocusable(
      onTap: selected ? _alreadyChosen : onTap,
      semanticLabel: semantic,
      lift: 1.0,
      builder: (context, highlighted) => AnimatedContainer(
        duration: LuMotion.focus,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? LuColors.gold
              : highlighted
              ? LuColors.surfaceHigh
              : Colors.transparent,
          borderRadius: LuRadius.pill,
        ),
        child: Text(
          label,
          style: LuText.label.copyWith(
            fontSize: 13,
            color: selected ? LuColors.onGold : LuColors.textMuted,
          ),
        ),
      ),
    );
  }
}
