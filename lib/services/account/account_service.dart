import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import '../config/env_service.dart';
import '../content/content_settings.dart';

/// The Lumora project the app signs in to.
///
/// Both values are public by design: the publishable key only lets a client
/// do what the row-level security policies and the server functions allow,
/// so it ships in the app (and in this open-source repository). No secret
/// key is ever in the app. `.env` may point a build at another project.
const String _defaultSupabaseUrl = 'https://wfrmsxoshloeaxykwzbg.supabase.co';
const String _defaultSupabaseKey =
    'sb_publishable_-yRUFbPNiGVVfGoCdEt_xQ_tmz2PKCp';

/// Why a sign-in or sign-up did not go through, in words the page can show.
enum AccountError {
  invalidInvite,
  wrongPassword,
  emailTaken,
  weakPassword,
  invalidEmail,
  emailNotConfirmed,
  samePassword,
  network,
  unknown,
}

class AccountException implements Exception {
  const AccountException(this.error, [this.detail]);

  final AccountError error;
  final String? detail;

  @override
  String toString() => 'AccountException($error, $detail)';
}

/// What a sign-up ended in.
enum SignUpResult {
  /// Signed in straight away.
  signedIn,

  /// The account exists; the project wants the address confirmed first.
  confirmEmail,
}

/// The Lumora account: signing in, signing up with an invite code, and who
/// is an admin.
///
/// Everything that matters is decided on the server. A sign-up without a
/// valid one-time code is refused by the database trigger that creates the
/// account, whatever this client sends; [signUp] only asks first so the page
/// can say "邀请码无效" instead of a generic error. Admin status comes from
/// the account's server-set `app_metadata.role`, read through `is_admin()`,
/// and drives [ContentSettings.setAdmin].
abstract final class AccountService {
  /// Signed in, or not. Null before [initialize] and when signed out.
  static final ValueNotifier<Session?> session = ValueNotifier(null);

  static bool _configured = false;
  static StreamSubscription<AuthState>? _authSub;

  /// Whether the app has a Supabase project to sign in to. Off in tests and
  /// in a build that could not start the client; then no sign-in is asked.
  static bool get configured => _configured;

  static bool get signedIn => session.value != null;

  static String? get email => session.value?.user.email;

  static SupabaseClient get _client => Supabase.instance.client;

  /// The project's address and publishable key, once [initialize] ran.
  /// The TMDb proxy (`functions/v1/tmdb`) is reached through them.
  static String? projectUrl;
  static String? publishableKey;

  /// The signed-in session's token, for calls that need a signed-in user.
  static String? get accessToken => session.value?.accessToken;

  static Future<void> initialize() async {
    // A release build signs in to Lumora's own project only: a `.env` or an
    // environment variable must not point it at a project whose `is_admin`
    // and invite checks say yes to everyone. Debug builds may switch.
    final url = kReleaseMode
        ? _defaultSupabaseUrl
        : EnvService.get('SUPABASE_URL', defaultValue: _defaultSupabaseUrl);
    final key = kReleaseMode
        ? _defaultSupabaseKey
        : EnvService.get('SUPABASE_ANON_KEY', defaultValue: _defaultSupabaseKey);
    try {
      await Supabase.initialize(
        url: url,
        anonKey: key,
        authOptions: const FlutterAuthClientOptions(
          detectSessionInUriPredicate: isOwnAuthCallback,
        ),
      );
      _configured = true;
      projectUrl = url;
      publishableKey = key;
      unawaited(_loadSocialProviders(url, key));
    } catch (e) {
      debugPrint('[AccountService] Supabase did not start: $e');
      return;
    }
    session.value = _client.auth.currentSession;
    _authSub = _client.auth.onAuthStateChange.listen(
      (state) {
        session.value = state.session;
        // Back from a reset email's link: ask for the new password.
        if (state.event == AuthChangeEvent.passwordRecovery) {
          recovering.value = true;
        }
        if (state.session == null) recovering.value = false;
        unawaited(_refreshAccount());
      },
      // A refresh that failed offline, or a provider page the viewer
      // cancelled: nothing to do but not crash.
      onError: (Object e) => debugPrint('[AccountService] auth: $e'),
    );
    unawaited(_refreshAccount());
  }

