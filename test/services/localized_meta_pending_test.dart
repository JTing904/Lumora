import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zplay/services/metadata/localized_meta.dart';
import 'package:zplay/services/metadata/tmdb_service.dart';
import 'package:zplay/services/settings/locale_settings.dart';

void main() {
  late int finds;
  var failFinds = 0;

  setUp(() {
    finds = 0;
    LocalizedMeta.clearCache();
    LocaleSettings.locale.value = const Locale('zh');
    TmdbService.buildTimeApiKeyOverrideForTesting = 'test-key';
    TmdbService.client = MockClient((request) async {
      if (request.url.path.contains('/find/')) {
        finds++;
        if (failFinds > 0) {
          failFinds--;
          return http.Response('busy', 503);
        }
      }
      final path = request.url.path;
      final body = path.contains('/genre/')
          ? {'genres': []}
          : path.endsWith('/credits')
          ? {
              'cast': [
                {
                  'name': '大卫·科伦斯韦特',
                  'original_name': 'David Corenswet',
                  'profile_path': '/dc.jpg',
                },
                {'name': '瑞秋·布罗斯纳安'},
              ],
            }
          : {
              'movie_results': [
                {
                  'id': 1061474,
                  'title': '超人',
                  'overview': '简介',
                  'genre_ids': [],
                },
              ],
            };
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
  });

  test('cards asking at once share one lookup, and it finishes', () async {
    final names = await Future.wait([
      for (var i = 0; i < 4; i++)
        LocalizedMeta.forImdbId('tt5950044', series: false),
    ]).timeout(const Duration(seconds: 5));
    expect(names.map((n) => n?.name), everyElement('超人'));
    expect(finds, 1);
  });

  test('the cast comes from the same TMDb title, in Chinese', () async {
    final cast = await LocalizedMeta.castFor('tt5950044', series: false);
    expect(cast?.map((c) => c.name), ['大卫·科伦斯韦特', '瑞秋·布罗斯纳安']);
    expect(cast?.first.searchName, 'David Corenswet');
    expect(cast?.first.photo, 'https://image.tmdb.org/t/p/w185/dc.jpg');
    expect(cast?.last.photo, isNull);
  });

  test('English asks TMDb for nothing', () async {
    LocaleSettings.locale.value = const Locale('en');
    expect(await LocalizedMeta.castFor('tt5950044', series: false), isNull);
    expect(finds, 0);
  });

  test(
    'a TMDb that did not answer is asked again, not cached as no match',
    () async {
      failFinds = 2; // the first ask and its retry
      expect(await LocalizedMeta.forImdbId('tt5950044', series: false), isNull);
      final again = await LocalizedMeta.forImdbId('tt5950044', series: false);
      expect(again?.name, '超人');
    },
  );
}
