import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'lu_theme.dart';

/// The account's photo, or its letter on its chosen colour (see
/// `AccountService`).
class LuAvatar extends StatelessWidget {
  const LuAvatar({
    super.key,
    required this.letter,
    required this.color,
    this.imageUrl,
    this.size = 40,
  });

  final String letter;
  final Color color;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: LuFonts.display,
          fontSize: size * 0.43,
          fontWeight: FontWeight.w700,
          color: LuColors.onGold,
        ),
      ),
    );
    final url = imageUrl;
    if (url == null) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}
