import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/l10n/generated/app_localizations.dart';
import 'package:zplay/models/continue_watching/continue_watching_item.dart';
import 'package:zplay/models/movie/movie.dart';
import 'package:zplay/widgets/search/search_result_card.dart';

Movie _row(String type) => Movie(
  id: 'tt12879782',
  name: "A Mortal's Journey",
  type: type,
  year: '2020–',
  imdbRating: '8.4',
  addonBaseUrl: 'https://v3-cinemeta.strem.io',
);

Future<void> _pump(WidgetTester tester, Widget child, {Locale? locale}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(child: SizedBox(width: 460, height: 182, child: child)),
        ),
      ),
    );

void main() {
  group('SearchKind.of', () {
    test('TMDb animation wins over the addon type', () {
      expect(SearchKind.of(_row('series'), true), SearchKind.anime);
      expect(SearchKind.of(_row('movie'), true), SearchKind.animeMovie);
    });

    test('live action is only claimed when TMDb said so', () {
      expect(SearchKind.of(_row('series'), false), SearchKind.liveSeries);
      expect(SearchKind.of(_row('series'), null), SearchKind.series);
      expect(SearchKind.of(_row('movie'), null), SearchKind.movie);
    });

    test('an anime addon row is animation without asking', () {
      expect(SearchKind.of(_row('anime'), null), SearchKind.anime);
    });
  });

  testWidgets('the card names the title, its kind and its year', (
    tester,
  ) async {
    await _pump(
      tester,
      SearchResultCard(movie: _row('series'), kind: SearchKind.anime),
    );
    expect(find.text("A Mortal's Journey"), findsOneWidget);
    expect(find.text('Animation'), findsOneWidget);
    expect(find.text('2020– · ★ 8.4'), findsOneWidget);
  });

  testWidgets('a local name leads, with the addon name under it', (
    tester,
  ) async {
    await _pump(
      tester,
      SearchResultCard(
        movie: _row('series'),
        kind: SearchKind.anime,
        localTitle: '凡人修仙传',
        resume: ContinueWatchingItem(
          id: 'tt12879782',
          title: '凡人修仙传',
          type: 'series',
          season: 1,
          episode: 3,
          positionSeconds: 760,
          totalDurationSeconds: 1215,
          lastWatchedAt: DateTime(2026, 10, 1),
          isTorrent: false,
        ),
      ),
      locale: const Locale('zh'),
    );
    expect(find.text('凡人修仙传'), findsOneWidget);
    expect(find.text("A Mortal's Journey"), findsOneWidget);
    expect(find.text('动画'), findsOneWidget);
    expect(find.text('看到 第 1 季 第 3 集'), findsOneWidget);
  });
}
