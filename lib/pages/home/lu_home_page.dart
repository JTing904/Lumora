import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../models/continue_watching/continue_watching_item.dart';
import '../../models/movie/movie.dart';
import '../../services/continue_watching/continue_watching_service.dart';
import '../../services/content/adult_guard.dart';
import '../../services/content/content_settings.dart';
import '../../services/layout/form_factor.dart';
import '../../services/metadata/tmdb_catalog.dart';
import '../../services/my_list/my_list_service.dart';
import '../../services/my_list/new_episode_service.dart';
import '../../services/p2p/p2p_settings_service.dart';
import '../../services/playback/play_launcher.dart';
import '../../services/recommend/recommender.dart';
import '../../services/settings/locale_settings.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_hero.dart';
import '../../ui/lu_theme.dart';
import '../../widgets/common/local_title_text.dart';
import '../../widgets/home/continue_watching_slider.dart'
    show continueWatchingCaption;
import '../../widgets/p2p/p2p_warning_dialog.dart';

/// One row of the home page: its title and its titles.
///
/// The title is read in build, in the page's language at that moment, so a
/// switch of language renames the row at once.
class _Row {
  const _Row(this.title, this.movies);

  final String Function(AppLocalizations l10n) title;
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

  /// Bumped on every load, so one overtaken by a newer (a new language,
  /// Retry) is dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    LocaleSettings.locale.addListener(_onLocaleChanged);
    // 有新集: checks My List's series in the background.
    NewEpisodeService.ensureStarted();
    // After the first frame: loading reads the page's language, which
    // initState may not.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
      _p2pNotice();
    });
  }

  @override
  void dispose() {
    LocaleSettings.locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  /// TMDb and the recommender answer in the viewer's language, so a new one
  /// reads the page again. What is on screen stays until it is replaced.
  void _onLocaleChanged() {
    if (mounted) _load();
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
    final generation = ++_generation;
    final hero = await _list(const TmdbQuery('/trending/all/day'), limit: 8);
    if (!mounted || generation != _generation) return;
    setState(
      () => _hero = hero.where((m) => m.backdrop != null).take(6).toList(),
    );

    final specs = <(String Function(AppLocalizations), TmdbQuery)>[
      (
        (l) => l.catTrendingSeries,
        const TmdbQuery('/trending/tv/week', {}, true),
      ),
      (
        (l) => l.catRecentlyUpdated,
        TmdbQuery.recentlyUpdated(series: true, animated: false),
      ),
      (
        (l) => l.catTrendingMovies,
        const TmdbQuery('/trending/movie/week', {}, true),
      ),
      (
        (l) => l.catTrendingAnime,
        TmdbQuery.discover(series: true, region: 'CN|JP|KR', animated: true),
      ),
      (
        (l) => l.catChineseMovies,
        TmdbQuery.discover(series: false, language: 'zh', animated: false),
      ),
    ];
    final results = await Future.wait([
      _list(const TmdbQuery('/trending/all/week'), limit: 10),
      for (final s in specs) _list(s.$2),
    ]);
    List<_Row> taste = const [];
    try {
      // The recommender names its rows in the language of the moment; a
      // switch reloads the page, which names them again.
      taste = [
        for (final s in await Recommender.sections())
          _Row((_) => s.title, AdultGuard.filter(s.movies)),
      ];
    } catch (_) {}
    if (!mounted || generation != _generation) return;
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
    // Top 10 on a phone: a smaller poster and a numeral well under its full
    // height, so about three cards show across instead of two. Keyed on the
    // shortest side so a phone held sideways stays compact; a television keeps
    // the full ten-foot look whatever its reported size.
    final compactRank = size.shortestSide < 600 && !DeviceProfile.isTelevision;
    final rankW = compactRank ? 92.0 : 150.0;
    final scaler = MediaQuery.textScalerOf(context);

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
                      height: LuContinueCard.heightFor(continueW, scaler) + 8,
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
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  NewEpisodeService.info,
                  MyListService.items,
                  ContentSettings.adultEnabled,
                ]),
                builder: (context, _) {
                  final shows = NewEpisodeService.newEpisodes();
                  if (shows.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: LuRail(
                      title: l10n.newEpRail,
                      padding: pad,
                      height: LuPosterCard.heightFor(posterW, scaler) + 8,
                      itemCount: shows.length,
                      itemBuilder: (context, i) {
                        final show = shows[i];
                        return LuPosterCard(
                          width: posterW,
                          title: show.title,
                          poster: show.poster,
                          badge: l10n.newEpBadge,
                          subtitle: show.latestCode(l10n),
                          onTap: () => PlayLauncher.openDetails(
                            context,
                            Movie(
                              id: show.detailsId,
                              name: show.title,
                              poster: show.poster,
                              year: show.year?.toString(),
                              type: 'series',
                              addonBaseUrl: 'https://v3-cinemeta.strem.io',
                            ),
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
                child: ValueListenableBuilder<Map<String, NewEpisodeInfo>>(
                  valueListenable: NewEpisodeService.info,
                  builder: (context, _, _) => Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: LuRail(
                      title: l10n.homeTop10,
                      padding: pad,
                      spacing: compactRank ? 12 : 28,
                      height: LuRankCard.heightFor(rankW) + 16,
                      itemCount: _top.length,
                      itemBuilder: (context, i) {
                        final m = _top[i];
                        return LuRankCard(
                          rank: i + 1,
                          title: m.name,
                          poster: m.poster,
                          posterWidth: rankW,
                          numeralScale: compactRank ? 0.62 : 1,
                          badge: _hasNew(m) ? l10n.newEpBadge : _kind(m),
                          onTap: () => PlayLauncher.openDetails(context, m),
                        );
                      },
                    ),
                  ),
                ),
              ),
            for (final row in _rows)
              SliverToBoxAdapter(
                child: ValueListenableBuilder<Map<String, NewEpisodeInfo>>(
                  valueListenable: NewEpisodeService.info,
                  builder: (context, _, _) => Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: LuRail(
                      title: row.title(l10n),
                      padding: pad,
                      height: LuPosterCard.heightFor(posterW, scaler) + 8,
                      itemCount: row.movies.length,
                      itemBuilder: (context, i) {
                        final m = row.movies[i];
                        final fresh = _newInfo(m);
                        return LuPosterCard(
                          width: posterW,
                          title: m.name,
                          poster: m.poster,
                          rating: m.imdbRating,
                          badge: fresh == null ? null : l10n.newEpBadge,
                          subtitle: [
                            if (fresh?.latestCode(l10n) case final code?)
                              code
                            else if (m.year != null)
                              m.year!,
                            _kind(m),
                          ].join(' · '),
                          onTap: () => PlayLauncher.openDetails(context, m),
                        );
                      },
                    ),
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

  /// The My List entry for [m] when it has a new episode (有新集).
  NewEpisodeInfo? _newInfo(Movie m) {
    if (m.type != 'series') return null;
    final info = NewEpisodeService.forId(m.id);
    return info != null && info.isNew ? info : null;
  }

  bool _hasNew(Movie m) => _newInfo(m) != null;

  String _kind(Movie m) {
    final l10n = l10nOf(context);
    return m.type == 'series' ? l10n.homeKindSeries : l10n.homeKindMovie;
  }
}
