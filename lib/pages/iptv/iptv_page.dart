import '../../l10n/l10n.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/theme/app_theme_service.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_theme.dart';
import '../../services/theme/design_tokens.dart';
import '../../services/iptv/hardcoded_channels.dart';
import '../../services/iptv/iptv_controller.dart';
import '../../services/iptv/iptv_settings.dart';
import '../../services/iptv/iptv_storage.dart';
import '../../models/iptv/iptv_models.dart';
import '../../services/discord/discord_rpc_service.dart';
import '../../shell/app_shell_scope.dart';
import '../../utils/navigation/route_transitions.dart';
import '../../services/layout/form_factor.dart';
import '../../widgets/common/focusable_card.dart';
import '../../widgets/iptv/iptv_hero_carousel.dart';
import '../../widgets/iptv/iptv_health_badge.dart';
import '../../widgets/iptv/iptv_slider_section.dart';
import '../multinutz/multinutz_page.dart';
import 'iptv_channel_sheet.dart';
import 'iptv_player_page.dart';
import 'iptv_portals_modal.dart';
import 'iptv_search_page.dart';
import 'widgets/live_guide_band.dart';
import '../../services/storage/app_image_cache.dart';

class IptvPage extends StatefulWidget {
  const IptvPage({super.key});

  @override
  State<IptvPage> createState() => _IptvPageState();
}

class _IptvPageState extends State<IptvPage> {
  final IptvController _ctrl = IptvController.instance;
  final ScrollController _scrollController = ScrollController();

  List<HardcodedChannel> _featured = [];
  List<HardcodedChannel> _espnAndCollege = [];
  List<HardcodedChannel> _usSports = [];
  List<HardcodedChannel> _soccer = [];
  List<HardcodedChannel> _combat = [];
  List<HardcodedChannel> _racing = [];
  List<HardcodedChannel> _movies = [];
  List<HardcodedChannel> _news = [];
  List<HardcodedChannel> _arabic = [];
  List<HardcodedChannel> _discovery = [];
  List<HardcodedChannel> _kids = [];
  List<HardcodedChannel> _boxing = [];

  /// Feed health for every Boxing channel, keyed by channel id.
  ///
  /// A fight-night rail exists to answer "which of these has a source that
  /// works?", so each card is judged from what the app already recorded for it
  /// rather than from a check this page would have to run itself: the hits a
  /// previous channel scan verified, the per-portal alive snapshots covering
  /// those stream ids, and the URLs the player has failed to open.
  Map<String, IptvHitHealth> _boxingHealth = const {};

  /// The evidence [_boxingHealth] was resolved from: the stored hits per
  /// channel and the snapshot of each portal they came from. Kept so a failure
  /// arriving later - the dead-URL store bumping its revision - re-resolves
  /// that same evidence instead of re-reading the disk for it.
  final Map<String, List<StoredHit>> _boxingHits = {};
  final Map<String, AliveSnapshot?> _boxingSnapshots = {};

  List<QuickChannel> _quickChannels = [];

  // (No return-slot state: the settings excursion below goes through the
  // shell, and the shell's own back guard returns to the previous slot.)
  @override
  void initState() {
    super.initState();
    DiscordRpcService.instance.setWatchingLiveTv(channelName: 'Live TV');
    IptvSettings.changeNotifier.addListener(_onSettingsChanged);
    AppThemeService.currentPalette.addListener(_onSettingsChanged);
    IptvDeadUrlStore.instance.revision.addListener(_onHealthChanged);
    _ctrl.init();
    _loadQuickChannels();
    _loadSections();
    _loadBoxingHealth();
  }

  Future<void> _loadQuickChannels() async {
    final channels = await IptvQuickChannelStore.load();
    if (!mounted) return;
    setState(() => _quickChannels = channels);
  }

  Future<void> _addQuickChannel(QuickChannel channel) async {
    await IptvQuickChannelStore.add(channel);
    if (!mounted) return;
    setState(() => _quickChannels.add(channel));
  }

