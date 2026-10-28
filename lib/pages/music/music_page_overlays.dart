part of 'music_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Drawers & modals
// ─────────────────────────────────────────────────────────────────────────────

/// A modal over the page: a dark scrim, a rounded 24 panel in the middle, and
/// its own focus scope so a remote stays inside it until it is closed.
class _LuModalFrame extends StatelessWidget {
  const _LuModalFrame({
    required this.onClose,
    required this.child,
    this.maxWidth = 760,
    this.heightFactor = 0.86,
    this.maxHeight = 680,
    this.padding = const EdgeInsets.all(24),
    this.shrinkWrap = false,
  });

  final VoidCallback onClose;
  final Widget child;
  final double maxWidth;
  final double heightFactor;
  final double maxHeight;
  final EdgeInsets padding;

  /// Size to the content rather than to a fixed height.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final phone = size.width < 700;
    final width = math.min(phone ? size.width - 24 : maxWidth, maxWidth);
    final height = math.min(size.height * heightFactor, maxHeight);
    final panel = Container(
      width: width,
      height: shrinkWrap ? null : height,
      constraints: shrinkWrap ? BoxConstraints(maxHeight: height) : null,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: LuColors.surface,
        borderRadius: LuRadius.card,
        border: Border.all(color: LuColors.lineSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 48,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
    return FocusScope(
      autofocus: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: const ColoredBox(color: Color(0xD90A0A0C)),
            ),
          ),
          Center(child: panel),
        ],
      ),
    );
  }
}

/// The close glyph every drawer and modal carries, focused first.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap, this.autofocus = true});

  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return LuMediaIconButton(
      icon: Icons.close_rounded,
      tooltip: l10nOf(context).actionClose,
      autofocus: autofocus,
      onTap: onTap,
    );
  }
}

/// A side drawer (lyrics, queue): full width on a phone, 380 at the right
/// edge elsewhere.
class _LuDrawerFrame extends StatelessWidget {
  const _LuDrawerFrame({
    required this.icon,
    required this.title,
    required this.onClose,
    required this.child,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final VoidCallback onClose;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;
    return FocusScope(
      autofocus: true,
      child: Container(
        width: isMobile ? size.width : 380,
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 16,
          20,
          16,
        ),
        decoration: BoxDecoration(
          color: LuColors.surface,
          borderRadius: isMobile
              ? null
              : const BorderRadius.horizontal(left: Radius.circular(24)),
          border: const Border(left: BorderSide(color: LuColors.lineSoft)),
          boxShadow: const [
            BoxShadow(color: Color(0xCC000000), blurRadius: 40),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: LuColors.gold, size: 22),
                const SizedBox(width: LuSpace.s),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuText.heading,
                  ),
                ),
                ...actions,
                const SizedBox(width: 6),
                _CloseButton(onTap: onClose),
              ],
            ),
            const SizedBox(height: LuSpace.m),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _MusicLyricsDrawer extends StatelessWidget {
  final MusicTrack track;
  final MusicPlayerController playerController;
  final VoidCallback onClose;

  const _MusicLyricsDrawer({
    required this.track,
    required this.playerController,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final lyrics = playerController.currentLyrics;
    final activeIndex = playerController.activeLyricIndex;

    final Widget body;
    if (playerController.isLoadingLyrics) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!lyrics.isSynced && lyrics.plainLyrics.isEmpty) {
      body = Center(
        child: Text(
          l10n.musNoLyricsFoundForThisTrack,
          textAlign: TextAlign.center,
          style: LuText.bodySoft,
        ),
      );
    } else if (lyrics.isSynced) {
      body = ListView.builder(
        itemCount: lyrics.syncedLines.length,
        itemBuilder: (context, index) {
          final line = lyrics.syncedLines[index];
          final isActive = index == activeIndex;
          return LuMediaRow(
            onTap: () => playerController.seekTo(line.timestamp),
            semanticLabel: line.text,
            minHeight: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              line.text,
              style: LuText.body.copyWith(
                fontSize: isActive ? 19 : 16,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? LuColors.gold : LuColors.textMuted,
              ),
            ),
          );
        },
      );
    } else {
      body = SingleChildScrollView(
        child: Text(
          lyrics.plainLyrics,
          style: LuText.body.copyWith(color: LuColors.textSoft, height: 1.7),
        ),
      );
    }

    return _LuDrawerFrame(
      icon: Icons.format_quote_rounded,
      title: l10n.musSyncedLyrics,
      onClose: onClose,
      child: body,
    );
  }
}

