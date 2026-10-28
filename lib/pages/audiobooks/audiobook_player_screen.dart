import '../../l10n/l10n.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../../models/audiobook/audiobook_model.dart';
import '../../services/theme/design_tokens.dart';
import '../../services/audiobook/audiobook_progress_service.dart';
import '../../services/audiobook/audiobook_settings.dart';
import '../../services/debrid/debrid_service.dart';
import '../../services/stream/torrent_stream_service.dart';
import '../../services/discord/discord_rpc_service.dart';
import '../../services/player/player_settings.dart';
import '../../services/playback/now_playing_service.dart';
import '../../widgets/audiobook/audiobook_interactive_physics_button.dart';
import '../../widgets/audiobook/audiobook_waveform_seekbar.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';
import '../music/lu_media_kit.dart';
import 'audiobook_lu_labels.dart';
import '../settings/appearance/audiobook_player_studio_page.dart';
import '../account/login_page.dart' show SignInRequired;

/// Playing an audiobook needs an account; [SignInRequired] shows the sign-in
/// page in its place until there is one.
class AudiobookPlayerScreen extends StatelessWidget {
  final Audiobook audiobook;
  final List<AudiobookChapter> chapters;
  final int initialChapterIndex;
  final Duration? initialPosition;

  const AudiobookPlayerScreen({
    super.key,
    required this.audiobook,
    required this.chapters,
    this.initialChapterIndex = 0,
    this.initialPosition,
  });

  @override
  Widget build(BuildContext context) => SignInRequired(
    child: Theme(
      data: luMediaTheme(),
      child: _AudiobookPlayerBody(
        audiobook: audiobook,
        chapters: chapters,
        initialChapterIndex: initialChapterIndex,
        initialPosition: initialPosition,
      ),
    ),
  );
}

class _AudiobookPlayerBody extends StatefulWidget {
  final Audiobook audiobook;
  final List<AudiobookChapter> chapters;
  final int initialChapterIndex;
  final Duration? initialPosition;

  const _AudiobookPlayerBody({
    required this.audiobook,
    required this.chapters,
    required this.initialChapterIndex,
    required this.initialPosition,
  });

  @override
  State<_AudiobookPlayerBody> createState() => _AudiobookPlayerScreenState();
}

