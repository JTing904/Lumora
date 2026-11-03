import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show NetworkImageLoadException;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../account/account_service.dart';
import '../layout/device_profile.dart';

/// Sends uncaught errors from release builds to the `client_errors` table.
///
/// Boring on purpose, like [CrashBreadcrumbs]:
/// * Release builds only, and only for a signed-in account: the table's
///   policy takes rows from invited accounts and nobody else.
/// * Private: messages and stacks go through [scrub] (URLs cut to their
///   scheme, emails, bearer tokens, JWTs, keys, local file paths and hex
///   hashes removed) and are cut to the column limits the table's policy
///   enforces.
///   No user id is sent; the database fills it in from the session.
/// * Quiet: a network failure is not a crash, and the same error (message
///   plus top frames) is sent once per session, at most
///   [maxReportsPerSession] in all. The server allows 50 a day on top.
/// * Harmless: never throws, never awaits on the UI's behalf; the insert is
///   fire-and-forget with a [sendTimeout].
abstract final class CrashReporter {
  static const int maxReportsPerSession = 10;
  static const int maxMessageChars = 2000;
  static const int maxStackChars = 8000;
  static const int maxVersionChars = 40;
  static const int maxPlatformChars = 40;
  static const int maxKindChars = 20;
  static const int dedupeFrames = 3;
  static const Duration sendTimeout = Duration(seconds: 10);

  static final ReportBudget _budget = ReportBudget(maxReportsPerSession);
  static Future<String?>? _version;
  static bool _installed = false;
  static bool _reporting = false;

  /// Chains onto [FlutterError.onError] and [PlatformDispatcher.onError].
  /// Whatever handled errors before still does (debug builds keep printing
  /// them); this only adds the report. Call once, early in `main`.
  static void install() {
    if (_installed) return;
    _installed = true;

    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      if (previousFlutter != null) {
        previousFlutter(details);
      } else {
        FlutterError.presentError(details);
      }
      if (details.silent) return;
      record(details.exception, details.stack, kind: 'flutter');
    };

