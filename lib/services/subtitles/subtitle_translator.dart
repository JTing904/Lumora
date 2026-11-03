import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../account/account_service.dart';
import 'subtitle_parser.dart';

/// Why a translation could not run at all.
enum SubtitleTranslationFailure {
  /// Lumora's AI only answers a signed-in account.
  signedOut,

  /// The account has not used an invite code.
  notInvited,

  /// No model answered.
  unavailable,
}

class SubtitleTranslationError implements Exception {
  const SubtitleTranslationError(this.failure);
  final SubtitleTranslationFailure failure;

  @override
  String toString() => 'SubtitleTranslationError($failure)';
}

/// Sends one chat request (the `ai` Edge Function's body) and returns the
/// reply's text.
typedef AiChat = Future<String> Function(Map<String, dynamic> body);

/// Turns an English subtitle into Chinese line by line.
///
/// Only the text changes: every line keeps the English file's timing, which
/// is why the result stays in time with the picture whenever the English
/// subtitle does. Lines are sent in small numbered batches, starting where
/// the viewer is, so the first Chinese lines show within seconds; the rest
/// fill in while the film plays. Finished lines are kept on disk, so a film
/// is translated once.
class SubtitleTranslator {
  SubtitleTranslator({
    AiChat? chat,
    this.batchSize = 20,
    this.parallel = 2,
    Future<Directory?> Function()? cacheDir,
  }) : _chat = chat ?? _supabaseChat,
       _cacheDir = cacheDir ?? _defaultCacheDir;

  final AiChat _chat;
  final int batchSize;
  final int parallel;
  final Future<Directory?> Function() _cacheDir;

  /// Fastest first. NVIDIA's free tier queues some models for a long time;
  /// with thinking turned down these answer a batch in about 5-10 s.
  static const List<Map<String, dynamic>> models = [
    {
      'model': 'nvidia/nemotron-3.5-lightning-30b-a3b',
      'chat_template_kwargs': {'enable_thinking': false},
    },
    {'model': 'openai/gpt-oss-20b', 'reasoning_effort': 'low'},
    {'model': 'minimaxai/minimax-m3.1-flash', 'reasoning_effort': 'low'},
  ];

  /// Bump when the prompt changes enough that saved lines should be redone.
  static const String _version = 'v1';

  static String cacheKeyFor(String sourceUrl) =>
      sha1.convert(utf8.encode('$_version|$sourceUrl')).toString();

  /// [count] line indexes in batches of [size], in time order.
  static List<List<int>> batchesOf(int count, int size) => [
    for (var i = 0; i < count; i += size)
      [for (var j = i; j < i + size && j < count; j++) j],
  ];

  /// Which of the [remaining] batches (in time order) to translate next
  /// when the viewer is at line [focus]: the first one still ahead of
  /// them, else the nearest one behind.
  static int nextBatch(List<List<int>> remaining, int focus) {
    final ahead = remaining.indexWhere((b) => b.last >= focus);
    return ahead >= 0 ? ahead : remaining.length - 1;
  }

  /// A subtitle line as plain one-line text: no styling tags, no breaks.
  static String plain(String text) => text
      .replaceAll(RegExp(r'\{\\[^}]*\}'), '')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll(RegExp(r'\s*\n\s*'), ' ')
      .trim();

  static const String _system =
      'You translate film and TV subtitles into natural, spoken Simplified '
      'Chinese (简体中文). Each input line is "number|English". Reply with '
      'one line per input, in the same order, as "number|中文" and nothing '
      'else: no notes, no English, no blank lines. Keep each line short like '
      'a real subtitle. Keep names consistent; leave a line that is only a '
      'name, sound or music cue short.';

  static List<Map<String, String>> messagesFor(List<String> lines) => [
    {'role': 'system', 'content': _system},
    {
      'role': 'user',
      'content': [
        for (var i = 0; i < lines.length; i++) '${i + 1}|${lines[i]}',
      ].join('\n'),
    },
  ];

  static final RegExp _numbered = RegExp(r'^\s*(\d+)\s*[|｜:：.、)]\s*(.*)$');

