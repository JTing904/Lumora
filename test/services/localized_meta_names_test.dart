import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zplay/services/metadata/localized_meta.dart';
import 'package:zplay/services/metadata/tmdb_service.dart';
import 'package:zplay/services/settings/locale_settings.dart';

void main() {
  setUp(() {
    LocalizedMeta.clearCache();
    LocaleSettings.locale.value = const Locale('zh');
    TmdbService.buildTimeApiKeyOverrideForTesting = 'test-key';
    TmdbService.client = MockClient((request) async {
      final path = request.url.path;
      final language = request.url.queryParameters['language'];
      final Object body;
      if (path.contains('/find/')) {
        body = {
          'tv_results': [
            {'id': 7, 'name': '吞噬星空', 'overview': '简介', 'genre_ids': []},
          ],
        };
      } else if (path.contains('/genre/')) {
        body = {'genres': []};
      } else if (path.endsWith('/search/tv')) {
        body = {
          'results': [
            {
              'id': 1,
              'name': 'Joy of Life',
              'original_name': '庆余年',
              'first_air_date': '2019-11-26',
            },
          ],
        };
      } else if (path.endsWith('/tv/1')) {
        body = language == 'zh-TW'
            ? {'name': '慶餘年', 'overview': '繁體簡介'}
            : {'name': '庆余年', 'overview': '简介', 'original_language': 'zh'};
      } else {
        body = {};
      }
      return http.Response(
        jsonEncode(body),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
  });

  tearDown(() {
    LocaleSettings.locale.value = const Locale('en');
    TmdbService.buildTimeApiKeyOverrideForTesting = null;
    TmdbService.client = http.Client();
    LocalizedMeta.clearCache();
  });

  test('a Chinese title asked by its own name keeps the zh-CN name', () async {
    final name = await LocalizedMeta.forTitle(
      '庆余年',
      year: '2019',
      series: true,
    );
    expect(name, '庆余年', reason: 'zh-TW would have given 慶餘年');
  });

  test('a looked-up name is known without asking again', () async {
    expect(LocalizedMeta.knownName('tt9', series: true), isNull);
    await LocalizedMeta.forImdbId('tt9', series: true);
    expect(LocalizedMeta.knownName('tt9', series: true), '吞噬星空');

    const key = (title: '庆余年', year: '2019');
    expect(
      LocalizedMeta.knownName(
        'tmdb:tv:1',
        title: key.title,
        year: key.year,
        series: true,
      ),
      isNull,
    );
    await LocalizedMeta.forTitle(key.title, year: key.year, series: true);
    expect(
      LocalizedMeta.knownName(
        'tmdb:tv:1',
        title: key.title,
        year: key.year,
        series: true,
      ),
      '庆余年',
    );
  });

  test('nothing is known in English', () async {
    await LocalizedMeta.forImdbId('tt9', series: true);
    LocaleSettings.locale.value = const Locale('en');
    expect(LocalizedMeta.knownName('tt9', series: true), isNull);
  });
}
