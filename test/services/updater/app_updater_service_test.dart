import 'dart:convert';
import 'dart:typed_data';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/updater/app_updater_service.dart';

import '../../../tool/sign_release.dart' show withVersionLine;

void main() {
  const hash =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  group('AppUpdaterService.checksumForAsset', () {
    test('reads sha256sum output', () {
      expect(
        AppUpdaterService.checksumForAsset(
          '$hash  app-arm64-v8a-release.apk\n',
          'app-arm64-v8a-release.apk',
        ),
        hash,
      );
    });

    test('accepts the binary-mode marker and a path prefix', () {
      expect(
        AppUpdaterService.checksumForAsset(
          '$hash *./ZPlay-Windows-Setup.exe',
          'ZPlay-Windows-Setup.exe',
        ),
        hash,
      );
    });

    test('does not match another asset', () {
      expect(
        AppUpdaterService.checksumForAsset('$hash  other.apk', 'app.apk'),
        isNull,
      );
    });

    test('ignores malformed lines', () {
      expect(
        AppUpdaterService.checksumForAsset('not-a-hash  app.apk', 'app.apk'),
        isNull,
      );
    });

    test('returns null for an empty asset name', () {
      expect(AppUpdaterService.checksumForAsset('$hash  app.apk', ''), isNull);
    });

    test('skips the version line a signed manifest begins with', () {
      // The same parser shipped in 1.0.0, so those clients still find their
      // checksum in a manifest that names its version.
      const manifest =
          '# lumora-version 1.0.1\n$hash  app.apk\n$hash *Lumora-Setup.exe\n';
      expect(AppUpdaterService.checksumForAsset(manifest, 'app.apk'), hash);
      expect(
        AppUpdaterService.checksumForAsset(manifest, 'Lumora-Setup.exe'),
        hash,
      );
    });
  });

  group('AppUpdaterService.manifestVersion', () {
    test('reads the version line', () {
      expect(
        AppUpdaterService.manifestVersion('# lumora-version 1.2.3\n$hash  a'),
        '1.2.3',
      );
      expect(
        AppUpdaterService.manifestVersion(
          '﻿# lumora-version 1.2.3\r\n$hash  a',
        ),
        '1.2.3',
      );
    });

    test('is null for an old-format manifest', () {
      expect(AppUpdaterService.manifestVersion('$hash  app.apk\n'), isNull);
      expect(AppUpdaterService.manifestVersion(''), isNull);
    });

    test('only counts the first line', () {
      expect(
        AppUpdaterService.manifestVersion(
          '$hash  app.apk\n# lumora-version 9.9.9\n',
        ),
        isNull,
      );
    });
  });

  group('AppUpdaterService.manifestAuthorizes', () {
    const manifest = '# lumora-version 1.2.0\n$hash  app.apk\n';

    test('accepts the tagged version when it is newer', () {
      expect(
        AppUpdaterService.manifestAuthorizes(
          manifest,
          releaseVersion: '1.2.0',
          installedVersion: '1.1.9',
        ),
        isTrue,
      );
    });

    test('refuses a manifest re-published under another tag', () {
      expect(
        AppUpdaterService.manifestAuthorizes(
          manifest,
          releaseVersion: '1.3.0',
          installedVersion: '1.2.5',
        ),
        isFalse,
      );
    });

    test('refuses a version that is not newer than the installed one', () {
      for (final installed in ['1.2.0', '1.2.1', '2.0.0']) {
        expect(
          AppUpdaterService.manifestAuthorizes(
            manifest,
            releaseVersion: '1.2.0',
            installedVersion: installed,
          ),
          isFalse,
          reason: 'installed $installed',
        );
      }
    });

    test('refuses an old-format manifest without a version line', () {
      expect(
        AppUpdaterService.manifestAuthorizes(
          '$hash  app.apk\n',
          releaseVersion: '1.2.0',
          installedVersion: '1.0.0',
        ),
        isFalse,
      );
    });
  });

  group('sign_release withVersionLine', () {
    const sums = '$hash  app.apk\n$hash *Lumora-Setup.exe\n';

    test('puts the version line first', () {
      final signed = withVersionLine(sums, '1.0.1');
      expect(signed, '# lumora-version 1.0.1\n$sums');
      expect(AppUpdaterService.manifestVersion(signed), '1.0.1');
    });

    test('replaces an earlier version line instead of stacking them', () {
      final once = withVersionLine(sums, '1.0.1');
      final twice = withVersionLine(once, '1.0.2');
      expect(twice, '# lumora-version 1.0.2\n$sums');
    });

    test('a signature over the whole file still verifies and old clients '
        'still find their checksum', () {
      final pair = ed.generateKey();
      final manifest = withVersionLine(sums, '1.0.1');
      final bytes = Uint8List.fromList(utf8.encode(manifest));
      final signature = ed.sign(pair.privateKey, bytes);
      expect(ed.verify(pair.publicKey, bytes, signature), isTrue);
      expect(AppUpdaterService.checksumForAsset(manifest, 'app.apk'), hash);
    });
  });
}
