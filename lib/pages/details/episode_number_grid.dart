import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/movie/video.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';

/// 选集 for a long season: the episode numbers as a grid, thirty to a page.
///
/// A 40-episode 国产剧 as a row of 300 px cards is a long sideways scroll to
/// reach episode 38; as numbers it is one glance. Watched episodes are dimmed,
/// the one in progress carries its progress, and the one to play next is
/// marked, and the page holding it opens first.
class EpisodeNumberGrid extends StatefulWidget {
  const EpisodeNumberGrid({
    super.key,
    required this.episodes,
    required this.onTap,
    this.isWatched,
    this.progressFor,
    this.current,
  });

  /// One season's episodes, in order.
  final List<Video> episodes;
  final ValueChanged<Video> onTap;
  final bool Function(Video)? isWatched;

  /// How far into an episode the viewer is, 0..1, or null.
  final double? Function(Video)? progressFor;

  /// The episode the primary action would play.
  final Video? current;

  static const int pageSize = 30;

  @override
  State<EpisodeNumberGrid> createState() => _EpisodeNumberGridState();
}

class _EpisodeNumberGridState extends State<EpisodeNumberGrid> {
  late int _page = _pageOf(widget.current);

  int _pageOf(Video? ep) {
    if (ep == null) return 0;
    final i = widget.episodes.indexWhere(
      (v) => v.season == ep.season && v.episode == ep.episode,
    );
    return i < 0 ? 0 : i ~/ EpisodeNumberGrid.pageSize;
  }

  @override
  void didUpdateWidget(EpisodeNumberGrid old) {
    super.didUpdateWidget(old);
    if (old.episodes != widget.episodes) _page = _pageOf(widget.current);
  }

  @override
  Widget build(BuildContext context) {
    final eps = widget.episodes;
    final pages = (eps.length / EpisodeNumberGrid.pageSize).ceil();
    final start = _page * EpisodeNumberGrid.pageSize;
    final shown = eps.skip(start).take(EpisodeNumberGrid.pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pages > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var p = 0; p < pages; p++)
                _RangeTab(
                  label: _rangeLabel(p),
                  selected: p == _page,
                  onTap: () => setState(() => _page = p),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ep in shown)
              _NumberCell(
                number: ep.episode ?? 0,
                watched: widget.isWatched?.call(ep) ?? false,
                progress: widget.progressFor?.call(ep),
                isCurrent:
                    widget.current != null &&
                    widget.current!.season == ep.season &&
                    widget.current!.episode == ep.episode,
                onTap: () => widget.onTap(ep),
              ),
          ],
        ),
      ],
    );
  }

  String _rangeLabel(int page) {
    final eps = widget.episodes;
    final first = eps[page * EpisodeNumberGrid.pageSize].episode ?? 0;
    final lastIndex = ((page + 1) * EpisodeNumberGrid.pageSize - 1).clamp(
      0,
      eps.length - 1,
    );
    final last = eps[lastIndex].episode ?? 0;
    return '$first-$last';
  }
}

class _RangeTab extends StatelessWidget {
  const _RangeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: LuRadius.pill,
            color: selected
                ? LuColors.text
                : (hi ? const Color(0x1FFFFFFF) : Colors.transparent),
            border: selected ? null : Border.all(color: LuColors.line),
          ),
          // Sized to the label: a Wrap's loose width would stretch it.
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: LuText.label.copyWith(
                fontFamily: LuFonts.display,
                color: selected ? LuColors.bg : LuColors.textSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberCell extends StatelessWidget {
  const _NumberCell({
    required this.number,
    required this.watched,
    required this.progress,
    required this.isCurrent,
    required this.onTap,
  });

  final int number;
  final bool watched;
  final double? progress;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return LuFocusable(
      onTap: onTap,
      semanticLabel: l10n.cwEpisode(number),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      builder: (context, hi) => Container(
        width: 64,
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: isCurrent
              ? const Color(0x29F2B544)
              : (hi ? LuColors.surfaceHigh : LuColors.surface),
          border: Border.all(
            color: isCurrent ? LuColors.gold : LuColors.lineSoft,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontFamily: LuFonts.display,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isCurrent
                      ? LuColors.gold
                      : (watched ? LuColors.textFaint : LuColors.text),
                ),
              ),
            ),
            if (watched)
              const Positioned(
                top: 3,
                right: 4,
                child: Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: LuColors.textFaint,
                ),
              ),
            if (progress case final p? when p > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: p.clamp(0.0, 1.0),
                  minHeight: 3,
                  color: LuColors.gold,
                  backgroundColor: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
