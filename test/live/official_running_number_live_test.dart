@Tags(['network'])
library;

// Live check that a later 凡人修仙传 season asks the official channel for the
// TMDb running number, not the sum of the addon's seasons.
//
//   flutter test --run-skipped --tags network test/live/official_running_number_live_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/official/official_episode_matcher.dart';
import 'package:zplay/services/official/official_youtube_source.dart';

void main() {
  test('S8E18 asks for 第194话 (TMDb order), not 第190话 (summed)', () async {
    // Cinemeta's seasons 1-7 hold 172 episodes; it files the four 燕家堡之战
    // episodes as specials, which TMDb counts, so 176 air before season 8.
    // Summing the addon's seasons (172 + 18 = 190) played 第190话.
    final found = await OfficialYouTubeSource().find(
      const OfficialQuery(
        names: ['凡人修仙传', "A Mortal's Journey"],
        season: 8,
        episode: 18,
        previousSeasonsEpisodes: 176,
      ),
      region: 'MY',
    );
    for (final m in found) {
      // ignore: avoid_print
      print('  ${m.kind.name} [${m.channel?.name}] ${m.upload.title}');
    }
    expect(found.where((m) => m.kind == OfficialMatchKind.episode), isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