  /// Only the code a sign-in this app started hands back, on its own scheme.
  /// A link that carries ready-made tokens (`#access_token=...`) is someone
  /// else's session: following it would swap the viewer into that account.
  @visibleForTesting
  static bool isOwnAuthCallback(Uri uri) =>
      uri.scheme == 'io.github.jting904.lumora' &&
      uri.host == 'login-callback' &&
      uri.queryParameters.containsKey('code') &&
      !uri.queryParameters.containsKey('access_token') &&
      !uri.fragment.contains('access_token');

  @visibleForTesting
  static void debugReset() {
    _authSub?.cancel();
    _authSub = null;
    _configured = false;
    session.value = null;
    invitedState.value = null;
  }

  /// Asks the server whether this account is an admin and has used an
  /// invite. Signed out, or on any failure, it is neither. An answer that
  /// arrives after the account changed (signed out, someone else signed in)
  /// is dropped, so one viewer's admin switch never lands on another.
  static Future<void> _refreshAccount() async {
    final uid = session.value?.user.id;
    if (uid == null) {
      invitedState.value = null;
      await ContentSettings.setAdmin(false);
      return;
    }
    bool stillSame() => session.value?.user.id == uid;
    if (session.value?.user.appMetadata['invited'] == true) {
      invitedState.value = true;
    } else {
      try {
        final result = await _client.rpc('is_invited');
        if (stillSame()) invitedState.value = result == true;
      } catch (e) {
        debugPrint('[AccountService] is_invited failed: $e');
        if (stillSame()) invitedState.value = false;
      }
    }
    try {
      final result = await _client.rpc('is_admin');
      if (stillSame()) await ContentSettings.setAdmin(result == true);
    } catch (e) {
      debugPrint('[AccountService] is_admin failed: $e');
      if (stillSame()) await ContentSettings.setAdmin(false);
    }
  }

