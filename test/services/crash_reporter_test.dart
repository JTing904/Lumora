import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zplay/services/diagnostics/crash_reporter.dart';

void main() {
  setUp(CrashReporter.debugReset);

  group('CrashReporter.scrub', () {
    test('cuts URLs to their origin, dropping path and query', () {
      final out = CrashReporter.scrub(
        'GET https://api.example.com:8443/v1/items?api_key=abc123&q=x failed',
      );
      expect(out, 'GET https://api.example.com:8443/[redacted] failed');
    });

    test('keeps only the file name of file URLs in stack frames', () {
      final out = CrashReporter.scrub(
        '#0 main (file:///C:/Users/alice/Desktop/ZPlay/lib/main.dart:12:5)',
      );
      expect(out, '#0 main (file:///[path]/main.dart:12:5)');
      expect(out, isNot(contains('alice')));
    });

    test('leaves package: frames alone', () {
      const frame = '#1 Foo.bar (package:zplay/pages/home.dart:40:7)';
      expect(CrashReporter.scrub(frame), frame);
    });

    test('removes emails', () {
      expect(
        CrashReporter.scrub('no account for jane.doe+x@mail.example.org'),
        'no account for [email]',
      );
    });

    test('removes bearer tokens and JWTs', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U';
      final out = CrashReporter.scrub('Authorization: Bearer $jwt; raw $jwt');
      expect(out, isNot(contains('eyJ')));
      expect(out, isNot(contains('dozjgNryP4J3')));
      expect(out, contains('[jwt]'));
    });

    test('removes known key formats', () {
      final out = CrashReporter.scrub(
        'keys sb_secret_AbCdEf123456789 and sk-live_ZYXWVUT9876 ghp_abcdefgh12345',
      );
      expect(out, isNot(contains('AbCdEf')));
      expect(out, isNot(contains('ZYXWVUT')));
      expect(out, isNot(contains('abcdefgh12345')));
    });

    test('removes key=value secrets', () {
      final out = CrashReporter.scrub(
        'bad config apiKey=hunter2, password: "s3cret" refresh_token=r1',
      );
      expect(out, isNot(contains('hunter2')));
      expect(out, isNot(contains('s3cret')));
      expect(out, isNot(contains('r1')));
      expect(out, contains('apiKey=[redacted]'));
    });

    test('removes stray query strings', () {
      expect(
        CrashReporter.scrub('path /stream?token=abc&id=5 not found'),
        isNot(contains('abc')),
      );
    });

    test('removes user names from home folders', () {
      final out = CrashReporter.scrub(
        r"Cannot open file, path = 'C:\Users\Alice Smith\AppData\x.db' "
        '/home/bob/.config/y /Users/carol/Library/z',
      );
      expect(out, isNot(contains('Alice')));
      expect(out, isNot(contains('bob')));
      expect(out, isNot(contains('carol')));
      expect(out, contains(r'C:\Users\[user]\AppData\x.db'));
      expect(out, contains('/home/[user]/.config/y'));
    });

    test('removes UUIDs and long random tokens but keeps identifiers', () {
      final out = CrashReporter.scrub(
        'user 123e4567-e89b-12d3-a456-426614174000 '
        'token Zx9QwErTy7UiOpAsDfGhJkLzXcVbNm123456 '
        "build_id: '0123456789abcdef0123456789abcdef' "
        '_SomeVeryLongWidgetNameStateMixinThing.build',
      );
      expect(out, isNot(contains('123e4567')));
      expect(out, isNot(contains('Zx9QwErTy7')));
      expect(out, contains('0123456789abcdef0123456789abcdef'));
      expect(out, contains('_SomeVeryLongWidgetNameStateMixinThing.build'));
    });

    test('leaves an ordinary error message untouched', () {
      const msg = 'Null check operator used on a null value';
      expect(CrashReporter.scrub(msg), msg);
    });
  });

  group('CrashReporter.truncate', () {
    test('keeps short text', () {
      expect(CrashReporter.truncate('abc', 10), 'abc');
      expect(CrashReporter.truncate('abcdefghij', 10), 'abcdefghij');
    });

    test('cuts to the limit with an ellipsis', () {
      final out = CrashReporter.truncate('a' * 50, 10);
      expect(out.length, 10);
      expect(out.endsWith('…'), isTrue);
    });

    test('never splits a surrogate pair', () {
      // 'a' then emoji (2 UTF-16 units) repeated.
      final text = 'a${'😀' * 20}';
      // A cut at 3 would land between the emoji's two halves.
      expect(CrashReporter.truncate(text, 3), 'a…');
      expect(CrashReporter.truncate(text, 4), 'a😀…');
    });

    test('messages and stacks respect the table limits', () {
      final message = CrashReporter.prepareMessage(
        StateError('x' * 5000),
      );
      expect(message.length, lessThanOrEqualTo(CrashReporter.maxMessageChars));
      final stack = CrashReporter.prepareStack(
        StackTrace.fromString('#0 f (package:zplay/a.dart:1:1)\n' * 1000),
      );
      expect(stack.length, lessThanOrEqualTo(CrashReporter.maxStackChars));
      expect(CrashReporter.prepareStack(null), '');
    });
  });

  group('CrashReporter.fingerprint', () {
    const stackA = '#0 a (package:zplay/a.dart:1:1)\n'
        '<asynchronous suspension>\n'
        '#1 b (package:zplay/b.dart:2:2)\n'
        '#2 c (package:zplay/c.dart:3:3)\n'
        '#3 d (package:zplay/d.dart:4:4)\n';
    const stackDeeperDiff = '#0 a (package:zplay/a.dart:1:1)\n'
        '#1 b (package:zplay/b.dart:2:2)\n'
        '#2 c (package:zplay/c.dart:3:3)\n'
        '#3 other (package:zplay/x.dart:9:9)\n';

    test('same message and top frames match', () {
      expect(
        CrashReporter.fingerprint('boom', stackA),
        CrashReporter.fingerprint('boom', stackDeeperDiff),
      );
    });

    test('different message or top frame differs', () {
      expect(
        CrashReporter.fingerprint('boom', stackA),
        isNot(CrashReporter.fingerprint('bang', stackA)),
      );
      expect(
        CrashReporter.fingerprint('boom', stackA),
        isNot(
          CrashReporter.fingerprint(
            'boom',
            stackA.replaceFirst('a.dart', 'z.dart'),
          ),
        ),
      );
    });

    test('skips the header of an obfuscated stack', () {
      const header1 = 'pid: 1, tid: 2\nbuild_id: abc\n';
      const header2 = 'pid: 7, tid: 8\nbuild_id: abc\n';
      const frames = '#00 abs 0000007a virt 00001 _kDartIsolateSnapshotInstructions+0x10\n';
      expect(
        CrashReporter.fingerprint('boom', header1 + frames),
        CrashReporter.fingerprint('boom', header2 + frames),
      );
    });
  });

  group('ReportBudget', () {
    test('admits each fingerprint once', () {
      final budget = ReportBudget(10);
      expect(budget.admit('a'), isTrue);
      expect(budget.admit('a'), isFalse);
      expect(budget.admit('b'), isTrue);
      expect(budget.sent, 2);
    });

    test('caps reports per session', () {
      final budget = ReportBudget(CrashReporter.maxReportsPerSession);
      var admitted = 0;
      for (var i = 0; i < 25; i++) {
        if (budget.admit('error $i')) admitted++;
      }
      expect(admitted, CrashReporter.maxReportsPerSession);
      expect(budget.admit('one more'), isFalse);
    });

    test('reset starts a new session', () {
      final budget = ReportBudget(1);
      expect(budget.admit('a'), isTrue);
      expect(budget.admit('b'), isFalse);
      budget.reset();
      expect(budget.admit('b'), isTrue);
    });
  });

  group('CrashReporter.isNetworkNoise', () {
    test('network failures are noise', () {
      expect(CrashReporter.isNetworkNoise(const SocketException('x')), isTrue);
      expect(CrashReporter.isNetworkNoise(TimeoutException('x')), isTrue);
      expect(
        CrashReporter.isNetworkNoise(const HandshakeException('x')),
        isTrue,
      );
      expect(CrashReporter.isNetworkNoise(http.ClientException('x')), isTrue);
    });

    test('app errors are not', () {
      expect(CrashReporter.isNetworkNoise(StateError('x')), isFalse);
      expect(CrashReporter.isNetworkNoise(const FormatException()), isFalse);
    });
  });

  test('record is a no-op outside release builds and never throws', () {
    expect(
      () => CrashReporter.record(StateError('x'), StackTrace.current,
          kind: 'flutter'),
      returnsNormally,
    );
  });
}
