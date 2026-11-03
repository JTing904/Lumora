/// Keeps a damaged Windows preferences file from stopping the app at launch.
///
/// **Why this exists.** `shared_preferences_windows` reads
/// `shared_preferences.json` with a bare `json.decode` and no catch, and it
/// writes the file in place rather than through a temporary file, so a power
/// cut or a killed process can leave it truncated or full of zero bytes. The
/// next `SharedPreferences.getInstance()` then throws, `main` never reaches
/// `runApp`, and the runner (which shows the window on the first frame) leaves
/// the process running with no window at all.
///
/// So before the first preferences read the file is checked here. A file that
/// is not a JSON object is moved aside as `shared_preferences.json.corrupt-…`
/// (never deleted, so it can still be inspected or recovered by hand) and the
/// copy saved at the previous good launch is put back in its place. Without
/// that copy the app starts with defaults.
///
/// The last-good copy matters because `JsonDocumentStore` keeps its
/// `__backup` documents in this same file: once the file is damaged, those
/// backups are gone with it.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../profiles/windows_state_migration.dart';

/// What [repairPreferencesFile] found and did.
enum PreferencesFileCheck {
  /// Not Windows, or no profile root could be resolved.
  notApplicable,

  /// No preferences file yet: a fresh install. Nothing to do.
  missing,

  /// The file parsed; it was also saved as the last-good copy.
  valid,

  /// The file could not be read at all (locked or no permission). It is left
  /// alone: it may be perfectly fine.
  unreadable,

  /// The file was damaged and has been replaced by the last-good copy.
  restoredFromLastGood,

  /// The file was damaged and there was no usable last-good copy, so the app
  /// starts with defaults.
  resetToDefaults,

  /// The file was damaged and could not be moved aside.
  repairFailed,
}

/// Suffix of the copy saved at each launch whose preferences file parsed.
const String lastGoodSuffix = '.lastgood';

/// Prefix of the suffix a damaged file is moved aside under.
const String corruptSuffix = '.corrupt-';

/// Whether [bytes] is something `shared_preferences_windows` can load: an
/// empty file (which the plugin treats as no preferences) or UTF-8 JSON whose
/// top level is an object. Anything else either throws inside the plugin or is
/// silently replaced by an empty map on the next write.
@visibleForTesting
bool isLoadablePreferences(List<int> bytes) {
  if (bytes.isEmpty) return true;
  try {
    final text = utf8.decode(bytes);
    if (text.isEmpty) return true;
    return json.decode(text) is Map;
  } on FormatException {
    return false;
  }
}

/// Checks the preferences file at [path] and repairs it if it is damaged.
/// Synchronous on purpose: it runs once before `runApp`, before anything else
/// can open the file. Never throws.
PreferencesFileCheck repairPreferencesFile(String path, {DateTime? now}) {
  try {
    final file = File(path);
    if (!file.existsSync()) return PreferencesFileCheck.missing;

    final List<int> bytes;
    try {
      bytes = _retrying(file.readAsBytesSync);
    } on FileSystemException catch (e) {
      debugPrint('[PrefsGuard] could not read $path: $e');
      return PreferencesFileCheck.unreadable;
    }

    final lastGood = File('$path$lastGoodSuffix');
    if (isLoadablePreferences(bytes)) {
      _saveLastGood(lastGood, bytes);
      return PreferencesFileCheck.valid;
    }

    final stamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final asidePath = '$path$corruptSuffix$stamp';
    try {
      _retrying(() => file.renameSync(asidePath));
    } on FileSystemException catch (e) {
      debugPrint('[PrefsGuard] could not move $path aside: $e');
      return PreferencesFileCheck.repairFailed;
    }
    debugPrint('[PrefsGuard] damaged preferences moved to $asidePath');

    if (lastGood.existsSync()) {
      try {
        final saved = _retrying(lastGood.readAsBytesSync);
        if (saved.isNotEmpty && isLoadablePreferences(saved)) {
          _writeAtomically(path, saved);
          debugPrint('[PrefsGuard] restored preferences from the last launch');
          return PreferencesFileCheck.restoredFromLastGood;
        }
      } on FileSystemException catch (e) {
        debugPrint('[PrefsGuard] could not restore the last-good copy: $e');
      }
    }
    return PreferencesFileCheck.resetToDefaults;
  } catch (e) {
    debugPrint('[PrefsGuard] check failed: $e');
    return PreferencesFileCheck.unreadable;
  }
}

/// Resolves the Windows preferences file the plugin will read and runs
/// [repairPreferencesFile] on it. Call after [migrateLegacyWindowsState], which
/// may have just copied the file in, and before the first preferences read.
PreferencesFileCheck guardWindowsPreferencesFile() {
  if (kIsWeb || !Platform.isWindows) return PreferencesFileCheck.notApplicable;
  final root = windowsProfileRoot();
  if (root == null) return PreferencesFileCheck.notApplicable;
  return repairPreferencesFile(p.join(root, 'shared_preferences.json'));
}

void _saveLastGood(File lastGood, List<int> bytes) {
  // An empty file has nothing worth restoring, and saving it would replace a
  // useful copy from an earlier launch.
  if (bytes.isEmpty) return;
  try {
    _writeAtomically(lastGood.path, bytes);
  } on FileSystemException catch (e) {
    // Only the safety net is lost; this launch is fine.
    debugPrint('[PrefsGuard] could not save the last-good copy: $e');
  }
}

/// Writes through a temporary sibling and a rename, so a crash mid-write can
/// never leave a half-written copy where a good one used to be.
void _writeAtomically(String path, List<int> bytes) {
  final temp = File('$path.tmp');
  _retrying(() => temp.writeAsBytesSync(bytes, flush: true));
  _retrying(() => temp.renameSync(path));
}

/// Runs [operation], trying twice more after a short pause if the file system
/// refuses it. On Windows a virus scanner or the search indexer briefly holds
/// a file that was just written, which is exactly when this runs.
T _retrying<T>(T Function() operation) {
  for (var attempt = 1; ; attempt++) {
    try {
      return operation();
    } on FileSystemException {
      if (attempt >= 3) rethrow;
      sleep(const Duration(milliseconds: 50));
    }
  }
}
