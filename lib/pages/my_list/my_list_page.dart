import '../../l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../models/my_list/my_list_item.dart';
import '../../services/content/content_settings.dart';
import '../../services/layout/form_factor.dart';
import '../../services/my_list/my_list_service.dart';
import '../../utils/navigation/route_transitions.dart';
import '../details/details_page.dart';
import '../../models/movie/movie.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_confirm.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';

class MyListPage extends StatefulWidget {
  const MyListPage({super.key});

  @override
  State<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {
  String _filterType = 'all'; // 'all', 'movie', 'series'
  String _sortBy = 'recent'; // 'recent', 'title', 'year'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MyListItem> _getFilteredAndSortedItems(List<MyListItem> allItems) {
    var filtered = allItems.where((item) {
      // 1. Filter by media type
      if (_filterType == 'movie' && item.type != 'movie') return false;
      if (_filterType == 'series' &&
          item.type != 'series' &&
          item.type != 'anime') {
        return false;
      }

      // 2. Filter by search query
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final title = item.title.toLowerCase();
        if (!title.contains(query)) return false;
      }
      return true;
    }).toList();

    // 3. Sort items
    switch (_sortBy) {
      case 'recent':
        filtered.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case 'title':
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case 'year':
        filtered.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
        break;
    }
    return filtered;
  }

  /// The shared card's input, and the details page's, from one place.
  ///
  /// The card and the route have to agree about the title, the poster, the year
  /// and the id, or tapping a card opens a different record than the one the
  /// user just read - so both read this.
  Movie _movieFor(MyListItem item) {
    // A TMDb-only title opens as `tmdb:tv:123` / `tmdb:movie:123`, the form
    // the details page resolves; a bare `tmdb:123` names no kind and cannot be.
    final tmdbKind = item.type == 'movie' ? 'movie' : 'tv';
    final effectiveId =
        item.imdbId ??
        (item.tmdbId != null ? 'tmdb:$tmdbKind:${item.tmdbId}' : null) ??
        item.traktId?.toString() ??
        '';

    return Movie(
      id: effectiveId,
      name: item.title,
      poster: item.poster,
      year: item.year?.toString(),
      type: item.type,
      addonBaseUrl: 'https://v3-cinemeta.strem.io',
    );
  }

  void _navigateToDetail(MyListItem item) {
    Navigator.push(
      context,
      LiquidRevealRoute(
        page: DetailsPage(movie: _movieFor(item)),
        tapPosition: null,
      ),
    );
  }

  Future<void> _confirmRemove(MyListItem item) async {
    final l10n = l10nOf(context);
    final confirm = await showLuConfirm(
      context,
      title: l10n.listRemoveConfirm,
      message: item.title,
      confirmLabel: l10n.listRemove,
    );
    if (confirm && mounted) MyListService.remove(item);
  }

  double _pad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 16;
    return FormFactorService.of(context) == FormFactor.television
        ? 48
        : LuSpace.page;
  }

  @override
  Widget build(BuildContext context) {
    final pad = _pad(context);
    return Theme(
      data: luTheme(),
      child: Material(
        color: LuColors.bg,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            MyListService.items,
            ContentSettings.adultEnabled,
          ]),
          builder: (context, _) {
            final allItems = MyListService.visibleItems;
            final displayed = _getFilteredAndSortedItems(allItems);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildToolbar(context, pad, allItems.length),
                ),
                if (displayed.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(allItems.isEmpty),
                  )
                else
                  SliverToBoxAdapter(
                    child: _buildGrid(context, pad, displayed),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The saved titles as posters, as many to a row as the width takes. A
  /// card's second action (long press, right click, the menu key or a held
  /// Select) asks to remove it.
  Widget _buildGrid(BuildContext context, double pad, List<MyListItem> items) {
    final l10n = l10nOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth - pad * 2;
        final phone = MediaQuery.sizeOf(context).width < 600;
        final spacing = phone ? 12.0 : 20.0;
        final target = phone ? 110.0 : 160.0;
        final columns = ((width + spacing) / (target + spacing)).floor().clamp(
          2,
          10,
        );
        final cardWidth = (width - spacing * (columns - 1)) / columns;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            pad,
            12,
            pad,
            40 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Wrap(
            spacing: spacing,
            runSpacing: 24,
            children: [
              for (final item in items)
                LuPosterCard(
                  width: cardWidth,
                  title: item.title,
                  poster: item.poster,
                  subtitle: [
                    if (item.year != null) '${item.year}',
                    item.type == 'movie' ? l10n.typeMovies : l10n.typeSeries,
                  ].join(' · '),
                  onTap: () => _navigateToDetail(item),
                  onLongPress: () => _confirmRemove(item),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 全部 / 电影 / 剧集, the order, the count and sync state, and a search
  /// field for a long list.
  Widget _buildToolbar(BuildContext context, double pad, int total) {
    final l10n = l10nOf(context);
    final phone = MediaQuery.sizeOf(context).width < 600;
    final filters = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in [
          ('all', l10n.subAll),
          ('movie', l10n.typeMovies),
          ('series', l10n.typeSeries),
        ])
          _Chip(
            label: label,
            selected: _filterType == value,
            onTap: () => setState(() => _filterType = value),
          ),
        const SizedBox(width: 8, height: 36),
        for (final (value, label) in [
          ('recent', l10n.listSortRecent),
          ('title', l10n.listSortTitle),
          ('year', l10n.listSortYear),
        ])
          _Chip(
            label: label,
            selected: _sortBy == value,
            quiet: true,
            onTap: () => setState(() => _sortBy = value),
          ),
      ],
    );
    final status = ValueListenableBuilder<bool>(
      valueListenable: MyListService.isSyncing,
      builder: (context, syncing, _) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        children: [
          Text(
            l10n.listSummary(total),
            style: LuText.caption.copyWith(color: LuColors.textMuted),
          ),
          const SizedBox(width: 12),
          if (syncing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: LuColors.gold,
              ),
            )
          else
            const Icon(
              Icons.cloud_done_rounded,
              size: 15,
              color: LuColors.textFaint,
            ),
          const SizedBox(width: 6),
          Text(
            syncing ? l10n.listSyncing : l10n.listSynced,
            style: LuText.caption.copyWith(color: LuColors.textMuted),
          ),
        ],
      ),
    );
    final search = SizedBox(
      width: phone ? double.infinity : 280,
      height: 42,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: LuText.body.copyWith(fontSize: 15),
        cursorColor: LuColors.gold,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: LuColors.surface,
          hintText: l10n.listSearch,
          hintStyle: LuText.body.copyWith(
            fontSize: 15,
            color: LuColors.textFaint,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: LuColors.textMuted,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: LuColors.textMuted,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: const OutlineInputBorder(
            borderRadius: LuRadius.pill,
            borderSide: BorderSide(color: LuColors.lineSoft),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: LuRadius.pill,
            borderSide: BorderSide(color: LuColors.lineSoft),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: LuRadius.pill,
            borderSide: BorderSide(color: LuColors.gold),
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 12, pad, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          status,
          const SizedBox(height: 14),
          if (phone) ...[
            search,
            const SizedBox(height: 12),
            filters,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: filters),
                const SizedBox(width: 16),
                search,
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isListEmpty) {
    final l10n = l10nOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isListEmpty
                  ? Icons.bookmark_border_rounded
                  : Icons.search_off_rounded,
              size: 52,
              color: LuColors.textFaint,
            ),
            const SizedBox(height: 16),
            Text(
              isListEmpty ? l10n.listEmpty : l10n.listNoMatch,
              style: LuText.heading,
            ),
            const SizedBox(height: 8),
            Text(
              isListEmpty ? l10n.listEmptyBody : l10n.listNoMatchBody,
              textAlign: TextAlign.center,
              style: LuText.bodySoft.copyWith(fontSize: 15),
            ),
            if (!isListEmpty) ...[
              const SizedBox(height: 18),
              LuButton(
                label: l10n.listResetFilters,
                icon: Icons.filter_alt_off_rounded,
                kind: LuButtonKind.secondary,
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _filterType = 'all';
                    _searchQuery = '';
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A filter or order choice: gold when chosen.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.quiet = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// The order choices: text only until chosen.
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: LuFocusable(
        onTap: onTap,
        builder: (context, hi) => AnimatedContainer(
          duration: LuMotion.focus,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0x29F2B544)
                : (hi ? const Color(0x1AFFFFFF) : Colors.transparent),
            borderRadius: LuRadius.pill,
            border: selected || quiet ? null : Border.all(color: LuColors.line),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: LuText.body.copyWith(
                fontSize: 14,
                color: selected ? LuColors.gold : LuColors.textSoft,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
