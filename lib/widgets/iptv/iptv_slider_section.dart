import 'package:flutter/material.dart';
import '../../services/home/home_page_settings.dart';
import '../../services/iptv/hardcoded_channels.dart';
import '../../services/iptv/iptv_settings.dart';
import '../../services/layout/form_factor.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_theme.dart';
import 'iptv_channel_card.dart';
import 'iptv_health_badge.dart';

class IptvCardSizing {
  final double cardWidth;
  final double posterHeight;
  final double totalHeight;
  final double spacing;
  final double sidePadding;

  const IptvCardSizing({
    required this.cardWidth,
    required this.posterHeight,
    required this.totalHeight,
    required this.spacing,
    required this.sidePadding,
  });

  factory IptvCardSizing.fromWidth(double screenWidth) {
    double cardWidth;
    if (screenWidth < 600) {
      cardWidth = 145;
    } else if (screenWidth < 1000) {
      cardWidth = 165;
    } else if (screenWidth < 1400) {
      cardWidth = 185;
    } else {
      cardWidth = 205;
    }

    final density = IptvSettings.cardDensity.value;
    if (density == CardDensity.compact) {
      cardWidth *= 0.85;
    } else if (density == CardDensity.cinematic) {
      cardWidth *= 1.20;
    }

    final posterHeight = cardWidth * 1.35;
    final totalHeight = posterHeight + 66;

    return IptvCardSizing(
      cardWidth: cardWidth,
      posterHeight: posterHeight,
      totalHeight: totalHeight,
      spacing: 16,
      sidePadding: 18,
    );
  }
}

class IptvSliderSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<HardcodedChannel> channels;
  final Function(HardcodedChannel) onChannelTap;
  final VoidCallback? onSeeAll;

  /// Per-channel feed health keyed by [HardcodedChannel.id], or null for a rail
  /// whose caller has nothing to say about health - in which case no card draws
  /// a badge and the rail is the rail it always was.
  final Map<String, IptvHitHealth>? healthByChannelId;

  const IptvSliderSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.channels,
    required this.onChannelTap,
    this.onSeeAll,
    this.healthByChannelId,
  });

  @override
  State<IptvSliderSection> createState() => _IptvSliderSectionState();
}

class _IptvSliderSectionState extends State<IptvSliderSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.channels.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final sizing = IptvCardSizing.fromWidth(width);
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: LuRail(
        title: widget.title,
        padding: iptvPagePadding(context),
        height: sizing.totalHeight,
        spacing: sizing.spacing,
        itemCount: widget.channels.length,
        itemBuilder: (context, index) {
          final ch = widget.channels[index];
          return SizedBox(
            width: sizing.cardWidth,
            child: IptvChannelCard(
              channel: ch,
              health: widget.healthByChannelId?[ch.id],
              onTap: () => widget.onChannelTap(ch),
            ),
          );
        },
      ),
    );
  }
}

/// The 直播 page's side gutter, the same as every Lumora page's.
double iptvPagePadding(BuildContext context) {
  if (MediaQuery.sizeOf(context).width < 600) return 16;
  return FormFactorService.of(context) == FormFactor.television
      ? 48
      : LuSpace.page;
}
