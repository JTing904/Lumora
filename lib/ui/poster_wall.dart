import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/metadata/tmdb_catalog.dart';
import '../services/storage/app_image_cache.dart';
import 'lu_theme.dart';

/// A tilted wall of this week's posters, dimmed, behind the sign-in card.
///
/// The posters are TMDb's trending titles; without a TMDb key or a network
/// the wall stays the plain ground, and the page still reads.
class PosterWall extends StatefulWidget {
  const PosterWall({super.key, this.columns = 10, this.opacity = 0.34});

  final int columns;
  final double opacity;

  @override
  State<PosterWall> createState() => _PosterWallState();
}

class _PosterWallState extends State<PosterWall> {
  List<String> _posters = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await TmdbCatalog.row(
        const TmdbQuery('/trending/all/week'),
        limit: 20,
        resolveImdb: false,
      );
      final posters = [
        for (final m in rows)
          if (m.poster != null && m.poster!.isNotEmpty) m.poster!,
      ];
      if (mounted && posters.isNotEmpty) setState(() => _posters = posters);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_posters.isEmpty) return const SizedBox.expand();
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, c) {
          // Wider and taller than the page, so the tilt never shows an edge.
          final w = c.maxWidth * 1.35;
          final cell = (w - (widget.columns - 1) * 18) / widget.columns;
          final rows = ((c.maxHeight * 1.6) / (cell * 1.5 + 18)).ceil();
          return OverflowBox(
            maxWidth: w,
            maxHeight: c.maxHeight * 1.6,
            child: Transform.rotate(
              angle: -0.157,
              child: Opacity(
                opacity: widget.opacity,
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    for (var i = 0; i < rows * widget.columns; i++)
                      ClipRRect(
                        borderRadius: LuRadius.poster,
                        child: SizedBox(
                          width: cell,
                          height: cell * 1.5,
                          child: CachedNetworkImage(
                            imageUrl:
                                _posters[(i * 3 + i ~/ widget.columns) %
                                    _posters.length],
                            cacheManager: AppImageCache.manager,
                            memCacheWidth: 240,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 600),
                            errorWidget: (_, __, ___) =>
                                const ColoredBox(color: LuColors.surfaceHigh),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
