import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zplay/services/storage/windows_prefs_guard.dart';

void main() {
  late Directory sandbox;
  late String prefsPath;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('lumora_prefs_guard');
    prefsPath = p.join(sandbox.path, 'shared_preferences.json');
  });

  tearDown(() {
    if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
  });

  List<String> corruptCopies() => sandbox
      .listSync()
      .map((e) => p.basename(e.path))
      .where((name) => name.contains(corruptSuffix))
      .toList();

  group('isLoadablePreferences', () {
    test('accepts an empty file and a JSON object', () {
      expect(isLoadablePreferences(const <int>[]), isTrue);
      expect(isLoadablePreferences('{}'.codeUnits), isTrue);
      expect(isLoadablePreferences('{"flutter.a":1}'.codeUnits), isTrue);
    });

    test('rejects truncated JSON, zero bytes, non-objects and bad UTF-8', () {
      expect(isLoadablePreferences('{"flutter.a":'.codeUnits), isFalse);
      expect(isLoadablePreferences(List<int>.filled(64, 0)), isFalse);
      expect(isLoadablePreferences('[1,2]'.codeUnits), isFalse);
      expect(isLoadablePreferences(const <int>[0x7b, 0xff, 0xfe]), isFalse);
    });
  });

  group('repairPreferencesFile', () {
    test('reports a fresh install and touches nothing', () {
      expect(repairPreferencesFile(prefsPath), PreferencesFileCheck.missing);
      expect(sandbox.listSync(), isEmpty);
    });

    test('keeps a valid file and saves it as the last-good copy', () {
      File(prefsPath).writeAsStringSync('{"flutter.theme":"dark"}');

      expect(repairPreferencesFile(prefsPath), PreferencesFileCheck.valid);
      expect(File(prefsPath).readAsStringSync(), '{"flutter.theme":"dark"}');
      expect(
        File('$prefsPath$lastGoodSuffix').readAsStringSync(),
        '{"flutter.theme":"dark"}',
      );
    });

    test('replaces an older last-good copy', () {
      File(prefsPath).writeAsStringSync('{"flutter.a":1}');
      repairPreferencesFile(prefsPath);
      File(prefsPath).writeAsStringSync('{"flutter.a":2}');

      expect(repairPreferencesFile(prefsPath), PreferencesFileCheck.valid);
      expect(
        File('$prefsPath$lastGoodSuffix').readAsStringSync(),
        '{"flutter.a":2}',
      );
    });

    test('does not let an empty file replace a useful last-good copy', () {
      File('$prefsPath$lastGoodSuffix').writeAsStringSync('{"flutter.a":1}');
      File(prefsPath).writeAsStringSync('');

      expect(repairPreferencesFile(prefsPath), PreferencesFileCheck.valid);
      expect(
        File('$prefsPath$lastGoodSuffix').readAsStringSync(),
        '{"flutter.a":1}',
      );
    });

    test('moves a damaged file aside and restores the last-good copy', () {
      File(prefsPath).writeAsStringSync('{"flutter.theme":"dark"}');
      repairPreferencesFile(prefsPath);
      File(prefsPath).writeAsStringSync('{"flutter.theme":"da');

      final result = repairPreferencesFile(
        prefsPath,
        now: DateTime.fromMillisecondsSinceEpoch(1234),
      );

      expect(result, PreferencesFileCheck.restoredFromLastGood);
      expect(File(prefsPath).readAsStringSync(), '{"flutter.theme":"dark"}');
      expect(
        File('$prefsPath${corruptSuffix}1234').readAsStringSync(),
        '{"flutter.theme":"da',
      );
    });

    test('moves a damaged file aside and starts from defaults', () {
      File(prefsPath).writeAsBytesSync(List<int>.filled(128, 0));

      expect(
        repairPreferencesFile(prefsPath),
        PreferencesFileCheck.resetToDefaults,
      );
      expect(File(prefsPath).existsSync(), isFalse);
      expect(corruptCopies(), hasLength(1));
    });

    test('ignores a damaged last-good copy', () {
      File('$prefsPath$lastGoodSuffix').writeAsStringSync('{"broken');
      File(prefsPath).writeAsStringSync('not json');

      expect(
        repairPreferencesFile(prefsPath),
        PreferencesFileCheck.resetToDefaults,
      );
      expect(File(prefsPath).existsSync(), isFalse);
    });
  });
}
