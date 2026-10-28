import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/manga/manga.dart';
import '../../models/manga/manga_chapter.dart';
import '../../services/discord/discord_rpc_service.dart';
import '../../services/layout/form_factor.dart';
import '../../services/manga/manga_service.dart';
import '../../services/manga/manga_settings.dart';
import '../../services/storage/app_image_cache.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';
import '../../widgets/common/custom_scroll_track.dart';
import '../books/widgets/lu_reading_kit.dart';
import 'widgets/manga_labels.dart';
import 'widgets/manga_reader_controls.dart';

class MangaReaderPage extends StatefulWidget {
  final Manga manga;
  final List<MangaChapter> chapters;
  final int currentChapterIndex;
  final int resumePageIndex;

  const MangaReaderPage({
    super.key,
    required this.manga,
    required this.chapters,
    required this.currentChapterIndex,
    this.resumePageIndex = 0,
  });

  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage> {
  final MangaService _mangaService = MangaService();
  final FocusNode _focusNode = FocusNode(debugLabel: 'manga reader page');

  /// The top bar's back button, where Select on the page sends focus.
  final FocusNode _chromeFocus = FocusNode(debugLabel: 'manga reader chrome');

  late int _currentChapterIndex;
  late int _currentPageIndex;

  List<String> _pageUrls = [];
  bool _isLoading = true;
  bool _showOverlay = true;
  bool _showDeckDrawer = false;

  late MangaReadingMode _readingMode;

  PageController? _pageController;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _deckScrollController = ScrollController();
  Timer? _progressSaveTimer;
  final TransformationController _transformationController =
      TransformationController();

  double _currentZoom = 1.0;

  /// Bumped by every [_loadChapter], so a slow answer for a chapter the
  /// viewer has already left is dropped.
  int _loadToken = 0;

  /// The webtoon list is being put back at [_currentPageIndex]; its scroll
  /// events until then are ours, not the viewer's, and must not be saved.
  bool _restoringWebtoon = false;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.currentChapterIndex;
    _currentPageIndex = widget.resumePageIndex;
    _readingMode = MangaSettings.defaultReadingMode.value;

    _initPageController();
    _focusNode.addListener(_onFocusMoved);
    _verticalScrollController.addListener(_onVerticalScroll);
    MangaSettings.changeNotifier.addListener(_onSettingsChanged);

    _loadChapter();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _initPageController() {
    _pageController?.dispose();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    _saveProgress();
    MangaSettings.changeNotifier.removeListener(_onSettingsChanged);
    _focusNode.removeListener(_onFocusMoved);
    _focusNode.dispose();
    _chromeFocus.dispose();
    _pageController?.dispose();
    _verticalScrollController.dispose();
    _deckScrollController.dispose();
    _transformationController.dispose();
    DiscordRpcService.instance.clearToIdle();
    super.dispose();
  }

  Matrix4 _buildCenterScaleMatrix(double scale, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    return Matrix4.identity()
      ..translate(cx, cy)
      ..scale(scale)
      ..translate(-cx, -cy);
  }

  void _zoomIn() {
    final size = MediaQuery.sizeOf(context);
    setState(() {
      _currentZoom = (_currentZoom + 0.25).clamp(0.25, 5.0);
      if ((_currentZoom - 1.0).abs() < 0.05) {
        _currentZoom = 1.0;
        _transformationController.value = Matrix4.identity();
      } else {
        _transformationController.value = _buildCenterScaleMatrix(
          _currentZoom,
          size,
        );
      }
    });
  }

  void _zoomOut() {
    final size = MediaQuery.sizeOf(context);
    setState(() {
      _currentZoom = (_currentZoom - 0.25).clamp(0.25, 5.0);
      if ((_currentZoom - 1.0).abs() < 0.05) {
        _currentZoom = 1.0;
        _transformationController.value = Matrix4.identity();
      } else {
        _transformationController.value = _buildCenterScaleMatrix(
          _currentZoom,
          size,
        );
      }
    });
  }

  void _resetZoom() {
    setState(() {
      _currentZoom = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _loadChapter() async {
    final token = ++_loadToken;
    _resetZoom();
    setState(() => _isLoading = true);

    final chapter = widget.chapters[_currentChapterIndex];
    DiscordRpcService.instance.setReadingManga(
      title: widget.manga.title,
      chapter: chapter.name.isNotEmpty
          ? chapter.name
          : 'Chapter ${chapter.number}',
      coverUrl: widget.manga.coverNormal.isNotEmpty
          ? widget.manga.coverNormal
          : widget.manga.coverSmall,
    );
    final urls = await _mangaService.getChapterImages(chapter.id);

    if (mounted && token == _loadToken) {
      setState(() {
        _pageUrls = urls;
        _isLoading = false;

        if (urls.isNotEmpty && _currentPageIndex >= urls.length) {
          _currentPageIndex = 0;
        }
      });

      // Keep a bounded window warm instead of decoding the whole chapter. The
      // deck is a lazy list, so far-off thumbnails do not need to be fetched
      // until they are actually scrolled into view.
      final pageCacheWidth = (MediaQuery.sizeOf(context).width * 2)
          .round()
          .clamp(96, 2048)
          .toInt();
      if (urls.isNotEmpty) {
        final thumbStart = _currentPageIndex - 10 < 0
            ? 0
            : _currentPageIndex - 10;
        final thumbEnd = _currentPageIndex + 10 >= urls.length
            ? urls.length - 1
            : _currentPageIndex + 10;
        for (var i = thumbStart; i <= thumbEnd; i++) {
          precacheImage(
            ResizeImage.resizeIfNeeded(
              140,
              null,
              CachedNetworkImageProvider(
                urls[i],
                cacheManager: AppImageCache.manager,
              ),
            ),
            context,
          );
        }
      }
      for (var i = _currentPageIndex - 2; i <= _currentPageIndex + 2; i++) {
        if (i < 0 || i >= urls.length) continue;
        precacheImage(
          ResizeImage.resizeIfNeeded(
            pageCacheWidth,
            null,
            CachedNetworkImageProvider(
              urls[i],
              cacheManager: AppImageCache.manager,
            ),
          ),
          context,
        );
      }

      if (_pageController?.hasClients ?? false) {
        _pageController!.jumpToPage(_currentPageIndex);
      } else {
        _initPageController();
      }

      _restoreWebtoonPosition();
      _saveProgress();
      _scrollToCurrentPageInDeck();
    }
  }

  /// Puts the webtoon list back at [_currentPageIndex] once it is laid out:
  /// the resumed page on open, the top for a new chapter.
  void _restoreWebtoonPosition() {
    if (_readingMode != MangaReadingMode.webtoon) return;
    _restoringWebtoon = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _verticalScrollController.hasClients) {
        final p = _verticalScrollController.position;
        _verticalScrollController.jumpTo(
          (_currentPageIndex * 900.0).clamp(0.0, p.maxScrollExtent),
        );
      }
      _restoringWebtoon = false;
    });
  }

  void _saveProgress() {
    _mangaService.saveProgress(
      widget.manga,
      _currentChapterIndex,
      _currentPageIndex,
      widget.chapters,
    );
  }

  void _scheduleSaveProgress() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }

