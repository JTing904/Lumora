import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../models/movie/movie.dart';
import '../../services/layout/form_factor.dart';
import '../../services/settings/locale_settings.dart';
import '../../services/metadata/tmdb_catalog.dart';
import '../../services/playback/play_launcher.dart';
import '../../shell/app_shell_scope.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_hero.dart';
import '../../ui/lu_theme.dart';
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
    _RowSpec(
      (l) => l.catTrendingSeries,
      const TmdbQuery('/trending/tv/week', {}, true),
    ),
    _RowSpec(
      (l) => l.catRecentlyUpdated,
      TmdbQuery.recentlyUpdated(series: true, animated: false),
    ),
    _RowSpec(
      (l) => l.catCnDrama,
      TmdbQuery.discover(series: true, region: 'CN', animated: false),
    ),
    _RowSpec(
      (l) => l.catHkDrama,
      TmdbQuery.discover(
        series: true,
        region: 'HK',
        animated: false,
        minVotes: 5,
      ),
    ),
    _RowSpec(
      (l) => l.catKrDrama,
      TmdbQuery.discover(series: true, region: 'KR', animated: false),
    ),
    _RowSpec(
      (l) => l.catUsDrama,
      TmdbQuery.discover(series: true, region: 'US', animated: false),
    ),
    _RowSpec(
      (l) => l.catTwDrama,
      TmdbQuery.discover(
        series: true,
        region: 'TW',
        animated: false,
        minVotes: 5,
      ),
    ),
    _RowSpec(
      (l) => l.catJpDrama,
      TmdbQuery.discover(series: true, region: 'JP', animated: false),
    ),
    _RowSpec(
      (l) => l.catGbDrama,
      TmdbQuery.discover(series: true, region: 'GB', animated: false),
    ),
    _RowSpec(
      (l) => l.catTopSeries,
      TmdbQuery.discover(
        series: true,
        animated: false,
        sortBy: 'vote_average.desc',
        minVotes: 300,
      ),
    ),
  ],
  CategoryKind.movies => [
    _RowSpec(
      (l) => l.catTrendingMovies,
      const TmdbQuery('/trending/movie/week', {}, true),
    ),
    _RowSpec(
      (l) => l.catRecentlyUpdated,
      TmdbQuery.recentlyUpdated(series: false),
    ),
    _RowSpec((l) => l.catNowPlaying, const TmdbQuery('/movie/now_playing')),
    _RowSpec(
      (l) => l.catChineseMovies,
      TmdbQuery.discover(series: false, language: 'zh', animated: false),
    ),
    _RowSpec(
      (l) => l.catHkMovies,
      TmdbQuery.discover(series: false, region: 'HK', animated: false),
    ),
    _RowSpec(
      (l) => l.catUsMovies,
      TmdbQuery.discover(series: false, region: 'US', animated: false),
    ),
    _RowSpec(
      (l) => l.catKrMovies,
      TmdbQuery.discover(series: false, region: 'KR', animated: false),
    ),
    _RowSpec(
      (l) => l.catJpMovies,
      TmdbQuery.discover(series: false, region: 'JP', animated: false),
    ),
    _RowSpec(
      (l) => l.catAnimatedMovies,
      TmdbQuery.discover(series: false, animated: true),
    ),
    _RowSpec(
      (l) => l.catTopMovies,
      TmdbQuery.discover(
        series: false,
        sortBy: 'vote_average.desc',
        minVotes: 1000,
      ),
    ),
  ],
  CategoryKind.anime => [
    // Chinese, Japanese and Korean only: worldwide, the most popular animated
    // series are American sitcoms (South Park, The Simpsons), which is not
    // what someone opening 动漫 is looking for.
    _RowSpec(
      (l) => l.catTrendingAnime,
      TmdbQuery.discover(series: true, region: 'CN|JP|KR', animated: true),
    ),
    _RowSpec(
      (l) => l.catRecentlyUpdated,
      TmdbQuery.recentlyUpdated(
        series: true,
        region: 'CN|JP|KR',
        animated: true,
      ),
    ),
    _RowSpec(
      (l) => l.catDonghua,
      TmdbQuery.discover(
        series: true,
        region: 'CN',
        animated: true,
        minVotes: 5,
      ),
    ),
    _RowSpec(
      (l) => l.catJpAnime,
      TmdbQuery.discover(series: true, region: 'JP', animated: true),
    ),
    _RowSpec(
      (l) => l.catAnimatedMovies,
      TmdbQuery.discover(series: false, animated: true),
    ),
    _RowSpec(
      (l) => l.catTopAnime,
      TmdbQuery.discover(
        series: true,
        animated: true,
        sortBy: 'vote_average.desc',
        minVotes: 200,
      ),
    ),
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

  /// Bumped on every reload (a new language, Retry), so a row that lands for
  /// an older one is dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    LocaleSettings.locale.addListener(_onLocaleChanged);
  }

  /// TMDb answers in the viewer's language, so a new one reads the rows
  /// again. A page not yet shown has nothing to redo; it loads in the new
  /// language when it is.
  void _onLocaleChanged() {
    if (!_started || !mounted) return;
    _generation++;
    _load();
  }

  /// Reads again every row that came back empty - a failed read looks the
  /// same as an empty list.
  void _retry() {
    _generation++;
    setState(() {
      for (var i = 0; i < _rows.length; i++) {
        if (_rows[i]?.isEmpty ?? false) _rows[i] = null;
      }
    });
    _load(onlyMissing: true);
  }

  /// The 筛选 panel's choice; anything but the default shows its results in
  /// place of the rows.
  CategoryFilter _filter = const CategoryFilter();
  bool _filterOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = widget.slot == null
        ? null
        : AppShellScope.of(context)?.current;
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
    LocaleSettings.locale.removeListener(_onLocaleChanged);
    _current?.removeListener(_onSlotChanged);
    super.dispose();
  }

  /// Every row, or with [onlyMissing] those not loaded. The rows already on
  /// screen stay until their new titles land, so a reload does not blank the
  /// page.
  Future<void> _load({bool onlyMissing = false}) async {
    final generation = _generation;
    bool wanted(int i) => !onlyMissing || _rows[i] == null;
    // The first row first, so the featured title arrives as early as it can,
    // then the rest together.
    if (wanted(0)) await _loadRow(0, generation);
    if (!mounted || generation != _generation) return;
    await Future.wait([
      for (var i = 1; i < _specs.length; i++)
        if (wanted(i)) _loadRow(i, generation),
    ]);
  }

  Future<void> _loadRow(int i, int generation) async {
    final movies = await TmdbCatalog.row(_specs[i].query, resolveImdb: false);
    if (!mounted || generation != _generation) return;
    setState(() => _rows[i] = movies);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final size = MediaQuery.sizeOf(context);
    final phone = size.width < 600;
    final tv = FormFactorService.of(context) == FormFactor.television;
    final pad = phone ? 16.0 : (tv ? 48.0 : LuSpace.page);
    final posterW = phone ? 116.0 : (tv ? 150.0 : 160.0);
    // Room for the cards' text at the viewer's text size, plus the focus
    // lift, so a rail does not overflow at a large text setting.
    final railH =
        LuPosterCard.heightFor(posterW, MediaQuery.textScalerOf(context)) + 8;
    final featured = (_rows.first ?? const <Movie>[])
        .where((m) => m.backdrop != null)
        .take(6)
        .toList();
    final empty = _rows.every((r) => r != null && r.isEmpty);

    return Theme(
      data: luTheme(),
      child: ColoredBox(
        color: LuColors.bg,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              // A filter's results take the page: the carousel is only for
              // browsing the rows.
              child: featured.isEmpty || !_filter.isDefault
                  ? SizedBox(height: MediaQuery.paddingOf(context).top + 24)
                  : LuHeroCarousel(movies: featured, phone: phone, pad: pad),
            ),
            SliverToBoxAdapter(child: _filterBar(context, pad)),
            if (!_filter.isDefault)
              SliverToBoxAdapter(
                child: CategoryFilterResults(
                  kind: widget.kind,
                  filter: _filter,
                  padding: pad,
                ),
              ),
            if (_filter.isDefault && empty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Text(
                        l10n.catEmpty,
                        textAlign: TextAlign.center,
                        style: LuText.bodySoft,
                      ),
                      const SizedBox(height: 20),
                      LuButton(
                        label: l10n.actionRetry,
                        icon: Icons.refresh_rounded,
                        kind: LuButtonKind.secondary,
                        onPressed: _retry,
                      ),
                    ],
                  ),
                ),
              ),
            for (var i = 0; i < _specs.length && _filter.isDefault; i++)
              SliverToBoxAdapter(
                child: switch (_rows[i]) {
                  null => SizedBox(height: railH + 52),
                  final movies when movies.length < 4 =>
                    const SizedBox.shrink(),
                  final movies => Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: LuRail(
                      title: _specs[i].title(l10n),
                      padding: pad,
                      height: railH,
                      itemCount: movies.length,
                      itemBuilder: (context, j) {
                        final m = movies[j];
                        return LuPosterCard(
                          width: posterW,
                          title: m.name,
                          titleId: m.id,
                          series: m.type == 'series',
                          poster: m.poster,
                          subtitle: m.year,
                          rating: m.imdbRating,
                          onTap: () => PlayLauncher.openDetails(context, m),
                        );
                      },
                    ),
                  ),
                },
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48 + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 筛选 and, once something is picked, 清除; the panel opens under them.
  Widget _filterBar(BuildContext context, double pad) {
    final l10n = l10nOf(context);
    final active = _filterOpen || !_filter.isDefault;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              LuButton(
                label: l10n.filterTitle,
                icon: _filterOpen
                    ? Icons.expand_less_rounded
                    : Icons.tune_rounded,
                kind: active ? LuButtonKind.primary : LuButtonKind.secondary,
                compact: true,
                onPressed: () => setState(() => _filterOpen = !_filterOpen),
              ),
              if (!_filter.isDefault)
                LuButton(
                  label: l10n.filterClear,
                  icon: Icons.close_rounded,
                  kind: LuButtonKind.secondary,
                  compact: true,
                  onPressed: () =>
                      setState(() => _filter = const CategoryFilter()),
                ),
            ],
          ),
          if (_filterOpen)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: LuColors.surface,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: LuColors.lineSoft),
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
