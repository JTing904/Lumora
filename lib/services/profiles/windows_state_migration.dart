/// One-shot migration of the Windows application-support profile left behind by
/// the rebrand.
///
/// **Why this exists.** `windows/runner/Runner.rc` is not cosmetic: the Windows
/// `path_provider` / `shared_preferences` plugins derive the app-support root
/// from its VERSIONINFO fields, as
/// `%APPDATA%\<CompanyName>\<ProductName>` (see the plugin's own
/// `_getApplicationSpecificSubdirectory`, which drops the company component
/// when the field is empty and falls back to the executable name when the
/// product name is empty). Those fields read `com.example` / `playtorrio` for
/// every install up to and including the rebrand commit `57b590d`
/// (`git show 57b590d~1:windows/runner/Runner.rc`), which changed them to
/// `tzero86` / `zplay`. That silently relocated every user's profile, so the
/// first launch after the rebrand saw an empty directory: no settings, no
/// watchlist, no addons, no TorrServer database. `docs/RENAME_PRODUCT_PLAN.md`
/// (§6, phase P5) scheduled this copy step; it was never implemented.
///
/// **Why it refuses to overwrite.** The destination is skipped whenever it
/// already exists. A user who has already run the new build and reconfigured
/// it has real work in that directory, and clobbering it with a stale copy from
/// the previous install would destroy it — the failure this whole file exists
/// to prevent, just pointed the other way.
///
/// The source is never deleted or moved: it stays in place as a fallback, so
/// the migration is reversible by removing the destination.
///
/// **Why a failed copy is retried anyway.** A copy that fails (or is killed)
/// leaves no destination, but the rest of startup then reads preferences and
/// the plugin creates an empty one, which the rule above would protect
/// forever. So a `<destination>.migration-pending` marker is written before
/// the copy starts and removed only once the copy is in place. While it is
/// there, an existing destination is known to be the app's own empty-start
/// profile rather than a migrated one, and the next launch moves it aside
/// (never deletes it) and copies again, at most [_maxAttempts] times.
/// Installs migrated before the marker existed have no marker, so they keep
/// the plain "destination exists, stay out" rule.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// What a (legacy, destination) pair calls for.
enum WindowsStateMigrationAction {
  /// The legacy profile exists and holds something, and the new location is
  /// free. This is the only action that writes anything.
  copy,

  /// The new profile directory already exists: the user owns it, so the
  /// migration stays out of it. Also returned when it is created by a previous
  /// successful run, which is what makes the whole thing one-shot.
  skipDestinationExists,

  /// An earlier copy started and never finished, and the destination that
  /// exists now was created by the app starting empty afterwards. It is moved
  /// aside and the copy runs again.
  retryAfterFailure,

  /// Another running copy of the app holds the migration lock and did not
  /// finish within the wait. Nothing was touched; the next launch decides.
  lockedByAnotherCopy,

  /// Nothing at the legacy path — a fresh install, or a user who already moved
  /// their own data across.
  noLegacyProfile,

  /// The legacy directory exists but is empty, so copying it would only
  /// manufacture an empty destination that then blocks every later attempt.
  emptyLegacyProfile,

  /// The migration does not apply here: not Windows, or no resolvable
  /// `%APPDATA%` to derive a profile root from.
  notApplicable,
}

/// Suffix of the staging directory used while copying, as a sibling of the
/// destination.
const String _stagingSuffix = '.migrating';

/// Suffix of the marker written before a copy and removed after it succeeds,
/// as a sibling of the destination. It holds the number of attempts so far.
const String _pendingSuffix = '.migration-pending';

/// Suffix of the lock file held while one process migrates, so a second copy
/// of the app never deletes or races the first one's staging directory.
const String _lockSuffix = '.migration-lock';

/// Suffix the app's own empty-start profile is moved aside under on a retry.
const String _replacedSuffix = '.before-migration-';

/// A copy that keeps failing (a locked or unreadable legacy file) would
/// otherwise slow every launch down for good.
const int _maxAttempts = 3;

/// Candidate legacy profile roots, most specific first, relative to
/// `%APPDATA%`.
///
/// `com.example/playtorrio` is the identity every pre-rebrand install wrote
/// to. The bare entries cover the fallback layouts `path_provider_windows`
/// produces when a VERSIONINFO field is missing: without a company name the
/// root is the product name alone, without a product name it is the executable
/// name. Probing a candidate list rather than one hardcoded path is the
/// established convention on this side of the codebase — see the renderer
/// preference lookup in `windows/runner/main.cpp:35-38`, which probes the same
/// two-way layout split.
const List<List<String>> _legacyProfileCandidates = <List<String>>[
  // Lumora 1.0.0 and the ZPlay builds before it.
  <String>['tzero86', 'zplay'],
  <String>['com.example', 'playtorrio'],
  <String>['playtorrio'],
  <String>['zplay'],
];

/// Destination identity. Pinned here rather than read from `path_provider`
/// because this runs before any plugin call: it must mirror `Runner.rc`'s
/// `CompanyName` / `ProductName` exactly, so changing the rebrand identity
/// means changing this line too.
const List<String> _destinationProfileSegments = <String>['JTing904', 'Lumora'];

