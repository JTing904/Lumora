import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_theme.dart';

/// What each version brought, in both languages, newest first. Shown once,
/// on the first start after updating to that version.
const Map<String, List<(String, String)>> releaseHighlights = {
  '1.0.1': [
    (
      'A new look for Manga, Books, Audiobooks, Music, Live TV, the player menus and every settings page.',
      '漫画、书籍、有声书、音乐、直播、播放器菜单和所有设定页都换上了新风格。',
    ),
    (
      'New-episode alerts: shows in My List get a "New episode" badge, Home has a New episodes row, and the airing calendar shows only your shows.',
      '新集提醒：收藏里的剧有新一集时会标上「有新集」，首页多了「新集上线」，追剧日历只显示你收藏的剧。',
    ),
    (
      'Your profile: a nickname, a profile photo or an avatar colour, under Me → Edit profile. They follow your account.',
      '个人资料：在「我的 → 编辑个人资料」设昵称、上传头像照片或选头像颜色，换设备也跟着走。',
    ),
    (
      'On Windows the app is now Lumora.exe. Your sign-in, history and settings came along automatically.',
      'Windows 版程序改名为 Lumora.exe，登录、观看记录和设定都已自动搬过来。',
    ),
    ('Plenty of bug fixes.', '修复了多个问题。'),
  ],
};

abstract final class WhatsNew {
  static const _key = 'lumora_last_seen_version';

  /// Whether this install had saved anything before this start: set in
  /// `main()` before any service writes. 1.0.0 saved no version, so an
  /// update from it is told apart from a fresh install this way.
  static bool hadPrefs = true;

  /// After an update, once: the new version's highlights. A fresh install
  /// only records its version, since everything is new to it.
  static Future<void> maybeShow(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version;
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getString(_key);
      await prefs.setString(_key, version);
      if (seen == version || (seen == null && !hadPrefs)) return;
      final notes = [
        for (final n in releaseHighlights[version] ?? const <(String, String)>[])
          // The Windows note only where there is a Windows program.
          if (Platform.isWindows || !n.$1.contains('Lumora.exe')) n,
      ];
      if (notes.isEmpty) return;
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => WhatsNewDialog(version: version, notes: notes),
      );
    } catch (e) {
      debugPrint('[WhatsNew] $e');
    }
  }
}

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key, required this.version, required this.notes});

  final String version;
  final List<(String, String)> notes;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return Theme(
      data: luTheme(),
      child: Dialog(
        backgroundColor: LuColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: LuRadius.card),
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: LuColors.gold,
                  size: 32,
                ),
                const SizedBox(height: LuSpace.m),
                Text(l10n.whatsNewTitle(version), style: LuText.title),
                const SizedBox(height: LuSpace.m),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (en, cn) in notes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 3, right: 10),
                                  child: Text(
                                    '✦',
                                    style: TextStyle(
                                      color: LuColors.gold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    zh ? cn : en,
                                    style: LuText.bodySoft.copyWith(
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: LuSpace.s),
                Align(
                  alignment: Alignment.centerRight,
                  child: LuButton(
                    label: l10n.whatsNewDone,
                    compact: true,
                    autofocus: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
