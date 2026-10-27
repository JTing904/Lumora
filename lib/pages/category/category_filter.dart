import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../models/movie/movie.dart';
import '../../services/content/adult_guard.dart';
import '../../services/metadata/tmdb_catalog.dart';
import '../../services/playback/play_launcher.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';
import 'category_page.dart' show CategoryKind;

/// One choice in a filter row: its label and what it puts on the query.
class FilterOption {
  const FilterOption(this.label, [this.value]);

  final String Function(AppLocalizations l10n) label;

  /// Null for 全部.
  final String? value;
}

/// How the results are ordered.
enum FilterSort { popular, newest, rating }

/// What the viewer has picked on a category page's 筛选 panel.
@immutable
class CategoryFilter {
  const CategoryFilter({
    this.region,
    this.genre,
    this.years,
    this.sort = FilterSort.popular,
  });

  /// TMDb origin country, `CN` or `US|GB|FR`.
  final String? region;

  /// TMDb genre id.
  final String? genre;

  /// `2025`, or a span `2010-2019`, or `-1999` for 更早.
  final String? years;
  final FilterSort sort;

  bool get isDefault =>
      region == null &&
      genre == null &&
      years == null &&
      sort == FilterSort.popular;

  CategoryFilter copyWith({
    String? Function()? region,
    String? Function()? genre,
    String? Function()? years,
    FilterSort? sort,
  }) => CategoryFilter(
    region: region != null ? region() : this.region,
    genre: genre != null ? genre() : this.genre,
    years: years != null ? years() : this.years,
    sort: sort ?? this.sort,
  );

  /// The TMDb list for this choice on a page of [kind], at result [page].
  TmdbQuery query(CategoryKind kind, {int page = 1, DateTime? now}) {
    final series = kind != CategoryKind.movies;
    final dateField = series ? 'first_air_date' : 'primary_release_date';
    final today = (now ?? DateTime.now()).toIso8601String().substring(0, 10);
    final (from, to) = _span(years);
    final genres = [
      if (kind == CategoryKind.anime) '16',
      if (genre != null) genre!,
    ];
    return TmdbQuery('/discover/${series ? 'tv' : 'movie'}', {
      'include_adult': 'false',
      'sort_by': switch (sort) {
        FilterSort.popular => 'popularity.desc',
        FilterSort.newest => '$dateField.desc',
        FilterSort.rating => 'vote_average.desc',
      },
      'vote_count.gte': switch (sort) {
        FilterSort.rating => '100',
        // A brand-new title has few votes, and "最新" is for exactly those.
        FilterSort.newest => '1',
        FilterSort.popular => '10',
      },
      // 动漫 means Chinese, Japanese and Korean animation unless a region is
      // chosen: the world's most popular animated series are US sitcoms.
      if ((region ?? (kind == CategoryKind.anime ? 'CN|JP|KR' : null))
          case final r?)
        'with_origin_country': r,
      if (genres.isNotEmpty) 'with_genres': genres.join(','),
      // 电视剧 and 电影 are live action; animation has its own page. 电视剧
      // is drama too: variety and talk shows only when 综艺 is picked.
      if (kind == CategoryKind.series && genre != '10764')
        'without_genres': '16,10764,10767'
      else if (kind == CategoryKind.movies)
        'without_genres': '16',
      if (from != null) '$dateField.gte': '$from-01-01',
      // Nothing announced for next year under 最新.
      '$dateField.lte': to != null ? '$to-12-31' : today,
      'page': '$page',
    });
  }

