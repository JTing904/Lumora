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

/// A Live TV section's name (one of IptvSettings.defaultCategories) in the
/// viewer's language. The stored keys stay the English names the user's order
/// and visibility are saved under; a name this app did not define (one a
/// remote playlist brought) is returned as it came.
String localizedLiveSection(String key) {
  final l10n = l10nCurrent();
  return switch (key) {
    'Premier Live Broadcasts' => l10n.liveCatPremier,
    'ESPN & College Basketball (NCAA)' => l10n.liveCatEspn,
    'US Major Leagues & Sports' => l10n.liveCatUsSports,
    'Global Football & Soccer' => l10n.liveCatSoccer,
    'Boxing' => l10n.liveCatBoxing,
    'Combat & Martial Arts' => l10n.liveCatCombat,
    'Motorsport & Racing' => l10n.liveCatRacing,
    'Movies & Premium Networks' => l10n.liveCatMovies,
    '24/7 Global News Networks' => l10n.liveCatNews,
    'Arabic & Regional Hub' => l10n.liveCatArabic,
    'Discovery & Documentaries' => l10n.liveCatDiscovery,
    'Kids & Family' => l10n.liveCatKids,
    'US Region' => l10n.liveCatUs,
    'UK Region' => l10n.liveCatUk,
    'Canada Region' => l10n.liveCatCanada,
    'Bay Area' => l10n.liveCatBayArea,
    'International Sports' => l10n.liveCatIntlSports,
    _ => key,
  };
}
