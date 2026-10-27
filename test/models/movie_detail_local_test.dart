import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/movie/movie_detail.dart';

void main() {
  final base = MovieDetail(
    id: 'tt12879782',
    type: 'series',
    name: "A Record of a Mortal's Journey to Immortality",
    description: 'An ordinary boy...',
    genres: const ['Animation'],
  );

  test('without local text the addon text is shown', () {
    expect(base.displayName, base.name);
    expect(base.displayDescription, base.description);
    expect(base.displayGenres, ['Animation']);
    expect(base.hasLocalName, isFalse);
  });

  test('local text is shown, and the name the scrapers use is kept', () {
    final zh = base.copyWith(
      localName: '凡人修仙传',
      localDescription: '看机智的凡人小子韩立……',
      localGenres: const ['动画', '动作冒险'],
    );
    expect(zh.displayName, '凡人修仙传');
    expect(zh.displayDescription, startsWith('看机智'));
    expect(zh.displayGenres, ['动画', '动作冒险']);
    expect(zh.hasLocalName, isTrue);
    expect(zh.name, "A Record of a Mortal's Journey to Immortality");
  });

  test('blank local text falls back', () {
    final blank = base.copyWith(localName: '  ', localDescription: '');
    expect(blank.displayName, base.name);
    expect(blank.displayDescription, base.description);
  });
}
