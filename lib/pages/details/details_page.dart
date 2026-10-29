import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/continue_watching/continue_watching_item.dart';
import '../../models/movie/episode_order.dart';
import '../../models/movie/movie.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/movie/video.dart';
import '../../models/my_list/my_list_item.dart';
import '../../services/continue_watching/continue_watching_service.dart';
import '../../services/continue_watching/watched_episodes.dart';
import '../../services/layout/form_factor.dart';
import '../../services/metadata/bestsimilar_scraper.dart';
import '../../services/metadata/episode_art.dart';
import '../../services/metadata/localized_meta.dart';
import '../../services/metadata/metadata_service.dart';
import '../../services/metadata/tmdb_catalog.dart';
import '../../services/my_list/my_list_service.dart';
import '../../services/player/source_pick_settings.dart';
import '../../services/playback/play_launcher.dart';
import '../../services/recommend/taste_store.dart';
import '../../services/stream/auto_source_picker.dart' show parseRuntime;
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';
import '../../utils/navigation/route_transitions.dart';
import '../../widgets/common/trailer_modal.dart';
import '../discover/discover_page.dart';
import '../player/watch_screen.dart';
import 'episode_number_grid.dart';
import '../../widgets/watch_providers/watch_providers_panel.dart';

/// A `bestsimilar_` row resolved to real details: the meta that was found plus
/// the identity it was found under, so the page can report the winning addon
/// and type the same way the plain id path does.
typedef _ResolvedBestsimilar = ({
  MovieDetail meta,
  String id,
  String type,
  String baseUrl,
});

/// 详情, as designed: the backdrop behind a title block on the left, the
/// actions that follow the viewer's progress (继续 第 3 集 · 12:40), and the
/// seasons and episodes inside the first screen, then 演员 and 相似推荐.
///
/// Written fresh on the Lumora kit (`lib/ui`); how a title is resolved, where
/// playback starts and what counts as watched are the app's own services.
class DetailsPage extends StatefulWidget {
  final Movie movie;

  /// Optional "More Like This" row the caller already has.
  final List<Movie>? relatedItems;

  const DetailsPage({super.key, required this.movie, this.relatedItems});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  MovieDetail? _detail;
  bool _isLoading = true;

  /// The remote's landing place: a television opens on the primary action.
  final FocusNode _primaryActionFocus = FocusNode(
    debugLabel: 'DetailsPrimaryAction',
  );
  bool _claimedPrimaryActionFocus = false;

  int? _selectedSeason;
  List<Video> _currentSeasonEpisodes = [];
  final ScrollController _episodeScroll = ScrollController();

  bool _isSynopsisExpanded = false;

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

  /// The number viewers know [season]x[episode] by (see
  /// [Video.displayNumber]).
  int _shownNumberOf(int? season, int episode) {
    for (final v in _detail?.videos ?? const <Video>[]) {
      if (v.season == season && v.episode == episode) {
        return v.shownNumber ?? episode;
      }
    }
    return episode;
  }

  /// The primary action's words: where the viewer is, not just "play".
  String get _playLabel {
    final l10n = l10nOf(context);
    final resume = _resumeItem;
    if (resume != null) {
      final time = _clock(resume.positionSeconds);
      return resume.episode != null
          ? l10n.detailsResumeEpisode(
              _shownNumberOf(resume.season, resume.episode!),
              time,
            )
          : l10n.detailsResume(time);
    }
    if (_nextUp case final next?) {
      return (next.season ?? 1) > 1 && next.displayNumber == null
          ? l10n.detailsPlaySeasonEpisode(next.season!, next.episode!)
          : l10n.detailsPlayEpisode(next.shownNumber!);
    }
    return _isCollection
        ? l10n.detailsPlayFirstMovie
        : (_isSeries ? l10n.detailsPlayEpisodes : l10n.detailsPlayMovie);
  }

  /// The unfinished session for this title, if the viewer has one.
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

  @override
  void initState() {
    super.initState();
    ContinueWatchingService.activeItems.addListener(_onSessionsChanged);
    WatchedEpisodes.shows.addListener(_onSessionsChanged);
    _fetchDetails();
  }

  @override
  void dispose() {
    ContinueWatchingService.activeItems.removeListener(_onSessionsChanged);
    WatchedEpisodes.shows.removeListener(_onSessionsChanged);
    _primaryActionFocus.dispose();
    _episodeScroll.dispose();
    super.dispose();
  }

