import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/scraper/sites/fsonic.dart';
import 'package:zplay/services/scraper/sites/fsonline.dart';
import 'package:zplay/services/scraper/sites/lookmovie.dart';
import 'package:zplay/services/scraper/sites/purstream.dart';
import 'package:zplay/services/scraper/sites/xdownloader.dart';

/// Each of these sites used to fall back to its first search hit (or any hit
/// from the right year) when the title was not listed, which played a remake,
/// a sequel or an unrelated film. They must now pick the title or nothing.
void main() {
  group('XDownloader picking a search item', () {
    test('rejects a similar title instead of taking the first movie', () {
      final items = [
        {'id': '1', 'type': 'movie', 'title': 'The Bear and the Wild Thing'},
        {'id': '2', 'type': 'tv', 'title': 'The Bear'},
      ];
      expect(XDownloaderScraper.pickItem(items, 'Bear Island', 'movie', null), isNull);
    });

    test('picks the exact title of the right type and year', () {
      final items = [
        {'id': '1', 'type': 'movie', 'title': 'Dune', 'year': 1984},
        {'id': '2', 'type': 'movie', 'title': 'Dune: Part Two', 'year': 2024},
        {'id': '3', 'type': 'movie', 'title': 'Dune', 'year': 2021},
      ];
      expect(XDownloaderScraper.pickItem(items, 'Dune', 'movie', 2021), items[2]);
    });
  });

  group('Purstream picking a search item', () {
    test('rejects a remake from another decade instead of taking the first movie', () {
      final items = [
        {'id': 1, 'type': 'movie', 'title': 'The Lion King', 'release_date': '1994-06-24'},
        {'id': 2, 'type': 'movie', 'title': 'Lion', 'release_date': '2016-11-25'},
      ];
      expect(PurstreamScraper.pickMatch(items, 'The Lion King', 'movie', 2019), isNull);
    });

    test('picks the same-year release of the title', () {
      final items = [
        {'id': 1, 'type': 'movie', 'title': 'The Lion King', 'release_date': '1994-06-24'},
        {'id': 2, 'type': 'tv', 'title': 'The Lion King', 'release_date': '2019-07-19'},
        {'id': 3, 'type': 'movie', 'title': 'The Lion King', 'release_date': '2019-07-19'},
      ];
      expect(PurstreamScraper.pickMatch(items, 'The Lion King', 'movie', 2019), items[2]);
    });
  });

  group('FSOnline picking a search link', () {
    const html = '''
      <a href="https://www3.fsonline.app/film/the-lion-king-1994/">x</a>
      <a href="https://www3.fsonline.app/film/the-lion-king-2019/">x</a>
      <a href="https://www3.fsonline.app/seriale/the-lion-guard-2015/">x</a>
    ''';

    test('rejects a link of the folder whose slug is another title', () {
      expect(FSOnlineScraper.pickLink(html, 'seriale', 'The Lion King', null), isNull);
      expect(FSOnlineScraper.pickLink(html, 'film', 'The Lion King', 2005), isNull);
    });

    test('picks the slug with the title and year', () {
      final m = FSOnlineScraper.pickLink(html, 'film', 'The Lion King', 2019);
      expect(m?.group(2), 'the-lion-king-2019');
    });

    test('accepts a title ending in a number with no year in the slug', () {
      const numbered = '<a href="https://www3.fsonline.app/film/blade-runner-2049/">x</a>';
      final m = FSOnlineScraper.pickLink(numbered, 'film', 'Blade Runner 2049', 2017);
      expect(m?.group(2), 'blade-runner-2049');
    });
  });

  group('FSonic picking a watch link', () {
    test('rejects every link when none names the title', () {
      final links = ['/watch/the-lion-guard-2015-11', '/watch/lion-2016-12'];
      expect(FSonicScraper.pickWatchLink(links, 'The Lion King', 2019), isNull);
    });

    test('picks the title with the right year over a remake', () {
      final links = [
        '/watch/the-lion-guard-2015-11',
        '/watch/the-lion-king-1994-12',
        '/watch/the-lion-king-2019-13',
      ];
      expect(FSonicScraper.pickWatchLink(links, 'The Lion King', 2019), links[2]);
    });
  });

  group('LookMovie picking a search result', () {
    test('rejects a result that only shares the year', () {
      final results = [
        {'title': 'Cats', 'year': 2019, 'slug': 'cats'},
        {'title': 'Joker', 'year': 2019, 'slug': 'joker'},
      ];
      expect(LookMovieScraper.pickResult(results, 'The Lion King', 2019), isNull);
    });

    test('picks the result with the title and the year', () {
      final results = [
        {'title': 'Joker', 'year': 2019, 'slug': 'joker'},
        {'title': 'The Lion King', 'year': 1994, 'slug': 'lion-1994'},
        {'title': 'The Lion King', 'year': 2019, 'slug': 'lion-2019'},
      ];
      expect(LookMovieScraper.pickResult(results, 'The Lion King', 2019), results[2]);
    });
  });
}
