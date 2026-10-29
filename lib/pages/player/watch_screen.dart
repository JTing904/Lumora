import '../../services/metadata/title_kind_service.dart';
import '../../services/metadata/episode_art.dart';
import '../account/login_page.dart' show SignInRequired;
import '../../services/player/source_pick_settings.dart';
import '../../services/stream/network_speed.dart';
import '../../services/stream/auto_source_picker.dart';
import '../../l10n/l10n.dart';
import '../../ui/lu_button.dart';
import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/zplay_logo.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../models/movie/movie.dart';
import '../../models/movie/video.dart';
import '../../models/movie/movie_detail.dart';

import '../../models/stream/stream_model.dart';
import '../../services/diagnostics/crash_breadcrumbs.dart';
import '../../models/subtitle/subtitle_model.dart';
import './player_screen.dart';
import '../../services/addon/addon_manager.dart';
import '../../services/debrid/debrid_service.dart';
import '../../services/debrid/debrid_rejection_store.dart';
import '../../services/layout/form_factor.dart';
import '../../services/scraper/title_match.dart';
import '../../services/stream/stream_service.dart';
import '../../services/theme/design_tokens.dart';
import '../../services/theme/glass_settings.dart';
import '../../services/scraper/builtin_providers_settings_service.dart';
import '../../widgets/common/performance_liquid_lens.dart';
import '../../widgets/common/focusable_card.dart';
import '../../widgets/common/trailer_modal.dart';
import '../../widgets/player/stream_bitrate_badge.dart';
import '../settings/settings_page.dart';
import '../details/details_page.dart';
import '../../utils/navigation/route_transitions.dart';
import '../../services/storage/app_image_cache.dart';
import '../../widgets/player/lu_player_style.dart';
import '../../services/official/official_source_loader.dart';
import '../../widgets/player/official_youtube_player.dart';
import '../../services/archive/archive_source_loader.dart';
import '../../widgets/watch_providers/watch_providers_panel.dart';

// ---------------------------------------------------------------------------
// WatchScreen
// ---------------------------------------------------------------------------
/// [_WatchScreenBody] for a signed-in viewer; the sign-in page for anyone else.
class WatchScreen extends StatelessWidget {
  const WatchScreen({
    super.key,
    required this.detail,
    this.selectedEpisode,
    required this.type,
    this.initialPosition,
    this.isCollection = false,
    this.autoPick = false,
  });

  final MovieDetail detail;
  final Video? selectedEpisode;
  final String type;
  final Duration? initialPosition;
  final bool isCollection;
  final bool autoPick;

  /// Stands in for the player route in tests.
  ///
  /// `PlayerScreen` owns a `media_kit` `Player`, which no widget test can build,
  /// and what a test has to prove about this screen is exactly the row-to-player
  /// handover: that the remote's centre button on a focused row opens that row's
  /// source. With this set, the route renders the test's own stand-in and is
  /// handed the source it would have played. Unset in the app.
  @visibleForTesting
  static Widget Function(StreamSource source)? debugPlayerBuilderForTesting;

  /// Stands in for the network probe behind the "自动" pick in tests.
  @visibleForTesting
  static Future<bool> Function(StreamSource source)? debugProbeForTesting;

  @override
  Widget build(BuildContext context) => SignInRequired(
    child: _WatchScreenBody(
      detail: detail,
      selectedEpisode: selectedEpisode,
      type: type,
      initialPosition: initialPosition,
      isCollection: isCollection,
      autoPick: autoPick,
    ),
  );
}

class _WatchScreenBody extends StatefulWidget {
  final MovieDetail detail;
  final Video? selectedEpisode;
  final String type;
  final Duration? initialPosition;

  final bool isCollection;

  /// Play the fastest working source as soon as the scrapers answer, instead
  /// of waiting for the viewer to pick one. See [AutoSourcePicker].
  final bool autoPick;

  const _WatchScreenBody({
    required this.detail,
    this.selectedEpisode,
    required this.type,
    this.initialPosition,
    this.isCollection = false,
    this.autoPick = false,
  });

