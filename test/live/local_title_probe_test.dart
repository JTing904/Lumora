@Tags(['network'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/services/config/env_service.dart';
import 'package:zplay/services/metadata/localized_meta.dart';
import 'package:zplay/services/metadata/tmdb_service.dart';
import 'package:zplay/services/settings/locale_settings.dart';

void main() {
  test(
    'Chinese names for a burst of titles',
    () async {
      SharedPreferences.setMockInitialValues({});
      await EnvService.initialize();
      LocaleSettings.locale.value = const Locale('zh');
      final sw = Stopwatch()..start();
      final one =
          await TmdbService.getScraperJson('/find/tt5950044', {
            'external_source': 'imdb_id',
            'language': 'zh-CN',
          }).timeout(
            const Duration(seconds: 10),
            onTimeout: () => {'timeout': true},
          );
      // ignore: avoid_print
      print(
        'direct ${sw.elapsedMilliseconds} ms: ${one?.keys} key=${TmdbService.hasScraperKey}',
      );
      for (final id in ['tt5950044', 'tt6262770']) {
        sw.reset();
        final t = await LocalizedMeta.forImdbId(id, series: false).timeout(
          const Duration(seconds: 20),
          onTimeout: () => const LocalText(name: 'TIMEOUT'),
        );
        // ignore: avoid_print
        print('seq $id ${sw.elapsedMilliseconds} ms: ${t?.name}');
      }
      const ids = [
        'tt5950044',
        'tt6262770',
        'tt0099674',
        'tt0111161',
        'tt0068646',
      ];
      final names = await Future.wait([
        for (final id in ids) LocalizedMeta.forImdbId(id, series: false),
        for (final id in ids) LocalizedMeta.forImdbId(id, series: false),
      ]);
      // ignore: avoid_print
      print(names.map((n) => n?.name).toList());
      expect(names.where((n) => n?.name != null).length, ids.length * 2);
    },
    skip: 'network',
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
