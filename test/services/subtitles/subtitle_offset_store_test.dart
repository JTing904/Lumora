import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/services/subtitles/subtitle_offset_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reads an offset saved before the stretch existed', () async {
    SharedPreferences.setMockInitialValues({
      'subtitle_offsets_v1': '{"a|p|n": 1.5}',
    });
    final t = (await SubtitleOffsetStore.loadTiming('a|p|n'))!;
    expect(t.delaySec, 1.5);
    expect(t.ratio, 1);
    expect(t.auto, isFalse);
    expect(await SubtitleOffsetStore.load('a|p|n'), 1.5);
  });

  test('a plain offset is still saved as a plain number', () async {
    await SubtitleOffsetStore.save('k', 2.346);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('subtitle_offsets_v1'), '{"k":2.35}');
  });

  test('keeps the stretch and who set the timing', () async {
    await SubtitleOffsetStore.saveTiming(
      'k',
      const SubtitleTiming(-0.4, ratio: 25 / 23.976, auto: true),
    );
    final t = (await SubtitleOffsetStore.loadTiming('k'))!;
    expect(t.delaySec, -0.4);
    expect(t.ratio, closeTo(25 / 23.976, 1e-6));
    expect(t.auto, isTrue);
  });

  test(
    'a stretch alone is worth keeping, nothing at all is forgotten',
    () async {
      await SubtitleOffsetStore.saveTiming(
        'k',
        const SubtitleTiming(0, ratio: 24 / 25),
      );
      expect(
        (await SubtitleOffsetStore.loadTiming('k'))!.ratio,
        closeTo(0.96, 1e-6),
      );
      await SubtitleOffsetStore.saveTiming('k', const SubtitleTiming(0));
      expect(await SubtitleOffsetStore.loadTiming('k'), isNull);
    },
  );

  test('a viewer save over an auto one clears the auto mark', () async {
    await SubtitleOffsetStore.saveTiming(
      'k',
      const SubtitleTiming(3, auto: true),
    );
    await SubtitleOffsetStore.save('k', 2);
    final t = (await SubtitleOffsetStore.loadTiming('k'))!;
    expect(t.auto, isFalse);
    expect(t.ratio, 1);
  });
}
