import '../../l10n/l10n.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/music/music_track.dart';
import '../../services/layout/form_factor.dart';
import '../../services/music/music_download_service.dart';
import '../../services/music/music_library_service.dart';
import '../../services/music/music_player_controller.dart';
import '../../services/music/music_service.dart';
import '../../services/music/music_settings.dart';
import '../../services/playback/music_now_playing_bridge.dart';
import '../../shell/app_shell_scope.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_confirm.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_text_field.dart';
import '../../ui/lu_theme.dart';
import '../../widgets/music/music_interactive_physics_button.dart';
import '../../widgets/music/music_waveform_seekbar.dart';
import '../settings/appearance/music_player_studio_page.dart';
import '../settings/appearance/music_settings_page.dart';
import 'lu_media_kit.dart';

part 'music_page_parts.dart';
part 'music_page_overlays.dart';
part 'music_page_player.dart';

/// Music's five views. Declaration order is the switcher order.
enum MusicView { home, search, browse, radio, library }

extension MusicViewX on MusicView {
  String get label => switch (this) {
    MusicView.home => l10nCurrent().musHome,
    MusicView.search => l10nCurrent().musSearch,
    MusicView.browse => l10nCurrent().musBrowse,
    MusicView.radio => l10nCurrent().musRadio,
    MusicView.library => l10nCurrent().musLibrary,
  };
}

/// The page's transient layers, bottom to top in paint order. The order is
/// what Back and Escape unwind by: the last open one is the one on top.
enum _MusicLayer {
  artist,
  album,
  curatedPlaylist,
  userPlaylist,
  shortcuts,
  downloads,
  player,
  queue,
  lyrics,
}

/// Whether the header takes its desktop row height. One breakpoint, read by
/// the header, the view band and the page's scroll inset.
bool _musicIsDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 900;

/// The header row's own height, including the strip the shell's blended nav
/// bar is charged to this page (`MediaQuery.paddingOf(context).top`).
double _musicHeaderHeight(BuildContext context) =>
    (_musicIsDesktop(context) ? 72.0 : 62.0) +
    MediaQuery.paddingOf(context).top;

/// The view band's height: the pill row plus the gap above and below it.
double _musicViewBandHeight(BuildContext context) =>
    LuSpace.s * 2 +
    (FormFactorService.of(context) == FormFactor.television ? 48.0 : 40.0);

/// Music, in Lumora's cinema look: a near-black ground, rails of square
/// covers, gold for the one thing each screen is for.
class MusicPage extends StatelessWidget {
  const MusicPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Theme(data: luMediaTheme(), child: const _MusicPageBody());
}

class _MusicPageBody extends StatefulWidget {
  const _MusicPageBody();

  @override
  State<_MusicPageBody> createState() => _MusicPageState();
}

class _MusicPageState extends State<_MusicPageBody> {
  final MusicService _musicService = MusicService.instance;
  final MusicPlayerController _playerController =
      MusicPlayerController.instance;
  final MusicLibraryService _libraryService = MusicLibraryService.instance;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();

  /// The view on screen, and the selection the header's switcher reports. The
  /// switcher is the only writer; [_onSearchChanged] moves it too, because a
  /// query in the field is the switcher's own Search row.
  MusicView _view = MusicView.home;

  Map<String, List<MusicTrack>> _sections = {};
  List<MusicArtist> _trendingArtists = [];
  List<MusicAlbum> _newReleases = [];
  List<MusicPlaylist> _curatedPlaylists = [];
  MusicTrack? _heroTrack;

  MusicSearchData _searchData = MusicSearchData.empty;
  MusicArtistDetails? _activeArtistModal;
  MusicAlbumDetails? _activeAlbumModal;
  MusicPlaylistDetails? _activeCuratedPlaylistModal;
  UserPlaylist? _activeUserPlaylistModal;

  bool _isLoading = true;
  bool _isSearching = false;
  String _activeQuery = '';
  String _selectedFilter = 'All';
  Timer? _debounceTimer;

  bool _isPlayerExpanded = false;
  bool _showQueueDrawer = false;
  bool _showLyricsDrawer = false;
  bool _showShortcutsModal = false;
  bool _showDownloadsModal = false;
  String? _toastMessage;
  Timer? _toastTimer;

  /// The shell this page sits in, when it sits in one (tests and pushed
  /// copies may not).
  AppShellController? _shell;

  /// Gives the shell's back press back, while this page is claiming it.
  VoidCallback? _releaseBackClaim;

  /// Whether Music is the vertical Browse is showing. Browse keeps every
  /// vertical mounted in an [IndexedStack], so the Browse slot being on screen
  /// does not mean this page is.
  bool _visible = true;

  /// The layers open at the last build, and the control that had focus when
  /// each one opened, so closing a layer can put the remote back on it.
  Set<_MusicLayer> _builtLayers = const {};
  final Map<_MusicLayer, FocusNode?> _layerOpeners = {};

  @override
  void initState() {
    super.initState();
    _playerController.addListener(_onStateChanged);
    _libraryService.addListener(_onStateChanged);
    MusicDownloadService.instance.addListener(_onStateChanged);
    MusicSettings.changeNotifier.addListener(_onStateChanged);
    MusicNowPlayingBridge.expandRequests.addListener(_onExpandRequested);
    _libraryService.init();
    MusicDownloadService.instance.init();
    _loadMusicData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depends on the enclosing visibility scopes, so a switch to another
    // Browse vertical comes back through here.
    final visible = Visibility.of(context);
    if (visible != _visible) {
      _visible = visible;
      _syncBackClaim();
    }
    final shell = AppShellScope.of(context);
    if (identical(shell, _shell)) return;
    _shell?.current.removeListener(_syncBackClaim);
    _releaseBackClaim?.call();
    _releaseBackClaim = null;
    _shell = shell;
    shell?.current.addListener(_syncBackClaim);
  }

