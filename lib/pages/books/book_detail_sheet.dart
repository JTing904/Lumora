import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/book/book_result.dart';
import '../../services/books/book_download_service.dart';
import '../../services/books/continue_reading_service.dart';
import '../../services/layout/device_profile.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_theme.dart';
import '../account/login_page.dart' show SignInRequired;
import '../audiobooks/generate_audiobook_screen.dart';
import 'epub_reader_page.dart';
import 'pdf_reader_page.dart';
import 'widgets/lu_reading_kit.dart';

class BookDetailSheet extends StatefulWidget {
  final BookResult book;

  const BookDetailSheet({super.key, required this.book});

  static Future<void> show(BuildContext context, BookResult book) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookDetailSheet(book: book),
    );
  }

  @override
  State<BookDetailSheet> createState() => _BookDetailSheetState();
}

class _BookDetailSheetState extends State<BookDetailSheet> {
  bool _isDownloaded = false;
  File? _downloadedFile;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _checkingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    File? downloaded;
    try {
      downloaded = await BookDownloadService.instance.getDownloadedBook(
        widget.book.md5,
        widget.book.bookFiletype,
      );
    } catch (e) {
      debugPrint('[BookDetailSheet] Could not check download status: $e');
    }
    if (!mounted) return;
    setState(() {
      _isDownloaded = downloaded != null;
      _downloadedFile = downloaded;
      _checkingStatus = false;
    });
  }

  Future<void> _startReadOrDownload() async {
    if (_isDownloaded && _downloadedFile != null) {
      _openReader(_downloadedFile!);
      return;
    }

    // Start download and open upon completion
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.01;
    });

    try {
      final file = await BookDownloadService.instance.downloadBook(
        widget.book,
        onProgress: (p) {
          if (mounted) {
            setState(() => _downloadProgress = p);
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _isDownloaded = file != null;
        _downloadedFile = file;
      });

      if (file != null) {
        _openReader(file);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10nOf(context).bk2FailedToDownloadBook(e)),
          backgroundColor: LuColors.danger,
        ),
      );
    }
  }

  void _openReader(File file) {
    Navigator.of(context).pop(); // Close sheet

    final progress = ContinueReadingService.getProgress(widget.book.md5);

    if (widget.book.isPdf) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PdfReaderPage(
            file: file,
            book: widget.book,
            initialPage: progress?.currentPage ?? 1,
          ),
        ),
      );
    } else {
      // EPUB, FB2, MOBI, AZW3, TXT, CBZ, LIT, LRF all open in universal reader
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => EpubReaderPage(
            file: file,
            book: widget.book,
            initialChapterIndex: progress?.chapterIndex ?? 0,
            initialScrollOffset: progress?.scrollOffset ?? 0.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final book = widget.book;
    final progress = ContinueReadingService.getProgress(book.md5);
    final hasProgress = progress != null && progress.progressPercent > 0;
    final phone = MediaQuery.sizeOf(context).width < 600;
    // The discs beside the read button match its height: LuButton is 44 tall
    // on a phone and 56 elsewhere, by the same test.
    final glyphSize =
        MediaQuery.sizeOf(context).shortestSide < 600 &&
            !DeviceProfile.isTelevision
        ? 44.0
        : 56.0;
    final facts = [
      book.bookFiletype.toUpperCase(),
      if (book.bookSize.isNotEmpty) book.bookSize,
      if (book.year.isNotEmpty) book.year,
      if (book.bookLang.isNotEmpty) book.bookLang,
    ].where((f) => f.isNotEmpty).toList();

    return LuSheetFrame(
      maxHeightFactor: 0.88,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                      child: SizedBox(
                        width: phone ? 112 : 136,
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: LuImage(
                            url: book.coverUrl,
                            cacheWidth: 420,
                            fallback: const Icon(
                              Icons.menu_book_rounded,
                              color: LuColors.textFaint,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.displayTitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: LuText.heading.copyWith(
                              fontSize: phone ? 20 : 24,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.displayAuthor,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: LuText.body.copyWith(
                              color: LuColors.textSoft,
                            ),
                          ),
                          if (facts.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (final f in facts) LuBadge(f, muted: true),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (hasProgress) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          progress.fileType == 'pdf'
                              ? l10n.bk2PageOfTotal(
                                  progress.currentPage,
                                  progress.totalPages,
                                )
                              : l10n.bk2ChapterOfTotal(
                                  progress.chapterIndex + 1,
                                  progress.totalChapters,
                                ),
                          style: LuText.label,
                        ),
                      ),
                      Text(
                        l10n.bk2PercentCompleted(
                          (progress.progressPercent * 100).round(),
                        ),
                        style: LuText.label.copyWith(
                          color: LuColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: LuRadius.pill,
                    child: LinearProgressIndicator(
                      value: progress.progressPercent,
                      backgroundColor: const Color(0x26FFFFFF),
                      color: LuColors.gold,
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                // The read action, then listening and the tidy-up as discs.
                Row(
                  children: [
                    Expanded(
                      child: LuButton(
                        label: _isDownloading
                            ? l10n.bk2DownloadingPercent(
                                (_downloadProgress * 100).round(),
                              )
                            : hasProgress
                            ? l10n.bkResumeReading
                            : l10n.bkReadNow,
                        icon: hasProgress
                            ? Icons.play_arrow_rounded
                            : Icons.auto_stories_rounded,
                        busy: _isDownloading,
                        expand: true,
                        autofocus: true,
                        onPressed: _checkingStatus
                            ? null
                            : _startReadOrDownload,
                      ),
                    ),
                    if (book.isEpub) ...[
                      const SizedBox(width: 12),
                      LuGlyphButton(
                        icon: Icons.record_voice_over_rounded,
                        label: l10n.bkGenerateAiAudiobookTts,
                        size: glyphSize,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignInRequired(
                                child: GenerateAudiobookScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (_isDownloaded) ...[
                      const SizedBox(width: 12),
                      LuGlyphButton(
                        icon: Icons.delete_outline_rounded,
                        label: l10n.bkDeleteDownloadedFile,
                        size: glyphSize,
                        danger: true,
                        onTap: () async {
                          await BookDownloadService.instance.deleteBook(
                            book.md5,
                            book.bookFiletype,
                          );
                          _checkDownloadStatus();
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 28),

                if (book.publisher.isNotEmpty ||
                    book.isbn.isNotEmpty ||
                    book.series.isNotEmpty) ...[
                  Text(l10n.bk2Information, style: LuText.heading),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: LuColors.surfaceHigh,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      border: Border.all(color: LuColors.lineSoft),
                    ),
                    child: Column(
                      children: [
                        if (book.publisher.isNotEmpty)
                          _buildInfoRow(l10n.bkPublisher, book.publisher),
                        if (book.series.isNotEmpty)
                          _buildInfoRow(l10n.bkSeries, book.series),
                        if (book.isbn.isNotEmpty)
                          _buildInfoRow('ISBN', book.isbn),
                        if (book.bookLang.isNotEmpty)
                          _buildInfoRow(l10n.bkLanguage, book.bookLang),
                        _buildInfoRow(
                          l10n.bkFileFormat,
                          book.bookFiletype.toUpperCase(),
                        ),
                        if (book.bookSize.isNotEmpty)
                          _buildInfoRow(l10n.bkSize, book.bookSize),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (book.description.isNotEmpty) ...[
                  Text(l10n.bk2Overview, style: LuText.heading),
                  const SizedBox(height: 10),
                  LuExpandableText(book.description, lines: 6),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: LuText.label.copyWith(color: LuColors.textMuted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: LuText.label.copyWith(color: LuColors.text),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
