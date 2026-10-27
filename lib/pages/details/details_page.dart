import '../../services/metadata/localized_meta.dart';
import '../../models/movie/episode_order.dart';
import '../../services/continue_watching/watched_episodes.dart';
import 'episode_number_grid.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/continue_watching/continue_watching_item.dart';
import '../../models/movie/movie.dart';
import '../../models/movie/video.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/my_list/my_list_item.dart';
import '../../services/metadata/bestsimilar_scraper.dart';
import '../../services/layout/form_factor.dart';
import '../../services/metadata/metadata_service.dart';
import '../../services/metadata/tmdb_catalog.dart';
import '../../services/my_list/my_list_service.dart';
import '../../services/cloudstream/cloudstream_manager.dart';
import '../../services/continue_watching/continue_watching_service.dart';
import '../../services/player/source_pick_settings.dart';
import '../../services/recommend/taste_store.dart';
import '../../utils/navigation/route_transitions.dart';
import '../../widgets/common/focusable_card.dart';
import '../../widgets/common/horizontal_edge_fade.dart';
import '../../widgets/common/pill_button.dart';
import '../../widgets/common/rail_skeleton.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/trailer_modal.dart';
import '../../widgets/movie/movie_card.dart';
import '../discover/discover_page.dart';
import '../player/watch_screen.dart';
import '../../services/storage/app_image_cache.dart';
import '../../services/theme/design_tokens.dart';

// ---------------------------------------------------------------------------
// Cast avatars
// ---------------------------------------------------------------------------

/// Gradient pair for a cast avatar.
///
/// The old six hardcoded pairs carried no identity — the avatar is decoration,
/// not a face. One deterministic cycle over four semantic hues keeps a given
/// name's avatar stable and adjacent cast members distinct, while the hue now
/// comes from the active palette instead of a literal.
List<Color> _avatarGradient(ZplayTokens tokens, int index) {
  final hue = switch (index % 4) {
    0 => tokens.accent,
    1 => tokens.info,
    2 => tokens.success,
    _ => tokens.warning,
  };
  return [Color.lerp(tokens.bg, hue, 0.45)!, hue];
}

/// A `bestsimilar_` row resolved to real details: the meta that was found plus
/// the identity it was found under, so the page can report the winning addon
/// and type the same way the plain id path does.
typedef _ResolvedBestsimilar = ({
  MovieDetail meta,
  String id,
  String type,
  String baseUrl,
});

class DetailsPage extends StatefulWidget {
  final Movie movie;

  /// Optional "More Like This" row. Not every addon/catalog gives you
  /// recommendations for free — pass in whatever list of Movie you already
  /// have (e.g. same-genre catalog results, or a recommendations field if
  /// your addon's meta response includes one). Section just doesn't render
  /// if this is null/empty, so it's safe to leave unset for now.
  final List<Movie>? relatedItems;

  const DetailsPage({super.key, required this.movie, this.relatedItems});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage>
    with SingleTickerProviderStateMixin {
  MovieDetail? _detail;
  bool _isLoading = true;

  /// The remote's landing place on this page, and the page's own node for it.
  ///
  /// A pushed route opens with focus on its own [FocusScope] when nothing
  /// inside it asks for focus, and on a television that is a page with nothing
  /// ringed at all: the sweep found the details page opening at "no focus",
  /// with the next press either doing nothing visible or - one press later, on
  /// the unmarked back control - leaving the page. The primary action is the
  /// honest place to land, because it is what the page exists to offer and the
  /// viewer can see it, so the page asks for it itself rather than leaving it
  /// to [FocusableCard.autofocus] to win an arbitration the route's scope is
  /// already holding.
  final FocusNode _primaryActionFocus = FocusNode(
    debugLabel: 'DetailsPrimaryAction',
  );

  /// Whether the claim above has been made, so a later rebuild cannot steal the
  /// remote back from wherever the user has moved to.
  bool _claimedPrimaryActionFocus = false;

  int? _selectedSeason;
  int? _previousSeason;
  List<Video> _currentSeasonEpisodes = [];

  bool _isSynopsisExpanded = false;

  // Similar content from BestSimilar
  List<BSItem> _similarItems = [];
  bool _isFetchingSimilar = false;

  String? _resolvedType;
  String? _resolvedBaseUrl;

  bool get _isCollection {
    final t = _resolvedType ?? _detail?.type ?? widget.movie.type;
    return t == 'collections' ||
        t == 'collection' ||
        widget.movie.isCollection ||
        (_detail != null && _detail!.isCollection);
  }

  bool get _isSeries {
    final t = _resolvedType ?? _detail?.type ?? widget.movie.type;
    return (t == 'series' ||
            t == 'tv' ||
            t == 'anime' ||
            (_detail != null && _detail!.videos.isNotEmpty)) &&
        !_isCollection;
  }

  /// The primary action's words, in one place.
  ///
  /// The label is also the width budget `_buildDesktopLayout` has to satisfy
  /// before it can size the column, so a second copy of these strings there
  /// would let the button and its own budget name different actions.
  String get _playLabel {
    final l10n = l10nOf(context);
    final resume = _resumeItem;
    if (resume != null) {
      final time = _clock(resume.positionSeconds);
      return resume.episode != null
          ? l10n.detailsResumeEpisode(resume.episode!, time)
          : l10n.detailsResume(time);
    }
    if (_nextUp case final next?) {
      return (next.season ?? 1) > 1
          ? l10n.detailsPlaySeasonEpisode(next.season!, next.episode!)
          : l10n.detailsPlayEpisode(next.episode!);
    }
    return _isCollection
        ? l10n.detailsPlayFirstMovie
        : (_isSeries ? l10n.detailsPlayEpisodes : l10n.detailsPlayMovie);
  }

  /// The unfinished session for this title, if the viewer has one.
  ///
  /// Continue Watching keeps one session per title and drops it once it passes
  /// 90%, so whatever is here is where the viewer stopped. The primary action
  /// resumes it, and its episode card carries the progress.
  ContinueWatchingItem? get _resumeItem {
    final ids = {widget.movie.id, if (_detail != null) _detail!.id};
    for (final item in ContinueWatchingService.activeItems.value) {
      if (ids.contains(item.id) && !item.isCompleted) return item;
    }
    return null;
  }

  /// The session's progress when it is on [ep], for that episode's card.
  ContinueWatchingItem? _resumeFor(Video ep) {
    final resume = _resumeItem;
    if (resume == null || resume.episode == null) return null;
    return resume.season == ep.season && resume.episode == ep.episode
        ? resume
        : null;
  }

  /// The season the page opens on: the first real one, as season 0 is
  /// specials, which few sources carry.
  static int? _openingSeason(List<int?> sorted) =>
      sorted.firstWhere((s) => (s ?? 0) > 0, orElse: () => sorted.first);

  List<Video> get _episodeOrder =>
      episodeOrder(_detail?.videos ?? const <Video>[]);

  /// With nothing in progress, the episode after the last one finished, so
  /// the primary action reads 播放 第 4 集 rather than starting over.
  Video? get _nextUp {
    if (!_isSeries || _isCollection || _resumeItem != null) return null;
    final id = _detail?.id;
    if (id == null) return null;
    final last = WatchedEpisodes.lastFinished(id);
    if (last == null) return null;
    return episodeNeighbour(_episodeOrder, last.$1, last.$2, 1);
  }

  bool _isWatched(Video ep) {
    final id = _detail?.id;
    return id != null && WatchedEpisodes.isWatched(id, ep.season, ep.episode);
  }

  /// The episode the primary action plays: in progress, next up, or first.
  Video? get _currentEpisodeTarget {
    final resume = _resumeItem;
    if (resume?.episode != null) {
      return _episodeOrder
          .where(
            (v) => v.season == resume!.season && v.episode == resume.episode,
          )
          .firstOrNull;
    }
    return _nextUp;
  }

  /// The cast in Chinese, once per title; the addon's names until then.
  final Map<String, Future<List<CastMember>?>> _localCastById = {};
  Future<List<CastMember>?> _localCast(MovieDetail meta) =>
      _localCastById[meta.id] ??= meta.id.startsWith('tt')
      ? LocalizedMeta.castFor(meta.id, series: _isSeries)
      : Future.value(null);

  void _onSessionsChanged() {
    if (mounted) setState(() {});
  }

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<int, ScrollController> _episodeControllers = {};

  ScrollController get _episodeScrollController {
    final key = _selectedSeason ?? -1;
    if (!_episodeControllers.containsKey(key)) {
      final c = ScrollController();
      c.addListener(_updateEpisodeScrollButtons);
      _episodeControllers[key] = c;
    }
    return _episodeControllers[key]!;
  }

  final ScrollController _castScrollController = ScrollController();
  final ScrollController _seasonScrollController = ScrollController();
  final ScrollController _relatedScrollController = ScrollController();
  final ScrollController _similarScrollController = ScrollController();

  bool _canScrollEpisodesLeft = false;
  bool _canScrollEpisodesRight = true;
  bool _isHoveringEpisodes = false;

  bool _canScrollCastLeft = false;
  bool _canScrollCastRight = true;
  bool _isHoveringCast = false;

  bool _canScrollRelatedLeft = false;
  bool _canScrollRelatedRight = true;
  bool _isHoveringRelated = false;

  bool _canScrollSeasonsLeft = false;
  bool _canScrollSeasonsRight = true;
  bool _isHoveringSeasons = false;

  bool _canScrollSimilarLeft = false;
  bool _canScrollSimilarRight = true;
  bool _isHoveringSimilar = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _castScrollController.addListener(_updateCastScrollButtons);
    _seasonScrollController.addListener(_updateSeasonScrollButtons);
    _relatedScrollController.addListener(_updateRelatedScrollButtons);
    _similarScrollController.addListener(_updateSimilarScrollButtons);

    ContinueWatchingService.activeItems.addListener(_onSessionsChanged);
    WatchedEpisodes.shows.addListener(_onSessionsChanged);
    _fetchDetails();
  }