/// The Windows app-support root the `path_provider` / `shared_preferences`
/// plugins use, `%APPDATA%\<CompanyName>\<ProductName>`, or null when
/// `%APPDATA%` is not set. Built here, without a plugin call, so it can be
/// used before the first plugin read.
String? windowsProfileRoot() {
  final appData = Platform.environment['APPDATA'];
  if (appData == null || appData.isEmpty) return null;
  return p.joinAll(<String>[appData, ..._destinationProfileSegments]);
}

/// Decides what should happen to a profile pair, touching the filesystem only
/// to stat it. Kept free of the platform guard, `%APPDATA%` resolution and
/// copying so the rule can be exercised directly by a unit test on any host.
WindowsStateMigrationAction planWindowsStateMigration({
  required String legacyPath,
  required String destinationPath,
}) {
  // Checked before anything else: if the destination is there we must not
  // touch it, whatever the legacy directory contains, unless our own marker
  // says it only exists because an earlier copy failed.
  if (Directory(destinationPath).existsSync()) {
    return _retryOwed(legacyPath, destinationPath)
        ? WindowsStateMigrationAction.retryAfterFailure
        : WindowsStateMigrationAction.skipDestinationExists;
  }
  final legacy = Directory(legacyPath);
  if (!legacy.existsSync()) {
    return WindowsStateMigrationAction.noLegacyProfile;
  }
  if (legacy.listSync().isEmpty) {
    return WindowsStateMigrationAction.emptyLegacyProfile;
  }
  return WindowsStateMigrationAction.copy;
}

bool _retryOwed(String legacyPath, String destinationPath) {
  final pending = File('$destinationPath$_pendingSuffix');
  if (!pending.existsSync()) return false;
  if (_attemptsSoFar(pending) >= _maxAttempts) return false;
  final legacy = Directory(legacyPath);
  return legacy.existsSync() && legacy.listSync().isNotEmpty;
}

int _attemptsSoFar(File pending) {
  try {
    return int.tryParse(pending.readAsStringSync().trim()) ?? 0;
  } on FileSystemException {
    return 0;
  }
}

