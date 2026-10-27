import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/pages/account/invite_codes_page.dart';
import 'package:zplay/pages/account/login_page.dart';
import 'package:zplay/services/account/account_service.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, LoginPage page) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pump();
  }

  test('codes are read in any case, with or without the dash', () {
    expect(normalizeInviteCode(' lumo-7k3p '), 'LUMO7K3P');
    expect(formatInviteCode('LUMO7K3P'), 'LUMO-7K3P');
  });

  testWidgets('without a Supabase project the gate shows the app', (
    tester,
  ) async {
    AccountService.debugReset();
    await tester.pumpWidget(
      const MaterialApp(home: AccountGate(child: Text('the app'))),
    );
    expect(find.text('the app'), findsOneWidget);
  });

  testWidgets('signing in sends the email and password', (tester) async {
    String? sent;
    await pumpLogin(
      tester,
      LoginPage(signIn: (email, password) async => sent = '$email/$password'),
    );
    await tester.enterText(find.byType(TextField).at(0), ' me@lumora.app ');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.byIcon(Icons.login_rounded));
    await tester.pump();
    expect(sent, 'me@lumora.app/secret123');
  });

  testWidgets('creating an account asks for the invite code', (tester) async {
    var calls = 0;
    await pumpLogin(
      tester,
      LoginPage(
        signUp: (email, password, code) async {
          calls++;
          throw const AccountException(AccountError.invalidInvite);
        },
      ),
    );
    await tester.tap(find.text('Create account').first);
    await tester.pump();
    expect(find.text('Invite code'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'new@lumora.app');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.byIcon(Icons.person_add_alt_1_rounded));
    await tester.pump();
    expect(find.text('Enter your invite code.'), findsOneWidget);
    expect(calls, 0, reason: 'no request without a code');

    await tester.enterText(find.byType(TextField).at(2), 'nope-2345');
    await tester.tap(find.byIcon(Icons.person_add_alt_1_rounded));
    await tester.pump();
    await tester.pump();
    expect(calls, 1);
    expect(
      find.text('This invite code is not valid, or has been used.'),
      findsOneWidget,
    );
  });

  testWidgets('a project that wants the email confirmed says so', (
    tester,
  ) async {
    await pumpLogin(
      tester,
      LoginPage(signUp: (_, __, ___) async => SignUpResult.confirmEmail),
    );
    await tester.tap(find.text('Create account').first);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), 'new@lumora.app');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.enterText(find.byType(TextField).at(2), 'LUMO7K3P');
    await tester.tap(find.byIcon(Icons.person_add_alt_1_rounded));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Account created. Open the link in your email, then sign in.'),
      findsOneWidget,
    );
  });

  testWidgets('the admin page lists codes and makes new ones', (tester) async {
    final made = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: InviteCodesPage(
          list: () async => [
            InviteCode(code: 'LUMO7K3P', createdAt: DateTime(2026, 10, 27)),
            InviteCode(
              code: 'ABCD2345',
              note: 'for A',
              createdAt: DateTime(2026, 10, 26),
              usedAt: DateTime(2026, 10, 27),
              usedByEmail: 'a@lumora.app',
            ),
          ],
          create: (n, {note}) async {
            made.add(n);
            return ['NEWC0DE2'];
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('LUMO-7K3P'), findsOneWidget);
    expect(find.text('ABCD-2345'), findsOneWidget);
    expect(find.text('for A · Used by a@lumora.app'), findsOneWidget);
    expect(find.text('2 codes · 1 unused'), findsOneWidget);

    await tester.tap(find.text('Make 5'));
    await tester.pump();
    expect(made, [5]);
  });
}
