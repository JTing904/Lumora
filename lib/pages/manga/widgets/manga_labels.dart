import '../../../l10n/generated/app_localizations.dart';
import '../../../services/manga/manga_settings.dart';

/// The words the manga pages show for the source's genres and the reader's
/// settings, in the viewer's language. The settings enums carry English labels
/// for the settings store; these are what a viewer reads.

/// The genres the shelf offers as filters, in order. The source's own list
/// also has genres this app does not browse by; they are left out here.
const List<String> mangaBrowseGenres = [
  'All',
  'Action',
  'Adventure',
  'Comedy',
  'Drama',
  'Fantasy',
  'Historical',
  'Horror',
  'Isekai',
  'Martial Arts',
  'Mystery',
  'Psychological',
  'Romance',
  'School Life',
  'Sci-fi',
  'Seinen',
  'Shounen',
  'Slice of Life',
  'Sports',
  'Supernatural',
  'Tragedy',
];

String mangaGenreLabel(AppLocalizations l10n, String genre) => switch (genre) {
  'All' => l10n.mangaGenreAll,
  'Action' => l10n.mangaGenreAction,
  'Adventure' => l10n.mangaGenreAdventure,
  'Comedy' => l10n.mangaGenreComedy,
  'Drama' => l10n.mangaGenreDrama,
  'Fantasy' => l10n.mangaGenreFantasy,
  'Historical' => l10n.mangaGenreHistorical,
  'Horror' => l10n.mangaGenreHorror,
  'Isekai' => l10n.mangaGenreIsekai,
  'Martial Arts' => l10n.mangaGenreMartialArts,
  'Mystery' => l10n.mangaGenreMystery,
  'Psychological' => l10n.mangaGenrePsychological,
  'Romance' => l10n.mangaGenreRomance,
  'School Life' => l10n.mangaGenreSchoolLife,
  'Sci-fi' => l10n.mangaGenreSciFi,
  'Seinen' => l10n.mangaGenreSeinen,
  'Shounen' => l10n.mangaGenreShounen,
  'Slice of Life' => l10n.mangaGenreSliceOfLife,
  'Sports' => l10n.mangaGenreSports,
  'Supernatural' => l10n.mangaGenreSupernatural,
  'Tragedy' => l10n.mangaGenreTragedy,
  _ => genre,
};

/// 日漫 / 韩漫 / 国漫 for the source's type, or null for one it does not name.
String? mangaTypeLabel(AppLocalizations l10n, String type) =>
    switch (type.trim().toLowerCase()) {
      'manga' => l10n.mangaTypeManga,
      'manhwa' => l10n.mangaTypeManhwa,
      'manhua' => l10n.mangaTypeManhua,
      _ => null,
    };

String mangaReadingModeLabel(AppLocalizations l10n, MangaReadingMode m) =>
    switch (m) {
      MangaReadingMode.webtoon => l10n.mangaModeWebtoon,
      MangaReadingMode.horizontalLtr => l10n.mangaModeLtr,
      MangaReadingMode.horizontalRtl => l10n.mangaModeRtl,
    };

/// The short form a pill can hold.
String mangaReadingModeShort(AppLocalizations l10n, MangaReadingMode m) =>
    switch (m) {
      MangaReadingMode.webtoon => l10n.mgWebtoonScroll,
      MangaReadingMode.horizontalLtr => l10n.mgHorizontalLtr,
      MangaReadingMode.horizontalRtl => l10n.mgHorizontalRtl,
    };

String mangaMaxWidthLabel(AppLocalizations l10n, MangaReaderMaxWidth w) =>
    switch (w) {
      MangaReaderMaxWidth.full => l10n.mangaWidthFull,
      MangaReaderMaxWidth.compact => l10n.mangaWidthCompact,
      MangaReaderMaxWidth.standard => l10n.mangaWidthStandard,
      MangaReaderMaxWidth.wide => l10n.mangaWidthWide,
    };

String mangaBackgroundLabel(AppLocalizations l10n, MangaReaderBackground b) =>
    switch (b) {
      MangaReaderBackground.pitchBlack => l10n.mangaBgPitchBlack,
      MangaReaderBackground.deepCharcoal => l10n.mangaBgDeepCharcoal,
      MangaReaderBackground.darkSlate => l10n.mangaBgDarkSlate,
      MangaReaderBackground.sepiaDark => l10n.mangaBgSepiaDark,
    };

String mangaDensityLabel(AppLocalizations l10n, MangaCardDensity d) =>
    switch (d) {
      MangaCardDensity.compact => l10n.mangaDensityCompact,
      MangaCardDensity.standard => l10n.mangaDensityStandard,
      MangaCardDensity.spacious => l10n.mangaDensitySpacious,
    };

/// `Ch. 164` / 第164话 for a chapter number, or empty for none.
String mangaChapterShort(AppLocalizations l10n, num number) {
  if (number <= 0) return '';
  final value = number == number.roundToDouble()
      ? number.toInt().toString()
      : number.toString();
  return l10n.mangaChapterShort(value);
}

/// Whether a source tag is one this app shows: it never prints the source's
/// adult-content tags.
bool mangaTagShown(String tag) {
  const hidden = {'ecchi', 'mature', 'adult', 'smut', 'hentai', 'harem'};
  final t = tag.trim().toLowerCase();
  return t.isNotEmpty && !hidden.contains(t) && !t.contains('18');
}
