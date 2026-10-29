import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../services/account/account_service.dart';
import '../../ui/figure_turntable.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_language_toggle.dart';
import '../../ui/lu_logo.dart';
import '../../ui/lu_text_field.dart';
import '../../ui/lu_theme.dart';
import '../../ui/poster_wall.dart';
import 'splash_page.dart';

/// The splash, then the app once signed in, or the sign-in page until then.
///
/// Without a Supabase project ([AccountService.configured] false: tests, a
/// build whose client did not start) nothing is asked.
class AccountGate extends StatefulWidget {
  const AccountGate({super.key, required this.child, this.splash = true});

  final Widget child;

  /// Show the splash first. Off in tests.
  final bool splash;

  @override
  State<AccountGate> createState() => _AccountGateState();
}

/// A debug build made with `--dart-define=LUMORA_FORCE_LOGIN=true` shows the
/// sign-in page even while signed in, to look at it without signing out.
/// Release builds ignore it.
const bool _forceLogin =
    kDebugMode && bool.fromEnvironment('LUMORA_FORCE_LOGIN');

class _AccountGateState extends State<AccountGate> {
  late bool _splashing = widget.splash && AccountService.configured;

  @override
  Widget build(BuildContext context) {
    if (!AccountService.configured) return widget.child;
    return AnimatedSwitcher(
      duration: LuMotion.page,
      child: _splashing
          ? SplashPage(
              key: const ValueKey('splash'),
              onDone: () => setState(() => _splashing = false),
            )
          // Browsing needs no account; playing does (see [SignInRequired]).
          : _forceLogin
          ? const LoginPage(key: ValueKey('login'))
          : ValueListenableBuilder<bool>(
              key: const ValueKey('app'),
              valueListenable: AccountService.recovering,
              // Back from a reset email: the new password first.
              builder: (context, recovering, child) =>
                  recovering ? const NewPasswordPage() : child!,
              child: widget.child,
            ),
    );
  }
}