  Future<void> _removeQuickChannel(String id) async {
    await IptvQuickChannelStore.remove(id);
    if (!mounted) return;
    setState(() => _quickChannels.removeWhere((c) => c.id == id));
  }

  void _showAddQuickChannelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddQuickChannelDialog(onAdd: _addQuickChannel),
    );
  }

  @override
  void dispose() {
    IptvSettings.changeNotifier.removeListener(_onSettingsChanged);
    AppThemeService.currentPalette.removeListener(_onSettingsChanged);
    IptvDeadUrlStore.instance.revision.removeListener(_onHealthChanged);
    _scrollController.dispose();
    DiscordRpcService.instance.clearToIdle();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _loadSections() {
    _featured = [
      HardcodedChannels.byId('espn_plus') ?? HardcodedChannels.byId('espn')!,
      HardcodedChannels.byId('ncaa_cbb') ?? HardcodedChannels.byId('espn')!,
      HardcodedChannels.byId('ufc')!,
      HardcodedChannels.byId('bein_sports')!,
      HardcodedChannels.byId('champions_league')!,
      HardcodedChannels.byId('f1')!,
      HardcodedChannels.byId('nba')!,
      HardcodedChannels.byId('hbo')!,
    ];
    _espnAndCollege = [
      HardcodedChannels.byId('espn_plus')!,
      HardcodedChannels.byId('espn')!,
      HardcodedChannels.byId('espn2')!,
      HardcodedChannels.byId('espnu')!,
      HardcodedChannels.byId('ncaa_cbb')!,
      HardcodedChannels.byId('ncaa_mens_cbb')!,
      HardcodedChannels.byId('ncaa_womens_cbb')!,
      HardcodedChannels.byId('sec_network')!,
      HardcodedChannels.byId('acc_network')!,
      HardcodedChannels.byId('big_ten_network')!,
      HardcodedChannels.byId('pac_12_network')!,
      HardcodedChannels.byId('espnews')!,
      HardcodedChannels.byId('espn_deportes')!,
      HardcodedChannels.byId('longhorn_network')!,
      HardcodedChannels.byId('bally_sports')!,
    ];
    _usSports = [
      HardcodedChannels.byId('nba')!,
      HardcodedChannels.byId('nfl')!,
      HardcodedChannels.byId('nfl_redzone')!,
      HardcodedChannels.byId('mlb')!,
      HardcodedChannels.byId('nhl')!,
      HardcodedChannels.byId('fox_sports')!,
      HardcodedChannels.byId('cbs_sports')!,
      HardcodedChannels.byId('nbc_sports')!,
      HardcodedChannels.byId('dazn')!,
      HardcodedChannels.byId('eurosport')!,
    ];
    _soccer = HardcodedChannels.byCategory('Soccer');
    _combat = HardcodedChannels.byCategory('Combat');
    _racing = HardcodedChannels.byCategory('Racing');
    _movies = HardcodedChannels.byCategory('Movies');
    _news = HardcodedChannels.byCategory('News');
    _arabic = HardcodedChannels.byCategory('Arabic');
    _discovery = HardcodedChannels.byCategory('Discovery');
    _kids = HardcodedChannels.byCategory('Kids');
    _boxing = HardcodedChannels.byCategory('Boxing');
  }

  void _onHealthChanged() {
    if (!mounted) return;
    setState(_resolveBoxingHealth);
  }

  /// Reads what the app already knows about the Boxing channels' feeds, then
  /// resolves it.
  ///
  /// Runs once per page. Freshness is a function of the clock rather than of a
  /// notification, so a snapshot lapsing from fresh to unknown is picked up by
  /// the next rebuild; the dead-URL store's `revision` covers the other
  /// direction, where an open player reports a failure while this page is alive.
  Future<void> _loadBoxingHealth() async {
    if (_boxing.isEmpty) return;
    final hits = <String, List<StoredHit>>{};
    for (final channel in _boxing) {
      hits[channel.id] = await IptvChannelResultsStore.load(channel.id);
    }
    final snapshots = <String, AliveSnapshot?>{};
    for (final hit in hits.values.expand((list) => list)) {
      final key = _portalKeyOf(hit);
      if (snapshots.containsKey(key)) continue;
      snapshots[key] = await IptvAliveStore.load(key);
    }
    if (!mounted) return;
    setState(() {
      _boxingHits
        ..clear()
        ..addAll(hits);
      _boxingSnapshots
        ..clear()
        ..addAll(snapshots);
      _resolveBoxingHealth();
    });
  }

  /// The key [IptvAliveStore] files a hit's snapshot under. Its snapshots are
  /// per portal credentials, so the hit's portal is rebuilt to look its own
  /// snapshot up; `'Saved'` is the source the channel-results store records for
  /// every hit it persists.
  static String _portalKeyOf(StoredHit hit) => IptvAliveStore.portalKey(
    IptvPortal(
      url: hit.portalUrl,
      username: hit.portalUser,
      password: hit.portalPass,
      source: 'Saved',
    ),
  );

  void _resolveBoxingHealth() {
    final health = <String, IptvHitHealth>{};
    for (final channel in _boxing) {
      final stored = _boxingHits[channel.id] ?? const <StoredHit>[];
      health[channel.id] = IptvHitHealth.ofChannel(
        stored.map(
          (hit) => IptvHitHealth.resolve(
            streamUrl: hit.streamUrl,
            streamId: hit.streamId,
            snapshot: _boxingSnapshots[_portalKeyOf(hit)],
          ),
        ),
      );
    }
    _boxingHealth = health;
  }

  /// The category the guide replaces. Named rather than inlined so the mapping
  /// between the guide and the user's category list is one place to look.
  static const String _guideCategory = 'Premier Live Broadcasts';

  /// The one rail whose cards carry feed health.
  ///
  /// Named for the same reason as [_guideCategory]: the rail and the id the
  /// health map is keyed by are one fact, and this is where they meet. Boxing
  /// is the rail that needs it because a fight night is the case the page
  /// cannot get wrong - the event starts at a fixed time, so a viewer picking a
  /// source is not shopping, they are trying to be watching in five minutes.
  static const String _boxingCategory = 'Boxing';

  Widget _buildLiveGuide(String title, List<HardcodedChannel> channels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ZplaySpacing.s8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: iptvPagePadding(context)),
          child: Text(title, style: LuText.heading),
        ),
        const SizedBox(height: ZplaySpacing.s12),
        LiveGuideBand(
          channels: channels,
          onWatchLive: _watchChannelNow,
          onFindStreams: _openChannel,
        ),
        const SizedBox(height: ZplaySpacing.s24),
      ],
    );
  }

  void _openChannel(HardcodedChannel channel) {
    IptvChannelSheet.show(context, channel);
  }

  void _watchChannelNow(HardcodedChannel channel) async {
    // If we have saved hits, launch immediately, otherwise open sheet to scan
    final results = _ctrl.channelResults;
    if (_ctrl.activeHardcoded?.id == channel.id && results.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IptvPlayerPage(
            channel: channel,
            hits: results,
            initialHitIndex: 0,
          ),
        ),
      );
    } else {
      IptvChannelSheet.show(context, channel);
    }
  }

  /// Settings is a shell slot now, so this switches the shell instead of pushing
  /// a route that would stack a second navigation model above it. The lookup is
  /// nullable because widget tests and entity routes mount this page outside the
  /// shell, where the no-op is the correct outcome.
  void _navigateToSettings() {
    AppShellScope.of(context)?.go(ShellSlot.settings);
  }

  void _navigateToSearch(Offset? tapPosition) {
    Navigator.push(
      context,
      LiquidRevealRoute(
        page: IptvSearchPage(quickChannels: _quickChannels),
        tapPosition: tapPosition,
      ),
    );
  }

  void _navigateToMultiStreams(Offset? tapPosition) {
    Navigator.push(
      context,
      LiquidRevealRoute(page: const MultiNutzPage(), tapPosition: tapPosition),
    );
  }

  /// A category's name in the viewer's language. The stored keys stay the
  /// English names the user's order and visibility are saved under.
  static String _categoryTitle(AppLocalizations l10n, String key) =>
      switch (key) {
        'Premier Live Broadcasts' => l10n.liveCatPremier,
        'ESPN & College Basketball (NCAA)' => l10n.liveCatEspn,
        'US Major Leagues & Sports' => l10n.liveCatUsSports,
        'Global Football & Soccer' => l10n.liveCatSoccer,
        'Boxing' => l10n.liveCatBoxing,
        'Combat & Martial Arts' => l10n.liveCatCombat,
        'Motorsport & Racing' => l10n.liveCatRacing,
        'Movies & Premium Networks' => l10n.liveCatMovies,
        '24/7 Global News Networks' => l10n.liveCatNews,
        'Arabic & Regional Hub' => l10n.liveCatArabic,
        'Discovery & Documentaries' => l10n.liveCatDiscovery,
        'Kids & Family' => l10n.liveCatKids,
        'US Region' => l10n.liveCatUs,
        'UK Region' => l10n.liveCatUk,
        'Canada Region' => l10n.liveCatCanada,
        'Bay Area' => l10n.liveCatBayArea,
        'International Sports' => l10n.liveCatIntlSports,
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final size = MediaQuery.sizeOf(context);
    final phone = size.width < 600;
    final tv = FormFactorService.of(context) == FormFactor.television;
    final pad = phone ? 16.0 : (tv ? 48.0 : LuSpace.page);
    // The strip the shell's blended nav rests on, charged to this page as its
    // top padding.
    final topPadding = MediaQuery.paddingOf(context).top;
    final spotlightEnabled = IptvSettings.enableSpotlight.value;
    final visibleCategories = IptvSettings.visibleCategories.value;

    final Map<String, (String, List<HardcodedChannel>)> categoryMap = {
      'Premier Live Broadcasts': (l10n.tvDescPremier, _featured),
      'ESPN & College Basketball (NCAA)': (
        'ESPN+, ESPN, ESPN2, ESPNU, NCAA Men\'s & Women\'s CBB, SEC & ACC',
        _espnAndCollege,
      ),
      'US Major Leagues & Sports': (
        'NBA TV, NFL Network, RedZone, MLB, NHL, Fox Sports & CBS Sports',
        _usSports,
      ),
      'Global Football & Soccer': (
        'UEFA Champions League, Premier League, beIN Sports, La Liga & Serie A',
        _soccer,
      ),
      'Boxing': (l10n.tvDescBoxing, _boxing),
      'Combat & Martial Arts': (
        'UFC Fight Pass, WWE, AEW, World Boxing & PPV',
        _combat,
      ),
      'Motorsport & Racing': (
        'Formula 1, MotoGP, NASCAR Cup, IndyCar & Rally WRC',
        _racing,
      ),
      'Movies & Premium Networks': (
        'HBO, Showtime, Starz, Cinemax, Paramount & AMC',
        _movies,
      ),
      '24/7 Global News Networks': (
        'CNN, BBC World, Fox News, Sky News, Al Jazeera & Bloomberg',
        _news,
      ),
      'Arabic & Regional Hub': (
        'MBC, Rotana, OSN, Abu Dhabi TV, Dubai TV & Al Arabiya',
        _arabic,
      ),
      'Discovery & Documentaries': (
        'National Geographic, Discovery Channel, History & Animal Planet',
        _discovery,
      ),
      'Kids & Family': (
        'Cartoon Network, Disney Channel, Nickelodeon & Spacetoon',
        _kids,
      ),
      'US Region': (l10n.tvDescUs, HardcodedChannels.byCategory('US')),
      'UK Region': (l10n.tvDescUk, HardcodedChannels.byCategory('UK')),
      'Canada Region': (
        'CBC News, CTV News, TSN Sportsnet, Crave & Global News',
        HardcodedChannels.byCategory('CA'),
      ),
      'Bay Area': (
        'KTVU Fox 2, KPIX 5 CBS, KGO 7 ABC, KRON 4 & NBC Bay Area',
        HardcodedChannels.byCategory('Bay Area'),
      ),
      'International Sports': (
        l10n.tvDescIntlSports,
        HardcodedChannels.byCategory('Int. Sports'),
      ),
    };

    // 直播 and its count, then the page's tools: 多路直播, 片源, 搜索频道
    // and 设置. In the shell's one focus tree, so UP from the content walks
    // through them to the bar by geometry alone.
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        LuButton(
          label: l10n.tvMultiStreams,
          icon: Icons.dashboard_rounded,
          kind: LuButtonKind.secondary,
          compact: true,
          onPressed: () => _navigateToMultiStreams(null),
        ),
        LuButton(
          label: l10n.tvManagePortalsPlaylists,
          icon: Icons.settings_input_antenna_rounded,
          kind: LuButtonKind.secondary,
          compact: true,
          onPressed: () => IptvPortalsModal.show(context),
        ),
        LuButton(
          label: l10n.tvSearchChannels,
          icon: Icons.search_rounded,
          kind: LuButtonKind.secondary,
          compact: true,
          onPressed: () => _navigateToSearch(null),
        ),
        LuButton(
          label: l10n.tvSettings,
          icon: Icons.tune_rounded,
          kind: LuButtonKind.text,
          compact: true,
          onPressed: _navigateToSettings,
        ),
      ],
    );
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.navLiveTv, style: LuText.title.copyWith(fontSize: 34)),
        const SizedBox(height: 4),
        Text(
          '${l10n.liveSubtitle} · ${l10n.tv2ChannelsCountCaps(HardcodedChannels.all.length)}',
          style: LuText.caption.copyWith(color: LuColors.textMuted),
        ),
      ],
    );

    return Theme(
      data: luTheme(),
      child: Scaffold(
        backgroundColor: LuColors.bg,
        body: RefreshIndicator(
          color: LuColors.gold,
          backgroundColor: LuColors.surface,
          onRefresh: () async => _ctrl.scrape(),
          child: ListView(
            controller: _scrollController,
            clipBehavior: Clip.none,
            padding: EdgeInsets.only(
              top: topPadding + (phone ? 16 : 28),
              bottom: 48 + MediaQuery.paddingOf(context).bottom,
            ),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: phone
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          heading,
                          const SizedBox(height: 16),
                          actions,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: heading),
                          const SizedBox(width: 24),
                          Flexible(child: actions),
                        ],
                      ),
              ),
              const SizedBox(height: 28),

              // The spotlight: the premier channels, full width.
              if (spotlightEnabled) ...[
                IptvHeroCarousel(
                  channels: _featured,
                  onWatchNow: _watchChannelNow,
                  onSourcesTap: _openChannel,
                ),
                const SizedBox(height: 20),
              ],

              // The viewer's own quick channels.
              _QuickChannelsSlider(
                channels: _quickChannels,
                onChannelTap: _openChannel,
                onAddTap: _showAddQuickChannelDialog,
                onRemoveTap: _removeQuickChannel,
              ),
              const SizedBox(height: 8),

              // The premier channels are the guide (a channel list beside the
              // selected channel's schedule); every other category is a rail,
              // in the user's own order and visibility.
              for (final catName in visibleCategories)
                if (categoryMap.containsKey(catName) &&
                    categoryMap[catName]!.$2.isNotEmpty)
                  if (catName == _guideCategory)
                    _buildLiveGuide(
                      _categoryTitle(l10n, catName),
                      categoryMap[catName]!.$2,
                    )
                  else
                    IptvSliderSection(
                      title: _categoryTitle(l10n, catName),
                      subtitle: categoryMap[catName]!.$1,
                      channels: categoryMap[catName]!.$2,
                      healthByChannelId: catName == _boxingCategory
                          ? _boxingHealth
                          : null,
                      onChannelTap: _openChannel,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Channels Slider (user-added channels)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickChannelsSlider extends StatefulWidget {
  final List<QuickChannel> channels;
  final Function(HardcodedChannel) onChannelTap;
  final VoidCallback onAddTap;
  final Function(String) onRemoveTap;

  const _QuickChannelsSlider({
    required this.channels,
    required this.onChannelTap,
    required this.onAddTap,
    required this.onRemoveTap,
  });

  @override
  State<_QuickChannelsSlider> createState() => _QuickChannelsSliderState();
}

class _QuickChannelsSliderState extends State<_QuickChannelsSlider> {
  late final ScrollController _scrollController;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  /// Drives the desktop scroll arrows. It was a `final bool` pinned to false,
  /// so the arrows were built at `left: -50` on every frame - off screen and
  /// still focusable, which is a focus target a remote can land on and not see.
  /// They are only built while the pointer is over the row now.
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateButtons);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateButtons() {
    if (!_scrollController.hasClients) return;
    final canLeft = _scrollController.position.pixels > 10;
    final canRight =
        _scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 10;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scroll(double dir) {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final amount = viewport * 0.75 * dir;
    final target = (_scrollController.position.pixels + amount).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: ZplayMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 600
        ? 140.0
        : width < 1000
        ? 160.0
        : 180.0;
    final posterH = cardWidth * 1.35;
    final totalH = posterH + 60;
    final isDesktop =
        !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.macOS ||
            Theme.of(context).platform == TargetPlatform.linux);

    return MouseRegion(
      onEnter: (_) {
        if (isDesktop) setState(() => _isHovering = true);
      },
      onExit: (_) {
        if (isDesktop) setState(() => _isHovering = false);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: iptvPagePadding(context),
          vertical: 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10nCurrent().tvQuickChannels,
                  style: ZplayType.title.toStyle(color: tokens.textPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                  color: tokens.accent,
                  tooltip: l10nCurrent().tvAddQuickChannel,
                  onPressed: widget.onAddTap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: totalH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ZplaySpacing.s4,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.channels.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: ZplaySpacing.s12),
                    itemBuilder: (context, index) {
                      if (index == widget.channels.length) {
                        return SizedBox(
                          width: cardWidth,
                          child: _QuickAddCard(onTap: widget.onAddTap),
                        );
                      }
                      final ch = widget.channels[index];
                      return SizedBox(
                        width: cardWidth,
                        child: _QuickChannelCard(
                          channel: ch,
                          onTap: () {
                            final hc = HardcodedChannel(
                              id: 'qc_${ch.id}',
                              name: ch.name,
                              short: ch.short,
                              category: ch.category,
                              keywords: ch.keywords,
                              gradient: ch.gradient,
                              iconUrl: ch.iconUrl,
                            );
                            widget.onChannelTap(hc);
                          },
                          onRemove: () => widget.onRemoveTap(ch.id),
                        ),
                      );
                    },
                  ),
                  // Desktop scroll arrows
                  if (isDesktop && _isHovering) ...[
                    AnimatedPositioned(
                      duration: ZplayMotion.fast,
                      curve: ZplayMotion.standard,
                      left: _canScrollLeft && _isHovering ? 2 : -50,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: tokens.textEmphasis,
                          ),
                          onPressed: _canScrollLeft ? () => _scroll(-1) : null,
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: ZplayMotion.fast,
                      curve: ZplayMotion.standard,
                      right: _canScrollRight && _isHovering ? 2 : -50,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: tokens.textEmphasis,
                          ),
                          onPressed: _canScrollRight ? () => _scroll(1) : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChannelCard extends StatelessWidget {
  final QuickChannel channel;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QuickChannelCard({
    required this.channel,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FocusableCard(
      onTap: onTap,
      builder: (context, state) => GestureDetector(
        // Pointer-only shortcut: FocusableCard owns tap and activation, not long press.
        onLongPress: onRemove,
        child: CardFocusRing(
          focused: state.focused,
          radius: ZplayRadius.smAll,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: ZplayRadius.smAll,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: channel.gradient,
                  ),
                  // The coloured glow on highlight is gone: it was a blurred
                  // second edge under the card's own focus ring.
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: channel.iconUrl != null
                            ? CachedNetworkImage(
                                imageUrl: channel.iconUrl!,
                                cacheManager: AppImageCache.manager,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) =>
                                    _QuickChannelIcon(channel.short),
                              )
                            : _QuickChannelIcon(channel.short),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.name,
                            style: ZplayType.label.toStyle(
                              color: tokens.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            channel.category,
                            style: ZplayType.caption.toStyle(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Remove button — always visible, and a real focus target: the
              // 20 dp dot this replaces was neither reachable nor pressable
              // from a remote. The disc stays small; the target around it is
              // the form factor's minimum.
              Positioned(
                top: 0,
                right: 0,
                child: FocusableCard(
                  onTap: onRemove,
                  builder: (context, closeState) => CardFocusRing(
                    focused: closeState.focused,
                    radius: ZplayRadius.fullAll,
                    child: SizedBox(
                      width: FormFactorService.of(context) == FormFactor.compact
                          ? 40.0
                          : kMinInteractiveDimension,
                      height:
                          FormFactorService.of(context) == FormFactor.compact
                          ? 40.0
                          : kMinInteractiveDimension,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(ZplaySpacing.s4),
                          decoration: BoxDecoration(
                            color: tokens.danger,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: tokens.textPrimary,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddCard extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickAddCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FocusableCard(
      onTap: onTap,
      builder: (context, state) => CardFocusRing(
        focused: state.focused,
        radius: ZplayRadius.smAll,
        child: Container(
          decoration: BoxDecoration(
            // A resting 2 dp accent border sat here, directly under the focus
            // ring the card draws in the same colour at the same width, so the
            // focused card read as a 4 dp double edge. The fill and the accent
            // glyph carry the affordance; the ring marks the focus.
            borderRadius: ZplayRadius.smAll,
            color: tokens.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: tokens.accent, size: 36),
              const SizedBox(height: 8),
              Text(
                l10nCurrent().tvAddChannel,
                style: ZplayType.label.toStyle(color: tokens.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChannelIcon extends StatelessWidget {
  final String short;
  const _QuickChannelIcon(this.short);

  @override
  Widget build(BuildContext context) {
    return Text(
      short,
      style: ZplayType.titleLarge.toStyle(color: context.tokens.textPrimary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Quick Channel Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _AddQuickChannelDialog extends StatefulWidget {
  final void Function(QuickChannel) onAdd;

  const _AddQuickChannelDialog({required this.onAdd});

  @override
  State<_AddQuickChannelDialog> createState() => _AddQuickChannelDialogState();
}

class _AddQuickChannelDialogState extends State<_AddQuickChannelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _shortCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();

  List<Color> _gradient = [const Color(0xFF7C5CFF), const Color(0xFF1A1A1A)];
  final List<List<Color>> _presetGradients = [
    [const Color(0xFF7C5CFF), const Color(0xFF1A1A1A)],
    [const Color(0xFFCC0000), const Color(0xFF1A1A1A)],
    [const Color(0xFF003366), const Color(0xFF0066CC)],
    [const Color(0xFFD4AF37), const Color(0xFF1A1A1A)],
    [const Color(0xFF00AA00), const Color(0xFF1A1A1A)],
    [const Color(0xFFFF6D00), const Color(0xFF1A1A1A)],
    [const Color(0xFF0066CC), const Color(0xFF003366)],
    [const Color(0xFFCC0000), const Color(0xFF001965)],
  ];

  String _selectedCategory = 'Quick';
  final List<String> _categories = [
    'Quick',
    'US',
    'UK',
    'CA',
    'Bay Area',
    'Sports',
    'News',
    'Movies',
    'Int. Sports',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortCtrl.dispose();
    _keywordsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AlertDialog(
      backgroundColor: tokens.surfaceOverlay,
      shape: const RoundedRectangleBorder(borderRadius: ZplayRadius.mdAll),
      title: Text(
        l10nCurrent().tvAddQuickChannel,
        style: ZplayType.title.toStyle(color: tokens.textPrimary),
      ),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  style: ZplayType.body.toStyle(color: tokens.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10nCurrent().tvChannelName,
                    labelStyle: ZplayType.body.toStyle(
                      color: tokens.textEmphasis,
                    ),
                    border: const UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: tokens.accent),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10nCurrent().tvRequired
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _shortCtrl,
                        style: ZplayType.body.toStyle(
                          color: tokens.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: l10nCurrent().tvShortCodeOptional,
                          labelStyle: ZplayType.body.toStyle(
                            color: tokens.textEmphasis,
                          ),
                          border: const UnderlineInputBorder(),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: tokens.accent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: tokens.surfaceOverlay,
                        style: ZplayType.body.toStyle(
                          color: tokens.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: l10nCurrent().tvCategory,
                          labelStyle: ZplayType.body.toStyle(
                            color: tokens.textEmphasis,
                          ),
                          border: const UnderlineInputBorder(),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: tokens.accent),
                          ),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: ZplayType.body.toStyle(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _keywordsCtrl,
                  style: ZplayType.body.toStyle(color: tokens.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10nCurrent().tvKeywordsCommaSeparated,
                    labelStyle: ZplayType.body.toStyle(
                      color: tokens.textEmphasis,
                    ),
                    hintText: l10nCurrent().tvKeywordsHint,
                    hintStyle: ZplayType.body.toStyle(color: tokens.textMuted),
                    border: const UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: tokens.accent),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10nCurrent().tvRequired
                      : null,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10nCurrent().tvGradient,
                    style: ZplayType.bodySmall.toStyle(
                      color: tokens.textEmphasis,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _presetGradients.map((g) {
                    final isSelected = _gradient == g;
                    return FocusableCard(
                      onTap: () => setState(() => _gradient = g),
                      builder: (context, state) => CardFocusRing(
                        focused: state.focused,
                        radius: ZplayRadius.smAll,
                        child: Container(
                          width:
                              FormFactorService.of(context) ==
                                  FormFactor.compact
                              ? 36
                              : kMinInteractiveDimension,
                          height:
                              FormFactorService.of(context) ==
                                  FormFactor.compact
                              ? 36
                              : kMinInteractiveDimension,
                          decoration: BoxDecoration(
                            borderRadius: ZplayRadius.smAll,
                            gradient: LinearGradient(colors: g),
                            border: Border.all(
                              color: isSelected
                                  ? tokens.accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10nCurrent().tvCancel,
            style: ZplayType.label.toStyle(color: tokens.textEmphasis),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.accent,
            foregroundColor: tokens.onAccent,
            shape: const RoundedRectangleBorder(
              borderRadius: ZplayRadius.smAll,
            ),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
              final shortVal = _shortCtrl.text.trim().isEmpty
                  ? _nameCtrl.text
                        .trim()
                        .substring(
                          0,
                          _nameCtrl.text.trim().length > 3
                              ? 3
                              : _nameCtrl.text.trim().length,
                        )
                        .toUpperCase()
                  : _shortCtrl.text.trim().toUpperCase();
              final channel = QuickChannel(
                id: id,
                name: _nameCtrl.text.trim(),
                short: shortVal,
                category: _selectedCategory,
                keywords: _keywordsCtrl.text
                    .trim()
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
                gradient: _gradient,
              );
              widget.onAdd(channel);
              Navigator.pop(context);
            }
          },
          child: Text(l10nCurrent().tv2Add),
        ),
      ],
    );
  }
}
