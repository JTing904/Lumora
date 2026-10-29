@Tags(['network'])
library;

// Live check of the third whitelist batch (licensed English-language
// distributors and the Shanghai / Zhejiang broadcasters) against real YouTube.
//
//   flutter test --run-skipped --tags network test/live/official_third_batch_live_test.dart
//
// Prints what each lookup resolved to; fails only when none of the films
// resolves to a third-batch channel at all.

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/official/official_episode_matcher.dart';
import 'package:zplay/services/official/official_youtube_source.dart';

void main() {
  const thirdBatch = {
    'UC52EYUUSlzcYqHj-qsx0RHg',
    'UCJ06BguWKS5GJsEue7u79PQ',
    'UCahKjkez9olNwcpc5pZwzvg',
    'UC8IHAQMuiJdY6ALuhG7iU8Q',
    'UCVVXDVee0JZ2dlPYtpdTZVg',
    'UCVFYikepF-avelvuIaQ_lHA',
    'UCGBzBkV-MinlBvHBzZawfLQ',
    'UCvRI1Nyvj9pAyHPzX7AviWQ',
    'UC6A_LC-A5NVJ2vw9A0OjCug',
    'UCyJYCQ6WaEMhdZAuPo799bA',
    'UCUZzyuAlhHNP3oiuMjn7RfQ',
    'UCijcd0GR0fkxCAZwkiuWqtQ',
    'UCQtW2oz8ec8pHjjxawujNjg',
    'UCsgPO6cNV0wBG-Og3bUZoFA',
    'UC88lvyJe7aHZmcvzvubDFRg',
    'UCu4XcDBdnZkV6-5z2f16M0g',
  };

  Future<List<OfficialMatch>> look(String label, OfficialQuery query) async {
    final found = await OfficialYouTubeSource().find(query, region: 'MY');
    // ignore: avoid_print
    print('$label:');
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

  test('licensed films resolve to a third-batch channel', () async {
    final hits = <OfficialMatch>[
      ...await look('McLintock!', const OfficialQuery(names: ['McLintock!'])),
      ...await look('Saturn 3', const OfficialQuery(names: ['Saturn 3'])),
      ...await look(
        'Knightriders',
        const OfficialQuery(names: ['Knightriders']),
      ),
      ...await look('Possessions', const OfficialQuery(names: ['Possessions'])),
    ];
    expect(
      hits.where((m) => thirdBatch.contains(m.upload.channelId)),
      isNotEmpty,
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('series and shows (printed only)', () async {
    await look(
      'PSI Factor S1E6',
      const OfficialQuery(
        names: ['PSI Factor: Chronicles of the Paranormal'],
        season: 1,
        episode: 6,
      ),
    );
    await look(
      '极限挑战 S7E1',
      const OfficialQuery(
        names: ['极限挑战', 'Go Fighting!'],
        season: 7,
        episode: 1,
      ),
    );
    await look(
      '人间世 S2E1',
      const OfficialQuery(
        names: ['人间世', 'Life Matters'],
        season: 2,
        episode: 1,
      ),
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
