import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the viewer's connection can sustain, learned from their own playback.
///
/// No speed-test host is contacted: the samples are the downloads the viewer
/// is already making. The player reports the peak rate it filled its cache at
/// for a direct stream, and the torrent engine its peak swarm rate. Until a
/// sample exists the estimate is null and source picking assumes a 1080p
/// connection.
abstract final class NetworkSpeed {
  static const String _storageKey = 'lumora_network_mbps';

  /// Megabits per second, smoothed; null until the first sample.
  static final ValueNotifier<double?> mbps = ValueNotifier<double?>(null);

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mbps.value = prefs.getDouble(_storageKey);
    } catch (_) {}
  }

  /// A direct stream's peak download rate: the line's real capacity, so it
  /// moves the estimate either way.
  static void recordLink(double sampleMbps) => _record(sampleMbps, raiseOnly: false);

  /// A torrent's peak rate. A slow swarm says nothing about the line, so a
  /// torrent sample can only raise the estimate.
  static void recordTorrent(double sampleMbps) => _record(sampleMbps, raiseOnly: true);

  static void _record(double sample, {required bool raiseOnly}) {
    if (!sample.isFinite || sample <= 0.05) return;
    final current = mbps.value;
    double next;
    if (current == null) {
      next = sample;
    } else if (raiseOnly) {
      if (sample <= current) return;
      next = current * 0.5 + sample * 0.5;
    } else {
      next = current * 0.6 + sample * 0.4;
    }
    mbps.value = double.parse(next.toStringAsFixed(2));
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setDouble(_storageKey, mbps.value!))
        .catchError((_) => false);
  }

  @visibleForTesting
  static void resetForTesting() => mbps.value = null;
}
