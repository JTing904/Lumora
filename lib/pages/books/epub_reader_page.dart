import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/book/book_result.dart';
import '../../models/book/reading_progress.dart';
import '../../services/books/continue_reading_service.dart';
import '../../services/books/epub_parser_service.dart';
import '../../services/books/reader_settings.dart';
import '../../services/window/window_service.dart';
import '../../services/discord/discord_rpc_service.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';
import '../../widgets/common/custom_scroll_track.dart';
import 'widgets/comic_reader_view.dart';
import 'widgets/epub_content_view.dart';
import 'widgets/focus_mode_view.dart';
import 'widgets/lu_reading_kit.dart';
import 'widgets/reader_customization_sheet.dart';
import 'widgets/reader_design_tokens.dart';

class EpubReaderPage extends StatefulWidget {
  final File file;
  final BookResult book;
  final int initialChapterIndex;
  final double initialScrollOffset;

  const EpubReaderPage({
    super.key,
    required this.file,
    required this.book,
    this.initialChapterIndex = 0,
    this.initialScrollOffset = 0.0,
  });

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _readerFocusNode = FocusNode(debugLabel: 'book reader page');

  /// The top bar's back button, where Select on the page sends focus.
  final FocusNode _chromeFocus = FocusNode(debugLabel: 'book reader chrome');

  /// The top and bottom bars, as groups: focus inside one of them is a
  /// control's, while focus in the text (a selection, an inline image) is
  /// still the page's.
  final FocusNode _topChromeGroup = FocusNode(
    debugLabel: 'book reader top bar',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final FocusNode _bottomChromeGroup = FocusNode(
    debugLabel: 'book reader bottom bar',
    canRequestFocus: false,
    skipTraversal: true,
  );

  EpubBookData? _bookData;
  bool _loading = true;
  String? _error;

  int _currentChapterIndex = 0;
  bool _showChrome = false; // Zero chrome by default
  bool _isHoveringControls = false;
  bool _drawerOpen = false;
  Timer? _chromeTimer;
  Timer? _progressSaveTimer;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _scrollController.addListener(_onScrollChanged);
    _loadBook();
  }

  @override
  void dispose() {
    _chromeTimer?.cancel();
    _progressSaveTimer?.cancel();
    _saveProgress();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _readerFocusNode.dispose();
    _chromeFocus.dispose();
    _topChromeGroup.dispose();
    _bottomChromeGroup.dispose();
    DiscordRpcService.instance.clearToIdle();
    super.dispose();
  }

