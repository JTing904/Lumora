import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../models/addon/addon.dart';
import '../../models/movie/movie.dart';
import '../../models/movie/movie_section.dart';
import '../../models/my_list/my_list_item.dart';
import '../../services/layout/form_factor.dart';
import '../../services/metadata/tmdb_catalog.dart';
import '../../services/my_list/my_list_service.dart';
import '../../services/playback/play_launcher.dart';
import '../../services/storage/app_image_cache.dart';
import '../../services/theme/design_tokens.dart';
import '../../shell/app_shell_scope.dart';
import '../../widgets/common/pill_button.dart';
import '../../widgets/common/rail_skeleton.dart';
import '../../widgets/movie/movie_card.dart';
import '../../widgets/movie/movie_slider_section.dart';
import 'category_filter.dart';

/// What a category page lists.
enum CategoryKind { series, movies, anime }

/// One row of a category page: its title and the TMDb list behind it.
class _RowSpec {
  const _RowSpec(this.title, this.query);

  final String Function(AppLocalizations l10n) title;
  final TmdbQuery query;
}

List<_RowSpec> _rowsFor(CategoryKind kind) => switch (kind) {
  CategoryKind.series => [
    _RowSpec((l) => l.catTrendingSeries, const TmdbQuery('/trending/tv/week', {}, true)),
    _RowSpec((l) => l.catRecentlyUpdated, TmdbQuery.recentlyUpdated(series: true, animated: false)),
    _RowSpec((l) => l.catCnDrama, TmdbQuery.discover(series: true, region: 'CN', animated: false)),
    _RowSpec((l) => l.catHkDrama, TmdbQuery.discover(series: true, region: 'HK', animated: false, minVotes: 5)),
    _RowSpec((l) => l.catKrDrama, TmdbQuery.discover(series: true, region: 'KR', animated: false)),
    _RowSpec((l) => l.catUsDrama, TmdbQuery.discover(series: true, region: 'US', animated: false)),
    _RowSpec((l) => l.catTwDrama, TmdbQuery.discover(series: true, region: 'TW', animated: false, minVotes: 5)),
    _RowSpec((l) => l.catJpDrama, TmdbQuery.discover(series: true, region: 'JP', animated: false)),
    _RowSpec((l) => l.catGbDrama, TmdbQuery.discover(series: true, region: 'GB', animated: false)),
    _RowSpec((l) => l.catTopSeries, TmdbQuery.discover(series: true, animated: false, sortBy: 'vote_average.desc', minVotes: 300)),
  ],
  CategoryKind.movies => [
    _RowSpec((l) => l.catTrendingMovies, const TmdbQuery('/trending/movie/week', {}, true)),
    _RowSpec((l) => l.catRecentlyUpdated, TmdbQuery.recentlyUpdated(series: false)),
    _RowSpec((l) => l.catNowPlaying, const TmdbQuery('/movie/now_playing')),
    _RowSpec((l) => l.catChineseMovies, TmdbQuery.discover(series: false, language: 'zh', animated: false)),
    _RowSpec((l) => l.catHkMovies, TmdbQuery.discover(series: false, region: 'HK', animated: false)),
    _RowSpec((l) => l.catUsMovies, TmdbQuery.discover(series: false, region: 'US', animated: false)),
    _RowSpec((l) => l.catKrMovies, TmdbQuery.discover(series: false, region: 'KR', animated: false)),
    _RowSpec((l) => l.catJpMovies, TmdbQuery.discover(series: false, region: 'JP', animated: false)),
    _RowSpec((l) => l.catAnimatedMovies, TmdbQuery.discover(series: false, animated: true)),
    _RowSpec((l) => l.catTopMovies, TmdbQuery.discover(series: false, sortBy: 'vote_average.desc', minVotes: 1000)),
  ],
  CategoryKind.anime => [
    // Chinese, Japanese and Korean only: worldwide, the most popular animated
    // series are American sitcoms (South Park, The Simpsons), which is not
    // what someone opening 动漫 is looking for.
    _RowSpec((l) => l.catTrendingAnime, TmdbQuery.discover(series: true, region: 'CN|JP|KR', animated: true)),
    _RowSpec((l) => l.catRecentlyUpdated, TmdbQuery.recentlyUpdated(series: true, region: 'CN|JP|KR', animated: true)),
    _RowSpec((l) => l.catDonghua, TmdbQuery.discover(series: true, region: 'CN', animated: true, minVotes: 5)),
    _RowSpec((l) => l.catJpAnime, TmdbQuery.discover(series: true, region: 'JP', animated: true)),
    _RowSpec((l) => l.catAnimatedMovies, TmdbQuery.discover(series: false, animated: true)),
    _RowSpec((l) => l.catTopAnime, TmdbQuery.discover(series: true, animated: true, sortBy: 'vote_average.desc', minVotes: 200)),
  ],
};

