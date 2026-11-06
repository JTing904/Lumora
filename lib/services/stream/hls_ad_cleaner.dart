import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'hls_ad_filter.dart';

/// What [HlsAdCleaner.clean] hands the player.
class HlsAdCleanOutcome {
  const HlsAdCleanOutcome(this.url, {this.removedSeconds = 0});

  /// The address to open: a local playlist when ads were cut, otherwise the
  /// address that was asked about.
  final String url;

  /// How much advert the local playlist leaves out.
  final double removedSeconds;

  bool get cleaned => removedSeconds > 0;
}

/// Opens 中文资源站 playlists without the ads those sites splice into them.
///
/// The playlist is fetched, [HlsAdFilter] cuts the ad blocks, and the result
/// is written to a file in the temp folder with every address absolute, so the
/// player opens the file and still fetches the film's segments from the site.
/// The ads are not skipped over, they are not in the playlist at all, which is
/// why subtitles and resume positions line up again.
///
/// Playback never waits on this for long and never fails because of it: any
/// error, a page that is not a playlist, a slow site or a playlist with no ads
/// all give back the original address.
class HlsAdCleaner {
  HlsAdCleaner({
    http.Client? client,
    Future<Directory> Function()? tempDirectory,
    this.timeout = const Duration(seconds: 4),
  }) : _client = client,
       _tempDirectory = tempDirectory ?? getTemporaryDirectory;

  static final HlsAdCleaner instance = HlsAdCleaner();

  /// The provider whose playlists carry the ads, as the source row names it.
  static const providerName = '中文资源站';

  /// How long the whole job may take, fetches included.
  final Duration timeout;

  final http.Client? _client;
  final Future<Directory> Function() _tempDirectory;

  static bool _sweptOldFiles = false;