  void _scrollToCurrentPageInDeck() {
    if (!_showDeckDrawer ||
        !_deckScrollController.hasClients ||
        _pageUrls.isEmpty) {
      return;
    }
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 600;
    final isVerySmall = screenW < 420;
    final cardW = (isVerySmall ? 52.0 : (isMobile ? 60.0 : 74.0)) + 8.0;
    final target = (_currentPageIndex * cardW) - (screenW / 2) + (cardW / 2);
    _deckScrollController.animateTo(
      target.clamp(0.0, _deckScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _onVerticalScroll() {
    if (_readingMode != MangaReadingMode.webtoon ||
        _pageUrls.isEmpty ||
        _restoringWebtoon) {
      return;
    }

    final offset = _verticalScrollController.offset;
    final estimatedIndex = (offset / 900).floor().clamp(
      0,
      _pageUrls.length - 1,
    );

    if (estimatedIndex != _currentPageIndex) {
      setState(() => _currentPageIndex = estimatedIndex);
      _scheduleSaveProgress();
      _scrollToCurrentPageInDeck();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPageIndex = index);
    _scheduleSaveProgress();
    _scrollToCurrentPageInDeck();
  }

  void _jumpToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pageUrls.length) return;
    setState(() => _currentPageIndex = pageIndex);

    if (_readingMode == MangaReadingMode.webtoon) {
      if (_verticalScrollController.hasClients) {
        final targetOffset = pageIndex * 900.0;
        _verticalScrollController.animateTo(
          targetOffset.clamp(
            0.0,
            _verticalScrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    } else {
      if (_pageController?.hasClients ?? false) {
        _pageController!.jumpToPage(pageIndex);
      }
    }
    _scheduleSaveProgress();
    _scrollToCurrentPageInDeck();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
      if (!_showOverlay) _showDeckDrawer = false;
    });
    // The chrome is gone with its controls: hand focus back to the page so a
    // remote's keys keep turning it.
    if (!_showOverlay) _focusNode.requestFocus();
  }

  void _toggleDeckDrawer() {
    setState(() {
      _showDeckDrawer = !_showDeckDrawer;
    });
    if (_showDeckDrawer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentPageInDeck();
      });
    }
  }