/// 电视剧, 电影 and 动漫: a featured title over rows of one kind, each row a
/// TMDb list in the viewer's language.
///
/// Built new rather than on the old catalogue browser: that page listed the
/// installed addons' catalogues by addon, in English, and none of them knew
/// 港剧 from 韩剧. Every row here is a kind a viewer would name.
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.kind, this.slot});

  final CategoryKind kind;

  /// The shell slot that shows this page. The shell mounts every slot at
  /// start-up, and a page that loaded then would spend its rows' requests on
  /// a page the viewer may never open; with a slot it loads the first time it
  /// is shown. Without one (a test, a pushed route) it loads at once.
  final ShellSlot? slot;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late final List<_RowSpec> _specs = _rowsFor(widget.kind);

  /// Each row's titles once loaded; null while loading.
  late final List<List<Movie>?> _rows = List.filled(_specs.length, null);

  bool _started = false;
  ValueListenable<ShellSlot>? _current;

  /// The 筛选 panel's choice; anything but the default shows its results in
  /// place of the rows.
  CategoryFilter _filter = const CategoryFilter();
  bool _filterOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = widget.slot == null ? null : AppShellScope.of(context)?.current;
    if (current == null) {
      _start();
      return;
    }
    if (!identical(current, _current)) {
      _current?.removeListener(_onSlotChanged);
      _current = current..addListener(_onSlotChanged);
      _onSlotChanged();
    }
  }

  void _onSlotChanged() {
    if (_current?.value == widget.slot) _start();
  }

  void _start() {
    if (_started) return;
    _started = true;
    _current?.removeListener(_onSlotChanged);
    _load();
  }

  @override
  void dispose() {
    _current?.removeListener(_onSlotChanged);
    super.dispose();
  }

  Future<void> _load() async {
    // The first row first, so the featured title arrives as early as it can,
    // then the rest together.
    await _loadRow(0);
    await Future.wait([
      for (var i = 1; i < _specs.length; i++) _loadRow(i),
    ]);
  }

  Future<void> _loadRow(int i) async {
    final movies = await TmdbCatalog.row(_specs[i].query, resolveImdb: false);
    if (!mounted) return;
    setState(() => _rows[i] = movies);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final size = MediaQuery.sizeOf(context);
    final sizing = MovieCardSizing.fromWidth(size.width);
    final featured = (_rows.first ?? const <Movie>[])
        .where((m) => m.backdrop != null)
        .take(6)
        .toList();
    final empty = _rows.every((r) => r != null && r.isEmpty);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: featured.isEmpty
              ? SizedBox(height: MediaQuery.paddingOf(context).top + 24)
              : _FeaturedHero(items: featured),
        ),
        SliverToBoxAdapter(child: _filterBar(context)),
        if (!_filter.isDefault)
          SliverToBoxAdapter(
            child: CategoryFilterResults(kind: widget.kind, filter: _filter),
          ),
        if (_filter.isDefault && empty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ZplaySpacing.s48),
              child: Center(
                child: Text(
                  l10n.catEmpty,
                  textAlign: TextAlign.center,
                  style: ZplayType.body.toStyle(
                    color: context.tokens.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        for (var i = 0; i < _specs.length && _filter.isDefault; i++)
          SliverToBoxAdapter(
            child: switch (_rows[i]) {
              null => Padding(
                padding: const EdgeInsets.only(bottom: ZplaySpacing.s24),
                child: RailSkeleton(sizing: sizing, showHeader: true),
              ),
              final movies when movies.length < 4 => const SizedBox.shrink(),
              final movies => MovieSliderSection(
                section: MovieSection(
                  title: _specs[i].title(l10n),
                  subtitle: '',
                  contentType: _specs[i].query.series ? 'series' : 'movie',
                  addonBaseUrl: 'https://v3-cinemeta.strem.io',
                  catalog: AddonCatalog(
                    type: _specs[i].query.series ? 'series' : 'movie',
                    id: 'curated_category_${widget.kind.name}_$i',
                  ),
                  movies: movies,
                ),
                showSeeAll: false,
                artwork: CardArtwork.poster,
              ),
            },
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: ZplaySpacing.s48 + MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ],
    );
  }

  /// 筛选 and, once something is picked, 清除; the panel opens under them.
  Widget _filterBar(BuildContext context) {
    final l10n = l10nOf(context);
    final tokens = context.tokens;
    final padding = MovieCardSizing.fromWidth(
      MediaQuery.sizeOf(context).width,
    ).sidePadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        ZplaySpacing.s8,
        padding,
        ZplaySpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: ZplaySpacing.s8,
            children: [
              PillButton(
                label: l10n.filterTitle,
                icon: _filterOpen
                    ? Icons.expand_less_rounded
                    : Icons.tune_rounded,
                variant: _filterOpen || !_filter.isDefault
                    ? PillVariant.primary
                    : PillVariant.secondary,
                onPressed: () => setState(() => _filterOpen = !_filterOpen),
              ),
              if (!_filter.isDefault)
                PillButton(
                  label: l10n.filterClear,
                  icon: Icons.close_rounded,
                  variant: PillVariant.secondary,
                  onPressed: () =>
                      setState(() => _filter = const CategoryFilter()),
                ),
            ],
          ),
          if (_filterOpen)
            Container(
              margin: const EdgeInsets.only(top: ZplaySpacing.s12),
              padding: const EdgeInsets.symmetric(
                horizontal: ZplaySpacing.s16,
                vertical: ZplaySpacing.s8,
              ),
              decoration: BoxDecoration(
                color: tokens.surface.withValues(alpha: 0.6),
                borderRadius: ZplayRadius.mdAll,
              ),
              child: CategoryFilterPanel(
                kind: widget.kind,
                filter: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
            ),
        ],
      ),
    );
  }
}

