import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../l10n/l10n.dart';
import '../../models/book/book_result.dart';
import '../../models/book/reading_progress.dart';
import '../../services/books/continue_reading_service.dart';
import '../../services/discord/discord_rpc_service.dart';
import '../../services/window/window_service.dart';
import '../../ui/lu_theme.dart';
import 'widgets/lu_reading_kit.dart';

/// A PDF, page by page, under a top bar (back, zoom, full screen) and a
/// bottom bar (pages and a slider) that fade away while reading.
class PdfReaderPage extends StatefulWidget {
  final File file;
  final BookResult book;
  final int initialPage;

  const PdfReaderPage({
    super.key,
    required this.file,
    required this.book,
    this.initialPage = 1,
  });

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  late final PdfViewerController _pdfController;
  final FocusNode _pageFocus = FocusNode(debugLabel: 'pdf reader page');
  final FocusNode _chromeFocus = FocusNode(debugLabel: 'pdf reader chrome');

  /// The top and bottom bars, as groups: focus inside one of them is a
  /// control's, wherever else it sits is the page's.
  final FocusNode _topBarGroup = FocusNode(
    debugLabel: 'pdf reader top bar',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final FocusNode _bottomBarGroup = FocusNode(
    debugLabel: 'pdf reader bottom bar',
    canRequestFocus: false,
    skipTraversal: true,
  );
  int _currentPage = 1;
  int _pageCount = 1;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pdfController = PdfViewerController();
    DiscordRpcService.instance.setReadingBook(
      title: widget.book.title,
      author: widget.book.author,
      coverUrl: widget.book.coverUrl,
      page: _currentPage,
    );
    _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _pageFocus.dispose();
    _chromeFocus.dispose();
    _topBarGroup.dispose();
    _bottomBarGroup.dispose();
    DiscordRpcService.instance.clearToIdle();
    super.dispose();
  }

