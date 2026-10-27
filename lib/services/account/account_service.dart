import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  static Future<void> initialize() async {
    final url = EnvService.get('SUPABASE_URL', defaultValue: _defaultSupabaseUrl);
    final key = EnvService.get(
      'SUPABASE_ANON_KEY',
      defaultValue: _defaultSupabaseKey,
    );
    try {
      await Supabase.initialize(url: url, anonKey: key);
      _configured = true;
    } catch (e) {
      debugPrint('[AccountService] Supabase did not start: $e');
      return;
    }
    session.value = _client.auth.currentSession;
    _authSub = _client.auth.onAuthStateChange.listen((state) {
      session.value = state.session;
      unawaited(_refreshAdmin());
    });
    unawaited(_refreshAdmin());
  }

  @visibleForTesting
  static void debugReset() {
    _authSub?.cancel();
    _authSub = null;
    _configured = false;
    session.value = null;
  }

  /// Asks the server whether this account is an admin. Signed out, or on any
  /// failure, it is not.
  static Future<void> _refreshAdmin() async {
    if (!signedIn) {
      await ContentSettings.setAdmin(false);
      return;
    }
    try {
      final result = await _client.rpc('is_admin');
      await ContentSettings.setAdmin(result == true);
    } catch (e) {
      debugPrint('[AccountService] is_admin failed: $e');
      await ContentSettings.setAdmin(false);
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
      valid = await _client.rpc('invite_code_valid', params: {'code': code}) ==
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

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } finally {
      session.value = null;
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
    return [
      for (final r in rows as List) (r as Map)['code'].toString(),
    ];
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
      'email_address_invalid' || 'validation_failed' => AccountError.invalidEmail,
      'email_not_confirmed' => AccountError.emailNotConfirmed,
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
