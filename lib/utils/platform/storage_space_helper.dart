import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart' show GetDiskFreeSpaceEx;

class StorageSpaceInfo {
  final int freeBytes;
  final int totalBytes;

  const StorageSpaceInfo({required this.freeBytes, required this.totalBytes});

  String get freeFormatted => _formatBytes(freeBytes);
  String get totalFormatted => _formatBytes(totalBytes);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(i == 0 ? 0 : 2)} ${suffixes[i]}';
  }
}

/// Helper to check available disk space before initiating media downloads.
class StorageSpaceHelper {
  /// Checks free space for the partition containing [directoryPath].
  /// Returns a [StorageSpaceInfo] or null if undetermined.
  static Future<StorageSpaceInfo?> getAvailableSpace(
    String directoryPath,
  ) async {
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      if (!kIsWeb && Platform.isWindows) {
        // Asked of Windows directly. The old `wmic` call is gone from current
        // Windows 11, so it silently answered "unknown" and downloads went
        // ahead onto a full disk; any other command-line tool would also risk
        // flashing a console window from this console-less app.
        return _windowsFreeSpace(directoryPath);
      } else if (!kIsWeb &&
          (Platform.isLinux || Platform.isMacOS || Platform.isAndroid)) {
        final result = await Process.run('df', ['-k', directoryPath]);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().trim().split('\n');
          if (lines.length >= 2) {
            final parts = lines.last.split(RegExp(r'\s+'));
            if (parts.length >= 4) {
              final totalKb = int.tryParse(parts[1]) ?? 0;
              final freeKb = int.tryParse(parts[3]) ?? 0;
              return StorageSpaceInfo(
                freeBytes: freeKb * 1024,
                totalBytes: totalKb * 1024,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[StorageSpaceHelper] Error checking free space: $e');
    }
    // Undetermined. There is deliberately no assumed-capacity fallback: a
    // fabricated "50 GB free of 128 GB" reads as a measurement, so a caller
    // that shows it to a person is showing them a number the app made up.
    // Callers render nothing when this is null, and `hasEnoughSpace` treats
    // null as "cannot prove there is too little" and allows the download.
    return null;
  }

  /// `GetDiskFreeSpaceEx` for the volume holding [directoryPath], which may be
  /// any folder on it (a drive, a mount point or a network share). The free
  /// figure is what this user may write, so a disk quota is respected.
  static StorageSpaceInfo? _windowsFreeSpace(String directoryPath) {
    return using((arena) {
      final path = directoryPath.toNativeUtf16(allocator: arena);
      final freeToCaller = arena<Uint64>();
      final total = arena<Uint64>();
      final ok = GetDiskFreeSpaceEx(path, freeToCaller, total, nullptr);
      if (ok == 0) return null;
      return StorageSpaceInfo(
        freeBytes: freeToCaller.value,
        totalBytes: total.value,
      );
    });
  }

  /// Verifies if there is sufficient space for [requiredBytes] + 100MB margin.
  static Future<bool> hasEnoughSpace(
    String directoryPath,
    int requiredBytes,
  ) async {
    if (requiredBytes <= 0) return true;
    final info = await getAvailableSpace(directoryPath);
    if (info == null) return true;
    final requiredWithMargin =
        requiredBytes + (100 * 1024 * 1024); // 100MB safety margin
    return info.freeBytes >= requiredWithMargin;
  }
}
