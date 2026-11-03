import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/l10n/generated/app_localizations.dart';
import 'package:zplay/pages/downloads/download_error_text.dart';
import 'package:zplay/services/download/download_error.dart';

void main() {
  final zh = lookupAppLocalizations(const Locale('zh'));

  test('stored codes round-trip', () {
    final code = DownloadError.code(DownloadErrorKind.httpStatus, 403);
    final parsed = DownloadError.classify(code);
    expect(parsed.kind, DownloadErrorKind.httpStatus);
    expect(parsed.detail, 403);
  });

  test('caught exceptions keep only their kind', () {
    final code = DownloadError.codeFor(
      const SocketException('refused, url https://x/y?token=abc'),
    );
    expect(code, 'dl:network');
    expect(
      DownloadError.codeFor(
        const DownloadFailure(DownloadErrorKind.notEnoughSpace),
      ),
      'dl:notEnoughSpace',
    );
  });

  test('English messages saved by earlier builds still map', () {
    const cases = {
      'Invalid download path': DownloadErrorKind.invalidPath,
      'File was moved or deleted from disk': DownloadErrorKind.fileMissing,
      'Reconnecting (attempt 3)...': DownloadErrorKind.reconnecting,
      'Failed to save final file: FileSystemException: x':
          DownloadErrorKind.saveFailed,
      'Exception: Server returned HTTP 404: Not Found':
          DownloadErrorKind.httpStatus,
      'Exception: Insufficient free disk space on target partition':
          DownloadErrorKind.notEnoughSpace,
      'Exception: HLS playlist contains 0 media segments':
          DownloadErrorKind.badPlaylist,
      'something odd': DownloadErrorKind.unknown,
    };
    cases.forEach((raw, kind) {
      expect(DownloadError.classify(raw).kind, kind, reason: raw);
    });
    expect(DownloadError.classify('Reconnecting (attempt 3)...').detail, 3);
  });

  test('the page shows Chinese, never the stored English', () {
    expect(downloadErrorText(zh, 'Invalid download path'), zh.dlErrInvalidPath);
    expect(
      downloadErrorText(zh, 'Exception: Server returned HTTP 404: Not Found'),
      zh.dlErrHttpStatus(404),
    );
    expect(downloadErrorText(zh, null), zh.dlUnknownError);
    expect(downloadErrorText(zh, 'weird English text'), zh.dlUnknownError);
  });
}