  @override
  void dispose() {
    ContinueWatchingService.activeItems.removeListener(_onSessionsChanged);
    WatchedEpisodes.shows.removeListener(_onSessionsChanged);
    _animController.dispose();
    _primaryActionFocus.dispose();
    for (final c in _episodeControllers.values) {
      c.dispose();
    }
    _castScrollController.dispose();
    _seasonScrollController.dispose();
    _relatedScrollController.dispose();
    _similarScrollController.dispose();
    super.dispose();
  }

  Future<void> _handlePlayAction(Video? ep) async {
    if (_detail == null) return;

    Navigator.push(
      context,
      CinematicSlideRoute(
        page: WatchScreen(
          detail: _detail!,
          type: _resolvedType ?? _detail!.type,
          selectedEpisode: ep,
          isCollection: _isCollection,
          autoPick: SourcePickSettings.autoPick.value,
        ),
      ),
    );
  }

  void _updateEpisodeScrollButtons() {
    if (!_episodeScrollController.hasClients) return;
    final canLeft = _episodeScrollController.position.pixels > 0;
    final canRight =
        _episodeScrollController.position.pixels <
        _episodeScrollController.position.maxScrollExtent;
    if (_canScrollEpisodesLeft != canLeft ||
        _canScrollEpisodesRight != canRight) {
      setState(() {
        _canScrollEpisodesLeft = canLeft;
        _canScrollEpisodesRight = canRight;
      });
    }
  }

  void _updateCastScrollButtons() {
    if (!_castScrollController.hasClients) return;
    final canLeft = _castScrollController.position.pixels > 0;
    final canRight =
        _castScrollController.position.pixels <
        _castScrollController.position.maxScrollExtent;
    if (_canScrollCastLeft != canLeft || _canScrollCastRight != canRight) {
      setState(() {
        _canScrollCastLeft = canLeft;
        _canScrollCastRight = canRight;
      });
    }
  }

  void _updateRelatedScrollButtons() {
    if (!_relatedScrollController.hasClients) return;
    final canLeft = _relatedScrollController.position.pixels > 0;
    final canRight =
        _relatedScrollController.position.pixels <
        _relatedScrollController.position.maxScrollExtent;
    if (_canScrollRelatedLeft != canLeft ||
        _canScrollRelatedRight != canRight) {
      setState(() {
        _canScrollRelatedLeft = canLeft;
        _canScrollRelatedRight = canRight;
      });
    }
  }

  void _updateSeasonScrollButtons() {
    if (!_seasonScrollController.hasClients) return;
    final canLeft = _seasonScrollController.position.pixels > 0;
    final canRight =
        _seasonScrollController.position.pixels <
        _seasonScrollController.position.maxScrollExtent;
    if (_canScrollSeasonsLeft != canLeft ||
        _canScrollSeasonsRight != canRight) {
      setState(() {
        _canScrollSeasonsLeft = canLeft;
        _canScrollSeasonsRight = canRight;
      });
    }
  }

  void _updateSimilarScrollButtons() {
    if (!_similarScrollController.hasClients) return;
    final canLeft = _similarScrollController.position.pixels > 0;
    final canRight =
        _similarScrollController.position.pixels <
        _similarScrollController.position.maxScrollExtent;
    if (_canScrollSimilarLeft != canLeft ||
        _canScrollSimilarRight != canRight) {
      setState(() {
        _canScrollSimilarLeft = canLeft;
        _canScrollSimilarRight = canRight;
      });
    }
  }