  /// Focus is on one of the bars' controls rather than the page.
  bool get _chromeHasFocus => _topBarGroup.hasFocus || _bottomBarGroup.hasFocus;

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_showControls) return;
      // Never hide the bars from under a remote's focus.
      if (_chromeHasFocus) {
        _startControlsTimer();
        return;
      }
      setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startControlsTimer();
    } else if (_chromeHasFocus) {
      _pageFocus.requestFocus();
    }
  }

  void _hideControls() {
    _controlsTimer?.cancel();
    setState(() => _showControls = false);
    _pageFocus.requestFocus();
  }

  void _saveProgress(int page, int total) {
    if (total <= 0) return;
    final percent = (page / total).clamp(0.0, 1.0);

    final progress = ReadingProgress(
      md5: widget.book.md5,
      title: widget.book.displayTitle,
      author: widget.book.displayAuthor,
      coverUrl: widget.book.coverUrl,
      filePath: widget.file.path,
      fileType: 'pdf',
      chapterIndex: page - 1,
      scrollOffset: page.toDouble(),
      progressPercent: percent,
      totalChapters: total,
      totalPages: total,
      currentPage: page,
      lastReadAt: DateTime.now(),
    );

    ContinueReadingService.saveProgress(progress);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // While a control has focus the arrows move between controls, Select is
    // the control's, and Escape hides the bars.
    if (_chromeHasFocus) {
      if (key == LogicalKeyboardKey.escape) {
        _hideControls();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.pageDown) {
      if (_currentPage < _pageCount) {
        _pdfController.goToPage(pageNumber: _currentPage + 1);
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.pageUp) {
      if (_currentPage > 1) {
        _pdfController.goToPage(pageNumber: _currentPage - 1);
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      // A remote's Select shows the bars and moves into them.
      setState(() => _showControls = true);
      _startControlsTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showControls) _chromeFocus.requestFocus();
      });
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyF) {
      WindowService.instance.toggleFullscreen();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final percent = ((_currentPage / (_pageCount > 0 ? _pageCount : 1)) * 100)
        .round();

    return Theme(
      data: luTheme(),
      child: PopScope(
        // A remote's Back from the bars hides them first.
        canPop: !(_showControls && _chromeHasFocus),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _hideControls();
        },
        child: Focus(
          focusNode: _pageFocus,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          onFocusChange: (_) => setState(() {}),
          child: Scaffold(
            backgroundColor: LuColors.bg,
            body: Stack(
              children: [
                // ── PDF Viewer ──
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                    child: PdfViewer.file(
                      widget.file.path,
                      controller: _pdfController,
                      initialPageNumber: widget.initialPage,
                      params: PdfViewerParams(
                        backgroundColor: LuColors.surface,
                        // The page's own keys turn it; pdfrx's handler would
                        // take focus on every tap and drag and eat them.
                        keyHandlerParams: const PdfViewerKeyHandlerParams(
                          enabled: false,
                        ),
                        onPageChanged: (pageNumber) {
                          if (pageNumber != null) {
                            setState(() => _currentPage = pageNumber);
                            _saveProgress(pageNumber, _pageCount);
                          }
                        },
                        onViewerReady: (document, controller) {
                          setState(() {
                            _pageCount = document.pages.length;
                          });
                          _saveProgress(_currentPage, document.pages.length);
                        },
                      ),
                    ),
                  ),
                ),

                // ── Top bar ──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  top: _showControls ? 0 : -(96 + top),
                  left: 0,
                  right: 0,
                  child: ExcludeFocus(
                    excluding: !_showControls,
                    child: Focus(
                      focusNode: _topBarGroup,
                      onFocusChange: (_) => setState(() {}),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(16, top + 10, 16, 24),
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
                                label: l10n.bkBackToLibrary,
                                iconSize: 18,
                                focusNode: _chromeFocus,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.book.displayTitle,
                                      style: LuText.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      widget.book.displayAuthor,
                                      style: LuText.caption.copyWith(
                                        color: LuColors.textSoft,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              LuGlyphButton(
                                icon: Icons.zoom_in_rounded,
                                label: l10n.bkZoomIn,
                                onTap: () => _pdfController.zoomUp(),
                              ),
                              const SizedBox(width: 8),
                              LuGlyphButton(
                                icon: Icons.zoom_out_rounded,
                                label: l10n.bkZoomOut,
                                onTap: () => _pdfController.zoomDown(),
                              ),
                              const SizedBox(width: 8),
                              LuGlyphButton(
                                icon: Icons.fullscreen_rounded,
                                label: l10n.bkFullscreenF,
                                iconSize: 22,
                                onTap: () =>
                                    WindowService.instance.toggleFullscreen(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom bar ──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  bottom: _showControls ? 0 : -(120 + bottom),
                  left: 0,
                  right: 0,
                  child: ExcludeFocus(
                    excluding: !_showControls,
                    child: Focus(
                      focusNode: _bottomBarGroup,
                      onFocusChange: (_) => setState(() {}),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, bottom + 12),
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
                                label: l10n.bkPreviousPage,
                                iconSize: 26,
                                onTap: _currentPage > 1
                                    ? () => _pdfController.goToPage(
                                        pageNumber: _currentPage - 1,
                                      )
                                    : null,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              l10n.bk2PdfPageOfTotal(
                                                _currentPage,
                                                _pageCount,
                                              ),
                                              style: LuText.label.copyWith(
                                                color: LuColors.text,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$percent%',
                                            style: LuText.label.copyWith(
                                              color: LuColors.gold,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SliderTheme(
                                        data: const SliderThemeData(
                                          trackHeight: 4,
                                          thumbShape: RoundSliderThumbShape(
                                            enabledThumbRadius: 7,
                                          ),
                                          overlayShape: RoundSliderOverlayShape(
                                            overlayRadius: 14,
                                          ),
                                          activeTrackColor: LuColors.gold,
                                          inactiveTrackColor: Color(0x33FFFFFF),
                                          thumbColor: LuColors.gold,
                                          overlayColor: Color(0x33F2B544),
                                        ),
                                        child: Slider(
                                          value: _currentPage.toDouble().clamp(
                                            1.0,
                                            _pageCount > 1
                                                ? _pageCount.toDouble()
                                                : 1.0,
                                          ),
                                          min: 1,
                                          max: _pageCount > 1
                                              ? _pageCount.toDouble()
                                              : 1.0,
                                          divisions: _pageCount > 1
                                              ? _pageCount - 1
                                              : 1,
                                          onChanged: (val) {
                                            _pdfController.goToPage(
                                              pageNumber: val.round(),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              LuGlyphButton(
                                icon: Icons.chevron_right_rounded,
                                label: l10n.bkNextPage,
                                iconSize: 26,
                                onTap: _currentPage < _pageCount
                                    ? () => _pdfController.goToPage(
                                        pageNumber: _currentPage + 1,
                                      )
                                    : null,
                              ),
                            ],
                          ),
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
  }
}
