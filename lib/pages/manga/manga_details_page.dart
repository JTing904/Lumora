import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/manga/manga.dart';
import '../../models/manga/manga_chapter.dart';
import '../../services/manga/manga_service.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';
import '../books/widgets/lu_reading_kit.dart';
import 'manga_reader_page.dart';
import 'widgets/manga_labels.dart';

/// One title: its cover over its own art, the facts and synopsis, 开始阅读 /
/// 继续阅读, then the chapters - searchable, fifty to a page.
class MangaDetailsPage extends StatefulWidget {
  final Manga manga;

  const MangaDetailsPage({super.key, required this.manga});

  @override
  State<MangaDetailsPage> createState() => _MangaDetailsPageState();
}

class _MangaDetailsPageState extends State<MangaDetailsPage> {
  final MangaService _mangaService = MangaService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Manga? _fullDetails;
  List<MangaChapter>? _chapters;
  Map<String, dynamic>? _historyEntry;
  bool _isLoading = true;

  // Chapter Pagination & Search
  String _chapterSearchQuery = '';
  int _currentChapterPage = 0;
  final int _chaptersPerPage = 50;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    final results = await Future.wait([
      _mangaService.getSeriesDetail(widget.manga.id),
      _mangaService.getChapters(widget.manga.id),
      _mangaService.getReadingHistory(),
    ]);

    final historyList = results[2] as List<Map<String, dynamic>>;
    Map<String, dynamic>? matchingHistory;
    try {
      matchingHistory = historyList.firstWhere(
        (h) => h['manga']['id'] == widget.manga.id,
      );
    } catch (_) {
      // No history found
    }

