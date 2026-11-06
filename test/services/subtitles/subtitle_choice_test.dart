import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/subtitle/subtitle_model.dart';
import 'package:zplay/services/subtitles/subtitle_choice.dart';

SubtitleVariant _v(String language, String title, [String url = '']) =>
    SubtitleVariant(
      providerName: 'test',
      language: language,
      title: title,
      downloadUrl: url.isEmpty ? '$language/$title' : url,
      format: 'srt',
    );

void main() {
  group('languageOf', () {
    test('reads the labels providers use for Chinese', () {
      for (final label in [
        'Chinese',
        'Chinese (Traditional)',
        'chi',
        'zho',
        'ZH',
        'zh-TW',
        '简体中文',
        '繁體中文',
        '粤语',
        'Chinese BG code',
      ]) {
        expect(
          SubtitleChoice.languageOf(label),
          SubtitleLanguage.chinese,
          reason: label,
        );
      }
    });

    test('reads English', () {
      for (final label in ['English', 'eng', 'EN', 'en-US']) {
        expect(
          SubtitleChoice.languageOf(label),
          SubtitleLanguage.english,
          reason: label,
        );
      }
    });

    test('a bilingual subtitle counts as Chinese', () {
      expect(
        SubtitleChoice.languageOf('Chinese & English'),
        SubtitleLanguage.chinese,
      );
    });

    test('every other language is left out', () {
      for (final label in [
        'French',
        'spa',
        'Japanese',
        'Portuguese (BR)',
        '',
      ]) {
        expect(SubtitleChoice.languageOf(label), isNull, reason: label);
      }
    });
  });

  test('tracks inside the stream: Chinese, English and unnamed ones stay', () {
    expect(SubtitleChoice.offersEmbedded('chi', 'Chinese'), isTrue);
    expect(SubtitleChoice.offersEmbedded('eng', null), isTrue);
    expect(SubtitleChoice.offersEmbedded(null, 'Track 1'), isTrue);
    expect(SubtitleChoice.offersEmbedded('und', null), isTrue);
    expect(SubtitleChoice.offersEmbedded('fre', 'Français'), isFalse);
    expect(SubtitleChoice.offersEmbedded(null, 'Japanese'), isFalse);
  });

  test('groups 中文 first, then English, and drops the rest', () {
    final groups = SubtitleChoice.group([
      _v('French', 'a'),
      _v('English', 'b'),
      _v('chi', 'c'),
      _v('Chinese (Traditional)', 'd'),
      _v('eng', 'e'),
    ]);
    expect(groups.map((g) => g.language), ['中文', 'English']);
    expect(groups.first.variants.map((v) => v.title), ['c', 'd']);
    expect(groups.last.variants.map((v) => v.title), ['b', 'e']);
  });

  test('the same file offered twice is listed once', () {
    final groups = SubtitleChoice.group([
      _v('English', 'a', 'https://x/1.srt'),
      _v('eng', 'a again', 'https://x/1.srt'),
    ]);
    expect(groups.single.variants, hasLength(1));
  });

  group('rank', () {
    const source = 'Renegade.Immortal.S01E01.1080p.WEB-DL.H264-NTb';

    test('the subtitle cut for the same release comes first', () {
      final ranked = SubtitleChoice.rank([
        _v('chi', 'Renegade.Immortal.S01E01.720p.HDTV.x264-LOL'),
        _v('chi', 'Renegade.Immortal.S01E01.1080p.WEB-DL.H264-NTb'),
        _v('chi', 'Renegade Immortal 01'),
      ], source);
      expect(ranked.first.title, contains('WEB-DL.H264-NTb'));
    });

    test('a matching source outranks a matching resolution alone', () {
      final ranked = SubtitleChoice.rank([
        _v('chi', 'Renegade.Immortal.E01.1080p.HDTV'),
        _v('chi', 'Renegade.Immortal.E01.720p.WEBRip'),
      ], 'Renegade Immortal E01 1080p WEBRip');
      expect(ranked.first.title, contains('WEBRip'));
    });

    test('with nothing to go on, the order is kept', () {
      final ranked = SubtitleChoice.rank([
        _v('chi', 'one'),
        _v('chi', 'two'),
      ], '');
      expect(ranked.map((v) => v.title), ['one', 'two']);
    });

    test('a machine translation goes last even when it fits best', () {
      final ranked = SubtitleChoice.rank([
        _v(
          'chi',
          'Hocus.Pocus.1993.720p.BrRip.x264.YIFY - Chinese (Auto Translated)',
        ),
        _v('chi', 'Hocus Pocus 1993 - Chinese (S)'),
      ], 'Hocus.Pocus.1993.720p.BrRip.x264.YIFY');
      expect(ranked.first.title, 'Hocus Pocus 1993 - Chinese (S)');
    });
  });
}