/// 登录, and 注册 behind the line under the button: the design's sign-in page,
/// a figure turning on the left and a glass card on the right, over a wall of
/// this week's posters. On a phone the figure sits above the form.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.signUp, this.signIn, this.figure});

  /// Stand-ins for [AccountService] in tests.
  final Future<SignUpResult> Function(
    String email,
    String password,
    String code,
  )?
  signUp;
  final Future<void> Function(String email, String password)? signIn;

  /// The figure to show first; random when null.
  final LuFigure? figure;

  /// The sign-in page as a route of its own, closing itself once signed in.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const _LoginRoute()));

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _invite = TextEditingController();
  late LuFigure _figure =
      widget.figure ??
      LuFigure.values[math.Random().nextInt(LuFigure.values.length)];
  bool _registering = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  String? _notice;

  /// Set once a reset email is on its way: the card asks for its code.
  String? _resetEmail;
  final _resetCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(AccountService.ensureSocialProviders());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _invite.dispose();
    _resetCode.dispose();
    super.dispose();
  }

  String _message(AppLocalizations l10n, AccountError e) => switch (e) {
    AccountError.invalidInvite => l10n.authErrInvalidInvite,
    AccountError.wrongPassword => l10n.authErrWrongPassword,
    AccountError.emailTaken => l10n.authErrEmailTaken,
    AccountError.weakPassword => l10n.authErrWeakPassword,
    AccountError.invalidEmail => l10n.authErrInvalidEmail,
    AccountError.emailNotConfirmed => l10n.authErrEmailNotConfirmed,
    AccountError.samePassword => l10n.authErrSamePassword,
    AccountError.network => l10n.authErrNetwork,
    AccountError.unknown => l10n.authErrUnknown,
  };

  void _toggleMode() => setState(() {
    _registering = !_registering;
    _error = null;
    _notice = null;
  });

  /// GitHub, Discord (or Google, Facebook) in the browser; the session comes
  /// back by itself.
  Future<void> _social(OAuthProvider provider) async {
    // One browser sign-in at a time: a second tap would replace the first
    // one's PKCE verifier and fail it.
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await AccountService.signInWith(provider);
    } catch (_) {
      if (mounted) setState(() => _error = l10nOf(context).authOAuthFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Sends the reset email to the address in the field.
  Future<void> _forgot() async {
    final l10n = l10nOf(context);
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() {
        _notice = null;
        _error = l10n.authForgotNeedEmail;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await AccountService.sendPasswordReset(email);
      if (mounted) {
        setState(() {
          _resetEmail = email;
          _resetCode.clear();
        });
      }
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = _message(l10n, e.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The reset email's code: signs in, and the new-password page follows.
  Future<void> _verifyReset() async {
    final l10n = l10nOf(context);
    if (_resetCode.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountService.verifyResetCode(_resetEmail!, _resetCode.text);
    } on AccountException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.error == AccountError.invalidInvite
              ? l10n.authResetWrongCode
              : _message(l10n, e.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _resetForm() {
    final l10n = l10nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.authResetCodeTitle, style: LuText.title),
        const SizedBox(height: LuSpace.s),
        Text(l10n.authResetCodeBody(_resetEmail!), style: LuText.bodySoft),
        const SizedBox(height: LuSpace.l),
        LuTextField(
          label: l10n.authResetCode,
          controller: _resetCode,
          hint: l10n.authResetCodeHint,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          textInputAction: TextInputAction.done,
          autofocus: true,
          onSubmitted: (_) => _verifyReset(),
        ),
        if (_error != null) ...[
          const SizedBox(height: LuSpace.m),
          Text(
            _error!,
            style: LuText.body.copyWith(fontSize: 14, color: LuColors.danger),
          ),
        ],
        const SizedBox(height: LuSpace.l),
        LuButton(
          label: l10n.authResetVerify,
          expand: true,
          busy: _busy,
          onPressed: _verifyReset,
        ),
        const SizedBox(height: LuSpace.m),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            LuButton(
              label: l10n.authResetResend,
              kind: LuButtonKind.text,
              onPressed: _busy ? null : _forgot,
            ),
            LuButton(
              label: l10n.authResetBack,
              kind: LuButtonKind.text,
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _resetEmail = null;
                      _error = null;
                    }),
            ),
          ],
        ),
      ],
    );
  }

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
    return Theme(
      data: luTheme(),
      child: Scaffold(
        backgroundColor: LuColors.bg,
        body: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 900;
            return Stack(
              fit: StackFit.expand,
              children: [
                PosterWall(columns: wide ? 10 : 5, opacity: wide ? 0.34 : 0.3),
                _Light(wide: wide),
                if (wide) _wide(c) else _narrow(c),
                // Asked for on the way to playing something: the way back to
                // browsing.
                if (Navigator.of(context).canPop())
                  Positioned(
                    left: wide ? 32 : 12,
                    top: MediaQuery.paddingOf(context).top + (wide ? 24 : 12),
                    child: LuFocusable(
                      onTap: () => Navigator.of(context).maybePop(),
                      semanticLabel: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      builder: (context, hi) => AnimatedContainer(
                        duration: LuMotion.focus,
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hi
                              ? const Color(0x33FFFFFF)
                              : const Color(0x1FFFFFFF),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: LuColors.text,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _wide(BoxConstraints c) {
    final cardRight = math.min(120.0, c.maxWidth * 0.08);
    return Stack(
      children: [
        const Positioned(left: 96, top: 64, child: LuLogo(size: 40)),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          right: 440 + cardRight + 40,
          child: Column(
            children: [
              const SizedBox(height: 120),
              Expanded(child: _figureStage()),
              _figureControls(),
              const SizedBox(height: 36),
            ],
          ),
        ),
        Positioned(
          right: cardRight,
          top: 0,
          bottom: 0,
          width: 440,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _card(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrow(BoxConstraints c) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LuLogo(size: 28),
            ),
            SizedBox(
              height: math.min(320, c.maxHeight * 0.38),
              child: _figureStage(),
            ),
            _figureControls(),
            const SizedBox(height: 12),
            _form(),
          ],
        ),
      ),
    );
  }

  Widget _figureStage() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // The pool of light the figure stands in, under its base: the frames
        // keep a margin below the base, so the pool sits a little up.
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, 0.8),
            child: FractionallySizedBox(
              widthFactor: 0.6,
              heightFactor: 0.09,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      LuColors.gold.withValues(alpha: 0.34),
                      LuColors.gold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: LuMotion.page,
          child: FigureTurntable(key: ValueKey(_figure), figure: _figure),
        ),
      ],
    );
  }

  Widget _figureControls() {
    final l10n = l10nOf(context);
    // Wraps rather than overflows on a narrow phone or with large text.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(
          Icons.swap_horiz_rounded,
          size: 20,
          color: LuColors.textMuted,
        ),
        const SizedBox(width: 8),
        Text(l10n.authDragToTurn, style: LuText.caption.copyWith(fontSize: 14)),
        const SizedBox(width: 18),
        Container(width: 1, height: 14, color: const Color(0xFF3A3833)),
        const SizedBox(width: 8),
        for (final f in LuFigure.values)
          LuFocusable(
            onTap: () => setState(() => _figure = f),
            semanticLabel: l10n.authSwitchFigure(f.label),
            lift: 1,
            builder: (context, highlighted) => SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: AnimatedContainer(
                  duration: LuMotion.focus,
                  width: f == _figure ? 28 : 10,
                  height: 8,
                  decoration: BoxDecoration(
                    color: f == _figure
                        ? LuColors.gold
                        : (highlighted
                              ? const Color(0x99FFFFFF)
                              : const Color(0x59FFFFFF)),
                    borderRadius: LuRadius.pill,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 44, 40, 36),
      decoration: BoxDecoration(
        color: LuColors.glass,
        borderRadius: LuRadius.card,
        border: Border.all(color: LuColors.glassEdge),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 80,
            offset: Offset(0, 30),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: LuLanguageToggle(),
          ),
          const SizedBox(height: LuSpace.s),
          _form(),
        ],
      ),
    );
  }

  Widget _form() {
    if (_resetEmail != null) return _resetForm();
    final l10n = l10nOf(context);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _registering ? l10n.authCreateAccount : l10n.authWelcomeBack,
            style: LuText.title,
          ),
          const SizedBox(height: LuSpace.s),
          Text(
            _registering ? l10n.authSignUpSubtitle : l10n.authSignInSubtitle,
            style: LuText.bodySoft,
          ),
          const SizedBox(height: LuSpace.l),
          LuTextField(
            label: l10n.authEmail,
            controller: _email,
            hint: l10n.authEmailHint,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            autofocus: true,
          ),
          const SizedBox(height: LuSpace.m),
          LuTextField(
            label: l10n.authPassword,
            controller: _password,
            hint: l10n.authPasswordHint,
            obscure: !_showPassword,
            autofillHints: [
              _registering ? AutofillHints.newPassword : AutofillHints.password,
            ],
            textInputAction: _registering
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: _registering ? null : (_) => _submit(),
            trailing: IconButton(
              tooltip: _showPassword
                  ? l10n.authHidePassword
                  : l10n.authShowPassword,
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: LuColors.textFaint,
                size: 20,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          if (!_registering && widget.signIn == null)
            Align(
              alignment: Alignment.centerRight,
              child: LuButton(
                label: l10n.authForgot,
                kind: LuButtonKind.text,
                compact: true,
                onPressed: _busy ? null : _forgot,
              ),
            ),
          AnimatedSize(
            duration: LuMotion.page,
            curve: LuMotion.ease,
            child: _registering
                ? Padding(
                    padding: const EdgeInsets.only(top: LuSpace.m),
                    child: LuTextField(
                      label: l10n.authInviteCode,
                      controller: _invite,
                      hint: l10n.authInviteFieldHint,
                      helper: l10n.authInviteHint,
                      code: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          if (_error != null || _notice != null) ...[
            const SizedBox(height: LuSpace.m),
            Text(
              _error ?? _notice!,
              style: LuText.body.copyWith(
                fontSize: 14,
                color: _error != null ? LuColors.danger : LuColors.success,
              ),
            ),
          ],
          const SizedBox(height: LuSpace.l),
          LuButton(
            label: _registering ? l10n.authSubmitSignUp : l10n.authSubmitSignIn,
            expand: true,
            busy: _busy,
            onPressed: _submit,
          ),
          // One tap with an account the viewer already has. A first sign-in
          // this way asks for an invite code once (see [RedeemInvitePage]).
          if (!_registering && widget.signIn == null)
            ValueListenableBuilder<Set<String>>(
              valueListenable: AccountService.socialProviders,
              builder: (context, on, _) {
                final buttons = [
                  if (on.contains('github'))
                    (
                      l10n.authWithGithub,
                      Icons.code_rounded,
                      OAuthProvider.github,
                    ),
                  if (on.contains('discord'))
                    (
                      l10n.authWithDiscord,
                      Icons.discord,
                      OAuthProvider.discord,
                    ),
                  if (on.contains('google'))
                    (
                      l10n.authWithGoogle,
                      Icons.g_mobiledata_rounded,
                      OAuthProvider.google,
                    ),
                  if (on.contains('facebook'))
                    (
                      l10n.authWithFacebook,
                      Icons.facebook_rounded,
                      OAuthProvider.facebook,
                    ),
                ];
                if (buttons.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: LuSpace.m),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: LuColors.line)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.authOr,
                            style: LuText.caption.copyWith(
                              color: LuColors.textFaint,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: LuColors.line)),
                      ],
                    ),
                    for (final (label, icon, provider) in buttons) ...[
                      const SizedBox(height: LuSpace.s),
                      LuButton(
                        label: label,
                        icon: icon,
                        kind: LuButtonKind.secondary,
                        expand: true,
                        onPressed: _busy ? null : () => _social(provider),
                      ),
                    ],
                  ],
                );
              },
            ),
          const SizedBox(height: LuSpace.m),
          // Wraps rather than overflows where the line runs longer than the
          // card (English, large text).
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _registering ? l10n.authHaveAccount : l10n.authFirstTime,
                style: LuText.caption.copyWith(
                  fontSize: 14,
                  color: LuColors.textMuted,
                ),
              ),
              LuButton(
                label: _registering
                    ? l10n.authSignInInstead
                    : l10n.authUseInvite,
                kind: LuButtonKind.text,
                onPressed: _busy ? null : _toggleMode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The page's light: gold from the top left, darkening towards the card,
/// and a fade into the ground at the bottom.
class _Light extends StatelessWidget {
  const _Light({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: wide
                  ? const LinearGradient(
                      colors: [
                        Color(0x8C0A0A0C),
                        Color(0xB30A0A0C),
                        Color(0xF00A0A0C),
                        LuColors.bg,
                      ],
                      stops: [0, 0.5, 0.72, 1],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x590A0A0C),
                        Color(0xBF0A0A0C),
                        LuColors.bg,
                      ],
                      stops: [0, 0.4, 0.56],
                    ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.92, -1),
                radius: 1.1,
                colors: [
                  Color(0x4DFFD27A),
                  Color(0x14F2B544),
                  Color(0x000A0A0C),
                ],
                stops: [0, 0.45, 0.7],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 260,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [LuColors.bg, Color(0x000A0A0C)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows [child] to a signed-in viewer, and the sign-in page in its place to
/// anyone else, turning into [child] the moment they sign in. Wraps the screens
/// that play something, so browsing needs no account and watching does.
///
/// [child] is not built until then, so nothing it starts in `initState` (a
/// player, a source search) runs for a signed-out viewer.
class SignInRequired extends StatelessWidget {
  const SignInRequired({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AccountService.configured) return child;
    return ValueListenableBuilder(
      valueListenable: AccountService.session,
      builder: (context, session, _) => session == null
          ? const LoginPage()
          : ValueListenableBuilder<bool>(
              valueListenable: AccountService.recovering,
              // Signed in by a reset code here: the new password first.
              builder: (context, recovering, _) => recovering
                  ? const NewPasswordPage()
                  : ValueListenableBuilder<bool?>(
                      valueListenable: AccountService.invitedState,
                      // Still asking the server: no flash of the code page.
                      builder: (context, invited, _) => switch (invited) {
                        true => child,
                        false => const RedeemInvitePage(),
                        null => const ColoredBox(
                          color: LuColors.bg,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      },
                    ),
            ),
    );
  }
}

/// [LoginPage] pushed from 我的: pops back once the viewer is signed in.
class _LoginRoute extends StatefulWidget {
  const _LoginRoute();

  @override
  State<_LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<_LoginRoute> {
  @override
  void initState() {
    super.initState();
    AccountService.session.addListener(_onSession);
  }

  @override
  void dispose() {
    AccountService.session.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (AccountService.session.value != null && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) => const LoginPage();
}

/// A GitHub, Discord, Google or Facebook account's first visit: one invite
/// code, then in.
class RedeemInvitePage extends StatefulWidget {
  const RedeemInvitePage({super.key});

  @override
  State<RedeemInvitePage> createState() => _RedeemInvitePageState();
}

class _RedeemInvitePageState extends State<RedeemInvitePage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final l10n = l10nOf(context);
    if (_code.text.trim().isEmpty) {
      setState(() => _error = l10n.authErrInviteMissing);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await AccountService.redeemInvite(_code.text);
      if (!mounted) return;
      if (!ok) setState(() => _error = l10n.authErrInvalidInvite);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.authErrNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Theme(
      data: luTheme(),
      child: Scaffold(
        backgroundColor: LuColors.bg,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: LuColors.glass,
                  borderRadius: LuRadius.card,
                  border: Border.all(color: LuColors.glassEdge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: LuLogo(size: 32),
                    ),
                    const SizedBox(height: LuSpace.l),
                    Text(l10n.authRedeemTitle, style: LuText.title),
                    const SizedBox(height: LuSpace.s),
                    Text(l10n.authRedeemBody, style: LuText.bodySoft),
                    if (AccountService.email case final email?) ...[
                      const SizedBox(height: LuSpace.s),
                      Text(
                        email,
                        style: LuText.caption.copyWith(color: LuColors.gold),
                      ),
                    ],
                    const SizedBox(height: LuSpace.l),
                    LuTextField(
                      label: l10n.authInviteCode,
                      controller: _code,
                      code: true,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _redeem(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: LuSpace.m),
                      Text(
                        _error!,
                        style: LuText.body.copyWith(
                          fontSize: 14,
                          color: LuColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: LuSpace.l),
                    LuButton(
                      label: l10n.authRedeemAction,
                      expand: true,
                      busy: _busy,
                      onPressed: _redeem,
                    ),
                    const SizedBox(height: LuSpace.s),
                    LuButton(
                      label: l10n.authRedeemSwitch,
                      kind: LuButtonKind.text,
                      onPressed: _busy ? null : AccountService.signOut,
                    ),
                    if (Navigator.of(context).canPop())
                      LuButton(
                        label: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        kind: LuButtonKind.text,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back from a password-reset email: a new password, then on into the app.
class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = l10nOf(context);
    if (_password.text.length < 6) {
      setState(() => _error = l10n.authErrWeakPassword);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountService.setNewPassword(_password.text);
    } on AccountException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.error) {
            AccountError.samePassword => l10n.authErrSamePassword,
            AccountError.weakPassword => l10n.authErrWeakPassword,
            AccountError.network => l10n.authErrNetwork,
            _ => l10n.authErrUnknown,
          },
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Theme(
      data: luTheme(),
      child: Scaffold(
        backgroundColor: LuColors.bg,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: LuColors.glass,
                  borderRadius: LuRadius.card,
                  border: Border.all(color: LuColors.glassEdge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: LuLogo(size: 32),
                    ),
                    const SizedBox(height: LuSpace.l),
                    Text(l10n.authNewPasswordTitle, style: LuText.title),
                    const SizedBox(height: LuSpace.s),
                    Text(
                      l10n.authNewPasswordBody(AccountService.email ?? ''),
                      style: LuText.bodySoft,
                    ),
                    const SizedBox(height: LuSpace.l),
                    LuTextField(
                      label: l10n.authPassword,
                      controller: _password,
                      hint: l10n.authPasswordHint,
                      obscure: !_show,
                      autofocus: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                      trailing: IconButton(
                        icon: Icon(
                          _show
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: LuColors.textFaint,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _show = !_show),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: LuSpace.m),
                      Text(
                        _error!,
                        style: LuText.body.copyWith(
                          fontSize: 14,
                          color: LuColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: LuSpace.l),
                    LuButton(
                      label: l10n.authNewPasswordAction,
                      expand: true,
                      busy: _busy,
                      onPressed: _save,
                    ),
                    const SizedBox(height: LuSpace.s),
                    // Remembered it after all: already signed in, so in.
                    LuButton(
                      label: l10n.authNewPasswordKeep,
                      kind: LuButtonKind.text,
                      onPressed: _busy
                          ? null
                          : () => AccountService.recovering.value = false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
