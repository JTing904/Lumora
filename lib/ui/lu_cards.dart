import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/layout/form_factor.dart';
import '../services/storage/app_image_cache.dart';
import '../widgets/common/local_title_text.dart';
import 'lu_confirm.dart';
import 'lu_focusable.dart';
import 'lu_theme.dart';

/// A picture from the network, or the ground with [fallback] while there is
/// none.
class LuImage extends StatelessWidget {
  const LuImage({
    super.key,
    required this.url,
    this.cacheWidth = 400,
    this.fallback,
  });

  final String? url;
  final int cacheWidth;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final blank = ColoredBox(
      color: LuColors.surfaceHigh,
      child: Center(child: fallback),
    );
    final u = url;
    if (u == null || u.isEmpty) return blank;
    return CachedNetworkImage(
      imageUrl: u,
      cacheManager: AppImageCache.manager,
      memCacheWidth: cacheWidth,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, __) => blank,
      errorWidget: (_, __, ___) => blank,
    );
  }
}

/// A small gold label on a picture: Top 1, 新一季, 热播, 剧集.
class LuBadge extends StatelessWidget {
  const LuBadge(this.text, {super.key, this.muted = false});

  final String text;

  /// Glass instead of gold, for a fact rather than a highlight.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: muted ? const Color(0xB30A0A0C) : LuColors.gold,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Text(
        text,
        style: LuText.caption.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: muted ? LuColors.textSoft : LuColors.onGold,
          height: 1.3,
        ),
      ),
    );
  }
}

/// A title as a 2:3 poster with its name and a line of facts under it.
class LuPosterCard extends StatelessWidget {
  const LuPosterCard({
    super.key,
    required this.title,
    required this.poster,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.rating,
    this.width = 160,
    this.onLongPress,
    this.titleId,
    this.series = false,
  });

  final String title;

  /// The title's IMDb id: with one, the card shows the viewer's-language
  /// name ([LocalTitleText]) once TMDb has it, [title] until then. Cinemeta
  /// and the similar-titles rail carry English names only.
  final String? titleId;

  /// Whether [titleId] is a series, for the TMDb lookup.
  final bool series;
  final String? poster;
  final String? subtitle;
  final String? badge;
  final String? rating;
  final VoidCallback onTap;
  final double width;

  /// The card's second action (Remove...): a long press, a right click, the
  /// menu key or a held Select. See [LuFocusable.onLongPress].
  final VoidCallback? onLongPress;

  /// The card's height: the poster, then two lines of text that grow with
  /// the viewer's text size ([scaler], `MediaQuery.textScalerOf`).
  static double heightFor(
    double width, [
    TextScaler scaler = TextScaler.noScaling,
  ]) => width * 1.5 + 8 + scaler.scale(46);

  static final TextStyle _titleStyle = LuText.body.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: LuFocusable(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: LuRadius.poster,
        semanticLabel: title,
        builder: (context, highlighted) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: LuRadius.poster,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LuImage(
                      url: poster,
                      cacheWidth: (width * 2.5).round(),
                      fallback: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: LuText.label,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Positioned(left: 8, top: 8, child: LuBadge(badge!)),
                    if (rating != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: LuBadge('★ $rating', muted: true),
                      ),
                    AnimatedOpacity(
                      opacity: highlighted ? 1 : 0,
                      duration: LuMotion.focus,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: Color(0x14FFFFFF)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (titleId case final id?)
              LocalTitleText(
                id: id,
                fallback: title,
                series: series,
                year: subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _titleStyle,
              )
            else
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _titleStyle,
              ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.caption,
              ),
          ],
        ),
      ),
    );
  }
}

/// 继续观看: a 16:9 still with the progress along its foot, the title and
/// where the viewer is.
class LuContinueCard extends StatelessWidget {
  const LuContinueCard({
    super.key,
    required this.title,
    required this.image,
    required this.progress,
    required this.caption,
    required this.onTap,
    this.onRemove,
    this.removeLabel,
    this.width = 320,
  });

  final Widget title;
  final String? image;

  /// 0..1.
  final double progress;
  final String caption;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final String? removeLabel;
  final double width;

  /// The card's height: the still, then a line of text that grows with the
  /// viewer's text size ([scaler], `MediaQuery.textScalerOf`).
  static double heightFor(
    double width, [
    TextScaler scaler = TextScaler.noScaling,
  ]) => width * 9 / 16 + 10 + scaler.scale(40);

  /// Remove, asked first: what a long press, a right click, the menu key or a
  /// held Select opens, so every input can remove a title, not just a
  /// pointer hovering the corner button.
  Future<void> _askRemove(BuildContext context) async {
    final remove = onRemove;
    if (remove == null) return;
    final l10n = l10nOf(context);
    final ok = await showLuConfirm(
      context,
      title: removeLabel ?? l10n.cwRemove,
      confirmLabel: l10n.listRemove,
    );
    if (ok) remove();
  }

