/// 有新集: how the service reads TMDb's answers and the viewer's record.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/my_list/my_list_item.dart';
import 'package:zplay/services/continue_watching/watched_episodes.dart';
import 'package:zplay/services/metadata/tmdb_service.dart';
import 'package:zplay/services/my_list/my_list_service.dart';
import 'package:zplay/services/my_list/new_episode_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NewEpisodeService.resetForTesting();
    MyListService.items.value = [];
    WatchedEpisodes.shows.value = const {};
  });
  tearDown(() {
    NewEpisodeService.resetForTesting();
    WatchedEpisodes.shows.value = const {};
    TmdbService.buildTimeApiKeyOverrideForTesting = null;
    TmdbService.client = http.Client();
  });

  DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  MyListItem show(int tmdbId, {String? imdbId}) => MyListItem(
    tmdbId: tmdbId,
    imdbId: imdbId,
    title: 'Show $tmdbId',
    type: 'series',
    addedAt: DateTime(2020),
  );

  test('watching under the IMDb id clears a TMDb-only save', () {
    MyListService.items.value = [show(9)];
    NewEpisodeService.seedForTesting(
      9,
      imdbId: 'tt0000009',
      latest: EpisodeRef(
        1,
        2,
        airDate: today().subtract(const Duration(days: 2)),
      ),
    );
    expect(NewEpisodeService.forId('tt0000009')?.isNew, isTrue);
    expect(NewEpisodeService.forId('tmdb:tv:9')?.tmdbId, 9);
    expect(NewEpisodeService.forId('9')?.tmdbId, 9);
    expect(NewEpisodeService.forId('tt404'), isNull);

    WatchedEpisodes.shows.value = {
      'tt0000009': ['1:2'],
    };
    NewEpisodeService.seedForTesting(
      9,
      imdbId: 'tt0000009',
      latest: EpisodeRef(
        1,
        2,
        airDate: today().subtract(const Duration(days: 2)),
      ),
    );
    expect(NewEpisodeService.forId('tt0000009')?.isNew, isFalse);
  });

  test('a cached next episode that has aired counts as the latest', () {
    MyListService.items.value = [show(5)];
    final aired = EpisodeRef(
      1,
      4,
      airDate: today().subtract(const Duration(days: 1)),
    );
    final ahead = EpisodeRef(
      1,
      5,
      airDate: today().add(const Duration(days: 6)),
    );
    NewEpisodeService.seedForTesting(
      5,
      latest: EpisodeRef(
        1,
        3,
        airDate: today().subtract(const Duration(days: 8)),
      ),
      next: aired,
      upcoming: [aired, ahead],
    );
    final info = NewEpisodeService.forId('tmdb:tv:5')!;
    expect(info.latest, aired);
    expect(info.next, ahead);
    expect(info.isNew, isTrue);
  });

  test('a show TMDb no longer has is remembered, not retried', () async {
    MyListService.items.value = [show(1), show(2)];
    final asked = <String>[];
    TmdbService.buildTimeApiKeyOverrideForTesting = 'test-key';
    TmdbService.client = MockClient((request) async {
      asked.add(request.url.path);
      if (request.url.path.endsWith('/tv/1')) {
        return http.Response('{"success":false}', 404);
      }
      expect(request.url.queryParameters['append_to_response'], 'external_ids');
      return http.Response(
        jsonEncode({
          'last_episode_to_air': {
            'season_number': 1,
            'episode_number': 1,
            'air_date': '2021-01-01',
          },
          'external_ids': {'imdb_id': 'tt0000002'},
        }),
        200,
      );
    });

    await NewEpisodeService.refresh();
    expect(asked, ['/3/tv/1', '/3/tv/2']);
    expect(NewEpisodeService.forId('tt0000002')?.tmdbId, 2);
    expect(NewEpisodeService.forId('tmdb:tv:1')?.latest, isNull);

    // Both answers are cached: the next run asks nothing.
    await NewEpisodeService.refresh();
    expect(asked, hasLength(2));
  });

  test('a server error stops the run and backs off', () async {
    MyListService.items.value = [show(1), show(2)];
    final asked = <String>[];
    TmdbService.buildTimeApiKeyOverrideForTesting = 'test-key';
    TmdbService.client = MockClient((request) async {
      asked.add(request.url.path);
      return http.Response('busy', 503);
    });

    await NewEpisodeService.refresh();
    expect(asked, ['/3/tv/1']);
    await NewEpisodeService.refresh();
    expect(asked, hasLength(1));
  });

  test('a failed /find stops the run and backs off', () async {
    MyListService.items.value = [
      MyListItem(
        imdbId: 'tt0000077',
        title: 'IMDb only',
        type: 'series',
        addedAt: DateTime(2020),
      ),
      show(2),
    ];
    final asked = <String>[];
    TmdbService.buildTimeApiKeyOverrideForTesting = 'test-key';
    TmdbService.client = MockClient((request) async {
      asked.add(request.url.path);
      return http.Response('slow down', 429);
    });

    await NewEpisodeService.refresh();
    expect(asked, ['/3/find/tt0000077']);
    await NewEpisodeService.refresh();
    expect(asked, hasLength(1));
  });
}
