import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform/app_folders.dart';

class DownloadPathHelper {
  static const String _customPathKey = 'custom_downloads_directory';
  static const String _customPathHistoryKey =
      'custom_downloads_directory_history';
  static const int _maxRememberedDirectories = 10;

  /// Launches the native system folder picker so user can pick where to save downloads.
  static Future<String?> pickDownloadsDirectory() async {
    try {
      final selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Downloads Folder',
      );
      if (selected != null && selected.isNotEmpty) {
        await setCustomDownloadsDirectoryPath(selected);
        return selected;
      }
    } catch (e) {
      debugPrint('[DownloadPathHelper] Folder picker error: $e');
    }
    return null;
  }

  /// Returns the configured downloads directory path.
  static Future<String> getDownloadsDirectoryPath() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_customPathKey);
    if (custom != null && custom.isNotEmpty) {
      final customDir = Directory(custom);
      if (await customDir.exists() || await _tryCreate(customDir)) {
        return custom;
      }
    }

    final defaultPath = await getDefaultDownloadsDirectoryPath();
    final defaultDir = Directory(defaultPath);
    if (!await defaultDir.exists()) {
      await defaultDir.create(recursive: true);
    }
    return defaultPath;
  }

  /// Sets a custom user downloads directory.
  static Future<void> setCustomDownloadsDirectoryPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customPathKey, path);

    // Keep a bounded history of user-picked folders so downloads started in a
    // previously selected folder can still be validated and resumed after the
    // user picks a different one.
    final normalized = p.normalize(p.absolute(path));
    final history = prefs.getStringList(_customPathHistoryKey) ?? const [];
    final updated = <String>[normalized];
    for (final previous in history) {
      final previousNormalized = p.normalize(p.absolute(previous));
      if (previousNormalized != normalized &&
          !updated.contains(previousNormalized)) {
        updated.add(previousNormalized);
      }
      if (updated.length >= _maxRememberedDirectories) break;
    }
    await prefs.setStringList(_customPathHistoryKey, updated);
  }

  /// Download roots the app itself recorded, used to validate persisted task
  /// paths without trusting the task file's own directory string. Runs at
  /// every start, so it only names folders and creates none; the old `ZPlay`
  /// roots stay here because downloads saved there are recorded by full path.
  static Future<List<String>> getTrustedDownloadDirectories() async {
    final prefs = await SharedPreferences.getInstance();
    final roots = <String>{
      for (final base in await _downloadBases()) ...[
        p.join(base, AppFolders.name),
        p.join(base, AppFolders.legacyName),
      ],
    };
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      roots.add(p.join(appDocDir.path, 'Downloads'));
    } catch (_) {}

    final current = prefs.getString(_customPathKey);
    if (current != null && current.isNotEmpty) roots.add(current);

    final history = prefs.getStringList(_customPathHistoryKey) ?? const [];
    roots.addAll(history.where((path) => path.isNotEmpty));

    return roots.toList();
  }

  /// An existing folder on the volume downloads go to, for measuring free
  /// space. Opening the Downloads page creates nothing.
  static Future<String> getExistingDownloadsVolumePath() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_customPathKey);
    if (custom != null &&
        custom.isNotEmpty &&
        await Directory(custom).exists()) {
      return custom;
    }
    for (final base in await _downloadBases()) {
      if (await Directory(base).exists()) return base;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }

  /// Removes the old `ZPlay` folders that hold no files.
  static Future<void> removeEmptyLegacyFolders() async {
    final bases = await _downloadBases();
    try {
      bases.add((await getApplicationDocumentsDirectory()).path);
    } catch (_) {}
    for (final base in bases) {
      await AppFolders.removeEmptyLegacy(base);
    }
  }

  /// The folders the app's own download folder goes in, best first.
  static Future<List<String>> _downloadBases() async {
    final bases = <String>[];
    if (kIsWeb) return bases;
    try {
      if (Platform.isAndroid) {
        bases.add('/storage/emulated/0/Download');
        final extDirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (extDirs != null && extDirs.isNotEmpty) {
          bases.add(extDirs.first.path);
        }
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) bases.add(downloadsDir.path);
      }
    } catch (_) {}
    return bases;
  }

  /// Returns the platform default download directory.
  static Future<String> getDefaultDownloadsDirectoryPath() async {
    for (final base in await _downloadBases()) {
      final target = Directory(p.join(base, AppFolders.name));
      if (await target.exists() || await _tryCreate(target)) {
        return target.path;
      }
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final fallback = Directory(p.join(appDocDir.path, 'Downloads'));
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    return fallback.path;
  }

  static Future<bool> _tryCreate(Directory dir) async {
    try {
      await dir.create(recursive: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sanitizes a filename removing forbidden filesystem characters.
  static String sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