/// Audiobook playback lives here rather than in a controller, so the shell's bar
/// is fed from this screen while it is mounted and falls silent when it is
/// disposed.
///
/// Lifting playback into a controller is a deliberate follow up rather than an
/// oversight: it would be a product change, not a refactor, because playback
/// would then survive the route. Until then this screen is the audiobook owner
/// and registers itself as such.
class _AudiobookPlayerScreenState extends State<_AudiobookPlayerBody>
    with SingleTickerProviderStateMixin
    implements NowPlayingCommands {
  Player? _player;
  final List<StreamSubscription> _playerSubscriptions = [];

  /// Bumped by every [_initChapter], so a load that a newer chapter change (or
  /// the screen closing) overtook while it awaited can tell it is stale and
  /// dispose the player it made instead of leaking it.
  int _loadToken = 0;
  late int _currentChapterIndex;

  bool _isLoading = true;
  bool _isPlaying = false;
  bool _autoplayNext = true;
  String _statusMessage = l10nCurrent().abkInitializingChapter;
  String? _errorMessage;

  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  final List<double> _speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5];

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _showChaptersDrawer = false;
  String _chapterSearchQuery = '';
  late AnimationController _discAnimController;
  Timer? _progressTimer;
  bool _hasRestoredPosition = false;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    AudiobookSettings.changeNotifier.addListener(_onSettingsChanged);

    NowPlayingService.register(this);
    _publishNowPlaying();

    _initChapter(_currentChapterIndex);

    // Save progress periodically; pause, seek, and dispose also flush it.
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveProgress();
    });
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  AudiobookChapter? get _currentChapter =>
      (widget.chapters.isNotEmpty &&
          _currentChapterIndex < widget.chapters.length)
      ? widget.chapters[_currentChapterIndex]
      : null;

  /// Publishes this screen's frame to the shell's bar.
  ///
  /// Called from the few places that move a published field rather than from
  /// `build`: a position tick rebuilds far more often than the bar needs to hear
  /// about, and every publish allocates a snapshot.
  void _publishNowPlaying() {
    final chapter = _currentChapter;
    final author = widget.audiobook.author?.trim() ?? '';
    final chapterTitle = chapter == null ? '' : chapter.title.trim();
    final cover = widget.audiobook.coverImage.trim();

    // The bar gives the subtitle one line, so it reads "author · chapter". Either
    // half can be missing on a sideloaded file, and a stranded separator reads
    // worse than the half that is there.
    final subtitle = author.isEmpty
        ? chapterTitle
        : (chapterTitle.isEmpty ? author : '$author · $chapterTitle');

    NowPlayingService.publish(
      NowPlayingSnapshot(
        kind: NowPlayingKind.audiobook,
        title: widget.audiobook.title,
        subtitle: subtitle,
        artworkUrl: cover.isEmpty ? null : cover,
        isPlaying: _isPlaying,
        position: _position,
        duration: _duration,
        // Chapters are this player's queue, so the transport walks them. The bar
        // greys a button instead of hiding it, which keeps the four controls in
        // place for a book that is one long chapter.
        canPrevious: _currentChapterIndex > 0,
        canNext: _currentChapterIndex < widget.chapters.length - 1,
      ),
    );
  }

  /// Nothing to expand into: this screen is already the full size surface, and it
  /// only owns the bar for as long as it is mounted on top of the shell.
  @override
  void openFullPlayer(BuildContext context) {}

  @override
  Future<void> togglePlayPause() async {
    _togglePlayPause();
  }

  @override
  Future<void> next() async {
    if (_currentChapterIndex >= widget.chapters.length - 1) return;
    await _initChapter(_currentChapterIndex + 1);
  }

  @override
  Future<void> previous() async {
    // The first chapter has nowhere to go back to, so the button restarts it,
    // which is what a listener reaching for it at the start of a book expects.
    if (_currentChapterIndex == 0) {
      await seek(Duration.zero);
      return;
    }
    await _initChapter(_currentChapterIndex - 1);
  }

  @override
  Future<void> seek(Duration position) async {
    await _player?.seek(position);
    if (!mounted) return;
    setState(() => _position = position);
    _saveProgress();
  }

  /// Stops the book and removes the bar, by leaving this screen.
  ///
  /// This surface *is* the full size player, so there is no smaller state to
  /// fall back to: stopping here means going away, which is exactly what
  /// [dispose] already does. The bar had no way to be dismissed once a book was
  /// playing, so the close button routes through here rather than trying to
  /// leave a book half-owned behind the bar.
  @override
  Future<void> stop() async {
    _saveProgress();
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _updateDiscordRpc({bool? isPaused}) {
    final chapter = _currentChapter;
    DiscordRpcService.instance.setListeningAudiobook(
      title: widget.audiobook.title,
      author: widget.audiobook.author,
      chapter: chapter?.title,
      coverUrl: widget.audiobook.coverImage,
      position: _position,
      duration: _duration,
      isPaused: isPaused ?? !_isPlaying,
    );
  }

  @override
  void dispose() {
    // The music bridge is the owner underneath once this screen goes away, so
    // give the commands back and clear the frame instead of leaving the bar on a
    // snapshot that no owner will ever update again.
    NowPlayingService.unregister(this);
    NowPlayingService.publish(null);
    _saveProgress();
    _progressTimer?.cancel();
    AudiobookSettings.changeNotifier.removeListener(_onSettingsChanged);
    for (final s in _playerSubscriptions) {
      s.cancel();
    }
    _playerSubscriptions.clear();
    _player?.dispose();
    _discAnimController.dispose();
    TorrentStreamService().cleanup();
    DiscordRpcService.instance.clearToIdle();
    super.dispose();
  }

  void _saveProgress() {
    if (_player != null && _duration > Duration.zero) {
      AudiobookProgressService.instance.saveProgress(
        audiobook: widget.audiobook,
        chapters: widget.chapters,
        chapterIndex: _currentChapterIndex,
        position: _position,
        duration: _duration,
      );
    }
  }

  Future<void> _initChapter(int index) async {
    if (index < 0 || index >= widget.chapters.length) return;
    final token = ++_loadToken;
    bool stale() => !mounted || token != _loadToken;

    _saveProgress();

    for (final s in _playerSubscriptions) {
      s.cancel();
    }
    _playerSubscriptions.clear();

    final previousPlayer = _player;
    _player = null;
    if (previousPlayer != null) {
      await previousPlayer.dispose();
    }
    if (stale()) return;

    setState(() {
      _currentChapterIndex = index;
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = l10nCurrent().abk2PreparingChapter(
        widget.chapters[index].title,
      );
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    _publishNowPlaying();

    final chapter = widget.chapters[index];
    String? streamUrl;
    Player? player;
    final subscriptions = <StreamSubscription>[];

    /// Drops what this load built once a newer one has taken over.
    Future<void> discard() async {
      for (final s in subscriptions) {
        s.cancel();
        _playerSubscriptions.remove(s);
      }
      subscriptions.clear();
      final built = player;
      player = null;
      await built?.dispose();
    }

    try {
      if (chapter.isTorrent) {
        final useDebrid = await DebridService().isDebridActiveForStreams();
        if (useDebrid) {
          final activeService = await DebridService().getSelectedService();
          if (stale()) return;
          setState(
            () => _statusMessage = l10nCurrent().abk2ResolvingAudioVia(
              activeService,
            ),
          );

          final debridFiles = await DebridService().resolveMagnet(
            magnet: chapter.url,
            fileIndex: chapter.torrentFileIndex,
            filename: chapter.title,
          );

          if (stale()) return;
          if (debridFiles.isEmpty || debridFiles.first.downloadUrl.isEmpty) {
            throw _ChapterResolveException(
              l10nCurrent().abkDebridCouldNotResolveAudio(activeService),
            );
          }

          streamUrl = debridFiles.first.downloadUrl;
        } else {
          if (stale()) return;
          setState(
            () =>
                _statusMessage = l10nCurrent().abkFetchingTorrentMetadataPeers,
          );
          streamUrl = await TorrentStreamService().streamTorrent(
            chapter.url,
            fileIdx: chapter.torrentFileIndex,
          );
          if (stale()) return;
        }
      } else {
        streamUrl = chapter.url;
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        throw _ChapterResolveException(
          l10nCurrent().abkAudioStreamUrlUnresolved,
        );
      }

      final isLocal =
          !streamUrl.startsWith('http://') && !streamUrl.startsWith('https://');
      final created = Player();
      player = created;

      final Media media;
      if (isLocal) {
        media = Media(File(streamUrl).uri.toString());
      } else {
        final sanitizedUrlStr = streamUrl.contains('::')
            ? streamUrl.replaceAll('::', '%3A%3A')
            : streamUrl;
        final cleanUri = Uri.parse(sanitizedUrlStr);

        final headers = <String, String>{
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        };
        if (chapter.httpHeaders != null) {
          headers.addAll(chapter.httpHeaders!);
        }

        media = Media(cleanUri.toString(), httpHeaders: headers);
      }

      subscriptions.addAll([
        created.stream.playing.listen((playing) {
          if (mounted) {
            setState(() => _isPlaying = playing);
            _updateDiscordRpc(isPaused: !playing);
            _publishNowPlaying();
            if (playing && !_discAnimController.isAnimating) {
              _discAnimController.repeat();
            } else if (!playing && _discAnimController.isAnimating) {
              _discAnimController.stop();
            }
          }
        }),
        created.stream.position.listen((pos) {
          if (mounted) {
            setState(() => _position = pos);
            _publishNowPlaying();
          }
        }),
        created.stream.duration.listen((dur) {
          if (mounted && dur > Duration.zero) {
            setState(() {
              _duration = dur;
              _isLoading = false;
            });
            _updateDiscordRpc();
            _publishNowPlaying();
          }
        }),
        created.stream.completed.listen((completed) {
          if (completed && mounted) {
            if (_autoplayNext &&
                _currentChapterIndex < widget.chapters.length - 1) {
              _initChapter(_currentChapterIndex + 1);
            }
          }
        }),
        created.stream.error.listen((err) {
          if (PlayerSettings.isNonFatalError(err)) {
            debugPrint('[AudiobookPlayer] Ignored non-fatal error: $err');
            return;
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = l10nCurrent().abk2PlaybackErrorErr(err);
            });
          }
        }),
      ]);
      _playerSubscriptions.addAll(subscriptions);

      await created.open(media);
      if (stale()) {
        await discard();
        return;
      }
      await created.setVolume(_volume * 100.0);
      await created.setRate(_playbackSpeed);

      // Auto-seek if resuming initial position
      if (!_hasRestoredPosition &&
          index == widget.initialChapterIndex &&
          widget.initialPosition != null &&
          widget.initialPosition! > Duration.zero) {
        await created.seek(widget.initialPosition!);
        _hasRestoredPosition = true;
      }

      if (stale()) {
        await discard();
        return;
      }

      setState(() {
        _player = created;
        _isLoading = false;
        _isPlaying = true;
      });
      _publishNowPlaying();

      _discAnimController.repeat();
    } catch (e) {
      // The player this load made never became the screen's, so it goes
      // whether or not a newer load has taken over.
      await discard();
      if (stale()) return;
      setState(() {
        _isLoading = false;
        _errorMessage = l10nCurrent().abk2PlaybackError(e);
      });
    }
  }

  void _togglePlayPause() {
    if (_player == null) return;

    if (_isPlaying) {
      _player!.pause();
      _discAnimController.stop();
      setState(() => _isPlaying = false);
      _saveProgress();
    } else {
      _player!.play();
      _discAnimController.repeat();
      setState(() => _isPlaying = true);
    }
    // Paused playback produces no position ticks, so the bar would otherwise keep
    // the play state from before the tap.
    _publishNowPlaying();
  }

  void _seekRelative(int seconds) {
    if (_player == null) return;
    final target = _position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _duration ? _duration : target);
    _player!.seek(clamped);
    if (mounted) setState(() => _position = clamped);
    _saveProgress();
  }

  void _cycleSpeed() {
    final nextIdx = (_speeds.indexOf(_playbackSpeed) + 1) % _speeds.length;
    final newSpeed = _speeds[nextIdx];
    setState(() => _playbackSpeed = newSpeed);
    _player?.setRate(newSpeed);
  }

  void _showPlayerCustomizer(BuildContext context) {
    showLuMediaDialog<void>(
      context: context,
      title: l10nCurrent().abk2AudioPlayerStyleStudio,
      icon: Icons.tune_rounded,
      maxWidth: 520,
      body: (ctx, _) {
        final l10n = l10nOf(ctx);
        Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(bottom: LuSpace.s),
          child: Text(text, style: LuText.label),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading(l10n.abk2SelectPlayerDesignPreset),
            ValueListenableBuilder<AudiobookPlayerPreset>(
              valueListenable: AudiobookSettings.selectedPlayerPreset,
              builder: (context, current, _) =>
                  LuPillTabs<AudiobookPlayerPreset>(
                    semanticsLabel: l10n.abkAudioPlayerDesignPreset,
                    selected: current,
                    compact: true,
                    onSelected: AudiobookSettings.setSelectedPlayerPreset,
                    options: [
                      for (final preset in AudiobookPlayerPreset.values)
                        LuPillOption(
                          value: preset,
                          label: abkPresetLabel(l10n, preset),
                        ),
                    ],
                  ),
            ),
            const SizedBox(height: LuSpace.l),
            heading(l10n.abk2SeekBarScrubberStyle),
            ValueListenableBuilder<AudiobookSeekbarStyle>(
              valueListenable: AudiobookSettings.customSeekbarStyle,
              builder: (context, current, _) =>
                  LuPillTabs<AudiobookSeekbarStyle>(
                    semanticsLabel: l10n.abkSeekBarScrubberStyle,
                    selected: current,
                    compact: true,
                    onSelected: AudiobookSettings.setCustomSeekbarStyle,
                    options: [
                      for (final style in AudiobookSeekbarStyle.values)
                        LuPillOption(
                          value: style,
                          label: abkSeekLabel(l10n, style),
                        ),
                    ],
                  ),
            ),
            const SizedBox(height: LuSpace.l),
            heading(l10n.abk2PlayPauseButtonStyle),
            ValueListenableBuilder<AudiobookPlayButtonStyle>(
              valueListenable: AudiobookSettings.customPlayButtonStyle,
              builder: (context, current, _) =>
                  LuPillTabs<AudiobookPlayButtonStyle>(
                    semanticsLabel: l10n.abkPlayPauseButtonStyle,
                    selected: current,
                    compact: true,
                    onSelected: AudiobookSettings.setCustomPlayButtonStyle,
                    options: [
                      for (final style in AudiobookPlayButtonStyle.values)
                        LuPillOption(
                          value: style,
                          label: abkButtonLabel(l10n, style),
                        ),
                    ],
                  ),
            ),
            const SizedBox(height: LuSpace.xl),
            LuButton(
              label: l10n.abkOpenDragDropPlayerStudio,
              icon: Icons.dashboard_customize_rounded,
              kind: LuButtonKind.secondary,
              expand: true,
              compact: true,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AudiobookPlayerStudioPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// The control that had focus when the chapters drawer opened.
  FocusNode? _chaptersDrawerOpener;

  /// Closes the chapters drawer and puts the remote back on the control that
  /// opened it.
  void _closeChaptersDrawer() {
    if (!_showChaptersDrawer) return;
    setState(() => _showChaptersDrawer = false);
    final opener = _chaptersDrawerOpener;
    _chaptersDrawerOpener = null;
    if (opener == null) return;
    // After the frame that removes the drawer, when the control is reachable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (opener.context == null || !opener.canRequestFocus) return;
      opener.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read in the build that opens the drawer, before its scope autofocuses,
    // so this is still the control that opened it.
    if (_showChaptersDrawer) {
      _chaptersDrawerOpener ??= FocusManager.instance.primaryFocus;
    }
    // While the chapters drawer is up, Back (the remote's, Android's, the
    // desktop's) closes the drawer instead of popping the whole player.
    return PopScope(
      canPop: !_showChaptersDrawer,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _closeChaptersDrawer();
      },
      child: _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final hasCover = widget.audiobook.coverImage.isNotEmpty;
    final currentChapter =
        widget.chapters.isNotEmpty &&
            _currentChapterIndex < widget.chapters.length
        ? widget.chapters[_currentChapterIndex]
        : null;
    final preset = AudiobookSettings.selectedPlayerPreset.value;

    final screenSize = MediaQuery.sizeOf(context);
    final isDesktop = screenSize.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Dismissible Scrim with blur
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const ColoredBox(color: Color(0xE00A0A0C)),
              ),
            ),

            // Floating Modal Window
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 680,
                  maxHeight: math.min(780, screenSize.height * 0.90),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    // A raised modal, not a menu: [surface] is the darkest of the
                    // three steps, so the glass island and the search field — both
                    // [surface] — keep reading as panels on top of this.
                    color: LuColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: LuColors.lineSoft),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.75),
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: LuMediaBackdrop(
                            url: hasCover ? widget.audiobook.coverImage : null,
                            httpHeaders: abkCoverHeaders,
                            opacity: 0.5,
                          ),
                        ),

                        // Main Modal Content
                        Column(
                          children: [
                            // Top App Bar
                            _buildTopAppBar(context, isDesktop: true),

                            // Main Content Rendered by Selected Player Preset
                            Expanded(
                              child: _buildPlayerContentByPreset(
                                preset,
                                false,
                                hasCover,
                                currentChapter,
                              ),
                            ),
                          ],
                        ),

                        // Sliding Premade Chapters Drawer Overlay
                        if (_showChaptersDrawer)
                          Positioned.fill(child: _buildPremadeChaptersDrawer()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: LuColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: LuMediaBackdrop(
              url: hasCover ? widget.audiobook.coverImage : null,
              httpHeaders: abkCoverHeaders,
              opacity: 0.55,
            ),
          ),

          // Main Layout
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Width alone was not enough. A 2 GB Chromecast with Google TV
                // reports 960x540 dp - comfortably past the 800 dp mark, so the
                // wide layout was chosen - and then a 260 dp cover, a vinyl disc
                // and the waveform had to fit in what was left of 540 dp minus
                // the app bar. They did not, so the transport controls were
                // pushed below the fold on the one screen where a remote user
                // most needs them.
                //
                // `artScale` is the correction: 1 on a normal window, smaller
                // when there is genuinely not the height for the wide art. The
                // presets already scroll, so this is about what fits, not
                // about reachability.
                final isWide = constraints.maxWidth > 800;
                final availableHeight = constraints.maxHeight;
                final artScale = availableHeight < 620
                    ? (availableHeight / 620).clamp(0.62, 1.0)
                    : 1.0;

                return Column(
                  children: [
                    // Top App Bar
                    _buildTopAppBar(context),

                    // Main Content Rendered by Selected Player Preset
                    Expanded(
                      child: _buildPlayerContentByPreset(
                        preset,
                        isWide,
                        hasCover,
                        currentChapter,
                        artScale: artScale,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Sliding Premade Chapters Drawer Overlay
          if (_showChaptersDrawer)
            Positioned.fill(child: _buildPremadeChaptersDrawer()),
        ],
      ),
    );
  }

  // ── Top Header Bar ──
  Widget _buildTopAppBar(BuildContext context, {bool isDesktop = false}) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 560;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 8,
      ),
      child: Row(
        children: [
          _PlayerIconButton(
            icon: isDesktop ? Icons.close_rounded : Icons.arrow_back_rounded,
            size: isMobile ? 20 : 24,
            tooltip: isDesktop
                ? l10nCurrent().actionClose
                : l10nCurrent().abkBackTip,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: isMobile ? 8 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.audiobook.title,
                  style: LuText.body.copyWith(
                    fontSize: isMobile ? 15 : 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.audiobook.source.toLowerCase().contains('audiobookbay')
                      ? l10nOf(context).abkTorrentSource
                      : widget.audiobook.source,
                  style: LuText.caption.copyWith(
                    color: LuColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? 6 : 10),
          // Autoplay Switch
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile) ...[
                Text(
                  l10nCurrent().abk2Autoplay,
                  style: const TextStyle(
                    color: LuColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Transform.scale(
                scale: isMobile ? 0.75 : 0.85,
                child: Switch(
                  value: _autoplayNext,
                  onChanged: (val) => setState(() => _autoplayNext = val),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(width: isMobile ? 4 : 8),
          // Customizer Button
          _PlayerIconButton(
            icon: Icons.tune_rounded,
            size: isMobile ? 20 : 24,
            tooltip: l10nCurrent().abkCustomizeAudioPlayer,
            onTap: () => _showPlayerCustomizer(context),
          ),
          SizedBox(width: isMobile ? 4 : 6),
          // Chapters Button
          _PlayerIconButton(
            icon: Icons.format_list_bulleted_rounded,
            size: isMobile ? 20 : 24,
            tooltip: l10nCurrent().abkChaptersList,
            onTap: () => setState(() => _showChaptersDrawer = true),
          ),
        ],
      ),
    );
  }

  // ── Multi-Player Preset Dispatcher ──
  Widget _buildPlayerContentByPreset(
    AudiobookPlayerPreset preset,
    bool isWide,
    bool hasCover,
    AudiobookChapter? currentChapter, {

    /// Scales the cover art and disc down when the viewport is short.
    double artScale = 1.0,
  }) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              _statusMessage,
              style: LuText.bodySoft,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: LuColors.danger,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: LuColors.danger, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ZplaySpacing.s16),
              // The shared pill, so a failed chapter is recoverable with the
              // same control that starts one and carries the same ring.
              LuButton(
                label: l10nCurrent().abkRetryChapter,
                icon: Icons.refresh_rounded,
                compact: true,
                autofocus: true,
                onPressed: () => _initChapter(_currentChapterIndex),
              ),
            ],
          ),
        ),
      );
    }

    if (preset == AudiobookPlayerPreset.vinylStudio) {
      return _buildVinylStudioPlayer(
        isWide,
        hasCover,
        currentChapter,
        artScale: artScale,
      );
    }
    if (preset == AudiobookPlayerPreset.minimalCapsule) {
      return _buildMinimalCapsulePlayer(
        isWide,
        hasCover,
        currentChapter,
        artScale: artScale,
      );
    }
    if (preset == AudiobookPlayerPreset.immersiveCanvas) {
      return _buildImmersiveCanvasPlayer(
        isWide,
        hasCover,
        currentChapter,
        artScale: artScale,
      );
    }
    if (preset == AudiobookPlayerPreset.customStudio) {
      return _buildCustomStudioPlayer(
        isWide,
        hasCover,
        currentChapter,
        artScale: artScale,
      );
    }
    // Default: Modern Glass Island
    return _buildModernGlassPlayer(
      isWide,
      hasCover,
      currentChapter,
      artScale: artScale,
    );
  }

  // ── 1. Modern Glass Island Player ──
  Widget _buildModernGlassPlayer(
    bool isWide,
    bool hasCover,
    AudiobookChapter? currentChapter, {
    double artScale = 1.0,
  }) {
    final seekStyle = AudiobookSettings.customSeekbarStyle.value;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Cover Art with 3D Float Shadow
              _buildCoverArtCard(
                hasCover,
                size: (isWide ? 220 : 160) * artScale,
              ),
              const SizedBox(height: 18),
              _buildTitleSection(currentChapter),
              const SizedBox(height: 18),

              // Glass Control Island
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  // 0.88 sat between the scale's `overlayHover` (0.15) and
                  // `textPrimary` (0.90); the scale tops out at 0.90 because it was
                  // cut for text, not scrims, so this panel takes the highest
                  // defined step. Going opaque instead would flatten the blurred
                  // cover art it is deliberately floating over.
                  color: LuColors.surface.withValues(alpha: 0.88),
                  borderRadius: LuRadius.card,
                  border: Border.all(color: LuColors.lineSoft),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Waveform Seekbar
                    AudiobookWaveformSeekbar(
                      position: _position,
                      duration: _duration,
                      isPlaying: _isPlaying,
                      style: seekStyle,
                      onSeek: (pos) => seek(pos),
                    ),
                    const SizedBox(height: 12),

                    // Controls Row
                    _buildMainControlsCluster(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. Vinyl Turntable Studio Player ──
  Widget _buildVinylStudioPlayer(
    bool isWide,
    bool hasCover,
    AudiobookChapter? currentChapter, {
    double artScale = 1.0,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinning Vinyl Disc
              _buildVinylDiscWidget(
                hasCover,
                size: (isWide ? 240 : 190) * artScale,
              ),
              const SizedBox(height: 18),
              _buildTitleSection(currentChapter),
              const SizedBox(height: 18),

              // Animated VU Meters
              _buildVuMetersWidget(),
              const SizedBox(height: 16),

              // Waveform Seekbar
              AudiobookWaveformSeekbar(
                position: _position,
                duration: _duration,
                isPlaying: _isPlaying,
                style: AudiobookSeekbarStyle.audioWaveformCanvas,
                onSeek: (pos) => seek(pos),
              ),
              const SizedBox(height: 14),

              // Controls Cluster
              _buildMainControlsCluster(),
            ],
          ),
        ),
      ),
    );
  }

  // ── 3. Minimalist Focus Capsule Player ──
  Widget _buildMinimalCapsulePlayer(
    bool isWide,
    bool hasCover,
    AudiobookChapter? currentChapter, {
    double artScale = 1.0,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // The token doc files a sheet under [surface], not [surfaceOverlay];
              // 0.94 was an almost-opaque carve-out and [textPrimary] (0.90) is
              // the top of the defined scale, so this is the nearest step.
              color: LuColors.surface.withValues(alpha: 0.92),
              borderRadius: LuRadius.card,
              border: Border.all(color: LuColors.lineSoft),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox.square(
                        dimension: 52,
                        child: LuMediaArt(
                          url: widget.audiobook.coverImage,
                          cacheWidth: 156,
                          icon: Icons.headphones_rounded,
                          httpHeaders: abkCoverHeaders,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentChapter?.title ??
                                l10nCurrent().abk2ChapterNumber(
                                  _currentChapterIndex + 1,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuText.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.audiobook.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuText.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AudiobookWaveformSeekbar(
                  position: _position,
                  duration: _duration,
                  isPlaying: _isPlaying,
                  style: AudiobookSeekbarStyle.gradientProgress,
                  onSeek: (pos) => seek(pos),
                ),
                const SizedBox(height: 12),
                _buildMainControlsCluster(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 4. Immersive Canvas Studio Player ──
  Widget _buildImmersiveCanvasPlayer(
    bool isWide,
    bool hasCover,
    AudiobookChapter? currentChapter, {
    double artScale = 1.0,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Oversized 3D Card
              _buildCoverArtCard(
                hasCover,
                size: (isWide ? 260 : 180) * artScale,
              ),
              const SizedBox(height: 20),
              _buildTitleSection(currentChapter),
              const SizedBox(height: 20),
              AudiobookWaveformSeekbar(
                position: _position,
                duration: _duration,
                isPlaying: _isPlaying,
                style: AudiobookSeekbarStyle.audioWaveformCanvas,
                onSeek: (pos) => seek(pos),
              ),
              const SizedBox(height: 16),
              _buildMainControlsCluster(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── 5. Custom Drag & Drop Studio Player ──
  Widget _buildCustomStudioPlayer(
    bool isWide,
    bool hasCover,
    AudiobookChapter? currentChapter, {
    double artScale = 1.0,
  }) {
    final order = AudiobookSettings.componentOrder.value;
    final seekStyle = AudiobookSettings.customSeekbarStyle.value;
    final artStyle = AudiobookSettings.customArtworkStyle.value;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: order.map((key) {
              switch (key) {
                case 'artwork':
                  if (artStyle == AudiobookArtworkStyle.hidden) {
                    return const SizedBox.shrink();
                  }
                  if (artStyle == AudiobookArtworkStyle.vinylDisc) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildVinylDiscWidget(
                        hasCover,
                        size: (isWide ? 220 : 170) * artScale,
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCoverArtCard(
                      hasCover,
                      size: (isWide ? 210 : 160) * artScale,
                    ),
                  );
                case 'title':
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildTitleSection(currentChapter),
                  );
                case 'seekbar':
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AudiobookWaveformSeekbar(
                      position: _position,
                      duration: _duration,
                      isPlaying: _isPlaying,
                      style: seekStyle,
                      onSeek: (pos) => seek(pos),
                    ),
                  );
                case 'mainControls':
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildMainControlsCluster(),
                  );
                case 'secondaryControls':
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSpeedSelectorPill(),
                        const SizedBox(width: 16),
                        _VolumeButton(
                          volume: _volume,
                          onVolumeChanged: (v) {
                            setState(() => _volume = v);
                            _player?.setVolume(v * 100.0);
                          },
                        ),
                      ],
                    ),
                  );
                case 'chaptersButton':
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LuButton(
                      label: l10nCurrent().abk2OpenChaptersPanel,
                      icon: Icons.format_list_bulleted_rounded,
                      kind: LuButtonKind.secondary,
                      compact: true,
                      onPressed: () =>
                          setState(() => _showChaptersDrawer = true),
                    ),
                  );
                default:
                  return const SizedBox.shrink();
              }
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Cover Art Card ──
  Widget _buildCoverArtCard(bool hasCover, {double size = 200}) {
    return AnimatedContainer(
      duration: LuMotion.page,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: LuRadius.card,
        boxShadow: [
          const BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 36,
            offset: Offset(0, 14),
          ),
          if (_isPlaying)
            const BoxShadow(color: Color(0x33F2B544), blurRadius: 40),
        ],
      ),
      child: ClipRRect(
        borderRadius: LuRadius.card,
        child: LuMediaArt(
          url: hasCover ? widget.audiobook.coverImage : null,
          cacheWidth: (size * 2.5).round(),
          icon: Icons.headphones_rounded,
          httpHeaders: abkCoverHeaders,
        ),
      ),
    );
  }

  // ── Spinning Vinyl Disc Widget ──
  Widget _buildVinylDiscWidget(bool hasCover, {double size = 220}) {
    return AnimatedBuilder(
      animation: _discAnimController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _discAnimController.value * 2 * 3.14159,
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: LuColors.gold.withValues(alpha: _isPlaying ? 0.3 : 0.12),
              blurRadius: _isPlaying ? 36 : 18,
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: LuMediaArt(
                  url: hasCover ? widget.audiobook.coverImage : null,
                  cacheWidth: (size * 2).round(),
                  icon: Icons.headphones_rounded,
                  httpHeaders: abkCoverHeaders,
                ),
              ),
              // The record's spindle hole.
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: LuColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: LuColors.gold, width: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── VU Audio Meters Widget ──
  Widget _buildVuMetersWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(16, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 4,
          height: _isPlaying ? (8 + ((i % 5) * 4.5)) : 6,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: _isPlaying ? LuColors.gold : const Color(0x3DFFFFFF),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  // ── Title Section ──
  Widget _buildTitleSection(AudiobookChapter? currentChapter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            currentChapter?.title ??
                l10nCurrent().abk2ChapterNumber(_currentChapterIndex + 1),
            textAlign: TextAlign.center,
            style: LuText.heading.copyWith(fontSize: 24, height: 1.25),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            l10nCurrent().abk2ChapterOfTotalBook(
              _currentChapterIndex + 1,
              widget.chapters.length,
              widget.audiobook.title,
            ),
            textAlign: TextAlign.center,
            style: LuText.label.copyWith(color: LuColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Main Controls Cluster (Prev, Rewind, Play, Forward, Next, Speed, Volume) ──
  Widget _buildMainControlsCluster() {
    final playBtnStyle = AudiobookSettings.customPlayButtonStyle.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;

        final prevBtn = _PlayerIconButton(
          icon: Icons.skip_previous_rounded,
          size: isNarrow ? 24 : 28,
          tooltip: l10nCurrent().abkPreviousChapter,
          onTap: _currentChapterIndex > 0
              ? () => _initChapter(_currentChapterIndex - 1)
              : null,
        );

        final rewBtn = _PlayerIconButton(
          icon: Icons.replay_10_rounded,
          size: isNarrow ? 24 : 28,
          tooltip: l10nCurrent().abkRewind10s,
          onTap: () => _seekRelative(-10),
        );

        // The physics button is the control: one focus stop, gold.
        final playButton = Tooltip(
          message: _isPlaying
              ? l10nCurrent().musPauseTip
              : l10nCurrent().musPlayTip,
          child: _buildPlayButtonByStyle(playBtnStyle),
        );

        final fwdBtn = _PlayerIconButton(
          icon: Icons.forward_10_rounded,
          size: isNarrow ? 24 : 28,
          tooltip: l10nCurrent().abkForward10s,
          onTap: () => _seekRelative(10),
        );

        final nextBtn = _PlayerIconButton(
          icon: Icons.skip_next_rounded,
          size: isNarrow ? 24 : 28,
          tooltip: l10nCurrent().abkNextChapter,
          onTap: _currentChapterIndex < widget.chapters.length - 1
              ? () => _initChapter(_currentChapterIndex + 1)
              : null,
        );

        final speedPill = _buildSpeedSelectorPill();

        final volumeBtn = _VolumeButton(
          volume: _volume,
          onVolumeChanged: (v) {
            setState(() => _volume = v);
            _player?.setVolume(v * 100.0);
          },
        );

        if (isNarrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary 5 Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [prevBtn, rewBtn, playButton, fwdBtn, nextBtn],
              ),
              const SizedBox(height: 12),
              // Secondary Utility Row: Speed and Volume
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [speedPill, volumeBtn],
                ),
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            speedPill,
            prevBtn,
            rewBtn,
            playButton,
            fwdBtn,
            nextBtn,
            volumeBtn,
          ],
        );
      },
    );
  }

  Widget _buildSpeedSelectorPill() {
    return Tooltip(
      message: l10nCurrent().abkPlaybackSpeedTip,
      child: LuFocusable(
        onTap: _cycleSpeed,
        lift: 1.06,
        semanticLabel:
            '${l10nCurrent().abkPlaybackSpeedTip} ${_playbackSpeed}x',
        builder: (context, highlighted) => AnimatedContainer(
          duration: LuMotion.focus,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0x29FFFFFF)
                : const Color(0x14FFFFFF),
            borderRadius: LuRadius.pill,
          ),
          child: Text(
            '${_playbackSpeed}x',
            style: LuText.label.copyWith(
              color: LuColors.gold,
              fontFamily: LuFonts.display,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  /// The gold play button, in the shape the player setting picks.
  Widget _buildPlayButtonByStyle(AudiobookPlayButtonStyle style) {
    final icon = _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded;
    const glow = [
      BoxShadow(color: Color(0x66F2B544), blurRadius: 26, spreadRadius: 1),
    ];

    final BorderRadius borderRadius;
    final Widget buttonCore;
    switch (style) {
      case AudiobookPlayButtonStyle.liquidGlassNeo:
        borderRadius = BorderRadius.circular(30);
        buttonCore = Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0x33F2B544),
            shape: BoxShape.circle,
            border: Border.all(color: LuColors.gold, width: 1.5),
            boxShadow: glow,
          ),
          child: Icon(icon, color: LuColors.gold, size: 34),
        );
      case AudiobookPlayButtonStyle.roundedSquare:
        borderRadius = BorderRadius.circular(18);
        buttonCore = Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: LuColors.gold,
            borderRadius: borderRadius,
            boxShadow: glow,
          ),
          child: Icon(icon, color: LuColors.onGold, size: 34),
        );
      case AudiobookPlayButtonStyle.accentPill:
        borderRadius = LuRadius.pill;
        buttonCore = Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: LuColors.gold,
            borderRadius: LuRadius.pill,
            boxShadow: glow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: LuColors.onGold, size: 26),
              const SizedBox(width: 8),
              Text(
                _isPlaying
                    ? l10nCurrent().abkPauseCaps
                    : l10nCurrent().abkPlayCaps,
                style: LuText.button.copyWith(
                  color: LuColors.onGold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      case AudiobookPlayButtonStyle.circleGlow:
        borderRadius = BorderRadius.circular(32);
        buttonCore = Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: LuColors.gold,
            boxShadow: glow,
          ),
          child: Icon(icon, color: LuColors.onGold, size: 38),
        );
    }

    return AudiobookInteractivePhysicsButton(
      effect: AudiobookSettings.customHoverEffect.value,
      glowColor: LuColors.gold,
      borderRadius: borderRadius,
      onTap: _togglePlayPause,
      child: buttonCore,
    );
  }

  // ── Chapters sheet ──
  Widget _buildPremadeChaptersDrawer() {
    final l10n = l10nOf(context);
    final filteredChapters = widget.chapters.where((c) {
      if (_chapterSearchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_chapterSearchQuery.toLowerCase());
    }).toList();

    return FocusScope(
      autofocus: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeChaptersDrawer,
              child: const ColoredBox(color: Color(0xB30A0A0C)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                height: MediaQuery.sizeOf(context).height * 0.72,
                decoration: BoxDecoration(
                  color: LuColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(color: LuColors.lineSoft),
                  boxShadow: const [
                    BoxShadow(color: Color(0xCC000000), blurRadius: 40),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: const BoxDecoration(
                        color: LuColors.line,
                        borderRadius: LuRadius.pill,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 14, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.format_list_bulleted_rounded,
                            color: LuColors.gold,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.abk2AudiobookChapters,
                              style: LuText.heading,
                            ),
                          ),
                          LuBadge(
                            l10n.abk2ChaptersCountUpper(widget.chapters.length),
                            muted: true,
                          ),
                          const SizedBox(width: 8),
                          LuMediaIconButton(
                            icon: Icons.close_rounded,
                            tooltip: l10n.actionClose,
                            onTap: _closeChaptersDrawer,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: SizedBox(
                        height: 46,
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _chapterSearchQuery = val),
                          style: LuText.label.copyWith(color: LuColors.text),
                          decoration: InputDecoration(
                            hintText: l10n.abkFilterChaptersByName,
                            hintStyle: LuText.label.copyWith(
                              color: const Color(0xFF77736B),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: LuColors.textMuted,
                              size: 18,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filteredChapters.length,
                        itemBuilder: (context, index) {
                          final chapter = filteredChapters[index];
                          final originalIndex = widget.chapters.indexOf(
                            chapter,
                          );
                          final isSelected =
                              originalIndex == _currentChapterIndex;

                          return _ChapterListItemTile(
                            chapter: chapter,
                            index: originalIndex,
                            isSelected: isSelected,
                            isPlaying: isSelected && _isPlaying,
                            onTap: () {
                              _closeChaptersDrawer();
                              _initChapter(originalIndex);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A chapter whose audio could not be found, carrying the sentence shown to
/// the listener, already localized, rather than an English exception text.
class _ChapterResolveException implements Exception {
  const _ChapterResolveException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _PlayerIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final String? tooltip;
  final VoidCallback? onTap;

  const _PlayerIconButton({
    required this.icon,
    this.size = 24,
    this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final padding = size <= 22 ? 7.0 : 10.0;

    final btn = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size,
        color: enabled ? LuColors.text : LuColors.textFaint,
      ),
    );

    return Tooltip(
      message: tooltip ?? '',
      child: AudiobookInteractivePhysicsButton(
        effect: AudiobookSettings.customHoverEffect.value,
        glowColor: LuColors.gold,
        borderRadius: BorderRadius.circular(size + 10),
        enabled: enabled,
        onTap: onTap,
        child: btn,
      ),
    );
  }
}

class _VolumeButton extends StatefulWidget {
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const _VolumeButton({required this.volume, required this.onVolumeChanged});

  @override
  State<_VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends State<_VolumeButton> {
  bool _showSlider = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlayerIconButton(
          icon: widget.volume == 0
              ? Icons.volume_off_rounded
              : (widget.volume > 0.5
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded),
          size: 22,
          tooltip: l10nCurrent().abkVolume,
          onTap: () {
            setState(() => _showSlider = !_showSlider);
          },
        ),
        if (_showSlider)
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: LuColors.gold,
                inactiveTrackColor: Color(0x3DFFFFFF),
                thumbColor: LuColors.gold,
              ),
              child: Slider(
                value: widget.volume,
                min: 0.0,
                max: 1.0,
                onChanged: widget.onVolumeChanged,
              ),
            ),
          ),
      ],
    );
  }
}

class _ChapterListItemTile extends StatelessWidget {
  final AudiobookChapter chapter;
  final int index;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;

  const _ChapterListItemTile({
    required this.chapter,
    required this.index,
    required this.isSelected,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: LuMediaRow(
        onTap: onTap,
        current: isSelected,
        semanticLabel: chapter.title,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? (isPlaying
                        ? Icons.graphic_eq_rounded
                        : Icons.pause_circle_filled_rounded)
                  : Icons.play_circle_outline_rounded,
              color: isSelected ? LuColors.gold : LuColors.textFaint,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.label.copyWith(
                  color: isSelected ? LuColors.text : LuColors.textSoft,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
