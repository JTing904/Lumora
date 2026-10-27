/// A build that carries no TMDb key asks Lumora's proxy instead, and never
/// sends a key of its own.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zplay/services/metadata/tmdb_service.dart';

void main() {
  tearDown(() {
    TmdbService.proxyBaseOverrideForTesting = null;
    TmdbService.buildTimeApiKeyOverrideForTesting = null;
    TmdbService.client = http.Client();
  });

  test('with no key, a lookup goes through the proxy', () async {
    TmdbService.buildTimeApiKeyOverrideForTesting = '';
    TmdbService.proxyBaseOverrideForTesting =
        'https://example.supabase.co/functions/v1/tmdb';
    late Uri asked;
    TmdbService.client = MockClient((request) async {
      asked = request.url;
      return http.Response(jsonEncode({'results': []}), 200);
    });

    expect(TmdbService.hasScraperKey, isTrue);
    expect(TmdbService.hasDirectScraperKey, isFalse);
    final body = await TmdbService.getScraperJson('/trending/all/week', {
      'language': 'zh-CN',
    });

    expect(body, isNotNull);
    expect(asked.host, 'example.supabase.co');
    expect(asked.path, '/functions/v1/tmdb/trending/all/week');
    expect(asked.queryParameters['language'], 'zh-CN');
    expect(asked.queryParameters.containsKey('api_key'), isFalse);
  });

  test('a proxy refusal reads as no answer', () async {
    TmdbService.buildTimeApiKeyOverrideForTesting = '';
    TmdbService.proxyBaseOverrideForTesting =
        'https://example.supabase.co/functions/v1/tmdb';
    TmdbService.client = MockClient(
      (_) async => http.Response('{"error":"sign in required"}', 401),
    );
    expect(await TmdbService.getScraperJson('/find/tt0903747'), isNull);
  });
}
