import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/subtitle/subtitle_model.dart';
import 'package:zplay/services/subtitles/subtitle_offset_store.dart';
import 'package:zplay/services/subtitles/subtitle_parser.dart';
import 'package:zplay/widgets/player/subtitle_align_sheet.dart';
import 'package:zplay/widgets/player/subtitle_cue_overlay.dart';

const cues = [
  SubCue(start: 186.0, end: 188.5, text: '王林，你可想好了？'),
  SubCue(start: 189.4, end: 191.0, text: '去了，就不能回头了'),
  SubCue(start: 191.2, end: 193.5, text: '这一天，终于来了'),
  SubCue(start: 194.0, end: 196.8, text: '爹，娘，我会回来的'),
  SubCue(start: 197.3, end: 199.0, text: '孩儿，保重'),
  SubCue(start: 200.0, end: 202.0, text: '走吧'),
];

void main() {
  group('the line on screen', () {
    test('is the cue the time falls in', () {
      expect(activeCueText(cues, 192.0), '这一天，终于来了');
      expect(activeCueText(cues, 188.9), isNull);
      expect(activeCueText(cues, 10), isNull);
    });

    test('follows the delay: positive shows lines later', () {
      // At 193.0 with +1.5 s, the line from 191.5 is showing.
      expect(activeCueText(cues, 193.0, delaySec: 1.5), '这一天，终于来了');
      expect(activeCueText(cues, 190.0, delaySec: -1.5), '这一天，终于来了');
    });
  });

  group('aligning a line', () {
    test('lists the lines around what is showing now', () {
      final lines = SubtitleAlign.nearby(cues, 192.0, 0);
      expect(lines, hasLength(5));
      expect(lines.map((c) => c.text), contains('这一天，终于来了'));
    });

    test('the line picked starts now', () {
      // The viewer hears "这一天" at 192.0 but the subtitle has it at 191.2.
      expect(SubtitleAlign.delayFor(cues[2], 192.0), 0.8);
      // Subtitles running late are pulled earlier.
      expect(SubtitleAlign.delayFor(cues[3], 192.0), -2.0);
    });

    test('works at the start and end of the file', () {
      expect(SubtitleAlign.nearby(cues, 0, 0), hasLength(5));
      expect(SubtitleAlign.nearby(cues, 999, 0), hasLength(5));
      expect(SubtitleAlign.nearby(const [], 10, 0), isEmpty);
    });
  });

  group('remembered timing', () {
    SubtitleVariant v(String title) => SubtitleVariant(
      providerName: 'OpenSubtitles',
      language: 'chi',
      title: title,
      downloadUrl: title,
      format: 'srt',
    );

    test('carries over to the next episode of the same release', () {
      expect(
        SubtitleOffsetStore.keyFor(
          'tt1',
          v('Renegade.Immortal.S01E02.1080p.WEB-DL'),
        ),
        SubtitleOffsetStore.keyFor(
          'tt1',
          v('Renegade.Immortal.S01E03.1080p.WEB-DL'),
        ),
      );
    });

    test('is kept apart for another title or release', () {
      final a = SubtitleOffsetStore.keyFor('tt1', v('Show.S01E02.WEB-DL'));
      expect(
        a,
        isNot(SubtitleOffsetStore.keyFor('tt2', v('Show.S01E02.WEB-DL'))),
      );
      expect(
        a,
        isNot(SubtitleOffsetStore.keyFor('tt1', v('Show.S01E02.HDTV'))),
      );
    });

    test('is saved, read back, and forgotten at zero', () async {
      SharedPreferences.setMockInitialValues({});
      await SubtitleOffsetStore.save('k', -1.23);
      expect(await SubtitleOffsetStore.load('k'), -1.23);
      await SubtitleOffsetStore.save('k', 0);
      expect(await SubtitleOffsetStore.load('k'), isNull);
    });
  });
}
