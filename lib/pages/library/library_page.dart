import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/content/content_settings.dart';
import '../../services/download/download_service.dart';
import '../../services/layout/form_factor.dart';
import '../../services/my_list/my_list_service.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';
import '../downloads/downloads_page.dart';
import '../my_list/my_list_page.dart';

/// The two halves of 我的收藏.
enum LibraryTab { myList, downloads }

/// 我的收藏: the saved titles and the downloads, behind two tabs. Both pages
/// stay mounted so switching keeps each one's scroll and filters.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  LibraryTab _tab = LibraryTab.myList;

  static const _pages = <Widget>[MyListPage(), DownloadsPage()];

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final tv = FormFactorService.of(context) == FormFactor.television;
    final pad = width < 600 ? 16.0 : (tv ? 48.0 : LuSpace.page);

    return Theme(
      data: luTheme(),
      child: ColoredBox(
        color: LuColors.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                pad,
                MediaQuery.paddingOf(context).top + (tv ? 16 : 24),
                pad,
                8,
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n.navMyList,
                    style: LuText.title.copyWith(fontSize: 30),
                  ),
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      MyListService.items,
                      ContentSettings.adultEnabled,
                      DownloadService.instance.tasksNotifier,
                    ]),
                    builder: (context, _) => Wrap(
                      spacing: 8,
                      children: [
                        _TabPill(
                          label: l10n.navMyListShort,
                          count: MyListService.visibleItems.length,
                          selected: _tab == LibraryTab.myList,
                          onTap: () => setState(() => _tab = LibraryTab.myList),
                        ),
                        _TabPill(
                          label: l10n.navDownloads,
                          count: DownloadService
                              .instance
                              .tasksNotifier
                              .value
                              .length,
                          selected: _tab == LibraryTab.downloads,
                          onTap: () =>
                              setState(() => _tab = LibraryTab.downloads),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRect(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: IndexedStack(index: _tab.index, children: _pages),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 收藏 12 / 下载 3: white when selected, outlined otherwise.
class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: LuFocusable(
        onTap: onTap,
        builder: (context, hi) => AnimatedContainer(
          duration: LuMotion.focus,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: selected
                ? LuColors.text
                : (hi ? const Color(0x1FFFFFFF) : Colors.transparent),
            borderRadius: LuRadius.pill,
            border: selected ? null : Border.all(color: LuColors.line),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              count > 0 ? '$label $count' : label,
              style: LuText.body.copyWith(
                fontSize: 15,
                color: selected ? LuColors.bg : LuColors.textSoft,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
