import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/subtitle/subtitle_model.dart';
import 'package:zplay/services/subtitles/subtitle_choice.dart';
import 'package:zplay/widgets/player/subtitle_autoload.dart';

SubtitleVariant _v(String language, String title) => SubtitleVariant(
  providerName: 'test',
  language: language,
  title: title,
  downloadUrl: '$language/$title',
  format: 'srt',
);

SubtitleLanguageGroup _zh(List<String> titles) => SubtitleLanguageGroup(
  language: SubtitleLanguage.chinese.label,
  variants: [for (final t in titles) _v('中文', t)],
);

SubtitleLanguageGroup _en(List<String> titles) => SubtitleLanguageGroup(
  language: SubtitleLanguage.english.label,
  variants: [for (final t in titles) _v('English', t)],
);

PlayerEmbeddedSubtitle _track(int index, String language) =>
    PlayerEmbeddedSubtitle(
      index: index,
      title: 'Track $index',
      language: language,
    );

SubtitleAutoload _decide(
  SubtitlePreference preference, {
  List<SubtitleLanguageGroup> groups = const [],
  List<PlayerEmbeddedSubtitle> embedded = const [],
  bool done = false,
  Duration elapsed = Duration.zero,
}) => SubtitleAutoloadRules.decide(
  preference: preference,
  groups: groups,
  embedded: embedded,
  providersDone: done,
  elapsed: elapsed,
);

