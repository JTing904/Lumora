@Tags(['network'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/services/config/env_service.dart';
import 'package:zplay/services/metadata/localized_meta.dart';
import 'package:zplay/services/settings/locale_settings.dart';

/// AniList's English names and years, as the anime page has them.
void main() {
  test('Chinese name and synopsis for AniList titles', () async {
    SharedPreferences.setMockInitialValues({});
    await EnvService.initialize();
    LocaleSettings.locale.value = const Locale('zh');
    for (final (title, year, series) in [
      ('ONE PIECE', '1999', true),
      ('Cyberpunk: Edgerunners', '2022', true),
      ('Frieren: Beyond Journey’s End', '2023', true),
      ('That Time I Got Reincarnated as a Slime Season 2', '2021', true),
      ('Your Name.', '2016', false),
      ('Cyberpunk: Edgerunners 2', '2026', true),
      ('Mob Psycho 100', '2016', true),
    ]) {
      final t = await LocalizedMeta.textForTitle(
        title,
        year: year,
        series: series,
      );
      // ignore: avoid_print
      print(
        '$title -> ${t?.name} | ${t?.overview?.substring(0, (t.overview!.length).clamp(0, 40))}',
      );
      expect(t?.overview, isNotNull, reason: title);
      expect(t?.name, isNot(contains('日记')), reason: title);
      if (title == 'Your Name.') expect(t?.name, contains('你的名字'));
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
