import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// The file the download list is kept in.
///
/// The list is saved on every progress tick, about once a second per running
/// download. Those saves used to run unserialised, so two could write the
/// same file at once, and one torn or truncated file made the next launch
/// start with no downloads at all. Here only one write runs at a time, saves
/// that arrive meanwhile collapse into one more write of the latest list,
/// each write goes to a temporary file that is then renamed over the real
/// one, and the list it replaces is kept as a backup to fall back to.
class DownloadTaskStore {
  DownloadTaskStore({
    required Future<Directory> Function() directory,
    Future<Directory?> Function()? legacyDirectory,
  }) : _directory = directory,
       _legacyDirectory = legacyDirectory;

  static const String fileName = 'lumora_download_tasks.json';

  /// The name and folder (Documents) the list had before it moved to the
  /// app's support folder, where users do not stumble on it.
  static const String legacyFileName = 'zplay_download_tasks.json';

  final Future<Directory> Function() _directory;
  final Future<Directory?> Function()? _legacyDirectory;

  Future<void>? _writing;
  bool _dirty = false;
  String Function()? _latest;

  Future<File> _file() async {
    final dir = await _directory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return File(p.join(dir.path, fileName));
  }

  /// Reads the saved list: the live file, then a write that was cut off
  /// before its rename, then the backup, then the old Documents file. Returns
  /// null when there is none that decodes.
  Future<List<Map<String, dynamic>>?> load() async {
    final file = await _file();
    final candidates = [
      file,
      File('${file.path}.tmp'),
      File('${file.path}.bak'),
    ];
    for (final candidate in candidates) {
      final tasks = await _read(candidate);
      if (tasks != null) {
        if (candidate != file) {
          debugPrint('[DownloadTaskStore] recovered list from $candidate');
          // Set the unreadable live file aside so the next write does not
          // turn it into the backup.
          await _setAside(file);
        }
        return tasks;
      }
    }
    await _setAside(file);

    final legacy = await _legacyFile();
    if (legacy == null) return null;
    final tasks = await _read(legacy);
    if (tasks == null) return null;
    try {
      await _writeAtomically(file, jsonEncode(tasks));
      await legacy.delete();
    } catch (e) {
      // The old file stays, so the move is tried again next launch.
      debugPrint('[DownloadTaskStore] could not move the old list: $e');
    }
    return tasks;
  }

  /// Saves the list [encode] returns at the time of writing. Saves made while
  /// a write is running are folded into one more write of the latest list.
  Future<void> save(String Function() encode) {
    _latest = encode;
    _dirty = true;
    return _writing ??= _drain();
  }

  Future<void> _drain() async {
    try {
      while (_dirty) {
        _dirty = false;
        try {
          await _writeAtomically(await _file(), _latest!());
        } catch (e) {
          debugPrint('[DownloadTaskStore] Failed to persist tasks: $e');
        }
      }
    } finally {
      _writing = null;
    }
  }

  Future<void> _writeAtomically(File file, String payload) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(payload, flush: true);
    if (await file.exists()) {
      await file.rename('${file.path}.bak');
    }
    await tmp.rename(file.path);
  }

  Future<File?> _legacyFile() async {
    try {
      final dir = await _legacyDirectory?.call();
      if (dir == null) return null;
      final file = File(p.join(dir.path, legacyFileName));
      return await file.exists() ? file : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _setAside(File file) async {
    try {
      if (await file.exists()) await file.rename('${file.path}.corrupt');
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>?> _read(File file) async {
    try {
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final decoded = jsonDecode(content);
      if (decoded is! List) return null;
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('[DownloadTaskStore] ${p.basename(file.path)} unreadable: $e');
      return null;
    }
  }
}
