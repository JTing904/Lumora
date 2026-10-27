import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/account/account_service.dart';
import 'package:zplay/services/player/playable_url.dart';
import 'package:zplay/services/updater/release_signature.dart';

void main() {
  group('sign-in deep links', () {
    test('a code from our own sign-in is taken', () {
      expect(
        AccountService.isOwnAuthCallback(
          Uri.parse('io.github.jting904.lumora://login-callback?code=abc'),
        ),
        isTrue,
      );
    });

    test('a link carrying ready-made tokens is not', () {
      for (final link in [
        'io.github.jting904.lumora://login-callback#access_token=x&refresh_token=y',
        'io.github.jting904.lumora://login-callback?access_token=x&code=abc',
        'io.github.jting904.lumora://login-callback?code=abc#access_token=x',
        'io.github.jting904.lumora://elsewhere?code=abc',
        'https://evil.example/login-callback?code=abc',
      ]) {
        expect(AccountService.isOwnAuthCallback(Uri.parse(link)), isFalse,
            reason: link);
      }
    });
  });

  group('stream addresses', () {
    test('network streams and local files play', () {
      for (final url in [
        'https://cdn.example/v.m3u8',
        'http://127.0.0.1:8090/stream/x',
        'rtmp://live.example/app',
        r'C:\Users\me\Videos\a.mkv',
        '/storage/emulated/0/a.mp4',
        'file:///tmp/a.mp4',
      ]) {
        expect(isPlayableUrl(url), isTrue, reason: url);
      }
    });

    test("mpv's own protocols and junk do not", () {
      for (final url in [
        'edl://a.mkv,0,10',
        'lavf://x',
        'memory://abc',
        'av://dshow:video=x',
        '-K cfg',
        r'\\server\share\a.mkv',
        '//server/share/a.mkv',
        '',
      ]) {
        expect(isPlayableUrl(url), isFalse, reason: url);
      }
    });
  });

  test('an unsigned or forged release manifest is not trusted', () {
    final manifest = utf8.encode('abc  Lumora-Setup.exe\n');
    expect(releaseManifestSigned(manifest, ''), isFalse);
    expect(releaseManifestSigned(manifest, base64.encode(List.filled(64, 1))),
        isFalse);
  });
}
