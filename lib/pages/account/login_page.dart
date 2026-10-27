import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../services/account/account_service.dart';
import '../../services/theme/design_tokens.dart';
import '../../widgets/common/pill_button.dart';
import '../../widgets/common/zplay_logo.dart';

/// Shows [child] once signed in, the sign-in page until then.
///
/// Without a Supabase project ([AccountService.configured] false: tests, a
/// build whose client did not start) nothing is asked.
class AccountGate extends StatelessWidget {
  const AccountGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AccountService.configured) return child;
    return ValueListenableBuilder(
      valueListenable: AccountService.session,
      builder: (context, session, _) =>
          session != null ? child : const LoginPage(),
    );
  }
}

/// 登录 and 注册. Signing up needs an invite code, once; signing in never.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.signUp, this.signIn});

  /// Stand-ins for [AccountService] in tests.
  final Future<SignUpResult> Function(String email, String password, String code)?
  signUp;
  final Future<void> Function(String email, String password)? signIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _invite = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _invite.dispose();
    super.dispose();
  }

  String _message(AppLocalizations l10n, AccountError e) => switch (e) {
    AccountError.invalidInvite => l10n.authErrInvalidInvite,
    AccountError.wrongPassword => l10n.authErrWrongPassword,
    AccountError.emailTaken => l10n.authErrEmailTaken,
    AccountError.weakPassword => l10n.authErrWeakPassword,
    AccountError.invalidEmail => l10n.authErrInvalidEmail,
    AccountError.emailNotConfirmed => l10n.authErrEmailNotConfirmed,
    AccountError.network => l10n.authErrNetwork,
    AccountError.unknown => l10n.authErrUnknown,
  };

  Future<void> _submit() async {
    final l10n = l10nOf(context);
    final email = _email.text.trim();
    final password = _password.text;
    final code = _invite.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = l10n.authErrInvalidEmail);
      return;
    }
    if (password.length < 6) {
      setState(() => _error = l10n.authErrWeakPassword);
      return;
    }
    if (_registering && normalizeInviteCode(code).isEmpty) {
      setState(() => _error = l10n.authErrInviteMissing);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      if (_registering) {
        final result = await (widget.signUp ?? AccountService.signUp)(
          email,
          password,
          code,
        );
        if (!mounted) return;
        if (result == SignUpResult.confirmEmail) {
          setState(() {
            _registering = false;
            _notice = l10n.authConfirmEmail;
          });
        }
      } else {
        await (widget.signIn ?? AccountService.signIn)(email, password);
      }
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = _message(l10n, e.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          // The brand's light and shadow: a warm glow from the top left.
          gradient: RadialGradient(
            center: const Alignment(-0.8, -0.9),
            radius: 1.4,
            colors: [tokens.accent.withValues(alpha: 0.16), tokens.bg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ZplaySpacing.s24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: ZplayLogo(size: 56)),
                      const SizedBox(height: ZplaySpacing.s12),
                      Text(
                        'Lumora',
                        textAlign: TextAlign.center,
                        style: ZplayType.display
                            .copyWith(size: 34, letterSpacing: 1)
                            .toStyle(color: tokens.textPrimary),
                      ),
                      const SizedBox(height: ZplaySpacing.s4),
                      Text(
                        l10n.authTagline,
                        textAlign: TextAlign.center,
                        style: ZplayType.body.toStyle(
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: ZplaySpacing.s32),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(l10n.authSignIn),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(l10n.authSignUp),
                          ),
                        ],
                        selected: {_registering},
                        showSelectedIcon: false,
                        onSelectionChanged: _busy
                            ? null
                            : (s) => setState(() {
                                _registering = s.first;
                                _error = null;
                                _notice = null;
                              }),
                      ),
                      const SizedBox(height: ZplaySpacing.s20),
                      _Field(
                        controller: _email,
                        label: l10n.authEmail,
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        autofill: const [AutofillHints.email],
                        autofocus: true,
                      ),
                      const SizedBox(height: ZplaySpacing.s12),
                      _Field(
                        controller: _password,
                        label: l10n.authPassword,
                        icon: Icons.lock_outline_rounded,
                        obscure: !_showPassword,
                        autofill: [
                          _registering
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        trailing: IconButton(
                          tooltip: _showPassword
                              ? l10n.authHidePassword
                              : l10n.authShowPassword,
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                        onSubmitted: _registering ? null : (_) => _submit(),
                      ),
                      if (_registering) ...[
                        const SizedBox(height: ZplaySpacing.s12),
                        _Field(
                          controller: _invite,
                          label: l10n.authInviteCode,
                          icon: Icons.confirmation_number_outlined,
                          capitalize: true,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: ZplaySpacing.s8),
                        Text(
                          l10n.authInviteHint,
                          style: ZplayType.caption.toStyle(
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                      if (_error != null || _notice != null) ...[
                        const SizedBox(height: ZplaySpacing.s16),
                        Text(
                          _error ?? _notice!,
                          style: ZplayType.body.toStyle(
                            color: _error != null
                                ? tokens.danger
                                : tokens.success,
                          ),
                        ),
                      ],
                      const SizedBox(height: ZplaySpacing.s24),
                      PillButton(
                        label: _busy
                            ? l10n.authWorking
                            : (_registering
                                  ? l10n.authSubmitSignUp
                                  : l10n.authSubmitSignIn),
                        icon: _registering
                            ? Icons.person_add_alt_1_rounded
                            : Icons.login_rounded,
                        expand: true,
                        onPressed: _busy ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.autofill = const [],
    this.trailing,
    this.onSubmitted,
    this.autofocus = false,
    this.capitalize = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final List<String> autofill;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool capitalize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final border = OutlineInputBorder(
      borderRadius: ZplayRadius.mdAll,
      borderSide: BorderSide(color: tokens.borderDefault),
    );
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofill,
      autofocus: autofocus,
      autocorrect: false,
      enableSuggestions: !obscure,
      textCapitalization: capitalize
          ? TextCapitalization.characters
          : TextCapitalization.none,
      onSubmitted: onSubmitted,
      textInputAction: onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      style: ZplayType.body.toStyle(color: tokens.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: tokens.textMuted),
        suffixIcon: trailing,
        filled: true,
        fillColor: tokens.surface.withValues(alpha: 0.7),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: tokens.accent, width: 1.5),
        ),
      ),
    );
  }
}