  /// The reply's lines by their 0-based position in the batch. Lines the
  /// model skipped or numbered outside the batch are left out.
  static Map<int, String> parseReply(String reply, int count) {
    final text = reply.replaceAll(
      RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false),
      '',
    );
    final out = <int, String>{};
    for (final line in const LineSplitter().convert(text)) {
      final m = _numbered.firstMatch(line);
      if (m == null) continue;
      final n = int.parse(m.group(1)!);
      final value = m.group(2)!.trim();
      if (n < 1 || n > count || value.isEmpty) continue;
      out.putIfAbsent(n - 1, () => value);
    }
    return out;
  }

  /// Translates [cues], reporting finished lines by cue index through
  /// [onLines] as they arrive (saved lines first). [focus] is the line the
  /// viewer is at; each next batch is picked from there, so a jump ahead is
  /// in Chinese seconds later. Returns once every batch was tried or
  /// [cancelled] says stop.
  ///
  /// Throws [SubtitleTranslationError] when the AI cannot be used at all:
  /// signed out, no invite, or not one batch answered.
  Future<void> translate(
    List<SubCue> cues, {
    required String cacheKey,
    required int Function() focus,
    required void Function(Map<int, String> lines) onLines,
    required bool Function() cancelled,
  }) async {
    final done = await _load(cacheKey);
    if (done.isNotEmpty) onLines(Map.of(done));

    // Only the lines not saved yet, in time order.
    final remaining = [
      for (final b in batchesOf(cues.length, batchSize))
        [
          for (final i in b)
            if (!done.containsKey(i)) i,
        ],
    ].where((b) => b.isNotEmpty).toList();
    if (remaining.isEmpty) return;
    final workers = remaining.length < parallel ? remaining.length : parallel;

    // Lines a busy model timed out on or skipped get one more go at the end.
    final retry = <List<int>>[];
    var retrying = false;
    var answered = 0;
    SubtitleTranslationError? fatal;
    var saving = Future<void>.value();

    Future<void> worker() async {
      while (fatal == null && !cancelled()) {
        if (remaining.isEmpty && !retrying) {
          retrying = true;
          remaining.addAll(retry..sort((a, b) => a.first - b.first));
        }
        if (remaining.isEmpty) return;
        final batch = remaining.removeAt(nextBatch(remaining, focus()));
        final firstTry = !retrying;
        final source = [for (final i in batch) plain(cues[i].text)];
        Map<int, String> got;
        try {
          got = await _translateBatch(source);
        } on SubtitleTranslationError catch (e) {
          fatal = e;
          return;
        }
        if (cancelled()) return;
        if (firstTry && got.length < batch.length) {
          final missed = [
            for (var k = 0; k < batch.length; k++)
              if (!got.containsKey(k)) batch[k],
          ];
          if (retrying) {
            // The retry round already started: join it in time order.
            final at = remaining.indexWhere((b) => b.first > missed.first);
            remaining.insert(at < 0 ? remaining.length : at, missed);
          } else {
            retry.add(missed);
          }
        }
        if (got.isEmpty) continue;
        answered++;
        final lines = {for (final e in got.entries) batch[e.key]: e.value};
        done.addAll(lines);
        onLines(lines);
        saving = saving.then((_) => _save(cacheKey, done));
      }
    }

    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
    await saving;
    final error = fatal;
    if (error != null) throw error;
    if (answered == 0 && !cancelled()) {
      throw const SubtitleTranslationError(
        SubtitleTranslationFailure.unavailable,
      );
    }
  }

  /// One batch, trying the next model when one fails or skips most lines.
  Future<Map<int, String>> _translateBatch(List<String> lines) async {
    var best = <int, String>{};
    for (final model in models) {
      try {
        final reply = await _chat({
          ...model,
          'messages': messagesFor(lines),
          'max_tokens': 2048,
          'temperature': 0.2,
          'timeout_ms': 30000,
        });
        final got = parseReply(reply, lines.length);
        if (got.length > best.length) best = got;
        if (got.length >= lines.length * 0.8) return got;
      } on SubtitleTranslationError catch (e) {
        if (e.failure != SubtitleTranslationFailure.unavailable) rethrow;
      } catch (_) {
        // Timed out or refused: the next model may answer.
      }
    }
    return best;
  }

  Future<File?> _file(String key) async {
    final dir = await _cacheDir();
    return dir == null ? null : File('${dir.path}/$key.json');
  }

  Future<Map<int, String>> _load(String key) async {
    try {
      final file = await _file(key);
      if (file == null || !await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (int.tryParse('${e.key}') != null && e.value is String)
            int.parse('${e.key}'): e.value as String,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(String key, Map<int, String> lines) async {
    try {
      final file = await _file(key);
      if (file == null) return;
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({for (final e in lines.entries) '${e.key}': e.value}),
      );
    } catch (_) {
      // Only the saving is lost; the lines on screen stay.
    }
  }

  static Future<Directory?> _defaultCacheDir() async {
    try {
      final base = await getApplicationSupportDirectory();
      return Directory('${base.path}/subtitle_ai');
    } catch (_) {
      return null;
    }
  }

  static Future<String> _supabaseChat(Map<String, dynamic> body) async {
    if (!AccountService.configured || AccountService.accessToken == null) {
      throw const SubtitleTranslationError(
        SubtitleTranslationFailure.signedOut,
      );
    }
    try {
      final res = await Supabase.instance.client.functions
          .invoke('ai', body: body)
          .timeout(const Duration(seconds: 40));
      final data = res.data is String ? jsonDecode(res.data) : res.data;
      final content = data['choices']?[0]?['message']?['content'];
      return content is String ? content : '';
    } on FunctionException catch (e) {
      if (e.status == 401) {
        throw const SubtitleTranslationError(
          SubtitleTranslationFailure.signedOut,
        );
      }
      if (e.status == 403) {
        throw const SubtitleTranslationError(
          SubtitleTranslationFailure.notInvited,
        );
      }
      rethrow;
    }
  }
}
