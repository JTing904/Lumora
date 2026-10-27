import 'dart:io';

import 'package:flutter/foundation.dart';

/// Registers `io.github.jting904.lumora://` with Windows for this user, so the
/// browser can hand a Google or Facebook sign-in back to this copy of the app.
/// Per-user (HKCU), so it needs no administrator rights and also covers the
/// portable ZIP; re-run each start so a moved install still answers.
abstract final class UrlScheme {
  static const scheme = 'io.github.jting904.lumora';

  static Future<void> register() async {
    if (kIsWeb || !Platform.isWindows) return;
    final exe = Platform.resolvedExecutable;
    const key = r'HKCU\Software\Classes\' + scheme;
    try {
      await Process.run('reg', ['add', key, '/ve', '/d', 'URL:Lumora', '/f']);
      await Process.run('reg', [
        'add', key, '/v', 'URL Protocol', '/d', '', '/f',
      ]);
      await Process.run('reg', [
        'add', '$key\\shell\\open\\command', '/ve',
        '/d', '"$exe" "%1"', '/f',
      ]);
    } catch (e) {
      debugPrint('[UrlScheme] could not register: $e');
    }
  }
}
