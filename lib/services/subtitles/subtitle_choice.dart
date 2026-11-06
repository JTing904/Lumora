import '../../models/subtitle/subtitle_model.dart';

/// The two subtitle languages Lumora offers.
enum SubtitleLanguage {
  chinese('中文'),
  english('English');

  const SubtitleLanguage(this.label);

  /// How the language is named in the subtitle menu.
  final String label;
}

/// What the viewer wants on screen when a video opens, remembered across
/// videos: the last subtitle they picked by hand.
enum SubtitlePreference {
  off,
  chinese,
  english;

  /// The stored [name] as a preference. Anything unknown, including the
  /// `aiChinese` of a build that translated with an AI, is Chinese: the
  /// default, and what that choice was after.
  static SubtitlePreference fromName(String? name) =>
      values.firstWhere((p) => p.name == name, orElse: () => chinese);

  /// The preference a subtitle in [language] stands for, or null when the
  /// language is neither (a track that names none says nothing).
  static SubtitlePreference? forLanguage(SubtitleLanguage? language) =>
      switch (language) {
        SubtitleLanguage.chinese => chinese,
        SubtitleLanguage.english => english,
        null => null,
      };

  /// The language to look for, or null for [off].
  SubtitleLanguage? get language => switch (this) {
    off => null,
    chinese => SubtitleLanguage.chinese,
    english => SubtitleLanguage.english,
  };
}

/// Which subtitles to offer and which to pick first.
///
/// Providers answer in every language they have, under labels of their own
/// ("Chinese (Traditional)", "chi", "简体中文", "English", "eng"...). Only
/// Chinese and English are wanted: anything else is dropped, and the rest is
/// grouped under one label per language.
///
/// Within a language, a subtitle cut for the same release as the stream is
/// the one most likely to be in time with it: the same source (WEB, BluRay,
/// HDTV) and release group usually mean the same edit and frame rate. Those
/// rank first.
abstract final class SubtitleChoice {
  static final RegExp _split = RegExp(r'[^a-z0-9一-鿿]+');

  static const Set<String> _chineseCodes = {
    'zh', 'chi', 'zho', 'chs', 'cht', 'zhs', 'zht', 'cn', 'tw', 'hk', //
    'cmn', 'yue', 'cantonese', 'mandarin', 'chinese',
  };
  static const Set<String> _englishCodes = {'en', 'eng', 'english'};

  /// The language a provider's [label] names, or null for any other.
  /// A bilingual Chinese and English subtitle counts as Chinese.
  static SubtitleLanguage? languageOf(String label) {
    final lower = label.toLowerCase().trim();
    if (lower.isEmpty) return null;
    if (RegExp(r'[中简繁粤國国汉漢]').hasMatch(lower)) {
      return SubtitleLanguage.chinese;
    }
    final tokens = lower.split(_split).where((t) => t.isNotEmpty).toSet();
    if (tokens.any(_chineseCodes.contains) || lower.contains('chinese')) {
      return SubtitleLanguage.chinese;
    }
    if (tokens.any(_englishCodes.contains) || lower.contains('english')) {
      return SubtitleLanguage.english;
    }
    return null;
  }

  /// Whether a subtitle track inside the stream is offered: Chinese or
  /// English, or one that names no language at all, which may be either.
  static bool offersEmbedded(String? language, String? title) {
    final lang = language?.trim() ?? '';
    if (lang.isNotEmpty && lang.toLowerCase() != 'und') {
      return languageOf(lang) != null;
    }
    final named = title?.trim() ?? '';
    if (named.isEmpty) return true;
    return languageOf(named) != null || !_namesALanguage(named);
  }

  static final RegExp _otherLanguage = RegExp(
    r'\b(fr|fre|fra|french|fran[cç]ais|de|ger|deu|german|deutsch|es|spa|spanish|'
    r'espa[nñ]ol|it|ita|italian|pt|por|portuguese|ja|jpn|japanese|ko|kor|korean|'
    r'ru|rus|russian|ar|ara|arabic|th|tha|thai|vi|vie|vietnamese|id|ind|'
    r'indonesian|ms|may|malay|hi|hin|hindi|tr|tur|turkish|pl|pol|polish|nl|dut|'
    r'dutch)\b',
    caseSensitive: false,
  );

