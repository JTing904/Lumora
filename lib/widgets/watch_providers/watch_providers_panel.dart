import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../models/movie/movie_detail.dart';
import '../../services/storage/app_image_cache.dart';
import '../../services/theme/design_tokens.dart';
import '../../services/watch_providers/watch_providers.dart';
import '../../services/watch_providers/watch_providers_service.dart';
import '../common/focusable_card.dart';
import '../player/lu_player_style.dart';

/// "Where to watch" (去哪看): the official services TMDb lists for [detail]
/// in Malaysia (else the device's country), grouped Free / With ads /
/// Subscription / Rent-Buy. Each tile says it opens the service's own app or
/// site, and does exactly that - Lumora plays nothing from these services.
///
/// Draws nothing while loading, when TMDb lists nothing, or on any failure.
class WatchProvidersPanel extends StatefulWidget {
  const WatchProvidersPanel({
    super.key,
    required this.detail,
    required this.type,
    this.padding = EdgeInsets.zero,
    this.service,
  });

  final MovieDetail detail;

  /// The app's type (`movie`, `series` ...).
  final String type;
  final EdgeInsets padding;

  /// Stands in for [WatchProvidersService.instance] in tests.
  final WatchProvidersService? service;

  @override
  State<WatchProvidersPanel> createState() => _WatchProvidersPanelState();
}

class _WatchProvidersPanelState extends State<WatchProvidersPanel> {
  late Future<RegionWatchProviders?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(WatchProvidersPanel old) {
    super.didUpdateWidget(old);
    if (old.detail.id != widget.detail.id || old.type != widget.type) {
      _future = _load();
    }
  }

  Future<RegionWatchProviders?> _load() =>
      (widget.service ?? WatchProvidersService.instance).forTitle(
        id: widget.detail.id,
        type: widget.type,
        tmdbId: widget.detail.tmdbId,
      );

  /// The name a service's search is asked for.
  String get _searchTitle {
    final local = widget.detail.localName;
    return (local != null && local.trim().isNotEmpty)
        ? local
        : widget.detail.name;
  }

  Future<void> _open(WatchProvider provider, RegionWatchProviders data) async {
    final l10n = l10nOf(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final link = WatchProviderLinks.forProvider(
      provider,
      title: _searchTitle,
      tmdbLink: data.tmdbLink,
    );
    var opened = false;
    if (link != null) {
      try {
        opened = await launchUrl(
          link.uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        opened = false;
      }
    }
    if (!opened) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.wtwOpenFailed(provider.name))),
      );
    }
  }

  Future<void> _openTmdb(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RegionWatchProviders?>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null || data.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: widget.padding,
          child: _buildPanel(context, data),
        );
      },
    );
  }

  Widget _buildPanel(BuildContext context, RegionWatchProviders data) {
    final l10n = l10nOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ZplaySpacing.s12),
      decoration: BoxDecoration(
        color: luTokens.surface.withValues(alpha: 0.7),
        borderRadius: ZplayRadius.mdAll,
        border: Border.all(
          color: luTokens.textPrimary.withValues(
            alpha: ZplayOpacity.borderSubtle,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.live_tv_rounded, size: 18, color: luTokens.accent),
              const SizedBox(width: ZplaySpacing.s8),
              Expanded(
                child: Text(
                  l10n.wtwTitle(data.region),
                  style: ZplayType.label
                      .copyWith(weight: FontWeight.w700)
                      .toStyle(color: luTokens.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZplaySpacing.s4),
          Text(
            l10n.wtwOpensOtherApp,
            style: ZplayType.caption.toStyle(color: luTokens.textMuted),
          ),
          for (final kind in WatchOfferKind.values)
            if ((data.groups[kind] ?? const []).isNotEmpty) ...[
              const SizedBox(height: ZplaySpacing.s12),
              Text(
                _kindLabel(kind, l10n),
                style: ZplayType.caption
                    .copyWith(weight: FontWeight.w700)
                    .toStyle(color: _kindColor(kind)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: ZplaySpacing.s8,
                runSpacing: ZplaySpacing.s8,
                children: [
                  for (final p in data.groups[kind]!)
                    _ProviderTile(
                      provider: p,
                      label: l10n.wtwWatchOn(p.name),
                      semantics: l10n.wtwOpensApp(p.name),
                      onTap: () => _open(p, data),
                    ),
                ],
              ),
            ],
          const SizedBox(height: ZplaySpacing.s12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: ZplaySpacing.s12,
            runSpacing: ZplaySpacing.s4,
            children: [
              if (data.tmdbLink != null)
                FocusableCard(
                  onTap: () => _openTmdb(data.tmdbLink!),
                  builder: (context, state) => CardFocusRing(
                    focused: state.focused,
                    radius: ZplayRadius.smAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.wtwMoreOnTmdb,
                            style: ZplayType.caption.toStyle(
                              color: state.highlighted
                                  ? luTokens.textPrimary
                                  : luTokens.accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 12,
                            color: luTokens.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Text(
                l10n.wtwAttribution,
                style: ZplayType.caption.toStyle(color: luTokens.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _kindLabel(WatchOfferKind kind, AppLocalizations l10n) =>
      switch (kind) {
        WatchOfferKind.free => l10n.wtwFree,
        WatchOfferKind.ads => l10n.wtwAds,
        WatchOfferKind.subscription => l10n.wtwSubscription,
        WatchOfferKind.rentBuy => l10n.wtwRentBuy,
      };

  static Color _kindColor(WatchOfferKind kind) => switch (kind) {
    WatchOfferKind.free => luTokens.success,
    WatchOfferKind.ads => luTokens.info,
    WatchOfferKind.subscription => luTokens.textSecondary,
    WatchOfferKind.rentBuy => luTokens.textSecondary,
  };
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.label,
    required this.semantics,
    required this.onTap,
  });

  final WatchProvider provider;
  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final logo = provider.logoUrl();
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Tooltip(
        message: semantics,
        child: FocusableCard(
          onTap: onTap,
          builder: (context, state) => CardFocusRing(
            focused: state.focused,
            radius: ZplayRadius.smAll,
            child: AnimatedContainer(
              duration: ZplayMotion.fast,
              padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
              decoration: BoxDecoration(
                color: state.highlighted
                    ? luTokens.surfaceRaised
                    : luTokens.surface,
                borderRadius: ZplayRadius.smAll,
                border: Border.all(
                  color: luTokens.textPrimary.withValues(
                    alpha: ZplayOpacity.borderMedium,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: logo == null
                          ? _fallback()
                          : CachedNetworkImage(
                              imageUrl: logo,
                              cacheManager: AppImageCache.manager,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => _fallback(),
                              placeholder: (_, _) => _fallback(),
                            ),
                    ),
                  ),
                  const SizedBox(width: ZplaySpacing.s8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZplayType.caption
                          .copyWith(weight: FontWeight.w600)
                          .toStyle(color: luTokens.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: luTokens.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback() => ColoredBox(
    color: luTokens.surfaceRaised,
    child: Center(
      child: Text(
        provider.name.isEmpty ? '?' : provider.name.characters.first,
        style: ZplayType.caption.toStyle(color: luTokens.textSecondary),
      ),
    ),
  );
}