  static Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AccountException(_authError(e), e.message);
    } catch (e) {
      throw AccountException(AccountError.network, '$e');
    }
  }

  static Future<SignUpResult> signUp(
    String email,
    String password,
    String inviteCode,
  ) async {
    final code = normalizeInviteCode(inviteCode);
    bool valid;
    try {
      valid =
          await _client.rpc('invite_code_valid', params: {'code': code}) ==
          true;
    } catch (e) {
      throw AccountException(AccountError.network, '$e');
    }
    if (!valid) throw const AccountException(AccountError.invalidInvite);
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'invite_code': code},
        // The confirmation link is often opened on another device, one with
        // no Lumora to hand it to: a page that says it worked, then sign in.
        emailRedirectTo: confirmedPage,
      );
      return res.session != null
          ? SignUpResult.signedIn
          : SignUpResult.confirmEmail;
    } on AuthException catch (e) {
      throw AccountException(_authError(e), e.message);
    } catch (e) {
      throw AccountException(AccountError.network, '$e');
    }
  }

  /// True from a password-reset link until the new password is saved.
  static final ValueNotifier<bool> recovering = ValueNotifier(false);

  /// Emails [email] a link that brings the viewer back here, signed in for
  /// setting a new password.
  static Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: oauthRedirect,
      );
    } on AuthException catch (e) {
      throw AccountException(_authError(e), e.message);
    } catch (e) {
      throw AccountException(AccountError.network, '$e');
    }
  }

  /// Signs in with the code from a reset email, on any device: the link in
  /// that email only works on the device that asked for it. Raises the
  /// password-recovery event, so [recovering] asks for the new password.
  static Future<void> verifyResetCode(String email, String code) async {
    try {
      await _client.auth.verifyOTP(
        type: OtpType.recovery,
        email: email.trim(),
        token: code.trim(),
      );
    } on AuthException catch (e) {
      throw AccountException(
        e.statusCode == '403' || e.code == 'otp_expired'
            ? AccountError.invalidInvite
            : _authError(e),
        e.message,
      );
    } catch (e) {
      throw AccountException(AccountError.network, '$e');
    }
  }

  /// Saves [password] for the account the reset link signed in.
  static Future<void> setNewPassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
      recovering.value = false;
    } on AuthException catch (e) {
      throw AccountException(_authError(e), e.message);
    } catch (e) {
      throw AccountException(AccountError.network, '$e');
    }
  }

  /// Where a sign-up's confirmation link lands. Listed in Supabase's Auth
  /// redirect URLs; the page lives in `site/`, published to GitHub Pages.
  static const confirmedPage = 'https://jting904.github.io/Lumora/confirmed.html';

  /// Where the browser hands a social sign-in (and a reset link) back.
  /// Listed in Supabase's Auth redirect URLs; Android and Windows register
  /// the scheme.
  static const oauthRedirect = 'io.github.jting904.lumora://login-callback';

  /// Where a desktop browser hands a social sign-in back: a one-shot listener
  /// on this machine. Chrome silently drops a redirect to a custom scheme that
  /// no click started (GitHub skips its consent page once approved), so on a
  /// computer the scheme link never arrives. Also listed in Supabase's Auth
  /// redirect URLs.
  static const loopbackPort = 43823;
  static const loopbackRedirect =
      'http://localhost:$loopbackPort/login-callback';

  static HttpServer? _loopback;
  static Timer? _loopbackTimeout;

  /// Opens the provider's sign-in in the browser. The session arrives through
  /// [session] when the browser hands back.
  static Future<void> signInWith(OAuthProvider provider) async {
    final desktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final redirect = desktop && await _listenForLoopback()
        ? loopbackRedirect
        : oauthRedirect;
    final opened = await _client.auth.signInWithOAuth(
      provider,
      redirectTo: redirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    if (!opened) throw const AccountException(AccountError.network);
  }

  /// Starts (or keeps) the loopback listener; false when the port is taken.
  static Future<bool> _listenForLoopback() async {
    // Nobody came back: free the port. A retry starts the wait again.
    _loopbackTimeout?.cancel();
    _loopbackTimeout = Timer(const Duration(minutes: 10), _closeLoopback);
    if (_loopback != null) return true;
    try {
      final server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        loopbackPort,
      );
      _loopback = server;
      server.listen((request) async {
        final params = request.uri.queryParameters;
        final code = params['code'];
        if (request.uri.path != '/login-callback' ||
            (code == null && params['error'] == null)) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        var ok = false;
        if (code != null) {
          try {
            await _client.auth.exchangeCodeForSession(code);
            ok = true;
          } catch (e) {
            debugPrint('[AccountService] code exchange: $e');
          }
        }
        request.response.headers.contentType = ContentType.html;
        request.response.write(_loopbackPage(ok));
        await request.response.close();
        // Anything on this machine can knock here; only a sign-in that went
        // through ends the wait, so a stray request cannot cut the real one.
        if (!ok) return;
        _closeLoopback();
        try {
          await windowManager.show();
          await windowManager.focus();
        } catch (_) {}
      });
      return true;
    } catch (e) {
      debugPrint('[AccountService] loopback: $e');
      return false;
    }
  }

  static void _closeLoopback() {
    _loopbackTimeout?.cancel();
    _loopbackTimeout = null;
    _loopback?.close(force: true);
    _loopback = null;
  }

  static String _loopbackPage(bool ok) {
    final title = ok ? '登录成功' : '登录没有完成';
    final body = ok
        ? '可以关闭这个页面，回到 Lumora。<br>You can close this tab and return to Lumora.'
        : '回到 Lumora 再试一次。<br>Go back to Lumora and try again.';
    return '<!doctype html><html lang="zh"><head><meta charset="utf-8">'
        '<title>Lumora</title><style>body{background:#0b0b10;color:#eee;'
        'font-family:system-ui,sans-serif;display:grid;place-items:center;'
        'height:100vh;margin:0;text-align:center}h1{font-weight:600}'
        'p{color:#aaa;line-height:1.7}</style></head><body><div>'
        '<h1>$title</h1><p>$body</p></div></body></html>';
  }

  /// The one-tap sign-ins switched on in Supabase (`github`, `discord`...),
  /// so the sign-in page offers only those that work. Read once at start.
  static final ValueNotifier<Set<String>> socialProviders = ValueNotifier(
    const {},
  );

  static Future<void> _loadSocialProviders(String url, String key) async {
    try {
      final res = await http
          .get(
            Uri.parse('${url.replaceAll(RegExp(r'/+$'), '')}/auth/v1/settings'),
            headers: {'apikey': key},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final external = (jsonDecode(res.body) as Map)['external'];
      if (external is! Map) return;
      socialProviders.value = {
        for (final e in external.entries)
          if (e.value == true && e.key != 'email' && e.key != 'phone')
            e.key.toString(),
      };
    } catch (e) {
      debugPrint('[AccountService] providers: $e');
    }
  }

  /// Whether the signed-in account has used an invite. An email sign-up
  /// always has (the server refuses one without a code); a Google or Facebook
  /// account has once [redeemInvite] succeeded. Read from the server-written
  /// `app_metadata`, which the viewer cannot edit.
  static bool get invited => invitedState.value == true;

  /// [invited] as the server last answered it: null while signed out or
  /// still asking, then true or false. A missing flag is not an invite.
  static final ValueNotifier<bool?> invitedState = ValueNotifier(null);

  /// Spends [code] for this account. False when it is wrong or already used.
  static Future<bool> redeemInvite(String code) async {
    try {
      final ok = await _client.rpc(
        'redeem_invite',
        params: {'code': normalizeInviteCode(code)},
      );
      if (ok != true) return false;
      invitedState.value = true;
      // The flag rides on the token: a fresh one carries it.
      final res = await _client.auth.refreshSession();
      session.value = res.session ?? session.value;
      return true;
    } catch (e) {
      throw AccountException(AccountError.network, '$e');
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } finally {
      session.value = null;
      invitedState.value = null;
      recovering.value = false;
      await ContentSettings.setAdmin(false);
    }
  }

  /// Admin only (the server refuses anyone else): [howMany] new codes.
  static Future<List<String>> createInviteCodes(
    int howMany, {
    String? note,
  }) async {
    final rows = await _client.rpc(
      'create_invite_codes',
      params: {'how_many': howMany, 'note': note},
    );
    return [for (final r in rows as List) (r as Map)['code'].toString()];
  }

  /// Admin only: every code, newest first.
  static Future<List<InviteCode>> listInviteCodes() async {
    final rows = await _client.rpc('list_invite_codes');
    return [for (final r in rows as List) InviteCode.fromJson(r as Map)];
  }

  static AccountError _authError(AuthException e) {
    final code = e.code ?? '';
    final message = e.message.toLowerCase();
    if (message.contains('invalid invite code')) {
      return AccountError.invalidInvite;
    }
    return switch (code) {
      'invalid_credentials' => AccountError.wrongPassword,
      'user_already_exists' || 'email_exists' => AccountError.emailTaken,
      'weak_password' => AccountError.weakPassword,
      'email_address_invalid' ||
      'validation_failed' => AccountError.invalidEmail,
      'email_not_confirmed' => AccountError.emailNotConfirmed,
      'same_password' => AccountError.samePassword,
      _ when message.contains('database error saving new user') =>
        AccountError.invalidInvite,
      _ => AccountError.unknown,
    };
  }
}

/// `lumo-7k3p` -> `LUMO7K3P`, as the server stores codes.
String normalizeInviteCode(String raw) =>
    raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

/// `LUMO7K3P` -> `LUMO-7K3P`, easier to read out and type.
String formatInviteCode(String code) =>
    code.length == 8 ? '${code.substring(0, 4)}-${code.substring(4)}' : code;

@immutable
class InviteCode {
  const InviteCode({
    required this.code,
    this.note,
    required this.createdAt,
    this.usedAt,
    this.usedByEmail,
  });

  factory InviteCode.fromJson(Map json) => InviteCode(
    code: json['code'].toString(),
    note: json['note']?.toString(),
    createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
    usedAt: json['used_at'] == null
        ? null
        : DateTime.parse(json['used_at'].toString()).toLocal(),
    usedByEmail: json['used_by_email']?.toString(),
  );

  final String code;
  final String? note;
  final DateTime createdAt;
  final DateTime? usedAt;
  final String? usedByEmail;

  bool get used => usedAt != null;
}
