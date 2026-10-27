import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/continue_watching/continue_watching_item.dart';
import '../../models/movie/movie.dart';
import '../../pages/details/details_page.dart';
import '../../services/metadata/metahub_art.dart';
import '../../services/storage/app_image_cache.dart';
import '../../services/theme/design_tokens.dart';
import '../../utils/navigation/route_transitions.dart';
import '../common/focusable_card.dart';

/// What a search result is, as the results page labels and filters it.
///
/// [series] and [movie] are what is left when TMDb could not say whether the
/// title is animated: the addon's own movie/series split, with no claim about
/// live action.
enum SearchKind {
  anime,
  animeMovie,
  liveSeries,
  series,
  movie;

  bool get isAnimation => this == anime || this == animeMovie;
  bool get isSeries => this == anime || this == liveSeries || this == series;

  /// [row] is the addon's result and [isAnimation] what TMDb said about it,
  /// null when TMDb was not asked or did not answer.
  static SearchKind of(Movie row, bool? isAnimation) {
    final isSeries =
        row.type == 'series' || row.type == 'tv' || row.type == 'anime';
    if (row.type == 'anime' || isAnimation == true) {
      return isSeries ? anime : animeMovie;
    }
    if (isAnimation == false && isSeries) return liveSeries;
    return isSeries ? series : movie;
  }

  String label(BuildContext context) {
    final l10n = l10nOf(context);
    return switch (this) {
      anime => l10n.searchKindAnime,
      animeMovie => l10n.searchKindAnimeMovie,
      liveSeries => l10n.searchKindLiveSeries,
      series => l10n.searchKindSeries,
      movie => l10n.searchKindMovie,
    };
  }
}

/// One search result: poster, a 动画 / 真人剧 / 电影 tag, the name, the year
/// and rating, and where the viewer stopped if they have started it.
///
/// Search used Home's 16:9 rail tiles, which carry no text until focused, so a
/// query like "Shin-chan" came back as a row of near-identical stills nobody
/// could tell apart. A search result has to be identifiable at rest: which of
/// several same-named titles it is, whether it is the animation or the live
/// action, and which year.
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.movie,
    required this.kind,
    this.localTitle,
    this.posterUrl,
    this.resume,
    this.compact = false,
  });

  final Movie movie;
  final SearchKind kind;

  /// The name in the viewer's language, shown above the addon's name when the
  /// two differ.
  final String? localTitle;

  /// A poster from elsewhere (TMDb) for a result whose source sent none.
  final String? posterUrl;

  /// The poster to draw: the source's, then [posterUrl], then the keyless
  /// metahub poster for an IMDb id.
  String? get _poster {
    final own = movie.poster;
    if (own != null && own.isNotEmpty) return own;
    if (posterUrl != null && posterUrl!.isNotEmpty) return posterUrl;
    return MetahubArt.isUsableId(movie.id)
        ? MetahubArt.posterUrl(movie.id)
        : null;
  }

  /// The viewer's unfinished session for this title, if any.
  final ContinueWatchingItem? resume;

  /// Phone width: a smaller poster and type.
  final bool compact;

  static double heightFor({required bool compact}) => compact ? 132 : 182;

  void _open(BuildContext context) {
    Navigator.push(
      context,
      CinematicSlideRoute(page: DetailsPage(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = l10nOf(context);
    final posterWidth = compact ? 72.0 : 100.0;
    final pad = compact ? ZplaySpacing.s12 : ZplaySpacing.s16;

    final local = localTitle?.trim();
    final hasLocal =
        local != null &&
        local.isNotEmpty &&
        local.toLowerCase() != movie.name.trim().toLowerCase();
    final title = hasLocal ? local : movie.name;

    final facts = <String>[
      if (movie.year != null && movie.year!.isNotEmpty) movie.year!,
      if (movie.imdbRating != null &&
          movie.imdbRating!.isNotEmpty &&
          movie.imdbRating != '0')
        '★ ${movie.imdbRating}',
    ];

    final kindColor = kind.isAnimation
        ? tokens.accent
        : (kind == SearchKind.liveSeries
              ? const Color(0xFF7CC4FF)
              : tokens.textSecondary);

    String? note;
    if (resume case final r?) {
      note = r.episode != null
          ? l10n.searchResumeEpisode(r.season ?? 1, r.episode!)
          : l10n.searchResumeMovie;
    }

    return FocusableCard(
      onTap: () => _open(context),
      builder: (context, state) => CardFocusRing(
        focused: state.focused,
        radius: ZplayRadius.mdAll,
        child: AnimatedContainer(
          duration: ZplayMotion.fast,
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: state.highlighted ? tokens.surfaceRaised : tokens.surface,
            borderRadius: ZplayRadius.mdAll,
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: ZplayRadius.smAll,
                child: SizedBox(
                  width: posterWidth,
                  height: posterWidth * 1.5,
                  child: _poster != null
                      ? CachedNetworkImage(
                          imageUrl: _poster!,
                          cacheManager: AppImageCache.manager,
                          memCacheWidth: 240,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _noPoster(context),
                        )
                      : _noPoster(context),
                ),
              ),
              SizedBox(width: pad),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: ZplayRadius.xsAll,
                        border: Border.all(color: kindColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ZplaySpacing.s8,
                          vertical: 1,
                        ),
                        child: Text(
                          kind.label(context),
                          style: ZplayType.caption
                              .copyWith(weight: FontWeight.w700)
                              .toStyle(color: kindColor),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? ZplaySpacing.s4 : ZplaySpacing.s8),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: (compact ? ZplayType.subtitle : ZplayType.title)
                          .copyWith(weight: FontWeight.w700, height: 1.25)
                          .toStyle(color: tokens.textPrimary),
                    ),
                    if (hasLocal)
                      Text(
                        movie.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZplayType.bodySmall.toStyle(
                          color: tokens.textMuted,
                        ),
                      ),
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: ZplaySpacing.s4),
                      Text(
                        facts.join(' · '),
                        style: ZplayType.bodySmall.toStyle(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (note != null)
                      Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZplayType.bodySmall.toStyle(
                          color: tokens.accent,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noPoster(BuildContext context) {
    final tokens = context.tokens;
    return ColoredBox(
      color: tokens.surfaceRaised,
      child: Center(
        child: Text(
          l10nOf(context).searchNoPoster,
          textAlign: TextAlign.center,
          style: ZplayType.caption.toStyle(color: tokens.textMuted),
        ),
      ),
    );
  }
}
