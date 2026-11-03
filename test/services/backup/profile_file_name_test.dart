import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/services/backup/backup_restore_service.dart';
import 'package:zplay/services/settings/locale_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleSettings.locale.value = null);

  test('a profile is looked for as lumora_profile.json, then by its old '
      'name', () async {
    final dir = Directory.systemTemp.createTempSync('lumora_ext_storage');
    addTearDown(() => dir.deleteSync(recursive: true));
    final paths = await BackupRestoreService.importSearchPaths(
      externalStorage: () async => dir,
    );
    expect(BackupRestoreService.importFileName, 'lumora_profile.json');
    expect(paths[0], endsWith('lumora_profile.json'));
    expect(paths[1], endsWith('zplay_profile.json'));
    expect(paths.indexWhere((p) => p.endsWith('zplay_profile.json')), 1);
  });

  test('a file pushed under the old name still imports', () async {
    final dir = Directory.systemTemp.createTempSync('lumora_ext_storage');
    addTearDown(() => dir.deleteSync(recursive: true));
    File(
      '${dir.path}${Platform.pathSeparator}zplay_profile.json',
    ).writeAsStringSync(
      jsonEncode({
        'schemaVersion': 2,
        'secretsExcluded': true,
        'settings': {'theme_mode': 'light'},
      }),
    );

    final msg = await BackupRestoreService.importSettingsFromFile(
      await BackupRestoreService.importSearchPaths(
        externalStorage: () async => dir,
      ),
    );

    expect(msg, contains('restored'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });

  test('the messages follow the app language and never name ZPlay', () async {
    LocaleSettings.locale.value = const Locale('zh');
    final msg = await BackupRestoreService.importSettingsJson(
      jsonEncode({'schemaVersion': 2, 'secretsExcluded': true, 'settings': {}}),
    );
    expect(msg, contains('已还原'));

    await expectLater(
      BackupRestoreService.importSettingsFromFile([
        '/sdcard/Download/lumora_profile.json',
        '/sdcard/Download/zplay_profile.json',
      ], read: (_) async => throw const FileSystemException('missing')),
      throwsA(
        isA<FileSystemException>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('lumora_profile.json'),
            contains('应用目录'),
            isNot(contains('zplay')),
          ),
        ),
      ),
    );
  });
}
