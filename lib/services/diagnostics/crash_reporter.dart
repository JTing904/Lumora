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
///   origin, emails, bearer tokens, JWTs, keys and home-folder names
///   removed) and are cut to the column limits the table's policy enforces.
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
  static final RegExp _windowsHome = RegExp(
    // A Windows user name may hold spaces: up to the next separator.
    r'''([A-Za-z]:[\\/]+(?:Users|Documents and Settings)[\\/]+)'''
    r'''(?:[^\\/"'<>\r\n]+(?=[\\/])|[^\\/\s"'<>]+)''',
    caseSensitive: false,
  );
  static final RegExp _unixHome = RegExp(r'''(/(?:home|Users)/)[^/\s"'<>]+''');
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
  /// cut to their origin (path and query are where tokens live; a `file:`
  /// URL keeps only the file name), then emails, auth headers, JWTs, known
  /// key formats, `key=value` secrets, stray query strings, home-folder
  /// names, UUIDs and long random tokens.
  @visibleForTesting
  static String scrub(String text) {
    var out = text.replaceAllMapped(_url, (m) => _originOf(m[0]!));
    out = out.replaceAll(_email, '[email]');
    out = out.replaceAllMapped(_authHeader, (m) => '${m[1]} [redacted]');
    out = out.replaceAll(_jwt, '[jwt]');
    out = out.replaceAll(_knownKey, '[key]');
    out = out.replaceAllMapped(_secretPair, (m) => '${m[1]}${m[2]}[redacted]');
    out = out.replaceAll(_query, '?[redacted]');
    out = out.replaceAllMapped(_windowsHome, (m) => '${m[1]}[user]');
    out = out.replaceAllMapped(_unixHome, (m) => '${m[1]}[user]');
    out = out.replaceAll(_uuid, '[uuid]');
    out = out.replaceAll(_longToken, '[redacted]');
    return out;
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
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port/[redacted]';
  }

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