  void _onScrollChanged() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }

  Future<void> _loadBook() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    DiscordRpcService.instance.setReadingBook(
      title: widget.book.title,
      author: widget.book.author,
      coverUrl: widget.book.coverUrl,
    );

    try {
      final parsed = await EpubParserService.instance.parseBook(
        widget.file,
        widget.book.bookFiletype,
      );

      if (!mounted) return;
      setState(() {
        _bookData = parsed;
        _loading = false;
        if (_currentChapterIndex >= parsed.totalChapters) {
          _currentChapterIndex = 0;
        }
      });

      DiscordRpcService.instance.setReadingBook(
        title: widget.book.title,
        author: widget.book.author,
        coverUrl: widget.book.coverUrl,
        page: _currentChapterIndex + 1,
        totalPages: parsed.totalChapters,
      );

      if (widget.initialScrollOffset > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(widget.initialScrollOffset);
          }
        });
      }

      _saveProgress();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = l10nCurrent().bk2FailedToOpenBook(widget.book.displayTitle, e);
        _loading = false;
      });
    }
  }

  /// Focus is on one of the chrome's controls rather than the page.
  bool get _chromeHasFocus =>
      _topChromeGroup.hasFocus || _bottomChromeGroup.hasFocus;

  /// Hides the chrome after a while, unless the pointer or a remote's focus
  /// is on it.
  void _scheduleChromeHide() {
    _chromeTimer?.cancel();
    _chromeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showChrome && !_isHoveringControls) {
        if (_chromeHasFocus) {
          _scheduleChromeHide();
          return;
        }
        setState(() => _showChrome = false);
      }
    });
  }

  void _onUserActivity() {
    if (!_showChrome) {
      setState(() => _showChrome = true);
    }
    _scheduleChromeHide();
  }

  void _toggleChrome() {
    setState(() {
      _showChrome = !_showChrome;
    });

    _chromeTimer?.cancel();
    if (_showChrome) {
      _scheduleChromeHide();
    } else if (_chromeHasFocus) {
      _readerFocusNode.requestFocus();
    }
  }

  /// Hides the chrome and gives the page its keys back.
  void _hideChrome() {
    _chromeTimer?.cancel();
    setState(() => _showChrome = false);
    _readerFocusNode.requestFocus();
  }

  void _goToChapter(int target) {
    if (_bookData == null) return;
    if (target < 0 || target >= _bookData!.totalChapters) return;

    HapticFeedback.selectionClick();

    setState(() {
      _currentChapterIndex = target;
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    _progressSaveTimer?.cancel();
    _saveProgress();
  }

  void _saveProgress() {
    if (_bookData == null) return;
    final total = _bookData!.totalChapters;
    final percent = total > 0
        ? ((_currentChapterIndex + 1) / total).clamp(0.0, 1.0)
        : 0.0;
    final offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;

    final progress = ReadingProgress(
      md5: widget.book.md5,
      title: widget.book.displayTitle,
      author: widget.book.displayAuthor,
      coverUrl: widget.book.coverUrl,
      filePath: widget.file.path,
      fileType: widget.book.bookFiletype.isNotEmpty
          ? widget.book.bookFiletype
          : 'epub',
      chapterIndex: _currentChapterIndex,
      scrollOffset: offset,
      progressPercent: percent,
      totalChapters: total,
      totalPages: total,
      currentPage: _currentChapterIndex + 1,
      lastReadAt: DateTime.now(),
    );

    ContinueReadingService.saveProgress(progress);
  }

  Uint8List? _getComicPageImage() {
    if (_bookData == null ||
        _currentChapterIndex >= _bookData!.chapters.length) {
      return null;
    }
    final ch = _bookData!.chapters[_currentChapterIndex];

    final key = 'page_$_currentChapterIndex.jpg';
    if (_bookData!.images.containsKey(key)) return _bookData!.images[key];

    final chImg = _bookData!.resolveImage(ch.href, ch.href);
    if (chImg != null) return chImg;

    final imgMatch = RegExp(
      r'<img[^>]+(?:src|href)="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(ch.htmlContent);
    if (imgMatch != null) {
      final src = imgMatch.group(1)!;
      final resolved = _bookData!.resolveImage(src, ch.href);
      if (resolved != null) return resolved;
    }

    if (widget.book.isComic && _bookData!.images.isNotEmpty) {
      if (_currentChapterIndex < _bookData!.images.length) {
        return _bookData!.images.values.elementAt(_currentChapterIndex);
      }
    }

    return null;
  }

  String _getSamplePreviewText() {
    if (_bookData == null ||
        _currentChapterIndex >= _bookData!.chapters.length) {
      return '';
    }
    final ch = _bookData!.chapters[_currentChapterIndex];
    final plain = ch.htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (plain.length > 200) {
      return '${plain.substring(0, 195)}...';
    }
    return plain;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    // The contents drawer handles its own keys.
    if (_drawerOpen) return KeyEventResult.ignored;

    // While a control has focus the arrows move between controls, Select is
    // the control's, and Escape hides the controls.
    if (_chromeHasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _hideChrome();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      // A remote's Select shows the controls and moves into them.
      setState(() => _showChrome = true);
      _scheduleChromeHide();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showChrome) _chromeFocus.requestFocus();
      });
      return KeyEventResult.handled;
    }

    if ((event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.arrowUp) &&
        _scrollController.hasClients) {
      // Down and Up read on through the chapter.
      final p = _scrollController.position;
      final dir = event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1;
      _scrollController.animateTo(
        (p.pixels + dir * p.viewportDimension * 0.6).clamp(
          0.0,
          p.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.pageDown) {
      _goToChapter(_currentChapterIndex + 1);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.pageUp) {
      _goToChapter(_currentChapterIndex - 1);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (ReaderSettings.current.focusModeActive) {
        ReaderSettings.exitFocusMode();
      } else {
        Navigator.of(context).pop();
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
      WindowService.instance.toggleFullscreen();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyT) {
      _scaffoldKey.currentState?.openDrawer();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ValueListenableBuilder<ReaderSettingsData>(
      valueListenable: ReaderSettings.settingsNotifier,
      builder: (context, settings, _) {
        final comicImage = _getComicPageImage();
        final isComicMode =
            comicImage != null &&
            (widget.book.isComic ||
                _bookData!.chapters[_currentChapterIndex].wordCount == 0 ||
                _bookData!.chapters[_currentChapterIndex].htmlContent.contains(
                  '<img',
                ));

        // If Focus Mode is active on text books
        if (settings.focusModeActive &&
            !isComicMode &&
            _bookData != null &&
            _bookData!.chapters.isNotEmpty) {
          return FocusModeView(
            book: _bookData!,
            chapter: _bookData!.chapters[_currentChapterIndex],
            settings: settings,
            onExit: () => ReaderSettings.exitFocusMode(),
            onNextChapter: _currentChapterIndex < _bookData!.chapters.length - 1
                ? () => _goToChapter(_currentChapterIndex + 1)
                : null,
            onPrevChapter: _currentChapterIndex > 0
                ? () => _goToChapter(_currentChapterIndex - 1)
                : null,
          );
        }

        final total = _bookData?.totalChapters ?? 1;
        final current = _currentChapterIndex + 1;
        final overallProgress = total > 0
            ? (current / total).clamp(0.0, 1.0)
            : 0.0;

        return Theme(
          data: luTheme(),
          child: PopScope(
            // A remote's Back from the controls hides them first.
            canPop: _drawerOpen || !(_showChrome && _chromeHasFocus),
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _hideChrome();
            },
            child: Focus(
              focusNode: _readerFocusNode,
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              onFocusChange: (_) => setState(() {}),
              child: Scaffold(
                key: _scaffoldKey,
                onDrawerChanged: (open) => setState(() => _drawerOpen = open),
                backgroundColor: isComicMode
                    ? ReaderTokens.bg
                    : settings.backgroundColor,
                drawer: _buildTocDrawer(),
                body: MouseRegion(
                  onHover: (_) => _onUserActivity(),
                  onEnter: (_) => _onUserActivity(),
                  child: Stack(
                    children: [
                      // ── Reader Content Canvas ──
                      Positioned.fill(
                        child: _loading
                            ? _buildSkeletonLoading(settings)
                            : _error != null
                            ? _buildErrorState(settings)
                            : _bookData == null || _bookData!.chapters.isEmpty
                            ? _buildEmptyState(settings)
                            : isComicMode
                            ? ComicReaderView(
                                imageBytes: comicImage,
                                pageTitle: _bookData!
                                    .chapters[_currentChapterIndex]
                                    .title,
                                onNextPage:
                                    _currentChapterIndex <
                                        _bookData!.chapters.length - 1
                                    ? () =>
                                          _goToChapter(_currentChapterIndex + 1)
                                    : null,
                                onPrevPage: _currentChapterIndex > 0
                                    ? () =>
                                          _goToChapter(_currentChapterIndex - 1)
                                    : null,
                                onToggleControls: _toggleChrome,
                                showControls: _showChrome,
                              )
                            : GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: _toggleChrome,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 780,
                                    ),
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(
                                        top: 76,
                                        bottom: 96,
                                      ),
                                      child: EpubContentView(
                                        book: _bookData!,
                                        chapter: _bookData!
                                            .chapters[_currentChapterIndex],
                                        settings: settings,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      // ── In-App Brightness Dimmer Layer ──
                      if (settings.brightness < 0.99)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: ReaderTokens.bg.withValues(
                                alpha: 1.0 - settings.brightness,
                              ),
                            ),
                          ),
                        ),

                      // ── Top Bar Chrome with Gradient Scrim ──
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedSlide(
                          offset: _showChrome
                              ? Offset.zero
                              : const Offset(0, -0.2),
                          duration: reduceMotion
                              ? Duration.zero
                              : ReaderTokens.motionChrome,
                          curve: ReaderTokens.curveChrome,
                          child: AnimatedOpacity(
                            opacity: _showChrome ? 1.0 : 0.0,
                            duration: reduceMotion
                                ? Duration.zero
                                : ReaderTokens.motionChrome,
                            curve: ReaderTokens.curveChrome,
                            child: IgnorePointer(
                              ignoring: !_showChrome,
                              child: ExcludeFocus(
                                excluding: !_showChrome,
                                child: MouseRegion(
                                  onEnter: (_) {
                                    _isHoveringControls = true;
                                    _chromeTimer?.cancel();
                                  },
                                  onExit: (_) {
                                    _isHoveringControls = false;
                                    _onUserActivity();
                                  },
                                  child: Focus(
                                    focusNode: _topChromeGroup,
                                    onFocusChange: (_) => setState(() {}),
                                    child: _buildTopChrome(
                                      settings,
                                      isComicMode,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Bottom Bar Chrome with Gradient Scrim ──
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedSlide(
                          offset: _showChrome
                              ? Offset.zero
                              : const Offset(0, 0.2),
                          duration: reduceMotion
                              ? Duration.zero
                              : ReaderTokens.motionChrome,
                          curve: ReaderTokens.curveChrome,
                          child: AnimatedOpacity(
                            opacity: _showChrome ? 1.0 : 0.0,
                            duration: reduceMotion
                                ? Duration.zero
                                : ReaderTokens.motionChrome,
                            curve: ReaderTokens.curveChrome,
                            child: IgnorePointer(
                              ignoring: !_showChrome,
                              child: ExcludeFocus(
                                excluding: !_showChrome,
                                child: MouseRegion(
                                  onEnter: (_) {
                                    _isHoveringControls = true;
                                    _chromeTimer?.cancel();
                                  },
                                  onExit: (_) {
                                    _isHoveringControls = false;
                                    _onUserActivity();
                                  },
                                  child: Focus(
                                    focusNode: _bottomChromeGroup,
                                    onFocusChange: (_) => setState(() {}),
                                    child: _buildBottomChrome(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Custom Scroll Track (Desktop Only) ──
                      if (!isComicMode &&
                          !_loading &&
                          _error == null &&
                          _bookData != null &&
                          MediaQuery.sizeOf(context).width > 800)
                        Positioned(
                          right: 24,
                          bottom: 40,
                          child: CustomScrollTrack(
                            controller: _scrollController,
                          ),
                        ),

                      // ── Hairline Progress Bar Pinned to Absolute Bottom (Always Visible) ──
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Stack(
                          children: [
                            // 2px track in 12% opacity
                            Container(
                              height: 2.0,
                              color: settings.textColor.withValues(alpha: 0.12),
                            ),
                            // 2px active indicator
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: overallProgress,
                              child: Container(
                                height: 2.0,
                                color: settings.accentColor,
                              ),
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
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TOP CHROME (56px Height + 24px Gradient Scrim)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTopChrome(ReaderSettingsData settings, bool isComicMode) {
    final l10n = l10nOf(context);
    final chapterTitle =
        _bookData != null && _currentChapterIndex < _bookData!.chapters.length
        ? _bookData!.chapters[_currentChapterIndex].title
        : widget.book.displayTitle;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 10,
        16,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF00A0A0C), Color(0x000A0A0C)],
        ),
      ),
      child: FocusTraversalGroup(
        child: Row(
          children: [
            LuGlyphButton(
              icon: Icons.arrow_back_ios_new_rounded,
              label: l10n.bk2BackToLibrary,
              iconSize: 18,
              focusNode: _chromeFocus,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            LuGlyphButton(
              icon: Icons.format_list_bulleted_rounded,
              label: l10n.bkTableOfContentsT,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.book.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuText.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuText.caption.copyWith(color: LuColors.textSoft),
                  ),
                ],
              ),
            ),
            if (!isComicMode) ...[
              const SizedBox(width: 8),
              LuGlyphButton(
                icon: Icons.center_focus_strong_rounded,
                label: l10n.bkFocusModeLineByLine,
                active: settings.focusModeActive,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ReaderSettings.toggleFocusMode();
                },
              ),
              const SizedBox(width: 8),
              LuGlyphButton(
                icon: Icons.tune_rounded,
                label: l10n.bkAppearanceCustomization,
                onTap: () => ReaderCustomizationSheet.show(
                  context,
                  realBookSampleText: _getSamplePreviewText(),
                ),
              ),
            ],
            const SizedBox(width: 8),
            LuGlyphButton(
              icon: Icons.fullscreen_rounded,
              label: l10n.bkToggleFullscreenF,
              iconSize: 22,
              onTap: () => WindowService.instance.toggleFullscreen(),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BOTTOM CHROME
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildBottomChrome() {
    if (_bookData == null || _bookData!.totalChapters == 0) {
      return const SizedBox.shrink();
    }
    final l10n = l10nOf(context);

    final total = _bookData!.totalChapters;
    final current = _currentChapterIndex + 1;
    final percent = ((current / total) * 100).round();

    final currentCh = _bookData!.chapters[_currentChapterIndex];
    final words = currentCh.wordCount;
    final minsLeft = words > 0 ? (words / 200).ceil() : 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        28,
        16,
        MediaQuery.paddingOf(context).bottom + 14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xF00A0A0C), Color(0x000A0A0C)],
        ),
      ),
      child: FocusTraversalGroup(
        child: Row(
          children: [
            LuGlyphButton(
              icon: Icons.chevron_left_rounded,
              label: l10n.bkPreviousChapterLeftArrow,
              iconSize: 26,
              onTap: _currentChapterIndex > 0
                  ? () => _goToChapter(_currentChapterIndex - 1)
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.booksChapterOfTotal('$current', '$total'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuText.label.copyWith(
                          color: LuColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Spacer(),
                    Text(
                      l10n.bk2PercentMinsLeft(percent, minsLeft),
                      style: LuText.caption.copyWith(color: LuColors.gold),
                    ),
                  ],
                ),
              ),
            ),
            LuGlyphButton(
              icon: Icons.chevron_right_rounded,
              label: l10n.bkNextChapterRightArrow,
              iconSize: 26,
              onTap: _currentChapterIndex < total - 1
                  ? () => _goToChapter(_currentChapterIndex + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATES: SKELETON LOADING, ERROR, EMPTY
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSkeletonLoading(ReaderSettingsData settings) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 28,
                width: 220,
                decoration: BoxDecoration(
                  color: settings.textColor.withValues(alpha: 0.12),
                  borderRadius: ReaderTokens.rounded8,
                ),
              ),
              const SizedBox(height: ReaderTokens.space32),
              for (int i = 0; i < 6; i++) ...[
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: settings.textColor.withValues(alpha: 0.07),
                    borderRadius: ReaderTokens.rounded4,
                  ),
                ),
                const SizedBox(height: ReaderTokens.space12),
              ],
              Container(
                height: 16,
                width: 180,
                decoration: BoxDecoration(
                  color: settings.textColor.withValues(alpha: 0.07),
                  borderRadius: ReaderTokens.rounded4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ReaderSettingsData settings) {
    final l10n = l10nOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              color: LuColors.danger,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? l10n.bkUnableToOpenBook,
              style: LuText.body.copyWith(color: settings.textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                LuButton(
                  label: l10n.bk2BackToLibrary,
                  kind: LuButtonKind.secondary,
                  compact: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                LuButton(
                  label: l10n.bk2Retry,
                  icon: Icons.refresh_rounded,
                  compact: true,
                  autofocus: true,
                  onPressed: _loadBook,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ReaderSettingsData settings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_rounded,
              color: settings.secondaryTextColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10nOf(context).bkNoReadableChaptersFound,
              style: LuText.body.copyWith(color: settings.secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TABLE OF CONTENTS DRAWER
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTocDrawer() {
    final l10n = l10nOf(context);
    final toc = _bookData?.tableOfContents ?? [];

    return Drawer(
      backgroundColor: LuColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.format_list_bulleted_rounded,
                    color: LuColors.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l10n.bkTableOfContents, style: LuText.heading),
                  ),
                ],
              ),
            ),
            Expanded(
              child: toc.isEmpty
                  ? Center(
                      child: Text(
                        l10n.bkNoTableOfContentsAvailable,
                        style: LuText.bodySoft,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: toc.length,
                      itemBuilder: (context, idx) {
                        final item = toc[idx];
                        final isSelected =
                            item.chapterIndex == _currentChapterIndex;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: LuFocusable(
                            autofocus: isSelected,
                            lift: 1.01,
                            borderRadius: LuRadius.field,
                            semanticLabel: item.title,
                            onTap: () {
                              Navigator.of(context).pop();
                              _goToChapter(item.chapterIndex);
                            },
                            builder: (context, hi) => AnimatedContainer(
                              duration: LuMotion.focus,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: LuRadius.field,
                                color: isSelected
                                    ? const Color(0x1FF2B544)
                                    : (hi
                                          ? LuColors.surfaceHigh
                                          : Colors.transparent),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 34,
                                    child: Text(
                                      '${idx + 1}',
                                      style: LuText.caption.copyWith(
                                        fontFamily: LuFonts.display,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? LuColors.gold
                                            : LuColors.textFaint,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: LuText.body.copyWith(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? LuColors.gold
                                            : LuColors.text,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      color: LuColors.gold,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