  @override
  void dispose() {
    _shell?.current.removeListener(_syncBackClaim);
    // A claim that outlived the page would swallow the press that leaves it.
    _releaseBackClaim?.call();
    _releaseBackClaim = null;
    _shell = null;
    _debounceTimer?.cancel();
    _toastTimer?.cancel();
    _playerController.removeListener(_onStateChanged);
    _libraryService.removeListener(_onStateChanged);
    MusicDownloadService.instance.removeListener(_onStateChanged);
    MusicSettings.changeNotifier.removeListener(_onStateChanged);
    MusicNowPlayingBridge.expandRequests.removeListener(_onExpandRequested);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {
      // The expanded player and the lyrics drawer are only drawn while a
      // track is loaded. A flag left set after playback stopped would keep
      // the page behind them out of the remote's reach with nothing on top to
      // close, so the flags go with the track.
      if (!_playerController.hasTrack) {
        _isPlayerExpanded = false;
        _showLyricsDrawer = false;
      }
    });
  }

  /// The layers on screen, bottom to top. A drawer or the expanded player
  /// whose flag is set but which has no track to show is not on screen, and a
  /// press must not be spent closing it.
  List<_MusicLayer> get _openLayers {
    final hasTrack = _playerController.hasTrack;
    return [
      if (_activeArtistModal != null) _MusicLayer.artist,
      if (_activeAlbumModal != null) _MusicLayer.album,
      if (_activeCuratedPlaylistModal != null) _MusicLayer.curatedPlaylist,
      if (_activeUserPlaylistModal != null) _MusicLayer.userPlaylist,
      if (_showShortcutsModal) _MusicLayer.shortcuts,
      if (_showDownloadsModal) _MusicLayer.downloads,
      if (_isPlayerExpanded && hasTrack) _MusicLayer.player,
      if (_showQueueDrawer) _MusicLayer.queue,
      if (_showLyricsDrawer && hasTrack) _MusicLayer.lyrics,
    ];
  }

  void _closeLayer(_MusicLayer layer) {
    setState(() {
      switch (layer) {
        case _MusicLayer.artist:
          _activeArtistModal = null;
        case _MusicLayer.album:
          _activeAlbumModal = null;
        case _MusicLayer.curatedPlaylist:
          _activeCuratedPlaylistModal = null;
        case _MusicLayer.userPlaylist:
          _activeUserPlaylistModal = null;
        case _MusicLayer.shortcuts:
          _showShortcutsModal = false;
        case _MusicLayer.downloads:
          _showDownloadsModal = false;
        case _MusicLayer.player:
          _isPlayerExpanded = false;
        case _MusicLayer.queue:
          _showQueueDrawer = false;
        case _MusicLayer.lyrics:
          _showLyricsDrawer = false;
      }
    });
  }

  /// Closes the topmost layer. Answers whether there was one.
  bool _closeTopLayer() {
    final open = _openLayers;
    if (open.isEmpty) return false;
    _closeLayer(open.last);
    return true;
  }

  /// Holds the shell's back press while a layer is up and Music is the page
  /// being shown, and gives it back otherwise.
  ///
  /// Android delivers Back to the shell's root guard rather than to this
  /// page's key handler, so without the claim one press skipped every overlay
  /// and left Music altogether. Claimed only while the Browse slot (Music's
  /// home) is on screen and Browse is showing the Music vertical: a claim held
  /// from a hidden slot or vertical would eat the press on whichever page the
  /// viewer is actually looking at.
  void _syncBackClaim() {
    final shell = _shell;
    final want =
        mounted &&
        shell != null &&
        shell.current.value == ShellSlot.browse &&
        _visible &&
        _openLayers.isNotEmpty;
    if (want && _releaseBackClaim == null) {
      _releaseBackClaim = shell.claimBack(_onBackClaimed);
    } else if (!want && _releaseBackClaim != null) {
      _releaseBackClaim!.call();
      _releaseBackClaim = null;
    }
  }

  void _onBackClaimed() {
    if (!mounted) return;
    if (!_closeTopLayer()) {
      // Nothing left to close: the claim was stale, so the next press is the
      // shell's again.
      _syncBackClaim();
    }
  }

  /// Remembers what had focus when a layer opened and, once a layer closes,
  /// puts focus back on it - the card, button or pill the viewer pressed.
  ///
  /// Run from `build`, where a layer about to open is not mounted yet, so the
  /// primary focus is still the control that opened it.
  void _trackLayerFocus(List<_MusicLayer> open) {
    final now = open.toSet();
    for (final layer in now.difference(_builtLayers)) {
      _layerOpeners[layer] = FocusManager.instance.primaryFocus;
    }
    final closed = _builtLayers.difference(now);
    if (closed.isNotEmpty) {
      // The topmost of the closed layers decides; lower ones closing in the
      // same frame were opened earlier, from further down.
      final top = closed.reduce((a, b) => a.index > b.index ? a : b);
      final opener = _layerOpeners[top];
      for (final layer in closed) {
        _layerOpeners.remove(layer);
      }
      if (opener != null) {
        // After the frame that removes the layer, when the control under it is
        // back in the traversal graph.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (opener.context == null || !opener.canRequestFocus) return;
          opener.requestFocus();
        });
      }
    }
    _builtLayers = now;
  }

  /// The shell's bar cannot reach this page's expansion flag and must not
  /// import it, so its expand tap arrives through the bridge instead.
  void _onExpandRequested() {
    if (!mounted || !_playerController.hasTrack) return;
    setState(() => _isPlayerExpanded = true);
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toastMessage = message);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  Future<void> _loadMusicData() async {
    setState(() => _isLoading = true);

    try {
      final sectionsFuture = _musicService.fetchFeaturedSections();
      final artistsFuture = _musicService.fetchTrendingArtists();
      final releasesFuture = _musicService.fetchNewReleases();
      final playlistsFuture = _musicService.fetchCuratedPlaylists();

      final results = await Future.wait([
        sectionsFuture,
        artistsFuture,
        releasesFuture,
        playlistsFuture,
      ]);

      final sections = results[0] as Map<String, List<MusicTrack>>;
      final artists = results[1] as List<MusicArtist>;
      final releases = results[2] as List<MusicAlbum>;
      final playlists = results[3] as List<MusicPlaylist>;

      MusicTrack? hero;
      if (sections.isNotEmpty && sections.values.first.isNotEmpty) {
        hero = sections.values.first.first;
      }

      if (mounted) {
        setState(() {
          _sections = sections;
          _trendingArtists = artists;
          _newReleases = releases;
          _curatedPlaylists = playlists;
          _heroTrack = hero;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading music data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchData = MusicSearchData.empty;
        _activeQuery = '';
        // An emptied field returns to the featured view rather than leaving
        // the search view selected behind an empty field.
        _view = MusicView.home;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() {
        _isSearching = true;
        _activeQuery = trimmed;
        _view = MusicView.search;
      });

      final results = await _musicService.searchFull(trimmed);

      if (mounted) {
        setState(() {
          _searchData = results;
          _isSearching = false;
        });
      }
    });
  }

  void _onGenreTap(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
  }

  Future<void> _openArtistModal(String artistId) async {
    _showToast(l10nCurrent().musLoadingArtistDetails);
    final details = await _musicService.fetchArtistDetails(artistId);
    if (details != null && mounted) {
      setState(() {
        _activeArtistModal = details;
      });
    }
  }

  Future<void> _openAlbumModal(String albumId) async {
    _showToast(l10nCurrent().musLoadingAlbum);
    final details = await _musicService.fetchAlbumDetails(albumId);
    if (details != null && mounted) {
      setState(() {
        _activeAlbumModal = details;
      });
    }
  }

  Future<void> _openCuratedPlaylistModal(String playlistId) async {
    _showToast(l10nCurrent().musLoadingPlaylist);
    final details = await _musicService.fetchPlaylistDetails(playlistId);
    if (details != null && mounted) {
      setState(() {
        _activeCuratedPlaylistModal = details;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_searchFocusNode.hasFocus) return;
    // A text field anywhere else on the page (the downloads search) types its
    // letters rather than firing shortcuts.
    // The primary focus is the [Focus] the field builds inside its
    // [EditableText], never the EditableText itself, so look upwards.
    if (FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>() !=
        null) {
      return;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyK) {
      _playerController.togglePlayPause();
    } else if (key == LogicalKeyboardKey.keyJ) {
      final newPos = _playerController.position - const Duration(seconds: 5);
      _playerController.seekTo(newPos.inSeconds < 0 ? Duration.zero : newPos);
      _showToast(l10nCurrent().musSeekBack5s);
    } else if (key == LogicalKeyboardKey.keyL) {
      final newPos = _playerController.position + const Duration(seconds: 5);
      _playerController.seekTo(newPos);
      _showToast(l10nCurrent().musSeekForward5s);
    } else if (key == LogicalKeyboardKey.keyM) {
      _playerController.setVolume(_playerController.volume > 0 ? 0.0 : 1.0);
      _showToast(
        _playerController.volume == 0
            ? l10nCurrent().musMuted
            : l10nCurrent().musUnmuted,
      );
    } else if (key == LogicalKeyboardKey.keyQ) {
      setState(() => _showQueueDrawer = !_showQueueDrawer);
    } else if (key == LogicalKeyboardKey.keyF) {
      // Without a track the expanded player is not drawn, and a flag set
      // anyway would hide the page behind an overlay that is not there.
      if (!_playerController.hasTrack) return;
      setState(() => _isPlayerExpanded = !_isPlayerExpanded);
    } else if (key == LogicalKeyboardKey.slash ||
        (HardwareKeyboard.instance.isShiftPressed &&
            key == LogicalKeyboardKey.slash)) {
      setState(() => _showShortcutsModal = !_showShortcutsModal);
    } else if (key == LogicalKeyboardKey.escape) {
      // Escape unwinds the topmost overlay and stops there - the same walk the
      // remote's Back takes through the shell claim. Leaving Music is the shell
      // rail's job, and a pop from inside a slot would take the shell route
      // with it.
      _closeTopLayer();
    }
  }

  void _showCreatePlaylistDialog({MusicTrack? initialTrack}) {
    final controller = TextEditingController();
    Future<void> create(BuildContext ctx) async {
      final name = controller.text.trim();
      if (name.isNotEmpty) {
        final pl = await _libraryService.createPlaylist(name);
        if (initialTrack != null) {
          await _libraryService.addTrackToPlaylist(pl.id, initialTrack);
          _showToast(
            l10nCurrent().mus2AddedTrackToPlaylist(initialTrack.title, name),
          );
        } else {
          _showToast(l10nCurrent().mus2CreatedPlaylist(name));
        }
      }
      if (ctx.mounted) Navigator.pop(ctx);
    }

    showLuMediaDialog<void>(
      context: context,
      title: l10nCurrent().musNewPlaylist,
      icon: Icons.playlist_add_rounded,
      body: (ctx, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (initialTrack != null) ...[
            _TrackIdentity(track: initialTrack, size: 48),
            const SizedBox(height: LuSpace.l),
          ],
          LuTextField(
            label: l10nCurrent().musNewPlaylist,
            hint: l10nCurrent().musEnterPlaylistTitle,
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => create(ctx),
          ),
        ],
      ),
      actions: (ctx) => [
        LuButton(
          label: l10nCurrent().musCancel,
          kind: LuButtonKind.secondary,
          compact: true,
          onPressed: () => Navigator.pop(ctx),
        ),
        LuButton(
          label: l10nCurrent().musCreate,
          icon: Icons.add_rounded,
          compact: true,
          onPressed: () => create(ctx),
        ),
      ],
    ).whenComplete(controller.dispose);
  }

  void _showAddToPlaylistMenu(MusicTrack track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final l10n = l10nOf(ctx);
        final playlists = _libraryService.userPlaylists;
        final isDownloaded = MusicDownloadService.instance.isDownloaded(
          track.id,
        );
        final isQueued = MusicDownloadService.instance.isQueued(track.id);
        return _LuSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _TrackIdentity(track: track, size: 56)),
                  LuMediaIconButton(
                    icon: Icons.close_rounded,
                    tooltip: l10n.actionClose,
                    quiet: true,
                    onTap: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: LuSpace.l),
              LuMediaTile(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                radius: LuRadius.field,
                selected: isDownloaded,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (isDownloaded) {
                    await MusicDownloadService.instance.deleteDownloadedTrack(
                      track.id,
                    );
                    _showToast(
                      l10nCurrent().mus2RemovedFromDownloads(track.title),
                    );
                  } else if (!isQueued) {
                    MusicDownloadService.instance.queueTrack(track);
                    _showToast(
                      l10nCurrent().mus2AddedToDownloadQueue(track.title),
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      isDownloaded
                          ? Icons.download_done_rounded
                          : (isQueued
                                ? Icons.hourglass_top_rounded
                                : Icons.download_rounded),
                      color: isDownloaded ? LuColors.gold : LuColors.text,
                      size: 22,
                    ),
                    const SizedBox(width: LuSpace.m),
                    Expanded(
                      child: Text(
                        isDownloaded
                            ? l10n.musDownloadedOfflineTapToRemove
                            : (isQueued
                                  ? l10n.musDownloadingQueued
                                  : l10n.musDownloadTrackOffline),
                        style: LuText.label.copyWith(color: LuColors.text),
                      ),
                    ),
                    if (isDownloaded)
                      const Icon(
                        Icons.delete_outline_rounded,
                        color: LuColors.danger,
                        size: 20,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: LuSpace.l),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.musSaveToPlaylist, style: LuText.heading),
                  ),
                  LuButton(
                    label: l10n.musNewPlaylist,
                    kind: LuButtonKind.secondary,
                    icon: Icons.add_rounded,
                    compact: true,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCreatePlaylistDialog(initialTrack: track);
                    },
                  ),
                ],
              ),
              const SizedBox(height: LuSpace.m),
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: LuSpace.l),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.playlist_add_rounded,
                        color: LuColors.textFaint,
                        size: 40,
                      ),
                      const SizedBox(height: LuSpace.s),
                      Text(
                        l10n.musNoCustomPlaylistsYet,
                        style: LuText.bodySoft,
                      ),
                      const SizedBox(height: LuSpace.m),
                      LuButton(
                        label: l10n.musCreateFirstPlaylist,
                        compact: true,
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCreatePlaylistDialog(initialTrack: track);
                        },
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final pl = playlists[index];
                      final inPlaylist = pl.tracks.any((t) => t.id == track.id);
                      return LuMediaRow(
                        onTap: () async {
                          if (inPlaylist) {
                            await _libraryService.removeTrackFromPlaylist(
                              pl.id,
                              track.id,
                            );
                            _showToast(
                              l10nCurrent().mus2RemovedFromPlaylist(pl.title),
                            );
                          } else {
                            await _libraryService.addTrackToPlaylist(
                              pl.id,
                              track,
                            );
                            _showToast(
                              l10nCurrent().mus2AddedToPlaylist(pl.title),
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Row(
                          children: [
                            const _IconSquare(
                              icon: Icons.queue_music_rounded,
                              size: 44,
                            ),
                            const SizedBox(width: LuSpace.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pl.title,
                                    style: LuText.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    l10n.mus2TracksCount(pl.tracks.length),
                                    style: LuText.caption,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              inPlaylist
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              color: inPlaylist
                                  ? LuColors.gold
                                  : LuColors.textMuted,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Top padding for a view's scroll list, so its content starts under the
  /// sticky chrome rather than behind it.
  double _contentTopPadding(BuildContext context) =>
      _musicHeaderHeight(context) + _musicViewBandHeight(context);

  /// The padding a view's scroll list carries: the sticky chrome above it and
  /// the page's closing gap, with the horizontal edge left to each block.
  EdgeInsets _viewListPadding(BuildContext context) => EdgeInsets.only(
    top: _contentTopPadding(context) + LuSpace.s,
    bottom: LuSpace.xxl,
  );

  /// The localized title of a home rail, from the id the service keys it by.
  String _railTitle(String id) {
    final l10n = l10nOf(context);
    switch (id) {
      case MusicService.railTrending:
        return l10n.musRailTrending;
      case MusicService.railPop:
        return l10n.musRailPop;
      case MusicService.railHipHop:
        return l10n.musRailHipHop;
      case MusicService.railElectronic:
        return l10n.musRailElectronic;
      case MusicService.railRock:
        return l10n.musRailRock;
      case MusicService.railSoundtracks:
        return l10n.musRailSoundtracks;
      case MusicService.railChill:
        return l10n.musRailChill;
      default:
        return id;
    }
  }

  Widget _gutter(Widget child) => Padding(
    padding: EdgeInsets.symmetric(horizontal: luMediaPad(context)),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final openLayers = _openLayers;
    _trackLayerFocus(openLayers);
    _syncBackClaim();
    // What is actually on screen, not the raw flags: a flag whose layer is
    // not drawn (no track loaded) must not lock the page out of focus.
    final anyOverlay = openLayers.isNotEmpty;
    final topLayer = openLayers.isEmpty ? null : openLayers.last;

    // Only the topmost layer takes the remote: an album opened from an
    // artist, or the queue drawn over the expanded player, would otherwise let
    // the D-pad wander into the layer underneath.
    Widget layer(_MusicLayer which, Widget child) =>
        ExcludeFocus(excluding: topLayer != which, child: child);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: LuColors.bg,
        body: Stack(
          children: [
            if (MusicSettings.enableAmbientLights.value)
              const Positioned.fill(child: LuMediaGlow()),

            // The page under its sticky chrome. While an overlay is up the page
            // behind it is out of the remote's reach, so the D-pad cannot wander
            // off the modal into rails nobody can see.
            Positioned.fill(
              child: ExcludeFocus(
                excluding: anyOverlay,
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildTabContent()),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _MusicChrome(
                        scrollController: _scrollController,
                        searchController: _searchController,
                        searchFocusNode: _searchFocusNode,
                        isSearching: _isSearching,
                        onSearchChanged: _onSearchChanged,
                        onClearSearch: _clearSearch,
                        onSettingsTap: () {
                          // Settings is a shell slot, so this switches the
                          // shell instead of pushing a second copy over it.
                          AppShellScope.of(context)?.go(ShellSlot.settings);
                        },
                        view: _view,
                        onSelected: _selectView,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_activeArtistModal != null)
              Positioned.fill(
                child: layer(
                  _MusicLayer.artist,
                  _MusicArtistDetailModal(
                    details: _activeArtistModal!,
                    onClose: () => setState(() => _activeArtistModal = null),
                    onPlayTrack: (t, queue) =>
                        _playerController.playTrack(t, playlistQueue: queue),
                    onAddToPlaylist: _showAddToPlaylistMenu,
                    onOpenAlbum: _openAlbumModal,
                  ),
                ),
              ),

            if (_activeAlbumModal != null)
              Positioned.fill(
                child: layer(
                  _MusicLayer.album,
                  _MusicAlbumDetailModal(
                    details: _activeAlbumModal!,
                    onClose: () => setState(() => _activeAlbumModal = null),
                    onPlayTrack: (t, queue) =>
                        _playerController.playTrack(t, playlistQueue: queue),
                    onAddToPlaylist: _showAddToPlaylistMenu,
                  ),
                ),
              ),

            if (_activeCuratedPlaylistModal != null)
              Positioned.fill(
                child: layer(
                  _MusicLayer.curatedPlaylist,
                  _MusicCuratedPlaylistDetailModal(
                    details: _activeCuratedPlaylistModal!,
                    onClose: () =>
                        setState(() => _activeCuratedPlaylistModal = null),
                    onPlayTrack: (t, queue) =>
                        _playerController.playTrack(t, playlistQueue: queue),
                    onAddToPlaylist: _showAddToPlaylistMenu,
                  ),
                ),
              ),

            if (_activeUserPlaylistModal != null)
              Positioned.fill(
                child: layer(
                  _MusicLayer.userPlaylist,
                  _MusicUserPlaylistDetailModal(
                    playlist: _activeUserPlaylistModal!,
                    onClose: () =>
                        setState(() => _activeUserPlaylistModal = null),
                    onPlayTrack: (t, queue) =>
                        _playerController.playTrack(t, playlistQueue: queue),
                    onRemoveTrack: (trackId) async {
                      final playlistId = _activeUserPlaylistModal?.id;
                      if (playlistId == null) return;
                      await _libraryService.removeTrackFromPlaylist(
                        playlistId,
                        trackId,
                      );
                      // The modal may have been closed (or another playlist
                      // opened) while the removal was in flight.
                      final current = _activeUserPlaylistModal;
                      if (!mounted ||
                          current == null ||
                          current.id != playlistId) {
                        return;
                      }
                      setState(() {
                        _activeUserPlaylistModal = _libraryService.userPlaylists
                            .firstWhere(
                              (p) => p.id == playlistId,
                              orElse: () => current,
                            );
                      });
                    },
                  ),
                ),
              ),

            if (_showShortcutsModal)
              Positioned.fill(
                child: layer(
                  _MusicLayer.shortcuts,
                  _MusicShortcutsModal(
                    onClose: () => setState(() => _showShortcutsModal = false),
                  ),
                ),
              ),

            if (_showDownloadsModal)
              Positioned.fill(
                child: layer(
                  _MusicLayer.downloads,
                  _MusicDownloadedTracksModal(
                    onClose: () => setState(() => _showDownloadsModal = false),
                    onPlayTrack: (t, queue) =>
                        _playerController.playTrack(t, playlistQueue: queue),
                    onAddToPlaylist: _showAddToPlaylistMenu,
                  ),
                ),
              ),

            if (_isPlayerExpanded && _playerController.hasTrack)
              Positioned.fill(
                child: layer(
                  _MusicLayer.player,
                  _MusicExpandedPlayer(
                    playerController: _playerController,
                    isSaved: _libraryService.isTrackLiked(
                      _playerController.currentTrack?.id ?? '',
                    ),
                    onToggleSave: () {
                      if (_playerController.currentTrack != null) {
                        _libraryService.toggleLikeTrack(
                          _playerController.currentTrack!,
                        );
                      }
                    },
                    onCollapse: () => setState(() => _isPlayerExpanded = false),
                    onQueueTap: () => setState(() => _showQueueDrawer = true),
                    onLyricsTap: () => setState(() => _showLyricsDrawer = true),
                    onAddToPlaylist: () {
                      if (_playerController.currentTrack != null) {
                        _showAddToPlaylistMenu(_playerController.currentTrack!);
                      }
                    },
                  ),
                ),
              ),

            if (_showQueueDrawer)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: layer(
                  _MusicLayer.queue,
                  _MusicQueueDrawer(
                    onClose: () => setState(() => _showQueueDrawer = false),
                  ),
                ),
              ),

            if (_showLyricsDrawer && _playerController.hasTrack)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: layer(
                  _MusicLayer.lyrics,
                  _MusicLyricsDrawer(
                    track: _playerController.currentTrack!,
                    playerController: _playerController,
                    onClose: () => setState(() => _showLyricsDrawer = false),
                  ),
                ),
              ),

            if (_toastMessage != null)
              Positioned(
                top: _contentTopPadding(context),
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: LuColors.surfaceHigh,
                        borderRadius: LuRadius.pill,
                        border: Border.all(color: const Color(0x66F2B544)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.music_note_rounded,
                            color: LuColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _toastMessage!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              semanticsLabel: _toastMessage,
                              style: LuText.label.copyWith(
                                color: LuColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Switches view from the header's band.
  ///
  /// The pending debounce is dropped rather than left to fire: it selects
  /// Search, so a query typed a moment before the tap would drag the user back
  /// out of the view they just asked for.
  void _selectView(MusicView view) {
    _debounceTimer?.cancel();
    if (_view == view) return;
    setState(() => _view = view);
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return switch (_view) {
      MusicView.home => _buildHomeView(),
      MusicView.search => _buildSearchView(),
      MusicView.browse => _buildBrowseView(),
      MusicView.radio => _buildRadioView(),
      MusicView.library => _buildLibraryView(),
    };
  }

  /// The cover width for rails and grids at this window.
  double _coverWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 132;
    if (luMediaIsTv(context)) return 168;
    return width < 1100 ? 160 : 180;
  }

  double _railHeight(BuildContext context, double coverWidth) =>
      LuMediaCover.heightFor(coverWidth, MediaQuery.textScalerOf(context)) + 12;

  Widget _rail({
    required String title,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    double? height,
  }) {
    final w = _coverWidth(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: LuSpace.xl),
      child: LuRail(
        title: title,
        padding: luMediaPad(context),
        spacing: 18,
        height: height ?? _railHeight(context, w),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }

  Widget _buildHomeView() {
    final l10n = l10nOf(context);
    final w = _coverWidth(context);
    final artistW = w * 0.82;

    return RefreshIndicator(
      color: LuColors.gold,
      backgroundColor: LuColors.surfaceHigh,
      onRefresh: _loadMusicData,
      child: ListView(
        controller: _scrollController,
        padding: _viewListPadding(context),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          if (MusicSettings.enableSpotlight.value && _heroTrack != null) ...[
            _MusicHeroBillboard(
              track: _heroTrack!,
              onPlayTap: () => _playerController.playTrack(
                _heroTrack!,
                playlistQueue: _sections.values.isNotEmpty
                    ? _sections.values.first
                    : null,
              ),
              onSaveTap: () {
                _libraryService.toggleLikeTrack(_heroTrack!);
                _showToast(
                  _libraryService.isTrackLiked(_heroTrack!.id)
                      ? l10nCurrent().musSavedToLibrary
                      : l10nCurrent().musRemovedFromLibrary,
                );
              },
              onAddToPlaylistTap: () => _showAddToPlaylistMenu(_heroTrack!),
              isSaved: _libraryService.isTrackLiked(_heroTrack!.id),
            ),
            const SizedBox(height: LuSpace.xl),
          ],
          if (_trendingArtists.isNotEmpty)
            _rail(
              title: l10n.musTrendingArtists,
              height: _railHeight(context, artistW),
              itemCount: _trendingArtists.length,
              itemBuilder: (context, index) {
                final artist = _trendingArtists[index];
                return LuMediaCover(
                  width: artistW,
                  circle: true,
                  icon: Icons.person_rounded,
                  title: artist.name,
                  imageUrl: artist.pictureUrl,
                  onTap: () {
                    if (artist.id.isNotEmpty) {
                      _openArtistModal(artist.id);
                    } else {
                      _onGenreTap(artist.name);
                    }
                  },
                );
              },
            ),
          if (_newReleases.isNotEmpty)
            _rail(
              title: l10n.musNewAlbumReleases,
              itemCount: _newReleases.length,
              itemBuilder: (context, index) {
                final album = _newReleases[index];
                return LuMediaCover(
                  width: w,
                  title: album.title,
                  subtitle: album.artistName,
                  imageUrl: album.coverUrl,
                  icon: Icons.album_rounded,
                  onTap: () => _openAlbumModal(album.id),
                );
              },
            ),
          if (_curatedPlaylists.isNotEmpty)
            _rail(
              title: l10n.musCuratedChartsMixes,
              itemCount: _curatedPlaylists.length,
              itemBuilder: (context, index) {
                final pl = _curatedPlaylists[index];
                return LuMediaCover(
                  width: w,
                  title: pl.title,
                  subtitle: l10n.mus2TracksCount(pl.trackCount),
                  imageUrl: pl.coverUrl,
                  icon: Icons.queue_music_rounded,
                  onTap: () => _openCuratedPlaylistModal(pl.id),
                );
              },
            ),
          for (final entry in _sections.entries)
            _rail(
              title: _railTitle(entry.key),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final track = entry.value[index];
                return LuMediaCover(
                  width: w,
                  title: track.title,
                  subtitle: track.artist,
                  imageUrl: track.coverUrl,
                  showPlay: true,
                  onTap: () => _playerController.playTrack(
                    track,
                    playlistQueue: entry.value,
                  ),
                  onLongPress: () => _showAddToPlaylistMenu(track),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Covers laid out as a grid that wraps to the window.
  Widget _coverWrap(List<Widget> covers) =>
      _gutter(Wrap(spacing: 18, runSpacing: 24, children: covers));

  Widget _buildSearchView() {
    final l10n = l10nOf(context);
    final w = _coverWidth(context);
    final pad = luMediaPad(context);

    return ListView(
      controller: _scrollController,
      padding: _viewListPadding(context),
      children: [
        LuPillTabs<String>(
          padding: EdgeInsets.symmetric(horizontal: pad),
          options: [
            LuPillOption<String>(value: 'All', label: l10n.filterAll),
            LuPillOption<String>(
              value: 'Tracks',
              label: l10n.mus2TracksTabCount(_searchData.tracks.length),
            ),
            LuPillOption<String>(
              value: 'Artists',
              label: l10n.mus2ArtistsTabCount(_searchData.artists.length),
            ),
            LuPillOption<String>(
              value: 'Albums',
              label: l10n.mus2AlbumsTabCount(_searchData.albums.length),
            ),
            LuPillOption<String>(
              value: 'Playlists',
              label: l10n.mus2PlaylistsTabCount(_searchData.playlists.length),
            ),
          ],
          selected: _selectedFilter,
          onSelected: (value) => setState(() => _selectedFilter = value),
          semanticsLabel: l10n.musSearchResults,
          compact: true,
        ),
        const SizedBox(height: LuSpace.l),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: LuSpace.xxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_searchData.tracks.isEmpty &&
            _searchData.artists.isEmpty &&
            _searchData.albums.isEmpty &&
            _searchData.playlists.isEmpty)
          _gutter(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LuSpace.xxl),
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    color: LuColors.textFaint,
                    size: 48,
                  ),
                  const SizedBox(height: LuSpace.m),
                  Text(
                    _activeQuery.isEmpty
                        ? l10n.musSearchToFindTracksArtistsAlbums
                        : l10n.mus2NoResultsFor(_activeQuery),
                    textAlign: TextAlign.center,
                    style: LuText.bodySoft,
                  ),
                ],
              ),
            ),
          )
        else ...[
          if ((_selectedFilter == 'All' || _selectedFilter == 'Tracks') &&
              _searchData.tracks.isNotEmpty) ...[
            LuMediaSectionTitle(
              title: l10n.musSongs,
              count: _searchData.tracks.length.clamp(0, 15),
            ),
            const SizedBox(height: LuSpace.m),
            _gutter(
              Column(
                children: [
                  for (
                    var index = 0;
                    index < _searchData.tracks.length.clamp(0, 15);
                    index++
                  )
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _trackRow(
                        _searchData.tracks[index],
                        _searchData.tracks,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: LuSpace.xl),
          ],
          if ((_selectedFilter == 'All' || _selectedFilter == 'Artists') &&
              _searchData.artists.isNotEmpty)
            _rail(
              title: l10n.musArtistsHeading,
              height: _railHeight(context, w * 0.82),
              itemCount: _searchData.artists.length,
              itemBuilder: (context, index) {
                final artist = _searchData.artists[index];
                return LuMediaCover(
                  width: w * 0.82,
                  circle: true,
                  icon: Icons.person_rounded,
                  title: artist.name,
                  imageUrl: artist.pictureUrl,
                  onTap: () => _openArtistModal(artist.id),
                );
              },
            ),
          if ((_selectedFilter == 'All' || _selectedFilter == 'Albums') &&
              _searchData.albums.isNotEmpty) ...[
            LuMediaSectionTitle(
              title: l10n.musAlbumsHeading,
              count: _searchData.albums.length.clamp(0, 12),
            ),
            const SizedBox(height: LuSpace.m),
            _coverWrap([
              for (final album in _searchData.albums.take(12))
                LuMediaCover(
                  width: w,
                  title: album.title,
                  subtitle: album.artistName,
                  imageUrl: album.coverUrl,
                  icon: Icons.album_rounded,
                  onTap: () => _openAlbumModal(album.id),
                ),
            ]),
            const SizedBox(height: LuSpace.xl),
          ],
          if ((_selectedFilter == 'All' || _selectedFilter == 'Playlists') &&
              _searchData.playlists.isNotEmpty) ...[
            LuMediaSectionTitle(
              title: l10n.musPlaylistsHeading,
              count: _searchData.playlists.length.clamp(0, 12),
            ),
            const SizedBox(height: LuSpace.m),
            _coverWrap([
              for (final pl in _searchData.playlists.take(12))
                LuMediaCover(
                  width: w,
                  title: pl.title,
                  subtitle: l10n.mus2TracksCount(pl.trackCount),
                  imageUrl: pl.coverUrl,
                  icon: Icons.queue_music_rounded,
                  onTap: () => _openCuratedPlaylistModal(pl.id),
                ),
            ]),
          ],
        ],
      ],
    );
  }

  Widget _trackRow(MusicTrack track, List<MusicTrack> queue) {
    return _MusicTrackRow(
      track: track,
      isPlaying:
          _playerController.currentTrack?.id == track.id &&
          _playerController.isPlaying,
      isCurrent: _playerController.currentTrack?.id == track.id,
      onTap: () => _playerController.playTrack(track, playlistQueue: queue),
      onMoreTap: () => _showAddToPlaylistMenu(track),
    );
  }

  /// A grid of genre or station tiles: two across on a phone, as many as fit
  /// elsewhere.
  Widget _tileGrid(List<Widget> Function(double width) tiles) {
    return _gutter(
      LayoutBuilder(
        builder: (context, constraints) {
          final max = constraints.maxWidth;
          final across = max < 600 ? 2 : (max / 240).floor().clamp(3, 6);
          final width = (max - 16 * (across - 1)) / across;
          return Wrap(spacing: 16, runSpacing: 16, children: tiles(width));
        },
      ),
    );
  }

  Widget _buildBrowseView() {
    final l10n = l10nOf(context);
    final genres = [
      (l10n.musGenrePopHits, 'Pop Hits', Icons.auto_awesome_rounded),
      (l10n.musHipHopRap, 'Hip-Hop', Icons.mic_external_on_rounded),
      (l10n.musElectronicEdm, 'EDM Dance', Icons.graphic_eq_rounded),
      (l10n.musChillLofiBeats, 'Chill Lofi', Icons.nightlight_round),
      (l10n.musGenreRockClassics, 'Rock Classics', Icons.electric_bolt_rounded),
      (l10n.musRBSoul, 'R&B Soul', Icons.favorite_rounded),
      (l10n.musSoundtracksGaming, 'Soundtracks', Icons.movie_filter_rounded),
      (l10n.musGenreHeavyMetal, 'Heavy Metal', Icons.whatshot_rounded),
      (l10n.musJazzBlues, 'Jazz Blues', Icons.nightlife_rounded),
      (l10n.musGenreClassicalPiano, 'Classical Piano', Icons.piano_rounded),
    ];

    return ListView(
      controller: _scrollController,
      padding: _viewListPadding(context),
      children: [
        LuMediaSectionTitle(
          title: l10n.musBrowseMoodsGenres,
          count: genres.length,
        ),
        const SizedBox(height: LuSpace.m),
        _tileGrid(
          (width) => [
            for (final (title, query, icon) in genres)
              SizedBox(
                width: width,
                height: 112,
                child: _GenreTile(
                  title: title,
                  icon: icon,
                  onTap: () => _onGenreTap(query),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioView() {
    final l10n = l10nOf(context);
    final radioGenres = [
      (l10n.musPopRadio, 'Pop Radio Hits'),
      (l10n.musRapHipHop, 'Hip Hop Radio'),
      (l10n.musRockMix, 'Rock Radio'),
      (l10n.musDanceElectro, 'Electro Radio'),
      (l10n.musRBStation, 'R&B Radio'),
      (l10n.musLofiAmbient, 'Lofi Radio'),
      (l10n.musHeavyMetalStation, 'Metal Radio'),
      (l10n.musJazzClub, 'Jazz Radio'),
    ];

    return ListView(
      controller: _scrollController,
      padding: _viewListPadding(context),
      children: [
        LuMediaSectionTitle(
          title: l10n.mus2RadioStationsLiveStreams,
          subtitle: l10n.mus2ContinuousMusicChannels,
        ),
        const SizedBox(height: LuSpace.m),
        _tileGrid(
          (width) => [
            for (final (name, query) in radioGenres)
              SizedBox(
                width: width,
                height: 112,
                child: _GenreTile(
                  title: name,
                  icon: Icons.radio_rounded,
                  onTap: () => _onGenreTap(query),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLibraryView() {
    final l10n = l10nOf(context);
    final liked = _libraryService.likedTracks;
    final playlists = _libraryService.userPlaylists;
    final recent = _libraryService.recentTracks;
    final w = _coverWidth(context);
    final phone = MediaQuery.sizeOf(context).width < 700;

    final downloaded = MusicDownloadService.instance.downloadedTracks;
    final queue = MusicDownloadService.instance.queue;
    final totalBytes = MusicDownloadService.instance.totalDownloadedSizeBytes;
    final sizeMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

    final likedBanner = _LibraryBanner(
      icon: Icons.favorite_rounded,
      title: l10n.musLikedSongs,
      subtitle: l10n.mus2FavouriteTracksCount(liked.length),
      actionIcon: liked.isNotEmpty ? Icons.play_arrow_rounded : null,
      onTap: () {
        if (liked.isNotEmpty) {
          _playerController.playTrack(liked.first, playlistQueue: liked);
        } else {
          _showToast(l10nCurrent().musNoLikedSongsYet);
        }
      },
    );
    final downloadsBanner = _LibraryBanner(
      icon: Icons.download_done_rounded,
      title: l10n.musDownloadedSongs,
      trailingNote: queue.isNotEmpty ? l10n.mus2QueueCount(queue.length) : null,
      subtitle: l10n.mus2OfflineTracksSize(downloaded.length, sizeMb),
      actionIcon: Icons.arrow_forward_rounded,
      onTap: () => setState(() => _showDownloadsModal = true),
    );

    return ListView(
      controller: _scrollController,
      padding: _viewListPadding(context),
      children: [
        LuMediaSectionTitle(
          title: l10n.musYourLibrary,
          trailing: LuButton(
            label: l10n.musNewPlaylist,
            icon: Icons.add_rounded,
            compact: true,
            onPressed: () => _showCreatePlaylistDialog(),
          ),
        ),
        const SizedBox(height: LuSpace.l),
        _gutter(
          phone
              ? Column(
                  children: [
                    likedBanner,
                    const SizedBox(height: LuSpace.m),
                    downloadsBanner,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: likedBanner),
                    const SizedBox(width: LuSpace.l),
                    Expanded(child: downloadsBanner),
                  ],
                ),
        ),
        const SizedBox(height: LuSpace.xl),

        if (playlists.isNotEmpty) ...[
          LuMediaSectionTitle(
            title: l10n.musCustomPlaylists,
            count: playlists.length,
          ),
          const SizedBox(height: LuSpace.m),
          _coverWrap([
            for (final pl in playlists)
              LuMediaCover(
                width: w,
                title: pl.title,
                subtitle: l10n.mus2TracksCount(pl.tracks.length),
                imageUrl: pl.tracks.isNotEmpty
                    ? pl.tracks.first.coverUrl
                    : null,
                icon: Icons.queue_music_rounded,
                onTap: () => setState(() => _activeUserPlaylistModal = pl),
              ),
          ]),
          const SizedBox(height: LuSpace.xl),
        ],

        if (recent.isNotEmpty) ...[
          LuMediaSectionTitle(
            title: l10n.musRecentlyPlayed,
            count: recent.length.clamp(0, 10),
          ),
          const SizedBox(height: LuSpace.m),
          _gutter(
            Column(
              children: [
                for (final track in recent.take(10))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _trackRow(track, recent),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
