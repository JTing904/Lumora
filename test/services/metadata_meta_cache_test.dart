/// Title details cache: keyed by the app's language, so a switch of language
/// is not served the other one's text, and with a time-to-live, so an airing
/// series picks up its new episodes without a restart.
library;

import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:zplay/services/metadata/metadata_service.dart';
import 'package:zplay/services/settings/locale_settings.dart';

void main() {
  late int hits;
  final t0 = DateTime(2026, 11, 3, 9);

  setUp(() {
    hits = 0;
    LocaleSettings.locale.value = const Locale('en');
    MetadataService.clock = () => t0;
    MetadataService.client = MockClient((request) async {
      hits++;
      final type = request.url.pathSegments.reversed.elementAt(1);
      return http.Response(
        jsonEncode({
          'meta': {'id': 'tt1', 'name': 'Show', 'type': type, 'videos': []},
        }),
        200,
      );
    });
    MetadataService.clearCache();
  });

  tearDown(() {
    MetadataService.client = http.Client();
    MetadataService.clock = DateTime.now;
    MetadataService.clearCache();
    LocaleSettings.locale.value = null;
  });

  Future<void> fetch(String type) => MetadataService.fetchMeta(
    baseUrl: 'https://addon.example.com',
    type: type,
    imdbId: 'tt1',
  );

  test('a series is read again after an hour', () async {
    await fetch('series');
    MetadataService.clock = () => t0.add(const Duration(minutes: 59));
    await fetch('series');
    expect(hits, 1);
    MetadataService.clock = () => t0.add(const Duration(hours: 1));
    await fetch('series');
    expect(hits, 2);
  });

  test('a film keeps longer than a series', () async {
    await fetch('movie');
    MetadataService.clock = () => t0.add(const Duration(hours: 2));
    await fetch('movie');
    expect(hits, 1);
    MetadataService.clock = () => t0.add(const Duration(hours: 24));
    await fetch('movie');
    expect(hits, 2);
  });

  test('a new language reads the details again', () async {
    await fetch('movie');
    LocaleSettings.locale.value = const Locale('zh');
    await fetch('movie');
    expect(hits, 2);
    LocaleSettings.locale.value = const Locale('en');
    await fetch('movie');
    expect(hits, 2, reason: 'the English entry is still fresh');
  });
}