  @override
  State<_WatchScreenBody> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<_WatchScreenBody>
    with SingleTickerProviderStateMixin {
  bool get _isCollection =>
      widget.isCollection ||
      widget.type == 'collections' ||
      widget.type == 'collection' ||
      widget.detail.isCollection ||
      (widget.selectedEpisode != null &&
          widget.selectedEpisode!.id.startsWith('tt') &&
          (widget.detail.type == 'collections' ||
              widget.detail.type == 'collection' ||
              widget.detail.isCollection));

  // Stream sources
  final List<StreamSource> _sources = [];
  final List<StreamSource> _pendingSources = [];

  /// The "自动" row's picker. One per screen, so what it learns about dead
  /// sources keeps greying them out after it has picked.
  final AutoSourcePicker _picker = AutoSourcePicker(
    probe: WatchScreen.debugProbeForTesting,
  );

  /// Whether an automatic pick is running, and the reason it stopped without
  /// one, for the row's subtitle.
  bool _autoPicking = false;
  bool _autoFoundNothing = false;

  /// Set when the viewer picks a row themselves, so a pick still running does
  /// not start a second player over theirs.
  bool _autoCancelled = false;

  /// Only what is certain greys a row out: a torrent with no seeders. A
  /// failed liveness probe is not certain (it fails links that play), so it
  /// orders the 自动 queue and is not shown.
  SourceDeadReason? _deadReason(StreamSource s) =>
      AutoSourcePicker.knownDead(s);

  /// The title's length in minutes, which turns a torrent's size into the
  /// rate it needs: the detail's own "162 min", else 45 for an episode and
  /// 120 for a film.
  int get _runtimeMinutes {
    final parsed = int.tryParse(
      RegExp(r'\d+').firstMatch(widget.detail.runtime ?? '')?.group(0) ?? '',
    );
    if (parsed != null && parsed > 0) return parsed;
    return widget.selectedEpisode != null && !_isCollection ? 45 : 120;
  }

  /// Plays the fastest working source, deciding while the scrapers are still
  /// answering.
  ///
  /// Every direct link is probed the moment it arrives ([AutoSourcePicker
  /// .offer]) and the first to answer alive is played. Only when the scrape
  /// has finished with every probe failed - or after 20 seconds with none
  /// alive - does it fall back to the best-seeded torrent. Sources heavier
  /// than the measured connection carries ([NetworkSpeed]), or above the
  /// viewer's 画质 choice, go to the back of the queue.
  Future<void> _runAutoPick() async {
    if (_autoPicking) return;
    setState(() {
      _autoPicking = true;
      _autoFoundNothing = false;
      _autoCancelled = false;
    });

    _picker
      ..bandwidthMbps = NetworkSpeed.mbps.value
      ..runtimeMinutes = _runtimeMinutes
      ..qualityCap = SourcePickSettings.qualityCap.value;
    // The original language, so a Spanish film's Spanish source is not taken
    // for a dub. Usually cached from search; never worth more than a moment.
    final facts = await TitleKindService.forImdbId(
      widget.detail.id,
      type: widget.type,
    ).timeout(const Duration(seconds: 2), onTimeout: () => null);
    if (!mounted) return;
    _picker.originalLanguage = facts?.originalLanguage;

    final started = DateTime.now();
    while (mounted && !_autoCancelled) {
      _picker.offer(_filteredSources);
      if (_picker.winner != null) break;
      if (!_isLoadingSources && !_picker.probing) break;
      if (DateTime.now().difference(started) >= const Duration(seconds: 20)) {
        break;
      }
      await Future.any([
        _picker.nextResult,
        Future<void>.delayed(const Duration(milliseconds: 250)),
      ]);
    }
    if (!mounted || _autoCancelled) return;

    final pick = _picker.pickNow(_filteredSources);
    // Nothing the picker can play, but the rights holder's own upload is
    // there: that is the pick. The picker never races it (it is not a stream).
    final official = pick == null
        ? _filteredSources.where(OfficialSourceLoader.isOfficial).firstOrNull
        : null;
    setState(() {
      _autoPicking = false;
      _autoFoundNothing = pick == null && official == null;
    });
    if (official != null) {
      _openSource(official, alternatives: const []);
      return;
    }
    if (pick == null) return;
    _openSource(
      pick.source,
      alternatives: _archiveSecond(pick.alternatives),
      autoPicked: true,
    );
  }

  /// [queue] with the Internet Archive copy right behind the first pick.
  ///
  /// The picker orders by probe speed and quality, so a public-domain file -
  /// standard definition, on a host slower to answer a probe - sat behind a
  /// dozen third-party links, past the switcher's last attempt, while those
  /// links served nothing. It is the one source here known to be lawful and
  /// still there, so it is the first fallback.
  static List<StreamSource> _archiveSecond(List<StreamSource> queue) {
    if (queue.length < 2) return queue;
    final archive = queue.skip(1).where(ArchiveSourceLoader.isArchive).toList();
    if (archive.isEmpty) return queue;
    return [
      queue.first,
      ...archive,
      ...queue.skip(1).where((s) => !ArchiveSourceLoader.isArchive(s)),
    ];
  }

  final List<SubtitleVariant> _discoveredSubtitles = [];
  final Set<String> _seenSubtitleUrls = {};
  Timer? _sourceBatchTimer;
  bool _isLoadingSources = true;
  StreamSubscription<StreamSource>? _streamSub;

  /// The scrapers and the official-upload lookup run side by side; the list
  /// stops saying "searching" only when both have answered, so an official
  /// upload replaces the "no sources" state instead of following it.
  bool _scrapeDone = false;
  bool _officialPending = false;

  /// The Internet Archive lookup (public-domain films), run beside the two
  /// above on the same terms.
  bool _archivePending = false;

  /// Whether every lookup has answered, so the list may stop "searching".
  bool get _allSourcesAnswered =>
      _scrapeDone && !_officialPending && !_archivePending;

  void _recordSubtitles(List<SubtitleVariant>? subs) {
    if (subs == null || subs.isEmpty) return;
    for (final s in subs) {
      if (_seenSubtitleUrls.add(s.downloadUrl.toLowerCase())) {
        _discoveredSubtitles.add(s);
      }
    }
  }

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Scroll
  final ScrollController _sourcesScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  /// Where a remote starts on this screen: the first source row.
  ///
  /// A pushed route opens with its own `FocusScope` holding focus, and a
  /// directional search from a node whose rect is the whole screen looks for a
  /// neighbour *outside* that rectangle — every row is inside it, so the first
  /// arrow press did nothing and no control on this page could be reached or
  /// activated from a D-pad at all. The screen therefore owns the node and
  /// requests it once a row exists, the same shape [PlayerScreen] uses for its
  /// transport: the state holds the node, the child attaches it, and the request
  /// is made after the frame that built it.
  final FocusNode _firstSourceFocusNode = FocusNode(
    debugLabel: 'WatchFirstSourceRow',
  );

  // Addon priority caching
  Map<String, int>? _cachedAddonOrder;
  Map<String, int> get _addonOrder {
    if (_cachedAddonOrder != null) return _cachedAddonOrder!;
    final map = <String, int>{};
    final allAddons = AddonManager.instance.addons;
    for (int i = 0; i < allAddons.length; i++) {
      final a = allAddons[i];
      map[a.manifest.name.toLowerCase()] = i;
      map[a.manifest.id.toLowerCase()] = i;
      if (a.manifest.id == 'builtin.zplayhttp' ||
          a.baseUrl == 'builtin:zplayhttp') {
        map['zplayhttp'] = i;
      }
      if (a.manifest.id == 'builtin.zplay' || a.baseUrl == 'builtin:zplay') {
        map['zplay'] = i;
      }
    }
    return _cachedAddonOrder = map;
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
    _loadDebridState();
    _loadStreams();
    if (widget.autoPick) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runAutoPick();
      });
    }

    // A hash remembered as refused while this screen is open (the player writes
    // one the moment a provider refuses) has to reach the list, so the badge and
    // the ordering follow without a reopen.
    DebridRejectionStore.revision.addListener(_onRejectionsChanged);
  }

  @override
  void dispose() {
    DebridRejectionStore.revision.removeListener(_onRejectionsChanged);
    _streamSub?.cancel();
    _streamSub = null;
    StreamService.stopAllScrapers();
    _sourceBatchTimer?.cancel();
    _animController.dispose();
    _sourcesScrollController.dispose();
    _mainScrollController.dispose();
    _firstSourceFocusNode.dispose();
    super.dispose();
  }

  /// The rejection memory changed somewhere (the player remembers a refusal),
  /// so the badges and the ordering of the source list are stale.
  void _onRejectionsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadStreams() async {
    _streamSub?.cancel();
    _streamSub = null;
    StreamService.stopAllScrapers();

    final streamId = widget.selectedEpisode?.id ?? widget.detail.id;

    // 1. Immediately inject any embedded streams from the video (e.g. Torbox/Debrid direct streams)
    if (widget.selectedEpisode != null &&
        widget.selectedEpisode!.streams.isNotEmpty) {
      for (final s in widget.selectedEpisode!.streams) {
        _recordSubtitles(s.subtitles);
      }
      _pendingSources.addAll(widget.selectedEpisode!.streams);
      _flushPendingSources();
    }

    final isColl = _isCollection;
    final effectiveType = isColl ? 'movie' : widget.type;
    final effectiveTitle = (isColl && widget.selectedEpisode != null)
        ? widget.selectedEpisode!.title
        : widget.detail.name;
    final epReleased = widget.selectedEpisode?.released;
    final effectiveYear =
        (isColl && epReleased != null && epReleased.length >= 4)
        ? int.tryParse(epReleased.substring(0, 4))
        // `year` is Stremio's releaseInfo, which for a series reads "2020–";
        // the leading year is what the scrapers need to tell same-named
        // titles apart.
        : leadingYear(widget.detail.year);
    final effectiveSeason = isColl ? null : widget.selectedEpisode?.season;
    final effectiveEpisode = isColl ? null : widget.selectedEpisode?.episode;
    int? chineseEpisode;
    if (!isColl &&
        effectiveSeason != null &&
        effectiveSeason > 0 &&
        effectiveEpisode != null) {
      chineseEpisode = await EpisodeArt.runningNumber(
        widget.detail,
        season: effectiveSeason,
        episode: effectiveEpisode,
      );
      if (!mounted) return;
    }

    _streamSub =
        StreamService.fetchStreams(
          type: effectiveType,
          id: streamId,
          title: effectiveTitle,
          year: effectiveYear,
          season: effectiveSeason,
          episode: effectiveEpisode,
          chineseEpisode: chineseEpisode,
          genres: widget.detail.genres,
        ).listen(
          (source) {
            if (!mounted) return;
            _recordSubtitles(source.subtitles);
            _pendingSources.add(source);
            if (_sources.isEmpty) {
              _flushPendingSources();
            } else {
              _sourceBatchTimer ??= Timer(
                const Duration(milliseconds: 50),
                _flushPendingSources,
              );
            }
          },
          onError: (_) {},
          onDone: () {
            _scrapeDone = true;
            _flushPendingSources();
            if (mounted && _isLoadingSources && _allSourcesAnswered) {
              setState(() => _isLoadingSources = false);
            }
          },
        );

    if (!isColl) _loadOfficialUploads();
    if (!isColl) _loadArchiveFilms();
  }

  /// A public-domain or openly licensed copy on the Internet Archive, matched
  /// by exact title and year. Fails quietly: no row, nothing else changes.
  Future<void> _loadArchiveFilms() async {
    _archivePending = true;
    final rows = await ArchiveSourceLoader.load(
      detail: widget.detail,
      type: widget.type,
      // Started from initState, where no inherited widget may be read.
      l10n: l10nCurrent(),
    );
    _archivePending = false;
    if (!mounted) return;
    _pendingSources.addAll(rows);
    _flushPendingSources();
    if (_allSourcesAnswered && _isLoadingSources) {
      setState(() => _isLoadingSources = false);
    }
  }

  /// The rights holder's own full upload on YouTube, when there is one.
  /// Fails quietly: no row, nothing else changes.
  Future<void> _loadOfficialUploads() async {
    _officialPending = true;
    final rows = await OfficialSourceLoader.load(
      detail: widget.detail,
      episode: widget.selectedEpisode,
      type: widget.type,
      // Started from initState, where no inherited widget may be read.
      l10n: l10nCurrent(),
    );
    _officialPending = false;
    if (!mounted) return;
    _pendingSources.addAll(rows);
    _flushPendingSources();
    if (_allSourcesAnswered && _isLoadingSources) {
      setState(() => _isLoadingSources = false);
    }
  }

  void _flushPendingSources() {
    _sourceBatchTimer?.cancel();
    _sourceBatchTimer = null;
    if (!mounted || _pendingSources.isEmpty) return;

    final bool firstBatch = _sources.isEmpty;
    final batch = _pendingSources.where((source) => !source.isMagnet).toList();
    _pendingSources.clear();
    if (batch.isEmpty) return;
    setState(() {
      _sources.addAll(batch);
    });
    // The list is on screen from this frame, so this is the first moment the
    // first row exists to be focused.
    if (firstBatch) _focusFirstSourceRow();
  }

  /// Hands focus to the first source row, once one has been built.
  ///
  /// Without this the route's own scope keeps focus and the page is inert to a
  /// remote; see [_firstSourceFocusNode]. The node is not attached until the row
  /// that carries it is built, and a request made before that rides the node's
  /// reparent, so this is safe to call as soon as the first batch is set.
  ///
  /// The scroll is the second half: the framework only ensures a focused node is
  /// visible for traversal-driven focus (`FocusTraversalPolicy
  /// .defaultTraversalRequestFocusCallback`), so a programmatic request would
  /// otherwise leave the row exactly where it was — below the fold on a short
  /// window, since the info region sits above the list.
  void _focusFirstSourceRow() {
    if (!FormFactorService.hasRemoteInput) return;
    final node = _firstSourceFocusNode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? rowContext = node.context;
      // Null when the row was never built — the list is below the fold and the
      // viewport has not reached it. Nothing to focus, and nothing to scroll to.
      if (rowContext == null) return;
      node.requestFocus();
      Scrollable.ensureVisible(
        rowContext,
        alignment: 0.5,
        duration: ZplayMotion.base,
        curve: ZplayMotion.standard,
      );
    });
  }

  /// Starts the source at [index], carrying the ranked remainder behind it.
  void _playSourceAt(List<StreamSource> sources, int index) {
    _autoCancelled = true;
    if (_autoPicking) setState(() => _autoPicking = false);
    _openSource(
      sources[index],
      alternatives: _alternativesAfter(sources, index),
    );
  }

  /// Starts [s], or leaves the app when the source is a link to somewhere else.
  ///
  /// Owned here rather than by the row so a row stays presentational: it draws
  /// itself, takes the ring and reports activation, and the screen decides what
  /// activation means. That split is what lets the D-pad handover be tested
  /// without building a media_kit player.
  void _openSource(
    StreamSource source, {
    required List<StreamSource> alternatives,
    bool autoPicked = false,
  }) {
    HapticFeedback.lightImpact();

    // The rights holder's own upload plays in YouTube's embedded player,
    // never in the stream player.
    final String? officialVideoId = OfficialSourceLoader.videoIdOf(source);
    if (officialVideoId != null) {
      CrashBreadcrumbs.stream(
        'open',
        title: source.displayTitle,
        addon: source.addonName,
      );
      OfficialYouTubePlayer.open(
        context,
        videoId: officialVideoId,
        title: source.displayTitle,
        channelName: source.providerName,
        // Progress and watched marks, as the stream player records them.
        detail: widget.detail,
        episode: widget.selectedEpisode,
        source: source,
        initialPosition: widget.initialPosition,
      );
      return;
    }

    final String? externalUrl = source.externalUrl;
    if (externalUrl != null && externalUrl.isNotEmpty) {
      if (externalUrl.startsWith('stremio://')) {
        // Example: stremio:///detail/movie/tt28479262
        final uri = Uri.parse(
          externalUrl.replaceFirst('stremio:///', 'stremio://'),
        );
        final segments = uri.pathSegments;
        if (uri.host == 'detail' && segments.length >= 2) {
          Navigator.push(
            context,
            CinematicSlideRoute(
              page: DetailsPage(
                movie: Movie(
                  id: segments[1],
                  type: segments[0],
                  name: source.name ?? l10nCurrent().plyUnknownSource,
                  addonBaseUrl: 'https://v3-cinemeta.strem.io',
                ),
              ),
            ),
          );
        }
        return;
      }
      // Anything else is a web page. Lumora never sends a viewer out to a
      // browser to watch; the source list already drops these, so this only
      // guards a source that reached the screen some other way.
      return;
    }

    final bool isCollection = widget.detail.isCollection;
    final Video? episode = widget.selectedEpisode;
    final String effectiveTitle =
        (isCollection && episode != null && episode.title.isNotEmpty)
        ? episode.title
        : source.displayTitle;

    CrashBreadcrumbs.stream(
      'open',
      title: source.displayTitle,
      addon: source.addonName,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _buildPlayer(source, effectiveTitle, alternatives, autoPicked),
      ),
    );
  }

  Widget _buildPlayer(
    StreamSource source,
    String title,
    List<StreamSource> alternatives,
    bool autoPicked,
  ) {
    final override = WatchScreen.debugPlayerBuilderForTesting;
    if (override != null) return override(source);
    return PlayerScreen(
      source: source,
      title: title,
      backdropUrl: widget.detail.background ?? widget.detail.poster,
      logoUrl: widget.detail.logo,
      detail: widget.detail,
      episode: widget.selectedEpisode,
      initialPosition: widget.initialPosition,
      initialSubtitles: _discoveredSubtitles,
      alternatives: alternatives.isEmpty ? null : alternatives,
      autoPicked: autoPicked,
    );
  }

  String? _selectedAddonFilter;
  String? _selectedSizeFilter;
  String _selectedTypeFilter = 'all'; // 'all', 'debrid', 'torrent', 'direct'
  final String _selectedSeederFilter =
      'all'; // 'all', 'most', '50+', '20+', '5+', '1+'
  String _selectedAudioFilter =
      'all'; // 'all', 'multi', 'english', 'hindi', 'german', 'french', 'spanish', 'spanish_castilian', 'spanish_latino', 'russian', 'japanese', 'italian'

  /// Whether torrent sources will be resolved by a Debrid service rather than by
  /// the local P2P engine, so the list can count and label them accordingly.
  bool _debridReady = false;
  String? _debridServiceName;

  Future<void> _loadDebridState() async {
    final ready = DebridService.isDebridReady.value;
    final service = ready ? await DebridService().getSelectedService() : null;
    if (!mounted) return;
    setState(() {
      _debridReady = ready;
      _debridServiceName = service;
    });
  }

  /// A Debrid source is either a link an addon already resolved for us, or a
  /// magnet that our active Debrid service will resolve in the cloud.
  bool _isDebridSource(StreamSource s) =>
      s.isDebridPlayable(debridReady: _debridReady);

  List<StreamSource> get _filteredSources {
    var list = List<StreamSource>.from(_sources);
    if (_selectedAddonFilter != null) {
      list = list.where((s) => s.addonName == _selectedAddonFilter).toList();
    }
    if (_selectedTypeFilter == 'debrid') {
      list = list.where(_isDebridSource).toList();
    } else if (_selectedTypeFilter == 'torrent') {
      list = list.where((s) => s.isTorrent).toList();
    } else if (_selectedTypeFilter == 'direct') {
      list = list.where((s) => s.isHttpDirect).toList();
    }
    if (_selectedSizeFilter != null) {
      switch (_selectedSizeFilter) {
        case '<1gb':
          list = list.where((s) {
            final sz = s.sizeBytes;
            return sz != null && sz < 1024 * 1024 * 1024;
          }).toList();
          break;
        case '1-5gb':
          list = list.where((s) {
            final sz = s.sizeBytes;
            return sz != null &&
                sz >= 1024 * 1024 * 1024 &&
                sz <= 5.0 * 1024 * 1024 * 1024;
          }).toList();
          break;
        case '5-15gb':
          list = list.where((s) {
            final sz = s.sizeBytes;
            return sz != null &&
                sz > 5.0 * 1024 * 1024 * 1024 &&
                sz <= 15.0 * 1024 * 1024 * 1024;
          }).toList();
          break;
        case '15-30gb':
          list = list.where((s) {
            final sz = s.sizeBytes;
            return sz != null &&
                sz > 15.0 * 1024 * 1024 * 1024 &&
                sz <= 30.0 * 1024 * 1024 * 1024;
          }).toList();
          break;
        case '>30gb':
          list = list.where((s) {
            final sz = s.sizeBytes;
            return sz != null && sz > 30.0 * 1024 * 1024 * 1024;
          }).toList();
          break;
      }
    }

    if (_selectedSeederFilter == '50+') {
      list = list.where((s) => (s.seeders ?? 0) >= 50).toList();
    } else if (_selectedSeederFilter == '20+') {
      list = list.where((s) => (s.seeders ?? 0) >= 20).toList();
    } else if (_selectedSeederFilter == '5+') {
      list = list.where((s) => (s.seeders ?? 0) >= 5).toList();
    } else if (_selectedSeederFilter == '1+') {
      list = list.where((s) => (s.seeders ?? 0) >= 1).toList();
    }

    // Filter by audio language / dub
    if (_selectedAudioFilter != 'all') {
      list = list
          .where(
            (s) => s.hasAudioLanguage(
              _selectedAudioFilter,
              mediaTitle: widget.detail.name,
            ),
          )
          .toList();
    }

    // Filter by active status of built-in providers. Torrents stay listed while a
    // Debrid service can resolve them, even with the local P2P engine switched off.
    list = list.where((s) => !s.isMagnet).toList();
    if (!AddonManager.instance.isZplayHttpActive) {
      list = list
          .where((s) => s.addonName.toLowerCase() != 'zplayhttp')
          .toList();
    }

    // Cached dynamic addon priority lookup from user's installed addons order
    final addonOrder = _addonOrder;
    final isCustomBuiltin = BuiltinProvidersSettingsService.instance.isCustom;

    list.sort((a, b) {
      final isHttpA = a.addonName.toLowerCase() == 'zplayhttp';
      final isHttpB = b.addonName.toLowerCase() == 'zplayhttp';

      // When custom Built-in providers mode is active, provider rank strictly dictates order
      if (isCustomBuiltin && isHttpA && isHttpB) {
        final pidA =
            a.providerId ?? BuiltinProvidersSettingsService.detectProviderId(a);
        final pidB =
            b.providerId ?? BuiltinProvidersSettingsService.detectProviderId(b);
        final rankA = BuiltinProvidersSettingsService.instance.getProviderRank(
          pidA,
        );
        final rankB = BuiltinProvidersSettingsService.instance.getProviderRank(
          pidB,
        );
        if (rankA != rankB) {
          return rankA.compareTo(rankB);
        }
        // Within the same provider, sort by secondary filter / quality:
        if (_selectedSeederFilter == 'most') {
          return (b.seeders ?? 0).compareTo(a.seeders ?? 0);
        } else if (_selectedSizeFilter == 'largest') {
          return (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0);
        } else if (_selectedSizeFilter == 'smallest') {
          return (a.sizeBytes ?? double.infinity).compareTo(
            b.sizeBytes ?? double.infinity,
          );
        } else {
          final qComp = b.qualityRank.compareTo(a.qualityRank);
          if (qComp != 0) return qComp;
          return (b.seeders ?? 0).compareTo(a.seeders ?? 0);
        }
      }

      // Addon-level order comparison
      final orderA = addonOrder[a.addonName.toLowerCase()] ?? 999;
      final orderB = addonOrder[b.addonName.toLowerCase()] ?? 999;
      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }

      // Standard sort across streams of the same addon
      if (_selectedSeederFilter == 'most') {
        return (b.seeders ?? 0).compareTo(a.seeders ?? 0);
      } else if (_selectedSizeFilter == 'largest') {
        return (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0);
      } else if (_selectedSizeFilter == 'smallest') {
        return (a.sizeBytes ?? double.infinity).compareTo(
          b.sizeBytes ?? double.infinity,
        );
      } else {
        final qComp = b.qualityRank.compareTo(a.qualityRank);
        if (qComp != 0) return qComp;
        return (b.seeders ?? 0).compareTo(a.seeders ?? 0);
      }
    });

    // Torrents the provider has already refused sink to the bottom, keeping the
    // ranking above intact inside both groups. They stay listed and selectable:
    // this is information, not an error, and a refusal only holds until the
    // provider changes its mind. Partitioned by hand because sort() is not
    // stable and would shuffle the ranking it just produced.
    // The rights holder's own uploads go first: they are the one source here
    // that is licensed to play.
    final official = <StreamSource>[];
    final usable = <StreamSource>[];
    final refused = <StreamSource>[];
    for (final s in list) {
      // The Internet Archive's public-domain copies are licensed to play
      // too, so they sit with the official uploads.
      if (OfficialSourceLoader.isOfficial(s) ||
          ArchiveSourceLoader.isArchive(s)) {
        official.add(s);
        continue;
      }
      (DebridRejectionStore.instance.isRejected(s.infoHash) ? refused : usable)
          .add(s);
    }
    return <StreamSource>[...official, ...usable, ...refused];
  }

  /// The ranked remainder behind [index] in the visible list, minus the torrents
  /// a provider has already refused. This is what the player walks when the
  /// source at [index] fails, and handing it back a refused torrent would only
  /// spend one of its attempts.
  List<StreamSource> _alternativesAfter(List<StreamSource> list, int index) {
    final store = DebridRejectionStore.instance;
    return list
        .skip(index + 1)
        .where(
          (s) =>
              !store.isRejected(s.infoHash) &&
              // An official upload is not a stream the player can fall to.
              !OfficialSourceLoader.isOfficial(s),
        )
        .toList();
  }

  String _getSizeFilterLabel(String? filter) {
    switch (filter) {
      case '<1gb':
        return '< 1 GB';
      case '1-5gb':
        return '1–5 GB';
      case '5-15gb':
        return '5–15 GB';
      case '15-30gb':
        return '15–30 GB';
      case '>30gb':
        return '> 30 GB';
      case 'largest':
        return l10nOf(context).watchSizeLargest;
      case 'smallest':
        return l10nOf(context).watchSizeSmallest;
      default:
        return l10nOf(context).watchSizeAll;
    }
  }

  bool _isDesktop() => MediaQuery.sizeOf(context).width >= 900;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final bgUrl = widget.detail.background ?? widget.detail.poster;
    final isDesktop = _isDesktop();

    final background = Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: luTokens.bg)),
        if (bgUrl != null) _buildBackdrop(bgUrl, screenSize, isDesktop),
      ],
    );
    final content = Stack(
      children: [
        SafeArea(
          child: isDesktop
              ? _buildDesktopLayout(screenSize)
              : _buildMobileLayout(screenSize),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _buildBackButton(),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: luTokens.bg,
      body: ValueListenableBuilder<bool>(
        valueListenable: GlassSettings.enabled,
        builder: (context, enabled, _) {
          if (enabled) {
            return LiquidGlassView(
              realTimeCapture: true,
              useSync: true,
              pixelRatio: 0.85,
              refreshRate: LiquidGlassRefreshRate.deviceRefreshRate,
              regionCapture: true,
              backgroundWidget: background,
              child: content,
            );
          }
          return Stack(children: [background, content]);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Backdrop
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBackdrop(String url, Size screenSize, bool isDesktop) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            cacheManager: AppImageCache.manager,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => ColoredBox(color: luTokens.bg),
          ),
          // Left-to-right dimming: dark on left (text side), lighter on right
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  luTokens.bg.withValues(alpha: isDesktop ? 0.92 : 0.88),
                  luTokens.bg.withValues(alpha: isDesktop ? 0.70 : 0.60),
                  luTokens.bg.withValues(alpha: isDesktop ? 0.20 : 0.15),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Bottom vertical gradient for legibility
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  luTokens.bg.withValues(alpha: 0.30),
                  luTokens.bg.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Desktop: side-by-side 60/40
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(Size screenSize) {
    final isWide = screenSize.width >= 1500;
    final leftFlex = isWide ? 5 : 5;
    final rightFlex = isWide ? 5 : 6;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 60,
            left: 48,
            right: 0,
            bottom: 24,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: info region
              Expanded(
                flex: leftFlex,
                child: SingleChildScrollView(
                  controller: _mainScrollController,
                  physics: const BouncingScrollPhysics(),
                  child: _buildInfoRegion(isDesktop: true),
                ),
              ),
              const SizedBox(width: ZplaySpacing.s32),
              // Right: sources panel (extends to right edge)
              Expanded(
                flex: rightFlex,
                child: Padding(
                  padding: const EdgeInsets.only(right: ZplaySpacing.s24),
                  child: _buildSourcesPanel(isDesktop: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mobile: stacked vertically
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(Size screenSize) {
    final filtered = _filteredSources;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          controller: _mainScrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top padding ──
            const SliverPadding(padding: EdgeInsets.only(top: 60)),

            // ── Info region (single box) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZplaySpacing.s24,
                ),
                child: _buildInfoRegion(isDesktop: false),
              ),
            ),

            const SliverPadding(
              padding: EdgeInsets.only(top: ZplaySpacing.s24),
            ),

            // ── Sources header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZplaySpacing.s24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.stream_rounded,
                              color: luTokens.accent,
                              size: 20,
                            ),
                            const SizedBox(width: ZplaySpacing.s8),
                            Text(
                              l10nOf(context).watchSources,
                              style: ZplayType.title.toStyle(
                                color: luTokens.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _isLoadingSources
                              ? (filtered.isEmpty
                                    ? l10nOf(context).watchSearching
                                    : l10nOf(
                                        context,
                                      ).watchFoundSearching(filtered.length))
                              : l10nOf(context).watchFound(filtered.length),
                          style: ZplayType.bodySmall.toStyle(
                            color: luTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (_sources.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildTypeChip(
                            'all',
                            l10nOf(context).watchFilterAll(_sources.length),
                            Icons.apps_rounded,
                            null,
                          ),
                          _buildTypeChip(
                            'debrid',
                            '⚡ ${l10nOf(context).watchFilterDebrid(_debridServiceName ?? 'Debrid', _sources.where(_isDebridSource).length)}',
                            Icons.bolt_rounded,
                            luTokens.info,
                          ),
                          _buildTypeChip(
                            'direct',
                            '🌐 ${l10nOf(context).watchFilterDirect(_sources.where((s) => s.isHttpDirect).length)}',
                            Icons.link_rounded,
                            luTokens.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: ZplaySpacing.s8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildSizeFilterDropdown(),
                          _buildAddonFilterDropdown(),
                          _buildAudioFilterDropdown(),
                        ],
                      ),
                    ],
                    if (!_isCollection)
                      WatchProvidersPanel(
                        detail: widget.detail,
                        type: widget.type,
                        padding: const EdgeInsets.only(top: ZplaySpacing.s12),
                      ),
                    const SizedBox(height: ZplaySpacing.s16),
                  ],
                ),
              ),
            ),

            // ── Sources list (virtualized!) ──
            if (_isLoadingSources && filtered.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZplaySpacing.s24,
                ),
                sliver: SliverList.builder(
                  itemCount: 4,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: ZplaySpacing.s8),
                    child: _buildShimmerCard(),
                  ),
                ),
              )
            else if (!_isLoadingSources && filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZplaySpacing.s24,
                  ),
                  child: _buildEmptyState(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZplaySpacing.s24,
                ),
                sliver: SliverList.builder(
                  itemCount: filtered.length + 1 + (_isLoadingSources ? 2 : 0),
                  itemBuilder: (context, row) {
                    if (row == 0) return _buildAutoRow();
                    final index = row - 1;
                    if (index >= filtered.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: ZplaySpacing.s8),
                        child: _buildShimmerCard(),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: ZplaySpacing.s8),
                      child: _SourceCard(
                        source: filtered[index],
                        detail: widget.detail,
                        deadReason: _deadReason(filtered[index]),
                        focusNode: index == 0 ? _firstSourceFocusNode : null,
                        onActivate: () => _playSourceAt(filtered, index),
                      ),
                    );
                  },
                ),
              ),

            // ── Bottom padding ──
            const SliverPadding(
              padding: EdgeInsets.only(bottom: ZplaySpacing.s24),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Info Region
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInfoRegion({required bool isDesktop}) {
    final meta = widget.detail;
    final ep = widget.selectedEpisode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Episode info header (if applicable)
        if (ep != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ZplaySpacing.s12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: luTokens.accent.withValues(
                alpha: ZplayOpacity.overlayHover,
              ),
              borderRadius: ZplayRadius.smAll,
              border: Border.all(color: luTokens.accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              _isCollection
                  ? l10nCurrent().ply2PartCaps(ep.episode ?? 1)
                  : ep.displayNumber != null
                  // A show counted straight through: 第194集, not S8E22.
                  ? l10nCurrent().panelEpisode('${ep.displayNumber}')
                  : 'S${ep.season ?? '?'}E${ep.episode ?? '?'}',
              style: ZplayType.label
                  .copyWith(weight: FontWeight.w700, letterSpacing: 0.5)
                  .toStyle(color: luTokens.accent),
            ),
          ),
          const SizedBox(height: ZplaySpacing.s12),
        ],

        // Logo or title
        _buildLogoOrTitle(meta, isDesktop),
        const SizedBox(height: ZplaySpacing.s12),

        // Episode title (if applicable, different from series title)
        if (ep != null && ep.title.isNotEmpty && ep.title != meta.name)
          Padding(
            padding: const EdgeInsets.only(bottom: ZplaySpacing.s12),
            child: Text(
              _episodeTitle(ep.title),
              style: ZplayType.title.toStyle(
                color: luTokens.textPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),

        // Meta row
        _buildMetaRow(meta),
        const SizedBox(height: ZplaySpacing.s16),

        // Genre pills
        if (meta.displayGenres.isNotEmpty) ...[
          _buildGenrePills(meta.displayGenres),
          const SizedBox(height: ZplaySpacing.s24),
        ],

        // Synopsis
        if (_getSynopsis() != null) ...[
          _buildSynopsis(_getSynopsis()!),
          const SizedBox(height: ZplaySpacing.s24),
        ],

        // Director
        if (meta.director.isNotEmpty) ...[
          _buildLabelChips(l10nCurrent().plyDirector, meta.director),
          const SizedBox(height: ZplaySpacing.s16),
        ],

        // Cast
        if (meta.cast.isNotEmpty) ...[
          _buildLabelChips(
            l10nOf(context).detailsCast,
            meta.cast.take(8).toList(),
          ),
          const SizedBox(height: ZplaySpacing.s24),
        ],

        // Action bar
        _buildActionBar(),
        const SizedBox(height: ZplaySpacing.s24),
      ],
    );
  }

  /// TMDb names an episode it knows nothing about "Episode 196"; that
  /// placeholder reads in the app's language, a real title as written.
  String _episodeTitle(String title) {
    final n = RegExp(r'^Episode (\d+)$').firstMatch(title.trim());
    if (n == null) return title;
    return l10nOf(context).panelEpisode(n.group(1)!);
  }

  String? _getSynopsis() {
    final ep = widget.selectedEpisode;
    if (ep != null && ep.overview != null && ep.overview!.isNotEmpty) {
      return ep.overview;
    }
    return widget.detail.displayDescription;
  }

  Widget _buildLogoOrTitle(MovieDetail meta, bool isDesktop) {
    if (meta.logo != null && meta.logo!.isNotEmpty && !meta.hasLocalName) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 380 : 260,
          maxHeight: isDesktop ? 120 : 80,
        ),
        child: CachedNetworkImage(
          imageUrl: meta.logo!,
          cacheManager: AppImageCache.manager,
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
    return Text(
      text,
      style: ZplayType.display
          .copyWith(size: isDesktop ? 36 : 28)
          .toStyle(color: luTokens.textPrimary)
          .copyWith(
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
    );
  }

  Widget _buildMetaRow(MovieDetail meta) {
    final items = <Widget>[];

    if (meta.year != null && meta.year!.isNotEmpty) {
      items.add(
        Text(
          meta.year!,
          style: ZplayType.body
              .copyWith(weight: FontWeight.w600)
              .toStyle(color: luTokens.textPrimary),
        ),
      );
    }

    if (meta.runtime != null && meta.runtime!.isNotEmpty) {
      items.add(
        Text(
          // Cinemeta writes English ("114 min", "1h 30min"); read the minutes
          // out and say them in the UI's language, as the details page does.
          switch (parseRuntime(meta.runtime)) {
            final d? => l10nOf(context).detailsRuntimeMinutes(d.inMinutes),
            null => meta.runtime!,
          },
          style: ZplayType.body.toStyle(color: luTokens.textSecondary),
        ),
      );
    }

    if (meta.imdbRating != null && meta.imdbRating!.isNotEmpty) {
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ZplaySpacing.s8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: luTokens.warning.withValues(
              alpha: ZplayOpacity.overlayHover,
            ),
            borderRadius: ZplayRadius.xsAll,
            border: Border.all(color: luTokens.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: luTokens.warning, size: 14),
              const SizedBox(width: 3),
              Text(
                meta.imdbRating!,
                style: ZplayType.bodySmall
                    .copyWith(weight: FontWeight.w700)
                    .toStyle(color: luTokens.warning),
              ),
            ],
          ),
        ),
      );
    }

    final spaced = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      spaced.add(items[i]);
      if (i < items.length - 1) {
        spaced.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ZplaySpacing.s8),
            child: Text(
              '·',
              style: ZplayType.body.toStyle(color: luTokens.textMuted),
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

  Widget _buildGenrePills(List<String> genres) {
    return Wrap(
      spacing: ZplaySpacing.s8,
      runSpacing: ZplaySpacing.s8,
      children: genres
          .map(
            (g) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ZplaySpacing.s12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: luTokens.textPrimary.withValues(
                  alpha: ZplayOpacity.borderDefault,
                ),
                borderRadius: ZplayRadius.fullAll,
                border: Border.all(
                  color: luTokens.textPrimary.withValues(
                    alpha: ZplayOpacity.borderMedium,
                  ),
                ),
              ),
              child: Text(
                g,
                style: ZplayType.bodySmall
                    .copyWith(weight: FontWeight.w500)
                    .toStyle(color: luTokens.textSecondary),
              ),
            ),
          )
          .toList(),
    );
  }

  bool _synopsisExpanded = false;

  Widget _buildSynopsis(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: ZplayType.body
                .copyWith(height: 1.6)
                .toStyle(color: luTokens.textSecondary),
          ),
          secondChild: Text(
            text,
            style: ZplayType.body
                .copyWith(height: 1.6)
                .toStyle(color: luTokens.textSecondary),
          ),
          crossFadeState: _synopsisExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(
                text: text,
                style: ZplayType.body.copyWith(height: 1.6).toStyle(),
              ),
              maxLines: 3,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);

            if (!painter.didExceedMaxLines) return const SizedBox.shrink();

            return FocusableCard(
              onTap: () =>
                  setState(() => _synopsisExpanded = !_synopsisExpanded),
              builder: (context, _) => Text(
                _synopsisExpanded
                    ? l10nOf(context).detailsShowLess
                    : l10nOf(context).detailsReadMore,
                style: ZplayType.label
                    .copyWith(weight: FontWeight.w600)
                    .toStyle(color: luTokens.accent),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLabelChips(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ZplayType.caption
              .copyWith(weight: FontWeight.w600, letterSpacing: 1.0)
              .toStyle(color: luTokens.textMuted),
        ),
        const SizedBox(height: ZplaySpacing.s8),
        Wrap(
          spacing: ZplaySpacing.s8,
          runSpacing: ZplaySpacing.s8,
          children: items
              .map(
                (name) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: luTokens.surfaceRaised,
                    borderRadius: ZplayRadius.fullAll,
                  ),
                  child: Text(
                    name,
                    style: ZplayType.bodySmall.toStyle(
                      color: luTokens.textSecondary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    // Only links the app can open itself: a trailer with a YouTube key, which
    // plays in the in-app modal. IMDb, wiki, search and genre links all sent
    // the viewer out to a browser, and Lumora does not do that.
    final links = widget.detail.links
        .where((link) {
          final isTrailer =
              link.name.toLowerCase().contains('trailer') ||
              link.category.toLowerCase().contains('trailer');
          return isTrailer && TrailerModal.youtubeKeyFromUrl(link.url) != null;
        })
        .take(4)
        .toList();
    if (links.isEmpty) return const SizedBox.shrink();

    return Row(
      children: links.map((link) {
        IconData icon = Icons.link_rounded;
        final nameLower = link.name.toLowerCase();
        final catLower = link.category.toLowerCase();

        if (nameLower.contains('imdb') || catLower.contains('imdb')) {
          icon = Icons.movie_creation_outlined;
        } else if (nameLower.contains('trailer') ||
            catLower.contains('trailer')) {
          icon = Icons.play_circle_outline;
        } else if (nameLower.contains('wiki') || catLower.contains('wiki')) {
          icon = Icons.article_outlined;
        } else if (nameLower.contains('search') ||
            catLower.contains('search')) {
          icon = Icons.search_rounded;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: link == links.last ? 0 : ZplaySpacing.s12,
            ),
            child: _buildActionButton(
              icon,
              link.name,
              onTap: () async {
                HapticFeedback.lightImpact();
                // Every link left in the bar is a YouTube trailer (see above),
                // and it plays in the app's own modal.
                final key = TrailerModal.youtubeKeyFromUrl(link.url);
                if (key == null) return;
                await TrailerModal.show(
                  context,
                  trailerKey: key,
                  title: widget.detail.displayName,
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return FocusableCard(
      onTap: onTap,
      builder: (context, _) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: luTokens.surface.withValues(alpha: 0.6),
          borderRadius: ZplayRadius.smAll,
          border: Border.all(
            color: luTokens.textPrimary.withValues(
              alpha: ZplayOpacity.borderSubtle,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: luTokens.textSecondary, size: 22),
            const SizedBox(height: ZplaySpacing.s4),
            Text(
              label,
              style: ZplayType.caption.toStyle(color: luTokens.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sources Panel
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSourcesPanel({required bool isDesktop}) {
    final filtered = _filteredSources;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stream_rounded, color: luTokens.accent, size: 20),
                const SizedBox(width: ZplaySpacing.s8),
                Text(
                  l10nOf(context).watchSources,
                  style: ZplayType.title.toStyle(color: luTokens.textPrimary),
                ),
              ],
            ),
            Text(
              _isLoadingSources
                  ? (filtered.isEmpty
                        ? l10nOf(context).watchSearching
                        : l10nOf(context).watchFoundSearching(filtered.length))
                  : l10nOf(context).watchFound(filtered.length),
              style: ZplayType.bodySmall.toStyle(color: luTokens.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Stream Type Filter Bar (All / Debrid / Torrents / Direct HTTP)
        if (_sources.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildTypeChip(
                'all',
                l10nOf(context).watchFilterAll(_sources.length),
                Icons.apps_rounded,
                null,
              ),
              _buildTypeChip(
                'debrid',
                '⚡ ${l10nOf(context).watchFilterDebrid(_debridServiceName ?? 'Debrid', _sources.where(_isDebridSource).length)}',
                Icons.bolt_rounded,
                luTokens.info,
              ),
              _buildTypeChip(
                'direct',
                '🌐 ${l10nOf(context).watchFilterDirect(_sources.where((s) => s.isHttpDirect).length)}',
                Icons.link_rounded,
                luTokens.success,
              ),
            ],
          ),
          const SizedBox(height: ZplaySpacing.s8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildSizeFilterDropdown(),
              _buildAddonFilterDropdown(),
              _buildAudioFilterDropdown(),
            ],
          ),
          const SizedBox(height: ZplaySpacing.s12),
        ],

        // Where to watch: official services, opened in their own apps.
        if (!_isCollection)
          WatchProvidersPanel(
            detail: widget.detail,
            type: widget.type,
            padding: const EdgeInsets.only(bottom: ZplaySpacing.s12),
          ),

        // Source list
        if (isDesktop)
          Expanded(child: _buildSourcesList(filtered, isDesktop))
        else
          _buildSourcesList(filtered, isDesktop),
      ],
    );
  }

  Widget _buildTypeChip(
    String typeKey,
    String label,
    IconData icon,
    Color? color,
  ) {
    final isSelected = _selectedTypeFilter == typeKey;
    final activeColor = color ?? luTokens.accent;

    return FocusableCard(
      onTap: () {
        setState(() {
          _selectedTypeFilter = typeKey;
        });
      },
      builder: (context, state) => CardFocusRing(
        focused: state.focused,
        radius: ZplayRadius.smAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.25)
                : luTokens.surface,
            borderRadius: ZplayRadius.smAll,
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : luTokens.textPrimary.withValues(
                      alpha: ZplayOpacity.borderMedium,
                    ),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? activeColor : luTokens.textEmphasis,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: ZplayType.caption
                    .copyWith(
                      weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    )
                    .toStyle(
                      color: isSelected
                          ? luTokens.textPrimary
                          : luTokens.textEmphasis,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The "自动（推荐）" row above the list.
  Widget _buildAutoRow() {
    const tokens = luTokens;
    final l10n = l10nOf(context);
    final subtitle = _autoPicking
        ? l10n.watchAutoPicking
        : (_autoFoundNothing ? l10n.watchAutoNone : l10n.watchAutoIdle);
    return Padding(
      padding: const EdgeInsets.only(bottom: ZplaySpacing.s8),
      child: FocusableCard(
        onTap: _autoPicking || _sources.isEmpty && !_isLoadingSources
            ? null
            : _runAutoPick,
        builder: (context, state) => CardFocusRing(
          focused: state.focused,
          radius: ZplayRadius.mdAll,
          child: AnimatedContainer(
            duration: ZplayMotion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: ZplaySpacing.s16,
              vertical: ZplaySpacing.s12,
            ),
            decoration: BoxDecoration(
              color: tokens.accent.withValues(
                alpha: state.highlighted ? 0.16 : 0.10,
              ),
              borderRadius: ZplayRadius.mdAll,
              border: Border.all(color: tokens.accent),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: _autoPicking
                      ? Padding(
                          padding: const EdgeInsets.all(4),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.accent,
                          ),
                        )
                      : Icon(
                          Icons.bolt_rounded,
                          color: tokens.accent,
                          size: 26,
                        ),
                ),
                const SizedBox(width: ZplaySpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.watchAutoTitle,
                        style: ZplayType.label
                            .copyWith(weight: FontWeight.w700)
                            .toStyle(color: tokens.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: ZplayType.caption.toStyle(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_arrow_rounded, color: tokens.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourcesList(List<StreamSource> sources, bool isDesktop) {
    if (_isLoadingSources && sources.isEmpty) {
      return _buildShimmerList();
    }

    if (!_isLoadingSources && sources.isEmpty) {
      return _buildEmptyState();
    }

    final list = ListView.separated(
      controller: isDesktop ? _sourcesScrollController : null,
      shrinkWrap: !isDesktop,
      physics: isDesktop
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: sources.length + 1 + (_isLoadingSources ? 2 : 0),
      separatorBuilder: (_, index) =>
          SizedBox(height: index == 0 ? 0 : ZplaySpacing.s8),
      itemBuilder: (context, row) {
        if (row == 0) return _buildAutoRow();
        final index = row - 1;
        if (index >= sources.length) {
          return _buildShimmerCard();
        }
        return _SourceCard(
          source: sources[index],
          detail: widget.detail,
          playsViaDebrid: _debridReady && sources[index].isMagnet,
          debridServiceName: _debridServiceName,
          deadReason: _deadReason(sources[index]),
          focusNode: index == 0 ? _firstSourceFocusNode : null,
          onActivate: () => _playSourceAt(sources, index),
        );
      },
    );

    return list;
  }

  Widget _buildSizeFilterDropdown() {
    final currentText = _getSizeFilterLabel(_selectedSizeFilter);

    return Builder(
      builder: (buttonContext) {
        return FocusableCard(
          onTap: () => _isDesktop()
              ? _showSizeGlassDropdown(buttonContext)
              : _showSizeBottomSheet(),
          builder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: ZplayRadius.mdAll,
              boxShadow: [
                BoxShadow(
                  color: luTokens.bg.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PerformanceLiquidLens(
              style: PerformanceGlassStyles.menuButton,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: ZplayRadius.mdAll,
                  border: Border.all(
                    color: luTokens.textPrimary.withValues(
                      alpha: ZplayOpacity.overlayHover,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.data_usage_rounded,
                      color: luTokens.textEmphasis,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentText,
                      style: ZplayType.label
                          .copyWith(weight: FontWeight.w600)
                          .toStyle(color: luTokens.textPrimary),
                    ),
                    const SizedBox(width: ZplaySpacing.s4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: luTokens.textEmphasis,
                      size: 20,
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

  void _showSizeGlassDropdown(BuildContext buttonContext) {
    final RenderBox button = buttonContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset buttonOffset = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    const double dialogWidth = 230.0;
    final double spaceBelow =
        overlay.size.height - (buttonOffset.dy + button.size.height + 8) - 16;
    final double spaceAbove = buttonOffset.dy - 16;
    final bool openAbove = spaceBelow < 280 && spaceAbove > spaceBelow;

    final double maxMenuHeight = (openAbove ? spaceAbove : spaceBelow).clamp(
      160.0,
      420.0,
    );
    final double? topOffset = openAbove
        ? null
        : (buttonOffset.dy + button.size.height + 8);
    final double? bottomOffset = openAbove
        ? (overlay.size.height - buttonOffset.dy + 8)
        : null;

    final double rawLeft = buttonOffset.dx;
    final double maxLeft = overlay.size.width - dialogWidth - 12.0;
    final double leftOffset = rawLeft.clamp(
      12.0,
      maxLeft > 12.0 ? maxLeft : 12.0,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10nCurrent().plyDismiss,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              top: topOffset,
              bottom: bottomOffset,
              left: leftOffset,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (openAbove ? 10 : -10) * (1 - value)),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: ZplayRadius.mdAll,
                      boxShadow: [
                        BoxShadow(
                          color: luTokens.bg.withValues(alpha: 0.60),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: PerformanceLiquidLens(
                      style: PerformanceGlassStyles.menu,
                      child: Container(
                        width: dialogWidth,
                        constraints: BoxConstraints(maxHeight: maxMenuHeight),
                        padding: const EdgeInsets.all(ZplaySpacing.s8),
                        decoration: BoxDecoration(
                          borderRadius: ZplayRadius.mdAll,
                          border: Border.all(
                            color: luTokens.textPrimary.withValues(
                              alpha: ZplayOpacity.overlayHover,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSizeDropdownItem(
                                l10nOf(context).watchSizeAll,
                                null,
                              ),
                              const SizedBox(height: ZplaySpacing.s4),
                              Container(
                                height: 1,
                                color: luTokens.textPrimary.withValues(
                                  alpha: ZplayOpacity.borderMedium,
                                ),
                              ),
                              const SizedBox(height: ZplaySpacing.s4),
                              _buildSizeDropdownItem('< 1 GB', '<1gb'),
                              _buildSizeDropdownItem('1 GB – 5 GB', '1-5gb'),
                              _buildSizeDropdownItem('5 GB – 15 GB', '5-15gb'),
                              _buildSizeDropdownItem(
                                '15 GB – 30 GB',
                                '15-30gb',
                              ),
                              _buildSizeDropdownItem('> 30 GB', '>30gb'),
                              const SizedBox(height: ZplaySpacing.s4),
                              Container(
                                height: 1,
                                color: luTokens.textPrimary.withValues(
                                  alpha: ZplayOpacity.borderMedium,
                                ),
                              ),
                              const SizedBox(height: ZplaySpacing.s4),
                              _buildSizeDropdownItem(
                                l10nOf(context).watchSizeLargestFirst,
                                'largest',
                              ),
                              _buildSizeDropdownItem(
                                l10nOf(context).watchSizeSmallestFirst,
                                'smallest',
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildSizeDropdownItem(String title, String? value) {
    final isSelected = _selectedSizeFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSizeFilter = value;
        });
        Navigator.pop(context);
      },
      borderRadius: ZplayRadius.mdAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: ZplayRadius.mdAll,
          color: isSelected
              ? luTokens.textPrimary.withValues(
                  alpha: ZplayOpacity.borderMedium,
                )
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: ZplayType.body
                    .copyWith(
                      weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    )
                    .toStyle(
                      color: isSelected
                          ? luTokens.textPrimary
                          : luTokens.textEmphasis,
                    ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: luTokens.textPrimary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonFilterDropdown() {
    final addons = _sources.map((e) => e.addonName).toSet().toList();
    if (addons.isEmpty) return const SizedBox.shrink();
    final currentText = _selectedAddonFilter == null
        ? l10nOf(context).watchAllSources
        : displayAddonName(_selectedAddonFilter!);

    return Builder(
      builder: (buttonContext) {
        return FocusableCard(
          onTap: () => _isDesktop()
              ? _showGlassDropdown(buttonContext, addons)
              : _showAddonBottomSheet(addons),
          builder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: ZplayRadius.mdAll,
              boxShadow: [
                BoxShadow(
                  color: luTokens.bg.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PerformanceLiquidLens(
              style: PerformanceGlassStyles.menuButton,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: ZplayRadius.mdAll,
                  border: Border.all(
                    color: luTokens.textPrimary.withValues(
                      alpha: ZplayOpacity.overlayHover,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentText,
                      style: ZplayType.label
                          .copyWith(weight: FontWeight.w600)
                          .toStyle(color: luTokens.textPrimary),
                    ),
                    const SizedBox(width: ZplaySpacing.s4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: luTokens.textEmphasis,
                      size: 20,
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

  void _showGlassDropdown(BuildContext buttonContext, List<String> addons) {
    final RenderBox button = buttonContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset buttonOffset = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    const double dialogWidth = 230.0;
    final double spaceBelow =
        overlay.size.height - (buttonOffset.dy + button.size.height + 8) - 16;
    final double spaceAbove = buttonOffset.dy - 16;
    final bool openAbove = spaceBelow < 280 && spaceAbove > spaceBelow;

    final double maxMenuHeight = (openAbove ? spaceAbove : spaceBelow).clamp(
      160.0,
      420.0,
    );
    final double? topOffset = openAbove
        ? null
        : (buttonOffset.dy + button.size.height + 8);
    final double? bottomOffset = openAbove
        ? (overlay.size.height - buttonOffset.dy + 8)
        : null;

    final double rawLeft = buttonOffset.dx;
    final double maxLeft = overlay.size.width - dialogWidth - 12.0;
    final double leftOffset = rawLeft.clamp(
      12.0,
      maxLeft > 12.0 ? maxLeft : 12.0,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10nCurrent().plyDismiss,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              top: topOffset,
              bottom: bottomOffset,
              left: leftOffset,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (openAbove ? 10 : -10) * (1 - value)),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: ZplayRadius.mdAll,
                      boxShadow: [
                        BoxShadow(
                          color: luTokens.bg.withValues(alpha: 0.60),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: PerformanceLiquidLens(
                      style: PerformanceGlassStyles.menu,
                      child: Container(
                        width: dialogWidth,
                        constraints: BoxConstraints(maxHeight: maxMenuHeight),
                        padding: const EdgeInsets.all(ZplaySpacing.s8),
                        decoration: BoxDecoration(
                          borderRadius: ZplayRadius.mdAll,
                          border: Border.all(
                            color: luTokens.textPrimary.withValues(
                              alpha: ZplayOpacity.overlayHover,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdownItem(
                                l10nOf(context).watchAllSources,
                                null,
                              ),
                              const SizedBox(height: ZplaySpacing.s4),
                              Container(
                                height: 1,
                                color: luTokens.textPrimary.withValues(
                                  alpha: ZplayOpacity.borderMedium,
                                ),
                              ),
                              const SizedBox(height: ZplaySpacing.s4),
                              ...addons.map(
                                (a) =>
                                    _buildDropdownItem(displayAddonName(a), a),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildDropdownItem(String title, String? value) {
    final isSelected = _selectedAddonFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAddonFilter = value;
        });
        Navigator.pop(context);
      },
      borderRadius: ZplayRadius.mdAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: ZplaySpacing.s12,
          horizontal: ZplaySpacing.s16,
        ),
        decoration: BoxDecoration(
          borderRadius: ZplayRadius.mdAll,
          color: isSelected
              ? luTokens.textPrimary.withValues(
                  alpha: ZplayOpacity.borderMedium,
                )
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: ZplayType.subtitle
                    .copyWith(
                      weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    )
                    .toStyle(
                      color: isSelected
                          ? luTokens.textPrimary
                          : luTokens.textEmphasis,
                    ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: luTokens.textPrimary, size: 20),
          ],
        ),
      ),
    );
  }

  String _getAudioFilterLabel(String key) {
    switch (key) {
      case 'multi':
        return l10nOf(context).watchAudioMulti;
      case 'english':
        return l10nOf(context).watchAudioEnglish;
      case 'hindi':
        return l10nOf(context).watchAudioHindi;
      case 'german':
        return l10nOf(context).watchAudioGerman;
      case 'french':
        return l10nOf(context).watchAudioFrench;
      case 'spanish_castilian':
        return l10nOf(context).watchAudioCastilian;
      case 'spanish_latino':
        return l10nOf(context).watchAudioLatino;
      case 'spanish':
        return l10nOf(context).watchAudioSpanish;
      case 'russian':
        return l10nOf(context).watchAudioRussian;
      case 'japanese':
        return l10nOf(context).watchAudioJapanese;
      case 'italian':
        return l10nOf(context).watchAudioItalian;
      default:
        return l10nOf(context).watchAllAudio;
    }
  }

  Widget _buildAudioFilterDropdown() {
    final currentText = _getAudioFilterLabel(_selectedAudioFilter);
    final isActive = _selectedAudioFilter != 'all';

    return Builder(
      builder: (buttonContext) {
        return FocusableCard(
          onTap: () => _isDesktop()
              ? _showAudioGlassDropdown(buttonContext)
              : _showAudioBottomSheet(),
          builder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: ZplayRadius.mdAll,
              boxShadow: [
                BoxShadow(
                  color: luTokens.bg.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PerformanceLiquidLens(
              style: PerformanceGlassStyles.menuButton,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: ZplayRadius.mdAll,
                  border: Border.all(
                    color: isActive
                        ? luTokens.accent.withValues(alpha: 0.6)
                        : luTokens.textPrimary.withValues(
                            alpha: ZplayOpacity.overlayHover,
                          ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.audiotrack_rounded,
                      color: isActive ? luTokens.accent : luTokens.textEmphasis,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentText,
                      style: ZplayType.label
                          .copyWith(weight: FontWeight.w600)
                          .toStyle(
                            color: isActive
                                ? luTokens.accent
                                : luTokens.textPrimary,
                          ),
                    ),
                    const SizedBox(width: ZplaySpacing.s4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: luTokens.textEmphasis,
                      size: 20,
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

  void _showAudioGlassDropdown(BuildContext buttonContext) {
    final RenderBox button = buttonContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset buttonOffset = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    const double dialogWidth = 240.0;
    final double spaceBelow =
        overlay.size.height - (buttonOffset.dy + button.size.height + 8) - 16;
    final double spaceAbove = buttonOffset.dy - 16;
    final bool openAbove = spaceBelow < 280 && spaceAbove > spaceBelow;

    final double maxMenuHeight = (openAbove ? spaceAbove : spaceBelow).clamp(
      160.0,
      420.0,
    );
    final double? topOffset = openAbove
        ? null
        : (buttonOffset.dy + button.size.height + 8);
    final double? bottomOffset = openAbove
        ? (overlay.size.height - buttonOffset.dy + 8)
        : null;

    final double rawLeft = buttonOffset.dx;
    final double maxLeft = overlay.size.width - dialogWidth - 12.0;
    final double leftOffset = rawLeft.clamp(
      12.0,
      maxLeft > 12.0 ? maxLeft : 12.0,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10nCurrent().plyDismiss,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              top: topOffset,
              bottom: bottomOffset,
              left: leftOffset,
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: ZplayRadius.mdAll,
                    boxShadow: [
                      BoxShadow(
                        color: luTokens.bg.withValues(alpha: 0.40),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: PerformanceLiquidLens(
                    style: PerformanceGlassStyles.menu,
                    child: Container(
                      width: dialogWidth,
                      constraints: BoxConstraints(maxHeight: maxMenuHeight),
                      padding: const EdgeInsets.symmetric(
                        vertical: ZplaySpacing.s8,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: ZplayRadius.mdAll,
                        border: Border.all(
                          color: luTokens.textPrimary.withValues(
                            alpha: ZplayOpacity.overlayHover,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAllAudio,
                              'all',
                            ),
                            const SizedBox(height: ZplaySpacing.s4),
                            Container(
                              height: 1,
                              color: luTokens.textPrimary.withValues(
                                alpha: ZplayOpacity.borderMedium,
                              ),
                            ),
                            const SizedBox(height: ZplaySpacing.s4),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioMulti,
                              'multi',
                            ),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioEnglish,
                              'english',
                            ),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioHindi,
                              'hindi',
                            ),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioGerman,
                              'german',
                            ),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioFrench,
                              'french',
                            ),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioCastilian,
                              'spanish_castilian',
                            ),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioLatino,
                              'spanish_latino',
                            ),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioSpanish,
                              'spanish',
                            ),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioRussian,
                              'russian',
                            ),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioJapanese,
                              'japanese',
                            ),
                            _buildAudioDropdownItem(
                              l10nOf(context).watchAudioItalian,
                              'italian',
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildAudioDropdownItem(String title, String value) {
    final isSelected = _selectedAudioFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAudioFilter = value;
        });
        Navigator.pop(context);
      },
      borderRadius: ZplayRadius.mdAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: ZplayRadius.mdAll,
          color: isSelected
              ? luTokens.textPrimary.withValues(
                  alpha: ZplayOpacity.borderMedium,
                )
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: ZplayType.body
                    .copyWith(
                      weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    )
                    .toStyle(
                      color: isSelected
                          ? luTokens.textPrimary
                          : luTokens.textEmphasis,
                    ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: luTokens.accent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassBottomSheetContainer({
    required BuildContext context,
    required Widget header,
    required Widget content,
  }) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: ZplaySpacing.s12,
          vertical: ZplaySpacing.s12,
        ),
        decoration: BoxDecoration(
          borderRadius: ZplayRadius.lgAll,
          color: luTokens.surfaceOverlay.withValues(alpha: 0.96),
          border: Border.all(
            color: luTokens.textPrimary.withValues(
              alpha: ZplayOpacity.borderStrong,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: luTokens.bg.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: ZplayRadius.lgAll,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: ZplaySpacing.s12),
                      decoration: BoxDecoration(
                        color: luTokens.textPrimary.withValues(alpha: 0.3),
                        borderRadius: ZplayRadius.xsAll,
                      ),
                    ),
                  ),
                  header,
                  const SizedBox(height: ZplaySpacing.s8),
                  Divider(
                    color: luTokens.textPrimary.withValues(
                      alpha: ZplayOpacity.borderMedium,
                    ),
                    height: 1,
                  ),
                  const SizedBox(height: ZplaySpacing.s8),
                  content,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem({
    required String title,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: ZplayRadius.mdAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: ZplaySpacing.s12,
          horizontal: ZplaySpacing.s16,
        ),
        margin: const EdgeInsets.only(bottom: ZplaySpacing.s4),
        decoration: BoxDecoration(
          borderRadius: ZplayRadius.mdAll,
          color: isSelected
              ? activeColor.withValues(alpha: ZplayOpacity.overlayHover)
              : Colors.transparent,
          border: isSelected
              ? Border.all(color: activeColor.withValues(alpha: 0.4))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: ZplayType.subtitle
                    .copyWith(
                      weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    )
                    .toStyle(
                      color: isSelected
                          ? luTokens.textPrimary
                          : luTokens.textEmphasis,
                    ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: activeColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAudioBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildGlassBottomSheetContainer(
          context: context,
          header: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ZplaySpacing.s8),
                decoration: BoxDecoration(
                  color: luTokens.accent.withValues(
                    alpha: ZplayOpacity.overlayHover,
                  ),
                  borderRadius: ZplayRadius.smAll,
                ),
                child: Icon(
                  Icons.audiotrack_rounded,
                  color: luTokens.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: ZplaySpacing.s12),
              Expanded(
                child: Text(
                  l10nCurrent().plyAudioDubLanguage,
                  style: ZplayType.subtitle
                      .copyWith(weight: FontWeight.w700)
                      .toStyle(color: luTokens.textPrimary),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: luTokens.textSecondary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAllAudio,
                    isSelected: _selectedAudioFilter == 'all',
                    activeColor: luTokens.accent,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'all');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioMulti,
                    isSelected: _selectedAudioFilter == 'multi',
                    activeColor: luTokens.accent,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'multi');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioEnglish,
                    isSelected: _selectedAudioFilter == 'english',
                    activeColor: luTokens.accent,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'english');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioHindi,
                    isSelected: _selectedAudioFilter == 'hindi',
                    activeColor: luTokens.warning,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'hindi');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioGerman,
                    isSelected: _selectedAudioFilter == 'german',
                    activeColor: luTokens.warning,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'german');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioFrench,
                    isSelected: _selectedAudioFilter == 'french',
                    activeColor: luTokens.info,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'french');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioCastilian,
                    isSelected: _selectedAudioFilter == 'spanish_castilian',
                    activeColor: luTokens.warning,
                    onTap: () {
                      setState(
                        () => _selectedAudioFilter = 'spanish_castilian',
                      );
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioLatino,
                    isSelected: _selectedAudioFilter == 'spanish_latino',
                    activeColor: luTokens.success,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'spanish_latino');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioSpanish,
                    isSelected: _selectedAudioFilter == 'spanish',
                    activeColor: luTokens.warning,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'spanish');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioRussian,
                    isSelected: _selectedAudioFilter == 'russian',
                    activeColor: luTokens.info,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'russian');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioJapanese,
                    isSelected: _selectedAudioFilter == 'japanese',
                    activeColor: luTokens.danger,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'japanese');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAudioItalian,
                    isSelected: _selectedAudioFilter == 'italian',
                    activeColor: luTokens.success,
                    onTap: () {
                      setState(() => _selectedAudioFilter = 'italian');
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSizeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildGlassBottomSheetContainer(
          context: context,
          header: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ZplaySpacing.s8),
                decoration: BoxDecoration(
                  color: luTokens.info.withValues(
                    alpha: ZplayOpacity.overlayHover,
                  ),
                  borderRadius: ZplayRadius.smAll,
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  color: luTokens.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: ZplaySpacing.s12),
              Expanded(
                child: Text(
                  l10nOf(context).watchSizeFilter,
                  style: ZplayType.subtitle
                      .copyWith(weight: FontWeight.w700)
                      .toStyle(color: luTokens.textPrimary),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: luTokens.textSecondary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchSizeAll,
                    isSelected: _selectedSizeFilter == null,
                    activeColor: luTokens.info,
                    onTap: () {
                      setState(() => _selectedSizeFilter = null);
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchSizeLargestFirst,
                    isSelected: _selectedSizeFilter == 'largest',
                    activeColor: luTokens.info,
                    onTap: () {
                      setState(() => _selectedSizeFilter = 'largest');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchSizeSmallestFirst,
                    isSelected: _selectedSizeFilter == 'smallest',
                    activeColor: luTokens.info,
                    onTap: () {
                      setState(() => _selectedSizeFilter = 'smallest');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: '< 1 GB',
                    isSelected: _selectedSizeFilter == '<1gb',
                    activeColor: luTokens.info,
                    onTap: () {
                      setState(() => _selectedSizeFilter = '<1gb');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: '1 - 5 GB',
                    isSelected: _selectedSizeFilter == '1-5gb',
                    activeColor: luTokens.info,
                    onTap: () {
                      setState(() => _selectedSizeFilter = '1-5gb');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: '5 - 15 GB',
                    isSelected: _selectedSizeFilter == '5-15gb',
                    activeColor: luTokens.info,
                    onTap: () {
                      setState(() => _selectedSizeFilter = '5-15gb');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: '15 - 30 GB',
                    isSelected: _selectedSizeFilter == '15-30gb',
                    activeColor: luTokens.info,
                    onTap: () {
                      setState(() => _selectedSizeFilter = '15-30gb');
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildBottomSheetItem(
                    title: '> 30 GB',
                    isSelected: _selectedSizeFilter == '>30gb',
                    activeColor: luTokens.info,
                    onTap: () {
                      setState(() => _selectedSizeFilter = '>30gb');
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddonBottomSheet(List<String> addons) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildGlassBottomSheetContainer(
          context: context,
          header: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ZplaySpacing.s8),
                decoration: BoxDecoration(
                  color: luTokens.textPrimary.withValues(
                    alpha: ZplayOpacity.borderMedium,
                  ),
                  borderRadius: ZplayRadius.smAll,
                ),
                child: Icon(
                  Icons.extension_rounded,
                  color: luTokens.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: ZplaySpacing.s12),
              Expanded(
                child: Text(
                  l10nOf(context).watchProviderFilter,
                  style: ZplayType.subtitle
                      .copyWith(weight: FontWeight.w700)
                      .toStyle(color: luTokens.textPrimary),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: luTokens.textSecondary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBottomSheetItem(
                    title: l10nOf(context).watchAllSources,
                    isSelected: _selectedAddonFilter == null,
                    activeColor: luTokens.textPrimary,
                    onTap: () {
                      setState(() => _selectedAddonFilter = null);
                      Navigator.pop(ctx);
                    },
                  ),
                  for (final addon in addons)
                    _buildBottomSheetItem(
                      title: displayAddonName(addon),
                      isSelected: _selectedAddonFilter == addon,
                      activeColor: luTokens.textPrimary,
                      onTap: () {
                        setState(() => _selectedAddonFilter = addon);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const _EmptySourcesStateWidget();
  }

  Widget _buildShimmerList() {
    return Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: ZplaySpacing.s8),
          child: _buildShimmerCard(),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return const RepaintBoundary(child: _ShimmerCard());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Back Button
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBackButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: luTokens.bg.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(
          color: luTokens.textPrimary.withValues(
            alpha: ZplayOpacity.borderStrong,
          ),
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: luTokens.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source Card
// ─────────────────────────────────────────────────────────────────────────────
/// One source in the list, as a real focus target.
///
/// The row used to be a `MouseRegion` around an `InkWell`, which is
/// pointer-first: an `InkWell` does install a focus node, but the row itself
/// drew nothing on focus and the screen never handed the list focus at all, so
/// on a television the page answered no key — Down left it pixel-identical and
/// the centre button started nothing, which made the player unreachable from
/// the couch. It is now the house pair: [FocusableCard] for the node, the
/// `ActivateIntent` binding and the hover/press state, and [CardFocusRing] for
/// the one focus indicator every other card in the app draws.
///
/// A torrent also draws the copy-magnet button, which is the one thing on the
/// row that is not the row's own activation. It was a bare `InkWell`, so a
/// pointer could copy the magnet and a remote could not: a single column has no
/// neighbour to the right, and a control drawn inside the row's own rectangle is
/// not a directional target, so no arrow could ever land on it. It is now a
/// second stop of this row — [FocusableCard] and [CardFocusRing] like the row
/// itself — and the row hands the remote into it on Right, which is the move a
/// viewer already makes to reach the next control along a row and the key the
/// device pass measured as doing nothing here.
///
/// Presentational on purpose: [onActivate] belongs to the screen, so where a
/// source opens - the player, another route, the browser - is decided where the
/// navigation lives.
class _SourceCard extends StatefulWidget {
  final StreamSource source;
  final MovieDetail detail;

  /// Set when this torrent will be played through the user's Debrid service
  /// instead of the local P2P engine. Carries the service name for the badge.
  final bool playsViaDebrid;
  final String? debridServiceName;

  /// Starts this source. Called by a tap and by the remote's centre button.
  final VoidCallback onActivate;

  /// Supplied for the first row only, which is where the screen hands focus as
  /// it opens; every other row carries a node of its own.
  final FocusNode? focusNode;

  /// Why this source is unlikely to play, when it is known: the row is drawn
  /// dimmed with the reason first among its badges. It stays tappable, since
  /// a seeder count can be stale and a link can come back.
  final SourceDeadReason? deadReason;

  const _SourceCard({
    required this.source,
    required this.detail,
    required this.onActivate,
    this.playsViaDebrid = false,
    this.debridServiceName,
    this.deadReason,
    this.focusNode,
  });

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  /// The node the row focusses through when the screen has not named one.
  ///
  /// Owned here rather than left to [FocusableCard]'s own internal node,
  /// because the screen hands focus to the first source after it loads.
  final FocusNode _ownedRowNode = FocusNode(debugLabel: 'WatchSourceRow');

  FocusNode get _rowNode => widget.focusNode ?? _ownedRowNode;

  @override
  void dispose() {
    _ownedRowNode.dispose();
    super.dispose();
  }

  /// Longest stored rejection reason that still fits the badge row. Anything
  /// longer falls back to plain 'Unavailable', because a chip is not a sentence.
  static const int _rejectionBadgeMaxChars = 24;

  @override
  Widget build(BuildContext context) {
    final s = widget.source;
    final badges = <Widget>[];

    if (widget.deadReason case final reason?) {
      badges.add(
        _badge(
          reason == SourceDeadReason.noSeeders
              ? l10nOf(context).watchDeadNoSeeds
              : l10nOf(context).watchDeadUnreachable,
          luTokens.textMuted,
        ),
      );
    }

    // Quality badge
    if (s.quality != null) {
      Color badgeColor;
      switch (s.quality) {
        case '4K':
          badgeColor = luTokens.accent;
          break;
        case '1080p':
          badgeColor = luTokens.info;
          break;
        case '720p':
          badgeColor = luTokens.textSecondary;
          break;
        default:
          badgeColor = luTokens.danger;
      }
      badges.add(_badge(s.quality!, badgeColor));
    }

    if (s.isHDR) badges.add(_badge('HDR', luTokens.warning));
    if (widget.playsViaDebrid) {
      badges.add(
        _badge('⚡ ${widget.debridServiceName ?? 'Debrid'}', luTokens.info),
      );
    }
    // A source the provider has already refused, kept in the list because a
    // refusal can be superseded. Quiet on purpose: this is information, not an
    // error, and it only points the user at the sources above it.
    if (DebridRejectionStore.instance.isRejected(s.infoHash)) {
      final String? reason = DebridRejectionStore.instance.reasonFor(
        s.infoHash,
      );
      final bool shortReason =
          reason != null &&
          reason.isNotEmpty &&
          reason.length <= _rejectionBadgeMaxChars;
      badges.add(
        _badge(
          shortReason ? reason : l10nOf(context).watchUnavailable,
          luTokens.textMuted,
        ),
      );
    }
    if (s.codec != null) badges.add(_badge(s.codec!, luTokens.textMuted));
    badges.add(
      StreamBitrateBadge(
        source: s,
        runtimeMinutes: int.tryParse(widget.detail.runtime ?? ''),
      ),
    );
    if (s.fileSize != null) badges.add(_badge(s.fileSize!, luTokens.textMuted));
    if (s.seeders != null) {
      final seederColor = s.seeders! >= 20
          ? luTokens.success
          : (s.seeders! >= 5 ? luTokens.warning : luTokens.danger);
      badges.add(
        _badge('👤 ${l10nOf(context).watchSeeds(s.seeders!)}', seederColor),
      );
    }

    // Audio Language / Dub badge
    final audioBadge = s.getAudioBadge(mediaTitle: widget.detail.name);
    if (audioBadge != null) {
      Color audioBadgeColor;
      if (audioBadge.contains('MULTI')) {
        audioBadgeColor = luTokens.accent;
      } else if (audioBadge.contains('HINDI') ||
          audioBadge.contains('TELUGU') ||
          audioBadge.contains('TAMIL') ||
          audioBadge.contains('MALAYALAM') ||
          audioBadge.contains('KANNADA') ||
          audioBadge.contains('PUNJABI')) {
        audioBadgeColor = luTokens.warning;
      } else if (audioBadge.contains('GER')) {
        audioBadgeColor = luTokens.warning;
      } else if (audioBadge.contains('FRE')) {
        audioBadgeColor = luTokens.info;
      } else if (audioBadge.contains('CAST')) {
        audioBadgeColor = luTokens.warning;
      } else if (audioBadge.contains('LAT')) {
        audioBadgeColor = luTokens.success;
      } else if (audioBadge.contains('SPA')) {
        audioBadgeColor = luTokens.warning;
      } else if (audioBadge.contains('RUS')) {
        audioBadgeColor = luTokens.info;
      } else if (audioBadge.contains('JPN')) {
        audioBadgeColor = luTokens.danger;
      } else if (audioBadge.contains('ITA')) {
        audioBadgeColor = luTokens.success;
      } else {
        audioBadgeColor = luTokens.textMuted;
      }
      badges.add(_badge(audioBadge, audioBadgeColor));
    }

    final Widget row = RepaintBoundary(
      // Rebuilds when the remote moves between this row and the action drawn on
      // it, which is not a change [FocusableCard] itself sees: the row keeps
      // focus either way, because `FocusNode.hasFocus` is true for every ancestor
      // of the primary focus - including an ancestor whose own inner control is
      // the one holding it.
      child: ListenableBuilder(
        listenable: _rowNode,
        builder: (context, _) => FocusableCard(
          focusNode: _rowNode,
          onTap: widget.onActivate,
          builder: (context, state) {
            // `highlighted` for the wash and the lit chevron, so a pointer and a
            // D-pad light a row the same way; `focused` for the ring, which is the
            // only thing on the row that says which one the remote is on. The ring
            // is painted over the surface rather than around it, so arriving
            // focus moves nothing.
            final bool lit = state.highlighted;
            // The ring reads a narrower question than `focused` does. That flag is
            // `FocusNode.hasFocus`, which is true for every ancestor of the primary
            // focus, so a row carrying a stop of its own - the copy-magnet button -
            // would stay ringed beside it and the screen would show two indicators
            // for one remote. The row's ring is for the row itself; while the
            // remote is on the button inside, the button's ring is the indicator
            // and this one stands down. The wash stays on `highlighted`, so the row
            // the action belongs to still reads as the active row.
            return CardFocusRing(
              focused: state.focused,
              radius: ZplayRadius.smAll,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: lit
                      ? luTokens.surfaceRaised.withValues(alpha: 0.9)
                      : luTokens.surface.withValues(alpha: 0.7),
                  borderRadius: ZplayRadius.smAll,
                  border: Border.all(
                    color: lit
                        ? luTokens.accent.withValues(alpha: 0.3)
                        : luTokens.textPrimary.withValues(
                            alpha: ZplayOpacity.borderSubtle,
                          ),
                  ),
                  boxShadow: lit
                      ? [
                          BoxShadow(
                            color: luTokens.accent.withValues(
                              alpha: ZplayOpacity.borderDefault,
                            ),
                            blurRadius: 16,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    // Addon icon
                    OfficialSourceLoader.isOfficial(s)
                        ? const _OfficialSourceIcon()
                        : ArchiveSourceLoader.isArchive(s)
                        ? const _ArchiveSourceIcon()
                        : _AddonSourceIcon(addonName: s.addonName),
                    const SizedBox(width: ZplaySpacing.s12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // One rule for this label, shared with the player's
                            // top bar, so the row and the badge over the video
                            // cannot name the same stream differently.
                            s.providerLabel,
                            style: ZplayType.label
                                .copyWith(weight: FontWeight.w600)
                                .toStyle(color: luTokens.textPrimary),
                          ),
                          if (s.title != null && s.title!.isNotEmpty) ...[
                            const SizedBox(height: ZplaySpacing.s4),
                            Text(
                              s.title!,
                              style: ZplayType.bodySmall.toStyle(
                                color: luTokens.textMuted,
                              ),
                            ),
                          ],
                          if (s.description != null &&
                              s.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              s.description!,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: ZplayType.bodySmall
                                  .copyWith(height: 1.3)
                                  .toStyle(color: luTokens.textSecondary),
                            ),
                          ],
                          if (badges.isNotEmpty) ...[
                            const SizedBox(height: ZplaySpacing.s8),
                            Wrap(spacing: 4, runSpacing: 4, children: badges),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: ZplaySpacing.s8),
                    // Play chevron
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: lit
                            ? luTokens.accent.withValues(alpha: 0.2)
                            : luTokens.textPrimary.withValues(
                                alpha: ZplayOpacity.borderSubtle,
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: lit ? luTokens.accent : luTokens.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    final Widget shown = widget.deadReason == null
        ? row
        : Opacity(opacity: 0.45, child: row);
    return shown;
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: ZplayOpacity.overlayHover),
        borderRadius: ZplayRadius.xsAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: ZplayType.caption
            .copyWith(weight: FontWeight.w700, letterSpacing: 0.3)
            .toStyle(color: color),
      ),
    );
  }
}

/// The mark on an "Official on YouTube" row: a play badge, so the rights
/// holder's own upload reads apart from the scraped sources under it.
class _OfficialSourceIcon extends StatelessWidget {
  const _OfficialSourceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: luTokens.danger.withValues(alpha: ZplayOpacity.overlayHover),
        borderRadius: ZplayRadius.smAll,
        border: Border.all(color: luTokens.danger.withValues(alpha: 0.4)),
      ),
      child: Icon(
        Icons.smart_display_rounded,
        color: luTokens.danger,
        size: 24,
      ),
    );
  }
}

/// The mark on an "Internet Archive" row: a library, so a public-domain copy
/// reads apart from the scraped sources.
class _ArchiveSourceIcon extends StatelessWidget {
  const _ArchiveSourceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: luTokens.success.withValues(alpha: ZplayOpacity.overlayHover),
        borderRadius: ZplayRadius.smAll,
        border: Border.all(color: luTokens.success.withValues(alpha: 0.4)),
      ),
      child: Icon(
        Icons.account_balance_rounded,
        color: luTokens.success,
        size: 22,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Addon Source Icon / App Logo
// ─────────────────────────────────────────────────────────────────────────────
class _AddonSourceIcon extends StatelessWidget {
  final String addonName;

  const _AddonSourceIcon({required this.addonName});

  @override
  Widget build(BuildContext context) {
    final nameLower = addonName.trim().toLowerCase();
    final isBuiltIn =
        nameLower == 'zplay' ||
        nameLower == 'zplayhttp' ||
        nameLower.startsWith('builtin');

    if (isBuiltIn) {
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: luTokens.textPrimary.withValues(
            alpha: ZplayOpacity.borderFaint,
          ),
          borderRadius: ZplayRadius.smAll,
          border: Border.all(color: luTokens.accent.withValues(alpha: 0.25)),
        ),
        child: const ZplayLogo(size: 30),
      );
    }

    final logoUrl = AddonManager.instance.getAddonLogo(addonName);

    if (logoUrl != null && logoUrl.isNotEmpty) {
      if (logoUrl.startsWith('asset:')) {
        final assetPath = logoUrl.substring('asset:'.length);
        return Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: luTokens.textPrimary.withValues(
              alpha: ZplayOpacity.borderFaint,
            ),
            borderRadius: ZplayRadius.smAll,
            border: Border.all(
              color: luTokens.textPrimary.withValues(
                alpha: ZplayOpacity.borderStrong,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: ZplayRadius.xsAll,
            child: Image.asset(
              assetPath,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
          ),
        );
      }

      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(ZplaySpacing.s4),
        decoration: BoxDecoration(
          color: luTokens.textPrimary.withValues(
            alpha: ZplayOpacity.borderFaint,
          ),
          borderRadius: ZplayRadius.smAll,
          border: Border.all(
            color: luTokens.textPrimary.withValues(
              alpha: ZplayOpacity.borderStrong,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: ZplayRadius.xsAll,
          child: CachedNetworkImage(
            imageUrl: logoUrl,
            cacheManager: AppImageCache.manager,
            memCacheWidth: 96,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              color: luTokens.textPrimary.withValues(
                alpha: ZplayOpacity.borderFaint,
              ),
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: luTokens.accent,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => _buildFallbackIcon(),
          ),
        ),
      );
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    final firstLetter = addonName.isNotEmpty ? addonName[0].toUpperCase() : 'A';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: luTokens.accent.withValues(alpha: ZplayOpacity.overlayHover),
        borderRadius: ZplayRadius.smAll,
        border: Border.all(color: luTokens.accent.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: ZplayType.title
              .copyWith(weight: FontWeight.w700)
              .toStyle(color: luTokens.accent),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: luTokens.surface.withValues(alpha: 0.5),
            borderRadius: ZplayRadius.smAll,
            border: Border.all(
              color: luTokens.textPrimary.withValues(
                alpha: ZplayOpacity.borderFaint,
              ),
            ),
          ),
          child: Row(
            children: [
              _shimmerBox(40, 40, 10),
              const SizedBox(width: ZplaySpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(double.infinity, 12, 4),
                    const SizedBox(height: ZplaySpacing.s8),
                    _shimmerBox(180, 10, 4),
                    const SizedBox(height: ZplaySpacing.s8),
                    Row(
                      children: [
                        _shimmerBox(40, 16, 4),
                        const SizedBox(width: ZplaySpacing.s4),
                        _shimmerBox(50, 16, 4),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ZplaySpacing.s8),
              _shimmerBox(36, 36, 18),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double width, double height, double radius) {
    final shimmerValue = _controller.value;
    final gradientStart = shimmerValue - 0.3;
    final gradientEnd = shimmerValue + 0.3;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            luTokens.surfaceRaised.withValues(alpha: 0.5),
            luTokens.surfaceRaised.withValues(alpha: 0.8),
            luTokens.surfaceRaised.withValues(alpha: 0.5),
          ],
          stops: [
            (gradientStart).clamp(0.0, 1.0),
            (shimmerValue).clamp(0.0, 1.0),
            (gradientEnd).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

class _EmptySourcesStateWidget extends StatefulWidget {
  const _EmptySourcesStateWidget();

  @override
  State<_EmptySourcesStateWidget> createState() =>
      _EmptySourcesStateWidgetState();
}

class _EmptySourcesStateWidgetState extends State<_EmptySourcesStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );
    // Run the entrance once. A perpetual pulse kept this whole state ticking.
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Static card content — identical on every platform.
    final cardContent = Container(
      padding: const EdgeInsets.symmetric(
        vertical: ZplaySpacing.s48,
        horizontal: ZplaySpacing.s24,
      ),
      decoration: BoxDecoration(
        color: luTokens.surfaceRaised.withValues(alpha: 0.94),
        border: Border.all(
          color: luTokens.textPrimary.withValues(
            alpha: ZplayOpacity.borderDefault,
          ),
        ),
        borderRadius: ZplayRadius.lgAll,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(ZplaySpacing.s16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: luTokens.accent.withValues(
                alpha: ZplayOpacity.borderMedium,
              ),
              border: Border.all(color: luTokens.accent.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.radar_rounded, color: luTokens.accent, size: 40),
          ),
          const SizedBox(height: ZplaySpacing.s24),
          Text(
            l10nOf(context).watchNoSources,
            style: ZplayType.title
                .copyWith(weight: FontWeight.w500)
                .toStyle(color: luTokens.textPrimary),
          ),
          const SizedBox(height: ZplaySpacing.s12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              l10nOf(context).watchNoSourcesBody,
              textAlign: TextAlign.center,
              style: ZplayType.body
                  .copyWith(height: 1.5)
                  .toStyle(color: luTokens.textSecondary),
            ),
          ),
          const SizedBox(height: ZplaySpacing.s32),
          LuButton(
            label: l10nOf(context).watchInstallAddons,
            icon: Icons.extension_rounded,
            compact: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
    );

    // The glass card — blur is static, not animated
    final glassCard = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: ZplayRadius.lgAll,
        boxShadow: [
          BoxShadow(
            color: luTokens.bg.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: cardContent,
    );

    // Only the initial fade/scale is animated (runs once, then stops)
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: _scaleAnim.value, child: child),
        );
      },
      child: glassCard,
    );
  }
}
