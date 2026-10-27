/// A live report of every source the app would offer for one title: when it
/// arrived, what it is, and whether the liveness probe passes. The companion
/// `tool/mpv_check.py` then opens each direct link in the app's own libmpv and
/// times the first decoded frame, which is the question the probe only
/// approximates.
///
/// Run on demand:
///
///   LUMORA_TITLE="Spider-Man: Brand New Day" LUMORA_ID=tt22084616 \
///   LUMORA_TYPE=movie LUMORA_YEAR=2026 LUMORA_REPORT=report.json \
///   flutter test --run-skipped --tags network test/live/source_report_test.dart
@Tags(['network'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/services/addon/addon_manager.dart';
import 'package:zplay/services/config/env_service.dart';
import 'package:zplay/services/player/player_settings.dart';
import 'package:zplay/models/stream/stream_model.dart';
import 'package:zplay/services/stream/auto_source_picker.dart';
import 'package:zplay/services/stream/stream_health_checker.dart';
import 'package:zplay/services/stream/stream_service.dart';

void main() {
  test('source report', () async {
    final env = Platform.environment;
    final title = env['LUMORA_TITLE'] ?? 'The Godfather Part III';
    final id = env['LUMORA_ID'] ?? 'tt0099674';
    final type = env['LUMORA_TYPE'] ?? 'movie';
    final year = int.tryParse(env['LUMORA_YEAR'] ?? '') ?? 1990;
    final season = int.tryParse(env['LUMORA_SEASON'] ?? '');
    final episode = int.tryParse(env['LUMORA_EPISODE'] ?? '');
    final out = env['LUMORA_REPORT'] ?? 'source_report.json';

    SharedPreferences.setMockInitialValues({});
    await EnvService.initialize();
    await AddonManager.instance.initialize();

    final started = DateTime.now();
    final rows = <Map<String, Object?>>[];
    final probes = <Future<void>>[];
    await for (final s in StreamService.fetchStreams(
      type: type,
      id: season != null ? '$id:$season:${episode ?? 1}' : id,
      title: title,
      year: year,
      season: season,
      episode: episode,
    ).timeout(const Duration(seconds: 40), onTimeout: (sink) => sink.close())) {
      final row = <String, Object?>{
        'arrivedMs': DateTime.now().difference(started).inMilliseconds,
        'addon': s.addonName,
        'provider': s.providerLabel,
        'title': s.title ?? s.name,
        'name': s.name,
        'rawTitle': s.title,
        'description': s.description,
        'quality': s.quality,
        'size': s.fileSize,
        'seeders': s.seeders,
        'torrent': s.isTorrent,
        'infoHash': s.infoHash,
        'fileIdx': s.fileIdx,
        'url': s.url,
        'external': s.externalUrl,
        'headers': s.url == null
            ? null
            : PlayerSettings.resolveStreamHeaders(s.url!, s.headers),
      };
      rows.add(row);
      if (!s.isTorrent && s.url != null) {
        final t0 = DateTime.now();
        probes.add(
          StreamHealthChecker.isAlive(s)
              .timeout(const Duration(seconds: 10), onTimeout: () => false)
              .then((alive) {
                row['probeAlive'] = alive;
                row['probeMs'] = DateTime.now().difference(t0).inMilliseconds;
              }),
        );
      }
    }
    await Future.wait(probes);
    StreamService.stopAllScrapers();

    // The queue 自动 would hand the player, in arrival order as the ranking
    // (the screen's own sort also weighs addon order), on the probe answers
    // above and the line speed in LUMORA_MBPS.
    final byKey = <String, Map<String, Object?>>{};
    final sources = <StreamSource>[];
    for (final row in rows) {
      final s = StreamSource(
        name: row['name'] as String?,
        title: row['rawTitle'] as String?,
        description: row['description'] as String?,
        url: row['url'] as String?,
        externalUrl: row['external'] as String?,
        infoHash: row['infoHash'] as String?,
        fileIdx: row['fileIdx'] as int?,
        addonName: row['addon'] as String,
      );
      byKey[AutoSourcePicker.keyOf(s)] = row;
      sources.add(s);
    }
    final picker =
        AutoSourcePicker(
            probe: (s) async =>
                byKey[AutoSourcePicker.keyOf(s)]?['probeAlive'] == true,
          )
          ..bandwidthMbps = double.tryParse(env['LUMORA_MBPS'] ?? '')
          ..runtimeMinutes = int.tryParse(env['LUMORA_RUNTIME'] ?? '');
    final pick = await picker.pick(sources);
    final queue = [
      for (final s in pick?.alternatives ?? const <StreamSource>[])
        rows.indexOf(byKey[AutoSourcePicker.keyOf(s)]!),
    ];

    File(out).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'title': title,
        'id': id,
        'type': type,
        'year': year,
        'runtime': int.tryParse(env['LUMORA_RUNTIME'] ?? ''),
        'queue': queue,
        'sources': rows,
      }),
    );
    // ignore: avoid_print
    print('wrote ${rows.length} sources to $out');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
