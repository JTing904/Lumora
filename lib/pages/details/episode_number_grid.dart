import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/movie/video.dart';
import '../../services/theme/design_tokens.dart';
import '../../widgets/common/focusable_card.dart';

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
    final tokens = context.tokens;
    final eps = widget.episodes;
    final pages = (eps.length / EpisodeNumberGrid.pageSize).ceil();
    final start = _page * EpisodeNumberGrid.pageSize;
    final shown = eps.skip(start).take(EpisodeNumberGrid.pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pages > 1) ...[
          Wrap(
            spacing: ZplaySpacing.s8,
            runSpacing: ZplaySpacing.s8,
            children: [
              for (var p = 0; p < pages; p++)
                _RangeTab(
                  label: _rangeLabel(p),
                  selected: p == _page,
                  onTap: () => setState(() => _page = p),
                ),
            ],
          ),
          const SizedBox(height: ZplaySpacing.s12),
        ],
        Wrap(
          spacing: ZplaySpacing.s8,
          runSpacing: ZplaySpacing.s8,
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
                tokens: tokens,
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
    final tokens = context.tokens;
    return Semantics(
      selected: selected,
      child: FocusableCard(
        onTap: onTap,
        builder: (_, state) => CardFocusRing(
          focused: state.focused,
          radius: ZplayRadius.fullAll,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: ZplaySpacing.s12),
            decoration: BoxDecoration(
              borderRadius: ZplayRadius.fullAll,
              color: selected
                  ? tokens.accent.withValues(alpha: 0.18)
                  : (state.highlighted ? tokens.surface : Colors.transparent),
            ),
            // Sized to the label: a Wrap's loose width would stretch it.
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: ZplayType.label.toStyle(
                  color: selected ? tokens.accent : tokens.textSecondary,
                  tabular: true,
                ),
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
    required this.tokens,
  });

  final int number;
  final bool watched;
  final double? progress;
  final bool isCurrent;
  final VoidCallback onTap;
  final ZplayTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Semantics(
      button: true,
      label: l10n.cwEpisode(number),
      child: FocusableCard(
        onTap: onTap,
        builder: (_, state) => CardFocusRing(
          focused: state.focused,
          radius: ZplayRadius.smAll,
          child: AnimatedScale(
            scale: state.highlighted ? 1.05 : 1.0,
            duration: ZplayMotion.fast,
            child: Container(
              width: 64,
              height: 48,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: ZplayRadius.smAll,
                color: isCurrent
                    ? tokens.accent.withValues(alpha: 0.18)
                    : tokens.surface.withValues(alpha: 0.7),
                border: Border.all(
                  color: isCurrent ? tokens.accent : tokens.borderSubtle,
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '$number',
                      style: ZplayType.subtitle.toStyle(
                        color: isCurrent
                            ? tokens.accent
                            : (watched ? tokens.textMuted : tokens.textPrimary),
                        tabular: true,
                      ),
                    ),
                  ),
                  if (watched)
                    Positioned(
                      top: 3,
                      right: 4,
                      child: Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: tokens.textMuted,
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
                        color: tokens.accent,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
