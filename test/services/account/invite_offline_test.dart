import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zplay/services/account/account_service.dart';

const String _uid = '11111111-1111-4111-8111-111111111111';

Session _session({String provider = 'github'}) => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: User(
    id: _uid,
    appMetadata: {'provider': provider},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Every server function called, in order.
  late List<String> calls;

  /// What `is_invited` answers; null: the network is down.
  bool? server;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      // A GitHub sign-up's code still waiting: a check that failed must not
      // spend it, or remove the account, as if the server had said no.
      AccountService.pendingInviteKey: jsonEncode({
        'code': 'LUMO7K3P',
        'at': DateTime.now().toIso8601String(),
      }),
    });
    AccountService.debugReset();
    calls = [];
    server = null;
    AccountService.rpcOverride = (fn, params) async {
      calls.add(fn);
      if (fn == 'is_invited') {
        if (server == null) throw Exception('offline');
        return server;
      }
      return false;
    };
  });

  tearDown(AccountService.debugReset);

  Future<bool> pendingKept() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(AccountService.pendingInviteKey);
  }

  test('offline, an account last known invited is let in', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${AccountService.invitedCacheKey}@$_uid', true);
    AccountService.session.value = _session();

    await AccountService.refreshAccountForTesting();

    expect(AccountService.invitedState.value, isTrue);
    expect(calls, isNot(contains('redeem_invite')));
    expect(calls, isNot(contains('discard_uninvited_self')));
    expect(await pendingKept(), isTrue);
  });

  test(
    'offline, an email account is let in even if never asked here',
    () async {
      AccountService.session.value = _session(provider: 'email');

      await AccountService.refreshAccountForTesting();

      expect(AccountService.invitedState.value, isTrue);
    },
  );

  test('offline and never asked, a GitHub account is asked for a code, '
      'and nothing is settled', () async {
    AccountService.session.value = _session();

    await AccountService.refreshAccountForTesting();

    expect(AccountService.invitedState.value, isFalse);
    expect(calls, ['is_invited', 'is_admin']);
    expect(await pendingKept(), isTrue);
  });

  test(
    'the server\'s answer is remembered for the next offline launch',
    () async {
      server = true;
      AccountService.session.value = _session();
      await AccountService.refreshAccountForTesting();
      expect(AccountService.invitedState.value, isTrue);
      expect(await AccountService.lastKnownInvited(_uid), isTrue);

      // The next launch, offline.
      AccountService.debugReset();
      AccountService.rpcOverride = (fn, params) async {
        if (fn == 'is_invited') throw Exception('offline');
        return false;
      };
      AccountService.session.value = _session();
      await AccountService.refreshAccountForTesting();
      expect(AccountService.invitedState.value, isTrue);
    },
  );

  test('the network back, the server\'s no replaces the memory', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${AccountService.invitedCacheKey}@$_uid', true);
    AccountService.session.value = _session();
    await AccountService.refreshAccountForTesting();
    expect(AccountService.invitedState.value, isTrue);

    server = false;
    AccountService.recheckIfOffline();
    await pumpEventQueue();

    expect(AccountService.invitedState.value, isFalse);
    expect(await AccountService.lastKnownInvited(_uid), isFalse);
  });

  test('a recheck happens only after an offline answer', () async {
    server = true;
    AccountService.session.value = _session();
    await AccountService.refreshAccountForTesting();
    calls.clear();

    AccountService.recheckIfOffline();
    await pumpEventQueue();

    expect(calls, isEmpty);
  });
}
