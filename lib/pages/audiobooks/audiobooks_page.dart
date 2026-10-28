import '../../l10n/l10n.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/audiobook/audiobook_model.dart';
import '../../services/layout/form_factor.dart';
import '../../services/audiobook/audiobook_progress_service.dart';
import '../../services/audiobook/audiobook_scraper_service.dart';
import '../../services/audiobook/audiobook_settings.dart';
import '../../services/audiobook/paper2audio_service.dart';
import '../../services/audiobook/custom_audiobook_service.dart';
import '../../services/config/service_credentials.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_confirm.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';
import '../../widgets/common/error_view.dart';
import '../music/lu_media_kit.dart';
import '../settings/appearance/audiobook_settings_page.dart';
import 'audiobook_detail_page.dart';
import 'audiobook_lu_labels.dart';
import 'audiobook_player_screen.dart';
import 'audiobook_route_transitions.dart';
import 'generate_audiobook_screen.dart';

/// Audiobooks, in Lumora's cinema look: the book in progress as the hero,
/// rails of square covers, gold for what each screen is for.
class AudiobooksPage extends StatelessWidget {
  const AudiobooksPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Theme(data: luMediaTheme(), child: const _AudiobooksBody());
}

class _AudiobooksBody extends StatefulWidget {
  const _AudiobooksBody();

  @override
  State<_AudiobooksBody> createState() => _AudiobooksPageState();
}

