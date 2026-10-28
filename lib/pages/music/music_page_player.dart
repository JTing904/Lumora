part of 'music_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Now playing
// ─────────────────────────────────────────────────────────────────────────────

class _MusicExpandedPlayer extends StatefulWidget {
  final MusicPlayerController playerController;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onCollapse;
  final VoidCallback onQueueTap;
  final VoidCallback onLyricsTap;
  final VoidCallback onAddToPlaylist;

  const _MusicExpandedPlayer({
    required this.playerController,
    required this.isSaved,
    required this.onToggleSave,
    required this.onCollapse,
    required this.onQueueTap,
    required this.onLyricsTap,
    required this.onAddToPlaylist,
  });

  @override
  State<_MusicExpandedPlayer> createState() => _MusicExpandedPlayerState();
}

class _MusicExpandedPlayerState extends State<_MusicExpandedPlayer>
    with SingleTickerProviderStateMixin {
  /// The phone layout's height under the artwork: the chrome row, title,
  /// seekbar, transport, the panels row and the gaps between them.
  static const double _mobileReservedHeight = 400;

  /// The smallest the artwork shrinks to before the phone layout scrolls.
  static const double _mobileMinArtSize = 120;

  late AnimationController _discAnimController;

  @override
  void initState() {
    super.initState();
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.playerController.isPlaying) {
      _discAnimController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MusicExpandedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playerController.isPlaying && !_discAnimController.isAnimating) {
      _discAnimController.repeat();
    } else if (!widget.playerController.isPlaying &&
        _discAnimController.isAnimating) {
      _discAnimController.stop();
    }
  }

  @override
  void dispose() {
    _discAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final track = widget.playerController.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final preset = MusicSettings.selectedFullscreenPreset.value;
    final seekStyle = MusicSettings.customSeekbarStyle.value;
    final artStyle = MusicSettings.customArtworkStyle.value;
    final order = MusicSettings.componentOrderFullscreen.value;

    final screenSize = MediaQuery.sizeOf(context);
    final isDesktop = screenSize.width >= 800;

    // The player's own chrome: close, the source chip, more.
    final chromeRow = Row(
      children: [
        LuMediaIconButton(
          icon: isDesktop
              ? Icons.close_rounded
              : Icons.keyboard_arrow_down_rounded,
          tooltip: l10n.musClosePlayerTip,
          quiet: true,
          iconSize: isDesktop ? 22 : 30,
          onTap: widget.onCollapse,
        ),
        const Spacer(),
        _AudioSourceChip(
          label: widget.playerController.currentQualityLabel.toUpperCase(),
          lossless: widget.playerController.isCurrentTrackLossless,
          onTap: () =>
              _AudioSourceSelectorButton._showAudioSourceDialog(context),
        ),
        const Spacer(),
        LuMediaIconButton(
          icon: Icons.more_horiz_rounded,
          tooltip: l10n.musAddToPlaylistTip,
          quiet: true,
          onTap: widget.onAddToPlaylist,
        ),
      ],
    );

    List<Widget> content(double artSize) => [
      if (preset == MusicFullscreenPreset.customStudio)
        ...order.map(
          (key) =>
              _buildCustomComponent(key, track, seekStyle, artStyle, artSize),
        )
      else
        ..._buildPresetBody(preset, track, seekStyle, artSize),
    ];

    final Widget surface;
    if (isDesktop) {
      surface = Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onCollapse,
              child: const ColoredBox(color: Color(0xE00A0A0C)),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: math.min(780, screenSize.height * 0.92),
              ),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: LuColors.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                  border: Border.all(color: LuColors.lineSoft),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xCC000000),
                      blurRadius: 48,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: LuMediaBackdrop(url: track.coverUrl, opacity: 0.5),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          chromeRow,
                          const SizedBox(height: LuSpace.l),
                          ...content(math.min(260.0, screenSize.height * 0.32)),
                          const SizedBox(height: LuSpace.s),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      surface = ColoredBox(
        color: LuColors.bg,
        child: Stack(
          children: [
            Positioned.fill(
              child: LuMediaBackdrop(url: track.coverUrl, opacity: 0.55),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuSpace.l,
                  vertical: LuSpace.m,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // The artwork gives way first: everything under it is a
                    // fixed height (title, seekbar, transport, panels), so the
                    // art takes what is left of the height actually available,
                    // never more than it used to on a tall phone. A short
                    // phone (360x640) keeps every control on screen, and a
                    // layout that still runs out of room scrolls rather than
                    // overflowing.
                    final artSize = math
                        .min(
                          math.min(
                            screenSize.width * 0.75,
                            screenSize.height * 0.38,
                          ),
                          constraints.maxHeight - _mobileReservedHeight,
                        )
                        .clamp(_mobileMinArtSize, double.infinity)
                        .toDouble();
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        // The chrome at the top and the body centred in the
                        // room under it, as the two spacers used to.
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            chromeRow,
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: content(artSize),
                            ),
                            const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    return FocusScope(autofocus: true, child: surface);
  }

  List<Widget> _buildPresetBody(
    MusicFullscreenPreset preset,
    MusicTrack track,
    MusicSeekbarStyle seekStyle,
    double artSize,
  ) {
    return [
      if (preset == MusicFullscreenPreset.vinylStudio)
        _buildVinylDiscArtwork(track, artSize)
      else if (preset == MusicFullscreenPreset.cyberWaveform)
        _buildFramedArtwork(track, artSize)
      else if (preset == MusicFullscreenPreset.liquidGlassNeo)
        _buildGlassArtwork(track, artSize)
      else
        _buildCinematicArtwork(track, artSize),

      const SizedBox(height: LuSpace.xl),
      _buildTitleRow(track),
      const SizedBox(height: LuSpace.l),

      MusicWaveformSeekbar(
        position: widget.playerController.position,
        duration: widget.playerController.duration,
        isPlaying: widget.playerController.isPlaying,
        style: preset == MusicFullscreenPreset.cyberWaveform
            ? MusicSeekbarStyle.waveformEqualizer
            : (preset == MusicFullscreenPreset.liquidGlassNeo
                  ? MusicSeekbarStyle.liquidGlassSlider
                  : seekStyle),
        keyStep: const Duration(seconds: 5),
        onSeek: (pos) => widget.playerController.seekTo(pos),
      ),

      const SizedBox(height: LuSpace.l),
      _buildPlaybackControlsRow(),
      const SizedBox(height: LuSpace.l),
      _buildSecondaryRow(),
    ];
  }

  Widget _buildCustomComponent(
    String key,
    MusicTrack track,
    MusicSeekbarStyle seekStyle,
    MusicArtworkStyle artStyle,
    double artSize,
  ) {
    final l10n = l10nOf(context);
    switch (key) {
      case 'artwork':
        return Padding(
          padding: const EdgeInsets.only(bottom: LuSpace.l),
          child: _buildCustomArtworkByStyle(track, artSize, artStyle),
        );
      case 'title':
        return Padding(
          padding: const EdgeInsets.only(bottom: LuSpace.m),
          child: _buildTitleRow(track),
        );
      case 'qualityBadge':
        return Padding(
          padding: const EdgeInsets.only(bottom: LuSpace.s),
          child: LuBadge(
            l10n.musHiResLosslessAudio(
              widget.playerController.currentQualityLabel.toUpperCase(),
            ),
          ),
        );
      case 'seekbar':
        return Padding(
          padding: const EdgeInsets.only(bottom: LuSpace.l),
          child: MusicWaveformSeekbar(
            position: widget.playerController.position,
            duration: widget.playerController.duration,
            isPlaying: widget.playerController.isPlaying,
            style: seekStyle,
            keyStep: const Duration(seconds: 5),
            onSeek: (pos) => widget.playerController.seekTo(pos),
          ),
        );
      case 'mainControls':
        return Padding(
          padding: const EdgeInsets.only(bottom: LuSpace.m),
          child: _buildPlaybackControlsRow(),
        );
      case 'secondaryControls':
        return Padding(
          padding: const EdgeInsets.only(bottom: LuSpace.s),
          child: _buildSecondaryRow(),
        );
      case 'extraActions':
        return Padding(
          padding: const EdgeInsets.only(bottom: LuSpace.xs),
          child: Center(
            child: LuButton(
              label: l10n.musPlayingQueue,
              kind: LuButtonKind.secondary,
              icon: Icons.queue_music_rounded,
              compact: true,
              onPressed: widget.onQueueTap,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTitleRow(MusicTrack track) {
    final l10n = l10nOf(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.title.copyWith(fontSize: 26, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.body.copyWith(color: LuColors.textMuted),
              ),
            ],
          ),
        ),
        LuMediaIconButton(
          icon: widget.isSaved
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          tooltip: l10n.musLikeTip,
          active: widget.isSaved,
          size: 48,
          onTap: widget.onToggleSave,
        ),
      ],
    );
  }

  /// A quiet transport glyph, with the page's hover setting for its motion.
  Widget _quiet({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    double size = 28,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: MusicInteractivePhysicsButton(
        effect: MusicSettings.customHoverEffect.value,
        glowColor: LuColors.gold,
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: active ? LuColors.gold : LuColors.textSoft,
            size: size,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControlsRow() {
    final l10n = l10nOf(context);
    final player = widget.playerController;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _quiet(
          icon: Icons.shuffle_rounded,
          tooltip: l10n.musShuffle,
          size: 22,
          active: player.isShuffle,
          onTap: player.toggleShuffle,
        ),
        _quiet(
          icon: Icons.skip_previous_rounded,
          tooltip: l10n.musPreviousTip,
          size: 34,
          onTap: player.playPrevious,
        ),
        Tooltip(
          message: player.isPlaying ? l10n.musPauseTip : l10n.musPlayTip,
          child: MusicInteractivePhysicsButton(
            effect: MusicSettings.customHoverEffect.value,
            glowColor: LuColors.gold,
            borderRadius: const BorderRadius.all(Radius.circular(36)),
            onTap: player.togglePlayPause,
            child: player.isLoading
                ? const SizedBox(
                    width: 68,
                    height: 68,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  )
                : _buildPlayButton(MusicSettings.customPlayButtonStyle.value),
          ),
        ),
        _quiet(
          icon: Icons.skip_next_rounded,
          tooltip: l10n.musNextTip,
          size: 34,
          onTap: player.playNext,
        ),
        _quiet(
          icon: player.repeatMode == MusicRepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          tooltip: l10n.musRepeatTip,
          size: 22,
          active: player.repeatMode != MusicRepeatMode.off,
          onTap: player.toggleRepeat,
        ),
      ],
    );
  }

  /// Lyrics and the queue, the two panels the player opens.
  Widget _buildSecondaryRow() {
    final l10n = l10nOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LuMediaIconButton(
          icon: Icons.format_quote_rounded,
          tooltip: l10n.musLyricsTip,
          quiet: true,
          onTap: widget.onLyricsTap,
        ),
        const SizedBox(width: LuSpace.l),
        LuMediaIconButton(
          icon: Icons.queue_music_rounded,
          tooltip: l10n.musQueueTip,
          quiet: true,
          onTap: widget.onQueueTap,
        ),
      ],
    );
  }

  /// The gold play button, in the shape the player setting picks.
  Widget _buildPlayButton(MusicPlayButtonStyle style) {
    final icon = widget.playerController.isPlaying
        ? Icons.pause_rounded
        : Icons.play_arrow_rounded;
    const glow = [
      BoxShadow(color: Color(0x66F2B544), blurRadius: 28, spreadRadius: 1),
    ];

    switch (style) {
      case MusicPlayButtonStyle.liquidGlassNeo:
        return Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0x33F2B544),
            shape: BoxShape.circle,
            border: Border.all(color: LuColors.gold, width: 1.5),
            boxShadow: glow,
          ),
          child: Icon(icon, color: LuColors.gold, size: 38),
        );
      case MusicPlayButtonStyle.neonSquare:
        return Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: LuColors.gold,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: glow,
          ),
          child: Icon(icon, color: LuColors.onGold, size: 38),
        );
      case MusicPlayButtonStyle.pillPulse:
        return Container(
          width: 104,
          height: 64,
          decoration: const BoxDecoration(
            color: LuColors.gold,
            borderRadius: LuRadius.pill,
            boxShadow: glow,
          ),
          child: Icon(icon, color: LuColors.onGold, size: 36),
        );
      case MusicPlayButtonStyle.circleGlow:
        return Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: LuColors.gold,
            shape: BoxShape.circle,
            boxShadow: glow,
          ),
          child: Icon(icon, color: LuColors.onGold, size: 40),
        );
    }
  }

  Widget _art(MusicTrack track, {int cacheWidth = 800}) =>
      LuMediaArt(url: track.coverUrl, cacheWidth: cacheWidth);

  Widget _buildVinylDiscArtwork(MusicTrack track, double size) {
    return AnimatedBuilder(
      animation: _discAnimController,
      builder: (context, child) => Transform.rotate(
        angle: widget.playerController.isPlaying
            ? _discAnimController.value * 2 * math.pi
            : 0,
        child: child,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF111114),
          border: Border.all(color: const Color(0xFF2A2A30), width: 4),
          boxShadow: const [
            BoxShadow(color: Color(0x40F2B544), blurRadius: 40),
          ],
        ),
        child: Center(
          child: ClipOval(
            child: SizedBox.square(
              dimension: size * 0.44,
              child: _art(track, cacheWidth: 400),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFramedArtwork(MusicTrack track, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: LuRadius.card,
        border: Border.all(color: LuColors.gold, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x55F2B544), blurRadius: 32)],
      ),
      child: ClipRRect(borderRadius: LuRadius.card, child: _art(track)),
    );
  }

  Widget _buildGlassArtwork(MusicTrack track, double size) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x40F2B544), blurRadius: 30)],
      ),
      child: ClipRRect(borderRadius: LuRadius.card, child: _art(track)),
    );
  }

  Widget _buildCinematicArtwork(MusicTrack track, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        borderRadius: LuRadius.card,
        boxShadow: [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 36,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: LuRadius.card, child: _art(track)),
    );
  }

  Widget _buildCustomArtworkByStyle(
    MusicTrack track,
    double size,
    MusicArtworkStyle style,
  ) {
    switch (style) {
      case MusicArtworkStyle.vinylSpinningDisc:
        return _buildVinylDiscArtwork(track, size);
      case MusicArtworkStyle.floatingCard3D:
        return _buildGlassArtwork(track, size);
      case MusicArtworkStyle.glowSphere:
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x55F2B544), blurRadius: 40)],
          ),
          child: ClipOval(child: _art(track)),
        );
      case MusicArtworkStyle.square3D:
        return _buildCinematicArtwork(track, size);
    }
  }
}
