import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/movie/video.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';

/// The local day an episode airs, from its TMDb date, or null when TMDb has
/// none (an unknown date counts as out, so nothing playable is hidden).
DateTime? episodeAirDay(Video ep) {
  final raw = ep.released;
  if (raw == null || raw.length < 10) return null;
  final d = DateTime.tryParse(raw.substring(0, 10));
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

/// Whether [ep] is out: no date, or a date on or before today.
bool episodeIsOut(Video ep, {DateTime? now}) {
  final day = episodeAirDay(ep);
  if (day == null) return true;
  final n = now ?? DateTime.now();
  return !day.isAfter(DateTime(n.year, n.month, n.day));
}

/// `11月3日` / `Nov 3` in the viewer's language.
String episodeAirLabel(BuildContext context, DateTime day) =>
    DateFormat.MMMd(Localizations.localeOf(context).toString()).format(day);

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
        if (_summary(context) case final text?) ...[
          Text(text, style: LuText.caption.copyWith(color: LuColors.textMuted)),
          const SizedBox(height: 10),
        ],
        // As many columns of at least 64 as fit, each stretched to fill the
        // row, so the grid ends flush with the page instead of short of it.
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final w = constraints.maxWidth;
            final cols = ((w + gap) / (64 + gap)).floor().clamp(4, 12);
            // Each cell is drawn inside [LuFocusable]'s 2 px ring inset on
            // every side, so a cell occupies its width plus 4; floored so the
            // summed row never comes out a hair over and wraps the last cell.
            final cell = ((w - gap * (cols - 1)) / cols).floorToDouble() - 4;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final ep in shown)
                  _NumberCell(
                    width: cell,
                    airDay: episodeIsOut(ep) ? null : episodeAirDay(ep),
                    number: ep.shownNumber ?? 0,
                    watched: widget.isWatched?.call(ep) ?? false,
                    progress: widget.progressFor?.call(ep),
                    isCurrent:
                        widget.current != null &&
                        widget.current!.season == ep.season &&
                        widget.current!.episode == ep.episode,
                    onTap: () => widget.onTap(ep),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// 已更新至第 12 集 · 第 13 集 11月3日 上线, when some are not out yet.
  String? _summary(BuildContext context) {
    final eps = widget.episodes;
    final l10n = l10nOf(context);
    final watched = eps.where((e) => widget.isWatched?.call(e) ?? false).length;
    final upcoming = eps.where((e) => !episodeIsOut(e)).toList();
    final out = eps.where(episodeIsOut).toList();
    final parts = [
      if (watched > 0) l10n.epWatchedCount('$watched'),
      if (upcoming.isNotEmpty && out.isNotEmpty)
        l10n.epOutUpTo('${out.last.shownNumber ?? out.length}'),
      if (upcoming.isNotEmpty)
        if (episodeAirDay(upcoming.first) case final day?)
          l10n.epNextAirs(
            '${upcoming.first.shownNumber ?? ''}',
            episodeAirLabel(context, day),
          ),
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  String _rangeLabel(int page) {
    final eps = widget.episodes;
    final first = eps[page * EpisodeNumberGrid.pageSize].shownNumber ?? 0;
    final lastIndex = ((page + 1) * EpisodeNumberGrid.pageSize - 1).clamp(
      0,
      eps.length - 1,
    );
    final last = eps[lastIndex].shownNumber ?? 0;
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
    required this.width,
    required this.airDay,
    required this.number,
    required this.watched,
    required this.progress,
    required this.isCurrent,
    required this.onTap,
  });

  final double width;

  /// The day a not-yet-aired episode comes out; null once it is out.
  final DateTime? airDay;
  final int number;
  final bool watched;
  final double? progress;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final upcoming = airDay != null;
    return LuFocusable(
      onTap: onTap,
      semanticLabel: l10n.cwEpisode(number),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      builder: (context, hi) => Container(
        width: width,
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          // Not out yet: no fill, a faint outline, so the aired ones read
          // as the playable block at a glance.
          color: isCurrent
              ? const Color(0x29F2B544)
              : upcoming
              ? (hi ? const Color(0x0FFFFFFF) : Colors.transparent)
              : (hi ? LuColors.surfaceHigh : LuColors.surface),
          border: Border.all(
            color: isCurrent
                ? LuColors.gold
                : (upcoming ? const Color(0x1AFFFFFF) : LuColors.lineSoft),
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      fontFamily: LuFonts.display,
                      fontSize: (upcoming || watched || isCurrent) ? 15 : 18,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? LuColors.gold
                          : (watched || upcoming
                                ? LuColors.textFaint
                                : LuColors.text),
                    ),
                  ),
                  if (isCurrent && airDay == null)
                    Text(
                      l10n.epUpNextHere,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: LuColors.gold,
                      ),
                    )
                  else if (watched && airDay == null)
                    Text(
                      l10n.epWatchedTag,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: LuColors.textFaint,
                      ),
                    ),
                  if (airDay case final day?)
                    Text(
                      episodeAirLabel(context, day),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: LuColors.textFaint,
                      ),
                    ),
                ],
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