class _MusicQueueDrawer extends StatelessWidget {
  final VoidCallback onClose;

  const _MusicQueueDrawer({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final controller = MusicPlayerController.instance;
    final queue = controller.playlist;
    final currentIndex = controller.currentIndex;

    return _LuDrawerFrame(
      icon: Icons.queue_music_rounded,
      title: l10n.mus2QueueCount(queue.length),
      onClose: onClose,
      actions: [
        if (queue.isNotEmpty)
          LuButton(
            label: l10n.musClear,
            kind: LuButtonKind.text,
            onPressed: controller.clearQueue,
          ),
      ],
      child: queue.isEmpty
          ? Center(child: Text(l10n.musQueueIsEmpty, style: LuText.bodySoft))
          : ListView.separated(
              itemCount: queue.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final track = queue[index];
                final isCurrent = index == currentIndex;
                return LuMediaRow(
                  current: isCurrent,
                  semanticLabel: '${track.title}, ${track.artist}',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  onTap: () =>
                      controller.playTrack(track, playlistQueue: queue),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        child: SizedBox.square(
                          dimension: 40,
                          child: LuMediaArt(
                            url: track.coverUrl,
                            cacheWidth: 120,
                          ),
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
                              style: LuText.label.copyWith(
                                color: isCurrent
                                    ? LuColors.gold
                                    : LuColors.text,
                                fontWeight: FontWeight.w700,
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
                      LuMediaIconButton(
                        icon: Icons.close_rounded,
                        tooltip: l10n.musRemoveFromQueueTip,
                        size: 36,
                        quiet: true,
                        iconColor: LuColors.textMuted,
                        onTap: () => controller.removeFromQueue(index),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// The head of an album or playlist modal: the cover, a gold kicker, the
/// title, one line of facts and the actions, with Close at the end.
class _CollectionHead extends StatelessWidget {
  const _CollectionHead({
    required this.title,
    required this.onClose,
    required this.actions,
    this.kicker,
    this.meta,
    this.imageUrl,
    this.icon = Icons.album_rounded,
  });

  final String title;
  final String? kicker;
  final String? meta;
  final String? imageUrl;
  final IconData icon;
  final VoidCallback onClose;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 700;
    final cover = phone ? 88.0 : 132.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          child: SizedBox.square(
            dimension: cover,
            child: imageUrl == null
                ? ColoredBox(
                    color: const Color(0x24F2B544),
                    child: Icon(icon, color: LuColors.gold, size: cover * 0.4),
                  )
                : LuMediaArt(url: imageUrl, cacheWidth: 400, icon: icon),
          ),
        ),
        SizedBox(width: phone ? 14 : 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kicker != null)
                Text(
                  kicker!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuText.label.copyWith(
                    color: LuColors.gold,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LuText.title.copyWith(
                  fontSize: phone ? 20 : 28,
                  height: 1.2,
                ),
              ),
              if (meta != null) ...[
                const SizedBox(height: 4),
                Text(
                  meta!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuText.caption,
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: LuSpace.m),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        _CloseButton(onTap: onClose, autofocus: actions.isEmpty),
      ],
    );
  }
}

class _MusicArtistDetailModal extends StatelessWidget {
  final MusicArtistDetails details;
  final VoidCallback onClose;
  final Function(MusicTrack, List<MusicTrack>) onPlayTrack;
  final Function(MusicTrack) onAddToPlaylist;
  final Function(String) onOpenAlbum;

  const _MusicArtistDetailModal({
    required this.details,
    required this.onClose,
    required this.onPlayTrack,
    required this.onAddToPlaylist,
    required this.onOpenAlbum,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final artist = details.artist;
    final phone = MediaQuery.sizeOf(context).width < 700;

    return _LuModalFrame(
      onClose: onClose,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: phone ? 170 : 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LuMediaArt(
                  url: artist.pictureUrl,
                  cacheWidth: 900,
                  icon: Icons.person_rounded,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x330A0A0C), LuColors.surface],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _CloseButton(
                    onTap: onClose,
                    autofocus: details.topTracks.isEmpty,
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 16,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        artist.name,
                        style: LuText.title.copyWith(fontSize: phone ? 26 : 34),
                      ),
                      if (details.topTracks.isNotEmpty)
                        LuButton(
                          label: l10n.musPlayAll,
                          icon: Icons.play_arrow_rounded,
                          compact: true,
                          autofocus: true,
                          onPressed: () => onPlayTrack(
                            details.topTracks.first,
                            details.topTracks,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (details.topTracks.isNotEmpty) ...[
                  Text(l10n.musTopSongs, style: LuText.heading),
                  const SizedBox(height: LuSpace.m),
                  for (
                    var index = 0;
                    index < details.topTracks.length.clamp(0, 10);
                    index++
                  )
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _MusicTrackRow(
                        track: details.topTracks[index],
                        index: index,
                        isPlaying: false,
                        isCurrent: false,
                        onTap: () => onPlayTrack(
                          details.topTracks[index],
                          details.topTracks,
                        ),
                        onMoreTap: () =>
                            onAddToPlaylist(details.topTracks[index]),
                      ),
                    ),
                  const SizedBox(height: LuSpace.l),
                ],
                if (details.albums.isNotEmpty) ...[
                  Text(l10n.musAlbumsDiscography, style: LuText.heading),
                  const SizedBox(height: LuSpace.m),
                  SizedBox(
                    height:
                        LuMediaCover.heightFor(
                          140,
                          MediaQuery.textScalerOf(context),
                        ) +
                        12,
                    child: FocusTraversalGroup(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: details.albums.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final album = details.albums[index];
                          return LuMediaCover(
                            width: 140,
                            title: album.title,
                            subtitle: album.artistName,
                            imageUrl: album.coverUrl,
                            icon: Icons.album_rounded,
                            onTap: () => onOpenAlbum(album.id),
                          );
                        },
                      ),
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
}

/// A tracklist under a collection head.
class _TrackList extends StatelessWidget {
  const _TrackList({
    required this.tracks,
    required this.onPlayTrack,
    required this.onAddToPlaylist,
  });

  final List<MusicTrack> tracks;
  final Function(MusicTrack, List<MusicTrack>) onPlayTrack;
  final Function(MusicTrack) onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerController.instance;
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isCurrent = player.currentTrack?.id == track.id;
        return _MusicTrackRow(
          track: track,
          index: index,
          isPlaying: isCurrent && player.isPlaying,
          isCurrent: isCurrent,
          onTap: () => onPlayTrack(track, tracks),
          onMoreTap: () => onAddToPlaylist(track),
        );
      },
    );
  }
}

class _MusicAlbumDetailModal extends StatelessWidget {
  final MusicAlbumDetails details;
  final VoidCallback onClose;
  final Function(MusicTrack, List<MusicTrack>) onPlayTrack;
  final Function(MusicTrack) onAddToPlaylist;

  const _MusicAlbumDetailModal({
    required this.details,
    required this.onClose,
    required this.onPlayTrack,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final album = details.album;
    final tracks = details.tracks;

    // The only truthful Hi-Res claim available: the player's own quality
    // label, and only while this album is the one playing.
    final player = MusicPlayerController.instance;
    final playingThisAlbum =
        album.id.isNotEmpty && player.currentTrack?.albumId == album.id;
    final albumKicker = playingThisAlbum
        ? (player.isCurrentTrackLossless
              ? l10n.musHiResLossless(player.currentQualityLabel)
              : player.currentQualityLabel)
        : l10n.musAlbum;

    return _LuModalFrame(
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CollectionHead(
            kicker: albumKicker,
            title: album.title,
            meta: [
              album.artistName,
              l10n.mus2TracksCount(tracks.length),
              if (album.releaseDate.isNotEmpty) album.releaseDate,
            ].join('  ·  '),
            imageUrl: album.coverUrl,
            onClose: onClose,
            actions: [
              if (tracks.isNotEmpty) ...[
                LuButton(
                  label: l10n.musPlayAlbum,
                  icon: Icons.play_arrow_rounded,
                  compact: true,
                  autofocus: true,
                  onPressed: () => onPlayTrack(tracks.first, tracks),
                ),
                LuButton(
                  label: l10n.musDownloadAlbum,
                  kind: LuButtonKind.secondary,
                  icon: Icons.download_rounded,
                  compact: true,
                  onPressed: () {
                    MusicDownloadService.instance.queueTracks(
                      tracks,
                      collectionName: album.title,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10nCurrent().mus2AddedAlbumTracksToQueue(
                            tracks.length,
                            album.title,
                          ),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: LuSpace.l),
          Expanded(
            child: _TrackList(
              tracks: tracks,
              onPlayTrack: onPlayTrack,
              onAddToPlaylist: onAddToPlaylist,
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicCuratedPlaylistDetailModal extends StatelessWidget {
  final MusicPlaylistDetails details;
  final VoidCallback onClose;
  final Function(MusicTrack, List<MusicTrack>) onPlayTrack;
  final Function(MusicTrack) onAddToPlaylist;

  const _MusicCuratedPlaylistDetailModal({
    required this.details,
    required this.onClose,
    required this.onPlayTrack,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final playlist = details.playlist;
    final tracks = details.tracks;

    return _LuModalFrame(
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CollectionHead(
            title: playlist.title,
            meta: l10n.mus2CuratedByTracks(playlist.creatorName, tracks.length),
            imageUrl: playlist.coverUrl,
            icon: Icons.queue_music_rounded,
            onClose: onClose,
            actions: [
              if (tracks.isNotEmpty) ...[
                LuButton(
                  label: l10n.musPlayPlaylist,
                  icon: Icons.play_arrow_rounded,
                  compact: true,
                  autofocus: true,
                  onPressed: () => onPlayTrack(tracks.first, tracks),
                ),
                LuButton(
                  label: l10n.musDownloadPlaylist,
                  kind: LuButtonKind.secondary,
                  icon: Icons.download_rounded,
                  compact: true,
                  onPressed: () {
                    MusicDownloadService.instance.queueTracks(
                      tracks,
                      collectionName: playlist.title,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10nCurrent().mus2AddedPlaylistTracksToQueue(
                            tracks.length,
                            playlist.title,
                          ),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: LuSpace.l),
          Expanded(
            child: _TrackList(
              tracks: tracks,
              onPlayTrack: onPlayTrack,
              onAddToPlaylist: onAddToPlaylist,
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicUserPlaylistDetailModal extends StatelessWidget {
  final UserPlaylist playlist;
  final VoidCallback onClose;
  final Function(MusicTrack, List<MusicTrack>) onPlayTrack;
  final Function(String) onRemoveTrack;

  const _MusicUserPlaylistDetailModal({
    required this.playlist,
    required this.onClose,
    required this.onPlayTrack,
    required this.onRemoveTrack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final tracks = playlist.tracks;
    final player = MusicPlayerController.instance;

    return _LuModalFrame(
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CollectionHead(
            title: playlist.title,
            meta: l10n.mus2CustomPlaylistTracks(tracks.length),
            imageUrl: tracks.isNotEmpty ? tracks.first.coverUrl : null,
            icon: Icons.queue_music_rounded,
            onClose: onClose,
            actions: [
              if (tracks.isNotEmpty) ...[
                LuButton(
                  label: l10n.musPlayPlaylist,
                  icon: Icons.play_arrow_rounded,
                  compact: true,
                  autofocus: true,
                  onPressed: () => onPlayTrack(tracks.first, tracks),
                ),
                LuButton(
                  label: l10n.musDownloadAll,
                  kind: LuButtonKind.secondary,
                  icon: Icons.download_rounded,
                  compact: true,
                  onPressed: () {
                    MusicDownloadService.instance.queueTracks(
                      tracks,
                      collectionName: playlist.title,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10nCurrent().mus2AddedPlaylistTracksToQueue(
                            tracks.length,
                            playlist.title,
                          ),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: LuSpace.l),
          Expanded(
            child: tracks.isEmpty
                ? Center(
                    child: Text(
                      l10n.musNoTracksInThisPlaylistYet,
                      style: LuText.bodySoft,
                    ),
                  )
                : ListView.separated(
                    itemCount: tracks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final isCurrent = player.currentTrack?.id == track.id;
                      return LuMediaRow(
                        current: isCurrent,
                        semanticLabel: '${track.title}, ${track.artist}',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        onTap: () => onPlayTrack(track, tracks),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              child: SizedBox.square(
                                dimension: 44,
                                child: LuMediaArt(
                                  url: track.coverUrl,
                                  cacheWidth: 132,
                                ),
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
                                    style: LuText.body.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrent
                                          ? LuColors.gold
                                          : LuColors.text,
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
                            LuMediaIconButton(
                              icon: Icons.delete_outline_rounded,
                              tooltip: l10n.musRemoveFromPlaylistTip,
                              size: 40,
                              quiet: true,
                              iconColor: LuColors.textMuted,
                              onTap: () => onRemoveTrack(track.id),
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
  }
}

class _MusicShortcutsModal extends StatelessWidget {
  final VoidCallback onClose;

  const _MusicShortcutsModal({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final shortcuts = [
      ('Space / K', l10n.musTogglePlayPause),
      ('J', l10n.musSeek5SecondsBackward),
      ('L', l10n.musSeek5SecondsForward),
      ('M', l10n.musToggleMuteUnmute),
      ('Q', l10n.musToggleQueueDrawer),
      ('F', l10n.musToggleFullscreenNowPlaying),
      ('? / Shift + /', l10n.musShowShortcuts),
    ];

    return _LuModalFrame(
      onClose: onClose,
      maxWidth: 460,
      shrinkWrap: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.keyboard_rounded, color: LuColors.gold),
              const SizedBox(width: LuSpace.s),
              Expanded(
                child: Text(l10n.musKeyboardShortcuts, style: LuText.heading),
              ),
              _CloseButton(onTap: onClose),
            ],
          ),
          const SizedBox(height: LuSpace.l),
          for (final (key, desc) in shortcuts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LuColors.surfaceHigh,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      border: Border.all(color: LuColors.line),
                    ),
                    child: Text(
                      key,
                      style: LuText.caption.copyWith(
                        color: LuColors.gold,
                        fontFamily: LuFonts.display,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: LuSpace.m),
                  Expanded(
                    child: Text(
                      desc,
                      textAlign: TextAlign.end,
                      style: LuText.label,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MusicDownloadedTracksModal extends StatefulWidget {
  final VoidCallback onClose;
  final Function(MusicTrack, List<MusicTrack>) onPlayTrack;
  final Function(MusicTrack) onAddToPlaylist;

  const _MusicDownloadedTracksModal({
    required this.onClose,
    required this.onPlayTrack,
    required this.onAddToPlaylist,
  });

  @override
  State<_MusicDownloadedTracksModal> createState() =>
      _MusicDownloadedTracksModalState();
}

class _MusicDownloadedTracksModalState
    extends State<_MusicDownloadedTracksModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final downloadService = MusicDownloadService.instance;
    final allDownloaded = downloadService.downloadedTracks;
    final queue = downloadService.queue;
    final totalBytes = downloadService.totalDownloadedSizeBytes;
    final sizeMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

    final q = _searchQuery.toLowerCase();
    final filtered = _searchQuery.isEmpty
        ? allDownloaded
        : allDownloaded
              .where(
                (t) =>
                    t.title.toLowerCase().contains(q) ||
                    t.artist.toLowerCase().contains(q) ||
                    t.album.toLowerCase().contains(q),
              )
              .toList();

    final phone = MediaQuery.sizeOf(context).width < 700;

    return _LuModalFrame(
      onClose: widget.onClose,
      maxWidth: 780,
      heightFactor: 0.9,
      maxHeight: 700,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconSquare(
                icon: Icons.offline_pin_rounded,
                size: phone ? 48 : 56,
              ),
              const SizedBox(width: LuSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.musDownloadedSongs, style: LuText.heading),
                    Text(
                      l10n.mus2OfflineTracksStorage(
                        allDownloaded.length,
                        sizeMb,
                      ),
                      style: LuText.caption,
                    ),
                  ],
                ),
              ),
              _CloseButton(onTap: widget.onClose),
            ],
          ),
          const SizedBox(height: LuSpace.m),
          if (queue.isNotEmpty) ...[
            _buildQueueBanner(queue, downloadService),
            const SizedBox(height: LuSpace.m),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (filtered.isNotEmpty) ...[
                LuButton(
                  label: l10n.musPlayAll,
                  icon: Icons.play_arrow_rounded,
                  compact: true,
                  onPressed: () {
                    final tracks = filtered
                        .map((d) => d.toMusicTrack())
                        .toList();
                    widget.onPlayTrack(tracks.first, tracks);
                  },
                ),
                LuButton(
                  label: l10n.musShuffle,
                  kind: LuButtonKind.secondary,
                  icon: Icons.shuffle_rounded,
                  compact: true,
                  onPressed: () {
                    final tracks =
                        filtered.map((d) => d.toMusicTrack()).toList()
                          ..shuffle();
                    widget.onPlayTrack(tracks.first, tracks);
                  },
                ),
              ],
              SizedBox(
                width: phone ? 220 : 260,
                height: 44,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: LuText.label.copyWith(color: LuColors.text),
                  decoration: InputDecoration(
                    hintText: l10n.musSearchOffline,
                    hintStyle: LuText.label.copyWith(
                      color: const Color(0xFF77736B),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: LuColors.textMuted,
                      size: 18,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: const OutlineInputBorder(
                      borderRadius: LuRadius.pill,
                      borderSide: BorderSide(color: LuColors.line),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: LuRadius.pill,
                      borderSide: BorderSide(color: LuColors.line),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: LuRadius.pill,
                      borderSide: BorderSide(color: LuColors.gold, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LuSpace.m),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.cloud_download_rounded,
                          color: LuColors.textFaint,
                          size: 48,
                        ),
                        const SizedBox(height: LuSpace.m),
                        Text(
                          _searchQuery.isNotEmpty
                              ? l10n.mus2NoDownloadedTracksMatch(_searchQuery)
                              : l10n.musNoOfflineDownloadsYetTapThe,
                          textAlign: TextAlign.center,
                          style: LuText.bodySoft,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final track = item.toMusicTrack();
                      final itemSizeMb = (item.fileSizeBytes / (1024 * 1024))
                          .toStringAsFixed(1);
                      final isFlac = item.format.toLowerCase() == 'flac';

                      return LuMediaRow(
                        semanticLabel: '${item.title}, ${item.artist}',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        onTap: () {
                          final allTracks = filtered
                              .map((d) => d.toMusicTrack())
                              .toList();
                          widget.onPlayTrack(track, allTracks);
                        },
                        onLongPress: () => widget.onAddToPlaylist(track),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              child: SizedBox.square(
                                dimension: 46,
                                child: LuMediaArt(
                                  url: track.coverUrl,
                                  filePath: item.localCoverPath,
                                  cacheWidth: 138,
                                ),
                              ),
                            ),
                            const SizedBox(width: LuSpace.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: LuText.body.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${item.artist} · ${item.album}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: LuText.caption,
                                        ),
                                      ),
                                      const SizedBox(width: LuSpace.s),
                                      LuBadge(
                                        isFlac
                                            ? 'FLAC'
                                            : item.format.toUpperCase(),
                                        muted: !isFlac,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$itemSizeMb MB',
                                        style: LuText.caption,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            LuMediaIconButton(
                              icon: Icons.delete_outline_rounded,
                              tooltip: l10n.musDeleteFromDownloads,
                              size: 40,
                              quiet: true,
                              iconColor: LuColors.textMuted,
                              onTap: () async {
                                final confirm = await showLuConfirm(
                                  context,
                                  title: l10nCurrent().musDeleteDownloadedSong,
                                  message: l10nCurrent()
                                      .mus2DeleteFromOfflineStorage(item.title),
                                  confirmLabel: l10nCurrent().musDelete,
                                );
                                if (confirm) {
                                  await downloadService.deleteDownloadedTrack(
                                    item.id,
                                  );
                                  if (mounted) setState(() {});
                                }
                              },
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
  }

  Widget _buildQueueBanner(
    List<MusicDownloadTask> queue,
    MusicDownloadService service,
  ) {
    final l10n = l10nOf(context);
    final activeTask = queue.firstWhere(
      (t) =>
          t.status == MusicDownloadStatus.downloading ||
          t.status == MusicDownloadStatus.extracting,
      orElse: () => queue.first,
    );
    final isExtracting = activeTask.status == MusicDownloadStatus.extracting;
    final progress = activeTask.progress.clamp(0.0, 1.0);

    return LuMediaPanel(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
      radius: LuRadius.field,
      color: LuColors.surfaceHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: isExtracting ? null : progress,
                ),
              ),
              const SizedBox(width: LuSpace.s),
              Expanded(
                child: Text(
                  isExtracting
                      ? l10n.mus2ExtractingStreamFor(activeTask.track.title)
                      : l10n.mus2DownloadingTrackPercent(
                          activeTask.track.title,
                          (progress * 100).toInt(),
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuText.caption.copyWith(color: LuColors.text),
                ),
              ),
              const SizedBox(width: LuSpace.s),
              Text(
                l10n.mus2InQueueCount(queue.length),
                style: LuText.caption.copyWith(color: LuColors.gold),
              ),
              LuMediaIconButton(
                icon: Icons.close_rounded,
                tooltip: l10n.musCancelDownloadTip,
                size: 34,
                quiet: true,
                iconColor: LuColors.textMuted,
                onTap: () => service.cancelTask(activeTask.track.id),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: LuRadius.pill,
            child: LinearProgressIndicator(
              value: isExtracting ? null : progress,
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
