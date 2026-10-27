import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/movie/movie.dart';
import 'package:zplay/services/content/adult_guard.dart';
import 'package:zplay/services/content/content_settings.dart';

Movie _m(String name) =>
    Movie(id: name, name: name, type: 'movie', addonBaseUrl: '');

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ContentSettings.setAdmin(false);
  });

  test('sexual titles are caught by any of their names', () {
    for (final name in [
      'My Hentai Girlfriend',
      'Hentai!',
      'An Erotic Story',
      'XXX Files',
      '变态母犬调教',
      '情色电影',
      'エロ漫画先生',
    ]) {
      expect(AdultGuard.looksAdult([name]), isTrue, reason: name);
    }
    expect(AdultGuard.looksAdult(['Ruff Trade'], flagged: true), isTrue);
    expect(
      AdultGuard.looksAdult(['Super HxEros', '弩级战队H×EROS']),
      isFalse,
      reason: 'no listed word: left to its source flag',
    );
  });

  test('ordinary titles are left alone', () {
    for (final name in [
      'Sex Education',
      'Hardcore Henry',
      'Javier\'s Passion',
      'Superman',
      '庆余年',
      '凡人修仙传',
      'Love, Death & Robots',
    ]) {
      expect(AdultGuard.looksAdult([name]), isFalse, reason: name);
    }
  });

  test(
    'hidden for everyone, shown only to an admin who turned it on',
    () async {
      final list = [_m('Superman'), _m('My Hentai Girlfriend')];
      expect(AdultGuard.filter(list).map((m) => m.name), ['Superman']);

      await ContentSettings.setAdmin(true);
      expect(AdultGuard.filter(list).length, 1, reason: 'switch still off');
      await ContentSettings.setAdultEnabled(true);
      expect(AdultGuard.filter(list).length, 2);

      await ContentSettings.setAdmin(false);
      expect(AdultGuard.filter(list).length, 1, reason: 'signing out hides it');
    },
  );

  test('an adult search term withholds the whole search', () async {
    expect(AdultGuard.adultQuery('erotic'), isTrue);
    expect(AdultGuard.adultQuery('Hentai'), isTrue);
    expect(AdultGuard.adultQuery('浪荡子的性爱旅程'), isTrue);
    expect(AdultGuard.adultQuery('庆余年'), isFalse);
    expect(AdultGuard.adultQuery('激情邀约'), isFalse);
    await ContentSettings.setAdmin(true);
    await ContentSettings.setAdultEnabled(true);
    expect(AdultGuard.adultQuery('erotic'), isFalse);
  });
}