  static (int?, int?) _span(String? years) {
    if (years == null) return (null, null);
    final parts = years.split('-');
    if (parts.length == 1) {
      final y = int.tryParse(parts.first);
      return (y, y);
    }
    return (int.tryParse(parts[0]), int.tryParse(parts[1]));
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryFilter &&
      other.region == region &&
      other.genre == genre &&
      other.years == years &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(region, genre, years, sort);
}

/// The rows of choices a page of [kind] offers.
({
  List<FilterOption> regions,
  List<FilterOption> genres,
  List<FilterOption> years,
})
filterOptionsFor(CategoryKind kind) {
  final all = FilterOption((l) => l.filterAll);
  final regions = switch (kind) {
    CategoryKind.anime => [
      all,
      FilterOption((l) => l.filterRegionCn, 'CN'),
      FilterOption((l) => l.filterRegionJp, 'JP'),
      FilterOption((l) => l.filterRegionKr, 'KR'),
      FilterOption((l) => l.filterRegionWest, 'US|GB|FR|CA'),
    ],
    _ => [
      all,
      FilterOption((l) => l.filterRegionCn, 'CN'),
      FilterOption((l) => l.filterRegionHk, 'HK'),
      FilterOption((l) => l.filterRegionTw, 'TW'),
      FilterOption((l) => l.filterRegionKr, 'KR'),
      FilterOption((l) => l.filterRegionJp, 'JP'),
      FilterOption((l) => l.filterRegionUs, 'US'),
      FilterOption((l) => l.filterRegionGb, 'GB'),
      FilterOption((l) => l.filterRegionTh, 'TH'),
      FilterOption((l) => l.filterRegionIn, 'IN'),
    ],
  };
  // TMDb keeps separate genre lists for films and series.
  final genres = switch (kind) {
    CategoryKind.movies => [
      all,
      FilterOption((l) => l.filterGenreAction, '28'),
      FilterOption((l) => l.filterGenreComedy, '35'),
      FilterOption((l) => l.filterGenreDrama, '18'),
      FilterOption((l) => l.filterGenreRomance, '10749'),
      FilterOption((l) => l.filterGenreSciFi, '878'),
      FilterOption((l) => l.filterGenreFantasy, '14'),
      FilterOption((l) => l.filterGenreHorror, '27'),
      FilterOption((l) => l.filterGenreThriller, '53'),
      FilterOption((l) => l.filterGenreCrime, '80'),
      FilterOption((l) => l.filterGenreMystery, '9648'),
      FilterOption((l) => l.filterGenreAdventure, '12'),
      FilterOption((l) => l.filterGenreWar, '10752'),
      FilterOption((l) => l.filterGenreFamily, '10751'),
      FilterOption((l) => l.filterGenreDocumentary, '99'),
    ],
    CategoryKind.series => [
      all,
      FilterOption((l) => l.filterGenreDrama, '18'),
      FilterOption((l) => l.filterGenreComedy, '35'),
      FilterOption((l) => l.filterGenreCrime, '80'),
      FilterOption((l) => l.filterGenreMystery, '9648'),
      FilterOption((l) => l.filterGenreActionAdventure, '10759'),
      FilterOption((l) => l.filterGenreSciFiFantasy, '10765'),
      FilterOption((l) => l.filterGenreFamily, '10751'),
      FilterOption((l) => l.filterGenreWarPolitics, '10768'),
      FilterOption((l) => l.filterGenreReality, '10764'),
      FilterOption((l) => l.filterGenreDocumentary, '99'),
    ],
    CategoryKind.anime => [
      all,
      FilterOption((l) => l.filterGenreActionAdventure, '10759'),
      FilterOption((l) => l.filterGenreSciFiFantasy, '10765'),
      FilterOption((l) => l.filterGenreComedy, '35'),
      FilterOption((l) => l.filterGenreDrama, '18'),
      FilterOption((l) => l.filterGenreMystery, '9648'),
      FilterOption((l) => l.filterGenreFamily, '10751'),
      FilterOption((l) => l.filterGenreKids, '10762'),
    ],
  };
  final thisYear = DateTime.now().year;
  final years = [
    all,
    for (var y = thisYear; y > thisYear - 5; y--)
      FilterOption((_) => '$y', '$y'),
    FilterOption((l) => l.filterYears2020s, '2020-${thisYear - 5}'),
    FilterOption((l) => l.filterYears2010s, '2010-2019'),
    FilterOption((l) => l.filterYears2000s, '2000-2009'),
    FilterOption((l) => l.filterYearsOlder, '1900-1999'),
  ];
  return (regions: regions, genres: genres, years: years);
}

/// The 筛选 panel: a row of choices each for 地区, 类型, 年份 and 排序.
class CategoryFilterPanel extends StatelessWidget {
  const CategoryFilterPanel({
    super.key,
    required this.kind,
    required this.filter,
    required this.onChanged,
  });

