import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/anime/extractors/anidb_extractor.dart';
import 'package:zplay/services/anime/extractors/anihq_extractor.dart';
import 'package:zplay/services/anime/extractors/one_two_three_anime_extractor.dart';

/// These anime sources used to play the first search result (or episode 1)
/// when nothing matched, so a viewer got a different show or episode. They
/// must now pick the requested title and episode, or nothing.
void main() {
  group('123Anime picking search slugs', () {
    test('drops slugs that do not name the title', () {
      const html = '<a href="/anime/one-punch-man">One Punch Man</a>'
          '<a href="/anime/boruto">Boruto</a>';
      expect(OneTwoThreeAnimeExtractor.matchingSlugs(html, ['One Piece']), isEmpty);
    });

    test('puts the exact title before a longer one that contains it', () {
      const html = '<a href="/anime/one-piece-film-red">One Piece Film: Red</a>'
          '<a href="/anime/one-punch-man">One Punch Man</a>'
          '<a href="/anime/one-piece">One Piece</a>';
      expect(
        OneTwoThreeAnimeExtractor.matchingSlugs(html, ['One Piece']),
        ['one-piece', 'one-piece-film-red'],
      );
    });

    test('matches on link text when the slug is not the name', () {
      const html = '<a href="/anime/x7k2"><span>Frieren</span></a>'
          '<a href="/anime/q9z1"><span>Naruto</span></a>';
      expect(OneTwoThreeAnimeExtractor.matchingSlugs(html, ['Frieren']), ['x7k2']);
    });
  });

  group('AniDB picking a search result and episode', () {
    final results = [
      {'id': 'one-punch-man-100', 'title': 'One Punch Man'},
      {'id': 'one-piece-3880', 'title': 'One Piece'},
    ];

    test('returns no result when none names the title', () {
      expect(AniDbExtractor.pickBestResult(results, ['Bleach']), isNull);
    });

    test('picks the result that names the title', () {
      expect(AniDbExtractor.pickBestResult(results, ['One Piece']), 'one-piece-3880');
    });

    test('returns no episode when the number is not listed', () {
      final episodes = [
        AniDbEpisode(number: 1, id: 'a'),
        AniDbEpisode(number: 2, id: 'b'),
      ];
      expect(AniDbExtractor.findEpisode(episodes, 5), isNull);
      expect(AniDbExtractor.findEpisode(episodes, 2)?.id, 'b');
    });
  });

  group('AniHQ picking a search link', () {
    const html = '''
      <a href="https://anihq.cc/watch/one-punch-man-episode-3-english-subbed/">x</a>
      <a href="https://anihq.cc/watch/one-piece-episode-3-english-subbed/">x</a>
    ''';

    test('rejects the episode link of another show', () {
      expect(AniHQExtractor.pickSearchLink(html, 'Bleach', 3, 'english-subbed'), isNull);
    });

    test('picks the episode link whose slug names the title', () {
      expect(
        AniHQExtractor.pickSearchLink(html, 'One Piece', 3, 'english-subbed'),
        'https://anihq.cc/watch/one-piece-episode-3-english-subbed/',
      );
    });
  });
}
