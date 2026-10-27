import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/continue_watching/continue_watching_item.dart';
import '../../models/movie/movie.dart';
import '../../services/continue_watching/continue_watching_service.dart';
import '../../services/content/adult_guard.dart';
import '../../services/layout/form_factor.dart';
import '../../services/metadata/tmdb_catalog.dart';
import '../../services/p2p/p2p_settings_service.dart';
import '../../services/playback/play_launcher.dart';
import '../../services/recommend/recommender.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_hero.dart';
import '../../ui/lu_theme.dart';
import '../../widgets/common/local_title_text.dart';
import '../../widgets/home/continue_watching_slider.dart'
    show continueWatchingCaption;
import '../../widgets/p2p/p2p_warning_dialog.dart';

/// One row of the home page: its title and its titles.
class _Row {
  const _Row(this.title, this.movies);

  final String title;
  final List<Movie> movies;
}

/// 首页, as designed: a full-bleed carousel of today's most watched titles,
/// 继续观看, 本周 Top 10, 为你推荐, then rows by kind, all in Chinese from
/// TMDb.
///
/// Written fresh on the Lumora kit (`lib/ui`); the catalogue engine (TMDb
/// lists, the recommender, Continue Watching, the source pick behind 播放) is
/// the app's own.
class LuHomePage extends StatefulWidget {
  const LuHomePage({super.key});

  @override
  State<LuHomePage> createState() => _LuHomePageState();
}

class _LuHomePageState extends State<LuHomePage> {
  List<Movie> _hero = const [];
  List<Movie> _top = const [];
  List<_Row> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // After the first frame: loading reads the page's language, which
    // initState may not.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
      _p2pNotice();
    });
  }

  /// The torrent notice, once ever (see [P2pSettingsService]).
  Future<void> _p2pNotice() async {
    try {
      if (!await P2pSettingsService.shouldShowWarning() || !mounted) return;
      await showDialog(
        context: context,
        builder: (context) => const P2pWarningDialog(),
      );
      await P2pSettingsService.setNeverShowWarning(true);
    } catch (_) {}
  }

  Future<List<Movie>> _list(TmdbQuery q, {int limit = 20}) async {
    try {
      return AdultGuard.filter(
        await TmdbCatalog.row(q, limit: limit, resolveImdb: false),
      );
    } catch (_) {
      return const [];
    }
  }

  Future<void> _load() async {
    final l10n = l10nOf(context);
    final hero = await _list(const TmdbQuery('/trending/all/day'), limit: 8);
    if (!mounted) return;
    setState(
      () => _hero = hero.where((m) => m.backdrop != null).take(6).toList(),
    );

    final specs = <(String, TmdbQuery)>[
      (l10n.catTrendingSeries, const TmdbQuery('/trending/tv/week', {}, true)),
      (
        l10n.catRecentlyUpdated,
        TmdbQuery.recentlyUpdated(series: true, animated: false),
      ),
      (
        l10n.catTrendingMovies,
        const TmdbQuery('/trending/movie/week', {}, true),
      ),
      (
        l10n.catTrendingAnime,
        TmdbQuery.discover(series: true, region: 'CN|JP|KR', animated: true),
      ),
      (
        l10n.catChineseMovies,
        TmdbQuery.discover(series: false, language: 'zh', animated: false),
      ),
    ];
    final results = await Future.wait([
      _list(const TmdbQuery('/trending/all/week'), limit: 10),
      for (final s in specs) _list(s.$2),
    ]);
    List<_Row> taste = const [];
    try {
      taste = [
        for (final s in await Recommender.sections())
          _Row(s.title, AdultGuard.filter(s.movies)),
      ];
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _top = results.first;
      _rows = [
        ...taste,
        for (var i = 0; i < specs.length; i++)
          _Row(specs[i].$1, results[i + 1]),
      ].where((r) => r.movies.length >= 4).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final size = MediaQuery.sizeOf(context);
    final phone = size.width < 600;
    final tv = FormFactorService.of(context) == FormFactor.television;
    final pad = phone ? 16.0 : (tv ? 48.0 : LuSpace.page);
    final posterW = phone ? 116.0 : (tv ? 150.0 : 160.0);
    final continueW = phone ? 240.0 : 320.0;
    final rankW = phone ? 104.0 : 150.0;

    return Theme(
      data: luTheme(),
      child: ColoredBox(
        color: LuColors.bg,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _hero.isEmpty
                  ? SizedBox(height: MediaQuery.paddingOf(context).top + 24)
                  : LuHeroCarousel(
                      movies: _hero,
                      phone: phone,
                      pad: pad,
                      badge: (i) => l10n.homeTodayTop(i + 1),
                    ),
            ),
            SliverToBoxAdapter(
              child: ValueListenableBuilder<List<ContinueWatchingItem>>(
                valueListenable: ContinueWatchingService.activeItems,
                builder: (context, sessions, _) {
                  final items = sessions
                      .where(
                        (s) =>
                            !s.isCompleted &&
                            (AdultGuard.allowed || !s.isAdult),
                      )
                      .toList();
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 36),
                    child: LuRail(
                      title: l10n.homeContinueWatching,
                      padding: pad,
                      height: LuContinueCard.heightFor(continueW),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final s = items[i];
                        return LuContinueCard(
                          width: continueW,
                          title: LocalTitleText(
                            id: s.id,
                            fallback: s.title,
                            series: s.type != 'movie',
                          ),
                          image: s.backdropUrl ?? s.posterUrl,
                          progress: s.progressPercent,
                          caption: continueWatchingCaption(context, s),
                          removeLabel: l10n.cwRemove,
                          onRemove: () => ContinueWatchingService.removeItem(s),
                          onTap: () => ContinueWatchingService.resumePlayback(
                            context,
                            s,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            if (_top.length >= 5)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: LuRail(
                    title: l10n.homeTop10,
                    padding: pad,
                    spacing: 28,
                    height: LuRankCard.heightFor(rankW) + 16,
                    itemCount: _top.length,
                    itemBuilder: (context, i) {
                      final m = _top[i];
                      return LuRankCard(
                        rank: i + 1,
                        title: m.name,
                        poster: m.poster,
                        posterWidth: rankW,
                        badge: _kind(m),
                        onTap: () => PlayLauncher.openDetails(context, m),
                      );
                    },
                  ),
                ),
              ),
            for (final row in _rows)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: LuRail(
                    title: row.title,
                    padding: pad,
                    height: LuPosterCard.heightFor(posterW) + 8,
                    itemCount: row.movies.length,
                    itemBuilder: (context, i) {
                      final m = row.movies[i];
                      return LuPosterCard(
                        width: posterW,
                        title: m.name,
                        poster: m.poster,
                        rating: m.imdbRating,
                        subtitle: [
                          if (m.year != null) m.year!,
                          _kind(m),
                        ].join(' · '),
                        onTap: () => PlayLauncher.openDetails(context, m),
                      );
                    },
                  ),
                ),
              ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(color: LuColors.gold),
                  ),
                ),
              )
            else if (_hero.isEmpty && _rows.isEmpty)
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
                        onPressed: () {
                          setState(() => _loading = true);
                          _load();
                        },
                      ),
                    ],
                  ),
                ),
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

  String _kind(Movie m) {
    final l10n = l10nOf(context);
    return m.type == 'series' ? l10n.homeKindSeries : l10n.homeKindMovie;
  }
}