  final CategoryKind kind;
  final CategoryFilter filter;
  final ValueChanged<CategoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final options = filterOptionsFor(kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterRow(
          label: l10n.filterRegion,
          options: options.regions,
          selected: filter.region,
          onSelected: (v) => onChanged(filter.copyWith(region: () => v)),
        ),
        _FilterRow(
          label: l10n.filterGenre,
          options: options.genres,
          selected: filter.genre,
          onSelected: (v) => onChanged(filter.copyWith(genre: () => v)),
        ),
        _FilterRow(
          label: l10n.filterYear,
          options: options.years,
          selected: filter.years,
          onSelected: (v) => onChanged(filter.copyWith(years: () => v)),
        ),
        _FilterRow(
          label: l10n.filterSort,
          options: [
            FilterOption((l) => l.filterSortPopular, FilterSort.popular.name),
            FilterOption((l) => l.filterSortNewest, FilterSort.newest.name),
            FilterOption((l) => l.filterSortRating, FilterSort.rating.name),
          ],
          selected: filter.sort.name,
          onSelected: (v) => onChanged(
            filter.copyWith(
              sort: FilterSort.values.firstWhere(
                (s) => s.name == v,
                orElse: () => FilterSort.popular,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<FilterOption> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: LuText.caption.copyWith(color: LuColors.textFaint),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) => _FilterChip(
                label: options[i].label(l10n),
                selected: options[i].value == selected,
                onTap: () => onSelected(options[i].value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: LuFocusable(
        onTap: onTap,
        builder: (context, hi) => AnimatedContainer(
          duration: LuMotion.focus,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: LuRadius.pill,
            color: selected
                ? const Color(0x29F2B544)
                : (hi ? const Color(0x1AFFFFFF) : Colors.transparent),
          ),
          child: Text(
            label,
            style: LuText.body.copyWith(
              fontSize: 15,
              color: selected ? LuColors.gold : LuColors.textSoft,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// The titles matching a filter, as a poster grid that loads more at its end.
class CategoryFilterResults extends StatefulWidget {
  const CategoryFilterResults({
    super.key,
    required this.kind,
    required this.filter,
    this.padding = LuSpace.page,
  });

  final CategoryKind kind;
  final CategoryFilter filter;
  final double padding;

  @override
  State<CategoryFilterResults> createState() => _CategoryFilterResultsState();
}

class _CategoryFilterResultsState extends State<CategoryFilterResults> {
  final List<Movie> _movies = [];
  int _page = 0;
  bool _loading = false;
  bool _done = false;

  /// Bumped on every new filter, so a page that lands for an old one is
  /// dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _more();
  }

  @override
  void didUpdateWidget(CategoryFilterResults old) {
    super.didUpdateWidget(old);
    if (old.filter != widget.filter || old.kind != widget.kind) {
      _generation++;
      _movies.clear();
      _page = 0;
      _done = false;
      _loading = false;
      _more();
    }
  }

  Future<void> _more() async {
    if (_loading || _done) return;
    final generation = _generation;
    setState(() => _loading = true);
    final next = _page + 1;
    final movies = await TmdbCatalog.row(
      widget.filter.query(widget.kind, page: next),
      resolveImdb: false,
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = false;
      _page = next;
      final seen = _movies.map((m) => m.id).toSet();
      final fresh = AdultGuard.filter(
        movies.where((m) => seen.add(m.id)).toList(),
      );
      _movies.addAll(fresh);
      // TMDb pages are 20; a short or repeated page is the end.
      if (movies.length < 10 || next >= 10) _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final phone = MediaQuery.sizeOf(context).width < 600;
    final cardWidth = phone ? 108.0 : 160.0;
    if (_movies.isEmpty && _loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: LuColors.gold)),
      );
    }
    if (_movies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Text(l10n.filterNoResults, style: LuText.bodySoft),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: phone ? 12 : 20,
            runSpacing: 22,
            children: [
              for (final movie in _movies)
                LuPosterCard(
                  width: cardWidth,
                  title: movie.name,
                  poster: movie.poster,
                  subtitle: movie.year,
                  rating: movie.imdbRating,
                  onTap: () => PlayLauncher.openDetails(context, movie),
                ),
            ],
          ),
          if (!_done)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: _loading
                    ? const SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: LuColors.gold,
                        ),
                      )
                    : LuButton(
                        label: l10n.filterLoadMore,
                        kind: LuButtonKind.secondary,
                        onPressed: _more,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
