import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/anime_arabic/anime_arabic_service.dart';
import 'package:zplay/services/scraper/sites/tmdb_helper.dart';
import 'package:zplay/services/scraper/title_match.dart';

/// Every source that searches by name must reject a same-named title of the
/// wrong year or kind, and return nothing rather than its first hit.
void main() {
  group('title_match', () {
    test('the same title in another form matches', () {
      expect(titleMatchScore("A Mortal's Journey", 'a mortals journey'), 3);
      expect(titleMatchScore('The Bear (2022)', 'The Bear'), 3);
    });

    test('every significant word present is a weaker match', () {
      expect(
        titleMatchScore(
          "A Mortal's Journey",
          "A Record of Mortal's Journey to Immortality Season 3",
        ),
        2,
      );
    });

    test('a listing that only shares a word is not a match', () {
      expect(titleMatchScore('Journey', 'My Journey to You'), 2);
      expect(titleMatchScore("A Mortal's Journey", 'My Journey to You'), 0);
    });

    test('years more than one apart are different titles', () {
      expect(
        isSameTitle('Dune', 'Dune', wantedYear: 2021, candidateYear: 1984),
        isFalse,
      );
      expect(
        isSameTitle('Dune', 'Dune', wantedYear: 2021, candidateYear: 2021),
        isTrue,
      );
      expect(isSameTitle('Dune', 'Dune', wantedYear: 2021), isTrue);
    });

    test('a series year range still yields its first year', () {
      expect(leadingYear('2020–'), 2020);
      expect(leadingYear('2019-2024'), 2019);
      expect(leadingYear(null), isNull);
      expect(leadingYear('TBA'), isNull);
    });
  });

  group('TMDb title search', () {
    final hits = [
      {
        'id': 243224,
        'name': '凡人修仙传',
        'original_name': '凡人修仙传',
        'first_air_date': '2025-07-27',
      },
      {
        'id': 106449,
        'name': '凡人修仙传',
        'original_name': '凡人修仙传',
        'first_air_date': '2020-07-25',
      },
      {'id': 1, 'name': 'Something Else', 'first_air_date': '2020-01-01'},
    ];

    test('the year picks between two titles of the same name', () {
      expect(TmdbHelper.pickSearchHit(hits, '凡人修仙传', 2020)?['id'], 106449);
      expect(TmdbHelper.pickSearchHit(hits, '凡人修仙传', 2025)?['id'], 243224);
      final english = [
        {
          'id': 243224,
          'name': "A Mortal's Journey",
          'first_air_date': '2025-07-27',
        },
        {
          'id': 106449,
          'name': "A Mortal's Journey",
          'first_air_date': '2020-07-25',
        },
      ];
      expect(
        TmdbHelper.pickSearchHit(english, "A Mortal's Journey", 2020)?['id'],
        106449,
      );
      expect(
        TmdbHelper.pickSearchHit(english, "A Mortal's Journey", 2025)?['id'],
        243224,
      );
    });

    test('nothing that matches means no id, never the first result', () {
      expect(TmdbHelper.pickSearchHit(hits, 'Breaking Bad', 2008), isNull);
    });
  });

  group('AnimeArabic search', () {
    test('picks the result named like the request, not the first', () {
      const results = [
        ArabicAnimeCard(slug: 'naruto', title: 'Naruto'),
        ArabicAnimeCard(slug: 'one-piece', title: 'One Piece'),
      ];
      expect(
        ArabicAnimeCard.bestMatch(results, 'One Piece')?.slug,
        'one-piece',
      );
    });

    test('returns nothing when no result is the request', () {
      const results = [ArabicAnimeCard(slug: 'naruto', title: 'Naruto')];
      expect(ArabicAnimeCard.bestMatch(results, 'Bleach'), isNull);
    });
  });
}
