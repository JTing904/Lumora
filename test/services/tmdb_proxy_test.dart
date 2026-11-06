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

  test('a busy proxy is asked again rather than read as no answer', () async {
    TmdbService.buildTimeApiKeyOverrideForTesting = '';
    TmdbService.proxyBaseOverrideForTesting =
        'https://example.supabase.co/functions/v1/tmdb';
    TmdbService.proxyRetryBase = Duration.zero;
    addTearDown(
      () => TmdbService.proxyRetryBase = const Duration(milliseconds: 1500),
    );
    var calls = 0;
    TmdbService.client = MockClient((_) async {
      calls++;
      return calls < 3
          ? http.Response('{"error":"too many requests"}', 429)
          : http.Response(jsonEncode({'title': 'Joy of Life'}), 200);
    });
    final body = await TmdbService.getScraperJson('/tv/12345', {
      'language': 'zh-CN',
    });
    expect(body?['title'], 'Joy of Life');
    expect(calls, 3);
  });

  test('the same request in flight twice is asked once', () async {
    TmdbService.buildTimeApiKeyOverrideForTesting = '';
    TmdbService.proxyBaseOverrideForTesting =
        'https://example.supabase.co/functions/v1/tmdb';
    var calls = 0;
    TmdbService.client = MockClient((_) async {
      calls++;
      return http.Response(jsonEncode({'id': 1}), 200);
    });
    final both = await Future.wait([
      TmdbService.getScraperJson('/movie/1', {'language': 'zh-CN'}),
      TmdbService.getScraperJson('/movie/1', {'language': 'zh-CN'}),
    ]);
    expect(both.every((b) => b?['id'] == 1), isTrue);
    expect(calls, 1);
  });

  test('requests are paced to the minute', () async {
    var now = DateTime(2026, 11, 6, 10);
    final slept = <Duration>[];
    final pace = ProxyPace(
      perMinute: 2,
      now: () => now,
      sleep: (d) async {
        slept.add(d);
        now = now.add(d);
      },
    );
    await pace.take();
    now = now.add(const Duration(seconds: 10));
    await pace.take();
    expect(slept, isEmpty);
    await pace.take();
    final waited = slept.fold(Duration.zero, (a, b) => a + b);
    expect(waited, const Duration(seconds: 50));
  });

  test('urgent requests have places ordinary ones cannot use', () async {
    var now = DateTime(2026, 11, 6, 10);
    final pace = ProxyPace(
      perMinute: 3,
      reserve: 1,
      now: () => now,
      sleep: (d) async => now = now.add(d),
    );
    await pace.take();
    await pace.take();
    final start = now;
    await pace.take(urgent: true);
    expect(now, start, reason: 'the reserved place is free');
    await pace.take();
    expect(now.difference(start), const Duration(minutes: 1));
  });

  test('an urgent request goes ahead of the ordinary ones waiting', () async {
    var now = DateTime(2026, 11, 6, 10);
    final pace = ProxyPace(
      perMinute: 1,
      now: () => now,
      sleep: (d) async => now = now.add(d),
    );
    await pace.take();
    final order = <String>[];
    final waiting = [
      pace.take().then((_) => order.add('card 1')),
      pace.take().then((_) => order.add('card 2')),
      pace.take(urgent: true).then((_) => order.add('details')),
    ];
    await Future.wait(waiting);
    expect(order, ['details', 'card 1', 'card 2']);
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
