part of 'music_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chrome: the search row and the view pills
// ─────────────────────────────────────────────────────────────────────────────

/// Music's chrome: the header row and the view band over the page. Clear at
/// the top, so the shell's blended bar rests on the page's own ground, and
/// the ground's colour once content scrolls beneath it.
class _MusicChrome extends StatelessWidget {
  final ScrollController scrollController;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool isSearching;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onSettingsTap;
  final MusicView view;
  final ValueChanged<MusicView> onSelected;

  const _MusicChrome({
    required this.scrollController,
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearching,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSettingsTap,
    required this.view,
    required this.onSelected,
  });

  /// Scroll distance over which the chrome settles onto the ground.
  static const double _scrollThreshold = 32.0;

  @override
  Widget build(BuildContext context) {
    final height = _musicHeaderHeight(context) + _musicViewBandHeight(context);

    final header = _MusicTopHeader(
      searchController: searchController,
      searchFocusNode: searchFocusNode,
      isSearching: isSearching,
      onSearchChanged: onSearchChanged,
      onClearSearch: onClearSearch,
      onSettingsTap: onSettingsTap,
    );
    final band = _MusicViewBand(view: view, onSelected: onSelected);

    return ListenableBuilder(
      listenable: scrollController,
      builder: (context, _) {
        // Two scroll views are attached for one frame of every view switch;
        // the newest is the one on screen.
        final positions = scrollController.positions;
        final offset = positions.isEmpty ? 0.0 : positions.last.pixels;
        final t = (offset / _scrollThreshold).clamp(0.0, 1.0);
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: LuColors.bg.withValues(alpha: 0.94 * t),
                      border: Border(
                        bottom: BorderSide(
                          color: LuColors.lineSoft.withValues(alpha: t),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [header, band]),
            ],
          ),
        );
      },
    );
  }
}

