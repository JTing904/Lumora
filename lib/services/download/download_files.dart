import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../models/download/download_task_model.dart';
import '../../utils/download/download_path_helper.dart';

/// Where a download's bytes go on disk, and whether a half-written `.part`
/// file may be continued.
///
/// A `.part` file is only ever appended to by the source that started it.
/// Retrying an episode from another source used to send a Range request to
/// source B and append its bytes onto source A's partial file, which spliced
/// two different encodes into one unplayable file. So a sidecar next to the
/// `.part` records a hash of the source that wrote it, and anything else
/// starts the file over.
abstract final class DownloadFiles {
  static const String partSuffix = '.part';
  static const String hlsMetaSuffix = '.hls_meta.json';
  static const String sourceSuffix = '.part.source';

  /// The file name, without extension, for one title (and episode).
  ///
  /// The media id is part of the name because two titles can share a name
  /// ("Dune" 1984 and 2021); with the title alone they shared one path, and
  /// finishing one deleted the other. Downloads already on disk keep their
  /// old names, since each task records its full path.
  static String baseFilename({
    required String title,
    required String mediaId,
    int? season,
    int? episode,
  }) {
    final safeTitle = DownloadPathHelper.sanitizeFilename(title);
    final epSuffix = (season != null && episode != null)
        ? '_S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}'
        : '';
    final safeId = DownloadPathHelper.sanitizeFilename(
      mediaId,
    ).replaceAll(' ', '_');
    final idSuffix = safeId.isEmpty ? '' : '_$safeId';
    return '$safeTitle$epSuffix$idSuffix';
  }

  /// What identifies the bytes a task downloads.
  ///
  /// A debrid link is re-resolved on every attempt and can change while the
  /// file behind it does not, so a debrid task is keyed by its torrent and
  /// file index instead of the link.
  static String sourceKey(DownloadTask task) {
    if (task.sourceType == DownloadSourceType.debrid) {
      final torrent = (task.infoHash?.isNotEmpty ?? false)
          ? task.infoHash!.toLowerCase()
          : (task.magnet ?? '');
      return 'debrid:$torrent#${task.fileIdx ?? -1}';
    }
    return 'url:${task.rawUrl ?? ''}';
  }

  /// The sidecar holds a hash, not the URL, because source URLs often carry
  /// account tokens and the sidecar sits in the user's Downloads folder.
  static String sourceFingerprint(String sourceKey) =>
      sha256.convert(utf8.encode(sourceKey)).toString();

  /// Whether a recorded fingerprint lets a `.part` be continued. A `.part`
  /// with no record came from a build that did not write one, so its source
  /// is unknown and it is not trusted.
  static bool canResume({
    required String? recordedFingerprint,
    required String sourceKey,
  }) {
    if (recordedFingerprint == null || recordedFingerprint.isEmpty) {
      return false;
    }
    return recordedFingerprint.trim() == sourceFingerprint(sourceKey);
  }

  static File partFile(String targetFilePath) =>
      File('$targetFilePath$partSuffix');

  static File _sourceFile(String targetFilePath) =>
      File('$targetFilePath$sourceSuffix');

  /// True when the `.part` (if any) next to [targetFilePath] was written by
  /// [sourceKey].
  static Future<bool> partBelongsTo(
    String targetFilePath,
    String sourceKey,
  ) async {
    String? recorded;
    try {
      final file = _sourceFile(targetFilePath);
      if (await file.exists()) recorded = await file.readAsString();
    } catch (_) {}
    return canResume(recordedFingerprint: recorded, sourceKey: sourceKey);
  }

  /// Makes sure whatever partial data sits at [targetFilePath] belongs to
  /// [sourceKey], deleting it when it does not. Returns whether partial data
  /// was kept.
  static Future<bool> keepPartOnlyFor(
    String targetFilePath,
    String sourceKey,
  ) async {
    final part = partFile(targetFilePath);
    final hasPart = await part.exists();
    final hasMeta = await File('$targetFilePath$hlsMetaSuffix').exists();
    if (!hasPart && !hasMeta) return false;
    if (await partBelongsTo(targetFilePath, sourceKey)) return hasPart;
    debugPrint(
      '[DownloadFiles] partial file came from another source; starting over',
    );
    await discardPart(targetFilePath);
    return false;
  }

  /// Records [sourceKey] as the writer of the `.part` at [targetFilePath].
  /// Called before the first byte of a fresh `.part` is written.
  static Future<void> claimPart(String targetFilePath, String sourceKey) async {
    final file = _sourceFile(targetFilePath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(sourceFingerprint(sourceKey), flush: true);
  }

  /// Removes the partial file and its bookkeeping.
  static Future<void> discardPart(String targetFilePath) async {
    for (final path in [
      '$targetFilePath$partSuffix',
      '$targetFilePath$hlsMetaSuffix',
      '$targetFilePath$sourceSuffix',
    ]) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Removes the source record once the `.part` has become the final file.
  static Future<void> forgetSource(String targetFilePath) async {
    try {
      final file = _sourceFile(targetFilePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
