import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/manga/manga.dart';
import '../../models/manga/manga_chapter.dart';
import '../../services/manga/manga_service.dart';
import '../../services/manga/manga_settings.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_theme.dart';
import '../../widgets/common/custom_scroll_track.dart';
import '../books/widgets/lu_reading_kit.dart';
import '../settings/appearance/manga_settings_page.dart';
import 'manga_details_page.dart';
import 'manga_reader_page.dart';
import 'widgets/manga_labels.dart';
import 'widgets/manga_reader_controls.dart';

/// 漫画: a search box, the reader's two quick settings, 继续阅读 and a poster
/// grid of the source's titles, filtered by genre pills.
class MangaPage extends StatefulWidget {
  const MangaPage({super.key});

  @override
  State<MangaPage> createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  // Static cache to preserve state across navigations
  static List<Manga>? _cachedMangaList;
  static List<Map<String, dynamic>>? _cachedReadingHistory;
  static int _cachedCurrentPage = 1;
  static String _cachedSearchQuery = '';
  static String _cachedSelectedGenre = 'All';
  static double _cachedScrollOffset = 0.0;

  final MangaService _mangaService = MangaService();
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  List<Manga> _mangaList = [];
  List<Map<String, dynamic>> _readingHistory = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  String _searchQuery = '';
  String _selectedGenre = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _cachedScrollOffset,
    );
    _searchController.text = _cachedSearchQuery;
    _selectedGenre = _cachedSelectedGenre;

    MangaSettings.changeNotifier.addListener(_onSettingsChanged);

    if (_cachedMangaList != null && _cachedReadingHistory != null) {
      _mangaList = _cachedMangaList!;
      _readingHistory = _cachedReadingHistory!;
      _currentPage = _cachedCurrentPage;
      _searchQuery = _cachedSearchQuery;
      _selectedGenre = _cachedSelectedGenre;
      // Refresh reading history in background silently
      _mangaService.getReadingHistory().then((history) {
        if (mounted) {
          setState(() {
            _readingHistory = history;
            _cachedReadingHistory = history;
          });
        }
      });
    } else {
      _isLoading = true;
      _loadInitialData();
    }

    MangaService.readingHistoryRevision.addListener(_loadHistory);
    _scrollController.addListener(_onScroll);
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    MangaSettings.changeNotifier.removeListener(_onSettingsChanged);
    MangaService.readingHistoryRevision.removeListener(_loadHistory);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _cachedScrollOffset = _scrollController.offset;
    }
    if (_isLoading || _isLoadingMore) return;

    // If we're within 800 pixels of the bottom, load more
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 800) {
      _loadMore();
    }
  }

  Future<void> _loadHistory() async {
    final history = await _mangaService.getReadingHistory();
    if (mounted) {
      setState(() {
        _readingHistory = history;
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _mangaList.clear();
    });

    final results = await Future.wait([
      _searchQuery.isEmpty
          ? _mangaService.getManga(
              page: _currentPage,
              tag: _selectedGenre == 'All' ? null : _selectedGenre,
            )
          : _mangaService.searchManga(_searchQuery, page: _currentPage),
      _mangaService.getReadingHistory(),
    ]);

    if (mounted) {
      setState(() {
        _mangaList = results[0] as List<Manga>;
        _readingHistory = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;

        _cachedMangaList = _mangaList;
        _cachedReadingHistory = _readingHistory;
        _cachedCurrentPage = _currentPage;
        _cachedSearchQuery = _searchQuery;
        _cachedSelectedGenre = _selectedGenre;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);

    _currentPage++;
    final newManga = _searchQuery.isEmpty
        ? await _mangaService.getManga(
            page: _currentPage,
            tag: _selectedGenre == 'All' ? null : _selectedGenre,
          )
        : await _mangaService.searchManga(_searchQuery, page: _currentPage);

    if (mounted) {
      setState(() {
        _mangaList.addAll(newManga);
        _isLoadingMore = false;

        _cachedMangaList = _mangaList;
        _cachedCurrentPage = _currentPage;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _loadInitialData();
  }

  void _onGenreSelected(String genre) {
    if (_selectedGenre == genre && _searchQuery.isEmpty) return;
    setState(() {
      _selectedGenre = genre;
      _cachedSelectedGenre = genre;
      _searchQuery = '';
      _searchController.clear();
      _cachedSearchQuery = '';
    });
    _loadInitialData();
  }

  void _openDetails(Manga manga) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => MangaDetailsPage(manga: manga)));
  }

  void _resumeReading(Map<String, dynamic> historyEntry) {
    final mangaJson = historyEntry['manga'];
    final manga = Manga.fromJson(mangaJson);
    final chapterIndex = historyEntry['chapterIndex'] as int;
    final pageIndex = historyEntry['pageIndex'] as int;
    final chaptersList = (historyEntry['chapters'] as List)
        .map((c) => MangaChapter.fromJson(c))
        .toList();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MangaReaderPage(
              manga: manga,
              chapters: chaptersList,
              currentChapterIndex: chapterIndex,
              resumePageIndex: pageIndex,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _onRemoveHistory(String mangaId) {
    _mangaService.removeHistory(mangaId).then((_) {
      _loadHistory();
    });
  }

  void _showMangaCustomizer(BuildContext context) {
    final l10n = l10nOf(context);
    showLuPanel<void>(
      context,
      title: l10n.mgCustomizeMangaSection,
      icon: Icons.tune_rounded,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LuSectionLabel(l10n.mgPosterCardDensity),
          const SizedBox(height: 10),
          ValueListenableBuilder<MangaCardDensity>(
            valueListenable: MangaSettings.cardDensity,
            builder: (context, density, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in MangaCardDensity.values)
                  LuChoicePill(
                    label: mangaDensityLabel(l10n, option),
                    selected: option == density,
                    onTap: () => MangaSettings.setCardDensity(option),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showContinueReading,
            builder: (context, show, _) => LuSwitchRow(
              label: l10n.mgShowContinueReadingSlider,
              value: show,
              onChanged: MangaSettings.setShowContinueReading,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showContentTypeBadge,
            builder: (context, show, _) => LuSwitchRow(
              label: l10n.mgShowContentTypeBadgeOnPosters,
              value: show,
              onChanged: MangaSettings.setShowContentTypeBadge,
            ),
          ),
          const SizedBox(height: 18),
          LuButton(
            label: l10n.mgMoreAppearanceReaderSettings,
            kind: LuButtonKind.secondary,
            icon: Icons.settings_rounded,
            compact: true,
            expand: true,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MangaSettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// A poster's width for the viewer's chosen density.
  double _posterWidth(double screenWidth) {
    final base = screenWidth < 600
        ? 116.0
        : (screenWidth < 1000 ? 150.0 : 168.0);
    return switch (MangaSettings.cardDensity.value) {
      MangaCardDensity.compact => base * 0.85,
      MangaCardDensity.standard => base,
      MangaCardDensity.spacious => base * 1.2,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 600;
    final pad = luPagePad(context);
    final posterW = _posterWidth(width);
    final showContinue = MangaSettings.showContinueReading.value;
    final showBadge = MangaSettings.showContentTypeBadge.value;
    final scaler = MediaQuery.textScalerOf(context);
    final showScrollTrack = MangaSettings.showScrollTrack.value;

    final heading = _searchQuery.isNotEmpty
        ? l10n.mgSearchResults
        : (_selectedGenre == 'All'
              ? l10n.mgDiscoverManga
              : l10n.mg2GenreManga(mangaGenreLabel(l10n, _selectedGenre)));

    return Theme(
      data: luTheme(),
      child: ColoredBox(
        color: LuColors.bg,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, pad, phone)),
                SliverToBoxAdapter(
                  child: MangaReaderControlBar(horizontalPadding: pad),
                ),

                // ── 继续阅读 ──
                if (showContinue &&
                    _readingHistory.isNotEmpty &&
                    _searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: LuRail(
                        title: l10n.mgContinueReading,
                        padding: pad,
                        height:
                            LuCoverContinueCard.heightFor(posterW, scaler) + 8,
                        itemCount: _readingHistory.length,
                        itemBuilder: (context, i) =>
                            _historyCard(_readingHistory[i], posterW),
                      ),
                    ),
                  ),

                // ── Discover / results, with the genre pills ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 32, pad, 0),
                    child: Text(
                      heading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuText.heading,
                    ),
                  ),
                ),
                if (_searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: LuPillRow(
                        padding: EdgeInsets.symmetric(horizontal: pad),
                        children: [
                          for (final genre in mangaBrowseGenres)
                            LuChoicePill(
                              label: mangaGenreLabel(l10n, genre),
                              selected: genre == _selectedGenre,
                              onTap: () => _onGenreSelected(genre),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),

                if (_isLoading && _mangaList.isEmpty)
                  LuPosterGridSkeleton(padding: pad, targetWidth: posterW)
                else if (_mangaList.isEmpty)
                  SliverToBoxAdapter(
                    child: LuEmptyState(
                      icon: Icons.search_off_rounded,
                      title: l10n.mgNoMangaFound,
                      action: _searchQuery.isNotEmpty || _selectedGenre != 'All'
                          ? LuButton(
                              label: l10n.mgResetToAllCategories,
                              icon: Icons.refresh_rounded,
                              kind: LuButtonKind.secondary,
                              compact: true,
                              onPressed: () => _onGenreSelected('All'),
                            )
                          : null,
                    ),
                  )
                else
                  LuPosterGrid(
                    itemCount: _mangaList.length,
                    padding: pad,
                    targetWidth: posterW,
                    itemBuilder: (context, i, w) {
                      final m = _mangaList[i];
                      return LuPosterCard(
                        width: w,
                        title: m.title,
                        poster: m.coverNormal.isNotEmpty
                            ? m.coverNormal
                            : m.coverSmall,
                        subtitle: m.author.isNotEmpty
                            ? m.author
                            : (m.year.isNotEmpty ? m.year : null),
                        badge: showBadge ? mangaTypeLabel(l10n, m.type) : null,
                        onTap: () => _openDetails(m),
                      );
                    },
                  ),

                if (_isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(color: LuColors.gold),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48 + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),

            // ── Custom Scroll Track (Desktop only) ──
            if (width > 800 && showScrollTrack)
              Positioned(
                right: 24,
                bottom: 40,
                child: CustomScrollTrack(controller: _scrollController),
              ),
          ],
        ),
      ),
    );
  }

  /// The page's title, its customise disc and the search box.
  Widget _buildHeader(BuildContext context, double pad, bool phone) {
    final l10n = l10nOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        pad,
        MediaQuery.paddingOf(context).top + 24,
        pad,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mangaPageTitle,
                      style: LuText.title.copyWith(fontSize: phone ? 28 : 34),
                    ),
                    if (!phone)
                      Text(l10n.mangaPageSubtitle, style: LuText.bodySoft),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              LuGlyphButton(
                icon: Icons.tune_rounded,
                label: l10n.mgCustomizeMangaSection,
                onTap: () => _showMangaCustomizer(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: LuSearchBox(
              controller: _searchController,
              hint: l10n.mgSearchMangaManhwaManhua,
              clearLabel: l10n.mgClearSearch,
              onSubmitted: _onSearchChanged,
              onClear: () => _onSearchChanged(''),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// One 继续阅读 card: the cover with the chapter on it, the title and how
  /// far along the reader is.
  Widget _historyCard(Map<String, dynamic> entry, double width) {
    final l10n = l10nOf(context);
    final mangaJson = entry['manga'] as Map<String, dynamic>;
    final mangaId = (mangaJson['id'] ?? '').toString();
    final title = (mangaJson['title'] ?? '').toString();
    final author = (mangaJson['author'] ?? '').toString();
    final coverUrl =
        (mangaJson['cover_normal'] ?? mangaJson['cover_small'] ?? '')
            .toString();
    final chapterIndex = entry['chapterIndex'] as int;
    final chaptersList = entry['chapters'] as List;

    var chapterLabel = '';
    if (chapterIndex >= 0 && chapterIndex < chaptersList.length) {
      final number = chaptersList[chapterIndex]['number'];
      if (number is num) chapterLabel = mangaChapterShort(l10n, number);
    }
    final fraction = chaptersList.isEmpty
        ? 0.0
        : ((chapterIndex + 1) / chaptersList.length).clamp(0.0, 1.0);
    final percent = (fraction * 100).round();

    return LuCoverContinueCard(
      width: width,
      title: title,
      cover: coverUrl,
      progress: fraction,
      badge: chapterLabel.isEmpty ? null : chapterLabel,
      caption: author.isEmpty
          ? l10n.mg2PercentRead(percent)
          : l10n.mg2AuthorPercentRead(author, percent),
      onTap: () => _resumeReading(entry),
      onRemove: () => _onRemoveHistory(mangaId),
      removeLabel: l10n.mgRemoveFromContinueReading,
    );
  }
}