void main() {
  group('SubtitlePreference', () {
    test('reads what was stored, and Chinese for anything else', () {
      expect(SubtitlePreference.fromName('off'), SubtitlePreference.off);
      expect(
        SubtitlePreference.fromName('english'),
        SubtitlePreference.english,
      );
      expect(SubtitlePreference.fromName(null), SubtitlePreference.chinese);
      // A build that translated with an AI stored this.
      expect(
        SubtitlePreference.fromName('aiChinese'),
        SubtitlePreference.chinese,
      );
    });

    test('a picked subtitle stands for its language', () {
      expect(
        SubtitlePreference.forLanguage(SubtitleLanguage.english),
        SubtitlePreference.english,
      );
      expect(SubtitlePreference.forLanguage(null), isNull);
    });
  });

  group('decide', () {
    test('off loads nothing, whatever is there', () {
      final d = _decide(
        SubtitlePreference.off,
        groups: [
          _zh(['a']),
        ],
        embedded: [_track(1, 'zh')],
        done: true,
      );
      expect(d, isA<AutoloadNone>());
    });

    test('Chinese: the first Chinese variant', () {
      final d = _decide(
        SubtitlePreference.chinese,
        groups: [
          _zh(['best', 'other']),
          _en(['en']),
        ],
      );
      expect(d, isA<AutoloadVariant>());
      expect((d as AutoloadVariant).variant.title, 'best');
      expect(d.isFallback, isFalse);
    });

    test('a track in the stream beats a download in the same language', () {
      final d = _decide(
        SubtitlePreference.chinese,
        groups: [
          _zh(['a']),
        ],
        embedded: [_track(3, 'chi')],
      );
      expect(d, isA<AutoloadEmbedded>());
      expect((d as AutoloadEmbedded).track.index, 3);
    });

    test('an embedded track in the other language does not count', () {
      final d = _decide(
        SubtitlePreference.chinese,
        groups: [
          _zh(['a']),
        ],
        embedded: [_track(1, 'eng')],
      );
      expect(d, isA<AutoloadVariant>());
    });

    test('English prefers its own embedded track, then the first variant', () {
      expect(
        _decide(
          SubtitlePreference.english,
          groups: [
            _en(['e1']),
            _zh(['z']),
          ],
          embedded: [_track(2, 'en')],
        ),
        isA<AutoloadEmbedded>(),
      );
      final d = _decide(
        SubtitlePreference.english,
        groups: [
          _zh(['z']),
          _en(['e1', 'e2']),
        ],
      );
      expect((d as AutoloadVariant).variant.title, 'e1');
    });

    test('English never falls back to Chinese', () {
      final d = _decide(
        SubtitlePreference.english,
        groups: [
          _zh(['z']),
        ],
        done: true,
        elapsed: const Duration(seconds: 30),
      );
      expect(d, isA<AutoloadNone>());
    });

    test('Chinese waits for Chinese while the search runs', () {
      final d = _decide(
        SubtitlePreference.chinese,
        groups: [
          _en(['e']),
        ],
        elapsed: const Duration(seconds: 3),
      );
      expect(d, isA<AutoloadWait>());
    });

    test('Chinese takes English once the search is over', () {
      final d = _decide(
        SubtitlePreference.chinese,
        groups: [
          _en(['e']),
        ],
        done: true,
      );
      expect(d, isA<AutoloadVariant>());
      expect(d.isFallback, isTrue);
    });

    test('Chinese takes English after the patience runs out', () {
      final d = _decide(
        SubtitlePreference.chinese,
        groups: [
          _en(['e']),
        ],
        elapsed: SubtitleAutoloadRules.patience,
      );
      expect(d.isFallback, isTrue);
      expect(d, isA<AutoloadVariant>());
    });

    test('the fallback prefers English inside the stream', () {
      final d = _decide(
        SubtitlePreference.chinese,
        groups: [
          _en(['e']),
        ],
        embedded: [_track(4, 'eng')],
        done: true,
      );
      expect(d, isA<AutoloadEmbedded>());
      expect(d.isFallback, isTrue);
    });

    test('nothing at all: waits, then gives up when the search ends', () {
      expect(
        _decide(
          SubtitlePreference.chinese,
          elapsed: const Duration(seconds: 20),
        ),
        isA<AutoloadWait>(),
      );
      expect(
        _decide(SubtitlePreference.chinese, done: true),
        isA<AutoloadNone>(),
      );
    });

    test('patience alone is not the end of the search', () {
      final d = _decide(
        SubtitlePreference.english,
        elapsed: const Duration(seconds: 20),
      );
      expect(d, isA<AutoloadWait>());
    });
  });

  group('shouldApply', () {
    final zhVariant = AutoloadVariant(_v('中文', 'z'));
    final enFallback = AutoloadVariant(_v('English', 'e'), fallback: true);
    final zhTrack = AutoloadEmbedded(_track(1, 'zh'));

    test('anything useful applies when nothing is loaded', () {
      expect(
        SubtitleAutoloadRules.shouldApply(AutoloadSettled.nothing, zhVariant),
        isTrue,
      );
      expect(
        SubtitleAutoloadRules.shouldApply(AutoloadSettled.nothing, enFallback),
        isTrue,
      );
      expect(
        SubtitleAutoloadRules.shouldApply(
          AutoloadSettled.nothing,
          const AutoloadWait(),
        ),
        isFalse,
      );
    });

    test('real Chinese replaces the English fallback, not the other way', () {
      expect(
        SubtitleAutoloadRules.shouldApply(AutoloadSettled.fallback, zhVariant),
        isTrue,
      );
      expect(
        SubtitleAutoloadRules.shouldApply(AutoloadSettled.fallback, enFallback),
        isFalse,
      );
      expect(
        SubtitleAutoloadRules.shouldApply(
          AutoloadSettled.downloaded,
          enFallback,
        ),
        isFalse,
      );
    });

    test('only a track from the stream replaces a download', () {
      expect(
        SubtitleAutoloadRules.shouldApply(
          AutoloadSettled.downloaded,
          zhVariant,
        ),
        isFalse,
      );
      expect(
        SubtitleAutoloadRules.shouldApply(AutoloadSettled.downloaded, zhTrack),
        isTrue,
      );
    });

    test('a track from the stream is never replaced', () {
      expect(
        SubtitleAutoloadRules.shouldApply(AutoloadSettled.embedded, zhTrack),
        isFalse,
      );
      expect(
        SubtitleAutoloadRules.shouldApply(AutoloadSettled.embedded, zhVariant),
        isFalse,
      );
    });

    test('settledBy rates what was applied', () {
      expect(
        SubtitleAutoloadRules.settledBy(zhTrack),
        AutoloadSettled.embedded,
      );
      expect(
        SubtitleAutoloadRules.settledBy(zhVariant),
        AutoloadSettled.downloaded,
      );
      expect(
        SubtitleAutoloadRules.settledBy(enFallback),
        AutoloadSettled.fallback,
      );
    });
  });

  test('资源站 sources keep their burned-in subtitles to themselves', () {
    expect(SubtitleAutoloadRules.sourceHasBurnedSubtitles('maccms'), isTrue);
    expect(SubtitleAutoloadRules.sourceHasBurnedSubtitles('vidzee'), isFalse);
    expect(SubtitleAutoloadRules.sourceHasBurnedSubtitles(null), isFalse);
  });
}
