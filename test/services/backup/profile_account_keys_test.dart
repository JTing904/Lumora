import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zplay/models/my_list/my_list_item.dart';
import 'package:zplay/services/account/account_service.dart';
import 'package:zplay/services/backup/backup_restore_service.dart';
import 'package:zplay/services/backup/profile_cipher.dart';
import 'package:zplay/services/diagnostics/diagnostics_export.dart';
import 'package:zplay/services/my_list/my_list_service.dart';

const String _me = '11111111-1111-4111-8111-111111111111';
const String _other = '22222222-2222-4222-8222-222222222222';
const String _sessionKey = 'sb-wfrmsxoshloeaxykwzbg-auth-token';
const String _sessionValue = '{"access_token":"session-secret"}';

Session _session(String id) => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  ),
);

/// A My List document as the store writes it, holding one title.
String _myList(String title) => jsonEncode([
  MyListItem(
    traktId: 1,
    title: title,
    year: 2024,
    type: 'movie',
    addedAt: DateTime.utc(2026),
  ).toJson(),
]);

/// A shared device: the signed-in account, another account, the session,
/// a GitHub sign-up's code and the sync's removal records.
Map<String, Object> _sharedDevice() => {
  _sessionKey: _sessionValue,
  'supabase.auth.token-code-verifier': 'pkce-secret',
  'lumora_pending_invite_v1': '{"code":"INVITE99"}',
  'my_list_v1@$_me': _myList('Mine'),
  'my_list_v1@$_other': _myList('Theirs'),
  'my_list_v1': _myList('Signed out'),
  'lumora_removed_my_list@$_me': '{"tt1":"2026-01-01T00:00:00Z"}',
  'lumora_sync_clock_offset_ms': 42,
  'theme_mode': 'dark',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MyListService.items.value = [];
  });

  tearDown(() => AccountService.session.value = null);

  group('export', () {
    test('names each key the way only its own account may see it', () {
      expect(BackupRestoreService.exportNameFor(_sessionKey, _me), isNull);
      expect(
        BackupRestoreService.exportNameFor('sb-otherref-auth-token', null),
        isNull,
      );
      expect(
        BackupRestoreService.exportNameFor('lumora_pending_invite_v1', _me),
        isNull,
      );
      expect(
        BackupRestoreService.exportNameFor('my_list_v1@$_other', _me),
        isNull,
      );
      expect(
        BackupRestoreService.exportNameFor('my_list_v1@$_me', _me),
        'my_list_v1',
      );
      // Signed in, a signed-out leftover is nobody's library to share.
      expect(BackupRestoreService.exportNameFor('my_list_v1', _me), isNull);
      expect(
        BackupRestoreService.exportNameFor('my_list_v1', null),
        'my_list_v1',
      );
      expect(
        BackupRestoreService.exportNameFor('my_list_v1@$_me', null),
        isNull,
      );
      expect(
        BackupRestoreService.exportNameFor('theme_mode', _me),
        'theme_mode',
      );
    });

    for (final passphrase in [null, 'a long passphrase']) {
      test('${passphrase == null ? 'a redacted' : 'an encrypted'} profile '
          'carries no session and no other account', () async {
        SharedPreferences.setMockInitialValues(_sharedDevice());
        AccountService.session.value = _session(_me);

        var exported = await BackupRestoreService.exportSettingsJson(
          passphrase: passphrase,
        );
        if (passphrase != null) {
          // Decrypted the way an import would, to look inside.
          exported = ProfileCipher.decrypt(exported, passphrase);
        }
        expect(exported, isNot(contains('session-secret')));
        expect(exported, isNot(contains('pkce-secret')));
        expect(exported, isNot(contains('INVITE99')));
        expect(exported, isNot(contains(_other)));
        expect(exported, isNot(contains('Theirs')));
        expect(exported, isNot(contains('Signed out')));
        expect(exported, isNot(contains('lumora_removed_')));
        expect(exported, isNot(contains(_me)));
        final settings =
            (jsonDecode(exported) as Map)['settings'] as Map<String, dynamic>;
        expect(settings['my_list_v1'], contains('Mine'));
        expect(settings['theme_mode'], 'dark');
      });
    }

    test(
      'a diagnostics report leaves out the session and other accounts',
      () async {
        SharedPreferences.setMockInitialValues(_sharedDevice());
        final report = await DiagnosticsExport(
          packageInfo: () async => PackageInfo(
            appName: 'Lumora',
            packageName: 'io.github.jting904.lumora',
            version: '1.0.0',
            buildNumber: '1',
          ),
          preferences: () async => SharedPreferences.getInstance(),
          reportDirectory: () async => null,
          breadcrumbs: () => const [],
          torrentEngineState: () => null,
          accountId: () => _me,
        ).buildReportString();

        expect(report, isNot(contains('session-secret')));
        expect(report, isNot(contains('pkce-secret')));
        expect(report, isNot(contains('INVITE99')));
        expect(report, isNot(contains(_other)));
        expect(report, isNot(contains('Theirs')));
        expect(report, contains('theme_mode'));
      },
    );

    test('isExcludedKey keeps out every account but the reader', () {
      expect(DiagnosticsExport.isExcludedKey(_sessionKey), isTrue);
      expect(
        DiagnosticsExport.isExcludedKey('lumora_pending_invite_v1'),
        isTrue,
      );
      expect(
        DiagnosticsExport.isExcludedKey('my_list_v1@$_other', accountId: _me),
        isTrue,
      );
      expect(
        DiagnosticsExport.isExcludedKey('my_list_v1@$_me', accountId: _me),
        isFalse,
      );
      expect(DiagnosticsExport.isExcludedKey('my_list_v1@$_me'), isTrue);
    });
  });

  group('import', () {
    test('finds the account an older file was written by', () {
      expect(
        BackupRestoreService.sourceAccountOf(['a', 'my_list_v1@$_other'], _me),
        _other,
      );
      expect(
        BackupRestoreService.sourceAccountOf([
          'my_list_v1@$_other',
          'my_list_v1@$_me',
        ], _me),
        _me,
      );
      // Two strangers: nobody's library is guessed at.
      expect(
        BackupRestoreService.sourceAccountOf([
          'my_list_v1@$_other',
          'my_list_v1@33333333-3333-4333-8333-333333333333',
        ], _me),
        isNull,
      );
    });

    test('puts the library in the account that imports it', () {
      String? at(String key, {String? uid = _me}) =>
          BackupRestoreService.importKeyFor(key, uid: uid, source: _other);
      expect(at('my_list_v1@$_other'), 'my_list_v1@$_me');
      expect(at('my_list_v1'), 'my_list_v1@$_me');
      expect(at('my_list_v1', uid: null), 'my_list_v1');
      expect(at('my_list_v1@$_other', uid: null), 'my_list_v1');
      expect(at('my_list_v1@33333333-3333-4333-8333-333333333333'), isNull);
      expect(at(_sessionKey), isNull);
      expect(at('lumora_pending_invite_v1'), isNull);
      expect(at('lumora_removed_my_list@$_other'), isNull);
      expect(at('theme_mode'), 'theme_mode');
    });

    test(
      "an older file's library lands in the importing account and shows",
      () async {
        AccountService.session.value = _session(_me);
        final file = jsonEncode({
          'schemaVersion': 2,
          'secretsExcluded': true,
          'settings': {
            _sessionKey: _sessionValue,
            'lumora_pending_invite_v1': '{"code":"INVITE99"}',
            'my_list_v1@$_other': _myList('Restored'),
            'lumora_removed_my_list@$_other': '{"tt1":"2026-01-01T00:00:00Z"}',
            'theme_mode': 'light',
          },
        });

        await BackupRestoreService.importSettingsJson(file);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey(_sessionKey), isFalse);
        expect(prefs.containsKey('lumora_pending_invite_v1'), isFalse);
        expect(prefs.containsKey('my_list_v1@$_other'), isFalse);
        expect(
          prefs.getKeys().where((k) => k.startsWith('lumora_removed_')),
          isEmpty,
        );
        expect(prefs.getString('my_list_v1@$_me'), contains('Restored'));
        expect(prefs.getString('theme_mode'), 'light');
        expect(MyListService.items.value.single.title, 'Restored');
      },
    );

    test('a profile exported by one account restores into another', () async {
      SharedPreferences.setMockInitialValues({
        'my_list_v1@$_other': _myList('Shared'),
      });
      AccountService.session.value = _session(_other);
      final profile = await BackupRestoreService.exportSettingsJson();

      SharedPreferences.setMockInitialValues({});
      AccountService.session.value = _session(_me);
      await BackupRestoreService.importSettingsJson(profile);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('my_list_v1@$_me'), contains('Shared'));
      expect(MyListService.items.value.single.title, 'Shared');
    });
  });
}
