import '../../l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../models/audiobook/audiobook_model.dart';
import '../../services/audiobook/audiobook_scraper_service.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_theme.dart';
import '../../widgets/common/error_view.dart';
import '../music/lu_media_kit.dart';
import 'audiobook_lu_labels.dart';
import 'audiobook_player_screen.dart';
import 'audiobook_route_transitions.dart';

/// One audiobook: its cover over a blurred copy of itself, the title, the way
/// into the player, and the chapters.
class AudiobookDetailPage extends StatelessWidget {
  final Audiobook audiobook;
  final String? heroTag;

  const AudiobookDetailPage({super.key, required this.audiobook, this.heroTag});

  @override
  Widget build(BuildContext context) => Theme(
    data: luMediaTheme(),
    child: _AudiobookDetailBody(audiobook: audiobook, heroTag: heroTag),
  );
}

class _AudiobookDetailBody extends StatefulWidget {
  final Audiobook audiobook;
  final String? heroTag;

  const _AudiobookDetailBody({required this.audiobook, this.heroTag});

  @override
  State<_AudiobookDetailBody> createState() => _AudiobookDetailPageState();
}

class _AudiobookDetailPageState extends State<_AudiobookDetailBody> {
  List<AudiobookChapter>? _chapters;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final chapters = await AudiobookScraperService.instance.getChapters(
        widget.audiobook,
      );
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = l10nCurrent().abk2FailedToLoadChapters(e);
        });
      }
    }
  }

  void _playChapter(AudiobookChapter chapter) {
    if (_chapters == null || _chapters!.isEmpty) return;
    final initialIndex = _chapters!
        .indexOf(chapter)
        .clamp(0, _chapters!.length - 1);

    Navigator.push(
      context,
      AudiobookPageRoute(
        page: AudiobookPlayerScreen(
          audiobook: widget.audiobook,
          chapters: _chapters!,
          initialChapterIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final book = widget.audiobook;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    final pad = luMediaPad(context);

    return Scaffold(
      backgroundColor: LuColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: LuMediaBackdrop(
              url: book.coverImage,
              httpHeaders: abkCoverHeaders,
              opacity: 0.5,
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, topInset + 14, pad, 8),
                  child: Row(
                    children: [
                      LuMediaIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: l10n.abkBackTip,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: LuSpace.m),
                      Expanded(
                        child: Text(
                          l10n.abkAudiobookDetails,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuText.label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildCoverImage(book, 200),
                            const SizedBox(height: LuSpace.l),
                            _buildDetails(book, isMobile),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildCoverImage(book, 260),
                            const SizedBox(width: LuSpace.xl),
                            Expanded(child: _buildDetails(book, isMobile)),
                          ],
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: LuMediaSectionTitle(
                    title: l10n.abkChaptersAudioFiles,
                    count: _chapters?.length,
                  ),
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    title: l10n.abkCouldNotLoadChapters,
                    error: _error,
                    onRetry: _fetchChapters,
                  ),
                )
              else if (_chapters == null || _chapters!.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      l10n.abkNoPlayableChaptersFound,
                      style: LuText.bodySoft,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pad,
                    0,
                    pad,
                    LuSpace.xxl + bottomInset,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final chapter = _chapters![index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ChapterTile(
                          chapter: chapter,
                          number: index + 1,
                          onTap: () => _playChapter(chapter),
                        ),
                      );
                    }, childCount: _chapters!.length),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(Audiobook book, double size) {
    Widget art = LuMediaArt(
      url: book.coverImage,
      cacheWidth: (size * 2.5).round(),
      icon: Icons.headphones_rounded,
      httpHeaders: abkCoverHeaders,
    );
    if (widget.heroTag != null) art = Hero(tag: widget.heroTag!, child: art);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        borderRadius: LuRadius.card,
        boxShadow: [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 36,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: LuRadius.card, child: art),
    );
  }

  Widget _buildDetails(Audiobook book, bool isMobile) {
    final l10n = l10nOf(context);
    final isTorrent = book.source.toLowerCase().contains('audiobookbay');
    final author = (book.author ?? '').trim();

    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        LuBadge(isTorrent ? l10n.abkTorrentSource : book.source),
        const SizedBox(height: LuSpace.m),
        Text(
          book.title,
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: LuText.title.copyWith(
            fontSize: isMobile ? 26 : 40,
            height: 1.15,
          ),
        ),
        if (author.isNotEmpty) ...[
          const SizedBox(height: LuSpace.s),
          Text(
            author,
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
            style: LuText.body.copyWith(color: LuColors.textMuted),
          ),
        ],
        const SizedBox(height: LuSpace.l),
        if (_chapters != null && _chapters!.isNotEmpty)
          LuButton(
            label: l10n.abkPlayFirstChapter,
            icon: Icons.play_arrow_rounded,
            autofocus: true,
            compact: isMobile,
            onPressed: () => _playChapter(_chapters!.first),
          ),
      ],
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final AudiobookChapter chapter;
  final int number;
  final VoidCallback onTap;

  const _ChapterTile({
    required this.chapter,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LuMediaTile(
      onTap: onTap,
      radius: const BorderRadius.all(Radius.circular(16)),
      lift: 1.01,
      semanticLabel: chapter.title,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '$number',
              style: LuText.label.copyWith(
                color: LuColors.textFaint,
                fontFamily: LuFonts.display,
              ),
            ),
          ),
          Expanded(
            child: Text(
              chapter.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LuText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: LuSpace.m),
          const Icon(
            Icons.play_circle_fill_rounded,
            color: LuColors.gold,
            size: 30,
          ),
        ],
      ),
    );
  }
}
