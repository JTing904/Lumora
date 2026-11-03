import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/subtitles/subtitle_parser.dart';
import 'package:zplay/services/subtitles/subtitle_translator.dart';

List<SubCue> cuesOf(int n) => [
  for (var i = 0; i < n; i++)
    SubCue(start: i * 2.0, end: i * 2.0 + 1.5, text: 'line $i'),
];

/// Answers like a model: "n|中文 n" for every numbered input line.
String echo(Map<String, dynamic> body) {
  final user = (body['messages'] as List).last['content'] as String;
  return user
      .split('\n')
      .map((l) => '${l.split('|').first}|中文${l.split('|').last}')
      .join('\n');
}

void main() {
  group('order', () {
    /// The batches in the order they are picked with the viewer at [focus].
    List<List<int>> order(int count, int focus, int size) {
      final remaining = SubtitleTranslator.batchesOf(count, size);
      final picked = <List<int>>[];
      while (remaining.isNotEmpty) {
        picked.add(
          remaining.removeAt(SubtitleTranslator.nextBatch(remaining, focus)),
        );
      }
      return picked;
    }

    test('starts where the viewer is, then fills in earlier lines', () {
      expect(order(10, 5, 3), [
        [3, 4, 5],
        [6, 7, 8],
        [9],
        [0, 1, 2],
      ]);
    });

    test('copes with an empty file and a position past the end', () {
      expect(order(0, 0, 20), isEmpty);
      expect(order(5, 99, 2).first, [4]);
    });
  });

  group('reply', () {
    test('maps numbered lines back to their place', () {
      final got = SubtitleTranslator.parseReply(
        '<think>hmm</think>\n1|你好\n\n2｜再见\n3: 谢谢\n9|多余的',
        3,
      );
      expect(got, {0: '你好', 1: '再见', 2: '谢谢'});
    });

    test('skips lines without a number', () {
      expect(SubtitleTranslator.parseReply('Here you go:\n2|好', 2), {1: '好'});
    });

    test('sends plain one-line text', () {
      expect(
        SubtitleTranslator.plain('<i>Hello</i>\n{\\an8}there'),
        'Hello there',
      );
    });
  });

  group('translating', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('subai'));
    tearDown(() async => dir.delete(recursive: true));

    SubtitleTranslator make(AiChat chat) => SubtitleTranslator(
      chat: chat,
      batchSize: 4,
      parallel: 2,
      cacheDir: () async => dir,
    );

    test('translates every line and remembers them', () async {
      final seen = <int, String>{};
      var calls = 0;
      await make((b) async {
        calls++;
        return echo(b);
      }).translate(
        cuesOf(10),
        cacheKey: 'k',
        focus: () => 6,
        onLines: seen.addAll,
        cancelled: () => false,
      );
      expect(seen.length, 10);
      expect(seen[7], '中文line 7');
      expect(calls, 3);

      // A second time comes from disk without asking the AI.
      final again = <int, String>{};
      await make((b) async => fail('asked again')).translate(
        cuesOf(10),
        cacheKey: 'k',
        focus: () => 0,
        onLines: again.addAll,
        cancelled: () => false,
      );
      expect(again, seen);
    });

    test('gives lines every model skipped a second go', () async {
      final asked = <String>[];
      final seen = <int, String>{};
      await make((b) async {
        final user = (b['messages'] as List).last['content'] as String;
        asked.add(user);
        // The first round never answers "line 2".
        if (user.contains('line 2') && user.contains('line 0')) {
          return echo(
            b,
          ).split('\n').where((l) => !l.contains('line 2')).join('\n');
        }
        return echo(b);
      }).translate(
        cuesOf(4),
        cacheKey: 'retry',
        focus: () => 0,
        onLines: seen.addAll,
        cancelled: () => false,
      );
      expect(seen.length, 4);
      expect(seen[2], '中文line 2');
      expect(asked.last, '1|line 2');
    });

    test('follows the viewer when they jump ahead', () async {
      var at = 0;
      final asked = <String>[];
      await SubtitleTranslator(
        chat: (b) async {
          final user = (b['messages'] as List).last['content'] as String;
          asked.add(user.split('\n').first.split('|').last);
          at = 30; // the viewer jumps after the first batch
          return echo(b);
        },
        batchSize: 4,
        parallel: 1,
        cacheDir: () async => dir,
      ).translate(
        cuesOf(40),
        cacheKey: 'jump',
        focus: () => at,
        onLines: (_) {},
        cancelled: () => false,
      );
      expect(asked.take(2), ['line 0', 'line 28']);
    });

    test('falls back to the next model', () async {
      final models = <String>[];
      final seen = <int, String>{};
      await make((b) async {
        models.add(b['model'] as String);
        if (b['model'] == SubtitleTranslator.models.first['model']) {
          throw TimeoutException('slow');
        }
        return echo(b);
      }).translate(
        cuesOf(3),
        cacheKey: 'k',
        focus: () => 0,
        onLines: seen.addAll,
        cancelled: () => false,
      );
      expect(seen.length, 3);
      expect(models.take(2), [
        SubtitleTranslator.models[0]['model'],
        SubtitleTranslator.models[1]['model'],
      ]);
    });

    test('says so when the account cannot use the AI', () async {
      expect(
        make((b) async {
          throw const SubtitleTranslationError(
            SubtitleTranslationFailure.notInvited,
          );
        }).translate(
          cuesOf(8),
          cacheKey: 'k',
          focus: () => 0,
          onLines: (_) {},
          cancelled: () => false,
        ),
        throwsA(
          isA<SubtitleTranslationError>().having(
            (e) => e.failure,
            'failure',
            SubtitleTranslationFailure.notInvited,
          ),
        ),
      );
    });

    test('says so when no model answers', () async {
      expect(
        make((b) async => throw TimeoutException('down')).translate(
          cuesOf(4),
          cacheKey: 'k',
          focus: () => 0,
          onLines: (_) {},
          cancelled: () => false,
        ),
        throwsA(isA<SubtitleTranslationError>()),
      );
    });

    test('stops when cancelled', () async {
      var stop = false;
      var calls = 0;
      await SubtitleTranslator(
        chat: (b) async {
          calls++;
          stop = true;
          return echo(b);
        },
        batchSize: 2,
        parallel: 1,
        cacheDir: () async => dir,
      ).translate(
        cuesOf(10),
        cacheKey: 'k',
        focus: () => 0,
        onLines: (_) {},
        cancelled: () => stop,
      );
      expect(calls, 1);
    });
  });
}
