/// Deciding whether a site's search result is the title that was asked for.
///
/// A source that searches by name and plays its first hit plays the wrong
/// show whenever two titles share a name - a remake, a sequel, the live-action
/// version of an animation - and nothing on screen says so. These checks are
/// shared so every scraper rejects a result for the same reasons, and a scraper
/// that finds no acceptable result returns nothing rather than a guess.
library;

/// Lower-case letters and digits only, with a trailing "(2020)" dropped, so
/// "A Mortal's Journey (2020)" and "a mortals journey" compare equal. Letters
/// of every script are kept: an ASCII-only filter turned "凡人修仙传" into an
/// empty string that matched nothing.
String normalizeTitle(String title) => title
    .toLowerCase()
    .replaceAll(RegExp(r'\(\d{4}\)'), '')
    .replaceAll("'", '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

const Set<String> _fillerWords = {'a', 'an', 'the', 'of', 'to', 'and'};

/// The significant words of [title], lower-cased.
Set<String> titleWords(String title) =>
    RegExp(r'[\p{L}\p{N}]+', unicode: true)
    .allMatches(
      title
          .toLowerCase()
          .replaceAll("'", '')
          .replaceAll(RegExp(r'\(\d{4}\)'), ''),
    )
    .map((m) => m.group(0)!)
    .where((w) => !_fillerWords.contains(w))
    .toSet();

/// How well [candidate] names [wanted]: 3 for the same title, 2 when every
/// significant word of [wanted] appears in [candidate], 0 otherwise.
///
/// A plain "contains" test is deliberately not used: it is what let "Bear"
/// match "The Bear and the Wild Thing" and a short title match any listing
/// that happens to include it.
int titleMatchScore(String wanted, String candidate) {
  final a = normalizeTitle(wanted);
  final b = normalizeTitle(candidate);
  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 3;
  final words = titleWords(wanted);
  if (words.isNotEmpty && titleWords(candidate).containsAll(words)) return 2;
  return 0;
}

/// Whether [candidate] is the same title as [wanted]: the names agree
/// ([titleMatchScore] > 0) and, when both years are known, they are at most
/// [tolerance] apart. An unknown year on either side does not reject.
bool isSameTitle(
  String wanted,
  String candidate, {
  int? wantedYear,
  int? candidateYear,
  int tolerance = 1,
}) {
  if (titleMatchScore(wanted, candidate) == 0) return false;
  if (wantedYear == null || candidateYear == null) return true;
  return (wantedYear - candidateYear).abs() <= tolerance;
}

/// The first four-digit year in [text], e.g. 2020 from "2020–" or
/// "2020-2024", or null when there is none.
int? leadingYear(String? text) {
  if (text == null) return null;
  final match = RegExp(r'(19|20)\d{2}').firstMatch(text);
  return match == null ? null : int.parse(match.group(0)!);
}