class _AudiobooksPageState extends State<_AudiobooksBody> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearching = false;
  List<Audiobook> _searchResults = [];
  List<AudiobookProgress> _continueListeningList = [];
  String? _errorMessage;
  int _searchSequence = 0;
  String _selectedCategory = 'All';

  /// The genres, by the query each one searches for. The query stays English
  /// (the sources are); the pill shows the viewer's language.
  static const List<String> _categories = [
    'All',
    'Fantasy',
    'Sci-Fi',
    'Mystery',
    'Thriller',
    'Non-Fiction',
    'Self-Help',
    'Horror',
    'Romance',
    'Adventure',
    'Classics',
  ];

  /// The credentials the online catalogue searches with. Neither is one a
  /// user can obtain, and a release build ships neither.
  static const List<ServiceCredential> _catalogueCredentials = [
    ServiceCredential.audiobookSearch,
    ServiceCredential.audiobookService,
  ];

  /// Whether the online catalogue can return anything. Without its
  /// credential the search comes back empty for every query, so the page
  /// explains that instead of showing a search that promises results.
  static bool get _catalogueAvailable =>
      _catalogueCredentials.any(ServiceCredentials.isConfigured);

  String _categoryLabel(String c) {
    final l = l10nOf(context);
    return switch (c) {
      'Fantasy' => l.abkCatFantasy,
      'Sci-Fi' => l.abkCatSciFi,
      'Mystery' => l.abkCatMystery,
      'Thriller' => l.abkCatThriller,
      'Non-Fiction' => l.abkCatNonFiction,
      'Self-Help' => l.abkCatSelfHelp,
      'Horror' => l.abkCatHorror,
      'Romance' => l.abkCatRomance,
      'Adventure' => l.abkCatAdventure,
      'Classics' => l.abkCatClassics,
      _ => l.filterAll,
    };
  }

  @override
  void initState() {
    super.initState();
    AudiobookSettings.changeNotifier.addListener(_onSettingsChanged);
    Paper2AudioService.instance.jobs.addListener(_onSettingsChanged);
    CustomAudiobookService.instance.audiobooks.addListener(_onSettingsChanged);
    for (final credential in _catalogueCredentials) {
      ServiceCredentials.notifier(credential).addListener(_onCredentialChanged);
    }

    Paper2AudioService.instance.getJobs();
    CustomAudiobookService.instance.ensureLoaded();

    _loadContinueListening();
    if (_catalogueAvailable) _performSearch('Harry Potter');
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// A credential supplied while the page is open brings the catalogue up.
  void _onCredentialChanged() {
    if (!mounted) return;
    setState(() {});
    if (_catalogueAvailable && _searchResults.isEmpty && !_isSearching) {
      _performSearch('Harry Potter');
    }
  }

  @override
  void dispose() {
    AudiobookSettings.changeNotifier.removeListener(_onSettingsChanged);
    Paper2AudioService.instance.jobs.removeListener(_onSettingsChanged);
    CustomAudiobookService.instance.audiobooks.removeListener(
      _onSettingsChanged,
    );
    for (final credential in _catalogueCredentials) {
      ServiceCredentials.notifier(
        credential,
      ).removeListener(_onCredentialChanged);
    }
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadContinueListening() async {
    final list = await AudiobookProgressService.instance.getAllProgress();
    if (!mounted) return;
    setState(() {
      _continueListeningList = list;
    });
  }

  Timer? _searchDebounce;

  void _onSearchChanged(String query) {
    setState(() {});
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted && query.trim().isNotEmpty) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchDebounce?.cancel();

    final currentSequence = ++_searchSequence;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await AudiobookScraperService.instance.search(trimmed);
      if (mounted && currentSequence == _searchSequence) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && currentSequence == _searchSequence) {
        setState(() {
          _isSearching = false;
          _errorMessage = l10nCurrent().abk2FailedToFetchAudiobooks(e);
        });
      }
    }
  }

  void _selectCategory(String cat) {
    setState(() => _selectedCategory = cat);
    if (cat == 'All') {
      _performSearch('Harry Potter');
    } else {
      _searchController.text = cat;
      _performSearch(cat);
    }
  }

  Future<void> _openStudio() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GenerateAudiobookScreen()),
    );
    _loadContinueListening();
  }

  void _showAudiobookCustomizer() {
    showLuMediaDialog<void>(
      context: context,
      title: l10nCurrent().abkCustomizeAudiobookSection,
      icon: Icons.tune_rounded,
      body: (ctx, _) {
        final l10n = l10nOf(ctx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.abkPosterCardDensity, style: LuText.label),
            const SizedBox(height: LuSpace.s),
            ValueListenableBuilder<AudiobookCardDensity>(
              valueListenable: AudiobookSettings.cardDensity,
              builder: (context, density, _) =>
                  LuPillTabs<AudiobookCardDensity>(
                    semanticsLabel: l10n.abkAudiobookPosterCardDensity,
                    selected: density,
                    compact: true,
                    onSelected: AudiobookSettings.setCardDensity,
                    options: [
                      for (final option in AudiobookCardDensity.values)
                        LuPillOption(
                          value: option,
                          label: abkDensityLabel(l10n, option),
                        ),
                    ],
                  ),
            ),
            const SizedBox(height: LuSpace.l),
            ValueListenableBuilder<bool>(
              valueListenable: AudiobookSettings.enableSpotlight,
              builder: (context, enabled, _) => LuMediaSwitchRow(
                label: l10n.abkFeaturedHeroSpotlightCarousel,
                value: enabled,
                onChanged: AudiobookSettings.setEnableSpotlight,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: AudiobookSettings.enableAmbientLights,
              builder: (context, enabled, _) => LuMediaSwitchRow(
                label: l10n.abkMovingAmbientBackgroundGlow,
                value: enabled,
                onChanged: AudiobookSettings.setEnableAmbientLights,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: AudiobookSettings.showContinueListening,
              builder: (context, show, _) => LuMediaSwitchRow(
                label: l10n.abkShowContinueListeningCarousel,
                value: show,
                onChanged: AudiobookSettings.setShowContinueListening,
              ),
            ),
            const SizedBox(height: LuSpace.l),
            LuButton(
              kind: LuButtonKind.secondary,
              label: l10n.abkOpenPlayerStudioThemes,
              icon: Icons.palette_outlined,
              expand: true,
              compact: true,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AudiobookSettingsPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 600;
    final pad = luMediaPad(context);
    final ambientEnabled = AudiobookSettings.enableAmbientLights.value;
    final showSpotlight = AudiobookSettings.enableSpotlight.value;
    final showContinue = AudiobookSettings.showContinueListening.value;
    final showCategoryPills = AudiobookSettings.showCategoryPills.value;
    final cardDensity = AudiobookSettings.cardDensity.value;
    final catalogue = _catalogueAvailable;

    final spotlightBook = _searchResults.isNotEmpty
        ? _searchResults.first
        : null;

    // The banner shows the audiobook in progress when there is one, else the
    // featured spotlight; with neither it is not drawn.
    final resumeEntry = showContinue && _continueListeningList.isNotEmpty
        ? _continueListeningList.first
        : null;
    final bannerBook =
        resumeEntry?.audiobook ?? (showSpotlight ? spotlightBook : null);

    final cover = (isMobile ? 140.0 : 170.0) * cardDensity.scale;

    return Scaffold(
      backgroundColor: LuColors.bg,
      body: Stack(
        children: [
          if (ambientEnabled) const Positioned.fill(child: LuMediaGlow()),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Title and the two page actions.
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, topInset + 20, pad, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.abkAudiobookHub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LuText.title.copyWith(
                                fontSize: isMobile ? 26 : 34,
                              ),
                            ),
                            Text(
                              catalogue
                                  ? l10n.abkExploreStreamListenToThousandsOf
                                  : l10n.abkHubSubtitleOwnLibrary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LuText.caption,
                            ),
                          ],
                        ),
                      ),
                      LuMediaIconButton(
                        icon: Icons.auto_awesome_rounded,
                        tooltip: l10n.abkAudiobookGeneratorStudio,
                        size: luMediaIsTv(context) ? 48 : 44,
                        onTap: _openStudio,
                      ),
                      const SizedBox(width: 10),
                      LuMediaIconButton(
                        icon: Icons.tune_rounded,
                        tooltip: l10n.abkAudiobookCustomizer,
                        size: luMediaIsTv(context) ? 48 : 44,
                        onTap: _showAudiobookCustomizer,
                      ),
                    ],
                  ),
                ),
              ),

              // Search and the genre pills only while there is a catalogue to
              // search; without one they would promise results.
              if (catalogue)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: _SearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      hint: l10n.abkSearchAudiobooksByTitleAuthorOr,
                      clearTooltip: l10n.abkClearSearchTip,
                      onChanged: _onSearchChanged,
                      onSubmitted: _performSearch,
                      onClear: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                ),

              if (showCategoryPills && catalogue)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: LuPillTabs<String>(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      compact: true,
                      options: [
                        for (final category in _categories)
                          LuPillOption<String>(
                            value: category,
                            label: _categoryLabel(category),
                          ),
                      ],
                      selected: _selectedCategory,
                      onSelected: _selectCategory,
                      semanticsLabel: l10n.abkAudiobookGenres,
                    ),
                  ),
                ),

              if (!_isSearching && bannerBook != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 32),
                    child: _buildStudioBanner(
                      resume: resumeEntry,
                      book: bannerBook,
                      isMobile: isMobile,
                    ),
                  ),
                ),

              if (showContinue && _continueListeningList.isNotEmpty)
                SliverToBoxAdapter(child: _buildContinueListeningSection()),

              if (!_isSearching)
                SliverToBoxAdapter(
                  child: _buildGeneratedAndUploadedSection(
                    // The unavailable panel below already points at the
                    // studio, so the empty-library prompt would repeat it.
                    promptWhenEmpty: catalogue,
                  ),
                ),

              if (!catalogue)
                SliverToBoxAdapter(
                  child: _CatalogueUnavailable(
                    padding: EdgeInsets.fromLTRB(
                      pad,
                      LuSpace.s,
                      pad,
                      LuSpace.xxl + bottomInset,
                    ),
                    onOpenStudio: _openStudio,
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 14),
                    child: LuMediaSectionTitle(
                      title: _searchController.text.isNotEmpty
                          ? l10n.abkSearchResults
                          : l10n.abkFeaturedAudiobooks,
                      count: _searchResults.length,
                    ),
                  ),
                ),

                if (_isSearching)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: LuSpace.m),
                          Text(
                            l10n.abkScrapingHighQualityAudiobookSources,
                            textAlign: TextAlign.center,
                            style: LuText.bodySoft,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(
                      title: l10n.abkCouldNotLoadAudiobooks,
                      error: _errorMessage,
                      onRetry: () => _performSearch(_searchController.text),
                    ),
                  )
                else if (_searchResults.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        l10n.abkNoAudiobooksFoundTryAnotherSearch,
                        textAlign: TextAlign.center,
                        style: LuText.bodySoft,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      pad,
                      0,
                      pad,
                      LuSpace.xxl + bottomInset,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: cover,
                        mainAxisExtent:
                            LuMediaCover.heightFor(
                              cover,
                              MediaQuery.textScalerOf(context),
                            ) +
                            8,
                        crossAxisSpacing: isMobile ? 14 : 20,
                        mainAxisSpacing: isMobile ? 18 : 24,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final book = _searchResults[index];
                        final heroTag =
                            'audiobook-cover-$index-${book.uuid.isNotEmpty ? book.uuid : book.title}';
                        return LayoutBuilder(
                          builder: (context, constraints) => Align(
                            alignment: Alignment.topLeft,
                            child: _AudiobookCard(
                              key: ValueKey('book-$index-${book.uuid}'),
                              book: book,
                              heroTag: heroTag,
                              width: constraints.maxWidth,
                              onReturn: _loadContinueListening,
                            ),
                          ),
                        );
                      }, childCount: _searchResults.length),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── The banner: the book in progress, or the spotlight ──
  Widget _buildStudioBanner({
    required AudiobookProgress? resume,
    required Audiobook book,
    required bool isMobile,
  }) {
    final l10n = l10nOf(context);

    // A saved entry whose chapter list came back empty cannot be resumed into
    // the player, so it falls back to the detail route.
    final resumable = resume != null && resume.chapters.isNotEmpty
        ? resume
        : null;
    final subject = resumable?.audiobook ?? book;
    final heroTag = resumable != null
        ? 'studio-banner-${resumable.key}'
        : 'spotlight-hero-${subject.uuid.isNotEmpty ? subject.uuid : subject.title}';

    final position = Duration(milliseconds: resumable?.positionMs ?? 0);
    final duration = Duration(milliseconds: resumable?.durationMs ?? 0);
    final remaining = duration - position;
    final percent = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final author = (subject.author ?? '').trim();
    final meta = [
      if (author.isNotEmpty) author,
      if (resumable != null)
        l10n.abk2ChapterOfTotal(
          resumable.chapterIndex + 1,
          resumable.chapters.length,
        ),
      if (resumable == null && author.isEmpty) subject.source,
    ].join('  ·  ');

    Future<void> open() async {
      if (resumable != null) {
        await Navigator.push(
          context,
          AudiobookPageRoute(
            page: AudiobookPlayerScreen(
              audiobook: subject,
              chapters: resumable.chapters,
              initialChapterIndex: resumable.chapterIndex,
              initialPosition: position,
            ),
          ),
        );
      } else {
        await Navigator.push(
          context,
          AudiobookPageRoute(
            page: AudiobookDetailPage(audiobook: subject, heroTag: heroTag),
          ),
        );
      }
      _loadContinueListening();
    }

    final showProgress = resumable != null && duration.inMilliseconds > 0;
    return LuMediaHero(
      kicker: resumable != null
          ? l10n.abkNowPlayingAudiobook
          : l10n.abkSpotlightFeatured,
      title: subject.title,
      meta: meta,
      imageUrl: subject.coverImage,
      httpHeaders: abkCoverHeaders,
      heroTag: heroTag,
      icon: Icons.headphones_rounded,
      progress: showProgress ? percent : null,
      progressLabel: showProgress
          ? l10n.abkTimeLeft(_formatRemaining(remaining))
          : null,
      actions: [
        LuButton(
          label: resumable != null
              ? l10n.abk2ResumeTimeLeft(_formatRemaining(remaining))
              : l10n.abkListenNow,
          icon: Icons.play_arrow_rounded,
          compact: isMobile,
          onPressed: open,
        ),
      ],
    );
  }

  /// `14:32:10` above an hour, `32:10` below it.
  static String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  // ── Continue Listening ──
  Widget _buildContinueListeningSection() {
    final l10n = l10nOf(context);
    final width = MediaQuery.sizeOf(context).width < 600 ? 140.0 : 168.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: LuSpace.xl),
      child: LuRail(
        title: l10n.abkContinueListening,
        padding: luMediaPad(context),
        spacing: 18,
        height: _ContinueCover.heightFor(
          width,
          MediaQuery.textScalerOf(context),
        ),
        itemCount: _continueListeningList.length,
        itemBuilder: (context, index) {
          final item = _continueListeningList[index];
          return _ContinueCover(
            progress: item,
            width: width,
            onDelete: () async {
              await AudiobookProgressService.instance.removeProgress(item.key);
              _loadContinueListening();
            },
            onTap: () async {
              await Navigator.push(
                context,
                AudiobookPageRoute(
                  page: AudiobookPlayerScreen(
                    audiobook: item.audiobook,
                    chapters: item.chapters,
                    initialChapterIndex: item.chapterIndex,
                    initialPosition: Duration(milliseconds: item.positionMs),
                  ),
                ),
              );
              _loadContinueListening();
            },
          );
        },
      ),
    );
  }

  // ── Generated & Uploaded Audiobooks ──
  Widget _buildGeneratedAndUploadedSection({bool promptWhenEmpty = true}) {
    final l10n = l10nOf(context);
    final pad = luMediaPad(context);

    final jobs = Paper2AudioService.instance.jobs.value;
    final uploaded = CustomAudiobookService.instance.audiobooks.value;
    final hasItems = jobs.isNotEmpty || uploaded.isNotEmpty;

    if (!hasItems && !promptWhenEmpty) return const SizedBox.shrink();
    if (!hasItems) {
      return Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, LuSpace.xl),
        child: LuMediaPanel(
          gradient: const LinearGradient(
            colors: [Color(0xFF221D13), LuColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Wrap(
            spacing: 18,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      color: LuColors.gold,
                      size: 28,
                    ),
                    const SizedBox(width: LuSpace.m),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.abkAiAudiobookStudioEpubGenerator,
                            style: LuText.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n.abkGenerateAudiobooksFromEpubsOrImport,
                            style: LuText.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              LuButton(
                label: l10n.abkOpenStudio,
                icon: Icons.auto_awesome_rounded,
                compact: true,
                onPressed: _openStudio,
              ),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width < 600 ? 132.0 : 156.0;
    final items = <Widget Function()>[
      for (final job in jobs)
        () {
          final cleanTitle = job.fileName.replaceAll(
            RegExp(r'\.epub$', caseSensitive: false),
            '',
          );
          final status = job.isDone
              ? l10n.abk2VoiceLabel(job.voiceId)
              : (job.isFailed
                    ? l10n.abkFailed
                    : l10n.abk2GeneratingPercent((job.progress * 100).round()));
          return LuMediaCover(
            width: width,
            title: cleanTitle,
            subtitle: status,
            filePath: job.coverPath,
            icon: Icons.headphones_rounded,
            showPlay: job.isDone,
            badge: job.isDone
                ? null
                : LuBadge(job.isFailed ? l10n.abkFailed : '…', muted: true),
            onTap: job.isDone
                ? () {
                    final streamOrLocalPath =
                        job.localAudioPath ?? job.downloadUrl!;
                    final book = Audiobook(
                      uuid: 'p2a_${job.runId}',
                      audioBookId: 'p2a_${job.runId}',
                      dynamicSlugId: job.runId,
                      title: cleanTitle,
                      author: l10nCurrent().abkAiGenerated,
                      coverImage: job.coverPath ?? '',
                      source: 'Paper2Audio AI',
                      pageUrl: streamOrLocalPath,
                    );
                    Navigator.push(
                      context,
                      AudiobookPageRoute(
                        page: AudiobookPlayerScreen(
                          audiobook: book,
                          chapters: [
                            AudiobookChapter(
                              title: cleanTitle,
                              url: streamOrLocalPath,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                : _openStudio,
          );
        },
      for (final b in uploaded)
        () => LuMediaCover(
          width: width,
          title: b.title,
          subtitle: l10n.abk2AuthorLocal(b.author),
          filePath: b.coverPath,
          icon: Icons.library_music_rounded,
          showPlay: true,
          onTap: () {
            Navigator.push(
              context,
              AudiobookPageRoute(
                page: AudiobookPlayerScreen(
                  audiobook: b.toAudiobookModel(),
                  chapters: b.toChapters(),
                ),
              ),
            );
          },
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: LuSpace.xl),
      child: LuRail(
        title: l10n.abkMyGeneratedUploadedAudiobooks,
        padding: pad,
        spacing: 18,
        trailing: LuButton(
          label: l10n.abkStudio,
          icon: Icons.tune_rounded,
          kind: LuButtonKind.text,
          onPressed: _openStudio,
        ),
        height:
            LuMediaCover.heightFor(width, MediaQuery.textScalerOf(context)) +
            12,
        itemCount: items.length,
        itemBuilder: (context, index) => items[index](),
      ),
    );
  }
}

/// Stands in for the featured grid and search results when the build has no
/// catalogue credential: says why there is nothing to browse, and points at
/// the studio, which imports the listener's own files (and turns an EPUB into
/// an audiobook when its generator is configured).
class _CatalogueUnavailable extends StatelessWidget {
  const _CatalogueUnavailable({
    required this.padding,
    required this.onOpenStudio,
  });

  final EdgeInsets padding;
  final VoidCallback onOpenStudio;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final canGenerate = ServiceCredentials.isConfigured(
      ServiceCredential.paper2audio,
    );
    return Padding(
      padding: padding,
      child: LuMediaPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_rounded, color: LuColors.gold, size: 32),
            const SizedBox(height: LuSpace.m),
            Text(l10n.abkCatalogueUnavailableTitle, style: LuText.heading),
            const SizedBox(height: LuSpace.s),
            Text(
              canGenerate
                  ? l10n.abkCatalogueUnavailableBody
                  : l10n.abkCatalogueUnavailableBodyImportOnly,
              style: LuText.bodySoft,
            ),
            const SizedBox(height: LuSpace.l),
            LuButton(
              label: l10n.abkOpenStudio,
              icon: Icons.auto_awesome_rounded,
              onPressed: onOpenStudio,
            ),
          ],
        ),
      ),
    );
  }
}

/// The page's search box: a pill field with a gold edge while it is focused.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.clearTooltip,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: LuMotion.focus,
          height: luMediaIsTv(context) ? 56 : 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: LuColors.field,
            borderRadius: LuRadius.pill,
            border: Border.all(
              color: focused ? LuColors.gold : LuColors.line,
              width: focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: focused ? LuColors.gold : LuColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  cursorColor: LuColors.gold,
                  style: LuText.body,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    hintText: hint,
                    hintStyle: LuText.body.copyWith(
                      color: const Color(0xFF77736B),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                LuMediaIconButton(
                  icon: Icons.close_rounded,
                  tooltip: clearTooltip,
                  size: 34,
                  quiet: true,
                  onTap: onClear,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 继续收听: a square cover with the progress along its foot, the title and
/// the chapter. Remove is its second action - a long press, a right click,
/// the menu key or a held Select - and the corner button for a pointer.
class _ContinueCover extends StatelessWidget {
  const _ContinueCover({
    required this.progress,
    required this.onTap,
    required this.onDelete,
    this.width = 160,
  });

  final AudiobookProgress progress;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final double width;

  static double heightFor(
    double width, [
    TextScaler scaler = TextScaler.noScaling,
  ]) => width + 10 + scaler.scale(44) + 12;

  Future<void> _askRemove(BuildContext context) async {
    final l10n = l10nOf(context);
    final ok = await showLuConfirm(
      context,
      title: l10n.abkRemoveFromContinue,
      message: progress.audiobook.title,
      confirmLabel: l10n.listRemove,
    );
    if (ok) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final item = progress;
    final book = item.audiobook;
    final heroTag =
        'continue-cover-${book.uuid.isNotEmpty ? book.uuid : book.title}';
    final percent = item.durationMs > 0
        ? (item.positionMs / item.durationMs).clamp(0.0, 1.0)
        : 0.0;
    final chapterTitle =
        item.chapters.isNotEmpty && item.chapterIndex < item.chapters.length
        ? item.chapters[item.chapterIndex].title
        : l10n.abk2ResumeChapterNumber(item.chapterIndex + 1);
    final pointerRemove = !FormFactorService.hasRemoteInput;

    return SizedBox(
      width: width,
      child: LuFocusable(
        onTap: onTap,
        onLongPress: () => _askRemove(context),
        borderRadius: LuMediaCover.radius,
        semanticLabel: book.title,
        builder: (context, highlighted) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: width,
              child: ClipRRect(
                borderRadius: LuMediaCover.radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: heroTag,
                      child: LuMediaArt(
                        url: book.coverImage,
                        cacheWidth: (width * 2.5).round(),
                        icon: Icons.headphones_rounded,
                        httpHeaders: abkCoverHeaders,
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: highlighted ? 1 : 0,
                      duration: LuMotion.focus,
                      child: const ColoredBox(
                        color: Color(0x660A0A0C),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: LuColors.gold,
                            size: 52,
                          ),
                        ),
                      ),
                    ),
                    if (pointerRemove && highlighted)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: ExcludeFocus(
                          child: IconButton(
                            tooltip: l10n.abkRemoveFromContinue,
                            onPressed: onDelete,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xB30A0A0C),
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: LuColors.text,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 4,
                        color: const Color(0x40FFFFFF),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: percent,
                          child: const ColoredBox(color: LuColors.gold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuText.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            Text(
              '${l10n.abk2PercentCompleted((percent * 100).toInt())} · $chapterTitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuText.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _AudiobookCard extends StatelessWidget {
  final Audiobook book;
  final String heroTag;
  final double width;
  final VoidCallback? onReturn;

  const _AudiobookCard({
    super.key,
    required this.book,
    required this.heroTag,
    required this.width,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final author = (book.author ?? '').trim();
    final isTorrent = book.source.toLowerCase().contains('audiobookbay');

    return LuMediaCover(
      width: width,
      title: book.title,
      // Narrator is not a field the scrapers fill, so the line carries the
      // author when there is one and the source otherwise.
      subtitle: author.isNotEmpty ? author : book.source,
      imageUrl: book.coverImage,
      httpHeaders: abkCoverHeaders,
      heroTag: heroTag,
      icon: Icons.headphones_rounded,
      badge: isTorrent ? LuBadge(l10n.abkTorrentSource, muted: true) : null,
      onTap: () async {
        await Navigator.push(
          context,
          AudiobookPageRoute(
            page: AudiobookDetailPage(audiobook: book, heroTag: heroTag),
          ),
        );
        onReturn?.call();
      },
    );
  }
}
