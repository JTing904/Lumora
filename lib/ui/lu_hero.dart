import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
///
/// A remote pages it from its buttons: Left on the first button shows the
/// previous title, Right on the last the next one, and focus lands on the
/// same button of the new slide. Anywhere else Left and Right move between
/// the buttons as usual.
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
  final _focus = FocusNode(debugLabel: 'hero', skipTraversal: true);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_paused || !mounted || widget.movies.length < 2) return;
      _go(_index + 1);
    });
  }

  Future<void> _go(int i) async {
    if (!_pages.hasClients) return;
    final next = i % widget.movies.length;
    await _pages.animateToPage(
      next < 0 ? next + widget.movies.length : next,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  /// The focusable controls of the slide on screen, in reading order: the
  /// nodes inside the carousel that lie within its bounds (a slide leaving
  /// or arriving mid-swipe is outside them).
  List<FocusNode> _controls() {
    final bounds = _focus.rect.inflate(1);
    final nodes = [
      for (final n in _focus.traversalDescendants)
        if (n.context != null &&
            n.canRequestFocus &&
            bounds.contains(n.rect.center))
          n,
    ];
    nodes.sort((a, b) {
      final dy = a.rect.center.dy - b.rect.center.dy;
      if (dy.abs() > 8) return dy.sign.toInt();
      return a.rect.center.dx.compareTo(b.rect.center.dx);
    });
    return nodes;
  }

  /// Left on the slide's first control pages back, Right on its last pages
  /// on; every other key, and Left/Right between the controls, are left to
  /// the normal traversal.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final dir = key == LogicalKeyboardKey.arrowLeft
        ? -1
        : key == LogicalKeyboardKey.arrowRight
        ? 1
        : 0;
    if (dir == 0 || widget.movies.length < 2) return KeyEventResult.ignored;
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) return KeyEventResult.ignored;
    final controls = _controls();
    final at = controls.indexOf(focused);
    if (at < 0) return KeyEventResult.ignored;
    // The edges in reading order, so a row of buttons that wraps still has
    // one first and one last.
    if (at != (dir < 0 ? 0 : controls.length - 1)) {
      return KeyEventResult.ignored;
    }
    _page(dir, at);
    return KeyEventResult.handled;
  }

  /// Shows the slide [dir] away and puts focus on its control [at], the
  /// one the viewer was on.
  Future<void> _page(int dir, int at) async {
    await _go(_index + dir);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controls = _controls();
      if (controls.isEmpty) return;
      controls[at.clamp(0, controls.length - 1)].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focus.dispose();
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
        focusNode: _focus,
        onKeyEvent: _onKey,
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

  /// Whether the lookup has finished, found or not. Until it has, 片单 is
  /// drawn ready (not greyed) and a press waits for the answer.
  bool _settled = false;

  /// A 片单 press made before the title resolved, run when it does.
  bool _pendingToggle = false;

  @override
  void initState() {
    super.initState();
    TmdbCatalog.resolve(
      widget.movie,
    ).then<Movie?>((m) => m).catchError((_) => null).then((m) {
      if (!mounted) return;
      final run = _pendingToggle && m != null;
      setState(() {
        _resolved = m;
        _settled = true;
        _pendingToggle = false;
      });
      if (run) _toggleList();
    });
  }

  /// What 片单's button does: toggle once the title is known, wait for it
  /// while it is still resolving, and nothing once it is known to be missing.
  VoidCallback? get _listPress {
    if (_resolved != null) return _toggleList;
    if (_settled) return null;
    return () => setState(() => _pendingToggle = true);
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
        // The text keeps a readable measure; the buttons may use the whole
        // width, or three of them wrap onto a second line on a wide window.
        Positioned(
          left: widget.pad,
          right: widget.pad,
          bottom: phone ? 48 : 84,
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
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: phone ? double.infinity : 600,
                  ),
                  child: Text(
                    m.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: LuText.hero.copyWith(fontSize: phone ? 34 : 64),
                  ),
                ),
                if ((m.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: phone ? double.infinity : 600,
                    ),
                    child: Text(
                      m.description!.trim(),
                      maxLines: phone ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: LuText.body.copyWith(
                        fontSize: phone ? 14 : 17,
                        color: LuColors.textSoft,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                // A phone gives the two actions the row in equal halves; a
                // wider screen keeps them at their own width, left-aligned.
                if (phone)
                  Row(
                    children: [
                      Expanded(
                        child:
                            ValueListenableBuilder<List<ContinueWatchingItem>>(
                              valueListenable:
                                  ContinueWatchingService.activeItems,
                              builder: (context, sessions, _) => LuButton(
                                label: _playLabel(sessions),
                                icon: Icons.play_arrow_rounded,
                                compact: phone,
                                expand: phone,
                                onPressed: () => PlayLauncher.play(context, m),
                              ),
                            ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder<List<MyListItem>>(
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
                              expand: phone,
                              busy: _pendingToggle,
                              onPressed: _listPress,
                            );
                          },
                        ),
                      ),
                    ],
                  )
                else
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
                          expand: phone,
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
                            expand: phone,
                            busy: _pendingToggle,
                            onPressed: _listPress,
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
