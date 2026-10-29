/// "Where to watch" (去哪看): the official services TMDb lists for a title in
/// one country, grouped the way a viewer decides - free, free with ads,
/// subscription, rent or buy - and the link each one opens.
///
/// The data is TMDb's `/movie/{id}/watch/providers` and
/// `/tv/{id}/watch/providers` (supplied to TMDb by JustWatch). Lumora only
/// shows it and hands the viewer to the service's own app or site; it never
/// plays anything from these services itself.
///
/// Pure Dart (no Flutter import) so the parser and the link rules can be
/// tested against recorded answers.
library;

/// How a service offers the title.
enum WatchOfferKind {
  /// Free, no account or ads needed (TMDb `free`).
  free,

  /// Free with ads (TMDb `ads`).
  ads,

  /// Included with a subscription (TMDb `flatrate`).
  subscription,

  /// Pay per title (TMDb `rent` and `buy`).
  rentBuy,
}

/// One service, as TMDb names it.
class WatchProvider {
  const WatchProvider({
    required this.id,
    required this.name,
    this.logoPath,
    this.displayPriority = 9999,
  });

  /// TMDb's provider id (8 is Netflix, 623 WeTV, 581 iQIYI ...).
  final int id;
  final String name;

  /// TMDb image path (`/rK1KljqmbvO9HQa1PBFLILWah72.png`), or null.
  final String? logoPath;

  /// TMDb's own order within a country; lower comes first.
  final int displayPriority;

  /// The logo at [size] (`w92`, `w154` ...), or null without one.
  String? logoUrl([String size = 'w92']) =>
      logoPath == null ? null : 'https://image.tmdb.org/t/p/$size$logoPath';

  @override
  bool operator ==(Object other) => other is WatchProvider && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The services for one title in one country.
class RegionWatchProviders {
  const RegionWatchProviders({
    required this.region,
    required this.groups,
    this.tmdbLink,
  });

  /// ISO 3166 country code the list is for (`MY`).
  final String region;

  /// TMDb's watch page for the title in [region], which links on to every
  /// service; the fallback for a service with no link rule of its own.
  final String? tmdbLink;

  /// Services by kind, in [WatchOfferKind] order, each list best first. A
  /// service appears once, under its cheapest kind.
  final Map<WatchOfferKind, List<WatchProvider>> groups;

  bool get isEmpty => groups.values.every((l) => l.isEmpty);

  /// Every service, cheapest kind first.
  Iterable<(WatchOfferKind, WatchProvider)> get offers sync* {
    for (final kind in WatchOfferKind.values) {
      for (final p in groups[kind] ?? const <WatchProvider>[]) {
        yield (kind, p);
      }
    }
  }
}

abstract final class WatchProvidersParser {
  /// TMDb's keys for each kind, cheapest first.
  static const Map<WatchOfferKind, List<String>> _keys = {
    WatchOfferKind.free: ['free'],
    WatchOfferKind.ads: ['ads'],
    WatchOfferKind.subscription: ['flatrate'],
    WatchOfferKind.rentBuy: ['rent', 'buy'],
  };

  /// At most this many services per kind; the rest are on TMDb's page.
  static const int maxPerKind = 8;

  /// The first of [regions] that has any service in [json] (a
  /// `watch/providers` answer); null when none does or [json] is not one.
  static RegionWatchProviders? parse(
    Object? json, {
    required List<String> regions,
  }) {
    if (json is! Map) return null;
    final results = json['results'];
    if (results is! Map) return null;
    final seen = <String>{};
    for (final raw in regions) {
      final region = raw.trim().toUpperCase();
      if (region.isEmpty || !seen.add(region)) continue;
      final entry = results[region];
      if (entry is! Map) continue;
      final parsed = _region(region, entry);
      if (!parsed.isEmpty) return parsed;
    }
    return null;
  }

