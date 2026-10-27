import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/scraper/sites/kisskh.dart';
import 'package:zplay/services/scraper/sites/vadapav.dart';
import 'package:zplay/services/scraper/sites/tmdb_helper.dart';

/// KissKH is the reported failure: the search endpoint happily answers a title
/// it has never heard of with a page of unrelated Asian dramas, so accepting
/// "whatever came back first" is how a viewer ends up playing a Korean drama
/// they did not ask for.
void main() {
  group('KissKH picking a drama out of search results', () {
    final unrelated = [
      {'id': '1', 'title': 'Squid Game'},
      {'id': '2', 'title': 'Crash Landing on You'},
    ];

    test('returns nothing when no result names the requested title', () {
      expect(KissKhScraper.pickBestDrama(unrelated, 'The Bear'), isNull);
    });

    test('still accepts the looser match when a title really is a substring', () {
      final results = [
        {'id': '1', 'title': 'Squid Game'},
        {'id': '2', 'title': 'The Bear and the Wild Thing'},
      ];

      expect(KissKhScraper.pickBestDrama(results, 'The Bear'), results[1]);
    });

    test('returns nothing when the result list is empty', () {
      expect(KissKhScraper.pickBestDrama(const [], 'The Bear'), isNull);
    });

    test('ignores malformed entries instead of letting one score', () {
      expect(KissKhScraper.pickBestDrama(['Squid Game', 42], 'The Bear'), isNull);
    });

    test('still picks an exact title match', () {
      final results = [
        {'id': '1', 'title': 'Squid Game'},
        {'id': '2', 'title': 'The Bear'},
      ];

      expect(KissKhScraper.pickBestDrama(results, 'The Bear'), results[1]);
    });

    test('matches across the dash-separated alternate titles a listing carries', () {
      final results = [
        {'id': '1', 'title': 'Squid Game'},
        {'id': '2', 'title': 'The Bear - La Ola'},
      ];

      expect(KissKhScraper.pickBestDrama(results, 'The Bear'), results[1]);
    });

    test('drops the trailing year before comparing', () {
      final results = [
        {'id': '1', 'title': 'Squid Game (2021)'},
        {'id': '2', 'title': 'The Bear (2022)'},
      ];

      expect(KissKhScraper.pickBestDrama(results, 'The Bear (2022)'), results[1]);
    });
  });

  group('KissKH telling same-named animation and live action apart', () {
    // The real search page for "A Mortal's Journey", trimmed.
    final results = [
      {
        'id': 8066,
        'title': "The Immortal Ascension - A Record of a Mortal's Journey to "
            'Immortality (Live Action)',
      },
      {'id': 7905, 'title': 'My Journey to You'},
      {
        'id': 10153,
        'title': "A Record Of Mortal's Journey To Immortality Season 4 - "
            'Fanren Xiu Xian Chuan 4th Season',
      },
      {
        'id': 8415,
        'title': "A Record of Mortal's Journey to Immortality Season 3 - "
            'Fanren Xiu Xian Chuan 3rd Season',
      },
    ];
    const animation = TitleFacts(tmdbId: 106449, isAnimation: true, year: 2020);

    test('the animated seasons are candidates, not only the live action', () {
      final ids = KissKhScraper.rankDramas(results, "A Mortal's Journey")
          .map((d) => d['id']);
      expect(ids, containsAll([8066, 10153, 8415]));
      expect(ids, isNot(contains(7905)));
    });

    test('the requested season ranks first', () {
      final ranked =
          KissKhScraper.rankDramas(results, "A Mortal's Journey", season: 3);
      expect(ranked.first['id'], 8415);
    });

    test('a live-action listing does not fit an animation request', () {
      final live = {'type': 'TVSeries', 'title': results[0]['title']};
      final anime = {'type': 'Anime', 'title': results[2]['title']};
      expect(KissKhScraper.fitsRequest(live, type: 'series', facts: animation),
          isFalse);
      expect(KissKhScraper.fitsRequest(anime, type: 'series', facts: animation),
          isTrue);
    });

    test('an animated listing does not fit a live-action request', () {
      const drama = TitleFacts(tmdbId: 243224, isAnimation: false, year: 2025);
      final anime = {'type': 'Anime', 'title': results[2]['title']};
      expect(KissKhScraper.fitsRequest(anime, type: 'series', facts: drama),
          isFalse);
    });

    test('season tags are read in every form KissKH writes them', () {
      expect(KissKhScraper.seasonOf('X Season 4 - Y'), 4);
      expect(KissKhScraper.seasonOf('X 3rd Season'), 3);
      expect(KissKhScraper.seasonOf('X\n 2th Season'), 2);
      expect(KissKhScraper.seasonOf('X'), isNull);
    });
  });

  group('KissKH and hyphenated film titles', () {
    // What KissKH answered for "Spider-Man: Brand New Day" (trimmed). The
    // 8-episode Spider-Noir series played for the film.
    final results = [
      {'id': '1', 'title': 'New Life Begins'},
      {'id': '2', 'title': 'Spider-Man: No Way Home'},
      {'id': '3', 'title': 'Spider-Noir (2026)'},
      {'id': '4', 'title': 'Spider-Man: Brand New Day (2026)'},
    ];

    test('a hyphen inside a word is not a name separator', () {
      expect(
        KissKhScraper.rankDramas(results, 'Spider-Man: Brand New Day'),
        [results[3]],
      );
    });

    test('a film request rejects a listing with several episodes', () {
      final series = {
        'title': 'Spider-Noir (2026)',
        'type': 'Hollywood',
        'episodes': [{'number': 1}, {'number': 2}],
      };
      expect(KissKhScraper.fitsRequest(series, type: 'movie'), isFalse);
      expect(KissKhScraper.fitsRequest(series, type: 'series'), isTrue);
    });

    test('a year in the listing name has to be the year asked for', () {
      final film = {
        'title': 'Spider-Man (2002)',
        'type': 'Hollywood',
        'episodes': [{'number': 1}],
      };
      expect(KissKhScraper.fitsRequest(film, type: 'movie', year: 2026), isFalse);
      expect(KissKhScraper.fitsRequest(film, type: 'movie', year: 2002), isTrue);
      expect(KissKhScraper.fitsRequest(film, type: 'movie'), isTrue);
    });
  });

  group('Vadapav files are checked against the request', () {
    test('a file for another title is dropped', () {
      expect(
        namesRequest(
          "The Lion King II: Simba's Pride (1998).720p.BluRay.x264.650MB-Pahe.in.mkv",
          "A Record of a Mortal's Journey to Immortality",
          isTv: true,
        ),
        isFalse,
      );
      expect(
        namesRequest(
          'Pride and Glory (2008).720p.BluRay.x264-Pahe.in.mkv',
          'Blossoms Shanghai',
          isTv: true,
        ),
        isFalse,
      );
    });

    test('the right file is kept', () {
      expect(
        namesRequest(
          'Spider-Man.Into.the.Spider-Verse.2018.1080p.BluRay.mkv',
          'Spider-Man: Into the Spider-Verse',
          year: 2018,
          isTv: false,
        ),
        isTrue,
      );
    });

    test('a film file of another year is dropped', () {
      expect(
        namesRequest(
          'Superman.1978.1080p.BluRay.mkv',
          'Superman',
          year: 2025,
          isTv: false,
        ),
        isFalse,
      );
    });
  });
}
