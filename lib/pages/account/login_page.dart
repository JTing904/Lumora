import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../services/account/account_service.dart';
import '../../ui/figure_turntable.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_focusable.dart';
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
          : ValueListenableBuilder(
              key: const ValueKey('gate'),
              valueListenable: AccountService.session,
              builder: (context, session, _) => session != null && !_forceLogin
                  ? widget.child
                  : const LoginPage(),
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

  void _toggleMode() => setState(() {
    _registering = !_registering;
    _error = null;
    _notice = null;
  });

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
      child: _form(),
    );
  }

  Widget _form() {
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