  Future<void> _handlePlayAction(Video? ep) async {
    if (_detail == null) return;
    // An episode that has not aired has nothing to find yet: say when it
    // comes out instead of opening a source search that can only fail.
    if (ep != null && !episodeIsOut(ep)) {
      final day = episodeAirDay(ep)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10nOf(context).epNotOutYet(
                '${ep.shownNumber ?? ''}',
                episodeAirLabel(context, day),
              ),
            ),
          ),
        );
      return;
    }
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

  /// [_loadDetails], never leaving the page loading: a throw or a path
  /// that returns without a detail ends on the unavailable state.
  Future<void> _fetchDetails() async {
    try {
      await _loadDetails();
    } catch (e) {
      debugPrint('[Details] ${widget.movie.id}: $e');
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDetails() async {
    String effectiveBaseUrl = widget.movie.addonBaseUrl;
    String effectiveType = widget.movie.type;
    String effectiveId = widget.movie.id;

    // A row from a TMDb list (the category pages) carries its TMDb id until
    // it is opened; the details and every source lookup need the IMDb one.
    if (effectiveId.startsWith('tmdb:')) {
      final resolved = await TmdbCatalog.resolve(widget.movie);
      if (!mounted) return;
      if (resolved != null) {
        effectiveId = resolved.id;
      } else {
        // No IMDb id: the addons cannot describe it, TMDb can.
        final fromTmdb = await TmdbCatalog.detailFromTmdb(widget.movie);
        if (!mounted) return;
        if (fromTmdb != null) {
          _showDetail(fromTmdb);
          return;
        }
      }
    }

    // Legacy CloudStream entries are no longer resolvable.
    if (effectiveId.startsWith('cloudstream:') ||
        effectiveId.startsWith('cloudstream_ep:') ||
        effectiveBaseUrl == 'cloudstream') {
      await Future<void>.delayed(Duration.zero);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(l10nOf(context).detailsSourceNoLongerSupported),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10nOf(context).detailsGoBack),
              ),
            ],
          ),
        );
      }
      return;
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

    // A TMDb row whose IMDb id the addons do not know: TMDb describes it.
    if (meta == null && widget.movie.id.startsWith('tmdb:')) {
      final fromTmdb = await TmdbCatalog.detailFromTmdb(widget.movie);
      if (!mounted) return;
      if (fromTmdb != null) {
        _showDetail(fromTmdb);
        return;
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
      _claimPrimaryActionFocus();

      // Fire off similar content fetch in background
      _fetchSimilarContent();
      if (meta != null) _addEpisodeArt(meta);
    }
  }

  /// Shows [meta] the way a fetched detail is shown: opening season, focus,
  /// then the similar titles.
  void _showDetail(MovieDetail meta) {
    _resolvedType = meta.type;
    setState(() {
      _detail = meta;
      _isLoading = false;
      final seasons = <int?>[
        ...meta.videos.map((v) => v.season).whereType<int>().toSet(),
      ]..sort((a, b) => a!.compareTo(b!));
      if (seasons.isNotEmpty) {
        _selectedSeason = _openingSeason(seasons);
        _updateEpisodesForSeason();
      } else {
        _currentSeasonEpisodes = List.from(meta.videos);
      }
    });
    _claimPrimaryActionFocus();
    _fetchSimilarContent();
    _addEpisodeArt(meta);
  }

  /// TMDb's stills and episode names, once they arrive, over the addon's
  /// missing images and "Episode 4" placeholders. Episode ids are untouched.
  void _addEpisodeArt(MovieDetail meta) {
    EpisodeArt.enrich(meta).then((better) {
      if (!mounted || identical(better, meta) || !identical(_detail, meta)) {
        return;
      }
      setState(() {
        _detail = better;
        if (_selectedSeason != null) {
          _currentSeasonEpisodes =
              better.videos.where((v) => v.season == _selectedSeason).toList()
                ..sort((a, b) => (a.episode ?? 0).compareTo(b.episode ?? 0));
        }
      });
    });
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
      _currentSeasonEpisodes =
          _detail!.videos.where((v) => v.season == _selectedSeason).toList()
            ..sort((a, b) => (a.episode ?? 0).compareTo(b.episode ?? 0));
    });

    // Open the row on the episode the primary action plays, not on episode 1.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_episodeScroll.hasClients) return;
      final target = _currentEpisodeTarget;
      final index = target == null
          ? -1
          : _currentSeasonEpisodes.indexWhere(
              (v) => v.season == target.season && v.episode == target.episode,
            );
      final step = _episodeWidth(context) + 16;
      _episodeScroll.jumpTo(
        index <= 0
            ? 0
            : (index * step - step / 2).clamp(
                0.0,
                _episodeScroll.position.maxScrollExtent,
              ),
      );
    });
  }

  void _selectSeason(int season) {
    if (_selectedSeason == season) return;
    setState(() => _selectedSeason = season);
    _updateEpisodesForSeason();
  }

  /// Hands the remote to the primary action once it exists; a pointer device
  /// is left alone.
  void _claimPrimaryActionFocus() {
    if (_claimedPrimaryActionFocus || !FormFactorService.hasRemoteInput) {
      return;
    }
    _claimedPrimaryActionFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _primaryActionFocus.requestFocus();
    });
  }

  void _toggleMyList() {
    final d = _detail;
    if (d == null) return;
    MyListService.toggle(_listItem(d));
  }

  MyListItem _listItem(MovieDetail d) => MyListItem.fromMovieDetail(
    id: d.id,
    name: d.name,
    poster: d.poster,
    year: d.year,
    type: d.type,
    imdbId: d.id.startsWith('tt') ? d.id : null,
    tmdbId: d.tmdbId != null ? int.tryParse(d.tmdbId!) : null,
  );

  void _playPrimary() {
    final resume = _resumeItem;
    if (resume != null) {
      ContinueWatchingService.resumePlayback(context, resume);
      return;
    }
    _handlePlayAction(
      _nextUp ??
          _episodeOrder.firstOrNull ??
          _currentSeasonEpisodes.firstOrNull ??
          _detail?.videos.firstOrNull,
    );
  }

  // -------------------------------------------------------------------------
  // Layout
  // -------------------------------------------------------------------------

  bool _phone(BuildContext context) => MediaQuery.sizeOf(context).width < 600;

  double _pad(BuildContext context) {
    if (_phone(context)) return 16;
    return FormFactorService.of(context) == FormFactor.television
        ? 48
        : LuSpace.page;
  }

  double _episodeWidth(BuildContext context) => _phone(context) ? 200 : 260;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: luTheme(),
      child: Scaffold(
        backgroundColor: LuColors.bg,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: LuColors.gold),
              )
            : _detail == null
            ? _buildError()
            : _buildContent(context, _detail!),
      ),
    );
  }

  Widget _buildError() {
    final l10n = l10nOf(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_rounded,
            size: 56,
            color: LuColors.textFaint,
          ),
          const SizedBox(height: 16),
          Text(l10n.detailsUnavailable, style: LuText.heading),
          const SizedBox(height: 24),
          LuButton(
            label: l10n.detailsGoBack,
            kind: LuButtonKind.secondary,
            autofocus: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MovieDetail meta) {
    final l10n = l10nOf(context);
    final size = MediaQuery.sizeOf(context);
    final phone = _phone(context);
    final pad = _pad(context);
    final top = MediaQuery.paddingOf(context).top;
    final backdropHeight = phone
        ? (size.width * 0.9).clamp(300.0, 460.0)
        : (size.height * 0.72).clamp(420.0, 720.0);
    final seasons =
        meta.videos.map((v) => v.season).whereType<int>().toSet().toList()
          ..sort();

    final header = Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: backdropHeight,
          child: _Backdrop(
            url: meta.background ?? meta.poster ?? widget.movie.poster,
            phone: phone,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            pad,
            top + (phone ? 12 : (size.height < 700 ? 16 : 28)),
            pad,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundIcon(
                icon: Icons.arrow_back_ios_new_rounded,
                label: l10n.detailsGoBack,
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(
                height: phone
                    ? backdropHeight * 0.24
                    : (size.height < 700 ? 6 : 48),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _buildInfo(meta, phone: phone),
              ),
              if (meta.videos.isNotEmpty) ...[
                SizedBox(height: phone ? 28 : (size.height < 700 ? 14 : 40)),
                if (seasons.length > 1) ...[
                  _buildSeasonChips(seasons),
                  const SizedBox(height: 16),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      _isCollection
                          ? l10n.detailsCollectionMovies
                          : l10n.detailsEpisodes,
                      style: LuText.heading,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: header),
        // Where to watch: official services, opened in their own apps.
        if (!_isCollection)
          SliverToBoxAdapter(
            child: WatchProvidersPanel(
              detail: meta,
              type: _resolvedType ?? meta.type,
              padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
            ),
          ),
        if (meta.videos.isNotEmpty)
          SliverToBoxAdapter(child: _buildEpisodes(pad)),
        if (meta.cast.isNotEmpty)
          SliverToBoxAdapter(
            child: FutureBuilder<List<CastMember>?>(
              future: _localCast(meta),
              builder: (context, snap) => _buildCast(
                snap.data ?? [for (final n in meta.cast) CastMember(n)],
                pad,
              ),
            ),
          ),
        if (widget.relatedItems case final related? when related.isNotEmpty)
          SliverToBoxAdapter(child: _buildRelated(related, pad)),
        if (_similarItems.isNotEmpty)
          SliverToBoxAdapter(child: _buildSimilar(pad))
        else if (_isFetchingSimilar)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LuColors.gold,
                  ),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: 56 + MediaQuery.paddingOf(context).bottom),
        ),
      ],
    );
  }

  /// Title, facts, synopsis and the actions.
  Widget _buildInfo(MovieDetail meta, {required bool phone}) {
    final l10n = l10nOf(context);
    // A television's 540 dp: everything a notch tighter so the episodes still
    // start on the first screen.
    final short = !phone && MediaQuery.sizeOf(context).height < 700;
    final facts = <Widget>[
      if (meta.imdbRating case final r? when r.isNotEmpty)
        Text(
          '★ $r',
          style: LuText.body.copyWith(
            color: LuColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
      if (meta.displayGenres.isNotEmpty)
        Text(meta.displayGenres.take(3).join(' / '), style: LuText.bodySoft),
      if (meta.year case final y? when y.isNotEmpty)
        Text(y, style: LuText.bodySoft),
      if (_isSeries)
        // A show counted straight through says how many episodes it has;
        // otherwise the seasons, specials (season 0) not counted as one.
        if (meta.videos.any((v) => v.displayNumber != null))
          Text(
            l10n.wgAniEpisodeCount(
              meta.videos
                  .where((v) => (v.season ?? 0) > 0)
                  .map((v) => v.shownNumber ?? 0)
                  .fold<int>(0, (a, b) => a > b ? a : b),
            ),
            style: LuText.bodySoft,
          )
        else if (meta.videos
                .map((v) => v.season)
                .whereType<int>()
                .where((s) => s > 0)
                .toSet()
                .length
            case final n when n > 0)
          Text(l10n.detailsSeasonCount(n), style: LuText.bodySoft),
      if (!_isSeries)
        if (meta.runtime case final rt? when rt.isNotEmpty)
          // Cinemeta writes English ("114 min", "1h 30min"); read the
          // minutes out and say them in the UI's language.
          Text(switch (parseRuntime(rt)) {
            final d? => l10n.detailsRuntimeMinutes(d.inMinutes),
            null => rt,
          }, style: LuText.bodySoft),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meta.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: LuText.hero.copyWith(
            fontSize: phone ? 32 : (short ? 36 : 56),
            shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 24)],
          ),
        ),
        SizedBox(height: short ? 8 : 14),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < facts.length; i++) ...[
              if (i > 0)
                const Text('·', style: TextStyle(color: LuColors.textFaint)),
              facts[i],
            ],
          ],
        ),
        if (meta.displayDescription case final text? when text.isNotEmpty) ...[
          SizedBox(height: short ? 8 : 14),
          _Synopsis(
            text: text,
            expanded: _isSynopsisExpanded,
            lines: short ? 2 : 3,
            moreLabel: l10n.detailsReadMore,
            lessLabel: l10n.detailsShowLess,
            onToggle: () =>
                setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
          ),
        ],
        SizedBox(height: short ? 14 : 22),
        if (phone) ...[
          _buildPlayButton(expand: true),
          const SizedBox(height: 14),
          _buildPhoneActions(meta),
          const SizedBox(height: 14),
          _buildSourceMode(),
        ] else ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPlayButton(),
              _buildListButton(),
              if (meta.trailerKey ?? widget.movie.trailerKey case final key?
                  when key.isNotEmpty)
                LuButton(
                  label: l10n.homeTrailer,
                  icon: Icons.smart_display_outlined,
                  kind: LuButtonKind.secondary,
                  onPressed: () => TrailerModal.show(
                    context,
                    trailerKey: key,
                    title: meta.displayName,
                  ),
                ),
              ..._buildRating(meta),
              // A television keeps the source mode on the same line, so the
              // episodes still start on the first screen.
              if (short) _buildSourceMode(),
            ],
          ),
          if (!short) ...[const SizedBox(height: 14), _buildSourceMode()],
        ],
      ],
    );
  }

  /// A phone's second row: My List, the trailer and 👍 / 👎 as equal
  /// icon-over-label buttons, so the row is balanced whatever is present.
  Widget _buildPhoneActions(MovieDetail meta) {
    final l10n = l10nOf(context);
    final trailer = meta.trailerKey ?? widget.movie.trailerKey;
    final id = meta.id;
    return ValueListenableBuilder<List<MyListItem>>(
      valueListenable: MyListService.items,
      builder: (context, _, __) =>
          ValueListenableBuilder<Map<String, TasteEntry>>(
            valueListenable: TasteStore.entries,
            builder: (context, entries, _) {
              final d = _detail;
              final inList = d != null && MyListService.isInList(_listItem(d));
              final rating = entries[id]?.rating ?? 0;
              void rate(int value) => TasteStore.recordRating(
                id,
                title: meta.name,
                series: _isSeries,
                rating: rating == value ? 0 : value,
              );
              final actions = <Widget>[
                _PhoneAction(
                  icon: inList ? Icons.check_rounded : Icons.add_rounded,
                  label: inList ? l10n.detailsInLibrary : l10n.catAddToList,
                  active: inList,
                  onTap: _toggleMyList,
                ),
                if (trailer != null && trailer.isNotEmpty)
                  _PhoneAction(
                    icon: Icons.smart_display_outlined,
                    label: l10n.homeTrailer,
                    onTap: () => TrailerModal.show(
                      context,
                      trailerKey: trailer,
                      title: meta.displayName,
                    ),
                  ),
                if (id.startsWith('tt')) ...[
                  _PhoneAction(
                    icon: rating == 1
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_up_outlined,
                    label: l10n.detailsLike,
                    active: rating == 1,
                    onTap: () => rate(1),
                  ),
                  _PhoneAction(
                    icon: rating == -1
                        ? Icons.thumb_down_rounded
                        : Icons.thumb_down_outlined,
                    label: l10n.detailsDislike,
                    active: rating == -1,
                    onTap: () => rate(-1),
                  ),
                ],
              ];
              return Row(
                children: [for (final a in actions) Expanded(child: a)],
              );
            },
          ),
    );
  }

  /// 播放 / 继续 第 3 集 · 12:40, with the session's progress under it.
  Widget _buildPlayButton({bool expand = false}) {
    final resume = _resumeItem;
    final button = LuButton(
      label: _playLabel,
      icon: Icons.play_arrow_rounded,
      expand: expand,
      focusNode: _primaryActionFocus,
      onPressed: _playPrimary,
    );
    if (resume == null) return button;
    return Stack(
      children: [
        button,
        Positioned(
          left: 24,
          right: 24,
          bottom: 7,
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: LuRadius.pill,
              child: LinearProgressIndicator(
                value: resume.progressPercent,
                minHeight: 3,
                color: LuColors.onGold,
                backgroundColor: LuColors.onGold.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListButton() {
    return ValueListenableBuilder<List<MyListItem>>(
      valueListenable: MyListService.items,
      builder: (context, _, __) {
        final d = _detail;
        final inList = d != null && MyListService.isInList(_listItem(d));
        final l10n = l10nOf(context);
        return LuButton(
          label: inList ? l10n.detailsInLibrary : l10n.catAddToList,
          icon: inList ? Icons.check_rounded : Icons.add_rounded,
          kind: LuButtonKind.secondary,
          onPressed: _toggleMyList,
        );
      },
    );
  }

  /// 片源：自动选最快 / 自己选, which pressing switches.
  Widget _buildSourceMode() {
    return ValueListenableBuilder<bool>(
      valueListenable: SourcePickSettings.autoPick,
      builder: (context, auto, _) => _Chip(
        icon: auto ? Icons.bolt_rounded : Icons.list_rounded,
        label: auto
            ? l10nOf(context).detailsSourceAuto
            : l10nOf(context).detailsSourceManual,
        onTap: () => SourcePickSettings.setAutoPick(!auto),
      ),
    );
  }

  /// 👍 / 👎: the strongest taste signal 为你推荐 gets.
  List<Widget> _buildRating(MovieDetail meta) {
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
          final l10n = l10nOf(context);
          return Wrap(
            spacing: 12,
            children: [
              _Disc(
                icon: rating == 1
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
                label: l10n.detailsLike,
                active: rating == 1,
                onTap: () => rate(1),
              ),
              _Disc(
                icon: rating == -1
                    ? Icons.thumb_down_rounded
                    : Icons.thumb_down_outlined,
                label: l10n.detailsDislike,
                active: rating == -1,
                onTap: () => rate(-1),
              ),
            ],
          );
        },
      ),
    ];
  }

  /// A season chip's words: 第 2 季, or the episodes it holds (第 22-46 集)
  /// when the cards count the show straight through.
  String _seasonLabel(int season) {
    final l10n = l10nOf(context);
    final videos = _detail?.videos ?? const <Video>[];
    // One renumbered episode means the whole show is counted straight
    // through, season 1 included (its numbers just happen to agree).
    if (!videos.any((v) => v.displayNumber != null)) {
      return l10n.detailsSeason(season);
    }
    final shown = [
      for (final v in videos)
        if (v.season == season && v.shownNumber != null) v.shownNumber!,
    ];
    if (shown.isEmpty) return l10n.detailsSeason(season);
    shown.sort();
    return l10n.detailsEpisodeRange('${shown.first}', '${shown.last}');
  }

  Widget _buildSeasonChips(List<int> seasons) {
    final l10n = l10nOf(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: seasons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = seasons[i];
          final on = s == _selectedSeason;
          return Center(
            child: LuFocusable(
              onTap: () => _selectSeason(s),
              builder: (context, hi) => AnimatedContainer(
                duration: LuMotion.focus,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? LuColors.text
                      : (hi ? const Color(0x1FFFFFFF) : Colors.transparent),
                  borderRadius: LuRadius.pill,
                  border: on ? null : Border.all(color: LuColors.line),
                ),
                child: Text(
                  // Season 0 is TMDb's specials, not a season.
                  s == 0 ? l10n.detailsSpecials : _seasonLabel(s),
                  style: LuText.body.copyWith(
                    fontSize: 15,
                    color: on ? LuColors.bg : LuColors.textSoft,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpisodes(double pad) {
    final episodes = _currentSeasonEpisodes.isNotEmpty
        ? _currentSeasonEpisodes
        : _detail!.videos;
    if (episodes.length > _gridThreshold && !_isCollection) {
      return Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
        child: EpisodeNumberGrid(
          key: ValueKey(_selectedSeason),
          episodes: episodes,
          current: _currentEpisodeTarget,
          isWatched: _isWatched,
          progressFor: (ep) => _resumeFor(ep)?.progressPercent,
          onTap: _handlePlayAction,
        ),
      );
    }
    final width = _episodeWidth(context);
    final target = _currentEpisodeTarget;
    final fallback = _detail?.background ?? _detail?.poster;
    // The still, the list's padding (12) and the gap under it (8), then the
    // label and title lines at the viewer's text size, with a little slack.
    final scaler = MediaQuery.textScalerOf(context);
    final lines = (scaler.scale(16) + scaler.scale(13)) * 1.6;
    final height = width * 9 / 16 + 20 + lines + 2;
    return SizedBox(
      height: height,
      child: LuSideScroll(
        controller: _episodeScroll,
        // On the still, not on the whole card with its two lines of text.
        arrowAlignment: Alignment(0, (6 + width * 9 / 32) / height * 2 - 1),
        child: ListView.separated(
          key: ValueKey(_selectedSeason),
          controller: _episodeScroll,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: 6),
          itemCount: episodes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, i) {
            final ep = episodes[i];
            return _EpisodeCard(
              episode: ep,
              width: width,
              fallbackImage: fallback,
              isCollection: _isCollection,
              resume: _resumeFor(ep),
              watched: _isWatched(ep),
              current:
                  target != null &&
                  target.season == ep.season &&
                  target.episode == ep.episode,
              onTap: () => _handlePlayAction(ep),
            );
          },
        ),
      ),
    );
  }

  static const int _gridThreshold = 20;

  Widget _buildCast(List<CastMember> cast, double pad) {
    if (cast.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: LuRail(
        title: l10nOf(context).detailsCast,
        padding: pad,
        height: 132,
        spacing: 18,
        itemCount: cast.length,
        itemBuilder: (context, i) => _CastAvatar(
          member: cast[i],
          onTap: () => Navigator.push(
            context,
            CinematicSlideRoute(
              page: DiscoverPage(query: cast[i].searchName, isGenre: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelated(List<Movie> related, double pad) {
    final w = _phone(context) ? 116.0 : 150.0;
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: LuRail(
        title: l10nOf(context).detailsMoreLikeThis,
        padding: pad,
        height: LuPosterCard.heightFor(w),
        itemCount: related.length,
        itemBuilder: (context, i) {
          final m = related[i];
          return LuPosterCard(
            width: w,
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
    );
  }

  Widget _buildSimilar(double pad) {
    final w = _phone(context) ? 116.0 : 150.0;
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: LuRail(
        title: l10nOf(context).detailsSimilar,
        padding: pad,
        height: LuPosterCard.heightFor(w),
        itemCount: _similarItems.length,
        itemBuilder: (context, i) {
          final m = _similarItemAsMovie(_similarItems[i]);
          return LuPosterCard(
            width: w,
            title: m.name,
            titleId: m.id,
            series: m.type == 'series',
            poster: m.poster,
            subtitle: m.year,
            rating: m.imdbRating,
            onTap: () => _openSimilarItem(_similarItems[i]),
          );
        },
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

/// The still behind the title: washed from the left so the text reads, and
/// faded into the ground at the bottom.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.url, required this.phone});

  final String? url;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        LuImage(url: url, cacheWidth: 1600),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: phone
                  ? const [Color(0x660A0A0C), Color(0x330A0A0C)]
                  : const [
                      Color(0xF50A0A0C),
                      Color(0xC70A0A0C),
                      Color(0x000A0A0C),
                    ],
              stops: phone ? null : const [0, 0.38, 0.68],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [LuColors.bg, Color(0x000A0A0C)],
              stops: [0, 0.5],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x990A0A0C), Color(0x000A0A0C)],
              stops: [0, 0.25],
            ),
          ),
        ),
      ],
    );
  }
}

/// A 44 dp glass disc: the page's back.
class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LuFocusable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, hi) => AnimatedContainer(
        duration: LuMotion.focus,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hi ? const Color(0x33FFFFFF) : const Color(0x1FFFFFFF),
          border: Border.all(color: const Color(0x38FFFFFF)),
        ),
        child: Icon(icon, size: 18, color: LuColors.text),
      ),
    );
  }
}

/// A 52 dp disc beside the buttons: 👍 / 👎, gold once chosen.
class _Disc extends StatelessWidget {
  const _Disc({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: LuFocusable(
        onTap: onTap,
        semanticLabel: label,
        builder: (context, hi) => AnimatedContainer(
          duration: LuMotion.focus,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? const Color(0x29F2B544)
                : (hi ? const Color(0x2EFFFFFF) : const Color(0x1AFFFFFF)),
            border: Border.all(
              color: active ? LuColors.gold : const Color(0x47FFFFFF),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? LuColors.gold : LuColors.text,
          ),
        ),
      ),
    );
  }
}

/// One of a phone's equal action buttons: an icon over its label.
class _PhoneAction extends StatelessWidget {
  const _PhoneAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return LuFocusable(
      onTap: onTap,
      lift: 1,
      semanticLabel: label,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      builder: (context, hi) => AnimatedContainer(
        duration: LuMotion.focus,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: hi ? const Color(0x1AFFFFFF) : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? LuColors.gold : LuColors.text),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: LuText.caption.copyWith(
                fontSize: 12,
                color: active ? LuColors.gold : LuColors.textSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small dark pill: the source mode.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LuFocusable(
      onTap: onTap,
      builder: (context, hi) => AnimatedContainer(
        duration: LuMotion.focus,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: hi ? const Color(0xCC24242A) : const Color(0xB3141418),
          borderRadius: LuRadius.pill,
          border: Border.all(color: const Color(0xFF3A3832)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: LuColors.gold),
            const SizedBox(width: 8),
            Text(
              label,
              style: LuText.body.copyWith(
                fontSize: 14,
                color: const Color(0xFFE3DED3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three lines of the synopsis, with 展开 / 收起 when it runs longer.
class _Synopsis extends StatelessWidget {
  const _Synopsis({
    required this.text,
    required this.expanded,
    required this.moreLabel,
    required this.lessLabel,
    required this.onToggle,
    this.lines = 3,
  });

  final String text;
  final bool expanded;
  final String moreLabel;
  final String lessLabel;
  final VoidCallback onToggle;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final style = LuText.body.copyWith(
      fontSize: 16,
      height: 1.75,
      color: LuColors.textSoft,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: lines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: box.maxWidth);
        final long = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: expanded ? null : lines,
              overflow: expanded ? null : TextOverflow.ellipsis,
            ),
            if (long)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LuFocusable(
                  onTap: onToggle,
                  lift: 1,
                  builder: (context, hi) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      expanded ? lessLabel : moreLabel,
                      style: LuText.body.copyWith(
                        fontSize: 14,
                        color: hi ? LuColors.goldLight : LuColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One episode: the still with where the viewer is, then its number and
/// name.
class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.episode,
    required this.width,
    required this.onTap,
    this.fallbackImage,
    this.resume,
    this.watched = false,
    this.current = false,
    this.isCollection = false,
  });

  final Video episode;
  final double width;
  final VoidCallback onTap;
  final String? fallbackImage;
  final ContinueWatchingItem? resume;
  final bool watched;

  /// The episode the primary action plays: outlined in gold.
  final bool current;
  final bool isCollection;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final ep = episode;
    final number = '${ep.shownNumber ?? "?"}';
    final label = isCollection
        ? l10n.detailsPartBadge(number)
        : l10n.detailsEpisodeBadge(number);
    final airDay = episodeIsOut(ep) ? null : episodeAirDay(ep);
    final tag = airDay != null
        ? '${l10n.epUpcoming} · ${episodeAirLabel(context, airDay)}'
        : resume != null
        ? l10n.detailsWatchedTo(_clock(resume!.positionSeconds))
        : (watched ? l10n.detailsWatched : null);
    final progress = resume?.progressPercent ?? (watched ? 1.0 : 0.0);
    final title = ep.title.trim();
    final showTitle = title.isNotEmpty && title != label;

    return SizedBox(
      width: width,
      child: LuFocusable(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        semanticLabel: showTitle ? '$label $title' : label,
        builder: (context, hi) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: LuMotion.focus,
              width: width,
              height: width * 9 / 16,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: current
                    ? Border.all(color: LuColors.gold, width: 2)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(current ? 10 : 12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: airDay != null ? 0.35 : 1,
                      child: LuImage(url: ep.thumbnail ?? fallbackImage),
                    ),
                    if (tag != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Color(0xA6000000),
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: Text(
                              tag,
                              style: LuText.caption.copyWith(
                                color: LuColors.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (progress > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          color: LuColors.gold,
                          backgroundColor: const Color(0x38FFFFFF),
                        ),
                      ),
                    AnimatedOpacity(
                      duration: LuMotion.focus,
                      opacity: hi ? 1 : 0,
                      child: const Center(
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xF2F4F1EA),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: LuColors.bg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: LuText.body.copyWith(
                fontWeight: FontWeight.w700,
                color: hi ? LuColors.goldLight : LuColors.text,
              ),
            ),
            if (showTitle)
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.caption.copyWith(color: LuColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

/// A round face and the name under it.
class _CastAvatar extends StatelessWidget {
  const _CastAvatar({required this.member, required this.onTap});

  final CastMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = member.name.trim().isEmpty
        ? '?'
        : member.name.trim().characters.first.toUpperCase();
    return SizedBox(
      width: 92,
      child: LuFocusable(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(46)),
        semanticLabel: member.name,
        builder: (context, hi) => Column(
          children: [
            AnimatedContainer(
              duration: LuMotion.focus,
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hi ? LuColors.gold : LuColors.lineSoft,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: LuImage(
                  url: member.photo,
                  cacheWidth: 200,
                  fallback: Text(initials, style: LuText.heading),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              member.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: LuText.caption.copyWith(
                color: hi ? LuColors.text : LuColors.textSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