class _MusicTopHeader extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool isSearching;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onSettingsTap;

  const _MusicTopHeader({
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearching,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 600;
    final isVeryNarrow = screenW < 400;
    final tv = luMediaIsTv(context);
    final pad = luMediaPad(context);
    final buttonSize = tv ? 48.0 : (isMobile ? 40.0 : 44.0);

    return Container(
      height: _musicHeaderHeight(context),
      padding: EdgeInsets.fromLTRB(pad, topInset + 10, pad, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: searchFocusNode,
              builder: (context, _) {
                final focused = searchFocusNode.hasFocus;
                return AnimatedContainer(
                  duration: LuMotion.focus,
                  height: tv ? 48 : 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: LuColors.field,
                    borderRadius: LuRadius.pill,
                    border: Border.all(
                      color: focused ? LuColors.gold : LuColors.line,
                      width: focused ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: focused ? LuColors.gold : LuColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          focusNode: searchFocusNode,
                          onChanged: onSearchChanged,
                          textInputAction: TextInputAction.search,
                          cursorColor: LuColors.gold,
                          style: LuText.body.copyWith(
                            fontSize: isMobile ? 15 : 16,
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            filled: false,
                            hintText: isVeryNarrow
                                ? l10n.musSearchShort
                                : (isMobile
                                      ? l10n.musSearchMusic
                                      : l10n.musSearchSongsArtistsAlbumsPlaylists),
                            hintStyle: LuText.body.copyWith(
                              fontSize: isMobile ? 15 : 16,
                              color: const Color(0xFF77736B),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      if (searchController.text.isNotEmpty)
                        LuMediaIconButton(
                          icon: Icons.close_rounded,
                          tooltip: l10n.musClearSearchTip,
                          size: 30,
                          quiet: true,
                          onTap: onClearSearch,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(width: isMobile ? 8 : 14),
          const _AudioSourceSelectorButton(),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            LuMediaIconButton(
              icon: Icons.dashboard_customize_rounded,
              tooltip: l10n.musMusicPlayerStudio,
              size: buttonSize,
              quiet: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MusicPlayerStudioPage(),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            LuMediaIconButton(
              icon: Icons.palette_outlined,
              tooltip: l10n.musMusicAtmosphereSettings,
              size: buttonSize,
              quiet: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MusicSettingsPage()),
                );
              },
            ),
          ],
          const SizedBox(width: 4),
          LuMediaIconButton(
            icon: Icons.settings_outlined,
            tooltip: l10n.musAppSettings,
            size: buttonSize,
            quiet: true,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

/// The page's own view switcher, under the header row: one pill per view,
/// the chosen one gold. The row scrolls on a phone instead of truncating.
class _MusicViewBand extends StatelessWidget {
  const _MusicViewBand({required this.view, required this.onSelected});

  final MusicView view;
  final ValueChanged<MusicView> onSelected;

  @override
  Widget build(BuildContext context) {
    final pad = luMediaPad(context);
    return SizedBox(
      height: _musicViewBandHeight(context),
      child: Align(
        alignment: Alignment.centerLeft,
        child: LuPillTabs<MusicView>(
          padding: EdgeInsets.symmetric(horizontal: pad),
          options: [
            for (final v in MusicView.values)
              LuPillOption<MusicView>(value: v, label: v.label),
          ],
          selected: view,
          onSelected: onSelected,
          semanticsLabel: l10nOf(context).musMusicView,
        ),
      ),
    );
  }
}

/// The audio source, as one glass chip that opens the source sheet. The same
/// control in the header and the expanded player.
class _AudioSourceChip extends StatelessWidget {
  final String label;

  /// Draws the diamond rather than the play disc.
  final bool lossless;

  final VoidCallback onTap;

  const _AudioSourceChip({
    required this.label,
    required this.lossless,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tv = luMediaIsTv(context);
    return LuFocusable(
      onTap: onTap,
      lift: 1.04,
      semanticLabel: '${l10nOf(context).musAudioSourceQuality}: $label',
      builder: (context, highlighted) => AnimatedContainer(
        duration: LuMotion.focus,
        height: tv ? 48 : 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0x29FFFFFF)
              : const Color(0x14FFFFFF),
          borderRadius: LuRadius.pill,
          border: Border.all(color: const Color(0x24FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              lossless ? Icons.diamond_rounded : Icons.play_circle_fill_rounded,
              color: LuColors.gold,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: LuText.caption.copyWith(
                color: LuColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: LuColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioSourceSelectorButton extends StatelessWidget {
  const _AudioSourceSelectorButton();

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerController.instance;

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final isFlac = player.audioSource == MusicAudioSource.flac;

        return _AudioSourceChip(
          label: isFlac ? 'FLAC' : 'YouTube',
          lossless: isFlac,
          onTap: () => _showAudioSourceDialog(context),
        );
      },
    );
  }

  static void _showAudioSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final player = MusicPlayerController.instance;

        return ListenableBuilder(
          listenable: player,
          builder: (context, _) {
            final l10n = l10nOf(context);
            final isFlac = player.audioSource == MusicAudioSource.flac;

            return _LuSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _IconSquare(icon: Icons.tune_rounded, size: 44),
                      const SizedBox(width: LuSpace.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.musAudioSourceQuality,
                              style: LuText.heading,
                            ),
                            Text(
                              l10n.musChooseExtractionEngine,
                              style: LuText.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: LuSpace.l),
                  _sourceOption(
                    title: l10n.musFlacLosslessQobuzHiRes,
                    subtitle: l10n.musStudioMasterQualityDesc,
                    icon: Icons.diamond_rounded,
                    isSelected: isFlac,
                    badge: l10n.musLossless,
                    onTap: () {
                      player.setAudioSource(MusicAudioSource.flac);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: LuSpace.m),
                  _sourceOption(
                    title: l10n.musYoutubeAudio,
                    subtitle: l10n.musYoutubeAudioDesc,
                    icon: Icons.play_circle_fill_rounded,
                    isSelected: !isFlac,
                    badge: l10n.musFast,
                    onTap: () {
                      player.setAudioSource(MusicAudioSource.youtube);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _sourceOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required String badge,
    required VoidCallback onTap,
  }) {
    return LuMediaTile(
      onTap: onTap,
      selected: isSelected,
      radius: LuRadius.field,
      padding: const EdgeInsets.all(16),
      semanticLabel: title,
      child: Row(
        children: [
          _IconSquare(icon: icon, size: 46),
          const SizedBox(width: LuSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: LuText.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: LuSpace.s),
                    LuBadge(badge, muted: !isSelected),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: LuText.caption),
              ],
            ),
          ),
          const SizedBox(width: LuSpace.s),
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isSelected ? LuColors.gold : LuColors.textFaint,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home: the hero, tiles and banners
// ─────────────────────────────────────────────────────────────────────────────

class _MusicHeroBillboard extends StatelessWidget {
  final MusicTrack track;
  final VoidCallback onPlayTap;
  final VoidCallback onSaveTap;
  final VoidCallback onAddToPlaylistTap;
  final bool isSaved;

  const _MusicHeroBillboard({
    required this.track,
    required this.onPlayTap,
    required this.onSaveTap,
    required this.onAddToPlaylistTap,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final phone = MediaQuery.sizeOf(context).width < 600;

    // The kicker carries the real quality label while this track is the one
    // playing; the catalogue carries no bit depth to claim otherwise.
    final player = MusicPlayerController.instance;
    final isPlayingThis =
        track.id.isNotEmpty && player.currentTrack?.id == track.id;
    final kicker = isPlayingThis
        ? (player.isCurrentTrackLossless
              ? l10n.musHiResLossless(player.currentQualityLabel)
              : player.currentQualityLabel)
        : l10n.musTopChartHit;

    final meta = [
      if (track.artist.isNotEmpty) track.artist,
      if (track.album.isNotEmpty) track.album,
      if (track.trackNumber != null && track.trackNumber! > 0)
        l10n.mus2TrackNumber('${track.trackNumber}'),
      if (track.durationSeconds > 0) track.formattedDuration,
    ].join('  ·  ');

    return LuMediaHero(
      kicker: kicker,
      title: track.title,
      meta: meta,
      imageUrl: track.coverUrl,
      actions: [
        LuButton(
          label: l10n.musPlayNow,
          icon: Icons.play_arrow_rounded,
          compact: phone,
          onPressed: onPlayTap,
        ),
        LuMediaIconButton(
          icon: isSaved
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          tooltip: l10n.musLikeTip,
          size: phone ? 40 : 56,
          active: isSaved,
          onTap: onSaveTap,
        ),
        LuMediaIconButton(
          icon: Icons.playlist_add_rounded,
          tooltip: l10n.musAddToPlaylistTip,
          size: phone ? 40 : 56,
          onTap: onAddToPlaylistTap,
        ),
      ],
    );
  }
}

/// A genre or a station: a rounded 24 tile, its glyph in gold.
class _GenreTile extends StatelessWidget {
  const _GenreTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LuFocusable(
      onTap: onTap,
      borderRadius: LuRadius.card,
      lift: 1.04,
      semanticLabel: title,
      builder: (context, highlighted) => AnimatedContainer(
        duration: LuMotion.focus,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: LuRadius.card,
          border: Border.all(color: LuColors.lineSoft),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: highlighted
                ? const [Color(0xFF2A2418), LuColors.surfaceHigh]
                : const [Color(0xFF1E1B15), LuColors.surface],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: LuColors.gold, size: 26),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LuText.body.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liked Songs and Downloaded Songs: a wide tile with a gold glyph, two lines
/// and a gold action disc.
class _LibraryBanner extends StatelessWidget {
  const _LibraryBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.actionIcon,
    this.trailingNote,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingNote;
  final IconData? actionIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LuMediaTile(
      onTap: onTap,
      semanticLabel: title,
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _IconSquare(icon: icon, size: 56, circle: true),
            const SizedBox(width: LuSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuText.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (trailingNote != null) ...[
                        const SizedBox(width: LuSpace.s),
                        LuBadge(trailingNote!, muted: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuText.caption,
                  ),
                ],
              ),
            ),
            if (actionIcon != null)
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: LuColors.gold,
                  shape: BoxShape.circle,
                ),
                child: Icon(actionIcon, color: LuColors.onGold, size: 26),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rows and small pieces
// ─────────────────────────────────────────────────────────────────────────────

class _MusicTrackRow extends StatelessWidget {
  final MusicTrack track;
  final bool isPlaying;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  /// The row's position in a tracklist (album, playlist, chart). A flat result
  /// list leaves it null and the leading slot carries the artwork instead.
  final int? index;

  const _MusicTrackRow({
    required this.track,
    required this.isPlaying,
    required this.isCurrent,
    required this.onTap,
    required this.onMoreTap,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final number = track.trackNumber ?? (index == null ? null : index! + 1);
    final phone = MediaQuery.sizeOf(context).width < 600;
    final transport = Icon(
      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      color: LuColors.gold,
      size: 24,
    );

    return LuMediaRow(
      onTap: onTap,
      onLongPress: onMoreTap,
      current: isCurrent,
      semanticLabel: '${track.title}, ${track.artist}',
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: number != null
                ? Center(
                    child: isCurrent
                        ? transport
                        : Text(
                            '$number',
                            style: LuText.label.copyWith(
                              color: LuColors.textFaint,
                              fontFamily: LuFonts.display,
                            ),
                          ),
                  )
                : ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LuMediaArt(url: track.coverUrl, cacheWidth: 144),
                        if (isCurrent)
                          ColoredBox(
                            color: const Color(0x990A0A0C),
                            child: Center(child: transport),
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: LuSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuText.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? LuColors.gold : LuColors.text,
                    height: 1.3,
                  ),
                ),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: LuSpace.s),
          _buildDownloadButton(context),
          if (!phone) ...[
            const SizedBox(width: LuSpace.s),
            Text(
              track.formattedDuration,
              style: LuText.caption.copyWith(fontFamily: LuFonts.display),
            ),
          ],
          const SizedBox(width: 4),
          LuMediaIconButton(
            icon: Icons.more_vert_rounded,
            tooltip: l10n.musMoreTip,
            size: 40,
            quiet: true,
            iconColor: LuColors.textMuted,
            onTap: onMoreTap,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    final l10n = l10nOf(context);
    final isDownloaded = MusicDownloadService.instance.isDownloaded(track.id);
    final task = MusicDownloadService.instance.getTask(track.id);
    final isDownloading =
        task != null &&
        (task.status == MusicDownloadStatus.extracting ||
            task.status == MusicDownloadStatus.downloading);
    final isQueued = task != null && task.status == MusicDownloadStatus.queued;

    if (isDownloaded) {
      return Tooltip(
        message: l10n.musDownloadedOffline,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.download_done_rounded,
            color: LuColors.gold,
            size: 20,
          ),
        ),
      );
    }

    if (isDownloading) {
      return Tooltip(
        message: l10n.mus2DownloadingPercent((task.progress * 100).toInt()),
        child: Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(
            value: task.progress > 0.05 ? task.progress : null,
            strokeWidth: 2.2,
          ),
        ),
      );
    }

    if (isQueued) {
      return Tooltip(
        message: l10n.musQueuedForDownload,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.hourglass_top_rounded,
            color: LuColors.goldLight,
            size: 20,
          ),
        ),
      );
    }

    return LuMediaIconButton(
      icon: Icons.download_rounded,
      tooltip: l10n.musDownloadTrack,
      size: 40,
      quiet: true,
      iconColor: LuColors.textMuted,
      onTap: () {
        MusicDownloadService.instance.queueTrack(track);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10nCurrent().mus2AddedToDownloadQueue(track.title)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

/// A track's cover, title and artist: the head of a sheet or a dialog.
class _TrackIdentity extends StatelessWidget {
  const _TrackIdentity({required this.track, this.size = 52});

  final MusicTrack track;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: SizedBox.square(
            dimension: size,
            child: LuMediaArt(url: track.coverUrl, cacheWidth: 160),
          ),
        ),
        const SizedBox(width: LuSpace.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A gold glyph on a gold-washed square (or disc): the mark of a playlist or
/// an option with no artwork of its own.
class _IconSquare extends StatelessWidget {
  const _IconSquare({required this.icon, this.size = 44, this.circle = false});

  final IconData icon;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0x24F2B544),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle
            ? null
            : const BorderRadius.all(Radius.circular(12)),
      ),
      child: Icon(icon, color: LuColors.gold, size: size * 0.5),
    );
  }
}

/// A bottom sheet in the cinema look: a rounded 24 panel that floats off the
/// edges, at most 560 wide.
class _LuSheet extends StatelessWidget {
  const _LuSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              margin: const EdgeInsets.all(LuSpace.m),
              padding: const EdgeInsets.all(LuSpace.l),
              decoration: BoxDecoration(
                color: LuColors.surface,
                borderRadius: LuRadius.card,
                border: Border.all(color: LuColors.lineSoft),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xAA000000),
                    blurRadius: 40,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: FocusTraversalGroup(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
