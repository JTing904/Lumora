import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/continue_watching/continue_watching_item.dart';
import '../models/movie/movie.dart';
import '../models/my_list/my_list_item.dart';
import '../services/continue_watching/continue_watching_service.dart';
import '../services/metadata/tmdb_catalog.dart';
import '../services/my_list/my_list_service.dart';
import '../services/playback/play_launcher.dart';
import 'lu_button.dart';
import 'lu_cards.dart';
import 'lu_theme.dart';

/// A full-bleed carousel of titles, one every eight seconds, each with 播放,
/// 加入收藏 and 详情; a remote or a pointer pauses it while on its controls.
/// Home's 今日热门 and the top of 电视剧 / 电影 / 动漫.
class LuHeroCarousel extends StatefulWidget {
  const LuHeroCarousel({
    super.key,
    required this.movies,
    required this.phone,
    required this.pad,
    this.badge,
  });

  final List<Movie> movies;
  final bool phone;
  final double pad;

  /// The gold label on slide [index] (from 0): 今日 Top 1 on Home, nothing
  /// on a category page.
  final String? Function(int index)? badge;

  @override
  State<LuHeroCarousel> createState() => _LuHeroCarouselState();
}

class _LuHeroCarouselState extends State<LuHeroCarousel> {
  final _pages = PageController();
  int _index = 0;
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_paused || !mounted || widget.movies.length < 2) return;
      _go(_index + 1);
    });
  }

  void _go(int i) {
    if (!_pages.hasClients) return;
    final next = i % widget.movies.length;
    _pages.animateToPage(
      next < 0 ? next + widget.movies.length : next,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final size = MediaQuery.sizeOf(context);
    final height = widget.phone
        ? (size.width * 1.25).clamp(420.0, 620.0)
        : (size.height * 0.72).clamp(420.0, 680.0);
    return MouseRegion(
      onEnter: (_) => _paused = true,
      onExit: (_) => _paused = false,
      child: Focus(
        skipTraversal: true,
        onFocusChange: (f) => _paused = f,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pages,
                itemCount: widget.movies.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _HeroSlide(
                  movie: widget.movies[i],
                  badge: widget.badge?.call(i),
                  phone: widget.phone,
                  pad: widget.pad,
                ),
              ),
              Positioned(
                right: widget.pad,
                bottom: widget.phone ? 18 : 40,
                child: Row(
                  children: [
                    if (!widget.phone)
                      ExcludeFocus(
                        child: IconButton(
                          tooltip: l10n.homeHeroPrevious,
                          onPressed: () => _go(_index - 1),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: LuColors.textSoft,
                          ),
                        ),
                      ),
                    for (var i = 0; i < widget.movies.length; i++)
                      Semantics(
                        button: true,
                        label: l10n.homeHeroSlide(i + 1),
                        child: GestureDetector(
                          onTap: () => _go(i),
                          child: AnimatedContainer(
                            duration: LuMotion.focus,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _index ? 28 : 12,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? LuColors.gold
                                  : const Color(0x59FFFFFF),
                              borderRadius: LuRadius.pill,
                            ),
                          ),
                        ),
                      ),
                    if (!widget.phone)
                      ExcludeFocus(
                        child: IconButton(
                          tooltip: l10n.homeHeroNext,
                          onPressed: () => _go(_index + 1),
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: LuColors.textSoft,
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

class _HeroSlide extends StatefulWidget {
  const _HeroSlide({
    required this.movie,
    required this.badge,
    required this.phone,
    required this.pad,
  });

  final Movie movie;
  final String? badge;
  final bool phone;
  final double pad;

  @override
  State<_HeroSlide> createState() => _HeroSlideState();
}

class _HeroSlideState extends State<_HeroSlide> {
  /// The title under its IMDb id, for 继续 and 片单; null until known.
  Movie? _resolved;

  @override
  void initState() {
    super.initState();
    TmdbCatalog.resolve(widget.movie)
        .then((m) {
          if (mounted && m != null) setState(() => _resolved = m);
        })
        .catchError((_) {});
  }

  String _playLabel(List<ContinueWatchingItem> sessions) {
    final l10n = l10nOf(context);
    final id = _resolved?.id;
    final s = id == null
        ? null
        : sessions.where((x) => x.id == id && !x.isCompleted).firstOrNull;
    if (s == null) return l10n.homePlay;
    return s.episode != null
        ? l10n.homeResumeEpisode(s.episode!)
        : l10n.homeResume;
  }

  void _toggleList() {
    final m = _resolved;
    if (m == null) return;
    MyListService.toggle(
      MyListItem.fromMovie(
        id: m.id,
        name: m.name,
        poster: m.poster,
        year: m.year,
        type: m.type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final m = widget.movie;
    final phone = widget.phone;
    final facts = [
      m.type == 'series' ? l10n.homeKindSeries : l10n.homeKindMovie,
      if (m.year != null) m.year!,
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        LuImage(url: m.backdrop, cacheWidth: 1920),
        // The design's two shades: dark on the left for the words, and the
        // page's own ground rising from the bottom so the rows sit on it.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: phone
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x330A0A0C), Color(0x660A0A0C), LuColors.bg],
                    stops: [0, 0.45, 1],
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xF00A0A0C),
                      Color(0xB80A0A0C),
                      Color(0x000A0A0C),
                    ],
                    stops: [0, 0.34, 0.62],
                  ),
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 260,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [LuColors.bg, Color(0x000A0A0C)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: widget.pad,
          right: phone ? widget.pad : null,
          bottom: phone ? 48 : 84,
          width: phone ? null : 600,
          child: FocusTraversalGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.badge case final b?) LuBadge(b),
                    Text(facts.join('  ·  '), style: LuText.label),
                    if (m.imdbRating != null)
                      Text(
                        '★ ${m.imdbRating}',
                        style: LuText.label.copyWith(
                          color: LuColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  m.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LuText.hero.copyWith(fontSize: phone ? 34 : 64),
                ),
                if ((m.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    m.description!.trim(),
                    maxLines: phone ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: LuText.body.copyWith(
                      fontSize: phone ? 14 : 17,
                      color: LuColors.textSoft,
                      height: 1.7,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    ValueListenableBuilder<List<ContinueWatchingItem>>(
                      valueListenable: ContinueWatchingService.activeItems,
                      builder: (context, sessions, _) => LuButton(
                        label: _playLabel(sessions),
                        icon: Icons.play_arrow_rounded,
                        compact: phone,
                        onPressed: () => PlayLauncher.play(context, m),
                      ),
                    ),
                    ValueListenableBuilder<List<MyListItem>>(
                      valueListenable: MyListService.items,
                      builder: (context, items, _) {
                        final inList =
                            _resolved != null &&
                            items.any((i) => i.imdbId == _resolved!.id);
                        return LuButton(
                          label: inList
                              ? l10n.detailsInLibrary
                              : l10n.catAddToList,
                          icon: inList
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          kind: LuButtonKind.secondary,
                          compact: phone,
                          onPressed: _resolved == null ? null : _toggleList,
                        );
                      },
                    ),
                    if (!phone)
                      LuButton(
                        label: l10n.homeMoreInfo,
                        icon: Icons.info_outline_rounded,
                        kind: LuButtonKind.secondary,
                        onPressed: () => PlayLauncher.openDetails(context, m),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
