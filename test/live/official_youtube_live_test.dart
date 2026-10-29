@Tags(['network'])
library;

// Live check of the official-upload source against real YouTube.
//
//   flutter test --run-skipped --tags network test/live/official_youtube_live_test.dart
//
// Prints what each lookup resolved to, and fails only when 凡人修仙传's recent
// episodes do not resolve to a whitelisted channel at all.

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/official/official_channels.dart';
import 'package:zplay/services/official/official_episode_matcher.dart';
import 'package:zplay/services/official/official_youtube_source.dart';

void main() {
  const names = ['凡人修仙传', "A Mortal's Journey"];

  Future<List<OfficialMatch>> look(int episode, {int? season}) async {
    final source = OfficialYouTubeSource();
    final sw = Stopwatch()..start();
    final found = await source.find(
      OfficialQuery(names: names, season: season ?? 1, episode: episode),
      region: 'MY',
    );
    // ignore: avoid_print
    print('凡人修仙传 E$episode (${sw.elapsedMilliseconds} ms):');
    for (final m in found) {
      // ignore: avoid_print
      print(
        '  ${m.kind.name.padRight(11)} ${m.upload.videoId} '
        '[${m.channel?.name}] ${m.upload.duration} ${m.upload.title}',
      );
    }
    if (found.isEmpty) {
      // ignore: avoid_print
      print('  (nothing)');
    }
    return found;
  }

  test('凡人修仙传 recent episodes resolve to a whitelisted channel', () async {
    final hits = <OfficialMatch>[];
    for (final e in [196, 195, 194, 190, 177, 170]) {
      hits.addAll(await look(e));
    }
    expect(
      hits.where(
        (m) =>
            m.kind == OfficialMatchKind.episode &&
            OfficialChannels.isWhitelisted(m.upload.channelId),
      ),
      isNotEmpty,
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a donghua on Tencent Video - Animation', () async {
    final source = OfficialYouTubeSource();
    final found = await source.find(
      const OfficialQuery(names: ['元尊', 'Dragon Prince Yuan'], episode: 18),
      region: 'MY',
    );
    // ignore: avoid_print
    print('元尊 E18:');
    for (final m in found) {
      // ignore: avoid_print
      print(
        '  ${m.kind.name.padRight(11)} ${m.upload.videoId} '
        '[${m.channel?.name}] ${m.upload.duration} ${m.upload.title}',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