  static RegionWatchProviders _region(String region, Map entry) {
    final taken = <int>{};
    final groups = <WatchOfferKind, List<WatchProvider>>{};
    for (final kind in WatchOfferKind.values) {
      final list = <WatchProvider>[];
      for (final key in _keys[kind]!) {
        final items = entry[key];
        if (items is! List) continue;
        for (final item in items) {
          final p = _provider(item);
          if (p == null || taken.contains(p.id)) continue;
          taken.add(p.id);
          list.add(p);
        }
      }
      list.sort((a, b) => a.displayPriority.compareTo(b.displayPriority));
      groups[kind] = list.take(maxPerKind).toList(growable: false);
    }
    final link = entry['link'];
    return RegionWatchProviders(
      region: region,
      tmdbLink: link is String && link.startsWith('https://') ? link : null,
      groups: groups,
    );
  }

  static WatchProvider? _provider(Object? item) {
    if (item is! Map) return null;
    final id = item['provider_id'];
    final name = item['provider_name'];
    if (id is! int || name is! String || name.trim().isEmpty) return null;
    final logo = item['logo_path'];
    final priority = item['display_priority'];
    return WatchProvider(
      id: id,
      name: name.trim(),
      logoPath: logo is String && logo.startsWith('/') ? logo : null,
      displayPriority: priority is int ? priority : 9999,
    );
  }
}

/// Where tapping a service goes.
class WatchLink {
  const WatchLink(this.uri, {required this.service});

  final Uri uri;

  /// Whether [uri] is the service's own app or site (true) or TMDb's watch
  /// page for the title (false).
  final bool service;
}

/// The link rules: a known service opens its own site at a search for the
/// title (an https App Link / Universal Link, which the phone hands to the
/// service's app when it is installed); anything else opens TMDb's watch
/// page, which links on to the service.
abstract final class WatchProviderLinks {
  /// Provider ids and lower-case name fragments, to a URL builder taking the
  /// encoded title.
  static final List<
    ({Set<int> ids, List<String> names, String Function(String q) url})
  >
  _rules = [
    (
      ids: {8, 1796, 175},
      names: ['netflix'],
      url: (q) => 'https://www.netflix.com/search?q=$q',
    ),
    (ids: {623}, names: ['wetv'], url: (q) => 'https://wetv.vip/en/search/$q'),
    (
      ids: {581},
      names: ['iqiyi', 'iq.com'],
      url: (q) => 'https://www.iq.com/search?query=$q',
    ),
    (
      ids: {158},
      names: ['viu'],
      // Viu's search answers outside its markets with a redirect; its home
      // page opens the app.
      url: (_) => 'https://www.viu.com/ott/my',
    ),
    (
      ids: {337, 122, 390},
      names: ['disney'],
      // Disney+ has no linkable search; the home page opens the app.
      url: (_) => 'https://www.disneyplus.com/',
    ),
    (
      ids: {9, 119, 2100, 613},
      names: ['prime video'],
      url: (q) => 'https://www.primevideo.com/search/?phrase=$q',
    ),
    (
      ids: {192, 188, 235},
      names: ['youtube'],
      url: (q) => 'https://www.youtube.com/results?search_query=$q',
    ),
    (
      ids: const <int>{},
      names: ['bilibili'],
      url: (q) => 'https://www.bilibili.tv/en/search-result?q=$q',
    ),
    (
      ids: {344},
      names: ['viki'],
      url: (q) => 'https://www.viki.com/search?q=$q',
    ),
    (
      ids: const <int>{},
      names: ['mewatch'],
      url: (q) => 'https://www.mewatch.sg/search?q=$q',
    ),
  ];

  /// The link for [provider] and a title called [title]; TMDb's page
  /// ([tmdbLink]) for a service without a rule. Null when there is neither.
  static WatchLink? forProvider(
    WatchProvider provider, {
    required String title,
    String? tmdbLink,
  }) {
    final name = provider.name.toLowerCase();
    // A store front that sells the title (Apple TV Store, Google Play ...) is
    // best reached through TMDb's page, which links the title itself.
    final store = name.contains('store');
    for (final rule in _rules) {
      final hit =
          rule.ids.contains(provider.id) || rule.names.any(name.contains);
      if (!hit || store) continue;
      final q = Uri.encodeComponent(title.trim());
      final uri = Uri.tryParse(rule.url(q));
      if (uri != null) return WatchLink(uri, service: true);
    }
    final fallback = tmdbLink == null ? null : Uri.tryParse(tmdbLink);
    return fallback == null ? null : WatchLink(fallback, service: false);
  }
}