/// The featured title at the top of a category page, rotating through a few.
///
/// A still with its name, year, rating and two-line synopsis over a scrim,
/// and two actions: 播放 and 加入片单. It changes every eight seconds unless
/// the pointer or the remote is on it. No trailer plays by itself.
class _FeaturedHero extends StatefulWidget {
  const _FeaturedHero({required this.items});

  final List<Movie> items;

  @override
  State<_FeaturedHero> createState() => _FeaturedHeroState();
}

class _FeaturedHeroState extends State<_FeaturedHero> {
  int _index = 0;
  Timer? _timer;
  bool _held = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _held || widget.items.length < 2) return;
      setState(() => _index = (_index + 1) % widget.items.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleList(Movie row) async {
    final movie = await TmdbCatalog.resolve(row);
    if (movie == null) return;
    MyListService.toggle(
      MyListItem.fromMovie(
        id: movie.id,
        name: movie.name,
        poster: movie.poster,
        year: movie.year,
        type: movie.type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = l10nOf(context);
    final size = MediaQuery.sizeOf(context);
    final television = FormFactorService.of(context) == FormFactor.television;
    final compact = size.width < 600;
    final height = (size.height * (compact ? 0.55 : 0.62)).clamp(320.0, 640.0);
    final side = compact ? ZplaySpacing.s16 : ZplaySpacing.s48;
    final movie = widget.items[_index];

    final facts = [
      if (movie.year != null) movie.year!,
      if (movie.imdbRating != null) '★ ${movie.imdbRating}',
    ];

    return MouseRegion(
      onEnter: (_) => _held = true,
      onExit: (_) => _held = false,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) => _held = focused,
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: CachedNetworkImage(
                  key: ValueKey(movie.id),
                  imageUrl: movie.backdrop!,
                  cacheManager: AppImageCache.manager,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorWidget: (_, __, ___) => ColoredBox(color: tokens.surface),
                ),
              ),
              // Left wash for the text, bottom fade into the rows.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tokens.bg.withValues(alpha: 0.94),
                      tokens.bg.withValues(alpha: 0.7),
                      tokens.bg.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.38, 0.68],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [tokens.bg, tokens.bg.withValues(alpha: 0)],
                    stops: const [0, 0.45],
                  ),
                ),
              ),
              Positioned(
                left: side,
                right: side,
                bottom: ZplaySpacing.s32,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(movie.id),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (facts.isNotEmpty)
                          Text(
                            facts.join('  ·  '),
                            style: ZplayType.body
                                .copyWith(weight: FontWeight.w600)
                                .toStyle(color: tokens.textEmphasis),
                          ),
                        const SizedBox(height: ZplaySpacing.s8),
                        Text(
                          movie.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ZplayType.display
                              .copyWith(
                                size: compact ? 34 : (television ? 44 : 56),
                                weight: FontWeight.w900,
                                height: 1.1,
                              )
                              .toStyle(color: tokens.textPrimary),
                        ),
                        if (movie.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: ZplaySpacing.s12),
                          Text(
                            movie.description!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ZplayType.body
                                .copyWith(height: 1.6, size: compact ? 14 : 16)
                                .toStyle(color: tokens.textEmphasis),
                          ),
                        ],
                        const SizedBox(height: ZplaySpacing.s20),
                        Wrap(
                          spacing: ZplaySpacing.s12,
                          runSpacing: ZplaySpacing.s12,
                          children: [
                            PillButton(
                              label: l10n.playerPlay,
                              icon: Icons.play_arrow_rounded,
                              onPressed: () => PlayLauncher.play(context, movie),
                            ),
                            ValueListenableBuilder<List<MyListItem>>(
                              valueListenable: MyListService.items,
                              builder: (context, _, __) {
                                // A lazily built row has no IMDb id yet;
                                // it is on the list under the one it
                                // resolves to.
                                final inList = MyListService.items.value.any(
                                  (i) =>
                                      i.title == movie.name &&
                                      i.type == movie.type,
                                );
                                return PillButton(
                                  label: inList
                                      ? l10n.detailsInLibrary
                                      : l10n.catAddToList,
                                  icon: inList
                                      ? Icons.check_rounded
                                      : Icons.add_rounded,
                                  variant: PillVariant.secondary,
                                  onPressed: () => _toggleList(movie),
                                );
                              },
                            ),
                            PillButton(
                              label: l10n.catDetails,
                              icon: Icons.info_outline_rounded,
                              variant: PillVariant.secondary,
                              onPressed: () =>
                                  PlayLauncher.openDetails(context, movie),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.items.length > 1)
                Positioned(
                  right: side,
                  bottom: ZplaySpacing.s40,
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.items.length; i++)
                        GestureDetector(
                          onTap: () => setState(() => _index = i),
                          child: AnimatedContainer(
                            duration: ZplayMotion.base,
                            margin: const EdgeInsets.only(left: 6),
                            width: i == _index ? 26 : 10,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? tokens.accent
                                  : tokens.textPrimary.withValues(alpha: 0.35),
                              borderRadius: ZplayRadius.fullAll,
                            ),
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
}