/// Takes the migration lock, waiting up to [timeout] for another copy of the
/// app that holds it. Polls a non-blocking lock rather than blocking, so a
/// timeout never leaves a lock request pending on a closed file.
Future<RandomAccessFile?> _acquireMigrationLock(
  String destinationPath,
  Duration timeout,
) async {
  final RandomAccessFile handle;
  try {
    final file = File('$destinationPath$_lockSuffix');
    file.parent.createSync(recursive: true);
    handle = file.openSync(mode: FileMode.append);
  } on FileSystemException catch (e) {
    debugPrint('[WindowsMigration] could not open the migration lock: $e');
    return null;
  }
  final deadline = DateTime.now().add(timeout);
  while (true) {
    try {
      handle.lockSync(FileLock.exclusive);
      return handle;
    } on FileSystemException {
      if (DateTime.now().isAfter(deadline)) {
        handle.closeSync();
        return null;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
}

void _releaseMigrationLock(RandomAccessFile handle, String destinationPath) {
  try {
    handle.unlockSync();
    handle.closeSync();
    File('$destinationPath$_lockSuffix').deleteSync();
  } on FileSystemException {
    // Another copy has it open, or it is already gone: either is fine.
  }
}

/// Copies [legacyPath] to [destinationPath] if [planWindowsStateMigration]
/// says so. Never throws and never deletes user data: a failed run leaves the
/// legacy profile exactly as it was, and a retry moves the destination it
/// replaces aside instead of removing it.
///
/// [lockWait] bounds how long this waits for another copy of the app that is
/// migrating at the same moment.
Future<WindowsStateMigrationAction> migrateWindowsProfile({
  required String legacyPath,
  required String destinationPath,
  Duration lockWait = const Duration(minutes: 2),
}) async {
  var action = planWindowsStateMigration(
    legacyPath: legacyPath,
    destinationPath: destinationPath,
  );
  if (!_writes(action)) return action;

  final lock = await _acquireMigrationLock(destinationPath, lockWait);
  if (lock == null) {
    debugPrint('[WindowsMigration] another copy is migrating; leaving it');
    return WindowsStateMigrationAction.lockedByAnotherCopy;
  }
  try {
    // Planned again under the lock: a copy that held it may have just
    // finished the job.
    action = planWindowsStateMigration(
      legacyPath: legacyPath,
      destinationPath: destinationPath,
    );
    if (!_writes(action)) return action;
    await _copyIntoPlace(legacyPath, destinationPath);
    return action;
  } finally {
    _releaseMigrationLock(lock, destinationPath);
  }
}

bool _writes(WindowsStateMigrationAction action) =>
    action == WindowsStateMigrationAction.copy ||
    action == WindowsStateMigrationAction.retryAfterFailure;

Future<void> _copyIntoPlace(String legacyPath, String destinationPath) async {
  // Before any write, so a run that fails or is killed from here on is
  // retried by the next launch even after the app has created an empty
  // destination in the meantime.
  final pending = File('$destinationPath$_pendingSuffix');
  try {
    pending.writeAsStringSync('${_attemptsSoFar(pending) + 1}', flush: true);
  } on FileSystemException catch (e) {
    debugPrint('[WindowsMigration] could not write the pending marker: $e');
  }

  // Copy into a staging sibling and rename it into place. Writing straight
  // into the destination would leave a half-copied profile behind if the
  // process died mid-copy. rename() is atomic within a volume, and a sibling
  // path is always the same volume.
  final stagingPath = '$destinationPath$_stagingSuffix';
  final staging = Directory(stagingPath);

  try {
    if (staging.existsSync()) {
      // Only a dead run can have left this behind: a live one would still
      // hold the lock this run now has. Reclaiming the reserved name is what
      // makes the migration recoverable rather than permanently blocked.
      debugPrint('[WindowsMigration] reclaiming leftover $stagingPath');
      staging.deleteSync(recursive: true);
    }
    final legacy = Directory(legacyPath);
    final counts = await _copyTree(legacy, stagingPath);
    final destination = Directory(destinationPath);
    if (destination.existsSync()) {
      // The empty-start profile from the launch after the failed copy. Kept,
      // not deleted, in case the user did set something up in it.
      final aside =
          '$destinationPath$_replacedSuffix'
          '${DateTime.now().millisecondsSinceEpoch}';
      destination.renameSync(aside);
      debugPrint('[WindowsMigration] moved the empty-start profile to $aside');
    }
    staging.renameSync(destinationPath);
    try {
      pending.deleteSync();
    } on FileSystemException {
      // Harmless: with the copy in place the next launch only re-checks.
    }
    debugPrint(
      '[WindowsMigration] $legacyPath -> $destinationPath '
      '(${counts.files} files, ${counts.directories} directories, '
      '${counts.skippedLinks} links skipped); legacy profile left in place',
    );
  } catch (e) {
    // Only ever removes the directory this run created; the pending marker
    // stays so the next launch tries again.
    if (staging.existsSync()) {
      try {
        staging.deleteSync(recursive: true);
      } catch (_) {
        // Nothing useful to do: the copy already failed and the next run
        // reclaims the same path anyway.
      }
    }
    debugPrint('[WindowsMigration] migration from $legacyPath failed: $e');
  }
}

/// Resolves the real profile root and runs the migration once. Call it from
/// the Dart bootstrap before anything reads a plugin-owned path; it is
/// deliberately synchronous work behind an awaited call, because the first
/// `path_provider` / `shared_preferences` read creates the destination and
/// would then make the copy unreachable.
Future<WindowsStateMigrationAction> migrateLegacyWindowsState() async {
  if (!Platform.isWindows) return WindowsStateMigrationAction.notApplicable;

  // `%APPDATA%` is already the Roaming known folder, so this matches
  // `windows/runner/main.cpp`, which builds the same paths from the same
  // environment variable.
  final appData = Platform.environment['APPDATA'];
  if (appData == null || appData.isEmpty) {
    debugPrint('[WindowsMigration] %APPDATA% is not set; nothing to migrate');
    return WindowsStateMigrationAction.notApplicable;
  }

  final destinationPath = p.joinAll(<String>[
    appData,
    ..._destinationProfileSegments,
  ]);
  // The overwhelmingly common case after the first successful migration is
  // "already done", so two stats short-circuit before any candidate is
  // stat'ed. Without the pending marker an existing destination is never
  // touched.
  if (Directory(destinationPath).existsSync() &&
      !File('$destinationPath$_pendingSuffix').existsSync()) {
    return WindowsStateMigrationAction.skipDestinationExists;
  }

  for (final segments in _legacyProfileCandidates) {
    final legacyPath = p.joinAll(<String>[appData, ...segments]);
    if (!Directory(legacyPath).existsSync()) continue;
    return migrateWindowsProfile(
      legacyPath: legacyPath,
      destinationPath: destinationPath,
    );
  }

  debugPrint('[WindowsMigration] no legacy profile under $appData');
  return WindowsStateMigrationAction.noLegacyProfile;
}

Future<({int files, int directories, int skippedLinks})> _copyTree(
  Directory source,
  String targetPath,
) async {
  final target = Directory(targetPath);
  await target.create(recursive: true);

  var files = 0;
  var directories = 0;
  var skippedLinks = 0;
  // followLinks: false so a link is copied as nothing rather than silently
  // expanded — a cycle in a profile directory would otherwise recurse until
  // the disk filled up.
  await for (final entity in source.list(followLinks: false)) {
    final childPath = p.join(targetPath, p.basename(entity.path));
    if (entity is Directory) {
      directories++;
      final counts = await _copyTree(entity, childPath);
      files += counts.files;
      directories += counts.directories;
      skippedLinks += counts.skippedLinks;
    } else if (entity is File) {
      await entity.copy(childPath);
      files++;
    } else {
      skippedLinks++;
    }
  }
  return (files: files, directories: directories, skippedLinks: skippedLinks);
}