  @override
  Widget build(BuildContext context) {
    // The corner button is for a pointer; a remote reaches Remove through the
    // card's own second action instead.
    final pointerRemove = onRemove != null && !FormFactorService.hasRemoteInput;
    return SizedBox(
      width: width,
      child: LuFocusable(
        onTap: onTap,
        onLongPress: onRemove == null ? null : () => _askRemove(context),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        builder: (context, highlighted) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LuImage(url: image, cacheWidth: (width * 2).round()),
                    AnimatedOpacity(
                      opacity: highlighted ? 1 : 0,
                      duration: LuMotion.focus,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: Color(0x40000000)),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            size: 52,
                            color: LuColors.gold,
                          ),
                        ),
                      ),
                    ),
                    if (pointerRemove && highlighted)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: ExcludeFocus(
                          child: IconButton(
                            tooltip: removeLabel,
                            onPressed: onRemove,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xB30A0A0C),
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: LuColors.text,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 4,
                        color: const Color(0x40FFFFFF),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: const ColoredBox(color: LuColors.gold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: DefaultTextStyle(
                    style: LuText.body.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title,
                  ),
                ),
                const SizedBox(width: 10),
                Text(caption, style: LuText.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Top 10: the place as a tall outlined numeral the poster leans on.
class LuRankCard extends StatelessWidget {
  const LuRankCard({
    super.key,
    required this.rank,
    required this.title,
    required this.poster,
    required this.onTap,
    this.badge,
    this.posterWidth = 150,
    this.numeralScale = 1,
  });

  final int rank;
  final String title;
  final String? poster;
  final String? badge;
  final VoidCallback onTap;
  final double posterWidth;

  /// The numeral's size as a share of [posterWidth]. A full-size numeral is
  /// the look on a wide screen; a phone shrinks it so the numeral and poster
  /// together leave room for more than two cards across.
  final double numeralScale;

  static double heightFor(double posterWidth) => posterWidth * 1.5;

  @override
  Widget build(BuildContext context) {
    final numeral = posterWidth * numeralScale;
    return LuFocusable(
      onTap: onTap,
      borderRadius: LuRadius.poster,
      semanticLabel: 'Top $rank $title',
      builder: (context, highlighted) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Transform.translate(
            offset: Offset(numeral * 0.12, numeral * 0.08),
            child: Text(
              '$rank',
              style: TextStyle(
                fontFamily: LuFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: numeral,
                height: 0.8,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = numeralScale < 1 ? 1.5 : 2
                  ..color = highlighted
                      ? LuColors.gold
                      : const Color(0xFF5C584F),
              ),
            ),
          ),
          SizedBox(
            width: posterWidth,
            height: posterWidth * 1.5,
            child: ClipRRect(
              borderRadius: LuRadius.poster,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LuImage(url: poster, cacheWidth: (posterWidth * 2.5).round()),
                  if (badge != null)
                    Positioned(left: 8, top: 8, child: LuBadge(badge!)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled row of cards that scrolls sideways, with arrows on a pointer
/// device.
class LuRail extends StatefulWidget {
  const LuRail({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    required this.height,
    this.spacing = 20,
    this.padding = LuSpace.page,
    this.trailing,
  });

  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;
  final double spacing;
  final double padding;
  final Widget? trailing;

  @override
  State<LuRail> createState() => _LuRailState();
}

class _LuRailState extends State<LuRail> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.padding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: LuText.heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?widget.trailing,
            ],
          ),
        ),
        const SizedBox(height: LuSpace.m),
        SizedBox(
          height: widget.height,
          child: LuSideScroll(
            controller: _scroll,
            child: FocusTraversalGroup(
              child: ListView.separated(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: EdgeInsets.symmetric(horizontal: widget.padding),
                itemCount: widget.itemCount,
                separatorBuilder: (_, __) => SizedBox(width: widget.spacing),
                itemBuilder: widget.itemBuilder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A sideways list made usable with a mouse: arrows that page it appear
/// while the pointer is over it (each only while there is more that way),
/// and a mouse can drag it as a finger does. Flutter leaves the mouse out
/// of dragging by default, and a wheel scrolls the page, not the row, so
/// on a computer a row without these could not be moved at all.
class LuSideScroll extends StatefulWidget {
  const LuSideScroll({
    super.key,
    required this.controller,
    required this.child,
    this.arrowAlignment = Alignment.center,
  });

  /// The controller of the horizontal scrollable in [child].
  final ScrollController controller;
  final Widget child;

  /// Where the arrows sit vertically, for a row whose cards are taller than
  /// the art they should be centred on.
  final Alignment arrowAlignment;

  @override
  State<LuSideScroll> createState() => _LuSideScrollState();
}

class _LuSideScrollState extends State<LuSideScroll> {
  bool _hover = false;

  void _page(int dir) {
    final c = widget.controller;
    if (!c.hasClients) return;
    final p = c.position;
    c.animateTo(
      (p.pixels + dir * p.viewportDimension * 0.8).clamp(
        0.0,
        p.maxScrollExtent,
      ),
      duration: LuMotion.page,
      curve: LuMotion.ease,
    );
  }

  bool _canGo(int dir) {
    final c = widget.controller;
    if (!c.hasClients || !c.position.hasContentDimensions) return false;
    final p = c.position;
    return dir < 0 ? p.pixels > 1 : p.pixels < p.maxScrollExtent - 1;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
            child: widget.child,
          ),
          for (final dir in const [-1, 1])
            Positioned(
              left: dir < 0 ? 8 : null,
              right: dir > 0 ? 8 : null,
              top: 0,
              bottom: 0,
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final show = _hover && _canGo(dir);
                  return AnimatedOpacity(
                    opacity: show ? 1 : 0,
                    duration: LuMotion.focus,
                    child: IgnorePointer(
                      ignoring: !show,
                      child: Align(
                        alignment: widget.arrowAlignment,
                        child: ExcludeFocus(
                          child: IconButton(
                            onPressed: () => _page(dir),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xCC0A0A0C),
                              fixedSize: const Size(44, 44),
                            ),
                            icon: Icon(
                              dir < 0
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                              color: LuColors.text,
                            ),
                          ),
                        ),
                      ),
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
