import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zplay/utils/platform/app_folders.dart';

void main() {
  late Directory base;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('app_folders_test');
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  Future<void> makeEmptyMusicFolders() async {
    await Directory(
      p.join(base.path, 'ZPlay', 'Music', 'Tracks'),
    ).create(recursive: true);
    await Directory(
      p.join(base.path, 'ZPlay', 'Music', 'Covers'),
    ).create(recursive: true);
  }

  group('under', () {
    test(
      'a new install gets a Lumora folder, and nothing is created',
      () async {
        final dir = await AppFolders.under(base.path, 'Music');

        expect(dir.path, p.join(base.path, 'Lumora', 'Music'));
        expect(await base.list().isEmpty, isTrue);
      },
    );

    test('old empty folders do not keep the old name in use', () async {
      await makeEmptyMusicFolders();

      final dir = await AppFolders.under(base.path, 'Music');

      expect(dir.path, p.join(base.path, 'Lumora', 'Music'));
    });

    test('an old folder with files keeps being used', () async {
      await makeEmptyMusicFolders();
      final track = File(
        p.join(base.path, 'ZPlay', 'Music', 'Tracks', 'a.m4a'),
      );
      await track.writeAsString('audio');

      final dir = await AppFolders.under(base.path, 'Music');

      expect(dir.path, p.join(base.path, 'ZPlay', 'Music'));
    });
  });

  group('removeEmptyLegacy', () {
    test('removes a tree of empty folders', () async {
      await makeEmptyMusicFolders();

      await AppFolders.removeEmptyLegacy(base.path);

      expect(await Directory(p.join(base.path, 'ZPlay')).exists(), isFalse);
    });

    test('keeps every folder and file when one file is left', () async {
      await makeEmptyMusicFolders();
      final track = File(
        p.join(base.path, 'ZPlay', 'Music', 'Tracks', 'a.m4a'),
      );
      await track.writeAsString('audio');

      await AppFolders.removeEmptyLegacy(base.path);

      expect(await track.readAsString(), 'audio');
      expect(
        await Directory(p.join(base.path, 'ZPlay', 'Music', 'Covers')).exists(),
        isTrue,
      );
    });

    test('does nothing when there is no old folder', () async {
      await AppFolders.removeEmptyLegacy(base.path);

      expect(await base.list().isEmpty, isTrue);
    });
  });
}