  static bool _namesALanguage(String title) => _otherLanguage.hasMatch(title);

  /// [variants] grouped as 中文 then English; other languages are dropped.
  static List<SubtitleLanguageGroup> group(Iterable<SubtitleVariant> variants) {
    final byLanguage = <SubtitleLanguage, List<SubtitleVariant>>{};
    for (final v in variants) {
      final language = languageOf(v.language);
      if (language == null) continue;
      final list = byLanguage.putIfAbsent(language, () => []);
      if (!list.any((e) => e.downloadUrl == v.downloadUrl)) list.add(v);
    }
    return [
      for (final language in SubtitleLanguage.values)
        if (byLanguage[language] case final list?)
          SubtitleLanguageGroup(language: language.label, variants: list),
    ];
  }

  static const Set<String> _sources = {
    'web', 'webdl', 'webrip', 'bluray', 'bdrip', 'brrip', 'hdtv', 'dvdrip', //
    'remux', 'amzn', 'nf', 'dsnp', 'hmax', 'atvp', 'hulu', 'iqiyi', 'wetv',
  };
  static const Set<String> _resolutions = {'2160p', '1080p', '720p', '480p'};

  /// How closely a subtitle named [subtitleName] fits the stream described
  /// by [sourceText]: higher is closer, 0 is nothing in common.
  static int versionScore(String subtitleName, String sourceText) {
    final sub = _tokens(subtitleName);
    final src = _tokens(sourceText);
    if (sub.isEmpty || src.isEmpty) return 0;
    var score = 0;
    for (final t in sub.intersection(src)) {
      if (_sources.contains(t)) {
        score += 4;
      } else if (_resolutions.contains(t)) {
        score += 1;
      } else if (t.length >= 3 && !RegExp(r'^\d+$').hasMatch(t)) {
        // A release group, an edition word, a title word: weaker on its own.
        score += 2;
      }
    }
    final group = _releaseGroup(subtitleName);
    if (group != null && group == _releaseGroup(sourceText)) score += 6;
    return score;
  }

  /// [variants] with the best fit for [sourceText] first; ties keep their
  /// order. Machine translations go last whatever their fit: one cut for
  /// the right release still reads worse than a person's subtitle, and as
  /// the default it was the first thing a viewer saw.
  static List<SubtitleVariant> rank(
    List<SubtitleVariant> variants,
    String sourceText,
  ) {
    final scored = [
      for (var i = 0; i < variants.length; i++)
        (
          i,
          versionScore(variants[i].title, sourceText),
          variants[i],
          isMachineTranslated(variants[i].title),
        ),
    ];
    scored.sort((a, b) {
      if (a.$4 != b.$4) return a.$4 ? 1 : -1;
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
    });
    return [for (final s in scored) s.$3];
  }

  /// A subtitle a machine translated ("... (Auto Translated)", SubtitleCat's
  /// label for its own translations).
  static bool isMachineTranslated(String title) => RegExp(
    r'auto[\s-]*translated|machine[\s-]*translat|机翻|機翻',
    caseSensitive: false,
  ).hasMatch(title);

  static Set<String> _tokens(String text) {
    final lower = text.toLowerCase().replaceAll('web-dl', 'webdl');
    return lower.split(_split).where((t) => t.isNotEmpty).toSet();
  }

  /// The group after the last `-` of a scene-style name ("...WEB-DL-NTb"),
  /// lower-cased; null when there is none.
  static String? _releaseGroup(String text) {
    final m = RegExp(
      r'-([A-Za-z0-9]{2,12})(?:\.[A-Za-z0-9]{2,4})?\s*$',
    ).firstMatch(text.trim());
    final group = m?.group(1)?.toLowerCase();
    if (group == null || group == 'dl' || _resolutions.contains(group)) {
      return null;
    }
    return group;
  }
}
