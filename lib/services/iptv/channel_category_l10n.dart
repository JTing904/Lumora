import '../../l10n/l10n.dart';

/// A built-in channel's category in the viewer's language. The stored value
/// stays the English key the channel list and the settings are written in.
String localizedChannelCategory(String category) {
  final l10n = l10nCurrent();
  return switch (category) {
    'Sports' => l10n.liveCatSports,
    'Soccer' => l10n.liveCatSoccerShort,
    'Boxing' => l10n.liveCatBoxing,
    'Combat' => l10n.liveCatCombat,
    'Racing' => l10n.liveCatRacing,
    'Movies' => l10n.liveCatMoviesShort,
    'News' => l10n.liveCatNewsShort,
    'Arabic' => l10n.liveCatArabic,
    'Discovery' => l10n.liveCatDiscovery,
    'Kids' => l10n.liveCatKids,
    'US' => l10n.liveCatUs,
    'UK' => l10n.liveCatUk,
    'CA' => l10n.liveCatCanada,
    'Bay Area' => l10n.liveCatBayArea,
    'Int. Sports' => l10n.liveCatIntlSports,
    _ => category,
  };
}