  void _nextChapter() {
    if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
        _currentPageIndex = 0;
      });
      _loadChapter();
    }
  }

  void _prevChapter() {
    if (_currentChapterIndex < widget.chapters.length - 1) {
      setState(() {
        _currentChapterIndex++;
        _currentPageIndex = 0;
      });
      _loadChapter();
    }
  }

  /// Focus is on one of the chrome's controls rather than the page.
  bool get _chromeHasFocus =>
      _showOverlay && _focusNode.hasFocus && !_focusNode.hasPrimaryFocus;

  void _onFocusMoved() {
    if (mounted) setState(() {});
  }

  /// Hides the chrome and gives the page its keys back.
  void _hideChrome() {
    setState(() {
      _showOverlay = false;
      _showDeckDrawer = false;
    });
    _focusNode.requestFocus();
  }

  void _turnPage({required bool forward}) {
    // Nothing to turn while a chapter loads: the PageView is not there yet.
    if (_isLoading) return;
    final attached = _pageController?.hasClients ?? false;
    if (forward) {
      if (_currentPageIndex < _pageUrls.length - 1) {
        if (!attached) return;
        _pageController!.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      } else {
        _nextChapter();
      }
    } else {
      if (_currentPageIndex > 0) {
        if (!attached) return;
        _pageController!.previousPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      } else {
        _prevChapter();
      }
    }
  }

  void _scrollWebtoon(double direction) {
    if (!_verticalScrollController.hasClients) return;
    final p = _verticalScrollController.position;
    _verticalScrollController.animateTo(
      (p.pixels + direction * p.viewportDimension * 0.75).clamp(
        0.0,
        p.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// Keys on the page: the arrows (and Space) turn or scroll it, Select shows
  /// the controls and moves focus into them, Escape leaves. While a control
  /// has focus the arrows move between controls, and Escape hides them.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final onPage = _focusNode.hasPrimaryFocus;

    if (key == LogicalKeyboardKey.escape) {
      if (event is KeyRepeatEvent) return KeyEventResult.handled;
      if (_chromeHasFocus) {
        _hideChrome();
      } else {
        Navigator.of(context).pop();
      }
      return KeyEventResult.handled;
    }
    if (!onPage) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) {
        // Shown already (as on open): move into it rather than hide it.
        if (_showOverlay) {
          _chromeFocus.requestFocus();
        } else {
          _toggleOverlay();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _showOverlay) _chromeFocus.requestFocus();
          });
        }
      }
      return KeyEventResult.handled;
    }

    if (_readingMode == MangaReadingMode.webtoon) {
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.pageDown) {
        _scrollWebtoon(1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.pageUp) {
        _scrollWebtoon(-1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final rtl = _readingMode == MangaReadingMode.horizontalRtl;
    final forwardKey = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final backKey = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == forwardKey || key == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) _turnPage(forward: true);
      return KeyEventResult.handled;
    }
    if (key == backKey) {
      if (event is KeyDownEvent) _turnPage(forward: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _showReaderCustomizer(BuildContext context) {
    final l10n = l10nOf(context);
    showLuPanel<void>(
      context,
      title: l10n.mgReaderSettingsLayout,
      icon: Icons.tune_rounded,
      maxWidth: 520,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPanel) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LuSectionLabel(l10n.mgReadingOrientationMode),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in MangaReadingMode.values)
                  LuChoicePill(
                    label: mangaReadingModeLabel(l10n, mode),
                    selected: mode == _readingMode,
                    onTap: () {
                      setState(() => _readingMode = mode);
                      setPanel(() {});
                      MangaSettings.setDefaultReadingMode(mode);
                      _initPageController();
                      _restoreWebtoonPosition();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            LuSectionLabel(l10n.mgPageReadingWidthConstraint),
            const SizedBox(height: 10),
            ValueListenableBuilder<MangaReaderMaxWidth>(
              valueListenable: MangaSettings.readerMaxWidth,
              builder: (context, width, _) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in MangaReaderMaxWidth.values)
                    LuChoicePill(
                      label: mangaMaxWidthLabel(l10n, option),
                      selected: option == width,
                      onTap: () => MangaSettings.setReaderMaxWidth(option),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LuSectionLabel(l10n.mgReaderBackgroundAtmosphere),
            const SizedBox(height: 10),
            const MangaAtmosphereChips(showLabel: false),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: MangaSettings.showPageDeck,
              builder: (context, showDeck, _) => LuSwitchRow(
                label: l10n.mgShowPageDeckPreviewsDrawer,
                value: showDeck,
                onChanged: MangaSettings.setShowPageDeck,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: MangaSettings.enableNextChapterDeck,
              builder: (context, showNext, _) => LuSwitchRow(
                label: l10n.mgShowNextChapterDeckCard,
                value: showNext,
                onChanged: MangaSettings.setEnableNextChapterDeck,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final chapter = widget.chapters[_currentChapterIndex];
    final chapterTitle = chapter.name.isNotEmpty
        ? chapter.name
        : l10n.mg2CurrentChapterNumber(chapter.number);
    final readerBg = MangaSettings.readerBackground.value.color;

    return Theme(
      data: luTheme(),
      child: PopScope(
        // A remote's Back from the controls hides them first.
        canPop: !_chromeHasFocus,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _hideChrome();
        },
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            backgroundColor: readerBg,
            body: Stack(
              children: [
                // Main Interactive Zoom & Pan Reader Container
                GestureDetector(
                  onTap: _toggleOverlay,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: LuColors.gold,
                          ),
                        )
                      : _pageUrls.isEmpty
                      ? LuEmptyState(
                          icon: Icons.image_not_supported_outlined,
                          title: l10n.mgNoPagesFoundForThisChapter,
                        )
                      : InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.25,
                          maxScale: 5.0,
                          panEnabled: true,
                          scaleEnabled: true,
                          clipBehavior: Clip.none,
                          onInteractionUpdate: (_) {
                            final s = _transformationController.value
                                .getMaxScaleOnAxis();
                            if ((s - _currentZoom).abs() > 0.05) {
                              setState(() => _currentZoom = s);
                            }
                          },
                          child: _readingMode == MangaReadingMode.webtoon
                              ? _buildVerticalWebtoonReader()
                              : _buildHorizontalPageView(),
                        ),
                ),

                // Custom Vertical Scroller for Webtoon Mode (desktop only)
                if (_readingMode == MangaReadingMode.webtoon &&
                    !_isLoading &&
                    _pageUrls.isNotEmpty &&
                    MangaSettings.showScrollTrack.value &&
                    !(Platform.isAndroid || Platform.isIOS) &&
                    MediaQuery.sizeOf(context).width >= 700)
                  Positioned(
                    right: 20,
                    top: 100,
                    bottom: 100,
                    child: Center(
                      child: CustomScrollTrack(
                        controller: _verticalScrollController,
                        axis: Axis.vertical,
                        length: 320.0,
                      ),
                    ),
                  ),

                if (_showOverlay)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildTopBar(chapterTitle),
                  ),

                if (_showOverlay)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomBar(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageImage(String url, {required BoxFit fit, double? placeholder}) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppImageCache.manager,
      // 2x screen width stays crisp under the 5x zoom while bounding the
      // decode.
      memCacheWidth: (MediaQuery.sizeOf(context).width * 2)
          .round()
          .clamp(96, 2048)
          .toInt(),
      fit: fit,
      placeholder: (context, url) => SizedBox(
        height: placeholder,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: LuColors.textFaint,
          ),
        ),
      ),
      errorWidget: (context, url, error) => SizedBox(
        height: placeholder == null ? null : 200,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: LuColors.textFaint,
            size: 48,
          ),
        ),
      ),
    );
  }

  // 1. Horizontal Reading Mode (LTR & RTL)
  Widget _buildHorizontalPageView() {
    final maxWidth = MangaSettings.readerMaxWidth.value.width;
    final isRtl = _readingMode == MangaReadingMode.horizontalRtl;

    return PageView.builder(
      controller: _pageController,
      reverse: isRtl,
      physics: _currentZoom > 1.05
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      itemCount: _pageUrls.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
            child: _pageImage(_pageUrls[index], fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  // 2. Vertical Webtoon Continuous Scroll Mode
  Widget _buildVerticalWebtoonReader() {
    final maxWidth = MangaSettings.readerMaxWidth.value.width;
    final pageGap = MangaSettings.pageGap.value;
    final showNextDeck = MangaSettings.enableNextChapterDeck.value;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: ListView.builder(
          controller: _verticalScrollController,
          physics: _currentZoom > 1.05
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          itemCount: _pageUrls.length + 1,
          itemBuilder: (context, index) {
            if (index == _pageUrls.length) {
              if (!showNextDeck) {
                return const SizedBox(height: 80);
              }
              return _buildNextChapterDeckCard();
            }

            return Container(
              margin: EdgeInsets.only(bottom: pageGap),
              child: _pageImage(
                _pageUrls[index],
                fit: BoxFit.fitWidth,
                placeholder: 350,
              ),
            );
          },
        ),
      ),
    );
  }

  // 3. Next Chapter card (at the end of a webtoon chapter)
  Widget _buildNextChapterDeckCard() {
    final l10n = l10nOf(context);
    final hasNext = _currentChapterIndex > 0;
    final nextChapter = hasNext
        ? widget.chapters[_currentChapterIndex - 1]
        : null;
    final nextTitle = nextChapter != null
        ? (nextChapter.name.isNotEmpty
              ? nextChapter.name
              : l10n.mg2NextChapterNumber(nextChapter.number))
        : l10n.mgYouAreAllCaughtUp;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LuColors.surface,
        borderRadius: LuRadius.card,
        border: Border.all(color: LuColors.lineSoft),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LuBadge(hasNext ? l10n.mgUpNext : l10n.mgChapterFinished),
          const SizedBox(height: 14),
          Text(
            nextTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: LuText.heading,
          ),
          const SizedBox(height: 6),
          Text(
            widget.manga.title,
            textAlign: TextAlign.center,
            style: LuText.bodySoft,
          ),
          const SizedBox(height: 22),
          if (hasNext)
            LuButton(
              label: l10n.mgReadNextChapter,
              icon: Icons.skip_next_rounded,
              onPressed: _nextChapter,
            )
          else
            LuButton(
              label: l10n.mgBackToMangaDetails,
              icon: Icons.check_circle_outline_rounded,
              kind: LuButtonKind.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  // 4. Page deck: thumbnails directly above the slider.
  Widget _buildPageDeckSection(bool isMobile, bool isVerySmall) {
    final l10n = l10nOf(context);
    final cardWidth = isVerySmall ? 54.0 : (isMobile ? 62.0 : 74.0);
    final cardHeight = isVerySmall ? 78.0 : (isMobile ? 88.0 : 104.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 10 : 16,
        10,
        isMobile ? 10 : 16,
        6,
      ),
      decoration: BoxDecoration(
        color: LuColors.glass,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        border: Border.all(color: LuColors.glassEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.view_carousel_rounded,
                color: LuColors.gold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.mgPageDeckPreview,
                  style: LuText.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              LuBadge(
                l10n.mg2ReaderPageOfTotal(
                  _currentPageIndex + 1,
                  _pageUrls.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: cardHeight + 8,
            child: ListView.builder(
              controller: _deckScrollController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _pageUrls.length,
              itemBuilder: (context, index) {
                final isCurrent = index == _currentPageIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: LuFocusable(
                    onTap: () => _jumpToPage(index),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    semanticLabel: '${index + 1}',
                    builder: (context, hi) => AnimatedContainer(
                      duration: LuMotion.focus,
                      width: cardWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        color: LuColors.surfaceHigh,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        border: Border.all(
                          color: isCurrent ? LuColors.gold : LuColors.line,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(7),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: _pageUrls[index],
                              cacheManager: AppImageCache.manager,
                              fit: BoxFit.cover,
                              memCacheWidth: 140,
                              placeholder: (_, __) =>
                                  const ColoredBox(color: LuColors.surfaceHigh),
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: LuColors.textFaint,
                                  size: 18,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? LuColors.gold
                                        : const Color(0xB30A0A0C),
                                    borderRadius: LuRadius.pill,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: LuText.caption.copyWith(
                                      fontSize: 11,
                                      height: 1.3,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrent
                                          ? LuColors.onGold
                                          : LuColors.text,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double get _tapTarget => FormFactorService.of(context) == FormFactor.compact
      ? 40.0
      : kMinInteractiveDimension;

  // Top chrome: a downward scrim with back, the title and the settings disc.
  Widget _buildTopBar(String title) {
    final l10n = l10nOf(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12 + topInset, 16, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE60A0A0C), Color(0x000A0A0C)],
        ),
      ),
      child: Row(
        children: [
          LuGlyphButton(
            icon: Icons.arrow_back_ios_new_rounded,
            label: l10n.mgBack,
            size: _tapTarget,
            iconSize: 18,
            focusNode: _chromeFocus,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.manga.title,
                  style: LuText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    shadows: const [luGlyphShadow],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuText.caption.copyWith(
                    color: LuColors.textSoft,
                    shadows: const [luGlyphShadow],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          LuGlyphButton(
            icon: Icons.tune_rounded,
            label: l10n.mgReaderCustomization,
            size: _tapTarget,
            onTap: () => _showReaderCustomizer(context),
          ),
        ],
      ),
    );
  }

  // Bottom chrome: the deck, the page slider, then chapter, zoom and page.
  Widget _buildBottomBar() {
    final l10n = l10nOf(context);
    final showScrubber = MangaSettings.showPageScrubber.value;
    final showDeckToggle = MangaSettings.showPageDeck.value;
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 600;
    final isVerySmall = screenW < 420;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final tapTarget = _tapTarget;
    final zoomed = (_currentZoom - 1.0).abs() > 0.03;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        28,
        isMobile ? 12 : 24,
        12 + bottomInset,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x000A0A0C), Color(0xE60A0A0C)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showDeckDrawer && _pageUrls.isNotEmpty)
            _buildPageDeckSection(isMobile, isVerySmall),

          if (showScrubber && _pageUrls.isNotEmpty)
            SliderTheme(
              data: const SliderThemeData(
                activeTrackColor: LuColors.gold,
                inactiveTrackColor: Color(0x33FFFFFF),
                thumbColor: LuColors.gold,
                overlayColor: Color(0x33F2B544),
                trackHeight: 4,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: _currentPageIndex.toDouble().clamp(
                  0.0,
                  (_pageUrls.length - 1).toDouble(),
                ),
                min: 0.0,
                max: (_pageUrls.length - 1).toDouble(),
                divisions: _pageUrls.length > 1 ? _pageUrls.length - 1 : 1,
                onChanged: (val) {
                  _jumpToPage(val.round());
                },
              ),
            ),

          FocusTraversalGroup(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LuGlyphButton(
                  icon: Icons.skip_previous_rounded,
                  label: l10n.mgPreviousChapter,
                  size: tapTarget,
                  iconSize: 22,
                  onTap: _currentChapterIndex < widget.chapters.length - 1
                      ? _prevChapter
                      : null,
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isVerySmall) ...[
                        LuGlyphButton(
                          icon: Icons.zoom_out_rounded,
                          label: l10n.mgZoomOut,
                          size: tapTarget,
                          iconSize: 18,
                          filled: false,
                          onTap: _currentZoom > 0.26 ? _zoomOut : null,
                        ),
                        LuFocusable(
                          onTap: _resetZoom,
                          semanticLabel: '${(_currentZoom * 100).round()}%',
                          builder: (_, hi) => Container(
                            height: tapTarget,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            child: Text(
                              '${(_currentZoom * 100).round()}%',
                              style: LuText.label.copyWith(
                                fontFamily: LuFonts.display,
                                fontWeight: FontWeight.w700,
                                color: zoomed
                                    ? LuColors.gold
                                    : (hi ? LuColors.text : LuColors.textSoft),
                              ),
                            ),
                          ),
                        ),
                        LuGlyphButton(
                          icon: Icons.zoom_in_rounded,
                          label: l10n.mgZoomIn,
                          size: tapTarget,
                          iconSize: 18,
                          filled: false,
                          onTap: _currentZoom < 4.9 ? _zoomIn : null,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: LuColors.glass,
                          borderRadius: LuRadius.pill,
                          border: Border.all(color: LuColors.glassEdge),
                        ),
                        child: Text(
                          l10n.mg2ReaderPageSlashTotal(
                            _currentPageIndex + 1,
                            _pageUrls.isNotEmpty ? _pageUrls.length : '?',
                          ),
                          style: LuText.caption.copyWith(
                            fontSize: isVerySmall ? 11 : 13,
                            fontWeight: FontWeight.w700,
                            color: LuColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDeckToggle) ...[
                      LuGlyphButton(
                        icon: Icons.view_carousel_rounded,
                        label: l10n.mgTogglePageDeck,
                        size: tapTarget,
                        iconSize: 20,
                        active: _showDeckDrawer,
                        onTap: _toggleDeckDrawer,
                      ),
                      const SizedBox(width: 8),
                    ],
                    LuGlyphButton(
                      icon: Icons.skip_next_rounded,
                      label: l10n.mgNextChapter,
                      size: tapTarget,
                      iconSize: 22,
                      onTap: _currentChapterIndex > 0 ? _nextChapter : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