    final dispatcher = PlatformDispatcher.instance;
    final previousPlatform = dispatcher.onError;
    dispatcher.onError = (error, stack) {
      record(error, stack, kind: 'platform');
      // Not handled here: the engine still logs it as before.
      return previousPlatform?.call(error, stack) ?? false;
    };
  }

  /// Reports one error. Also the hook for a `runZonedGuarded` handler
  /// (`kind: 'zone'`). Never throws.
  static void record(Object error, StackTrace? stack, {required String kind}) {
    if (!kReleaseMode || _reporting) return;
    _reporting = true;
    try {
      if (isNetworkNoise(error)) return;
      if (!AccountService.configured || !AccountService.signedIn) return;
      final message = prepareMessage(error);
      final trace = prepareStack(stack);
      if (!_budget.admit(fingerprint(message, trace))) return;
      unawaited(_send(kind: kind, message: message, stack: trace));
    } catch (_) {
      // Diagnostics must never become the crash.
    } finally {
      _reporting = false;
    }
  }

  static Future<void> _send({
    required String kind,
    required String message,
    required String stack,
  }) async {
    try {
      final row = <String, Object?>{
        'app_version': truncate(await _appVersion() ?? '', maxVersionChars),
        'platform': truncate(platformName(), maxPlatformChars),
        'kind': truncate(kind, maxKindChars),
        'message': message,
        'stack': stack,
      };
      await Supabase.instance.client
          .from('client_errors')
          .insert(row)
          .timeout(sendTimeout);
    } catch (_) {
      // Offline, over the daily limit, or signed out meanwhile: drop it.
    }
  }

  static Future<String?> _appVersion() {
    return _version ??= PackageInfo.fromPlatform()
        .then<String?>((info) => '${info.version}+${info.buildNumber}')
        .timeout(const Duration(seconds: 3))
        .catchError((Object _) => null);
  }

  /// windows, android, android-tv, linux, macos, ios, or other.
  static String platformName() {
    try {
      if (Platform.isAndroid) {
        return DeviceProfile.isTelevision ? 'android-tv' : 'android';
      }
      if (Platform.isIOS) return 'ios';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
      if (Platform.isMacOS) return 'macos';
    } catch (_) {}
    return 'other';
  }

  /// Failures of the network rather than the app: a dropped connection, a
  /// slow server, a bad certificate on someone's Wi-Fi, an image host's 404.
  @visibleForTesting
  static bool isNetworkNoise(Object error) =>
      error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is HttpException ||
      error is http.ClientException ||
      error is NetworkImageLoadException;

  @visibleForTesting
  static String prepareMessage(Object error) {
    String text;
    try {
      text = error.toString();
    } catch (_) {
      text = error.runtimeType.toString();
    }
    return truncate(scrub(text), maxMessageChars);
  }

  @visibleForTesting
  static String prepareStack(StackTrace? stack) {
    if (stack == null) return '';
    return truncate(scrub(stack.toString()), maxStackChars);
  }

  /// The same error from the same place: the message and the top
  /// [dedupeFrames] frames. Numbered frames (`#0 …`) are preferred, so the
  /// header of an obfuscated release stack does not stand in for frames.
  @visibleForTesting
  static String fingerprint(String message, String stack) {
    final lines = stack
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && line != '<asynchronous suspension>')
        .toList();
    final frames = lines.where((line) => line.startsWith('#')).toList();
    final top = (frames.isNotEmpty ? frames : lines).take(dedupeFrames);
    return '$message\n${top.join('\n')}';
  }

  /// Cuts [text] to at most [max] UTF-16 units, ending in `…` when cut.
  /// Postgres counts characters, never more than UTF-16 units, so the
  /// result always passes the table's `char_length` checks. A surrogate
  /// pair is never split.
  @visibleForTesting
  static String truncate(String text, int max) {
    if (text.length <= max) return text;
    if (max <= 0) return '';
    var end = max - 1;
    if (end > 0) {
      final last = text.codeUnitAt(end - 1);
      if (last >= 0xD800 && last <= 0xDBFF) end--;
    }
    return '${text.substring(0, end)}…';
  }

  /// Any `scheme://…` URL, up to whitespace, a quote or a bracket.
  static final RegExp _url = RegExp(
    r'''[a-zA-Z][a-zA-Z0-9+.\-]*://[^\s"'<>()\[\]{}\\]+''',
  );
  static final RegExp _email = RegExp(
    r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}',
  );
  static final RegExp _authHeader = RegExp(
    r'\b(Bearer|Basic|Token)\s+[A-Za-z0-9._~+/=\-]+',
    caseSensitive: false,
  );
  static final RegExp _jwt = RegExp(
    r'eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+(?:\.[A-Za-z0-9_\-]*)?',
  );
  static final RegExp _knownKey = RegExp(
    r'\b(?:sb_(?:publishable|secret)_|sk[-_](?:live_|test_)?|pk_(?:live|test)_|'
    r'ghp_|gho_|ghu_|ghs_|github_pat_|xox[abprs]-|AIza|AKIA)[A-Za-z0-9_\-]{8,}',
  );
  static final RegExp _secretPair = RegExp(
    r'''\b([A-Za-z_\-]*(?:api[_\-]?key|apikey|token|secret|password|passwd|pwd|'''
    r'''authorization|auth|session|signature|sig|key))(\s*[=:]\s*)["']?[^\s"'&,;)}\]]+''',
    caseSensitive: false,
  );
  static final RegExp _query = RegExp(
    r'''\?[^\s"'<>()\[\]{}]*=[^\s"'<>()\[\]{}]*''',
  );

  /// A local path inside quotes, as `FileSystemException` prints it: the
  /// whole quoted text, because a file name may hold spaces.
  static final RegExp _quotedPath = RegExp(
    r'''(['"])((?:[A-Za-z]:[\\/]|\\\\|/)[^'"\r\n]*)\1''',
  );

  /// A Windows path on any drive (`D:\Movies\…`, `C:/…`) or share
  /// (`\\server\…`). A folder name may hold spaces, so a segment runs to the
  /// next separator, but never ends in one (Windows does not allow it), so
  /// two paths in one sentence stay two; the last segment stops at
  /// whitespace. The drive letter must stand alone, so `https://` is not a
  /// drive.
  static final RegExp _windowsPath = RegExp(
    r'''(?<![A-Za-z0-9+.\-])(?:[A-Za-z]:[\\/]+|\\\\)'''
    r'''(?:[^\\/\r\n"'<>|*?:]*[^\\/\s"'<>|*?:][\\/]+)*[^\\/\s"'<>|*?:]*''',
  );

  /// An absolute Unix path of two or more segments (`/home/…`,
  /// `/storage/emulated/0/Download/…`), starting where a path can start, so
  /// the `/[redacted]` an earlier step leaves after a URL is not one.
  static final RegExp _unixPath = RegExp(
    r'''(?<![^\s'"(=,\[])/(?:[^/\s'"<>()]+/)+[^/\s'"<>()]*''',
  );

  /// File names that come from the app itself rather than from the user's
  /// media, so they are worth keeping when the folder is dropped.
  static final RegExp _appFileName = RegExp(
    r'^[A-Za-z0-9_\-.]+\.(?:dll|exe|so|dylib|dart)$',
    caseSensitive: false,
  );

  /// 32 to 64 hex digits in any case: a torrent infohash (40), an MD5 (32) or
  /// a SHA-256 (64) can name exactly what someone was watching. The engine's
  /// `build_id` is kept: it is the same for every copy of a release and is
  /// what an obfuscated stack is symbolicated with.
  static final RegExp _hexToken = RegExp(
    r'''(?<![A-Za-z0-9_])(?<!build_id: ')[0-9a-fA-F]{32,64}(?![A-Za-z0-9_])''',
  );
  static final RegExp _uuid = RegExp(
    r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}\b',
  );

  /// A run of 32+ token characters with upper case, lower case and a digit:
  /// random keys look like that; identifiers and hex build ids do not.
  static final RegExp _longToken = RegExp(
    r'(?<![A-Za-z0-9_\-])(?=[A-Za-z0-9_\-]*[A-Z])(?=[A-Za-z0-9_\-]*[a-z])'
    r'(?=[A-Za-z0-9_\-]*[0-9])[A-Za-z0-9_\-]{32,}',
  );

  /// Removes what could identify the viewer or unlock something: URLs are
  /// cut to their scheme (the host says which server or addon someone uses,
  /// path and query are where tokens live; a `file:` URL keeps only the file
  /// name), then emails, auth headers, JWTs, known key formats, `key=value`
  /// secrets, stray query strings, local file paths, UUIDs, hex hashes and
  /// long random tokens.
  @visibleForTesting
  static String scrub(String text) {
    var out = text.replaceAllMapped(_url, (m) => _originOf(m[0]!));
    out = out.replaceAll(_email, '[email]');
    out = out.replaceAllMapped(_authHeader, (m) => '${m[1]} [redacted]');
    out = out.replaceAll(_jwt, '[jwt]');
    out = out.replaceAll(_knownKey, '[key]');
    out = out.replaceAllMapped(_secretPair, (m) => '${m[1]}${m[2]}[redacted]');
    out = out.replaceAll(_query, '?[redacted]');
    out = out.replaceAllMapped(
      _quotedPath,
      (m) => '${m[1]}${_pathPlaceholder(m[2]!)}${m[1]}',
    );
    out = out.replaceAllMapped(_windowsPath, (m) => _pathPlaceholder(m[0]!));
    out = out.replaceAllMapped(_unixPath, (m) => _pathPlaceholder(m[0]!));
    out = out.replaceAll(_uuid, '[uuid]');
    out = out.replaceAll(_hexToken, '[hash]');
    out = out.replaceAll(_longToken, '[redacted]');
    return out;
  }

  /// `[path]`, plus the file's extension so the kind of file survives, or the
  /// whole name when it is one of the app's own binaries or sources.
  static String _pathPlaceholder(String path) {
    final name = path.split(RegExp(r'[\\/]')).last.trim();
    if (_appFileName.hasMatch(name)) return '[path]/$name';
    final ext = RegExp(r'\.([A-Za-z0-9]{1,8})$').firstMatch(name);
    return ext == null ? '[path]' : '[path].${ext[1]}';
  }

  static String _originOf(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.isEmpty) return '[url]';
    if (uri.scheme == 'file') {
      // Keep the file name and line (`main.dart:12:5`), not the folders.
      final name = raw.split(RegExp(r'[\\/]')).last.split('?').first;
      return 'file:///[path]/${name.split('#').first}';
    }
    if (uri.host.isEmpty) return '[url]';
    // This machine's own servers say nothing about the viewer and tell a
    // local engine's failure apart from a remote one.
    if (_isLoopback(uri.host)) {
      final port = uri.hasPort ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$port/[redacted]';
    }
    return '${uri.scheme}://[host]/[redacted]';
  }

  static bool _isLoopback(String host) =>
      host == 'localhost' ||
      host == '::1' ||
      host == '[::1]' ||
      host.startsWith('127.');

  @visibleForTesting
  static void debugReset() {
    _budget.reset();
    _version = null;
    _reporting = false;
  }
}

/// Which errors a session still sends: each fingerprint once, [limit] in
/// all. Holds at most [limit] fingerprints.
@visibleForTesting
class ReportBudget {
  ReportBudget(this.limit);

  final int limit;
  final Set<String> _seen = <String>{};

  int get sent => _seen.length;

  /// Whether to send the error with [fingerprint]; counts it if so.
  bool admit(String fingerprint) {
    if (_seen.length >= limit || _seen.contains(fingerprint)) return false;
    _seen.add(fingerprint);
    return true;
  }

  void reset() => _seen.clear();
}
