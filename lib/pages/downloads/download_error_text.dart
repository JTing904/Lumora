import '../../l10n/generated/app_localizations.dart';
import '../../services/download/download_error.dart';

/// A task's stored error in the user's language. Never shows the stored text
/// itself, which may be an English exception message from an earlier build.
String downloadErrorText(AppLocalizations l10n, String? stored) {
  final error = DownloadError.classify(stored);
  switch (error.kind) {
    case DownloadErrorKind.invalidPath:
      return l10n.dlErrInvalidPath;
    case DownloadErrorKind.fileMissing:
      return l10n.dlErrFileMissing;
    case DownloadErrorKind.torrentUnsupported:
      return l10n.dlErrTorrentUnsupported;
    case DownloadErrorKind.noDebridLink:
      return l10n.dlErrNoDebridLink;
    case DownloadErrorKind.emptyUrl:
      return l10n.dlErrEmptyUrl;
    case DownloadErrorKind.httpStatus:
      final status = error.detail;
      return status == null ? l10n.dlErrNetwork : l10n.dlErrHttpStatus(status);
    case DownloadErrorKind.notEnoughSpace:
      return l10n.dlErrNotEnoughSpace;
    case DownloadErrorKind.reconnecting:
      return l10n.dlErrReconnecting(error.detail ?? 1);
    case DownloadErrorKind.saveFailed:
      return l10n.dlErrSaveFailed;
    case DownloadErrorKind.badPlaylist:
      return l10n.dlErrBadPlaylist;
    case DownloadErrorKind.network:
      return l10n.dlErrNetwork;
    case DownloadErrorKind.unknown:
      return l10n.dlUnknownError;
  }
}
