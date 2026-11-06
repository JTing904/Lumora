/// Which subtitle a video opens with.
///
/// Kept out of `player_screen.dart` for the same reason as
/// `player_playback_rules.dart`: the screen owns a `media_kit` `Player` and no
/// test can build it, so the decision is driven here. The screen asks again
/// whenever something new arrives (a batch of subtitles, the stream's own
/// tracks, the end of the search, a timer) and applies the answer.
library;

import '../../models/subtitle/subtitle_model.dart';
import '../../services/subtitles/subtitle_choice.dart';

/// What the screen should do with the subtitles it knows of so far.
sealed class SubtitleAutoload {
  const SubtitleAutoload();

  /// True when this is not the language the viewer asked for.
  bool get isFallback => false;
}

/// Nothing yet: more may still arrive.
final class AutoloadWait extends SubtitleAutoload {
  const AutoloadWait();
}

/// Nothing to load, now or later: subtitles are off, or the search is over
/// and found nothing.
final class AutoloadNone extends SubtitleAutoload {
  const AutoloadNone();
}

/// A track inside the stream.
final class AutoloadEmbedded extends SubtitleAutoload {
  const AutoloadEmbedded(this.track, {this.fallback = false});
  final PlayerEmbeddedSubtitle track;
  final bool fallback;

  @override
  bool get isFallback => fallback;
}

/// A downloaded subtitle.
final class AutoloadVariant extends SubtitleAutoload {
  const AutoloadVariant(this.variant, {this.fallback = false});
  final SubtitleVariant variant;
  final bool fallback;

  @override
  bool get isFallback => fallback;
}

/// How good what is on screen already is, as far as the automatic choice
/// goes. A better answer may replace a worse one; nothing replaces a track
/// from the stream itself.
enum AutoloadSettled {
  /// Nothing loaded by the automatic choice yet.
  nothing,

  /// The other language, taken because the wanted one was missing.
  fallback,

  /// A download in the wanted language.
  downloaded,

  /// A track from the stream in the wanted language.
  embedded,
}

abstract final class SubtitleAutoloadRules {
  /// How long to wait for the wanted language before taking the other one
  /// that is already here. Providers answer one after another, and a slow
  /// one can hold up the end of the search for a long time.
  static const Duration patience = Duration(seconds: 8);

  /// Whether a source usually has its subtitles burned into the picture, so
  /// that turning one on by default would lay a second line over them. The
  /// 中文资源站 (MacCMS sites) nearly always carry Chinese, often Chinese and
  /// English, in the image itself.
  static bool sourceHasBurnedSubtitles(String? providerId) =>
      providerId == 'maccms';

  /// The subtitle to open with, given what is known so far.
  ///
  /// A track inside the stream in the wanted language wins: it was cut for
  /// this video. Otherwise the first variant of that language, which is the
  /// best fit for the release (see `SubtitleChoice.rank`, applied before the
  /// groups get here). Chinese that does not exist falls back to English,
  /// but only once the search is over or [patience] has run out, so a
  /// provider that answers in English first does not beat Chinese a moment
  /// later.
  static SubtitleAutoload decide({
    required SubtitlePreference preference,
    required List<SubtitleLanguageGroup> groups,
    required List<PlayerEmbeddedSubtitle> embedded,
    required bool providersDone,
    required Duration elapsed,
  }) {
    final wanted = preference.language;
    if (wanted == null) return const AutoloadNone();

    final track = _embeddedIn(embedded, wanted);
    if (track != null) return AutoloadEmbedded(track);
    final variant = _variantIn(groups, wanted);
    if (variant != null) return AutoloadVariant(variant);

    final giveUpWaiting = providersDone || elapsed >= patience;
    if (wanted == SubtitleLanguage.chinese && giveUpWaiting) {
      const english = SubtitleLanguage.english;
      final englishTrack = _embeddedIn(embedded, english);
      if (englishTrack != null) {
        return AutoloadEmbedded(englishTrack, fallback: true);
      }
      final englishVariant = _variantIn(groups, english);
      if (englishVariant != null) {
        return AutoloadVariant(englishVariant, fallback: true);
      }
    }
    return providersDone ? const AutoloadNone() : const AutoloadWait();
  }

  /// Whether [decision] should replace what the automatic choice put on
  /// screen before, which is [settled].
  static bool shouldApply(AutoloadSettled settled, SubtitleAutoload decision) {
    if (decision is! AutoloadEmbedded && decision is! AutoloadVariant) {
      return false;
    }
    return switch (settled) {
      AutoloadSettled.nothing => true,
      // Something better than the other language turned up.
      AutoloadSettled.fallback => !decision.isFallback,
      // A download is in place; only the stream's own track beats it.
      AutoloadSettled.downloaded =>
        decision is AutoloadEmbedded && !decision.isFallback,
      AutoloadSettled.embedded => false,
    };
  }

  /// What [decision], once applied, leaves on screen.
  static AutoloadSettled settledBy(SubtitleAutoload decision) {
    if (decision.isFallback) return AutoloadSettled.fallback;
    return switch (decision) {
      AutoloadEmbedded() => AutoloadSettled.embedded,
      AutoloadVariant() => AutoloadSettled.downloaded,
      _ => AutoloadSettled.nothing,
    };
  }

  static PlayerEmbeddedSubtitle? _embeddedIn(
    List<PlayerEmbeddedSubtitle> embedded,
    SubtitleLanguage language,
  ) => embedded
      .where(
        (e) => SubtitleChoice.languageOf(e.language ?? e.title) == language,
      )
      .firstOrNull;

  static SubtitleVariant? _variantIn(
    List<SubtitleLanguageGroup> groups,
    SubtitleLanguage language,
  ) => groups
      .where((g) => g.language == language.label)
      .expand((g) => g.variants)
      .firstOrNull;
}