  void _scrollList(ScrollController controller, double directionMultiplier) {
    if (!controller.hasClients) return;
    final viewportWidth = controller.position.viewportDimension;
    final scrollAmount = viewportWidth * 0.7 * directionMultiplier;
    final target = (controller.position.pixels + scrollAmount).clamp(
      0.0,
      controller.position.maxScrollExtent,
    );
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _fetchDetails() async {
    String effectiveBaseUrl = widget.movie.addonBaseUrl;
    String effectiveType = widget.movie.type;
    String effectiveId = widget.movie.id;

    // A row from a TMDb list (the category pages) carries its TMDb id until
    // it is opened; the details and every source lookup need the IMDb one.
    if (effectiveId.startsWith('tmdb:')) {
      final resolved = await TmdbCatalog.resolve(widget.movie);
      if (!mounted) return;
      if (resolved != null) effectiveId = resolved.id;
    }

    // Handle direct CloudStream detail resolution
    if (effectiveId.startsWith('cloudstream:') ||
        effectiveBaseUrl == 'cloudstream') {
      final parts = effectiveId.split(':');
      if (parts.length >= 3) {
        final sourceId = parts[1];
        final mediaUrl = Uri.decodeComponent(parts.sublist(2).join(':'));
        final csDetail = await CloudStreamManager.instance
            .fetchCloudStreamDetail(
              sourceId: sourceId,
              mediaUrl: mediaUrl,
              fallbackTitle: widget.movie.name,
              fallbackPoster: widget.movie.poster,
            );
        if (csDetail != null) {
          if (mounted) {
            setState(() {
              _detail = csDetail;
              _resolvedType = csDetail.type;
              _isLoading = false;

              if (csDetail.videos.isNotEmpty) {
                final seasons = csDetail.videos
                    .map((v) => v.season)
                    .where((s) => s != null)
                    .toSet()
                    .toList();
                seasons.sort();
                if (seasons.isNotEmpty) {
                  _selectedSeason = _openingSeason(seasons);
                  _updateEpisodesForSeason();
                } else {
                  _currentSeasonEpisodes = List.from(csDetail.videos);
                }
              }
            });
            _animController.forward();
            _claimPrimaryActionFocus();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _updateSeasonScrollButtons();
                _updateCastScrollButtons();
                _updateRelatedScrollButtons();
              }
            });

            _fetchSimilarContent();
          }
          return;
        }
      }
    }

    // Bestsimilar rows carry the scraper's own id (`bestsimilar_10856`), not
    // an IMDb id — the site publishes none — so their details can only come
    // from resolving the title first. That resolution lives in
    // [_resolveBestsimilarDetail]; every other row takes the normal id path
    // below.
    MovieDetail? meta;
    if (effectiveId.startsWith('bestsimilar_') ||
        effectiveBaseUrl.contains('bestsimilar')) {
      final resolved = await _resolveBestsimilarDetail();
      if (resolved != null) {
        meta = resolved.meta;
        effectiveBaseUrl = resolved.baseUrl;
        effectiveType = resolved.type;
        effectiveId = resolved.id;
        _resolvedBaseUrl = effectiveBaseUrl;
        _resolvedType = effectiveType;
      }
    }

    meta ??= await MetadataService.fetchMeta(
      baseUrl: effectiveBaseUrl,
      type: effectiveType,
      imdbId: effectiveId,
    );

    // If fetchMeta failed, try fallback search to resolve
    if (meta == null && !effectiveId.startsWith('tt')) {
      final yearNum = widget.movie.year != null
          ? int.tryParse(widget.movie.year!.replaceAll(RegExp(r'[^0-9]'), ''))
          : null;
      final resolved = await MetadataService.findMovieByTitle(
        title: widget.movie.name,
        type: widget.movie.type,
        year: yearNum,
      );
      if (resolved != null) {
        effectiveBaseUrl = resolved.addonBaseUrl;
        effectiveType = resolved.type;
        effectiveId = resolved.id;
        _resolvedBaseUrl = effectiveBaseUrl;
        _resolvedType = effectiveType;
        meta = await MetadataService.fetchMeta(
          baseUrl: resolved.addonBaseUrl,
          type: resolved.type,
          imdbId: resolved.id,
        );
      }
    }

    if (meta != null && meta.type.isNotEmpty) {
      _resolvedType = meta.type;
    }

    if (mounted) {
      setState(() {
        _detail = meta;
        _isLoading = false;

        if (meta != null &&
            (_isSeries || meta.videos.isNotEmpty) &&
            meta.videos.isNotEmpty) {
          final seasons = meta.videos
              .map((v) => v.season)
              .where((s) => s != null)
              .toSet()
              .toList();
          seasons.sort();
          if (seasons.isNotEmpty) {
            _selectedSeason = _openingSeason(seasons);
            _updateEpisodesForSeason();
          } else {
            _currentSeasonEpisodes = List.from(meta.videos);
          }
        }
      });
      _animController.forward();
      _claimPrimaryActionFocus();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateSeasonScrollButtons();
          _updateCastScrollButtons();
          _updateRelatedScrollButtons();
        }
      });

      // Fire off similar content fetch in background
      _fetchSimilarContent();
    }
  }

  /// Resolves a `bestsimilar_` row to real details.
  ///
  /// The row carries no IMDb id — bestsimilar publishes none — so the title
  /// goes through the fuzzy IMDb suggestion lookup. One attempt is not enough:
  /// the year the row carries can disagree with IMDb's and steer the pick
  /// wrong, and IMDb suggestion rows whose kind is not feature/movie/series
  /// (direct-to-video sequels report `video`, TV films `TV movie`) are dropped
  /// by the typed lookup entirely, so a title that exists on IMDb can still
  /// resolve to nothing. The title is therefore retried under loosened
  /// year/type biases and finally through an untyped lookup, and only a real
  /// id that a meta addon actually served details for is accepted — nothing
  /// here invents an id.
  Future<_ResolvedBestsimilar?> _resolveBestsimilarDetail() async {
    final title = widget.movie.name;
    final yearNum = widget.movie.year != null
        ? int.tryParse(widget.movie.year!.replaceAll(RegExp(r'[^0-9]'), ''))
        : null;
    final preferredType = widget.movie.type;
    final otherType =
        preferredType == 'series' ||
            preferredType == 'tv' ||
            preferredType == 'anime'
        ? 'movie'
        : 'series';

    // Most trusted first: the row as printed, then without its year, then
    // without its type hint, then bare.
    for (final bias in <({String type, int? year})>[
      (type: preferredType, year: yearNum),
      (type: preferredType, year: null),
      (type: otherType, year: yearNum),
      (type: otherType, year: null),
    ]) {
      final resolved = await MetadataService.findMovieByTitle(
        title: title,
        type: bias.type,
        year: bias.year,
      );
      if (resolved == null) continue;
      final hit = await _metaFor(
        id: resolved.id,
        baseUrl: resolved.addonBaseUrl,
        types: [resolved.type],
      );
      if (hit != null) return hit;
    }

    // Titles the typed lookup cannot see: ask without a kind filter and keep
    // the rows it drops. Exact title first — the case this catches is a real
    // IMDb row under the exact name carrying one of the unmapped kinds.
    final candidates = await MetadataService.suggestionSearch(query: title);
    final normalized = title.toLowerCase().trim();
    for (final wantExact in const [true, false]) {
      for (final c in candidates) {
        if ((c.name.toLowerCase().trim() == normalized) != wantExact) continue;
        final hit = await _metaFor(
          id: c.id,
          baseUrl: c.addonBaseUrl,
          types: [c.type, c.type == 'movie' ? 'series' : 'movie'],
        );
        if (hit != null) return hit;
      }
    }
    return null;
  }

  /// Fetches meta for a resolved candidate under each type it could be served
  /// as, returning the first real hit. A candidate no addon serves is treated
  /// as unresolved, exactly like no candidate at all.
  Future<_ResolvedBestsimilar?> _metaFor({
    required String id,
    required String baseUrl,
    required List<String> types,
  }) async {
    for (final type in types) {
      final meta = await MetadataService.fetchMeta(
        baseUrl: baseUrl,
        type: type,
        imdbId: id,
      );
      if (meta != null) {
        return (meta: meta, id: id, type: type, baseUrl: baseUrl);
      }
    }
    return null;
  }

  Future<void> _fetchSimilarContent() async {
    if (_isFetchingSimilar) return;
    setState(() => _isFetchingSimilar = true);

    try {
      final title = _detail?.name ?? widget.movie.name;
      final yearStr = _detail?.year ?? widget.movie.year;
      final year = yearStr != null
          ? int.tryParse(yearStr.replaceAll(RegExp(r'[^0-9]'), ''))
          : null;
      final isTv = _isSeries;

      final hit = await BestSimilarScraper.findBest(
        title: title,
        year: year,
        isTv: isTv,
      );

      if (hit == null || !mounted) {
        if (mounted) setState(() => _isFetchingSimilar = false);
        return;
      }

      final details = await BestSimilarScraper.fetchDetails(
        id: hit.id,
        slug: hit.slug,
      );

      if (mounted) {
        setState(() {
          _similarItems = details?.similar ?? [];
          _isFetchingSimilar = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateSimilarScrollButtons();
        });
      }
    } catch (e) {
      debugPrint('[Similar] fetch failed: $e');
      if (mounted) setState(() => _isFetchingSimilar = false);
    }
  }

  Future<void> _openSimilarItem(BSItem item) async {
    final resolved = await MetadataService.findMovieByTitle(
      title: item.title,
      type: item.isTv ? 'series' : (_resolvedType ?? widget.movie.type),
      year: item.year,
      preferredBaseUrl: _resolvedBaseUrl ?? widget.movie.addonBaseUrl,
    );

    if (resolved != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DetailsPage(movie: resolved)),
      );
    }
  }

  /// A display-only [Movie] for a scraper row, so a scraper recommendation can
  /// sit in the row as the same [MovieCard] every other film rail uses.
  ///
  /// It is only ever drawn: the id keeps the `bestsimilar_` prefix the rest of
  /// the app keys title resolution off, and the tap goes through
  /// [_openSimilarItem] rather than the card's own navigation.
  Movie _similarItemAsMovie(BSItem item) => Movie(
    id: 'bestsimilar_${item.id}',
    name: item.title,
    poster: item.thumbUrl.isEmpty ? null : item.thumbUrl,
    year: item.year?.toString(),
    type: item.isTv ? 'series' : 'movie',
    addonBaseUrl: _resolvedBaseUrl ?? widget.movie.addonBaseUrl,
    imdbRating: item.rating?.toString(),
  );

  void _updateEpisodesForSeason() {
    if (_detail == null || _selectedSeason == null) return;
    setState(() {
      _currentSeasonEpisodes = _detail!.videos
          .where((v) => v.season == _selectedSeason)
          .toList();
      _currentSeasonEpisodes.sort(
        (a, b) => (a.episode ?? 0).compareTo(b.episode ?? 0),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_episodeScrollController.hasClients) {
        // Open on the episode the primary action plays, not on episode 1.
        final target = _currentEpisodeTarget;
        final index = target == null
            ? -1
            : _currentSeasonEpisodes.indexWhere(
                (v) => v.season == target.season && v.episode == target.episode,
              );
        final step = (_isDesktop() ? 300.0 : 230.0) + ZplaySpacing.s16;
        final position = _episodeScrollController.position;
        _episodeScrollController.jumpTo(
          index <= 0
              ? 0
              : (index * step - step / 2).clamp(0.0, position.maxScrollExtent),
        );
      }
      _updateEpisodeScrollButtons();
    });
  }

  /// Hands the remote to the page's primary action, once the page has one.
  ///
  /// Called from each path that first resolves a detail, because that is the
  /// frame the pill is built in and a request posted for a node that is not
  /// attached yet is dropped. The callback runs at the end of that frame, so
  /// the pill exists by the time focus is asked for.
  ///
  /// A pointer device is left alone. [CardFocusRing] draws nothing until a card
  /// is focused, so claiming focus here on a phone or a desktop window would
  /// paint the television's "where am I" ring over a screen the user drives
  /// with a finger, and there is no remote to lose.
  void _claimPrimaryActionFocus() {
    if (_claimedPrimaryActionFocus ||
        !FormFactorService.hasRemoteInput) {
      return;
    }
    _claimedPrimaryActionFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _primaryActionFocus.requestFocus();
    });
  }

  bool _isDesktop([BuildContext? ctx]) {
    return MediaQuery.sizeOf(ctx ?? context).width >= 800;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: tokens.accent))
          : _detail == null
          ? _buildError()
          : _buildContent(context),
    );
  }

  Widget _buildError() {
    final tokens = context.tokens;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 64,
            color: tokens.textDisabled,
          ),
          const SizedBox(height: ZplaySpacing.s16),
          Text(
            l10nOf(context).detailsUnavailable,
            style: ZplayType.title.toStyle(color: tokens.textSecondary),
          ),
          const SizedBox(height: ZplaySpacing.s24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.surface,
              foregroundColor: tokens.textPrimary,
            ),
            child: Text(l10nOf(context).detailsGoBack),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final tokens = context.tokens;
    final meta = _detail!;
    final bgUrl = meta.background ?? meta.poster ?? widget.movie.poster;
    final posterUrl = meta.poster ?? widget.movie.poster;
    final isDesktop = _isDesktop(context);
    final screenSize = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Sized from the viewport that is actually left, not from a fraction of a
    // monitor's height.
    //
    // A television is 960x540 dp - 960 wide, which clears the desktop
    // breakpoint, but only 540 tall. Laying it out like a desktop meant a
    // 280dp-wide 2:3 poster was 420dp tall on its own, so the poster ran off
    // the bottom and pushed Play Movie and the rest of the buttons out of the
    // viewport entirely. The hero is a backdrop offset rather than a real
    // content height, so it gives way first; the poster is then bounded by
    // whatever is left, minus the two buttons that must remain visible.
    final isShortViewport = screenSize.height < 700;
    final heroFraction = isDesktop ? (isShortViewport ? 0.30 : 0.46) : 0.4;
    final heroHeight = (screenSize.height * heroFraction).clamp(
      isShortViewport ? 150.0 : 320.0,
      520.0,
    );
    final contentMaxWidth = isDesktop ? 1440.0 : double.infinity;
    final overlap = isDesktop ? (isShortViewport ? 60.0 : 120.0) : 70.0;
    // What the content column has left to work with, once the backdrop offset,
    // the horizontal padding and the bottom inset are gone. The poster is
    // bounded by this so it can never be what pushes the buttons off-screen.
    final availableHeight =
        screenSize.height -
        (heroHeight - overlap) -
        ZplaySpacing.s48 -
        bottomInset;

    return Stack(
      children: [
        if (bgUrl != null) _buildBackdrop(bgUrl, screenSize),
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? ZplaySpacing.s48 : ZplaySpacing.s24,
                        0,
                        isDesktop ? ZplaySpacing.s48 : ZplaySpacing.s24,
                        ZplaySpacing.s48 + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: heroHeight - overlap),
                          isDesktop
                              ? _buildDesktopLayout(
                                  meta,
                                  posterUrl,
                                  availableHeight: availableHeight,
                                )
                              : _buildMobileLayout(meta, posterUrl),
                          const SizedBox(height: ZplaySpacing.s32),
                          if (meta.cast.isNotEmpty) ...[
                            FutureBuilder<List<CastMember>?>(
                              future: _localCast(meta),
                              builder: (context, snap) => _buildCastRow(
                                snap.data ??
                                    [for (final n in meta.cast) CastMember(n)],
                              ),
                            ),
                            const SizedBox(height: ZplaySpacing.s32),
                          ],
                          if (meta.videos.isNotEmpty) ...[
                            if (meta.videos
                                    .map((v) => v.season)
                                    .where((s) => s != null)
                                    .toSet()
                                    .length >
                                1) ...[
                              _buildSeasonSelector(meta),
                              const SizedBox(height: ZplaySpacing.s24),
                            ] else ...[
                              _railHeader(
                                _isCollection
                                    ? l10nOf(context).detailsCollectionMovies
                                    : l10nOf(context).detailsEpisodes,
                              ),
                              const SizedBox(height: ZplaySpacing.s12),
                            ],
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 550),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  alignment: Alignment.topCenter,
                                  children: <Widget>[
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    final isIncoming =
                                        child.key == ValueKey(_selectedSeason);
                                    final int incomingSeason =
                                        _selectedSeason ?? 1;
                                    final int previousSeason =
                                        _previousSeason ?? 1;

                                    final bool slidingRight =
                                        incomingSeason > previousSeason;

                                    // Incoming starts offset, Outgoing ends offset
                                    final Offset beginOffset = isIncoming
                                        ? (slidingRight
                                              ? const Offset(0.12, 0.0)
                                              : const Offset(-0.12, 0.0))
                                        : (slidingRight
                                              ? const Offset(-0.12, 0.0)
                                              : const Offset(0.12, 0.0));

                                    final slideAnimation =
                                        Tween<Offset>(
                                          begin: beginOffset,
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        );

                                    final scaleAnimation =
                                        Tween<double>(
                                          begin: 0.94,
                                          end: 1.0,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        );

                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: slideAnimation,
                                        child: ScaleTransition(
                                          scale: scaleAnimation,
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                              child:
                                  _currentSeasonEpisodes.length >
                                          _gridThreshold &&
                                      !_isCollection
                                  ? Align(
                                      key: ValueKey(_selectedSeason),
                                      alignment: Alignment.topLeft,
                                      child: EpisodeNumberGrid(
                                        episodes: _currentSeasonEpisodes,
                                        current: _currentEpisodeTarget,
                                        isWatched: _isWatched,
                                        progressFor: (ep) =>
                                            _resumeFor(ep)?.progressPercent,
                                        onTap: _handlePlayAction,
                                      ),
                                    )
                                  : _buildEpisodeSlider(
                                      key: ValueKey(_selectedSeason),
                                    ),
                            ),
                            const SizedBox(height: ZplaySpacing.s32),
                          ],
                          if (widget.relatedItems != null &&
                              widget.relatedItems!.isNotEmpty) ...[
                            _buildRelatedRow(widget.relatedItems!),
                            const SizedBox(height: ZplaySpacing.s32),
                          ],
                          if (_similarItems.isNotEmpty) ...[
                            _buildSimilarRow(),
                            const SizedBox(height: ZplaySpacing.s32),
                          ] else if (_isFetchingSimilar) ...[
                            _railHeader(l10nOf(context).detailsSimilar),
                            const SizedBox(height: ZplaySpacing.s12),
                            // Card-shaped placeholders rather than a spinner:
                            // the row is a film rail, so it arrives at the
                            // height and shape the real cards will take instead
                            // of moving everything when they land.
                            _onRailGrid(
                              RailSkeleton(
                                sizing: MovieCardSizing.fromWidth(
                                  MediaQuery.sizeOf(context).width,
                                ),
                              ),
                            ),
                            const SizedBox(height: ZplaySpacing.s32),
                          ],
                          const SizedBox(height: ZplaySpacing.s48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: isDesktop ? ZplaySpacing.s24 : (topInset + 10),
          left: isDesktop ? ZplaySpacing.s48 : ZplaySpacing.s16,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              // The page's way out, wearing the house ring like every other
              // control a remote can land on.
              //
              // It was an [IconButton], whose Material focus overlay is
              // invisible over this scrim, and the sweep caught what that
              // costs: the page opened with nothing ringed, one DOWN put focus
              // here with nothing ringed, and the next OK left the page. A
              // television's only proof that a control is reachable is the
              // ring, so a focus stop without one is worse than no stop at
              // all - the user cannot tell the difference between it and the
              // end of the page.
              child: FocusableCard(
                onTap: () => Navigator.pop(context),
                builder: (context, state) => CardFocusRing(
                  focused: state.focused,
                  radius: ZplayRadius.fullAll,
                  child: Container(
                    padding: const EdgeInsets.all(ZplaySpacing.s12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.textPrimary.withValues(
                        alpha: ZplayOpacity.borderMedium,
                      ),
                      border: Border.all(color: tokens.borderStrong),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: tokens.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Persistent, full-viewport cinematic backdrop.
  //
  // Unlike a hero strip that gets cropped to a fixed height and then hands
  // off to flat background color, this sits behind the *entire* screen and
  // stays there while the foreground scrolls over it — so the image never
  // abruptly disappears, it just gradually recedes under layered scrims.
  // Three separate gradients do different jobs so no single one has to be
  // aggressive enough to look like a hard cutoff:
  //   1. a soft cap at the very top (keeps the back button legible)
  //   2. a slow bottom fade that only reaches solid bg near ~90% down
  //   3. a gentle horizontal wash so text on the left never fights the image
  // -------------------------------------------------------------------------
  Widget _buildBackdrop(String bgUrl, Size screenSize) {
    final tokens = context.tokens;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: screenSize.height,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: bgUrl,
              cacheManager: AppImageCache.manager,
              memCacheWidth: 1280,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            // horizontal wash — darkens where the title/synopsis sit, leaves
            // the rest of the image breathing room instead of blacking it all out
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    tokens.bg,
                    tokens.surfaceRaised.withValues(alpha: 0.60),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 0.82],
                ),
              ),
            ),
            // slow bottom fade — the whole point of the fix: this used to
            // resolve to solid bg by ~70% of a 300-460px strip, now it takes
            // nearly the full viewport height to settle
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    tokens.surfaceRaised.withValues(alpha: 0.40),
                    tokens.bg,
                  ],
                  stops: const [0.0, 0.62, 0.94],
                ),
              ),
            ),
            // top cap so the back button always has contrast
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tokens.bg.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.22],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Desktop: real two-column layout. Poster + actions pinned left;
  // logo/title, metadata, synopsis fill the right. With the backdrop now
  // persistent behind everything, this row no longer needs a "quick facts"
  // filler box just to feel less empty underneath the poster — genres are
  // already in the metadata line, so it's dropped to avoid repeating itself.
  // -------------------------------------------------------------------------
  Widget _buildDesktopLayout(
    MovieDetail meta,
    String? posterUrl, {
    required double availableHeight,
  }) {
    final tokens = context.tokens;

    // The column is poster + gap + Play + gap + Library, and the two buttons
    // are the part that must never fall below the fold: on a television
    // "Play Movie" is the only way into the app's main function. So the poster
    // takes whatever height is left over rather than a fixed width that
    // decides its own height from a 2:3 ratio.
    //
    // Both buttons are [PillButton.heightFor] tall and this is that number. 56
    // was the old private button's height, which is 8 dp more than the pill ever
    // draws, so the reserve was over-paying by 16 dp of the column and the
    // poster was coming out short by that much. Read from the shared control's
    // own height rather than a literal, so the two cannot drift apart again.
    final double buttonHeight = PillButton.heightFor(context);
    const double columnGap = ZplaySpacing.s12;
    const double posterGap = ZplaySpacing.s16;
    final double maxPosterHeight =
        availableHeight - buttonHeight * 2 - columnGap - posterGap;

    // Width is whatever a 2:3 poster of that height needs, capped at the
    // desktop size so a tall monitor still gets the 280dp column it had.
    final double posterWidth = (maxPosterHeight * 2 / 3).clamp(120.0, 280.0);

    // The column is as wide as its widest child needs to be, and the primary
    // action is one of those children. The poster is bounded by the viewport's
    // height budget - that is deliberate, it is what stopped the poster from
    // pushing the buttons off a 540 dp screen - but the CTA's label is bounded
    // by nothing except the words in it. On a television the poster's budget
    // yields a 177 dp column and "Play Episodes" does not fit it, so the page's
    // main action read "Play Episod…" at ten feet while hundreds of dp sat
    // empty beside it. Widening the column for the label costs the poster
    // nothing: the poster keeps the 2:3 box its own budget allows.
    // The label's own budget, next to the poster's, with the larger of the two
    // taken for the column.
    final double ctaWidth = PillButton.minWidthFor(
      context,
      _playLabel,
      icon: Icons.play_arrow_rounded,
    );
    final double columnWidth = ctaWidth > posterWidth ? ctaWidth : posterWidth;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: columnWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (posterUrl != null)
                // The poster keeps its own width inside a column that can now
                // be wider than it. Stretched to the column, the 2:3
                // `AspectRatio` would derive its height from the wider box and
                // grow the poster taller by exactly the width the label bought
                // - which is what would push both buttons back down the page
                // and out of the viewport again.
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: posterWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: ZplayRadius.mdAll,
                        boxShadow: [
                          // subtle accent-tinted glow behind the poster, on
                          // top of the usual drop shadow, so it reads as "lit"
                          // rather than just floating on black
                          BoxShadow(
                            color: tokens.accent.withValues(alpha: 0.18),
                            blurRadius: 46,
                            spreadRadius: -6,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: ZplayRadius.mdAll,
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: CachedNetworkImage(
                            imageUrl: posterUrl,
                            cacheManager: AppImageCache.manager,
                            memCacheWidth: 512,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                ColoredBox(color: tokens.surface),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: posterGap),
              _buildPlayButton(fullWidth: true),
              const SizedBox(height: columnGap),
              _buildLibraryButton(fullWidth: true),
            ],
          ),
        ),
        const SizedBox(width: ZplaySpacing.s32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogoOrTitle(meta, isDesktop: true),
              const SizedBox(height: ZplaySpacing.s16),
              _buildMetadataRow(meta),
              if (meta.displayDescription?.isNotEmpty == true) ...[
                const SizedBox(height: ZplaySpacing.s24),
                _buildSynopsis(meta.displayDescription!),
              ],
              if (meta.displayGenres.isNotEmpty) ...[
                const SizedBox(height: ZplaySpacing.s24),
                _buildGenreChips(meta.displayGenres),
              ],
              const SizedBox(height: ZplaySpacing.s24),
              _buildSecondaryActions(meta),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(MovieDetail meta, String? posterUrl) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (posterUrl != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: ZplayRadius.smAll,
                  boxShadow: [
                    BoxShadow(
                      color: tokens.accent.withValues(alpha: 0.16),
                      blurRadius: 28,
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: ZplayRadius.smAll,
                  child: CachedNetworkImage(
                    imageUrl: posterUrl,
                    cacheManager: AppImageCache.manager,
                    memCacheWidth: 330,
                    width: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(width: ZplaySpacing.s16),
            Expanded(child: _buildLogoOrTitle(meta, isDesktop: false)),
          ],
        ),
        const SizedBox(height: ZplaySpacing.s24),
        _buildMetadataRow(meta),
        const SizedBox(height: ZplaySpacing.s24),
        Row(
          children: [
            Expanded(child: _buildPlayButton(fullWidth: true)),
            const SizedBox(width: ZplaySpacing.s12),
            _buildLibraryButton(fullWidth: false),
          ],
        ),
        if (meta.displayDescription?.isNotEmpty == true) ...[
          const SizedBox(height: ZplaySpacing.s24),
          _buildSynopsis(meta.displayDescription!),
        ],
        if (meta.displayGenres.isNotEmpty) ...[
          const SizedBox(height: ZplaySpacing.s16),
          _buildGenreChips(meta.displayGenres),
        ],
        const SizedBox(height: ZplaySpacing.s16),
        _buildSecondaryActions(meta),
      ],
    );
  }

  // Logo is now capped in both width AND height, so it can never dwarf the
  // poster next to it the way it did before (that's what made the poster
  // look like an afterthought in the screenshot).
  Widget _buildLogoOrTitle(MovieDetail meta, {required bool isDesktop}) {
    // The addon's logo art spells the English name; with a Chinese name to
    // show, the name is set as text instead.
    if (meta.logo != null && meta.logo!.isNotEmpty && !meta.hasLocalName) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 380 : 220,
          maxHeight: isDesktop ? 130 : 80,
        ),
        child: CachedNetworkImage(
          imageUrl: meta.logo!,
          cacheManager: AppImageCache.manager,
          memCacheWidth: 512,
          alignment: Alignment.bottomLeft,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) =>
              _buildTextTitle(meta.displayName, isDesktop),
        ),
      );
    }
    return _buildTextTitle(meta.displayName, isDesktop);
  }

  Widget _buildTextTitle(String text, bool isDesktop) {
    final tokens = context.tokens;

    return Text(
      text,
      style: ZplayType.display
          .copyWith(size: isDesktop ? 40 : 28)
          .toStyle(color: tokens.textPrimary)
          .copyWith(
            shadows: [
              Shadow(
                color: tokens.bg.withValues(alpha: 0.7),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
    );
  }

  // Small pill chips for genres, sitting under the synopsis. This replaces
  // the old boxed "Quick Facts" panel — same information, but styled as a
  // lightweight row instead of a card that left dead space under the poster.
  Widget _buildGenreChips(List<String> genres) {
    final tokens = context.tokens;

    return Wrap(
      spacing: ZplaySpacing.s8,
      runSpacing: ZplaySpacing.s8,
      children: genres.map((g) {
        Offset? lastTap;
        // The Listener records the pointer origin for the reveal without
        // joining the gesture arena, so the card's tap still fires.
        return Listener(
          onPointerDown: (d) => lastTap = d.position,
          child: FocusableCard(
            onTap: () {
              Navigator.push(
                context,
                LiquidRevealRoute(
                  page: DiscoverPage(query: g, isGenre: true),
                  tapPosition: lastTap,
                ),
              );
            },
            builder: (_, state) => CardFocusRing(
              // The pills had no focus mark at all, so a remote that walked
              // into this row walked into nothing: the ring is the whole of
              // what tells a D-pad user which genre they are on.
              focused: state.focused,
              radius: ZplayRadius.lgAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZplaySpacing.s12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tokens.textPrimary.withValues(
                    alpha: ZplayOpacity.borderSubtle,
                  ),
                  borderRadius: ZplayRadius.lgAll,
                  border: Border.all(color: tokens.borderStrong),
                ),
                child: Text(
                  g,
                  style: ZplayType.label
                      .copyWith(weight: FontWeight.w600)
                      .toStyle(color: tokens.textEmphasis),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetadataRow(MovieDetail meta) {
    final tokens = context.tokens;
    final List<Widget> items = [];

    if (meta.year != null && meta.year!.isNotEmpty) {
      items.add(
        Text(
          meta.year!,
          style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
        ),
      );
    }

    if (_isSeries) {
      final seasonCount = meta.videos
          .map((v) => v.season)
          .where((s) => s != null)
          .toSet()
          .length;
      if (seasonCount > 0) {
        items.add(
          Text(
            l10nOf(context).detailsSeasonCount(seasonCount),
            style: ZplayType.body.toStyle(color: tokens.textEmphasis),
          ),
        );
      }
    } else if (meta.runtime != null && meta.runtime!.isNotEmpty) {
      items.add(
        Text(
          meta.runtime!,
          style: ZplayType.body.toStyle(color: tokens.textEmphasis),
        ),
      );
    }

    if (meta.imdbRating != null && meta.imdbRating!.isNotEmpty) {
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: tokens.textPrimary.withValues(
              alpha: ZplayOpacity.borderStrong,
            ),
            borderRadius: ZplayRadius.xsAll,
            border: Border.all(
              color: tokens.textPrimary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: tokens.warning, size: 14),
              const SizedBox(width: ZplaySpacing.s4),
              Text(
                meta.imdbRating!,
                style: ZplayType.bodySmall
                    .copyWith(weight: FontWeight.w700)
                    .toStyle(color: tokens.textPrimary),
              ),
            ],
          ),
        ),
      );
    }

    if (meta.displayGenres.isNotEmpty) {
      items.add(
        Text(
          meta.displayGenres.take(3).join(' · '),
          style: ZplayType.body.toStyle(color: tokens.textEmphasis),
        ),
      );
    }

    final List<Widget> spaced = [];
    for (int i = 0; i < items.length; i++) {
      spaced.add(items[i]);
      if (i < items.length - 1) {
        spaced.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ZplaySpacing.s12),
            child: Text(
              '•',
              style: ZplayType.body
                  .copyWith(size: 16)
                  .toStyle(color: tokens.textDisabled),
            ),
          ),
        );
      }
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 6,
      children: spaced,
    );
  }

  /// The page's primary call to action, as the shared [PillButton].
  ///
  /// It was a private `_HoverButton` over an accent-gradient `Container` with a
  /// `smAll` radius - a rounded rectangle with a glow, in a design language whose
  /// hero CTAs are pills. It also *scaled*: `_HoverButton` grows a focused button
  /// by 4%, which on the television moves the only control that reaches playback
  /// and shifts the poster above it. The shared pill draws its focus ring over
  /// itself instead, so nothing around it moves.
  ///
  /// [fullWidth] survives because the desktop column stretches it to the poster's
  /// width and the mobile row does the same beside the library button.
  ///
  /// With an unfinished session it resumes that session instead, says where
  /// ("继续 第 3 集 · 12:40"), and draws how far in it is as a hairline inside
  /// the pill, so the column keeps the height `_buildDesktopLayout` budgets.
  Widget _buildPlayButton({required bool fullWidth}) {
    final resume = _resumeItem;
    final pill = PillButton(
      label: _playLabel,
      icon: Icons.play_arrow_rounded,
      expand: fullWidth,
      focusNode: _primaryActionFocus,
      onPressed: resume != null
          ? () => ContinueWatchingService.resumePlayback(context, resume)
          : () => _handlePlayAction(
              _nextUp ??
              _episodeOrder.firstOrNull ??
              (_currentSeasonEpisodes.isNotEmpty
                  ? _currentSeasonEpisodes.first
                  : (_detail?.videos.isNotEmpty == true
                        ? _detail!.videos.first
                        : null)),
            ),
    );
    if (resume == null) return pill;

    final onAccent = context.tokens.onAccent;
    final inset = PillButton.heightFor(context) / 2;
    return Stack(
      children: [
        pill,
        Positioned(
          left: inset,
          right: inset,
          bottom: 6,
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: ZplayRadius.fullAll,
              child: LinearProgressIndicator(
                value: resume.progressPercent,
                minHeight: 3,
                color: onAccent,
                backgroundColor: onAccent.withValues(alpha: 0.22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The trailer and the source mode, side by side under the synopsis.
  Widget _buildSecondaryActions(MovieDetail meta) {
    return Wrap(
      spacing: ZplaySpacing.s12,
      runSpacing: ZplaySpacing.s12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_buildTrailerButton(meta) case final trailer?) trailer,
        _buildSourceModeButton(),
        ..._buildRatingButtons(meta),
      ],
    );
  }

  /// 👍 / 👎: the strongest taste signal 为你推荐 gets. Pressing the active
  /// one again clears it.
  List<Widget> _buildRatingButtons(MovieDetail meta) {
    final id = meta.id;
    if (!id.startsWith('tt')) return const [];
    final series = _isSeries;
    return [
      ValueListenableBuilder<Map<String, TasteEntry>>(
        valueListenable: TasteStore.entries,
        builder: (context, entries, _) {
          final rating = entries[id]?.rating ?? 0;
          void rate(int value) => TasteStore.recordRating(
            id,
            title: meta.name,
            series: series,
            rating: rating == value ? 0 : value,
          );
          return Wrap(
            spacing: ZplaySpacing.s12,
            children: [
              PillButton(
                label: l10nOf(context).detailsLike,
                icon: rating == 1
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
                variant: rating == 1 ? PillVariant.primary : PillVariant.secondary,
                onPressed: () => rate(1),
              ),
              PillButton(
                label: l10nOf(context).detailsDislike,
                icon: rating == -1
                    ? Icons.thumb_down_rounded
                    : Icons.thumb_down_outlined,
                variant: rating == -1
                    ? PillVariant.primary
                    : PillVariant.secondary,
                onPressed: () => rate(-1),
              ),
            ],
          );
        },
      ),
    ];
  }

  /// "片源：自动选最快" or "片源：自己选", which pressing switches.
  ///
  /// Automatic is what the play button does by default: the source list opens
  /// and plays the fastest source that is known to be this title. Choosing
  /// leaves the list waiting for the viewer, the way it always worked.
  Widget _buildSourceModeButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: SourcePickSettings.autoPick,
      builder: (context, auto, _) => PillButton(
        label: auto
            ? l10nOf(context).detailsSourceAuto
            : l10nOf(context).detailsSourceManual,
        icon: auto ? Icons.bolt_rounded : Icons.list_rounded,
        variant: PillVariant.secondary,
        onPressed: () => SourcePickSettings.setAutoPick(!auto),
      ),
    );
  }

  /// The trailer, when the metadata carries one, in the app's own player.
  Widget? _buildTrailerButton(MovieDetail meta) {
    final key = meta.trailerKey ?? widget.movie.trailerKey;
    if (key == null || key.isEmpty) return null;
    return PillButton(
      label: l10nOf(context).homeTrailer,
      icon: Icons.play_circle_outline_rounded,
      variant: PillVariant.secondary,
      onPressed: () =>
          TrailerModal.show(
            context,
            trailerKey: key,
            title: meta.displayName,
          ),
    );
  }

  /// The qualifier beside the primary action, as the shared [PillButton].
  ///
  /// [PillVariant.secondary] is the reference's translucent scrim over the
  /// artwork, so it needs none of the height arithmetic the old private control
  /// carried: it is laid out to exactly [PillButton.heightFor], the same value
  /// `_buildDesktopLayout` reserves for it, and the two stacked rows can no
  /// longer drift apart.
  ///
  /// The label and glyph still say whether the title is on the list; the accent
  /// fill that used to say it as well is gone with the private control, because
  /// accent is the app's *selection* colour and "on my list" is a state, not a
  /// selection - the pill's own two variants are all a CTA may draw.
  ///
  /// [fullWidth] survives because the desktop column stretches it to the poster's
  /// width and the mobile row does the same beside the play button.
  Widget _buildLibraryButton({required bool fullWidth}) {
    return ValueListenableBuilder<List<MyListItem>>(
      valueListenable: MyListService.items,
      builder: (context, items, _) {
        final inList =
            _detail != null &&
            MyListService.isInList(
              MyListItem.fromMovieDetail(
                id: _detail!.id,
                name: _detail!.name,
                poster: _detail!.poster,
                year: _detail!.year,
                type: _detail!.type,
                imdbId: _detail!.id.startsWith('tt') ? _detail!.id : null,
                tmdbId: _detail!.tmdbId != null
                    ? int.tryParse(_detail!.tmdbId!)
                    : null,
              ),
            );

        return PillButton(
          label: inList
              ? l10nOf(context).detailsInLibrary
              : l10nOf(context).detailsLibrary,
          variant: PillVariant.secondary,
          icon: inList ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          expand: fullWidth,
          onPressed: _toggleMyList,
        );
      },
    );
  }

  void _toggleMyList() {
    if (_detail == null) return;

    final item = MyListItem.fromMovieDetail(
      id: _detail!.id,
      name: _detail!.name,
      poster: _detail!.poster,
      year: _detail!.year,
      type: _detail!.type,
      imdbId: _detail!.id.startsWith('tt') ? _detail!.id : null,
      tmdbId: _detail!.tmdbId != null ? int.tryParse(_detail!.tmdbId!) : null,
    );

    MyListService.toggle(item);
  }

  Widget _buildSynopsis(String text) {
    final tokens = context.tokens;
    final style = ZplayType.body
        .copyWith(size: 15, height: 1.55, letterSpacing: 0.2)
        .toStyle(color: tokens.textEmphasis);
    const maxLines = 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.clamp(0.0, 720.0);
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: maxWidth);

        final isOverflowing = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Text(
                  text,
                  maxLines: _isSynopsisExpanded ? null : maxLines,
                  overflow: _isSynopsisExpanded
                      ? TextOverflow.visible
                      : TextOverflow.fade,
                  style: style,
                ),
              ),
            ),
            if (isOverflowing) ...[
              const SizedBox(height: ZplaySpacing.s8),
              FocusableCard(
                onTap: () =>
                    setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                // A bare label is still a focus stop, and a stop a remote
                // cannot see is how this page ended up opening with nothing
                // ringed. The ring hugs the words.
                builder: (_, state) => CardFocusRing(
                  focused: state.focused,
                  radius: ZplayRadius.xsAll,
                  child: Text(
                    _isSynopsisExpanded
                        ? l10nOf(context).detailsShowLess
                        : l10nOf(context).detailsReadMore,
                    style: ZplayType.body
                        .copyWith(weight: FontWeight.w700)
                        .toStyle(color: tokens.textPrimary),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// The shared [SectionHeader], placed on this page's own grid.
  ///
  /// See [_onRailGrid] for why the header's own inset is cancelled.
  Widget _railHeader(String title) => _onRailGrid(SectionHeader(title: title));

  /// Cancels the 16 dp inset a rail's chrome bakes in.
  ///
  /// [SectionHeader] and [RailSkeleton] draw against the edge of a full-bleed
  /// rail on Home, where the row owns that inset itself. This page already pays
  /// its horizontal padding at the column level, so the inset is cancelled
  /// here rather than doubled: every row title and every placeholder sits on
  /// the same left edge as the cards beneath it, the way a rail does on Home.
  Widget _onRailGrid(Widget child) {
    return Transform.translate(
      offset: const Offset(-ZplaySpacing.s16, 0),
      child: child,
    );
  }

  /// The photo when there is one, the initials over the gradient otherwise
  /// (and while the photo loads or if it fails).
  Widget _castAvatarContent(
    String? photo,
    String initials,
    ZplayTokens tokens,
  ) {
    final text = Text(
      initials,
      style: ZplayType.label
          .copyWith(weight: FontWeight.w700)
          .toStyle(color: tokens.textPrimary),
    );
    if (photo == null) return text;
    return CachedNetworkImage(
      imageUrl: photo,
      cacheManager: AppImageCache.manager,
      memCacheWidth: 192,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      placeholder: (_, __) => Center(child: text),
      errorWidget: (_, __, ___) => Center(child: text),
    );
  }

  Widget _buildCastRow(List<CastMember> cast) {
    final tokens = context.tokens;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringCast = true),
      onExit: (_) => setState(() => _isHoveringCast = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _railHeader(l10nOf(context).detailsCast),
          const SizedBox(height: ZplaySpacing.s12),
          SizedBox(
            height: 132,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ListView.separated(
                  clipBehavior: Clip.none,
                  controller: _castScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: cast.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: ZplaySpacing.s24),
                  itemBuilder: (context, index) {
                    final member = cast[index];
                    final name = member.name;
                    final initials = name.isNotEmpty
                        ? name
                              .trim()
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join('')
                              .toUpperCase()
                        : '?';
                    final pair = _avatarGradient(
                      tokens,
                      name.hashCode.abs() % 4,
                    );

                    return SizedBox(
                      width: 84,
                      child: Column(
                        children: [
                          Builder(
                            builder: (context) {
                              Offset? lastTap;
                              return GestureDetector(
                                onTapDown: (d) => lastTap = d.globalPosition,
                                child: FocusableCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      LiquidRevealRoute(
                                        page: DiscoverPage(
                                          // The search knows them by the
                                          // name they were credited under.
                                          query: member.searchName,
                                          isGenre: false,
                                        ),
                                        tapPosition: lastTap,
                                      ),
                                    );
                                  },
                                  builder: (_, state) => AnimatedScale(
                                    scale: state.pressed
                                        ? 0.96
                                        : (state.highlighted ? 1.05 : 1.0),
                                    duration: ZplayMotion.fast,
                                    curve: ZplayMotion.standard,
                                    child: CardFocusRing(
                                      focused: state.focused,
                                      radius: ZplayRadius.fullAll,
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: pair,
                                          ),
                                          border: Border.all(
                                            color: tokens.textPrimary
                                                .withValues(
                                                  alpha:
                                                      ZplayOpacity.borderMedium,
                                                ),
                                            width: 1.5,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: _castAvatarContent(
                                          member.photo,
                                          initials,
                                          tokens,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: ZplaySpacing.s8),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ZplayType.bodySmall
                                .copyWith(height: 1.2, weight: FontWeight.w600)
                                .toStyle(color: tokens.textEmphasis),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (_isDesktop()) ...[
                  if (_canScrollCastLeft)
                    Positioned(
                      left: 0,
                      top: 10,
                      bottom: 40,
                      child: _buildScrollArrow(
                        Icons.arrow_back_ios_new_rounded,
                        () => _scrollList(_castScrollController, -1),
                        _isHoveringCast,
                      ),
                    ),
                  if (_canScrollCastRight)
                    Positioned(
                      right: 0,
                      top: 10,
                      bottom: 40,
                      child: _buildScrollArrow(
                        Icons.arrow_forward_ios_rounded,
                        () => _scrollList(_castScrollController, 1),
                        _isHoveringCast,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The season picker.
  ///
  /// Deliberately not [TabStrip]. That strip is the app's page-band control, and
  /// its selection reveal calls `Scrollable.ensureVisible`, which walks up
  /// *every* ancestor scrollable - inside this page's scroll view it would
  /// scroll the whole page to centre the strip on each season tap. The rows that
  /// use it (Home's filter row, Browse's verticals, Music's view bar) are all
  /// page chrome outside their scroll views for exactly that reason.
  ///
  /// So the strip keeps its own controller and arrows, and its chips now carry
  /// the app's single focus marker rather than only scaling on hover.
  Widget _buildSeasonSelector(MovieDetail meta) {
    final tokens = context.tokens;
    final seasons = meta.videos
        .map((v) => v.season)
        .whereType<int>()
        .toSet()
        .toList();
    seasons.sort();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringSeasons = true),
      onExit: (_) => setState(() => _isHoveringSeasons = false),
      child: SizedBox(
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ListView.separated(
              clipBehavior: Clip.none,
              controller: _seasonScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: seasons.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: ZplaySpacing.s12),
              itemBuilder: (context, index) {
                final season = seasons[index];
                final isSelected = _selectedSeason == season;
                return FocusableCard(
                  onTap: () {
                    if (_selectedSeason != season) {
                      setState(() {
                        _previousSeason = _selectedSeason;
                        _selectedSeason = season;
                      });
                      _updateEpisodesForSeason();
                    }
                  },
                  builder: (_, state) => AnimatedScale(
                    scale: state.pressed
                        ? 0.96
                        : (state.highlighted ? 1.02 : 1.0),
                    duration: ZplayMotion.fast,
                    curve: ZplayMotion.standard,
                    child: CardFocusRing(
                      focused: state.focused,
                      radius: ZplayRadius.lgAll,
                      child: AnimatedContainer(
                        duration: ZplayMotion.base,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tokens.textPrimary
                              : tokens.textPrimary.withValues(
                                  alpha: ZplayOpacity.borderSubtle,
                                ),
                          borderRadius: ZplayRadius.lgAll,
                          border: Border.all(
                            color: isSelected
                                ? tokens.textPrimary
                                : tokens.textPrimary.withValues(
                                    alpha: ZplayOpacity.borderMedium,
                                  ),
                          ),
                        ),
                        child: Text(
                          l10nOf(context).detailsSeason(season),
                          style: ZplayType.subtitle
                              .copyWith(
                                weight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              )
                              .toStyle(
                                color: isSelected
                                    ? tokens.bg
                                    : tokens.textPrimary,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_isDesktop()) ...[
              if (_canScrollSeasonsLeft)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildScrollArrow(
                    Icons.arrow_back_ios_new_rounded,
                    () => _scrollList(_seasonScrollController, -1),
                    _isHoveringSeasons,
                  ),
                ),
              if (_canScrollSeasonsRight)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildScrollArrow(
                    Icons.arrow_forward_ios_rounded,
                    () => _scrollList(_seasonScrollController, 1),
                    _isHoveringSeasons,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Past this many episodes a season is a grid of numbers, not a row of
  /// cards: one glance instead of a long sideways scroll.
  static const int _gridThreshold = 20;

  Widget _buildEpisodeSlider({Key? key}) {
    final isDesktop = _isDesktop();
    final cardWidth = isDesktop ? 300.0 : 230.0;

    return MouseRegion(
      key: key,
      onEnter: (_) => setState(() => _isHoveringEpisodes = true),
      onExit: (_) => setState(() => _isHoveringEpisodes = false),
      child: SizedBox(
        height: isDesktop ? 275 : 245,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // The shared edge fade rather than a private `ShaderMask`: the row
            // signals that it continues the way every other horizontal row in
            // the app does, and it drops the fade on a side that has nothing
            // left to reach.
            HorizontalEdgeFade(
              scrollController: _episodeScrollController,
              extent: isDesktop ? 60 : 40,
              child: ListView.separated(
                clipBehavior: Clip.hardEdge,
                controller: _episodeScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _currentSeasonEpisodes.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: ZplaySpacing.s16),
                itemBuilder: (context, index) {
                  final ep = _currentSeasonEpisodes[index];
                  return SizedBox(
                    width: cardWidth,
                    child: _EpisodeCard(
                      episode: ep,
                      resume: _resumeFor(ep),
                      watched: _isWatched(ep),
                      fallbackImageUrl:
                          _detail?.background ??
                          _detail?.poster ??
                          widget.movie.poster,
                      onTap: () => _handlePlayAction(ep),
                      isCollection: _isCollection,
                    ),
                  );
                },
              ),
            ),
            if (isDesktop) ...[
              if (_canScrollEpisodesLeft)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildScrollArrow(
                    Icons.arrow_back_ios_new_rounded,
                    () => _scrollList(_episodeScrollController, -1),
                    _isHoveringEpisodes,
                  ),
                ),
              if (_canScrollEpisodesRight)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildScrollArrow(
                    Icons.arrow_forward_ios_rounded,
                    () => _scrollList(_episodeScrollController, 1),
                    _isHoveringEpisodes,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // "More Like This" — fills the dead space at the bottom of the page and
  // gives people somewhere to go next instead of hitting a wall of black.
  //
  // The cards are the shared [MovieCard], so a film in this row is the same
  // object as a film in a Home rail: same artwork, same single focus ring, same
  // focus panel. It was a private `_HoverButton` around a bare poster, which is
  // a card that grew but never said what it was.
  Widget _buildRelatedRow(List<Movie> related) {
    final isDesktop = _isDesktop();
    final sizing = MovieCardSizing.fromWidth(MediaQuery.sizeOf(context).width);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringRelated = true),
      onExit: (_) => setState(() => _isHoveringRelated = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _railHeader(l10nOf(context).detailsMoreLikeThis),
          const SizedBox(height: ZplaySpacing.s12),
          SizedBox(
            height: sizing.totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                HorizontalEdgeFade(
                  scrollController: _relatedScrollController,
                  extent: isDesktop ? 60 : 40,
                  child: ListView.separated(
                    clipBehavior: Clip.none,
                    controller: _relatedScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: related.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: sizing.spacing),
                    itemBuilder: (context, index) {
                      final item = related[index];
                      return SizedBox(
                        width: sizing.cardWidth,
                        child: MovieCard(
                          movie: item,
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsPage(movie: item),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (isDesktop) ...[
                  if (_canScrollRelatedLeft)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildScrollArrow(
                        Icons.arrow_back_ios_new_rounded,
                        () => _scrollList(_relatedScrollController, -1),
                        _isHoveringRelated,
                      ),
                    ),
                  if (_canScrollRelatedRight)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildScrollArrow(
                        Icons.arrow_forward_ios_rounded,
                        () => _scrollList(_relatedScrollController, 1),
                        _isHoveringRelated,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Similar Content" — the scraper's own recommendations for this title.
  ///
  /// The cards are the shared [MovieCard], built from a display-only [Movie];
  /// the tap still goes through [_openSimilarItem], which is what resolves a
  /// scraper row to a real title. That drops the old card's accent-bordered
  /// similarity percentage: the shared card owns a row's anatomy, and an accent
  /// box drawn on a card is the decorative chrome the design language keeps out
  /// of a rail. The rating it also showed is now the card's own badge.
  Widget _buildSimilarRow() {
    final isDesktop = _isDesktop();
    final sizing = MovieCardSizing.fromWidth(MediaQuery.sizeOf(context).width);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringSimilar = true),
      onExit: (_) => setState(() => _isHoveringSimilar = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _railHeader(l10nOf(context).detailsSimilar),
          const SizedBox(height: ZplaySpacing.s12),
          SizedBox(
            height: sizing.totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                HorizontalEdgeFade(
                  scrollController: _similarScrollController,
                  extent: isDesktop ? 60 : 40,
                  child: ListView.separated(
                    clipBehavior: Clip.none,
                    controller: _similarScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _similarItems.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: sizing.spacing),
                    itemBuilder: (context, index) {
                      final item = _similarItems[index];
                      return SizedBox(
                        width: sizing.cardWidth,
                        child: MovieCard(
                          movie: _similarItemAsMovie(item),
                          onTap: () => _openSimilarItem(item),
                        ),
                      );
                    },
                  ),
                ),
                if (isDesktop) ...[
                  if (_canScrollSimilarLeft)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildScrollArrow(
                        Icons.arrow_back_ios_new_rounded,
                        () => _scrollList(_similarScrollController, -1),
                        _isHoveringSimilar,
                      ),
                    ),
                  if (_canScrollSimilarRight)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildScrollArrow(
                        Icons.arrow_forward_ios_rounded,
                        () => _scrollList(_similarScrollController, 1),
                        _isHoveringSimilar,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollArrow(IconData icon, VoidCallback onTap, bool isVisible) {
    final tokens = context.tokens;

    return Center(
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: ZplayMotion.base,
        child: IgnorePointer(
          ignoring: !isVisible,
          // An invisible arrow must not be a focus stop: IgnorePointer blocks
          // taps but not focus, so a remote would land on a control that is not
          // on screen. ExcludeFocus wraps the focusable itself, because the
          // arrow is drawn as a [FocusableCard] the remote can reach.
          child: ExcludeFocus(
            excluding: !isVisible,
            child: FocusableCard(
              onTap: onTap,
              builder: (_, state) => AnimatedScale(
                scale: state.pressed ? 0.96 : (state.highlighted ? 1.1 : 1.0),
                duration: ZplayMotion.fast,
                curve: ZplayMotion.standard,
                child: CardFocusRing(
                  focused: state.focused,
                  radius: ZplayRadius.fullAll,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: tokens.bg.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tokens.textPrimary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(icon, color: tokens.textPrimary, size: 18),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `12:40` for a position, `1:02:40` past the hour.
String _clock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

class _EpisodeCard extends StatelessWidget {
  final Video episode;
  final String? fallbackImageUrl;
  final VoidCallback? onTap;
  final bool isCollection;

  /// The viewer's unfinished session when it is on this episode: the card
  /// says where they stopped, draws the progress along the art's bottom edge
  /// and is outlined in the accent so the row shows where to pick up.
  final ContinueWatchingItem? resume;

  /// Finished: the card says 已看.
  final bool watched;

  const _EpisodeCard({
    required this.episode,
    this.resume,
    this.watched = false,
    this.fallbackImageUrl,
    this.onTap,
    this.isCollection = false,
  });

  /// The episode's date, trimmed to what the card's meta line can carry: a year
  /// for a collection entry, a `YYYY-MM-DD` for an episode. Null when the source
  /// gave no usable date, so the row can drop the column rather than print `--`.
  String? get _releaseLabel {
    final released = episode.released;
    if (released == null || released.length < 4) return null;
    if (isCollection) return released.substring(0, 4);
    return released.length >= 10 ? released.substring(0, 10) : released;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ep = episode;
    final imgUrl = ep.thumbnail ?? fallbackImageUrl;

    return FocusableCard(
      onTap: onTap,
      enabled: onTap != null,
      builder: (_, state) {
        return AnimatedScale(
          scale: state.highlighted ? 1.03 : 1.0,
          duration: ZplayMotion.base,
          curve: ZplayMotion.standard,
          // The ring is the card's only focus marker. It used to brighten the
          // frame's own hairline on hover as well, which is a second indicator
          // for the same state; the lift and the play glyph are pointer
          // feedback and stay.
          child: CardFocusRing(
            focused: state.focused,
            radius: ZplayRadius.smAll,
            child: Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: ZplayRadius.smAll,
                border: Border.all(
                  color: resume != null ? tokens.accent : tokens.borderSubtle,
                  width: resume != null ? 2 : 1,
                ),
                boxShadow: state.highlighted
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: ZplayRadius.smAll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imgUrl != null)
                            CachedNetworkImage(
                              imageUrl: imgUrl,
                              cacheManager: AppImageCache.manager,
                              memCacheWidth: 330,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  ColoredBox(color: tokens.surfaceRaised),
                            )
                          else
                            ColoredBox(color: tokens.surfaceRaised),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  tokens.bg.withValues(alpha: 0.75),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                          // The prototype puts the episode number on the art
                          // rather than in the text block, so a row of episodes
                          // can be told apart at a glance while scanning.
                          Positioned(
                            left: ZplaySpacing.s8,
                            bottom: ZplaySpacing.s8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: tokens.bg.withValues(alpha: 0.8),
                                borderRadius: ZplayRadius.xsAll,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: ZplaySpacing.s4,
                                  vertical: ZplaySpacing.s2,
                                ),
                                child: Text(
                                  isCollection
                                      ? l10nOf(
                                          context,
                                        ).detailsPartBadge('${ep.episode ?? "?"}')
                                      : l10nOf(context).detailsEpisodeBadge(
                                          '${ep.episode ?? "?"}',
                                        ),
                                  style: ZplayType.caption
                                      .copyWith(weight: FontWeight.w700)
                                      .toStyle(color: tokens.textPrimary),
                                ),
                              ),
                            ),
                          ),
                          if (watched && resume == null)
                            Positioned(
                              right: ZplaySpacing.s8,
                              top: ZplaySpacing.s8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: tokens.bg.withValues(alpha: 0.8),
                                  borderRadius: ZplayRadius.xsAll,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ZplaySpacing.s4,
                                    vertical: ZplaySpacing.s2,
                                  ),
                                  child: Text(
                                    l10nOf(context).detailsWatched,
                                    style: ZplayType.caption.toStyle(
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (resume case final resume?) ...[
                            Positioned(
                              right: ZplaySpacing.s8,
                              top: ZplaySpacing.s8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: ZplayRadius.xsAll,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ZplaySpacing.s8,
                                    vertical: ZplaySpacing.s2,
                                  ),
                                  child: Text(
                                    l10nOf(context).detailsWatchedTo(
                                      _clock(resume.positionSeconds),
                                    ),
                                    style: ZplayType.caption.toStyle(
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: LinearProgressIndicator(
                                value: resume.progressPercent,
                                minHeight: 4,
                                color: tokens.accent,
                                backgroundColor: tokens.textPrimary.withValues(
                                  alpha: 0.22,
                                ),
                              ),
                            ),
                          ],
                          Center(
                            child: AnimatedOpacity(
                              opacity: state.highlighted ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: tokens.textPrimary.withValues(
                                    alpha: 0.95,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: tokens.bg,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(ZplaySpacing.s12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ep.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ZplayType.label
                                      .copyWith(weight: FontWeight.w600)
                                      .toStyle(color: tokens.textPrimary),
                                ),
                              ),
                              // The number moved onto the thumbnail, so it is not
                              // repeated here; the row carries the release date.
                              if (_releaseLabel != null) ...[
                                const SizedBox(width: ZplaySpacing.s8),
                                Text(
                                  _releaseLabel!,
                                  style: ZplayType.caption.toStyle(
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (ep.overview != null) ...[
                            const SizedBox(height: ZplaySpacing.s4),
                            Text(
                              ep.overview!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ZplayType.bodySmall
                                  .copyWith(height: 1.3)
                                  .toStyle(color: tokens.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
