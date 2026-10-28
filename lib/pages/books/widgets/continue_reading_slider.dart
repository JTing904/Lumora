import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/book/book_result.dart';
import '../../../models/book/reading_progress.dart';
import '../../../services/books/continue_reading_service.dart';
import '../../../ui/lu_cards.dart';
import '../epub_reader_page.dart';
import '../pdf_reader_page.dart';
import 'lu_reading_kit.dart';

/// 继续阅读 for books: a rail of the covers being read, each with how far
/// along the reader is. Nothing at all while nothing is being read.
class ContinueReadingSlider extends StatelessWidget {
  const ContinueReadingSlider({
    super.key,
    this.title,
    this.padding = 24,
    this.coverWidth = 140,
  });

  /// The rail's heading; 继续阅读 by default.
  final String? title;

  /// The page's side margin.
  final double padding;
  final double coverWidth;

  void _openReader(BuildContext context, ReadingProgress item) {
    final file = File(item.filePath);
    final book = BookResult(
      title: item.title,
      author: item.author,
      md5: item.md5,
      link: '',
      bookImage: item.coverUrl,
      bookFiletype: item.fileType,
    );

    if (item.fileType == 'pdf') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PdfReaderPage(
            file: file,
            book: book,
            initialPage: item.currentPage,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => EpubReaderPage(
            file: file,
            book: book,
            initialChapterIndex: item.chapterIndex,
            initialScrollOffset: item.scrollOffset,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ReadingProgress>>(
      valueListenable: ContinueReadingService.activeItems,
      builder: (context, items, _) {
        if (items.isEmpty) return const SizedBox.shrink();
        final l10n = l10nOf(context);
        final scaler = MediaQuery.textScalerOf(context);

        return Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: LuRail(
            title: title ?? l10n.mgContinueReading,
            padding: padding,
            height: LuCoverContinueCard.heightFor(coverWidth, scaler) + 8,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final percent = (item.progressPercent * 100).round();
              final author = item.author.trim();
              // "Frank Herbert · 64% read"; without an author, where in the
              // book the reader is.
              final position = item.fileType == 'pdf'
                  ? l10n.bk2PageNumber(item.currentPage)
                  : l10n.booksChapterShort('${item.chapterIndex + 1}');
              return LuCoverContinueCard(
                width: coverWidth,
                title: item.title,
                cover: item.coverUrl,
                progress: item.progressPercent,
                badge: item.fileType.isEmpty
                    ? null
                    : item.fileType.toUpperCase(),
                caption: author.isNotEmpty
                    ? l10n.bk2SliderAuthorPercentRead(author, percent)
                    : l10n.bk2SliderPositionPercentRead(position, percent),
                onTap: () => _openReader(context, item),
                onRemove: () => ContinueReadingService.removeProgress(item.md5),
                removeLabel: l10n.mgRemoveFromContinueReading,
              );
            },
          ),
        );
      },
    );
  }
}
