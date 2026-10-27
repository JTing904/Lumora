/// The player's chrome is Lumora's cinema palette, fixed: gold accent, warm
/// ink, near-black glass - whatever accent the rest of the app is set to.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/theme/app_theme_service.dart';
import 'package:zplay/ui/lu_theme.dart';
import 'package:zplay/widgets/player/player_glass.dart';

void main() {
  tearDown(
    () => AppThemeService.currentPalette.value =
        AppThemeService.defaultPalette,
  );

  test('the player wears the Lumora palette', () {
    expect(PlayerTheme.accent, LuColors.gold);
    expect(PlayerTheme.ink, LuColors.text);
    expect(PlayerTheme.canvas, const Color(0xFF000000));
  });

  test('and keeps it when the app accent changes', () {
    final other = AppThemeService.palettes.firstWhere(
      (p) => p.id != AppThemeService.defaultPalette.id,
    );
    AppThemeService.currentPalette.value = other;
    expect(PlayerTheme.accent, LuColors.gold);
  });
}