    if (mounted) {
      setState(() {
        _fullDetails = results[0] as Manga;
        _chapters = results[1] as List<MangaChapter>;
        _historyEntry = matchingHistory;
        _isLoading = false;
      });
    }
  }

  void _startReading(int chapterIndex, {int pageIndex = 0}) {
    if (_chapters == null || _chapters!.isEmpty) return;

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MangaReaderPage(
                  manga: _fullDetails ?? widget.manga,
                  chapters: _chapters!,
                  currentChapterIndex: chapterIndex,
                  resumePageIndex: pageIndex,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        )
        .then((_) {
          _loadDetails();
        });
  }

  List<MangaChapter> get _filteredChapters {
    if (_chapters == null) return [];
    if (_chapterSearchQuery.isEmpty) return _chapters!;

    final query = _chapterSearchQuery.toLowerCase();
    return _chapters!
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) ||
              c.number.toString().contains(query),
        )
        .toList();
  }

  List<MangaChapter> get _paginatedChapters {
    final filtered = _filteredChapters;
    final startIndex = _currentChapterPage * _chaptersPerPage;
    if (startIndex >= filtered.length) return [];

    final endIndex = (startIndex + _chaptersPerPage).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  static String _number(double n) =>
      n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 1);

  String _chapterTitle(MangaChapter chapter) {
    final l10n = l10nOf(context);
    if (chapter.name.isNotEmpty && chapter.name.toLowerCase() != 'last read') {
      return chapter.name;
    }
    return chapter.number > 0
        ? l10n.mg2ChapterNumber(_number(chapter.number))
        : l10n.mgChapter;
  }

  @override
  Widget build(BuildContext context) {
    final manga = _fullDetails ?? widget.manga;
    final coverUrl = manga.coverNormal.isNotEmpty
        ? manga.coverNormal
        : manga.coverSmall;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 720;
    final pad = luPagePad(context);
    final top = MediaQuery.paddingOf(context).top;

    return Theme(
      data: luTheme(),
      child: Scaffold(
        backgroundColor: LuColors.bg,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Positioned.fill(child: LuCoverBackdrop(url: coverUrl)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, top + 16, pad, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LuGlyphButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          label: l10nOf(context).mgBack,
                          iconSize: 18,
                          autofocus: true,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        SizedBox(height: wide ? 32 : 20),
                        wide
                            ? _wideHeader(manga, coverUrl)
                            : _narrowHeader(manga, coverUrl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (manga.synopsis.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10nOf(context).mg2Synopsis,
                          style: LuText.heading,
                        ),
                        const SizedBox(height: 10),
                        LuExpandableText(manga.synopsis),
                      ],
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(child: _chaptersHeader(pad, wide)),
            ..._chapterSlivers(pad),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56 + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(String url, double width) => ClipRRect(
    borderRadius: const BorderRadius.all(Radius.circular(14)),
    child: SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: LuImage(
          url: url,
          cacheWidth: (width * 3).round(),
          fallback: const Icon(
            Icons.menu_book_rounded,
            color: LuColors.textFaint,
            size: 40,
          ),
        ),
      ),
    ),
  );

  Widget _wideHeader(Manga manga, String coverUrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cover(coverUrl, 210),
        const SizedBox(width: 36),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _info(manga, phone: false),
          ),
        ),
      ],
    );
  }

  Widget _narrowHeader(Manga manga, String coverUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _cover(coverUrl, 160)),
        const SizedBox(height: 22),
        _info(manga, phone: true),
      ],
    );
  }

  /// Title, the facts line, the genres and the action.
  Widget _info(Manga manga, {required bool phone}) {
    final l10n = l10nOf(context);
    final type = mangaTypeLabel(l10n, manga.type);
    final facts = <String>[
      if (type != null) type,
      if (manga.author.isNotEmpty) manga.author,
      if (manga.year.isNotEmpty) manga.year,
    ];
    final tags = manga.tags.where(mangaTagShown).take(phone ? 5 : 6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          manga.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: LuText.hero.copyWith(
            fontSize: phone ? 28 : 44,
            shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 24)],
          ),
        ),
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < facts.length; i++) ...[
                if (i > 0)
                  const Text('·', style: TextStyle(color: LuColors.textFaint)),
                Text(facts[i], style: LuText.bodySoft),
              ],
            ],
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: LuRadius.pill,
                    color: const Color(0x14FFFFFF),
                    border: Border.all(color: LuColors.lineSoft),
                  ),
                  child: Text(
                    mangaGenreLabel(l10n, tag),
                    style: LuText.caption.copyWith(color: LuColors.textSoft),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (_isLoading)
          const SizedBox(
            height: 56,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox.square(
                dimension: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: LuColors.gold,
                ),
              ),
            ),
          )
        else
          _primaryAction(phone),
      ],
    );
  }

  Widget _primaryAction(bool phone) {
    final l10n = l10nOf(context);
    final history = _historyEntry;
    final chapters = _chapters;
    if (history != null) {
      final index = history['chapterIndex'] as int;
      final chNum = (chapters != null && index < chapters.length)
          ? chapters[index].number
          : '';
      return LuButton(
        label: l10n.mg2ResumeChapter(chNum.toString().isNotEmpty ? chNum : ''),
        icon: Icons.play_arrow_rounded,
        expand: phone,
        onPressed: () =>
            _startReading(index, pageIndex: history['pageIndex'] as int),
      );
    }
    if (chapters != null && chapters.isNotEmpty) {
      return LuButton(
        label: l10n.mgStartReading,
        icon: Icons.menu_book_rounded,
        expand: phone,
        onPressed: () => _startReading(chapters.length - 1),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _chaptersHeader(double pad, bool wide) {
    final l10n = l10nOf(context);
    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(l10n.mgChapters, style: LuText.heading),
        if (_chapters != null) ...[
          const SizedBox(width: 10),
          Text('${_chapters!.length}', style: LuText.caption),
        ],
      ],
    );
    final search = LuSearchBox(
      controller: _searchController,
      hint: l10n.mgSearchChapters,
      clearLabel: l10n.mgClearChapterSearch,
      height: 46,
      onChanged: (val) => setState(() {
        _chapterSearchQuery = val;
        _currentChapterPage = 0;
      }),
      onClear: () => setState(() {
        _chapterSearchQuery = '';
        _currentChapterPage = 0;
      }),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 36, pad, 14),
      child: wide
          ? Row(
              children: [
                Expanded(child: title),
                SizedBox(width: 300, child: search),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [title, const SizedBox(height: 12), search],
            ),
    );
  }

  List<Widget> _chapterSlivers(double pad) {
    final l10n = l10nOf(context);
    if (_isLoading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: LuColors.gold),
            ),
          ),
        ),
      ];
    }
    final page = _paginatedChapters;
    if (page.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                _chapterSearchQuery.isNotEmpty
                    ? l10n.mg2NoChaptersMatching(_chapterSearchQuery)
                    : l10n.mgNoChaptersFound,
                textAlign: TextAlign.center,
                style: LuText.bodySoft,
              ),
            ),
          ),
        ),
      ];
    }
    final totalPages = (_filteredChapters.length / _chaptersPerPage).ceil();
    final historyIndex = _historyEntry?['chapterIndex'] as int?;
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final chapter = page[index];
            final originalIndex = _chapters!.indexOf(chapter);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChapterRow(
                number: chapter.number > 0 ? _number(chapter.number) : '#',
                title: _chapterTitle(chapter),
                read: historyIndex != null && historyIndex < originalIndex,
                current: historyIndex == originalIndex,
                onTap: () => _startReading(originalIndex),
              ),
            );
          }, childCount: page.length),
        ),
      ),
      if (totalPages > 1)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LuGlyphButton(
                  icon: Icons.chevron_left_rounded,
                  label: l10n.mgPreviousChapterPage,
                  iconSize: 24,
                  onTap: _currentChapterPage > 0
                      ? () => setState(() => _currentChapterPage--)
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  l10n.mg2PageOfTotal(_currentChapterPage + 1, totalPages),
                  style: LuText.label,
                ),
                const SizedBox(width: 16),
                LuGlyphButton(
                  icon: Icons.chevron_right_rounded,
                  label: l10n.mgNextChapterPage,
                  iconSize: 24,
                  onTap: _currentChapterPage < totalPages - 1
                      ? () => setState(() => _currentChapterPage++)
                      : null,
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

/// One chapter: its number in a disc, its name, and a chevron. The chapter
/// being read is gold; the ones before it are quieter.
class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.number,
    required this.title,
    required this.read,
    required this.current,
    required this.onTap,
  });

  final String number;
  final String title;
  final bool read;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LuFocusable(
      onTap: onTap,
      lift: 1.01,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      semanticLabel: title,
      builder: (context, hi) => AnimatedContainer(
        duration: LuMotion.focus,
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          color: current
              ? const Color(0x1FF2B544)
              : (hi ? LuColors.surfaceHigh : LuColors.surface),
          border: Border.all(
            color: current ? const Color(0x66F2B544) : LuColors.lineSoft,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current ? LuColors.gold : const Color(0x14FFFFFF),
              ),
              child: Text(
                number,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: LuFonts.display,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ).copyWith(color: current ? LuColors.onGold : LuColors.text),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LuText.body.copyWith(
                  fontSize: 15,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  color: current
                      ? LuColors.gold
                      : (read ? LuColors.textFaint : LuColors.text),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              current ? Icons.play_arrow_rounded : Icons.chevron_right_rounded,
              color: current ? LuColors.gold : LuColors.textFaint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
