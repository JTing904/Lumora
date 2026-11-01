import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
// Tests drive the platform interface directly; these are path_provider's own
// dependencies and the pubspec is owned elsewhere, so they cannot be declared.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/utils/download/download_path_helper.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getDownloadsPath() async => p.join(root, 'Downloads');

  @override
  Future<String?> getApplicationDocumentsPath() async =>
      p.join(root, 'Documents');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records prior custom download roots without duplicates', () async {
    final first = p.join(Directory.systemTemp.path, 'zplay-downloads-one');
    final second = p.join(Directory.systemTemp.path, 'zplay-downloads-two');

    await DownloadPathHelper.setCustomDownloadsDirectoryPath(first);
    await DownloadPathHelper.setCustomDownloadsDirectoryPath(second);
    await DownloadPathHelper.setCustomDownloadsDirectoryPath(first);

    final prefs = await SharedPreferences.getInstance();
    final history =
        prefs.getStringList('custom_downloads_directory_history') ?? const [];

    expect(history.first, p.normalize(p.absolute(first)));
    expect(history, contains(p.normalize(p.absolute(second))));
    expect(history.toSet().length, history.length);
    expect(history.length, lessThanOrEqualTo(10));
  });

  group('the folder downloads go to', () {
    late Directory root;
    late Directory downloads;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('download_folder_test');
      downloads = await Directory(
        p.join(root.path, 'Downloads'),
      ).create(recursive: true);
      PathProviderPlatform.instance = _FakePathProvider(root.path);
    });

    tearDown(() async {
      await root.delete(recursive: true);
    });

    test('is a Lumora folder, made only when it is asked for', () async {
      final path = await DownloadPathHelper.getDownloadsDirectoryPath();

      expect(path, p.join(downloads.path, 'Lumora'));
      expect(await Directory(path).exists(), isTrue);
    });

    test(
      'the checks made at start-up and on the page create nothing',
      () async {
        await DownloadPathHelper.getTrustedDownloadDirectories();
        await DownloadPathHelper.getExistingDownloadsVolumePath();

        expect(await downloads.list().isEmpty, isTrue);
      },
    );

    test('downloads saved in the old folder stay trusted', () async {
      final roots = await DownloadPathHelper.getTrustedDownloadDirectories();

      expect(roots, contains(p.join(downloads.path, 'ZPlay')));
      expect(roots, contains(p.join(downloads.path, 'Lumora')));
    });

    test('an empty old folder goes, one with a download stays', () async {
      final empty = await Directory(
        p.join(downloads.path, 'ZPlay'),
      ).create(recursive: true);

      await DownloadPathHelper.removeEmptyLegacyFolders();
      expect(await empty.exists(), isFalse);

      await empty.create(recursive: true);
      final film = File(p.join(empty.path, 'film.mp4'));
      await film.writeAsString('video');

      await DownloadPathHelper.removeEmptyLegacyFolders();
      expect(await film.exists(), isTrue);
    });
  });
}
