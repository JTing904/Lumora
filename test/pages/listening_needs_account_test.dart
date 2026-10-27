import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/pages/account/login_page.dart';
import 'package:zplay/pages/browse/browse_page.dart';

void main() {
  test('music and audiobooks need an account; books and manga do not', () {
    expect(BrowseVertical.music.page, isA<SignInRequired>());
    expect(BrowseVertical.audiobooks.page, isA<SignInRequired>());
    expect(BrowseVertical.books.page, isNot(isA<SignInRequired>()));
    expect(BrowseVertical.manga.page, isNot(isA<SignInRequired>()));
  });
}
