import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// The folders Lumora keeps where the user can see them: under Documents and
/// Downloads.
///
/// These used to be called `ZPlay`. What was saved there is recorded by
/// absolute path (tracks, audiobooks, download tasks), so a folder that holds
/// files stays put and keeps being used, and one that holds none is removed
/// by [removeEmptyLegacy].
abstract final class AppFolders {
  static const String name = 'Lumora';
  static const String legacyName = 'ZPlay';

  /// `<base>/Lumora/<part>`, or `<base>/ZPlay/<part>` while that holds files.
  /// Creates nothing: a folder should appear when there is something to put
  /// in it.
  static Future<Directory> under(String base, String part) async {
    final legacy = Directory(p.join(base, legacyName, part));
    if (await _holdsFiles(legacy)) return legacy;
    return Directory(p.join(base, name, part));
  }

  /// Removes `<base>/ZPlay` if nothing but empty folders is left in it.
  ///
  /// Folders go one at a time, deepest first, without `recursive`, so that a
  /// file can never be deleted here, whatever appears in the meantime.
  static Future<void> removeEmptyLegacy(String base) async {
    final root = Directory(p.join(base, legacyName));
    try {
      if (!await root.exists() || await _holdsFiles(root)) return;
      final folders = await root
          .list(recursive: true, followLinks: false)
          .where((entity) => entity is Directory)
          .toList();
      folders.sort((a, b) => b.path.length.compareTo(a.path.length));
      for (final folder in folders) {
        await folder.delete();
      }
      await root.delete();
    } catch (e) {
      debugPrint('[AppFolders] could not remove $root: $e');
    }
  }

  /// Anything that is not a folder counts as a file, a link included, and a
  /// folder that cannot be read is assumed to hold some.
  static Future<bool> _holdsFiles(Directory dir) async {
    try {
      if (!await dir.exists()) return false;
      return await dir
          .list(recursive: true, followLinks: false)
          .any((entity) => entity is! Directory);
    } catch (_) {
      return true;
    }
  }
}