  /// Whether [url] from [provider] is a playlist this is meant for.
  static bool appliesTo(String? provider, String url) {
    if (provider != providerName) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }
    return uri.path.toLowerCase().contains('.m3u8');
  }

  static const _folderName = 'lumora_hls';

  /// Whether [url] is a playlist this wrote, the kind that names http
  /// segments from a file.
  static bool isCleanedPlaylist(String url) =>
      url.startsWith('file:') &&
      url.contains('/$_folderName/') &&
      url.endsWith('.m3u8');

  /// mpv's ffmpeg refuses to fetch http segments named by a playlist it read
  /// from a file unless told otherwise (`Protocol 'http' not on whitelist
  /// 'file,crypto,data'`). The list has commas, so it is length-prefixed in
  /// mpv's option syntax.
  static const mpvDemuxerOptions =
      'strict=experimental,protocol_whitelist=%35%file,http,https,tcp,tls,'
      'crypto,data';

  /// The address to open in place of [url]. [headers] are the ones the player
  /// will send, so a site that wants a Referer answers the same here.
  Future<HlsAdCleanOutcome> clean(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    final original = HlsAdCleanOutcome(url);
    final deadline = DateTime.now().add(timeout);
    try {
      return await _clean(
        url,
        headers,
        deadline,
      ).timeout(timeout, onTimeout: () => original);
    } catch (e) {
      debugPrint('[HlsAdCleaner] Left the playlist alone: $e');
      return original;
    }
  }

  Future<HlsAdCleanOutcome> _clean(
    String url,
    Map<String, String> headers,
    DateTime deadline,
  ) async {
    final original = HlsAdCleanOutcome(url);
    final base = Uri.parse(url);
    if (base.scheme != 'http' && base.scheme != 'https') return original;
    final text = await _fetch(base, headers, deadline);
    if (text == null) return original;

    if (!HlsAdFilter.isMaster(text)) {
      final result = HlsAdFilter.clean(text, base);
      _log(url, result);
      if (!result.changed) return original;
      final file = await _write(_name(url), result.playlist, deadline);
      return HlsAdCleanOutcome(file, removedSeconds: result.removedSeconds);
    }

    // A master playlist: clean each rendition and point a local copy of the
    // master at the cleaned ones. Players pick among them as they would have.
    final variants = HlsAdFilter.variants(text, base);
    if (variants.isEmpty) return original;
    final results = await Future.wait([
      for (final v in variants) _cleanVariant(v.uri, headers, deadline),
    ]);
    final cleaned = <String, HlsCleanResult>{};
    for (var i = 0; i < variants.length; i++) {
      final result = results[i];
      if (result != null && result.changed) cleaned[variants[i].uri] = result;
    }
    if (cleaned.isEmpty) return original;

    final id = _name(url);
    final files = <String, String>{};
    var index = 0;
    for (final entry in cleaned.entries) {
      files[entry.key] = await _write(
        '$id.v${index++}',
        entry.value.playlist,
        deadline,
      );
    }
    final removed = cleaned.values
        .map((r) => r.removedSeconds)
        .reduce((a, b) => a > b ? a : b);

    // One rendition and nothing else in the master: the media playlist alone
    // is the same thing without a second file.
    if (variants.length == 1 && !text.contains('#EXT-X-MEDIA:')) {
      return HlsAdCleanOutcome(files.values.single, removedSeconds: removed);
    }
    final master = HlsAdFilter.absolutize(text, base, replace: (u) => files[u]);
    final file = await _write(id, master, deadline);
    return HlsAdCleanOutcome(file, removedSeconds: removed);
  }

  Future<HlsCleanResult?> _cleanVariant(
    String url,
    Map<String, String> headers,
    DateTime deadline,
  ) async {
    try {
      final base = Uri.parse(url);
      final text = await _fetch(base, headers, deadline);
      if (text == null || HlsAdFilter.isMaster(text)) return null;
      final result = HlsAdFilter.clean(text, base);
      _log(url, result);
      return result;
    } catch (e) {
      debugPrint('[HlsAdCleaner] Variant left alone: $e');
      return null;
    }
  }

  /// The playlist at [uri], or null when it is not one.
  Future<String?> _fetch(
    Uri uri,
    Map<String, String> headers,
    DateTime deadline,
  ) async {
    final left = deadline.difference(DateTime.now());
    if (left <= Duration.zero) return null;
    final client = _client ?? http.Client();
    try {
      final res = await client.get(uri, headers: headers).timeout(left);
      if (res.statusCode != 200) return null;
      // A film's playlist is a few hundred kilobytes; more is not one.
      if (res.bodyBytes.length > 8 * 1024 * 1024) return null;
      final text = utf8.decode(res.bodyBytes, allowMalformed: true);
      return HlsAdFilter.looksLikePlaylist(text) ? text : null;
    } finally {
      if (_client == null) client.close();
    }
  }

  void _log(String url, HlsCleanResult result) {
    if (result.changed) {
      debugPrint(
        '[HlsAdCleaner] Removed ${result.removedSeconds.toStringAsFixed(1)} s '
        'of ads (${result.removedBlocks} blocks, ${result.removedSegments} '
        'segments) from ${_redact(url)}',
      );
    } else {
      debugPrint(
        '[HlsAdCleaner] No ads removed from ${_redact(url)}'
        '${result.skipReason == null ? '' : ' (${result.skipReason})'}',
      );
    }
  }

  static String _redact(String url) {
    final uri = Uri.tryParse(url);
    return uri == null ? url : '${uri.host}${uri.path}';
  }

  /// A file name for [url]: the same address always lands on the same file,
  /// so a reopen overwrites rather than piling up.
  static String _name(String url) {
    var hash = 0xcbf29ce484222325;
    for (final byte in utf8.encode(url)) {
      hash = (hash ^ byte) * 0x100000001b3;
    }
    return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }

  /// Writes [playlist] as `<name>.m3u8` and returns its `file://` address.
  ///
  /// The extension matters: Media3 picks the HLS parser from it.
  Future<String> _write(String name, String playlist, DateTime deadline) async {
    final folder = Directory(
      '${(await _tempDirectory()).path}${Platform.pathSeparator}$_folderName',
    );
    await folder.create(recursive: true);
    _sweepOldFiles(folder);
    final file = File('${folder.path}${Platform.pathSeparator}$name.m3u8');
    // Whole or not at all: an earlier open of the same address may still be
    // reading the file it replaces.
    final partial = File('${file.path}.tmp');
    try {
      await partial.writeAsString(playlist, flush: true);
      await partial.rename(file.path);
    } catch (_) {
      await file.writeAsString(playlist, flush: true);
    }
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('playlist written after the deadline');
    }
    return file.uri.toString();
  }

  /// Drops playlists from earlier days, once per run.
  static void _sweepOldFiles(Directory folder) {
    if (_sweptOldFiles) return;
    _sweptOldFiles = true;
    unawaited(() async {
      try {
        final cutoff = DateTime.now().subtract(const Duration(days: 1));
        await for (final f in folder.list()) {
          if (f is File && (await f.lastModified()).isBefore(cutoff)) {
            await f.delete();
          }
        }
      } catch (_) {}
    }());
  }
}
