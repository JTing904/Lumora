import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/pages/browse/browse_page.dart';

void main() {
  test('更多内容 no longer offers anime, books or audiobooks', () {
    final offered = offeredVerticals(adultEnabled: false);
    expect(offered, isNot(contains(BrowseVertical.anime)));
    expect(offered, isNot(contains(BrowseVertical.books)));
    expect(offered, isNot(contains(BrowseVertical.audiobooks)));
    expect(offered, [
      BrowseVertical.moviesAndTv,
      BrowseVertical.collections,
      BrowseVertical.liveTv,
      BrowseVertical.manga,
      BrowseVertical.music,
    ]);
  });

  test('18+ is offered last, and only with the adult switch on', () {
    expect(
      offeredVerticals(adultEnabled: false),
      isNot(contains(BrowseVertical.adult)),
    );
    expect(offeredVerticals(adultEnabled: true).last, BrowseVertical.adult);
  });
}
