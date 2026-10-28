import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/book/book_result.dart';
import '../../services/books/bookracy_service.dart';
import '../../services/books/continue_reading_service.dart';
import '../../services/books/reader_settings.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_theme.dart';
import 'book_detail_sheet.dart';
import 'widgets/continue_reading_slider.dart';
import 'widgets/lu_reading_kit.dart';
import 'widgets/reader_customization_sheet.dart';
import 'widgets/reader_design_tokens.dart';

/// One entry of the shelf's font selector: the face's name and the value
/// written to `ReaderSettingsData.fontFamily`.
@immutable
class _FontEngine {
  const _FontEngine(this.label, this.family);

  final String label;
  final String family;
}

const List<_FontEngine> _fontEngines = [
  _FontEngine('Poppins', 'Poppins'),
  _FontEngine('Georgia', ReaderTokens.defaultSerifFont),
  _FontEngine('OpenDyslexic', 'OpenDyslexic'),
];

/// 书籍: search, the format pills, the reader's quick style, 继续阅读 and a
/// cover grid. A cover opens its sheet, where it is downloaded and read.
class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<BookResult> _books = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  String _currentQuery = 'fantasy';
  String? _selectedFormat; // 'epub', 'pdf', or null for all
  int _currentPage = 1;
  bool _hasMore = true;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      if (!_loadingMore && !_loading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadBooks({bool resetPage = true}) async {
    if (resetPage) {
      _currentPage = 1;
      _hasMore = true;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await BookracyService.instance.searchBooks(
        query: _currentQuery,
        page: _currentPage,
        limit: 80,
        formatFilter: _selectedFormat,
      );

      if (!mounted) return;
      setState(() {
        _books = results;
        _loading = false;
        _hasMore = results.length >= 20;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = l10nCurrent().bk2FailedToLoadBooks(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      _currentPage++;
      final more = await BookracyService.instance.searchBooks(
        query: _currentQuery,
        page: _currentPage,
        limit: 80,
        formatFilter: _selectedFormat,
      );

      if (!mounted) return;
      setState(() {
        _books.addAll(more);
        _loadingMore = false;
        if (more.isEmpty) _hasMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 380), () {
      final trimmed = query.trim();
      setState(() {
        _currentQuery = trimmed.isNotEmpty ? trimmed : 'fantasy';
      });
      _loadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 600;
    final pad = luPagePad(context);
    final coverW = phone ? 116.0 : (width < 1000 ? 150.0 : 164.0);
    final query = _searchController.text.trim();

    return Theme(
      data: luTheme(),
      child: ColoredBox(
        color: LuColors.bg,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, pad, phone)),
            SliverToBoxAdapter(child: _buildFilters(context, pad)),
            SliverToBoxAdapter(child: _buildReaderStyle(context, pad)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ContinueReadingSlider(padding: pad, coverWidth: coverW),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 8, pad, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        query.isNotEmpty
                            ? l10n.bk2ResultsFor(query)
                            : l10n.bkDiscoverBooks,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuText.heading,
                      ),
                    ),
                    if (!_loading && _books.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text('${_books.length}', style: LuText.caption),
                    ],
                  ],
                ),
              ),
            ),

            if (_loading)
              LuPosterGridSkeleton(padding: pad, targetWidth: coverW)
            else if (_error != null)
              SliverToBoxAdapter(
                child: LuEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.bkCouldNotLoadBooks,
                  message: _error,
                  action: LuButton(
                    label: l10n.actionRetry,
                    icon: Icons.refresh_rounded,
                    kind: LuButtonKind.secondary,
                    compact: true,
                    onPressed: () => _loadBooks(),
                  ),
                ),
              )
            else if (_books.isEmpty)
              SliverToBoxAdapter(
                child: LuEmptyState(
                  icon: Icons.search_off_rounded,
                  title: l10n.bkNoBooksFound,
                  message: l10n.bkTrySearchingForAnotherTitleAuthor,
                ),
              )
            else
              LuPosterGrid(
                itemCount: _books.length,
                padding: pad,
                targetWidth: coverW,
                itemBuilder: (context, i, w) {
                  final book = _books[i];
                  final progress = ContinueReadingService.getProgress(book.md5);
                  final reading =
                      progress != null && progress.progressPercent > 0.01;
                  return LuPosterCard(
                    width: w,
                    title: book.displayTitle,
                    poster: book.coverUrl,
                    subtitle: reading
                        ? l10n.bk2AuthorPercentRead(
                            book.displayAuthor,
                            (progress.progressPercent * 100).round(),
                          )
                        : book.displayAuthor,
                    badge: book.bookFiletype.isEmpty
                        ? null
                        : book.bookFiletype.toUpperCase(),
                    onTap: () => BookDetailSheet.show(context, book),
                  );
                },
              ),

            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: LuColors.gold,
                    ),
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
      ),
    );
  }

  /// The page's title and the search box.
  Widget _buildHeader(BuildContext context, double pad, bool phone) {
    final l10n = l10nOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        pad,
        MediaQuery.paddingOf(context).top + 24,
        pad,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.booksPageTitle,
            style: LuText.title.copyWith(fontSize: phone ? 28 : 34),
          ),
          if (!phone) Text(l10n.booksPageSubtitle, style: LuText.bodySoft),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: LuSearchBox(
              controller: _searchController,
              hint: l10n.bkSearchMillionsOfBooksAuthors,
              clearLabel: l10n.mgClearSearch,
              onChanged: _onSearchChanged,
              onClear: () => _onSearchChanged(''),
            ),
          ),
        ],
      ),
    );
  }

  /// The format pills.
  Widget _buildFilters(BuildContext context, double pad) {
    final l10n = l10nOf(context);
    const formats = ['epub', 'pdf', 'mobi', 'azw3', 'fb2', 'txt', 'cbz'];
    void pick(String? format) {
      setState(() => _selectedFormat = format);
      _loadBooks();
    }

    return Semantics(
      label: l10n.bkBookFormats,
      container: true,
      child: LuPillRow(
        padding: EdgeInsets.symmetric(horizontal: pad),
        children: [
          LuChoicePill(
            label: l10n.bk2AllFormats,
            selected: _selectedFormat == null,
            onTap: () => pick(null),
          ),
          for (final f in formats)
            LuChoicePill(
              label: f.toUpperCase(),
              selected: _selectedFormat == f,
              onTap: () => pick(f),
            ),
        ],
      ),
    );
  }

  /// The reader's quick style: the face it sets books in, and the size and
  /// margins, which opens the full customisation sheet. Both write
  /// [ReaderSettings], which the reader renders.
  Widget _buildReaderStyle(BuildContext context, double pad) {
    final l10n = l10nOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ValueListenableBuilder<ReaderSettingsData>(
        valueListenable: ReaderSettings.settingsNotifier,
        builder: (context, settings, _) {
          final size = settings.fontSize.round();
          final margins = _marginLabel(context, settings.marginPreset);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: LuSectionLabel(l10n.booksReaderStyle),
              ),
              Semantics(
                label: l10n.bkReaderFontEngine,
                container: true,
                child: LuPillRow(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  children: [
                    for (final engine in _fontEngines)
                      LuChoicePill(
                        label: engine.label,
                        fontFamily: engine.family,
                        selected: settings.fontFamily == engine.family,
                        onTap: () =>
                            ReaderSettings.updateFontFamily(engine.family),
                      ),
                    LuChoicePill(
                      label: '${l10n.booksFontSizePt('$size')} · $margins',
                      icon: Icons.tune_rounded,
                      selected: false,
                      onTap: () => ReaderCustomizationSheet.show(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _marginLabel(BuildContext context, MarginPreset preset) {
    final l10n = l10nOf(context);
    return switch (preset) {
      MarginPreset.compact => l10n.bkCompact,
      MarginPreset.balanced => l10n.bkStandard,
      MarginPreset.wide => l10n.bkWide,
    };
  }
}
