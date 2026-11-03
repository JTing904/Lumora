/// Why a download stopped, kept on the task as a short code rather than the
/// English text of an exception.
///
/// The Downloads page used to print `task.error` inside its localized
/// "failed: …" line, so Chinese users read raw English (and exception text
/// can carry a source URL with its token). Tasks now store a code, the page
/// turns it into the user's language, and [classify] still understands the
/// English messages saved by earlier builds.
enum DownloadErrorKind {
  invalidPath,
  fileMissing,
  torrentUnsupported,
  noDebridLink,
  emptyUrl,
  httpStatus,
  notEnoughSpace,
  reconnecting,
  saveFailed,
  badPlaylist,
  network,
  unknown,
}

class DownloadError {
  const DownloadError(this.kind, [this.detail]);

  final DownloadErrorKind kind;

  /// The HTTP status for [DownloadErrorKind.httpStatus], the attempt number
  /// for [DownloadErrorKind.reconnecting].
  final int? detail;

  static const String _prefix = 'dl:';

  /// The code stored in `DownloadTask.error`.
  static String code(DownloadErrorKind kind, [int? detail]) =>
      detail == null ? '$_prefix${kind.name}' : '$_prefix${kind.name}:$detail';

  /// The code for a caught exception. Only the kind survives; the message is
  /// not kept.
  static String codeFor(Object error) {
    if (error is DownloadFailure) return code(error.kind, error.detail);
    final parsed = classify(error.toString());
    return code(parsed.kind, parsed.detail);
  }

  /// Reads a stored error: a code, or the English text earlier builds saved.
  static DownloadError classify(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return const DownloadError(DownloadErrorKind.unknown);

    if (text.startsWith(_prefix)) {
      final parts = text.substring(_prefix.length).split(':');
      final kind = DownloadErrorKind.values
          .where((k) => k.name == parts.first)
          .firstOrNull;
      if (kind != null) {
        return DownloadError(
          kind,
          parts.length > 1 ? int.tryParse(parts[1]) : null,
        );
      }
      return const DownloadError(DownloadErrorKind.unknown);
    }

    final lower = text.toLowerCase();
    final reconnect = RegExp(r'reconnecting.*?attempt (\d+)').firstMatch(lower);
    if (reconnect != null) {
      return DownloadError(
        DownloadErrorKind.reconnecting,
        int.tryParse(reconnect.group(1)!),
      );
    }
    if (lower.contains('invalid download path')) {
      return const DownloadError(DownloadErrorKind.invalidPath);
    }
    if (lower.contains('moved or deleted')) {
      return const DownloadError(DownloadErrorKind.fileMissing);
    }
    if (lower.contains('torrent downloads')) {
      return const DownloadError(DownloadErrorKind.torrentUnsupported);
    }
    if (lower.contains('debrid')) {
      return const DownloadError(DownloadErrorKind.noDebridLink);
    }
    if (lower.contains('empty download url') ||
        lower.contains('empty hls stream url')) {
      return const DownloadError(DownloadErrorKind.emptyUrl);
    }
    if (lower.contains('disk space') || lower.contains('no space left')) {
      return const DownloadError(DownloadErrorKind.notEnoughSpace);
    }
    if (lower.contains('failed to save final file') ||
        lower.contains('filesystemexception')) {
      return const DownloadError(DownloadErrorKind.saveFailed);
    }
    final status = RegExp(r'http (\d{3})').firstMatch(lower);
    if (status != null) {
      return DownloadError(
        DownloadErrorKind.httpStatus,
        int.tryParse(status.group(1)!),
      );
    }
    if (lower.contains('socketexception') ||
        lower.contains('httpexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('timeoutexception') ||
        lower.contains('timed out') ||
        lower.contains('connection') ||
        lower.contains('host lookup') ||
        lower.contains('failed to fetch segment')) {
      return const DownloadError(DownloadErrorKind.network);
    }
    if (lower.contains('#extm3u') ||
        lower.contains('media segments') ||
        lower.contains('hls')) {
      return const DownloadError(DownloadErrorKind.badPlaylist);
    }
    return const DownloadError(DownloadErrorKind.unknown);
  }
}

/// Thrown inside the download engines for a failure with a known kind.
class DownloadFailure implements Exception {
  const DownloadFailure(this.kind, [this.detail]);

  final DownloadErrorKind kind;
  final int? detail;

  @override
  String toString() => DownloadError.code(kind, detail);
}
