// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lumora';

  @override
  String get navHome => 'Home';

  @override
  String get navBrowse => 'Browse';

  @override
  String get navSearch => 'Search';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSettings => 'Settings';

  @override
  String get navLiveTv => 'Live TV';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCopyReport => 'Copy report';

  @override
  String get actionSaveReport => 'Save report';

  @override
  String get actionCopyDiagnostic => 'Copy diagnostic';

  @override
  String get shellFullscreen => 'Fullscreen';

  @override
  String get shellExitFullscreen => 'Exit Fullscreen';

  @override
  String get shellFullscreenTooltip => 'Fullscreen (F11)';

  @override
  String get shellExitFullscreenTooltip => 'Exit Fullscreen (F11)';

  @override
  String get errorLoadFailed => 'Could not load movies';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String get listSeparator => ', ';

  @override
  String get shortcutsTitle => 'Keyboard shortcuts';

  @override
  String get shortcutsClose => 'Close keyboard shortcuts';

  @override
  String get shortcutsGroupAnywhere => 'Anywhere';

  @override
  String get shortcutsGroupMoving => 'Moving around';

  @override
  String get shortcutsGroupPlaying => 'While playing';

  @override
  String get shortcutsGroupReading => 'While reading';

  @override
  String get shortcutsShowSheet => 'Show this sheet';

  @override
  String get shortcutsShowSheetNote => 'Also Shift + /';

  @override
  String get shortcutsToggleFullscreen => 'Toggle fullscreen';

  @override
  String get shortcutsLeaveFullscreen =>
      'Leave fullscreen, or close what is open';

  @override
  String get shortcutsLeaveFullscreenNote =>
      'Never navigates away from a page by itself';

  @override
  String get shortcutsMyList => 'My List and Downloads';

  @override
  String get shortcutsSearchMacNote => 'Cmd + K on macOS';

  @override
  String get shortcutsSettingsMacNote => 'Cmd + , on macOS';

  @override
  String get shortcutsPlayPause => 'Play or pause';

  @override
  String get shortcutsPlayPauseNote => 'K does the same';

  @override
  String get shortcutsSeek => 'Back or forward 10 seconds';

  @override
  String get shortcutsSeekNote =>
      'The arrow keys do this too, when the video has focus';

  @override
  String get shortcutsMute => 'Mute or unmute';

  @override
  String get shortcutsAspect => 'Change how the video fills the screen';

  @override
  String get shortcutsPage => 'Previous or next page or chapter';

  @override
  String get shortcutsLine => 'Down or up a line, in focus mode';

  @override
  String nowPlayingSemantics(String title, String subtitle) {
    return 'Now playing, $title, $subtitle';
  }

  @override
  String get nowPlayingOpenHint => 'Open the full player';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerNext => 'Next';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionPlayback => 'PLAYBACK';

  @override
  String get settingsSectionSources => 'SOURCES';

  @override
  String get settingsSectionIntegrations => 'INTEGRATIONS';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsSectionContent => 'CONTENT';

  @override
  String get settingsSectionApp => 'APP';

  @override
  String get stateEnabled => 'Enabled';

  @override
  String get stateDisabled => 'Disabled';

  @override
  String get stateActive => 'Active';

  @override
  String get stateOffline => 'Offline';

  @override
  String get stateConnected => 'Connected';

  @override
  String get stateNotSet => 'Not set';

  @override
  String get stateOn => 'On';

  @override
  String get stateOff => 'Off';

  @override
  String get settingsVideoTitle => 'Video & Upscaling';

  @override
  String get settingsVideoSubtitle =>
      'Anime4K neural GLSL shader presets and GPU pipeline';

  @override
  String get settingsP2pTitle => 'Built-in P2P Torrent Source';

  @override
  String get settingsP2pActiveSubtitle =>
      'Lumora torrent swarms (Knaben, TorrentGalaxy) active';

  @override
  String get settingsP2pDisabledSubtitle =>
      'P2P disabled. Using only direct HTTP streaming';

  @override
  String get settingsP2pActiveValue => 'P2P Active';

  @override
  String get settingsP2pHttpValue => 'HTTP Only';

  @override
  String get settingsP2pInfoTooltip => 'P2P Advisory Details';

  @override
  String get settingsAddonsTitle => 'Addons';

  @override
  String get settingsAddonsSubtitle => 'Stremio catalogs and content providers';

  @override
  String settingsAddonsInstalled(int count) {
    return '$count Installed';
  }

  @override
  String get settingsBuiltinTitle => 'Built-in Providers';

  @override
  String get settingsBuiltinSubtitle =>
      'Built-in streaming sources, priority order & toggles';

  @override
  String get settingsBuiltinCustom => 'Custom';

  @override
  String get settingsBuiltinDefault => 'Default';

  @override
  String get settingsDebridTitle => 'Debrid & Cloud Streaming';

  @override
  String get settingsDebridSubtitle =>
      'Real-Debrid, TorBox, AllDebrid, Premiumize & Debrid-Link';

  @override
  String get settingsTraktTitle => 'Trakt.tv Sync';

  @override
  String get settingsTraktSubtitle =>
      'Cross-device watchlist, history & playback synchronization';

  @override
  String get settingsSimklTitle => 'Simkl Sync';

  @override
  String get settingsSimklSubtitle =>
      'Cross-device Movies, TV & Anime synchronization';

  @override
  String get settingsTmdbTitle => 'TMDb API Key';

  @override
  String get settingsTmdbSubtitle =>
      'Your own key for the ranked 1990s rails and scraper metadata';

  @override
  String get settingsTmdbYourKey => 'Your key';

  @override
  String get settingsServiceKeysTitle => 'Service API Keys';

  @override
  String get settingsServiceKeysSubtitle =>
      'Subtitles, audiobooks and scraper keys you supply yourself';

  @override
  String settingsServiceKeysCount(int provided, int total) {
    return '$provided of $total set';
  }

  @override
  String get settingsDiscordTitle => 'Discord Rich Presence';

  @override
  String get settingsDiscordEnabledSubtitle =>
      'Broadcasting movies, shows, music & live activity to Discord';

  @override
  String get settingsDiscordDisabledSubtitle =>
      'Disabled. Activity is hidden from Discord';

  @override
  String get settingsAppearanceTitle => 'Appearance & Interface';

  @override
  String get settingsAppearanceSubtitle =>
      'Liquid Glass, wallpaper and Home Page UI';

  @override
  String get settingsGlassOn => 'Glass ON';

  @override
  String get settingsCalendarTitle => 'TV Airing Calendar';

  @override
  String get settingsCalendarOnSubtitle =>
      'Calendar buttons active on Home top bar and section headers';

  @override
  String get settingsCalendarOffSubtitle =>
      'Calendar disabled and hidden across all pages';

  @override
  String get settingsAiQuizTitle => 'AI Recommendation Quiz';

  @override
  String get settingsAiQuizOnSubtitle =>
      'AI Taste Profile Quiz active on Home and Search bars';

  @override
  String get settingsAiQuizOffSubtitle =>
      'AI quiz disabled and hidden across all pages';

  @override
  String get settingsAdultTitle => 'Adult Content';

  @override
  String get settingsAdultOnSubtitle =>
      '18+ catalogs, search results and sources are enabled';

  @override
  String get settingsAdultOffSubtitle =>
      'Hidden. No 18+ catalogs, search results or sources are fetched';

  @override
  String get settingsBackupTitle => 'Backup & Restore';

  @override
  String get settingsBackupSubtitle =>
      'Export or import settings, theme and library progress (JSON)';

  @override
  String get settingsBackupDialogSubtitle => 'Cross-device JSON configuration';

  @override
  String get settingsBackupDescription =>
      'Exports your settings, theme, My List and progress. Leave the passphrase blank for a redacted profile that keeps credentials, IPTV portals and addon URLs on this device. A passphrase encrypts a full profile with them included.';

  @override
  String get settingsPassphraseOptional => 'Passphrase (optional)';

  @override
  String get settingsPassphraseHelper =>
      'At least 8 characters for an encrypted full profile.';

  @override
  String get settingsExportProfile => 'Export Profile';

  @override
  String get settingsPassphraseTooShort =>
      'Use at least 8 characters for the passphrase.';

  @override
  String get settingsRedactedProfileCopied =>
      'Redacted profile copied. Credentials, portals and addons stay on this device.';

  @override
  String get settingsEncryptedProfileCopied =>
      'Encrypted full profile copied. Keep the passphrase safe; it cannot be recovered.';

  @override
  String get settingsImportJson => 'Import JSON';

  @override
  String get settingsPasteJsonTitle => 'Paste Configuration JSON';

  @override
  String get settingsPasteJsonHint => 'Paste backup JSON here...';

  @override
  String get settingsPassphraseEncrypted => 'Passphrase (encrypted profiles)';

  @override
  String get settingsPassphraseEncryptedHelper =>
      'Leave blank for a redacted profile. Encrypted profiles need the passphrase they were exported with.';

  @override
  String get settingsPasteFromClipboard => 'Paste from Clipboard';

  @override
  String get settingsFromFile => 'From File';

  @override
  String get settingsRestoreNow => 'Restore Now';

  @override
  String settingsImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get settingsChooseProfile => 'Choose a Lumora profile';

  @override
  String get settingsClearCacheTitle => 'Clear cache';

  @override
  String get settingsClearCacheSubtitle =>
      'Drop cached artwork & metadata. Sign-in, addons, My List & history stay';

  @override
  String get settingsClearCacheConfirmTitle => 'Clear cache?';

  @override
  String get settingsClearCacheConfirmBody =>
      'Removes cached artwork and metadata so fresh copies are fetched. This does not sign you out or remove addons - your profile, My List, watch history and settings stay exactly as they are.';

  @override
  String get settingsClear => 'Clear';

  @override
  String settingsCacheArtwork(String error) {
    return 'artwork cache ($error)';
  }

  @override
  String settingsCacheMetadata(String error) {
    return 'metadata cache ($error)';
  }

  @override
  String settingsCacheHero(String error) {
    return 'hero artwork cache ($error)';
  }

  @override
  String get settingsCacheCleared => 'Cache cleared.';

  @override
  String settingsCacheClearedExcept(String failures) {
    return 'Cache cleared except the $failures.';
  }

  @override
  String get settingsCacheClearedSuffix =>
      'You are still signed in - addons, My List, watch history and settings are untouched.';

  @override
  String get settingsUpdatesTitle => 'App Updates';

  @override
  String get settingsUpdatesSubtitle =>
      'Check for latest software versions and patches';

  @override
  String get settingsUpdatesCheck => 'Check';

  @override
  String get settingsDiagnosticsSubtitle =>
      'App, device and player state (redacted) you can copy or save';

  @override
  String get settingsLanguageSubtitle =>
      'Chinese, English, or follow the device';

  @override
  String get settingsAboutTitle => 'About Lumora';

  @override
  String get settingsAboutSubtitle => 'Architecture, video engine, and credits';

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get diagnosticsSubtitle =>
      'Local app, device and player report (no telemetry)';

  @override
  String get diagnosticsDescription =>
      'A local-only snapshot of this install: app and device details, player settings, the stream engine state and the recent crash breadcrumbs. Credentials, addon URLs, IPTV portals and playlist links are never included. Nothing is uploaded - the report only exists once you copy or save it.';

  @override
  String get diagnosticsSectionDevice => 'DEVICE';

  @override
  String get diagnosticsSectionPlayerEngine => 'PLAYER & ENGINE';

  @override
  String get diagnosticsSectionBreadcrumbs => 'CRASH BREADCRUMBS';

  @override
  String get diagnosticsSummary => 'Summary';

  @override
  String get diagnosticsNotAvailable => 'Not available';

  @override
  String diagnosticsBreadcrumbCount(int count, int shown) {
    return '$count recorded • last $shown shown';
  }

  @override
  String get diagnosticsBreadcrumbs => 'Recent activity';

  @override
  String get diagnosticsEmpty => 'No breadcrumbs recorded yet.';

  @override
  String get diagnosticsCopied => 'Diagnostics report copied.';

  @override
  String get diagnosticsCopiedToClipboard =>
      'Diagnostic report copied to clipboard';

  @override
  String get diagnosticsCopyFailed => 'Could not copy the report';

  @override
  String get diagnosticsSaveFailed => 'Could not save the report';

  @override
  String diagnosticsSaved(String path) {
    return 'Diagnostics saved to $path';
  }

  @override
  String get searchHintTv => 'Search for a movie or series';

  @override
  String get searchHint => 'Search movies, series, or paste links';

  @override
  String get searchVoice => 'Search by voice';

  @override
  String get searchVoiceDenied =>
      'Microphone access is off. Allow it for Lumora to search by voice.';

  @override
  String get searchAiQuiz => 'AI Taste Quiz';

  @override
  String get searchPaste => 'Paste from clipboard';

  @override
  String get searchFailureTitle => 'Search could not reach its sources';

  @override
  String searchFailureBody(int failed, int total) {
    return '$failed of $total sources did not respond';
  }

  @override
  String get searchFailureAdvice =>
      'A dead addon or an expired provider runtime is fixed in Addons.';

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchingMoreSources => 'Searching more sources...';

  @override
  String searchPartialFailure(String sources) {
    return 'Partial Source Failure: $sources did not respond. Other sources answered normally, so the results below are real but incomplete.';
  }

  @override
  String get searchRecent => 'Recent Searches';

  @override
  String get searchClearAll => 'Clear All';

  @override
  String get searchTrending => 'Trending & Suggested';

  @override
  String get searchNothingToSuggest => 'Nothing to suggest yet';

  @override
  String get searchNothingToSuggestBody =>
      'Search for a title above, or connect an addon in Settings to have something to search.';

  @override
  String get searchPinnedSpine => 'PINNED SPINE';

  @override
  String searchCloudstreamSection(String provider) {
    return 'CloudStream • $provider';
  }

  @override
  String get searchCloudstreamExtension => 'CloudStream Extension';

  @override
  String get searchTitlesSection => 'Titles';

  @override
  String get searchImdbSuggestions => 'IMDb suggestions';

  @override
  String get searchDirectStream => 'Direct Stream';

  @override
  String get searchSourceTitleLookup => 'Title lookup';

  @override
  String get playerSeekBack => 'Seek -10s';

  @override
  String get playerSeekForward => 'Seek +10s';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerMute => 'Mute';

  @override
  String get playerUnmute => 'Unmute';

  @override
  String get playerPreviousEpisode => 'Previous Episode';

  @override
  String get playerNextEpisode => 'Next Episode';

  @override
  String get playerEpisodes => 'Episodes';

  @override
  String get playerAspectRatio => 'Aspect Ratio (C)';

  @override
  String get playerPlaybackSpeed => 'Playback Speed';

  @override
  String get playerAudioTracks => 'Audio Tracks';

  @override
  String get playerSubtitles => 'Subtitles';

  @override
  String get playerSubtitleSync => 'Subtitle Sync';

  @override
  String get playerFullscreen => 'Fullscreen (F)';

  @override
  String get playerExitFullscreen => 'Exit Fullscreen (F)';

  @override
  String playerVolume(int percent) {
    return 'Volume $percent%';
  }

  @override
  String playerSeekPosition(String position, String duration) {
    return '$position of $duration';
  }

  @override
  String get a11yOpenDetails => 'Open details';

  @override
  String a11yResume(String title, int percent) {
    return 'Resume $title, $percent% watched';
  }

  @override
  String get emptyMyList => 'Your list is empty';

  @override
  String get emptyMyListBody =>
      'Save your favorite movies and TV shows to watch anytime';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'App language. System follows your device.';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => 'Chinese';

  @override
  String get a11yResumePlayback => 'Resume playback';

  @override
  String get playerPlaybackPosition => 'Playback position';

  @override
  String get playerVolumeLabel => 'Volume';

  @override
  String get homePlay => 'Play';

  @override
  String get homeMoreInfo => 'More Info';

  @override
  String get homeTrailer => 'Trailer';

  @override
  String get homeContinueWatching => 'Continue Watching';

  @override
  String get homeSeeAll => 'See All';

  @override
  String get homeCalendar => 'Calendar';

  @override
  String get homeTop10 => 'This Week\'s Top 10';

  @override
  String get homeLoadingLibrary => 'Loading your library...';

  @override
  String get homeEmptyShelf =>
      'Nothing on the shelf yet. Add an addon in Settings, or pull down to refresh.';

  @override
  String homeMinutesLeft(int minutes) {
    return '${minutes}m left';
  }

  @override
  String homeBecauseOnList(String title) {
    return 'Because you have \"$title\" on your list';
  }

  @override
  String homeBecauseWatching(String title) {
    return 'Because you\'re watching \"$title\"';
  }

  @override
  String homeBasedOn(String title) {
    return 'Recommendations based on $title';
  }

  @override
  String get homeTraktRecommended => 'Recommended for You (Trakt)';

  @override
  String get homeTraktRecommendedSub =>
      'Personalized based on your Trakt watch history';

  @override
  String get homeTrendingWeek => 'Trending This Week';

  @override
  String get homeTrendingWeekSub => 'What Trakt viewers are watching right now';

  @override
  String get homePopularNow => 'Popular Now';

  @override
  String get homePopularNowSub => 'Most-watched titles across Trakt';

  @override
  String get homeComingSoon => 'Coming Soon';

  @override
  String get homeComingSoonSub => 'Most anticipated upcoming releases';

  @override
  String get homeFromTrakt => 'From Trakt';

  @override
  String get homeSimklRecommended => 'Recommended for You (Simkl)';

  @override
  String get homeSimklRecommendedSub =>
      'Top-rated & personalized suggestions from Simkl';

  @override
  String catalogPopular(String type) {
    return 'Popular $type';
  }

  @override
  String catalogNew(String type) {
    return 'New $type';
  }

  @override
  String catalogTopRated(String type) {
    return 'Top Rated $type';
  }

  @override
  String get typeMovies => 'Movies';

  @override
  String get typeSeries => 'Series';

  @override
  String get typeAnime => 'Anime';

  @override
  String get typeCollections => 'Collections';

  @override
  String get kindMovie => 'Movie';

  @override
  String get kindSeries => 'Series';

  @override
  String get kindAnime => 'Anime';

  @override
  String get detailsPlayMovie => 'Play Movie';

  @override
  String get detailsPlayEpisodes => 'Play Episodes';

  @override
  String get detailsPlayFirstMovie => 'Play First Movie';

  @override
  String detailsResume(String time) {
    return 'Resume · $time';
  }

  @override
  String detailsResumeEpisode(int episode, String time) {
    return 'Resume E$episode · $time';
  }

  @override
  String get detailsLibrary => 'Library';

  @override
  String get detailsInLibrary => 'In Library';

  @override
  String detailsSeasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seasons',
      one: '1 Season',
    );
    return '$_temp0';
  }

  @override
  String detailsSeason(int season) {
    return 'Season $season';
  }

  @override
  String get detailsEpisodes => 'Episodes';

  @override
  String get detailsCollectionMovies => 'Movies in Collection';

  @override
  String get detailsSimilar => 'Similar Content';

  @override
  String get detailsMoreLikeThis => 'More Like This';

  @override
  String get detailsCast => 'Top Cast & Characters';

  @override
  String get detailsReadMore => 'Read more';

  @override
  String get detailsShowLess => 'Show less';

  @override
  String get detailsUnavailable => 'Details unavailable.';

  @override
  String get detailsGoBack => 'Go Back';

  @override
  String detailsEpisodeBadge(String episode) {
    return 'E$episode';
  }

  @override
  String detailsPartBadge(String part) {
    return 'PART $part';
  }

  @override
  String detailsWatchedTo(String time) {
    return 'Watched to $time';
  }

  @override
  String get searchKindAnime => 'Animation';

  @override
  String get searchKindAnimeMovie => 'Animated film';

  @override
  String get searchKindLiveSeries => 'Live-action series';

  @override
  String get searchKindSeries => 'Series';

  @override
  String get searchKindMovie => 'Movie';

  @override
  String searchFilterAll(int count) {
    return 'All $count';
  }

  @override
  String searchFilterAnime(int count) {
    return 'Animation $count';
  }

  @override
  String searchFilterSeries(int count) {
    return 'Series $count';
  }

  @override
  String searchFilterMovies(int count) {
    return 'Movies $count';
  }

  @override
  String get searchFilterEmpty => 'Nothing of this kind.';

  @override
  String searchResumeEpisode(int season, int episode) {
    return 'Watched to S$season E$episode';
  }

  @override
  String get searchResumeMovie => 'Started watching';

  @override
  String get searchHot => 'Popular searches';

  @override
  String get searchNoPoster => 'No poster';

  @override
  String get watchSources => 'Watch Sources';

  @override
  String get watchSearching => 'Searching sources...';

  @override
  String watchFoundSearching(int count) {
    return '$count found · Searching...';
  }

  @override
  String watchFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources found',
      one: '1 source found',
    );
    return '$_temp0';
  }

  @override
  String watchFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String watchFilterDebrid(String service, int count) {
    return '$service ($count)';
  }

  @override
  String watchFilterTorrents(int count) {
    return 'Torrents ($count)';
  }

  @override
  String watchFilterDirect(int count) {
    return 'Direct ($count)';
  }

  @override
  String get watchSeedsAll => 'All Seeds';

  @override
  String get watchSeedsMost => 'Most Seeds';

  @override
  String get watchSeedsMostLong => 'Most Seeds (High to Low)';

  @override
  String watchSeedsAtLeast(int count) {
    return '$count+ Seeds';
  }

  @override
  String get watchSeedsActive => 'Active Seeds';

  @override
  String get watchSeedsActiveLong => 'Active Seeds (>0)';

  @override
  String get watchSizeAll => 'All Sizes';

  @override
  String get watchSizeLargest => 'Largest';

  @override
  String get watchSizeSmallest => 'Smallest';

  @override
  String get watchSizeLargestFirst => 'Largest First';

  @override
  String get watchSizeSmallestFirst => 'Smallest First';

  @override
  String get watchAllSources => 'All Sources';

  @override
  String get watchAllAudio => 'All Audio';

  @override
  String get watchAudioMulti => '🌐 Multi-Audio';

  @override
  String get watchAudioEnglish => '🇺🇸 English / Original';

  @override
  String get watchAudioHindi => '🇮🇳 Hindi / Indian';

  @override
  String get watchAudioGerman => '🇩🇪 German';

  @override
  String get watchAudioFrench => '🇫🇷 French';

  @override
  String get watchAudioCastilian => '🇪🇸 Spanish (Castilian)';

  @override
  String get watchAudioLatino => '🇲🇽 Spanish (Latin)';

  @override
  String get watchAudioSpanish => '🌎 All Spanish';

  @override
  String get watchAudioRussian => '🇷🇺 Russian';

  @override
  String get watchAudioJapanese => '🇯🇵 Japanese';

  @override
  String get watchAudioItalian => '🇮🇹 Italian';

  @override
  String get watchSeedersFilter => 'Seeders Filter';

  @override
  String get watchSizeFilter => 'File Size Filter';

  @override
  String get watchProviderFilter => 'Source Provider';

  @override
  String get watchUnavailable => 'Unavailable';

  @override
  String watchSeeds(int count) {
    return '$count Seeds';
  }

  @override
  String get watchMagnetCopied => 'Magnet link copied to clipboard';

  @override
  String get watchCopied => 'Copied!';

  @override
  String get watchCopyMagnet => 'Copy Magnet Link';

  @override
  String get watchNoSources => 'No sources found';

  @override
  String get watchNoSourcesBody =>
      'No streams found. Install more addons from Settings or try another title.';

  @override
  String get watchInstallAddons => 'Install Addons';

  @override
  String get watchAutoTitle => 'Auto (recommended)';

  @override
  String get watchAutoIdle => 'Plays the fastest source that is this title';

  @override
  String get watchAutoPicking => 'Finding the fastest source…';

  @override
  String get watchAutoNone =>
      'Nothing here plays by itself. Pick one below to try.';

  @override
  String get watchDeadNoSeeds => '0 seeders · probably won\'t play';

  @override
  String get watchDeadUnreachable => 'Can\'t connect';

  @override
  String get detailsSourceAuto => 'Source: Auto';

  @override
  String get detailsSourceManual => 'Source: Manual';

  @override
  String playerSpeedLabel(String rate) {
    return 'Speed ${rate}x';
  }

  @override
  String playerSubtitlesWith(String language) {
    return 'Subtitles · $language';
  }

  @override
  String get playerSubtitlesOff => 'Subtitles · Off';

  @override
  String playerSourceWith(String quality) {
    return 'Source · $quality';
  }

  @override
  String get playerSource => 'Source';

  @override
  String get playerSubChinese => 'Chinese';

  @override
  String get playerSubEnglish => 'English';

  @override
  String get panelNoStreamsEpisode => 'No streams found for this episode';

  @override
  String get panelNoStreamsTitle => 'No streams found for this title';

  @override
  String get panelEmptyEpisodeBody =>
      'Try going back to episodes and choosing another episode or provider.';

  @override
  String get panelEmptyTitleBody =>
      'Try another provider for this title, or close this panel and check your addons in Settings.';

  @override
  String get panelBackToEpisodes => 'Back to Episodes';

  @override
  String panelEpisode(String episode) {
    return 'Episode $episode';
  }

  @override
  String panelAllProviders(String addon) {
    return 'All providers · watching via $addon';
  }

  @override
  String get panelClose => 'Close';

  @override
  String get panelSearchingAll => 'Searching every provider…';

  @override
  String get panelRescrape => 'Rescrape Sources';

  @override
  String get panelScrapingMore => 'Scraping additional sources...';

  @override
  String get panelStreamSource => 'Stream Source';

  @override
  String get playerNotResponding =>
      'This stream is not responding - the source may be expired.';

  @override
  String get playerNotRespondingPick =>
      'This stream is not responding - the source may be expired. Pick another source below.';

  @override
  String get playerTryingAnother =>
      'This source is not responding • Trying another source';

  @override
  String get playerInitializing => 'Initializing...';

  @override
  String playerBuffering(String label) {
    return 'Buffering $label...';
  }

  @override
  String playerEpisodeLabel(String season, String episode, String title) {
    return 'S$season:E$episode - $title';
  }

  @override
  String get playerGatheringPeers => 'Gathering metadata & peers...';

  @override
  String playerUsingDebrid(String service) {
    return 'Using $service for files...';
  }

  @override
  String get playerSourceFailed =>
      'Source failed to play. Please select another source below.';

  @override
  String get playerOpenError =>
      'Media Open Error: Stream server quota exceeded or invalid media format.\nPlease select another stream.';

  @override
  String get playerTestingOthers => 'Testing other sources for you';

  @override
  String playerTrying(String source) {
    return 'Trying $source.';
  }

  @override
  String playerAttempt(String attempt, String max) {
    return 'Attempt $attempt of $max';
  }

  @override
  String get playerChooseMyself => 'Choose a source myself';

  @override
  String get playerChooseAnother => 'Choose another source';

  @override
  String get playerGoBack => 'Go back';

  @override
  String get playerBack => 'Back';

  @override
  String get playerScreenshot => 'Screenshot';

  @override
  String get playerDownloading => 'Downloading...';

  @override
  String get playerDownloadMedia => 'Download Media';

  @override
  String get playerLockScreen => 'Lock Screen';

  @override
  String get playerCast => 'Cast';

  @override
  String get playerLocked => 'Screen is locked. Tap the lock icon to unlock.';

  @override
  String get playerUnlock => 'Unlock';

  @override
  String get playerMuted => 'Muted';

  @override
  String get playerCannotSeek =>
      'This source cannot seek • Starting from the beginning';

  @override
  String get playerSubDownloadFailed => 'Failed to download subtitle';

  @override
  String get playerSubSynced => 'Subtitle timing synchronized and saved!';

  @override
  String get playerDownloadInProgress =>
      'Download already in progress in background.';

  @override
  String get playerAlreadyDownloaded => 'This media is already downloaded.';

  @override
  String get playerDownloadStarted =>
      'Download started in background. Track progress in Downloads tab.';

  @override
  String get playerUrlCopied => 'Stream URL copied to clipboard';

  @override
  String get playerNoUrl => 'No active stream URL available to copy.';

  @override
  String get playerSubSyncEmbedded =>
      'Subtitle sync is not supported for embedded subtitles. Please select an external subtitle.';

  @override
  String get playerSubSyncNeedExternal =>
      'Please load an external subtitle to use subtitle sync.';

  @override
  String get playerSubSyncEmbeddedShort =>
      'Subtitle sync is not supported for embedded subtitles.';

  @override
  String get playerSpeechSyncNeedsFile =>
      'Speech sync requires an external subtitle file.';

  @override
  String get playerDismiss => 'Dismiss (✕)';

  @override
  String get playerSources => 'Sources';

  @override
  String get playerQuality => 'Quality';

  @override
  String playerQualityWith(String quality) {
    return 'Quality · $quality';
  }

  @override
  String get playerQualityAuto => 'Auto';

  @override
  String get playerQualityAutoNote => 'Best your connection carries';

  @override
  String playerQualityAutoMeasured(String mbps) {
    return 'Best for your $mbps Mbps';
  }

  @override
  String get playerQualityPlaying => 'Playing now';

  @override
  String playerQualitySources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources',
      one: '1 source',
    );
    return '$_temp0';
  }

  @override
  String playerQualityNone(String quality) {
    return 'No source in $quality for this title';
  }

  @override
  String get p2pAdvisory => 'PRIVACY & NETWORK ADVISORY';

  @override
  String get p2pTitle => 'P2P Torrent Streaming Notice';

  @override
  String get p2pExit => 'Exit';

  @override
  String get p2pQuestion =>
      'Would you like to turn off the built-in P2P torrent source and use only direct HTTP streaming?';

  @override
  String get p2pBody =>
      'P2P (peer-to-peer torrent) streaming connects directly to public torrent swarms to download and seed video pieces. In certain countries and regions, unencrypted torrent activity may be monitored and could result in warning letters or notices from your Internet Service Provider (ISP).';

  @override
  String get p2pDirectTitle => 'Direct Stream';

  @override
  String get p2pDirectBody =>
      'Safe direct HTTPS web streams. No torrenting or peer uploading.';

  @override
  String get p2pTorrentTitle => 'Torrent Engine';

  @override
  String get p2pTorrentBody =>
      'P2P swarms (Knaben, TorrentGalaxy). Involves peer data sharing.';

  @override
  String get p2pNote =>
      'Note: You can easily toggle the built-in P2P source back on or off anytime in Settings.';

  @override
  String get p2pDontShowAgain => 'Don\'t Show Again';

  @override
  String get p2pTurnOff => 'Yes, Turn Off P2P';

  @override
  String get p2pTurnedOff =>
      'P2P torrent source turned off. Direct streams will be used.';

  @override
  String recommendFor(String kind) {
    return 'For you · $kind';
  }

  @override
  String recommendBecause(String kind) {
    return 'Because you watch a lot of $kind';
  }

  @override
  String get detailsLike => 'Like';

  @override
  String get detailsDislike => 'Not for me';

  @override
  String get subRefreshOnline => 'Refresh Online Subtitles';

  @override
  String get subSyncBar => 'Subtitle Sync Bar';

  @override
  String get subAppearance => 'Subtitle Appearance';

  @override
  String get subSpeechSync => 'Speech Text Sync';

  @override
  String get subOff => 'Off';

  @override
  String get subEmbedded => 'Embedded';

  @override
  String get subEmbeddedCaps => 'EMBEDDED';

  @override
  String get subAllLanguages => 'All Languages';

  @override
  String get subAll => 'All';

  @override
  String get subHearingImpaired => 'HI / CC';

  @override
  String get subForced => 'Forced';

  @override
  String get subForcedCaps => 'FORCED';

  @override
  String get subLanguages => 'LANGUAGES';

  @override
  String get subSearchOnline => 'Search Online';

  @override
  String get subSearching => 'Searching subtitles...';

  @override
  String get subNone => 'No subtitles available.';

  @override
  String get subSearchProviders => 'Search Online Providers';

  @override
  String get subSearchingMore => 'Searching additional subtitles online...';

  @override
  String get subFindMore => 'Find more subtitles';

  @override
  String get speedTitle => 'PLAYBACK SPEED';

  @override
  String get speedNormal => 'Normal (1.0×)';

  @override
  String get speedSleepTimer => 'SLEEP TIMER';

  @override
  String get audioTracksTitle => 'AUDIO TRACKS';

  @override
  String get audioDefaultPlaying => 'Default audio stream playing.';

  @override
  String get audioSyncOffset => 'Audio Sync Offset';

  @override
  String get aspectTitle => 'ASPECT RATIO';

  @override
  String get aspectSubtitleScale => 'Subtitle Size Scale';

  @override
  String get episodesScrollUp => 'Scroll Up';

  @override
  String get episodesScrollDown => 'Scroll Down';

  @override
  String get episodesPrevSeasons => 'Previous Seasons';

  @override
  String get episodesNextSeasons => 'Next Seasons';

  @override
  String get episodesPlaying => 'PLAYING';

  @override
  String get episodesSelectSources => 'Select Sources';

  @override
  String get syncTextSync => 'Text Sync';

  @override
  String get syncDiscard => 'Discard changes';

  @override
  String get syncDone => 'Done';

  @override
  String get syncDriftActive =>
      'Drift correction active (2 anchor points). Fine-tune with buttons.';

  @override
  String get syncFixSectionCaps => 'FIX SECTION';

  @override
  String get syncTimingCaps => 'SUBTITLE TIMING';

  @override
  String get syncSelectRange => 'Select Range & Sync';

  @override
  String get syncSpeechDialogue => 'Speech Dialogue Sync';

  @override
  String get syncSearchDialogue => 'Search dialogue...';

  @override
  String get syncNow => 'NOW';

  @override
  String get syncFromHere => 'Sync from here';

  @override
  String get syncJumpHere => 'Jump here';

  @override
  String get syncJumpNow => 'Jump to now';

  @override
  String get syncSelecting => 'Selecting';

  @override
  String get syncFixSection => 'Fix section';

  @override
  String get syncReset => 'Reset timing';

  @override
  String get syncSaving => 'Saving...';

  @override
  String get syncSave => 'Save Timing';

  @override
  String get listRemoveConfirm => 'Remove from My List?';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get listRemove => 'Remove';

  @override
  String get listTitle => 'My List';

  @override
  String get listSyncing => 'Syncing...';

  @override
  String get listSynced => 'Cloud Synced';

  @override
  String get listFilter => 'Filter saved titles';

  @override
  String get listSortRecent => 'Recently Added';

  @override
  String get listSortTitle => 'Alphabetical';

  @override
  String get listSortYear => 'Release Year';

  @override
  String get listSearch => 'Search saved titles...';

  @override
  String get listEmpty => 'Your list is empty';

  @override
  String get listNoMatch => 'No titles found';

  @override
  String get listEmptyBody =>
      'Save your favorite movies and TV shows to watch anytime';

  @override
  String get listNoMatchBody =>
      'Try adjusting your search query or filter settings';

  @override
  String get listResetFilters => 'Reset Filters';

  @override
  String get dlFileMissing =>
      'File not found on disk. It may have been moved or deleted.';

  @override
  String get dlDeleteTitle => 'Delete Download';

  @override
  String get commonDelete => 'Delete';

  @override
  String get dlList => 'Download list';

  @override
  String get dlActive => 'Active';

  @override
  String get dlDone => 'Downloaded';

  @override
  String get dlTitle => 'Downloads';

  @override
  String get dlOpenFolder => 'Open Downloads Folder';

  @override
  String get dlNoActive => 'No active downloads';

  @override
  String get dlNoActiveBody =>
      'Media you download from the video player will show up here.';

  @override
  String get dlTorrent => 'P2P Torrent';

  @override
  String get dlDebrid => 'Cloud Debrid';

  @override
  String get dlDirect => 'Direct HTTP';

  @override
  String get dlUnknownError => 'Unknown error';

  @override
  String get dlResume => 'Resume';

  @override
  String get dlRetry => 'Retry / Reconnect';

  @override
  String get dlOpenLocation => 'Open Folder Location';

  @override
  String get dlNoDone => 'No downloaded media';

  @override
  String get dlNoDoneBody =>
      'Completed downloads will appear here for offline playback.';

  @override
  String get dlOffline => 'Offline Media';

  @override
  String get animeLoadFailedArabic =>
      'Failed to load Arabic Anime catalog. Check your internet connection.';

  @override
  String get animeLoadFailedRetry =>
      'Failed to load Anime catalog. Please check your internet connection or retry.';

  @override
  String get animeLoadFailed =>
      'Failed to load Anime catalog. Check your internet connection.';

  @override
  String get animeCouldNotLoad => 'Could not load anime';

  @override
  String get animeTrending => 'Trending on AniList';

  @override
  String get animeTrendingSub => 'Top popular and trending series';

  @override
  String get animeSeasonPopular => 'Popular This Season (AniList Sync)';

  @override
  String get animeMasterpieces => 'All-Time Masterpieces';

  @override
  String get animeMasterpiecesSub => 'Critically acclaimed top rated anime';

  @override
  String get animeNextSeason => 'Anticipated Next Season';

  @override
  String get animeNextSeasonSub => 'Upcoming anime you cannot miss';

  @override
  String get animeAction => 'Action & Adventure';

  @override
  String get animeActionSub => 'High octane battles and epic journeys';

  @override
  String get animeRomance => 'Romance & Drama';

  @override
  String get animeRomanceSub => 'Heartfelt emotional stories';

  @override
  String get animeFantasy => 'Fantasy & Isekai';

  @override
  String get animeFantasySub => 'Magical realms and alternate worlds';

  @override
  String get animeSciFi => 'Sci-Fi & Cyberpunk';

  @override
  String get animeSciFiSub => 'Futuristic technologies and dystopian worlds';

  @override
  String get animeCatalogue => 'Anime catalogue';

  @override
  String get animeSearch => 'Search anime';

  @override
  String get animeAnilistDetails => 'AniList Details';

  @override
  String get animeSortTrending => 'Trending';

  @override
  String get animeSortPopular => 'Most Popular';

  @override
  String get animeSortTop => 'Top Rated';

  @override
  String get animeSortFavorited => 'Most Favorited';

  @override
  String get animeSortNewest => 'Newest';

  @override
  String get animeSortOldest => 'Oldest';

  @override
  String get animeSortTitle => 'Title (A-Z)';

  @override
  String get commonClear => 'Clear';

  @override
  String get animeSearchHint => 'Search anime, movies, OVAs...';

  @override
  String get animeSortBy => 'Sort By';

  @override
  String get animeGenre => 'Genre';

  @override
  String get animeYear => 'Year';

  @override
  String get animeSeason => 'Season';

  @override
  String get animeFormat => 'Format';

  @override
  String get animeStatus => 'Status';

  @override
  String get animeReset => 'Reset';

  @override
  String get animeNoMatch => 'No anime found matching your criteria';

  @override
  String get animeNoMatchBody => 'Try different keywords or clearing filters';

  @override
  String get animeTvSeries => 'Anime TV Series';

  @override
  String get animeMovies => 'Anime Movies';

  @override
  String get animeAddToList => 'ADD TO LIST';

  @override
  String get animeCast => 'Characters & Cast';

  @override
  String get animeRelations => 'Franchise & Relations';

  @override
  String get animeAlsoLike => 'You May Also Like';

  @override
  String get animeWatching => 'Watching';

  @override
  String get animePlan => 'Plan to Watch';

  @override
  String get animeCompleted => 'Completed';

  @override
  String get animeDropped => 'Dropped';

  @override
  String get aboutTitle => 'About Lumora';

  @override
  String get aboutTagline => 'Movies, series and anime in one place';

  @override
  String get aboutBody =>
      'Lumora brings movies, TV series, anime and live TV together in one app, and picks the source that plays fastest for you.';

  @override
  String get aboutTech => 'CORE TECHNOLOGIES';

  @override
  String get aboutTechEngine => 'High-Performance Video Engine';

  @override
  String get aboutTechSources => 'Debrid & Multi-Source Scrapers';

  @override
  String get aboutTechSourcesBody =>
      'Direct high-speed cloud playback via Real-Debrid, TorBox, and Stremio addons.';

  @override
  String get aboutTechGlass => 'Liquid Glass GLSL Shaders';

  @override
  String get aboutTechGlassBody =>
      'Custom real-time optical refraction, lenses, and fluid physics.';

  @override
  String get aboutTechSync => 'Trakt & Cloud Synchronization';

  @override
  String get aboutTechSyncBody =>
      'Cross-platform watchlist, episode tracking, and playback scrobbling.';

  @override
  String get aboutCredits => 'CREDITS & LICENCE';

  @override
  String get aboutZplayCredit => 'Lumora is built on ZPlay by tzero86';

  @override
  String get aboutPlaytorrio => 'Based on PlayTorrio V3';

  @override
  String get aboutPlaytorrioCredit =>
      'Original project by Ayman (@ayman708-UX)';

  @override
  String get aboutFontLicense =>
      'Poppins is bundled under the SIL Open Font License 1.1.';

  @override
  String get aboutTmdb =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get aboutGplBody =>
      'Lumora is a modified version of ZPlay, itself a modified version of PlayTorrio V3, distributed under the GNU General Public License v3.0. Tap to read the licence.';

  @override
  String get updatesUpToDate => 'Lumora is up to date!';

  @override
  String get updatesTitle => 'App Updates & System';

  @override
  String get updatesBody =>
      'Keep Lumora up to date with the latest features, security patches, and performance improvements.';

  @override
  String get updatesChecking => 'Checking for updates...';

  @override
  String get updatesCheck => 'Check for Updates';

  @override
  String get updatesChannels => 'RELEASE CHANNELS';

  @override
  String get updatesStable => 'Official Stable Channel';

  @override
  String get updatesStableBody =>
      'Direct GitHub release distribution with automated checksum verification.';

  @override
  String get updatesInApp => 'Seamless In-App Patching';

  @override
  String get updatesInAppBody =>
      'Downloads and applies executable updates directly without manual file downloads.';

  @override
  String get provTitle => 'Built-in Providers';

  @override
  String get provResetConfirm => 'Reset Providers Order?';

  @override
  String get provResetBody =>
      'This will restore all 45 direct providers to their default order and re-enable any disabled providers.';

  @override
  String get provDefaultMode => 'Default Mode';

  @override
  String get provDefaultModeBody =>
      'Standard auto-sorting across all 45 providers';

  @override
  String get provCustomMode => 'Custom Mode';

  @override
  String get provCustomModeBody =>
      'Manual provider order, toggles & priority scraping';

  @override
  String get provDefault => 'Default';

  @override
  String get provDefaultShort => 'Standard auto-sorting';

  @override
  String get provCustom => 'Custom';

  @override
  String get provCustomShort => 'Manual order & toggles';

  @override
  String get provDefaultActive => 'Default Mode Active';

  @override
  String get provDefaultActiveBody =>
      'In Default mode all providers run at once and results are sorted by resolution (4K, 1080p, 720p) and file size.';

  @override
  String get provSwitchCustom => 'Switch to Custom Mode';

  @override
  String get provPriority => 'Priority Scrape & Result Sorting';

  @override
  String get provPriorityBody =>
      'Providers at the top scrape first, and their results always show at the top, whatever their size or quality.';

  @override
  String get provSearch => 'Search providers (e.g. CineSrc)...';

  @override
  String get provSearch2 => 'Search providers (e.g. CineSrc, Dulo)...';

  @override
  String get provEnableAll => 'Enable All';

  @override
  String get provDisableAll => 'Disable All';

  @override
  String get provClearToReorder => 'Clear search to drag & reorder';

  @override
  String get provMoveUp => 'Move Up';

  @override
  String get provMoveDown => 'Move Down';

  @override
  String get navSeries => 'Series';

  @override
  String get navMovies => 'Movies';

  @override
  String get navAnime => 'Anime';

  @override
  String get navMyList => 'My List';

  @override
  String get navMyListShort => 'My List';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get navMe => 'Me';

  @override
  String get navMore => 'More';

  @override
  String get catTrendingSeries => 'Trending series';

  @override
  String get catCnDrama => 'Chinese dramas';

  @override
  String get catHkDrama => 'Hong Kong dramas';

  @override
  String get catKrDrama => 'Korean dramas';

  @override
  String get catUsDrama => 'American series';

  @override
  String get catTwDrama => 'Taiwanese dramas';

  @override
  String get catJpDrama => 'Japanese dramas';

  @override
  String get catGbDrama => 'British series';

  @override
  String get catTopSeries => 'Top rated series';

  @override
  String get catTrendingMovies => 'Trending films';

  @override
  String get catNowPlaying => 'In cinemas';

  @override
  String get catChineseMovies => 'Chinese-language films';

  @override
  String get catHkMovies => 'Hong Kong films';

  @override
  String get catUsMovies => 'Hollywood';

  @override
  String get catKrMovies => 'Korean films';

  @override
  String get catJpMovies => 'Japanese films';

  @override
  String get catAnimatedMovies => 'Animated films';

  @override
  String get catTopMovies => 'Top rated films';

  @override
  String get catTrendingAnime => 'Trending animation';

  @override
  String get catDonghua => 'Chinese animation';

  @override
  String get catJpAnime => 'Anime';

  @override
  String get catTopAnime => 'Top rated animation';

  @override
  String get catAddToList => 'Add to My List';

  @override
  String get catDetails => 'Details';

  @override
  String get catEmpty =>
      'Nothing to show here yet. These rows come from TMDb; check the TMDb key in Settings.';

  @override
  String get settingsMoreSubtitle =>
      'Manga, books, audiobooks, music and collections';

  @override
  String get homeResume => 'Resume';

  @override
  String homeResumeEpisode(int episode) {
    return 'Resume E$episode';
  }

  @override
  String cwEpisode(int episode) {
    return 'E$episode';
  }

  @override
  String cwSeasonEpisode(int season, int episode) {
    return 'S$season E$episode';
  }

  @override
  String get cwMovie => 'Movie';

  @override
  String get cwRemove => 'Remove from Continue Watching';

  @override
  String get catRecentlyUpdated => 'Recently updated';

  @override
  String get heroSeriesBadge => 'TV';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterClear => 'Clear';

  @override
  String get filterAll => 'All';

  @override
  String get filterRegion => 'Region';

  @override
  String get filterGenre => 'Genre';

  @override
  String get filterYear => 'Year';

  @override
  String get filterSort => 'Sort';

  @override
  String get filterSortPopular => 'Popular';

  @override
  String get filterSortNewest => 'Newest';

  @override
  String get filterSortRating => 'Top rated';

  @override
  String get filterRegionCn => 'Mainland China';

  @override
  String get filterRegionHk => 'Hong Kong';

  @override
  String get filterRegionTw => 'Taiwan';

  @override
  String get filterRegionKr => 'Korea';

  @override
  String get filterRegionJp => 'Japan';

  @override
  String get filterRegionUs => 'US';

  @override
  String get filterRegionGb => 'UK';

  @override
  String get filterRegionTh => 'Thailand';

  @override
  String get filterRegionIn => 'India';

  @override
  String get filterRegionWest => 'Western';

  @override
  String get filterGenreAction => 'Action';

  @override
  String get filterGenreComedy => 'Comedy';

  @override
  String get filterGenreDrama => 'Drama';

  @override
  String get filterGenreRomance => 'Romance';

  @override
  String get filterGenreSciFi => 'Sci-fi';

  @override
  String get filterGenreFantasy => 'Fantasy';

  @override
  String get filterGenreHorror => 'Horror';

  @override
  String get filterGenreThriller => 'Thriller';

  @override
  String get filterGenreCrime => 'Crime';

  @override
  String get filterGenreMystery => 'Mystery';

  @override
  String get filterGenreAdventure => 'Adventure';

  @override
  String get filterGenreWar => 'War';

  @override
  String get filterGenreFamily => 'Family';

  @override
  String get filterGenreDocumentary => 'Documentary';

  @override
  String get filterGenreActionAdventure => 'Action & adventure';

  @override
  String get filterGenreSciFiFantasy => 'Sci-fi & fantasy';

  @override
  String get filterGenreWarPolitics => 'War & politics';

  @override
  String get filterGenreReality => 'Variety';

  @override
  String get filterGenreKids => 'Kids';

  @override
  String get filterYears2020s => '2020s';

  @override
  String get filterYears2010s => '2010s';

  @override
  String get filterYears2000s => '2000s';

  @override
  String get filterYearsOlder => 'Older';

  @override
  String get filterNoResults => 'Nothing matches these filters.';

  @override
  String get filterLoadMore => 'Load more';

  @override
  String get heroMovieBadge => 'Film';

  @override
  String get introOutroTitle => 'Skip intro & credits';

  @override
  String get introOutroButton => 'Intro/credits';

  @override
  String get introOutroAuto => 'Skip intro automatically';

  @override
  String get introOutroOn => 'On';

  @override
  String get introOutroOff => 'Off';

  @override
  String get introOutroIntro => 'Intro ends';

  @override
  String get introOutroOutro => 'Credits start';

  @override
  String get introOutroSetHere => 'Set to now';

  @override
  String get introOutroClear => 'Clear';

  @override
  String get introOutroHint =>
      'Press “Set to now” where the intro ends or the credits start; every episode of this show is skipped the same way.';

  @override
  String get introSkipped => 'Intro skipped';

  @override
  String upNextIn(int seconds) {
    return 'Next episode in ${seconds}s';
  }

  @override
  String get upNextPlayNow => 'Play now';

  @override
  String get upNextCancel => 'Cancel';

  @override
  String get skipIntro => 'Skip Intro';

  @override
  String get skipRecap => 'Skip Recap';

  @override
  String get skipCredits => 'Skip Credits';

  @override
  String get skipPreview => 'Skip Preview';

  @override
  String detailsPlayEpisode(int episode) {
    return 'Play E$episode';
  }

  @override
  String detailsPlaySeasonEpisode(int season, int episode) {
    return 'Play S$season E$episode';
  }

  @override
  String get detailsWatched => 'Watched';

  @override
  String playerTooShort(int minutes) {
    return 'This source is only $minutes min long, not the episode. Pick another source.';
  }

  @override
  String playerTooShortNext(int minutes) {
    return 'This source is only $minutes min long, not the episode. Trying the next one…';
  }

  @override
  String get abkAudiobookDetails => 'Audiobook Details';

  @override
  String get abkChaptersAudioFiles => 'Chapters & Audio Files';

  @override
  String get abkCouldNotLoadChapters => 'Could not load chapters';

  @override
  String get abkNoPlayableChaptersFound => 'No playable chapters found.';

  @override
  String get abkPlayFirstChapter => 'Play First Chapter';

  @override
  String get abkInitializingChapter => 'Initializing chapter...';

  @override
  String get abkFetchingTorrentMetadataPeers =>
      'Fetching torrent metadata & peers...';

  @override
  String get abkAudioPlayerDesignPreset => 'Audio player design preset';

  @override
  String get abkSeekBarScrubberStyle => 'Seek bar scrubber style';

  @override
  String get abkPlayPauseButtonStyle => 'Play pause button style';

  @override
  String get abkOpenDragDropPlayerStudio => 'Open Drag & Drop Player Studio';

  @override
  String get abkCustomizeAudioPlayer => 'Customize Audio Player';

  @override
  String get abkChaptersList => 'Chapters List';

  @override
  String get abkRetryChapter => 'Retry Chapter';

  @override
  String get abkPreviousChapter => 'Previous Chapter';

  @override
  String get abkRewind10s => 'Rewind 10s';

  @override
  String get abkForward10s => 'Forward 10s';

  @override
  String get abkNextChapter => 'Next Chapter';

  @override
  String get abkPauseCaps => 'PAUSE';

  @override
  String get abkPlayCaps => 'PLAY';

  @override
  String get abkFilterChaptersByName => 'Filter chapters by name...';

  @override
  String get abkVolume => 'Volume';

  @override
  String get abkCustomizeAudiobookSection => 'Customize Audiobook Section';

  @override
  String get abkPosterCardDensity => 'Poster Card Density';

  @override
  String get abkAudiobookPosterCardDensity => 'Audiobook poster card density';

  @override
  String get abkFeaturedHeroSpotlightCarousel =>
      'Featured Hero Spotlight Carousel';

  @override
  String get abkMovingAmbientBackgroundGlow => 'Moving Ambient Background Glow';

  @override
  String get abkShowContinueListeningCarousel =>
      'Show \"Continue Listening\" Carousel';

  @override
  String get abkOpenPlayerStudioThemes => 'Open Player Studio & Themes';

  @override
  String get abkAudiobookHub => 'Audiobook Hub';

  @override
  String get abkExploreStreamListenToThousandsOf =>
      'Explore, stream & listen to thousands of stories';

  @override
  String get abkAudiobookGeneratorStudio => 'Audiobook Generator & Studio';

  @override
  String get abkAudiobookCustomizer => 'Audiobook Customizer';

  @override
  String get abkSearchAudiobooksByTitleAuthorOr =>
      'Search audiobooks by title, author, or genre...';

  @override
  String get abkAudiobookGenres => 'Audiobook genres';

  @override
  String get abkSearchResults => 'Search Results';

  @override
  String get abkFeaturedAudiobooks => 'Featured Audiobooks';

  @override
  String get abkScrapingHighQualityAudiobookSources =>
      'Scraping high-quality audiobook sources...';

  @override
  String get abkCouldNotLoadAudiobooks => 'Could not load audiobooks';

  @override
  String get abkNoAudiobooksFoundTryAnotherSearch =>
      'No audiobooks found. Try another search query.';

  @override
  String get abkNowPlayingAudiobook => 'NOW PLAYING AUDIOBOOK';

  @override
  String get abkSpotlightFeatured => 'SPOTLIGHT FEATURED';

  @override
  String get abkListenNow => 'Listen Now';

  @override
  String get abkContinueListening => 'Continue Listening';

  @override
  String get abkAiAudiobookStudioEpubGenerator =>
      'AI Audiobook Studio & EPUB Generator';

  @override
  String get abkGenerateAudiobooksFromEpubsOrImport =>
      'Generate audiobooks from EPUBs or import your own MP3/M4B audiobooks.';

  @override
  String get abkOpenStudio => 'Open Studio';

  @override
  String get abkMyGeneratedUploadedAudiobooks =>
      'My Generated & Uploaded Audiobooks';

  @override
  String get abkStudio => 'Studio';

  @override
  String get abkFailed => 'Failed';

  @override
  String get abkPlay => 'Play';

  @override
  String get abkEpubExceeds250kWords => 'EPUB Exceeds 250k Words';

  @override
  String get abkCancel => 'Cancel';

  @override
  String get abkSplitGenerate => 'Split & Generate';

  @override
  String get abkUploadCompleteGenerationStarted =>
      'Upload complete — AI Audiobook generation started!';

  @override
  String get abkRemove => 'Remove';

  @override
  String get abkAddPersonalAudiobook => 'Add Personal Audiobook';

  @override
  String get abkAudiobookTitle => 'Audiobook Title';

  @override
  String get abkAuthorNarrator => 'Author / Narrator';

  @override
  String get abkSelectCoverArt => 'Select Cover Art';

  @override
  String get abkChangeCover => 'Change Cover';

  @override
  String get abkImportToLibrary => 'Import to Library';

  @override
  String get abkAudiobookStudioGenerator => 'Audiobook Studio & Generator';

  @override
  String get abkAudiobookStudioTabs => 'Audiobook studio tabs';

  @override
  String get abkRefreshStatus => 'Refresh Status';

  @override
  String get abkNoGeneratedAudiobooksYet => 'No generated audiobooks yet';

  @override
  String get abkPickAnEpubAboveToSynthesize =>
      'Pick an EPUB above to synthesize high-quality voice narrations.';

  @override
  String get abkAiNarratorVoiceKokoroEngine =>
      'AI Narrator Voice (Kokoro Engine)';

  @override
  String get abkRescanBooks => 'Rescan Books';

  @override
  String get abkGenerate => 'Generate';

  @override
  String get abkAnalyzingUploadingBook => 'Analyzing & Uploading Book...';

  @override
  String get abkSelectExternalEpubFile => 'Select External EPUB File';

  @override
  String get abkPickAnyEpubFileFromYour =>
      'Pick any .epub file from your device. Large books (>250k words) are auto-split.';

  @override
  String get abkCompleted => 'Completed';

  @override
  String get abkPlayInApp => 'Play in App';

  @override
  String get abkCopyStreamUrl => 'Copy Stream URL';

  @override
  String get abkUploadPersonalAudiobookFiles =>
      'Upload Personal Audiobook Files';

  @override
  String get abkImportYourOwnMp3M4bM4a =>
      'Import your own .mp3, .m4b, .m4a, or .flac audiobooks to listen offline.';

  @override
  String get abkNoPersonalAudiobooksAddedYet =>
      'No personal audiobooks added yet';

  @override
  String get abkTapTheBannerAboveToImport =>
      'Tap the banner above to import audio files from your device.';

  @override
  String get abkDelete => 'Delete';

  @override
  String get bkResumeReading => 'Resume Reading';

  @override
  String get bkReadNow => 'Read Now';

  @override
  String get bkGenerateAiAudiobookTts => 'Generate AI Audiobook (TTS)';

  @override
  String get bkDeleteDownloadedFile => 'Delete downloaded file';

  @override
  String get bkPublisher => 'Publisher';

  @override
  String get bkSeries => 'Series';

  @override
  String get bkLanguage => 'Language';

  @override
  String get bkFileFormat => 'File Format';

  @override
  String get bkSize => 'Size';

  @override
  String get bkDiscoverBooks => 'Discover Books';

  @override
  String get bkCouldNotLoadBooks => 'Could not load books';

  @override
  String get bkNoBooksFound => 'No books found';

  @override
  String get bkTrySearchingForAnotherTitleAuthor =>
      'Try searching for another title, author, or language';

  @override
  String get bkSearchMillionsOfBooksAuthors =>
      'Search millions of books & authors...';

  @override
  String get bkFontEngine => 'Font Engine:';

  @override
  String get bkReaderFontEngine => 'Reader font engine';

  @override
  String get bkCompact => 'Compact';

  @override
  String get bkStandard => 'Standard';

  @override
  String get bkWide => 'Wide';

  @override
  String get bkBookFormats => 'Book formats';

  @override
  String get bkTableOfContentsT => 'Table of Contents (T)';

  @override
  String get bkFocusModeLineByLine => 'Focus Mode (Line-by-Line)';

  @override
  String get bkAppearanceCustomization => 'Appearance & Customization';

  @override
  String get bkToggleFullscreenF => 'Toggle Fullscreen (F)';

  @override
  String get bkPreviousChapterLeftArrow => 'Previous Chapter (Left Arrow)';

  @override
  String get bkNextChapterRightArrow => 'Next Chapter (Right Arrow)';

  @override
  String get bkUnableToOpenBook => 'Unable to open book';

  @override
  String get bkNoReadableChaptersFound => 'No readable chapters found.';

  @override
  String get bkTableOfContents => 'Table of Contents';

  @override
  String get bkNoTableOfContentsAvailable => 'No table of contents available';

  @override
  String get bkBackToLibrary => 'Back to Library';

  @override
  String get bkZoomIn => 'Zoom In';

  @override
  String get bkZoomOut => 'Zoom Out';

  @override
  String get bkFullscreenF => 'Fullscreen (F)';

  @override
  String get bkPreviousPage => 'Previous Page';

  @override
  String get bkNextPage => 'Next Page';

  @override
  String get bkZoomOutCtrl => 'Zoom Out (Ctrl -)';

  @override
  String get bkZoomInCtrl => 'Zoom In (Ctrl +)';

  @override
  String get bkResetZoom => 'Reset Zoom (100%)';

  @override
  String get bkFocusModeActive => 'Focus Mode Active';

  @override
  String get bkExitFocusMode => 'Exit Focus Mode';

  @override
  String get bkExitEsc => 'Exit (Esc)';

  @override
  String get bkTapAboveBelowToMoveKeys =>
      'Tap above/below to move · ↑ ↓ keys to navigate';

  @override
  String get bkPreviousLineUpArrow => 'Previous Line (Up Arrow)';

  @override
  String get bkNextLineDownArrowSpace => 'Next Line (Down Arrow / Space)';

  @override
  String get bkCloseSettings => 'Close Settings';

  @override
  String get bkAppearance => 'Appearance';

  @override
  String get bkReset => 'Reset ✓';

  @override
  String get bkResetToDefaults => 'Reset to Defaults';

  @override
  String get bkSerif => 'Serif';

  @override
  String get bkSans => 'Sans';

  @override
  String get bkDyslexic => 'Dyslexic';

  @override
  String get bkMono => 'Mono';

  @override
  String get bkFontFamily => 'Font Family';

  @override
  String get bkFontSize => 'Font Size';

  @override
  String get bkLineHeight => 'Line Height';

  @override
  String get bkAlignment => 'Alignment';

  @override
  String get bkFirstLineIndent => 'First-Line Indent';

  @override
  String get bkReadingThemes => 'Reading Themes';

  @override
  String get bkLight => 'Light';

  @override
  String get bkSepia => 'Sepia';

  @override
  String get bkDark => 'Dark';

  @override
  String get bkAmoled => 'AMOLED';

  @override
  String get bkReaderBrightness => 'Reader Brightness';

  @override
  String get bkPageMargins => 'Page Margins';

  @override
  String get bkBalanced => 'Balanced';

  @override
  String get bkReadingMode => 'Reading Mode';

  @override
  String get bkContinuousScroll => 'Continuous Scroll';

  @override
  String get bkPaginatedTurns => 'Paginated Turns';

  @override
  String get mgChapters => 'Chapters';

  @override
  String get mgNoChaptersFound => 'No chapters found.';

  @override
  String get mgChapter => 'Chapter';

  @override
  String get mgPreviousChapterPage => 'Previous chapter page';

  @override
  String get mgNextChapterPage => 'Next chapter page';

  @override
  String get mgSearchChapters => 'Search chapters...';

  @override
  String get mgClearChapterSearch => 'Clear chapter search';

  @override
  String get mgStartReading => 'Start Reading';

  @override
  String get mgBack => 'Back';

  @override
  String get mgCustomizeMangaSection => 'Customize Manga Section';

  @override
  String get mgClose => 'Close';

  @override
  String get mgPosterCardDensity => 'Poster Card Density';

  @override
  String get mgMangaPosterCardDensity => 'Manga poster card density';

  @override
  String get mgMovingAmbientBackgroundGlow => 'Moving Ambient Background Glow';

  @override
  String get mgShowContinueReadingSlider => 'Show \"Continue Reading\" Slider';

  @override
  String get mgShowContentTypeBadgeOnPosters =>
      'Show Content Type Badge on Posters';

  @override
  String get mgMoreAppearanceReaderSettings =>
      'More Appearance & Reader Settings';

  @override
  String get mgContinueReading => 'Continue Reading';

  @override
  String get mgSearchResults => 'Search Results';

  @override
  String get mgDiscoverManga => 'Discover Manga';

  @override
  String get mgFilteredByCategory => 'Filtered by category';

  @override
  String get mgResetToAllCategories => 'Reset to All Categories';

  @override
  String get mgNoMangaFound => 'No manga found';

  @override
  String get mgSearchMangaManhwaManhua => 'Search Manga, Manhwa, Manhua...';

  @override
  String get mgClearSearch => 'Clear search';

  @override
  String get mgRemoveFromContinueReading => 'Remove from Continue Reading';

  @override
  String get mgReaderSettingsLayout => 'Reader Settings & Layout';

  @override
  String get mgReadingOrientationMode => 'Reading Orientation Mode';

  @override
  String get mgReadingOrientationModeLabel => 'Reading orientation mode';

  @override
  String get mgPageReadingWidthConstraint => 'Page Reading Width Constraint';

  @override
  String get mgPageReadingWidthConstraintLabel =>
      'Page reading width constraint';

  @override
  String get mgReaderBackgroundAtmosphere => 'Reader Background Atmosphere';

  @override
  String get mgShowPageDeckPreviewsDrawer => 'Show Page Deck Previews Drawer';

  @override
  String get mgShowNextChapterDeckCard => 'Show Next Chapter Deck Card';

  @override
  String get mgNoPagesFoundForThisChapter => 'No pages found for this chapter.';

  @override
  String get mgYouAreAllCaughtUp => 'You are all caught up!';

  @override
  String get mgUpNext => 'UP NEXT';

  @override
  String get mgChapterFinished => 'CHAPTER FINISHED';

  @override
  String get mgReadNextChapter => 'Read Next Chapter';

  @override
  String get mgBackToMangaDetails => 'Back to Manga Details';

  @override
  String get mgPageDeckPreview => 'Page Deck Preview';

  @override
  String get mgReaderCustomization => 'Reader Customization';

  @override
  String get mgPreviousChapter => 'Previous Chapter';

  @override
  String get mgZoomOut => 'Zoom Out (-)';

  @override
  String get mgZoomIn => 'Zoom In (+)';

  @override
  String get mgTogglePageDeck => 'Toggle Page Deck';

  @override
  String get mgNextChapter => 'Next Chapter';

  @override
  String get mgReaderAtmosphere => 'Reader Atmosphere:';

  @override
  String get mgWebtoonScroll => 'Webtoon Scroll';

  @override
  String get mgHorizontalLtr => 'Horizontal LTR';

  @override
  String get mgHorizontalRtl => 'Horizontal RTL';

  @override
  String get musHome => 'Home';

  @override
  String get musSearch => 'Search';

  @override
  String get musBrowse => 'Browse';

  @override
  String get musRadio => 'Radio';

  @override
  String get musLibrary => 'Library';

  @override
  String get musLoadingArtistDetails => 'Loading artist details...';

  @override
  String get musLoadingAlbum => 'Loading album...';

  @override
  String get musLoadingPlaylist => 'Loading playlist...';

  @override
  String get musSeekBack5s => 'Seek -5s';

  @override
  String get musSeekForward5s => 'Seek +5s';

  @override
  String get musMuted => 'Muted';

  @override
  String get musUnmuted => 'Unmuted';

  @override
  String get musNewPlaylist => 'New Playlist';

  @override
  String get musEnterPlaylistTitle => 'Enter playlist title...';

  @override
  String get musCancel => 'Cancel';

  @override
  String get musCreate => 'Create';

  @override
  String get musDownloadedOfflineTapToRemove =>
      'Downloaded Offline (Tap to Remove)';

  @override
  String get musDownloadingQueued => 'Downloading / Queued...';

  @override
  String get musDownloadTrackOffline => 'Download Track Offline';

  @override
  String get musSaveToPlaylist => 'Save to Playlist';

  @override
  String get musNoCustomPlaylistsYet => 'No custom playlists yet';

  @override
  String get musCreateFirstPlaylist => 'Create First Playlist';

  @override
  String get musSavedToLibrary => 'Saved to Library';

  @override
  String get musRemovedFromLibrary => 'Removed from Library';

  @override
  String get musNewAlbumReleases => 'New Album Releases';

  @override
  String get musCuratedChartsMixes => 'Curated Charts & Mixes';

  @override
  String get musSearchResults => 'Search results';

  @override
  String get musSearchToFindTracksArtistsAlbums =>
      'Search to find tracks, artists, albums and playlists';

  @override
  String get musSongs => 'Songs';

  @override
  String get musHipHopRap => 'Hip-Hop & Rap';

  @override
  String get musElectronicEdm => 'Electronic & EDM';

  @override
  String get musChillLofiBeats => 'Chill Lofi Beats';

  @override
  String get musRBSoul => 'R&B & Soul';

  @override
  String get musSoundtracksGaming => 'Soundtracks & Gaming';

  @override
  String get musJazzBlues => 'Jazz & Blues';

  @override
  String get musBrowseMoodsGenres => 'Browse Moods & Genres';

  @override
  String get musPopRadio => 'Pop Radio';

  @override
  String get musRapHipHop => 'Rap & Hip-Hop';

  @override
  String get musRockMix => 'Rock Mix';

  @override
  String get musDanceElectro => 'Dance & Electro';

  @override
  String get musRBStation => 'R&B Station';

  @override
  String get musLofiAmbient => 'Lofi & Ambient';

  @override
  String get musHeavyMetalStation => 'Heavy Metal Station';

  @override
  String get musJazzClub => 'Jazz Club';

  @override
  String get musYourLibrary => 'Your Library';

  @override
  String get musNoLikedSongsYet => 'No liked songs yet';

  @override
  String get musLikedSongs => 'Liked Songs';

  @override
  String get musDownloadedSongs => 'Downloaded Songs';

  @override
  String get musCustomPlaylists => 'Custom Playlists';

  @override
  String get musRecentlyPlayed => 'Recently Played';

  @override
  String get musSearchShort => 'Search…';

  @override
  String get musSearchMusic => 'Search music…';

  @override
  String get musSearchSongsArtistsAlbumsPlaylists =>
      'Search songs, artists, albums, playlists...';

  @override
  String get musMusicPlayerStudio => 'Music Player Studio';

  @override
  String get musMusicAtmosphereSettings => 'Music Atmosphere Settings';

  @override
  String get musAppSettings => 'App Settings';

  @override
  String get musMusicView => 'Music view';

  @override
  String get musAudioSourceQuality => 'Audio Source & Quality';

  @override
  String get musChooseExtractionEngine =>
      'Choose your preferred music extraction engine';

  @override
  String get musFlacLosslessQobuzHiRes => 'FLAC Lossless (Qobuz Hi-Res)';

  @override
  String get musStudioMasterQualityDesc =>
      'Studio master quality up to 24-bit/192kHz with zero compression';

  @override
  String get musLossless => 'LOSSLESS';

  @override
  String get musYoutubeAudio => 'YouTube Audio';

  @override
  String get musYoutubeAudioDesc =>
      'High-speed audio extraction with intelligent track & duration matching';

  @override
  String get musFast => 'FAST';

  @override
  String get musTopChartHit => 'TOP CHART HIT';

  @override
  String get musPlayNow => 'Play Now';

  @override
  String get musTrendingArtists => 'Trending Artists';

  @override
  String get musDownloadedOffline => 'Downloaded (Offline)';

  @override
  String get musQueuedForDownload => 'Queued for download';

  @override
  String get musDownloadTrack => 'Download Track';

  @override
  String get musSyncedLyrics => 'Synced Lyrics';

  @override
  String get musNoLyricsFoundForThisTrack => 'No lyrics found for this track.';

  @override
  String get musClear => 'Clear';

  @override
  String get musQueueIsEmpty => 'Queue is empty';

  @override
  String get musPlayAll => 'Play All';

  @override
  String get musTopSongs => 'Top Songs';

  @override
  String get musAlbumsDiscography => 'Albums & Discography';

  @override
  String get musAlbum => 'ALBUM';

  @override
  String get musPlayAlbum => 'Play Album';

  @override
  String get musDownloadAlbum => 'Download Album';

  @override
  String get musPlayPlaylist => 'Play Playlist';

  @override
  String get musDownloadPlaylist => 'Download Playlist';

  @override
  String get musDownloadAll => 'Download All';

  @override
  String get musNoTracksInThisPlaylistYet => 'No tracks in this playlist yet';

  @override
  String get musPlayingQueue => 'Playing Queue';

  @override
  String get musTogglePlayPause => 'Toggle Play / Pause';

  @override
  String get musSeek5SecondsBackward => 'Seek -5 seconds backward';

  @override
  String get musSeek5SecondsForward => 'Seek +5 seconds forward';

  @override
  String get musToggleMuteUnmute => 'Toggle Mute / Unmute';

  @override
  String get musToggleQueueDrawer => 'Toggle Queue Drawer';

  @override
  String get musToggleFullscreenNowPlaying => 'Toggle Fullscreen Now Playing';

  @override
  String get musShowShortcuts => 'Show Shortcuts';

  @override
  String get musKeyboardShortcuts => 'Keyboard Shortcuts';

  @override
  String get musShuffle => 'Shuffle';

  @override
  String get musSearchOffline => 'Search offline...';

  @override
  String get musNoOfflineDownloadsYetTapThe =>
      'No offline downloads yet.\nTap the download icon on any song, album, or playlist to listen offline.';

  @override
  String get musDeleteFromDownloads => 'Delete from downloads';

  @override
  String get musDeleteDownloadedSong => 'Delete Downloaded Song';

  @override
  String get musDelete => 'Delete';

  @override
  String get tvLiveBadge => 'LIVE';

  @override
  String get tvCancelSelection => 'Cancel Selection';

  @override
  String get tvManageDeleteChannels => 'Manage / Delete Channels';

  @override
  String get tvDeselectAll => 'Deselect All';

  @override
  String get tvSelectAll => 'Select All';

  @override
  String get tvStop => 'Stop';

  @override
  String get tvScanningPortals => 'Scanning all verified portals in parallel…';

  @override
  String get tvNoAliveStreams => 'No alive streams discovered yet.';

  @override
  String get tvTapScanMoreHint =>
      'Tap \"Scan More Portals\" to discover fresh feeds.';

  @override
  String get tvClearSearch => 'Clear Search';

  @override
  String get tvFreeBadge => 'FREE';

  @override
  String get tvWatchLive => 'Watch Live';

  @override
  String get tvScanMore => 'Scan More';

  @override
  String get tvChannelListAndSchedule => 'Channel list and programme schedule';

  @override
  String get tvDescPremier =>
      'Top worldwide sporting events and championship channels';

  @override
  String get tvDescBoxing =>
      'Sky Sports Box Office, DAZN, TNT Sports Box Office & free combat channels';

  @override
  String get tvDescUs =>
      'ABC News Live, CBS News 24/7, NBC News Now, Weather Channel & more';

  @override
  String get tvDescUk => 'BBC One UK, ITV News, Sky News UK, Channel 4 & more';

  @override
  String get tvDescIntlSports =>
      'Willow Cricket, Fox Soccer Plus, GolTV, TUDN, Viaplay & more';

  @override
  String get tvManagePortalsPlaylists => 'Manage Portals & Playlists';

  @override
  String get tvSearchChannels => 'Search Channels';

  @override
  String get tvSettings => 'Settings';

  @override
  String get tvMultiStreamsTooltip => 'Multi Streams (Multi-View Window)';

  @override
  String get tvMultiStreams => 'Multi Streams';

  @override
  String get tvQuickChannels => 'Quick Channels';

  @override
  String get tvAddQuickChannel => 'Add Quick Channel';

  @override
  String get tvAddChannel => 'Add Channel';

  @override
  String get tvChannelName => 'Channel Name';

  @override
  String get tvRequired => 'Required';

  @override
  String get tvShortCodeOptional => 'Short Code (optional)';

  @override
  String get tvCategory => 'Category';

  @override
  String get tvKeywordsCommaSeparated => 'Keywords (comma-separated)';

  @override
  String get tvKeywordsHint => 'e.g. cnn, news, international';

  @override
  String get tvGradient => 'Gradient';

  @override
  String get tvCancel => 'Cancel';

  @override
  String get tvConnectingToStream => 'Connecting to stream…';

  @override
  String get tvChannelNoSources => 'This channel has no stream sources.';

  @override
  String get tvFeedWouldNotPlay => 'This feed would not play.';

  @override
  String get tvFeedStalled => 'This feed stalled and would not keep playing.';

  @override
  String get tvAspectFitContain => 'ASPECT: FIT (CONTAIN)';

  @override
  String get tvAspectFillZoomCrop => 'ASPECT: FILL (ZOOM / CROP)';

  @override
  String get tvAspectStretchFill => 'ASPECT: STRETCH (FILL)';

  @override
  String get tvReconnecting => 'Reconnecting…';

  @override
  String get tvMuted => 'MUTED';

  @override
  String get tvPlayerLive => 'LIVE';

  @override
  String get tvPlayerVod => 'VOD';

  @override
  String get tvCategoryChannels => 'Category Channels';

  @override
  String get tvAlternativeFeeds => 'Alternative Feeds';

  @override
  String get tvExitFullscreenF11 => 'Exit Fullscreen (F11)';

  @override
  String get tvFullscreenF11 => 'Fullscreen (F11)';

  @override
  String get tvSeekBack10 => 'Seek -10s';

  @override
  String get tvSeekForward10 => 'Seek +10s';

  @override
  String get tvFitShort => 'FIT';

  @override
  String get tvZoomShort => 'ZOOM';

  @override
  String get tvStretchShort => 'STRETCH';

  @override
  String get tvStreamFeeds => 'Stream Feeds';

  @override
  String get tvCustomizePortalsModal => 'Customize Portals Modal';

  @override
  String get tvCardDisplayStyle => 'Card Display Style';

  @override
  String get tvShowPortalExpiry => 'Show Portal Expiry Date';

  @override
  String get tvShowMaxConnections => 'Show Max Connections';

  @override
  String get tvDefaultStartingTab => 'Default Starting Tab';

  @override
  String get tvPortalsAndPlaylists => 'Portals & Playlists';

  @override
  String get tvIptvPortalsAndPlaylists => 'IPTV Portals & Playlists';

  @override
  String get tvCustomizeModalStyle => 'Customize Modal Style';

  @override
  String get tvFinding => 'Finding…';

  @override
  String get tvGenerate => 'Generate';

  @override
  String get tvGeneratePortals => 'Generate Portals';

  @override
  String get tvChoosePortalSource => 'Choose Portal Source';

  @override
  String get tvCloudVault => 'Cloud Vault';

  @override
  String get tvCloudVaultDesc =>
      'High-speed cloud database with live IPTV servers';

  @override
  String get tvRedditCommunities => 'Reddit Communities';

  @override
  String get tvRedditDesc => 'Scrapes live shared pastes from subreddits';

  @override
  String get tvPortalsAdd => 'Add';

  @override
  String get tvAddPortal => 'Add Portal';

  @override
  String get tvDone => 'Done';

  @override
  String get tvManage => 'Manage';

  @override
  String get tvPortalsDeselectAll => 'Deselect All';

  @override
  String get tvPortalsSelectAll => 'Select All';

  @override
  String get tvDeleteAll => 'Delete All';

  @override
  String get tvAddXtreamPortal => 'Add Xtream Codes Portal';

  @override
  String get tvUsername => 'Username';

  @override
  String get tvPassword => 'Password';

  @override
  String get tvShowPassword => 'Show Password';

  @override
  String get tvHidePassword => 'Hide Password';

  @override
  String get tvCopyLogin => 'Copy Login (url:user:pass)';

  @override
  String get tvRemoveFavorite => 'Remove Favorite';

  @override
  String get tvAddToFavorites => 'Add to Favorites';

  @override
  String get tvRemovePortal => 'Remove Portal';

  @override
  String get tvAddM3u => 'Add M3U';

  @override
  String get tvAddM3uUrl => 'Add M3U URL';

  @override
  String get tvAddM3uSubscription => 'Add M3U Playlist Subscription';

  @override
  String get tvPlaylistName => 'Playlist Name';

  @override
  String get tvM3uUrlLabel => 'M3U / M3U8 URL';

  @override
  String get tvNoM3uPlaylists => 'No M3U playlists saved.';

  @override
  String get tvCopyPlaylistUrl => 'Copy Playlist URL';

  @override
  String get tvRemovePlaylist => 'Remove Playlist';

  @override
  String get tvIptvPortal => 'IPTV Portal';

  @override
  String get tvCustomizePortalBrowser => 'Customize Portal Browser';

  @override
  String get tvChannelLayoutMode => 'Channel Stream Layout Mode';

  @override
  String get tvGridColumns => 'Grid Stream Columns';

  @override
  String get tvShowChannelLogos => 'Show Channel Stream Logos';

  @override
  String get tvShowEpgNowPlaying => 'Show EPG \"Now Playing\" Snippet';

  @override
  String get tvShowCategoryCounts => 'Show Category Stream Counts';

  @override
  String get tvFavoritesStar => '⭐ Favorites';

  @override
  String get tvLiveChannels => 'Live Channels';

  @override
  String get tvMovies => 'Movies';

  @override
  String get tvSeries => 'Series';

  @override
  String get tvBrowserLive => 'LIVE';

  @override
  String get tvBrowserVod => 'VOD';

  @override
  String get tvBrowserSeriesBadge => 'SERIES';

  @override
  String get tvSelectCategory => 'Select Category';

  @override
  String get tvFilterCategories => 'Filter categories…';

  @override
  String get tvBrowserBack => 'Back';

  @override
  String get tvLiveTv => 'Live TV';

  @override
  String get tvTvSeries => 'TV Series';

  @override
  String get tvSearchChannelsHint => 'Search channels…';

  @override
  String get tvCheckHealth => 'Check Health';

  @override
  String get tvCustomizeBrowserLayout => 'Customize Portal Browser Layout';

  @override
  String get tvCustomize => 'Customize';

  @override
  String get tvLive => 'Live';

  @override
  String get tvSearchInCategory => 'Search in this category…';

  @override
  String get tvCouldNotLoadPortal => 'Could not load this portal';

  @override
  String get tvNoFavoritedChannels => 'No Favorited Channels';

  @override
  String get tvFavoritesHint =>
      'Tap the star icon on any channel to save it to your Favorites.';

  @override
  String get tvNoStreamsInCategory => 'No streams available in this category.';

  @override
  String get tvEpgNow => 'NOW: ';

  @override
  String get tvEpgNext => '   NEXT: ';

  @override
  String get tvLiveStreamFeed => 'Live Stream Feed';

  @override
  String get tvRemoveFromFavorites => 'Remove from Favorites';

  @override
  String get tvBrowserAddToFavorites => 'Add to Favorites';

  @override
  String get tvCouldNotLoadEpisodes => 'Could not load episodes';

  @override
  String get tvSearchBack => 'Back';

  @override
  String get tvSearchHint => 'Search 60+ live channels, leagues, networks…';

  @override
  String get tvChannelCategories => 'Channel categories';

  @override
  String get tvNoChannelsMatch => 'No channels match your search.';

  @override
  String get tvLiveBroadcast => 'Live broadcast';

  @override
  String get tvUpcomingOnChannel => 'Upcoming On This Channel';

  @override
  String get tvNothingElseListed => 'Nothing else listed for this channel.';

  @override
  String get tvNoProgrammeGuide => 'No programme guide for this channel yet.';

  @override
  String get tvFindLiveStreams => 'Find Live Streams';

  @override
  String get tvGuideLive => 'LIVE';

  @override
  String get tvWatchLiveStream => 'Watch Live Stream';

  @override
  String get tvScheduledProgramme => 'Scheduled programme';

  @override
  String get aniPlayEp1Modal => 'Play Ep 1';

  @override
  String get aniJumpToEpModal => 'Jump to ep #';

  @override
  String get aniPlayEp1 => 'Play Ep 1';

  @override
  String get aniJumpToEp => 'Jump to ep #';

  @override
  String get aniGeneralTab => '🇯🇵 General';

  @override
  String get aniArabicAnimeTab => '🇸🇦 Arabic Anime';

  @override
  String get aniSettings => 'Settings';

  @override
  String get aniWatchS1E1 => 'Watch S1:E1';

  @override
  String get aniArabicToggle => '🇸🇦 Arabic';

  @override
  String get aniAnimeToggle => '🇯🇵 Anime';

  @override
  String get aniOvasOnasSpecials => 'OVAs, ONAs & Specials';

  @override
  String get aniTrendingAnime => 'Trending Anime';

  @override
  String get aniPopularThisSeason => 'Popular This Season';

  @override
  String get aniAllTimeTopRated => 'All-Time Top Rated';

  @override
  String get aniCascadingExtractors => 'Cascading native anime extractors…';

  @override
  String get aniSubtitleOrDub => 'Subtitle or dub';

  @override
  String get aniStreamAll => 'All';

  @override
  String get aniSources => 'Sources';

  @override
  String get aniExtractingStreams =>
      'Extracting MegaPlay, VidWish, AllAnime & Miruro streams...';

  @override
  String get aniRetryScraping => 'Retry Scraping';

  @override
  String get aniStreamSource => 'Stream Source';

  @override
  String get aniStreamDubBadge => 'DUB';

  @override
  String get aniStreamSubBadge => 'SUB';

  @override
  String get aiAnalyzingStorylines =>
      'Analyzing your favorite storylines & themes...';

  @override
  String get aiStudyingPreferences =>
      'Studying your storytelling and mood preferences...';

  @override
  String get aiFindingMatches => 'Finding high-precision cinema matches...';

  @override
  String get aiPolishingRecs =>
      'Polishing your personalized recommendations...';

  @override
  String get aiBack => 'Back';

  @override
  String get aiRecommendationQuiz => 'Recommendation Quiz';

  @override
  String get aiRetake => 'Retake';

  @override
  String get aiWhatDoYouLike => 'What do you like to watch?';

  @override
  String get aiQuizIntro =>
      'Rate 3 or more movies or TV shows. Choose what you liked or disliked, and select key elements to generate pinpoint AI recommendations.';

  @override
  String get aiAddAnotherTitle => 'Add Another Title';

  @override
  String get aiRate3ToUnlock => 'Rate 3 Titles to Unlock Recommendations';

  @override
  String get aiRemoveTitle => 'Remove this title';

  @override
  String get aiSearchHint => 'Search movie or TV series...';

  @override
  String get aiNeedIdeas => 'Need ideas?';

  @override
  String get aiHowWasExperience => 'How was your experience with it?';

  @override
  String get aiLovedIt => 'Loved it ❤️';

  @override
  String get aiLikedIt => 'Liked it 👍';

  @override
  String get aiItWasOkay => 'It was okay 😐';

  @override
  String get aiDisliked => 'Disliked 👎';

  @override
  String get aiWhatStoodOut =>
      'What stood out? (Pick key elements or write a note):';

  @override
  String get aiFetchingTags => 'Fetching reason tags...';

  @override
  String get aiNotesHint => 'Additional notes or specifics (optional)...';

  @override
  String get aiSynthesizing =>
      'Synthesizing taste vectors with multi-signal AI...';

  @override
  String get aiYourMatches => 'Your Personalized Matches';

  @override
  String get plyMedia3EngineError => 'Playback error on the Media3 engine';

  @override
  String get plyRefusedByProvider => 'Refused by provider';

  @override
  String get plyNoticeRefused => 'refused this source';

  @override
  String get plyNotReadyYet => 'Not ready yet';

  @override
  String get plyNoticeNotReady => 'does not have this source ready yet';

  @override
  String get plyAccountRejected => 'Account rejected';

  @override
  String get plyNoticeAccountRejected => 'rejected the account';

  @override
  String get plyTemporarilyUnavailable => 'Temporarily unavailable';

  @override
  String get plyNoticeCouldNotServe => 'could not serve this source';

  @override
  String get plyWaitingForData => '⏳ Waiting for this source to deliver data';

  @override
  String get plyBlackScreenSoftware =>
      '⚠️ Black screen detected • Switched to Software Mode';

  @override
  String get plyDecoderResynced =>
      '⚠️ Decoder failed at this resolution • Hardware decoding re-synced';

  @override
  String get plyMaxBoost => 'MAX BOOST';

  @override
  String get plyBoost => 'BOOST';

  @override
  String get ply2xSpeed => '2X Speed';

  @override
  String get plyAspectFillCrop => 'ASPECT: FILL / CROP (ZOOM)';

  @override
  String get plyAspectStretch => 'ASPECT: STRETCH TO FILL';

  @override
  String get plyAspectFit => 'ASPECT: FIT TO SCREEN';

  @override
  String get plyDirector => 'DIRECTOR';

  @override
  String get plyDismiss => 'Dismiss';

  @override
  String get plyAudioDubLanguage => 'Audio & Dub Language';

  @override
  String get plyUnknownSource => 'Unknown';

  @override
  String get mnzRestoring => 'Restoring...';

  @override
  String get mnzPlaybackError => 'Playback error';

  @override
  String get mnzSwitchingFeed => 'Switching feed...';

  @override
  String get mnzSwitchFailed => 'Switch failed';

  @override
  String get mnzCustomStream => 'Custom Stream';

  @override
  String get mnzConnecting => 'Connecting...';

  @override
  String get mnzSelectChannel => 'Select Channel';

  @override
  String get mnzStreamDetails => 'Stream Details';

  @override
  String get mnzStreamName => 'Stream Name';

  @override
  String get mnzLiveStream => 'Live Stream';

  @override
  String get mnzDiscoveringStream => 'Discovering stream...';

  @override
  String get mnzNoActiveFeeds => 'No active feeds found';

  @override
  String get mnzConnectingToFeed => 'Connecting to feed...';

  @override
  String get mnzFailedToLoadFeed => 'Failed to load feed';

  @override
  String get mnzCancel => 'Cancel';

  @override
  String get mnzAdd => 'Add';

  @override
  String get mnzAddLiveFeed => 'Add Live Stream Feed';

  @override
  String get mnzBackToLiveTv => 'Back to Live TV';

  @override
  String get mnzMultiStreams => 'MULTI STREAMS';

  @override
  String get mnzPreviousLayout => 'Previous Layout';

  @override
  String get mnzNextLayout => 'Next Layout';

  @override
  String get mnzDoneRearranging => 'Done Rearranging';

  @override
  String get mnzRearrangeStreams => 'Rearrange Streams';

  @override
  String get mnzMuteAll => 'Mute All';

  @override
  String get mnzClearAllWindows => 'Clear All Windows';

  @override
  String get dscCustom => 'Custom';

  @override
  String get dscNoAdultSources =>
      'No 18+ sources yet.\nMark an addon as 18+ in Settings → Addons, or install one.';

  @override
  String get dscNoTitlesInCatalog => 'No titles found in this catalog';

  @override
  String get dscSelectRequiredFilter => 'Select Required Filter';

  @override
  String get dscCancel => 'Cancel';

  @override
  String get dscDiscover => 'Discover';

  @override
  String get dscSearchHint => 'Search...';

  @override
  String get dscSearchCatalog => 'Search catalog';

  @override
  String get colFranchises => 'Franchises';

  @override
  String get colMemoryLane => 'Memory Lane';

  @override
  String get colCuratedTitle => 'Curated Franchises & Eras';

  @override
  String get colCuratedSubtitle => 'Hand-picked film packs, in watch order.';

  @override
  String get colBack => 'Back';

  @override
  String get calBack => 'Back';

  @override
  String get calTitle => 'TV Shows Airing Calendar';

  @override
  String get calSubtitle =>
      'Upcoming broadcast & streaming episodes with live network filters';

  @override
  String get calFilterShows => 'Filter shows...';

  @override
  String get calToday => 'TODAY';

  @override
  String get calTomorrow => 'TOMORROW';

  @override
  String get calNetwork => 'Network:';

  @override
  String get calNoEpisodesThisDay => 'No episodes found for this day';

  @override
  String get calTryAllNetworks =>
      'Try selecting \"All\" or a different network above';

  @override
  String get calSelectAnotherDay =>
      'Select another day from the timeline above';

  @override
  String get hmCinemaUniverse => 'Your Cinema Universe';

  @override
  String get hmAiTasteQuiz => 'AI Taste Quiz';

  @override
  String get hmTvAiringCalendar => 'TV Airing Calendar';

  @override
  String get ctlNoItemsFound => 'No items found';

  @override
  String get ctlSearchHint => 'Search...';

  @override
  String get ctlAll => 'All';

  @override
  String get araResolvingServers => 'Resolving servers…';

  @override
  String get araCrackingServerMap => 'Cracking Arabic server map…';

  @override
  String get stgaAddStremioAddon => 'Add Stremio Addon';

  @override
  String get stgaPasteStremioManifestHint =>
      'Paste the Stremio addon manifest.json URL to install catalogs, metadata, streams, or subtitles.';

  @override
  String get stgaCancel => 'Cancel';

  @override
  String get stgaInstall => 'Install';

  @override
  String get stgaRemoveAddonBody =>
      'Its catalogs and metadata will be removed from your home page.';

  @override
  String get stgaRemove => 'Remove';

  @override
  String get stgaInstallRepoPluginsBody =>
      'Would you like to install all plugins from this repository now so their streaming sources become available immediately on the watch screen?';

  @override
  String get stgaBrowseLater => 'Browse Later';

  @override
  String get stgaInstallAllNow => 'Install All Now';

  @override
  String get stgaInstallingPlugins => 'Installing Plugins';

  @override
  String get stgaPreparingRuntime => 'Preparing runtime...';

  @override
  String get stgaAddCloudStreamRepo => 'Add CloudStream Repository';

  @override
  String get stgaPasteRepoUrlHint =>
      'Paste the repository URL (supports cloudstreamrepo://, repo.json, or plugins.json).';

  @override
  String get stgaBrowseMarketplace => 'Browse Marketplace';

  @override
  String get stgaAddRepository => 'Add Repository';

  @override
  String get stgaCsExtensionWillUninstall =>
      'This CloudStream extension will be uninstalled.';

  @override
  String get stgaRemoveRepoBody =>
      'Plugins from this repository will not be deleted, but repository updates will no longer be fetched.';

  @override
  String get stgaStremioAddons => 'Stremio Addons';

  @override
  String get stgaStremioTabDescription =>
      'Addons provide metadata, catalogs, and streaming sources. Hold and drag to reorder priority. Providers higher up load and appear first in watch sources.';

  @override
  String get stgaInstalledProvidersAddons => 'INSTALLED PROVIDERS & ADDONS';

  @override
  String get stgaNoAddonsInstalled => 'No Addons Installed';

  @override
  String get stgaNoAddonsHint =>
      'Click \"Add Addon\" above to install a Stremio manifest URL.';

  @override
  String get stgaDebridAddons => 'DEBRID ADDONS';

  @override
  String get stgaDebridAddonsDescription =>
      'Installs the addon for the Debrid provider selected in Settings and fills your saved key in at request time, so the key is never stored twice.';

  @override
  String stgaDebridAddonsPlaceholderNote(String realdebrid) {
    return 'Addons that take the key as a plain URL parameter accept a $realdebrid style placeholder. Addons that hide it inside a base64 config blob have to be pasted fully configured instead.';
  }

  @override
  String get stgaCloudStreamTabDescription =>
      'CloudStream (.cs3) extensions provide stream providers directly from popular media sites. Extensions run locally in a sandboxed sidecar or native ART engine.';

  @override
  String get stgaCsEngineReady => 'CloudStream Engine Ready';

  @override
  String get stgaRuntimeSetupRequired => 'Runtime Setup Required';

  @override
  String get stgaNativeEngineActive =>
      'Native engine active and listening for queries.';

  @override
  String get stgaDownloadingRuntime => 'Downloading runtime components...';

  @override
  String get stgaRequiresRuntimeHost =>
      'Requires runtime host to execute .cs3 bytecode.';

  @override
  String get stgaRequiresSidecarRuntime =>
      'Requires sidecar runtime to execute .cs3 bytecode.';

  @override
  String get stgaRepoMarketplace => 'Repository Marketplace';

  @override
  String get stga45PlusRepos => '45+ Repos';

  @override
  String get stgaRepoMarketplaceDescription =>
      'Browse curated Turkish, 3rabi, English, Hindi & global repos with direct install links.';

  @override
  String get stgaBrowseAvailablePlugins => 'Browse Available Plugins';

  @override
  String get stgaDeselectAll => 'Deselect All';

  @override
  String get stgaSelectAll => 'Select All';

  @override
  String get stgaInstalledExtensions => 'INSTALLED EXTENSIONS';

  @override
  String get stgaInstalledCsExtensions => 'INSTALLED CLOUDSTREAM EXTENSIONS';

  @override
  String get stgaNoExtensionsInstalled => 'No Extensions Installed';

  @override
  String get stgaNoExtensionsHint =>
      'Click \"Browse Available Plugins\" to find and install extensions.';

  @override
  String get stgaRepositories => 'REPOSITORIES';

  @override
  String get stgaNoReposHint =>
      'No custom repositories added. Click \"Add Repository\" to subscribe to a CloudStream repository.';

  @override
  String get stgaInstallAllFromRepoTooltip =>
      'Install all plugins from this repository';

  @override
  String get stgaBrowseRepoPlugins => 'Browse repository plugins';

  @override
  String get stgaRemoveRepository => 'Remove repository';

  @override
  String get stgaSetupEngine => 'Setup Engine';

  @override
  String get stgaBuiltinTorrServer =>
      'Built-in TorrServer P2P streaming engine';

  @override
  String get stgaBuiltinHttpScrapers =>
      'Built-in multi-source fast HTTP scrapers';

  @override
  String get stgaMoveUpPriority => 'Move up in priority';

  @override
  String get stgaMoveDownPriority => 'Move down in priority';

  @override
  String get stgaBuiltinTorrent => 'BUILT-IN TORRENT';

  @override
  String get stgaBuiltinHttp => 'BUILT-IN HTTP';

  @override
  String get stgaRemoveAddon => 'Remove addon';

  @override
  String get stgaFunctions => 'FUNCTIONS';

  @override
  String get stgaCatalogs => 'Catalogs';

  @override
  String get stgaSearch => 'Search';

  @override
  String get stgaSources => 'Sources';

  @override
  String get stgaSubtitles => 'Subtitles';

  @override
  String get stgaInstalling => 'Installing...';

  @override
  String get stgaAddAddon => 'Add Addon';

  @override
  String get stgaConnecting => 'Connecting...';

  @override
  String get stgaConnect => 'Connect';

  @override
  String get stgaDisconnect => 'Disconnect';

  @override
  String get stgaConnected => 'Connected';

  @override
  String get stgaNoDebridProviderYet => 'No Debrid provider is set up yet';

  @override
  String get stgaSetupDebridFirst =>
      'Set up a Debrid provider in Settings first, then come back to connect it.';

  @override
  String get stgaCsDefaultDescription =>
      'CloudStream scraping & streaming provider';

  @override
  String get stgaAvailablePlugins => 'Available Plugins';

  @override
  String get stgaAvailableCsPlugins => 'Available CloudStream Plugins';

  @override
  String get stgaSearchPluginsHint =>
      'Search plugins (e.g. Sflix, SuperStream)...';

  @override
  String get stgaNoPluginsInRepos =>
      'No plugins found in added repositories.\nPlease add a CloudStream repository URL first.';

  @override
  String get stgaInstalled => 'Installed';

  @override
  String get stgaUninstall => 'Uninstall';

  @override
  String get stgaInstallRepoPluginsNowQ =>
      'Would you like to install plugins from this repository now?';

  @override
  String get stgaLater => 'Later';

  @override
  String get stgaInstallingRepoPlugins => 'Installing Repository Plugins';

  @override
  String get stgaInstallingExtensions => 'Installing extensions...';

  @override
  String get stgaMarketplace => 'Marketplace';

  @override
  String get stgaRefreshListFromWeb => 'Refresh list from web';

  @override
  String get stgaSearchRepoOrPluginHint =>
      'Search repository or plugin (e.g. Turkish, 3rabi, DiziBox, Shahid)...';

  @override
  String get stgaAdded => 'Added';

  @override
  String get stgaAddingRepository => 'Adding Repository...';

  @override
  String get stgaInstallRepository => 'Install Repository';

  @override
  String get stgaInstallAllPlugins => 'Install All Plugins';

  @override
  String get stgaBrowse => 'Browse';

  @override
  String get stgaHidePlugins => 'Hide plugins';

  @override
  String get stgaPastedKeyFromClipboard => 'Pasted key from clipboard';

  @override
  String get stgaDismiss => 'Dismiss';

  @override
  String get stgaDebridPageDescription =>
      'Stream torrents and magnet links instantly through high-speed cloud debrid providers without local peer-to-peer downloading.';

  @override
  String get stgaUseDebridForStreams => 'Use Debrid for Streams';

  @override
  String get stgaRouteTorrentsThroughCloud =>
      'Route torrent links through cloud servers';

  @override
  String get stgaSelectDebridAndSaveKey =>
      'Select an active Debrid provider and save your API key below.';

  @override
  String get stgaDebridDisabledLocal =>
      'Debrid streaming disabled. Using local engine.';

  @override
  String get stgaDebridToggleNote =>
      'When enabled, all torrents from Lumora and Stremio addons are resolved exclusively through your active Debrid provider without touching the local torrent engine.';

  @override
  String get stgaActiveProvider => 'ACTIVE PROVIDER';

  @override
  String get stgaSelectDefaultDebrid => 'Select Default Debrid Provider';

  @override
  String get stgaDebridProviderNote =>
      'Lumora will send requests to this provider when streaming.';

  @override
  String get stgaProviderCredentials => 'PROVIDER CREDENTIALS';

  @override
  String get stgaGetTokenRealDebrid =>
      'Get token from real-debrid.com/apitoken';

  @override
  String get stgaGetKeyTorBox => 'Get key from torbox.app/settings';

  @override
  String get stgaGetKeyAllDebrid => 'Get key from alldebrid.com/apikeys';

  @override
  String get stgaAccountConnected => 'Account: Connected';

  @override
  String get stgaGetKeyPremiumize => 'Get key from premiumize.me/account';

  @override
  String get stgaGetKeyDebridLink =>
      'Get key from debrid-link.com/webapp/apikey';

  @override
  String get stgaActiveBadge => 'ACTIVE';

  @override
  String get stgaPasteApiKeyToken => 'Paste API Key / Token';

  @override
  String get stgaClear => 'Clear';

  @override
  String get stgaShowKey => 'Show Key';

  @override
  String get stgaHideKey => 'Hide Key';

  @override
  String get stgaPasteFromClipboard => 'Paste from Clipboard';

  @override
  String get stgaSave => 'Save';

  @override
  String get stgaPurposeWyzie =>
      'Searches the Wyzie subtitle catalogue for movies and episodes.';

  @override
  String get stgaPurposeAudiobookSearch =>
      'Mints the anonymous token the Audionest audiobook search API requires.';

  @override
  String get stgaPurposeAudiobookService =>
      'Bearer for the Audionest audiobook search endpoint.';

  @override
  String get stgaPurposePaper2audio =>
      'Firebase key for the paper2audio PDF to audiobook backend.';

  @override
  String get stgaPurposeVidgod =>
      'Bearer for the VidGod cloud cache behind the built-in streams.';

  @override
  String get stgaPurposeFilms365 =>
      'Bearer for the Films365 direct stream API.';

  @override
  String get stgaPurposeTraktSecret =>
      'Exchanges the device code for a Trakt access token.';

  @override
  String get stgaSourceUser => 'Your key is in use.';

  @override
  String get stgaSourceBuildTime => 'Supplied at build time for this build.';

  @override
  String get stgaSourceInherited => 'Running on the value this app ships with.';

  @override
  String get stgaSourceNone => 'No key available, so this source stays off.';

  @override
  String get stgaPastedKeyFromClipboardDot => 'Pasted key from clipboard.';

  @override
  String get stgaKeysYouCanObtain => 'KEYS YOU CAN OBTAIN';

  @override
  String get stgaBorrowedCredentials => 'BORROWED CREDENTIALS';

  @override
  String get stgaRelated => 'RELATED';

  @override
  String get stgaSavedBadge => 'SAVED';

  @override
  String get stgaClearKey => 'Clear key';

  @override
  String get stgaTmdbApiKey => 'TMDb API Key';

  @override
  String get stgaTmdbRowDescription =>
      'Ranks the 1990s rails and covers the scraper metadata lookups.';

  @override
  String get stgbGpuUpscaling => 'GPU Upscaling';

  @override
  String get stgbUpscalingPresets => 'UPSCALING PRESETS';

  @override
  String get stgbDisabledOff => 'Disabled (Off)';

  @override
  String get stgbStandardPlaybackDesc =>
      'Standard video playback without GLSL neural filters. Lowest GPU overhead.';

  @override
  String get stgbStandard => 'Standard';

  @override
  String get stgbModeAFast => 'Mode A — Fast / Balanced';

  @override
  String get stgbModeAFastDesc =>
      'Sharp line restoration & 2x CNN upscale. Best for 1080p anime and balanced GPU power.';

  @override
  String get stgbRecommended => 'Recommended';

  @override
  String get stgbModeAHq => 'Mode A — High Quality (Ultra)';

  @override
  String get stgbModeAHqDesc =>
      'Maximum perceptual fidelity using Very Large CNNs. Recommended for discrete GPUs (RTX/Radeon).';

  @override
  String get stgbUltraQuality => 'Ultra Quality';

  @override
  String get stgbModeBSoft => 'Mode B — Soft / Denoise';

  @override
  String get stgbModeBSoftDesc =>
      'Smooth line reconstruction and artifact reduction. Best for blurry, compressed, or older anime.';

  @override
  String get stgbDenoise => 'Denoise';

  @override
  String get stgbModeCDeblur => 'Mode C — Deblur & Scale';

  @override
  String get stgbModeCDeblurDesc =>
      'Aggressive deblurring and scaling. Best for 480p and 720p low-resolution anime episodes.';

  @override
  String get stgbDeblur => 'Deblur';

  @override
  String get stgbFsrSmooth => 'FSR 1.0 — Smooth';

  @override
  String get stgbLiveAction => 'Live action';

  @override
  String get stgbFsrSharp => 'FSR 1.0 — Sharp';

  @override
  String get stgbUseWithCare => 'Use with care';

  @override
  String get stgbPipelineCompat => 'PIPELINE & COMPATIBILITY';

  @override
  String get stgbPlaybackStartApply => 'Playback Start Application';

  @override
  String get stgbPlaybackStartApplyDesc =>
      'Shaders are configured before playback begins. Changing a preset applies to the next opened stream or video.';

  @override
  String get stgbHwDecoderAccel => 'Hardware Decoder Acceleration';

  @override
  String get stgbHwDecoderAccelDesc =>
      'media_kit uses native auto-safe hardware decoding to feed GPU texture memory directly into the GLSL shader pass.';

  @override
  String get stgbPlatformRecommendation => 'Platform Recommendation';

  @override
  String get stgbPlatformRecommendationDesc =>
      'For desktop (Windows/macOS/Linux), Mode A HQ provides crystal-clear lines. For mobile devices, Mode A Fast offers smooth 60fps playback.';

  @override
  String get stgbHwAccelDecoding => 'HARDWARE ACCELERATION & DECODING';

  @override
  String get stgbAllPlatforms => 'All Platforms';

  @override
  String get stgbAutoSafeRecommended => 'Auto-Safe (Recommended)';

  @override
  String get stgbAutoSafeDesc =>
      'GPU hardware decoding with safe driver fallbacks. Best efficiency for most PCs and devices.';

  @override
  String get stgbDefault => 'Default';

  @override
  String get stgbSoftwareDecoding => 'Software Decoding (Crash-Proof)';

  @override
  String get stgbSoftwareDecodingDesc =>
      'Pure CPU decoding via FFmpeg libavcodec. Eliminates black screens and driver lockups on older GPUs or virtual machines.';

  @override
  String get stgbFullyReliable => '100% Reliable';

  @override
  String get stgbDirectHardware => 'Direct Hardware';

  @override
  String get stgbDirectHardwareDesc =>
      'Direct GPU decoding (Direct3D 11 / MediaCodec / VAAPI). Fastest on modern high-end graphics.';

  @override
  String get stgbMaxGpu => 'Max GPU';

  @override
  String get stgbPlaybackEngine => 'PLAYBACK ENGINE';

  @override
  String get stgbMpvOnly => 'mpv only';

  @override
  String get stgbExoPlayerFastest => 'Android\'s ExoPlayer (Fastest at 4K)';

  @override
  String get stgbExoPlayerDesc =>
      'Decodes straight into a surface, so 4K arrives without being copied out of the decoder first. On a 2 GB television that is the difference between 904 ms and over 1,900 ms of delay, and between no dropped frames and one and a half a second. Subtitles are rendered by Android, so the styling options below do not apply here.';

  @override
  String get stgbFasterAt4k => 'Faster at 4K';

  @override
  String get stgbMpvFullSubtitle => 'mpv (Full subtitle control)';

  @override
  String get stgbMpvDesc =>
      'The bundled engine. Plays torrents and live streams, offers the complete subtitle styling surface below, and supports the upscaling presets. Decoded frames are copied through a texture, which is what makes 4K stutter on small televisions.';

  @override
  String get stgbMostFeatures => 'Most features';

  @override
  String get stgbTorrentsLiveUseMpv => 'Torrents and live TV always use mpv';

  @override
  String get stgbTorrentsLiveUseMpvDesc =>
      'Whichever engine you pick here, torrent sources and live channels play through mpv, because Android\'s player cannot open them. The choice applies to films, series and anything else fetched over plain HTTP.';

  @override
  String get stgbAutoRecoverBlack => 'Auto-Recover Black Screens';

  @override
  String get stgbActiveWatchdog => 'Active Watchdog';

  @override
  String get stgbActiveWatchdogDesc =>
      'Monitors stream startup. If audio plays for 2.5s without video frames, or a GPU decoder error occurs, the player recovers automatically. On Android it switches to software decoding only up to 1080p and re-syncs the hardware decoder above that, because a software 4K decoder needs more memory than the device has. A source that is merely not delivering data yet is waited on rather than treated as a decoder fault.';

  @override
  String get stgbAndroidRenderingEngine => 'ANDROID RENDERING ENGINE';

  @override
  String get stgbDirectSurface => 'Direct Surface (SurfaceView)';

  @override
  String get stgbZeroCopy => 'Zero-Copy';

  @override
  String get stgbOffTextureView => 'Off (TextureView)';

  @override
  String get stgbDirectSurfaceDesc =>
      'Uses Flutter SurfaceProducer to render frames directly to hardware surface without texture blitting. Significantly boosts 4K/60fps playback and reduces battery usage on Android. (Keep disabled if your device experiences display glitches).';

  @override
  String get stgbAppearanceIntro =>
      'Fine-tune the visual atmosphere, custom wallpaper background and interface layouts.';

  @override
  String get stgbInterfaceAtmosphere => 'INTERFACE & ATMOSPHERE';

  @override
  String get stgbCustomBgWallpaper => 'Custom Background & Wallpaper';

  @override
  String get stgbCustomBgWallpaperDesc =>
      'Upload custom photos, choose curated dark wallpapers, and blend theme ambient lighting';

  @override
  String get stgbCustomActive => 'Custom Active';

  @override
  String get stgbDefaultTheme => 'Default Theme';

  @override
  String get stgbLiquidGlassSetup => 'Liquid Glass Setup';

  @override
  String get stgbLiquidGlassSetupDesc =>
      'Adjust hover impact, wobble spring physics, lens refraction, and chromatic aberration';

  @override
  String get stgbDisabled => 'Disabled';

  @override
  String get stgbHomeUiThemes => 'Home Page UI';

  @override
  String get stgbHomeUiThemesDesc =>
      '\"Because you have on your list\" smart slider, hero spotlight, and card density';

  @override
  String get stgbLiveTvSportsUi => 'Live TV & Sports UI';

  @override
  String get stgbLiveTvSportsUiDesc =>
      'Broadcast hero spotlight, channel card density, category ordering, and live badge styling';

  @override
  String get stgbSpotlightOn => 'Spotlight ON';

  @override
  String get stgbCompact => 'Compact';

  @override
  String get stgbContent => 'CONTENT';

  @override
  String get stgbMangaUiReader => 'Manga UI & Reader Atmosphere';

  @override
  String get stgbMangaUiReaderDesc =>
      'Ambient moving lighting, card density, reading layout widths, webtoon/horizontal modes, and page deck preview';

  @override
  String get stgbWebtoon => 'Webtoon';

  @override
  String get stgbHorizontal => 'Horizontal';

  @override
  String get stgbPlayback => 'PLAYBACK';

  @override
  String get stgbAudiobookUiStudio => 'Audiobook UI & Player Studio';

  @override
  String get stgbAudiobookUiStudioDesc =>
      'Hero spotlight, 5 distinct player designs, drag & drop modular studio, waveform canvas scrubber, and custom controls';

  @override
  String get stgbMusicUiStudio => 'Music UI & Player Studio';

  @override
  String get stgbMusicUiStudioDesc =>
      'Hero spotlight, lossless badges, and fullscreen player studio for layout, seekbar, physics & turntable styling';

  @override
  String get stgbDiagnostics => 'DIAGNOSTICS';

  @override
  String get stgbGraphicsBackend => 'Graphics Backend';

  @override
  String get stgbRestartToApplyBackend =>
      'Restart the app to apply — the backend is fixed when the engine starts.';

  @override
  String get stgbSkiaRecommended => 'Skia (Recommended)';

  @override
  String get stgbSimklIntro =>
      'Connect your Simkl account to synchronize Movies, TV Shows, and Anime watchlists, continue watching progress, and custom lists.';

  @override
  String get stgbConnected => 'CONNECTED';

  @override
  String get stgbDisconnected => 'DISCONNECTED';

  @override
  String get stgbCheckingCredentials => 'Checking credentials...';

  @override
  String get stgbSimklSignInPin =>
      'Sign in with PIN to activate Simkl cloud sync';

  @override
  String get stgbDisconnect => 'Disconnect';

  @override
  String get stgbConnectSimkl => 'Connect Simkl';

  @override
  String get stgbSimklEnterPin => 'Enter this PIN code at simkl.com/pin:';

  @override
  String get stgbOpenSimklPin => 'Open simkl.com/pin';

  @override
  String get stgbSimklWaitingPin => 'Waiting for PIN approval on simkl.com...';

  @override
  String get stgbCloudSyncControls => 'Cloud Sync Controls';

  @override
  String get stgbSyncSimklWatchlist =>
      'Sync Simkl Watchlist & Continue Watching';

  @override
  String get stgbSimklManualPull =>
      'Manually triggers an immediate pull from Simkl';

  @override
  String get stgbTraktIntro =>
      'Connect your Trakt.tv account to seamlessly synchronize your watch history, watchlist, continue watching progress, and ratings across all your devices.';

  @override
  String get stgbTraktSignIn => 'Sign in to activate two-way cloud sync';

  @override
  String get stgbPairAccount => 'Pair Account';

  @override
  String get stgbTraktEnterCode =>
      'Enter this activation code at trakt.tv/activate:';

  @override
  String get stgbOpenTraktActivate => 'Open trakt.tv/activate';

  @override
  String get stgbTraktWaitingAuth => 'Waiting for authorization on trakt.tv...';

  @override
  String get stgbSyncWatchlistNow => 'Sync Watchlist & Continue Watching Now';

  @override
  String get stgbTraktManualPull =>
      'Manually triggers an immediate pull from Trakt';

  @override
  String get stgbConnectedStatus => 'Connected';

  @override
  String get stgbTmdbKeyRejected => 'That key was rejected by TMDb';

  @override
  String get stgbTmdbUnreachable => 'Could not reach TMDb';

  @override
  String get stgbTmdbPasteFirst => 'Paste a TMDb API key first.';

  @override
  String get stgbTmdbKeySaved =>
      'TMDb key saved. The 1990s rails now use TMDb ranks.';

  @override
  String get stgbTmdbKeyCleared =>
      'TMDb key cleared. The built-in 1990s picks are back.';

  @override
  String get stgbPastedKey => 'Pasted key from clipboard.';

  @override
  String get stgbDismiss => 'Dismiss';

  @override
  String get stgbTmdbCredential => 'TMDB CREDENTIAL';

  @override
  String get stgbCredits => 'CREDITS';

  @override
  String get stgbSaved => 'SAVED';

  @override
  String get stgbTmdbSavedOnDevice =>
      'Saved on this device. Enter a new key to replace it.';

  @override
  String get stgbTmdbFreeKey => 'Free key from themoviedb.org';

  @override
  String get stgbTmdbPasteHint => 'Paste your TMDb API key';

  @override
  String get stgbShowKey => 'Show Key';

  @override
  String get stgbHideKey => 'Hide Key';

  @override
  String get stgbPasteFromClipboard => 'Paste from Clipboard';

  @override
  String get stgbSaveAndTest => 'Save and test';

  @override
  String get stgbTmdbKeySavedTest =>
      'A key is saved. Run a test to confirm it still works.';

  @override
  String get stgbTmdbNoKey =>
      'No key saved yet, so the built-in picks are in use.';

  @override
  String get stgbClearKey => 'Clear key';

  @override
  String get stgbAboutPoweredBy =>
      'Powered by embedded media_kit / libmpv with hardware-accelerated decoding.';

  @override
  String get stgbPlayerStudio => 'Player Studio';

  @override
  String get stgbCustomAudiobookStudio => 'Custom Audiobook Player Studio';

  @override
  String get stgbAudiobookStudioDesc =>
      'Drag components, transform seekbars, customize button physics';

  @override
  String get stgbApplyAsActivePlayer => 'Apply As Active Player';

  @override
  String get stgbStudioDesigner => 'Studio Designer';

  @override
  String get stgbLivePreviewCanvas => 'Live Preview Canvas';

  @override
  String get stgbTestLiveCanvas => 'Test Live Canvas';

  @override
  String get stgbBackToCustomizer => 'Back to Customizer';

  @override
  String get stgbLiveInteractiveCanvas => 'LIVE INTERACTIVE CANVAS';

  @override
  String get stgbCustomStudio => 'CUSTOM STUDIO';

  @override
  String get stgbPremadeChaptersPanel => 'Premade Chapters Panel';

  @override
  String get stgbPauseCaps => 'PAUSE';

  @override
  String get stgbPlayCaps => 'PLAY';

  @override
  String get stgbPremadeChaptersPreview => 'Premade Chapters Panel Preview';

  @override
  String get stgbDragDropLayout => 'Drag & Drop Layout';

  @override
  String get stgbSeekBarCanvas => 'Seek Bar Canvas';

  @override
  String get stgbPlayButtonPhysics => 'Play Button & Physics';

  @override
  String get stgbArtworkFrame => 'Artwork & Frame';

  @override
  String get stgbArtworkVinylFrame => 'Artwork & Vinyl Frame';

  @override
  String get stgbChapterBookTitles => 'Chapter & Book Titles';

  @override
  String get stgbSeekBarScrubberCanvas => 'Seek Bar Scrubber Canvas';

  @override
  String get stgbPrimaryControlsAudiobook =>
      'Primary Controls (Play, Pause, Skip ±10s)';

  @override
  String get stgbSecondaryControlsAudiobook =>
      'Secondary Controls (Speed Pill & Volume)';

  @override
  String get stgbPremadeChaptersButton => 'Premade Chapters Panel Button';

  @override
  String get stgbDragDropArranger => 'Drag & Drop Component Arranger';

  @override
  String get stgbAudiobookArrangerDesc =>
      'Hold and drag any block to reorder the vertical layout of your audio player in real-time.';

  @override
  String get stgbSeekBarStyles => 'Seek Bar Canvas & Scrubber Styles';

  @override
  String get stgbSeekBarStylesDesc =>
      'Select how your progress bar and scrubber render inside your custom player canvas.';

  @override
  String get stgbPlayPauseStyle => 'Play / Pause Button Style';

  @override
  String get stgbHoverTouchPhysics => 'Hover & Touch Physics';

  @override
  String get stgbPhysicsPlayground => 'Live Touch & Hover Physics Playground';

  @override
  String get stgbArtworkDisplayMode => 'Artwork Display Mode';

  @override
  String get stgbColorThemesAccents => 'COLOR THEMES & ACCENTS';

  @override
  String get stgbAmbientLightingGlows =>
      'AMBIENT BACKGROUND LIGHTING & MOVING GLOWS';

  @override
  String get stgbDiscoveryAudiobookPosters => 'DISCOVERY & AUDIOBOOK POSTERS';

  @override
  String get stgbChooseAudioPreset => 'CHOOSE AUDIO PLAYER PRESET';

  @override
  String get stgbMakeCustomAudiobookPlayer =>
      'MAKE YOUR CUSTOM AUDIOBOOK PLAYER (DRAG & DROP STUDIO)';

  @override
  String get stgbEnableMovingAtmosphere => 'Enable Moving Ambient Atmosphere';

  @override
  String get stgbLightingFlowPattern => 'Lighting Flow Pattern';

  @override
  String get stgbGlowStrengthOpacity => 'Glow Strength / Opacity';

  @override
  String get stgbMotionDriftSpeed => 'Motion Drift Speed';

  @override
  String get stgbLiveAtmospherePreview => 'Live Atmosphere Preview';

  @override
  String get stgbShowHeroCarousel => 'Show Hero Spotlight Carousel';

  @override
  String get stgbAudiobookHeroDesc =>
      'Featured bestselling audiobook showcase at the top of the hub';

  @override
  String get stgbShowContinueListening =>
      'Show \"Continue Listening\" Carousel';

  @override
  String get stgbContinueListeningDesc =>
      'Quick resume cards with chapter progress bar and direct play';

  @override
  String get stgbAudiobookCardDensity => 'Audiobook Poster Card Density';

  @override
  String get stgbShowGenreBadges => 'Show Quick Genre & Category Badges';

  @override
  String get stgbShowAudiobookRuntime =>
      'Show Audiobook Runtime / Total Duration';

  @override
  String get stgbPosterHoverGlowElevation =>
      'Poster Card Hover Glow & Elevation';

  @override
  String get stgbOpenStudio => 'Open Studio';

  @override
  String get stgbVisualPlayerStudio => 'Visual Custom Player Studio';

  @override
  String get stgbFullStudio => 'FULL STUDIO';

  @override
  String get stgbVisualPlayerStudioDesc =>
      'Drag & drop layout elements, procedural waveform canvases, liquid glass buttons, and premade chapters panel in real-time.';

  @override
  String get stgbEnterPlayerStudio => 'Enter Custom Player Studio';

  @override
  String get stgbInteractiveStudioPreview => 'Interactive Studio Preview';

  @override
  String get stgbLiveCaps => 'LIVE';

  @override
  String get stgbSeekBarScrubberStyle => 'Seek Bar / Scrubber Style';

  @override
  String get stgbPlayPauseStyling => 'Play / Pause Button Styling';

  @override
  String get stgbArtworkDisplayStyle => 'Artwork Display Style';

  @override
  String get stgbButtonHoverPhysics => 'Button Hover & Touch Physics';

  @override
  String get stgbPlayerLayoutComponents =>
      'Player Layout Components (Drag to Arrange)';

  @override
  String get stgbPlayerLayoutComponentsDesc =>
      'Hold and drag any block to reorder how controls appear inside your player';

  @override
  String get stgbLiquidGlassPlayerBlur =>
      'Liquid Glass Player Blur & Refraction';

  @override
  String get stgbShowSpeedSelector =>
      'Show Playback Speed Selector (0.5x - 2.5x)';

  @override
  String get stgbShowSkipButtons => 'Show Skip Forward/Rewind Buttons (±10s)';

  @override
  String get stgbShowChaptersDrawerButton =>
      'Show Quick Chapters Sliding Drawer Button';

  @override
  String get stgbLaunchFullStudio => 'Launch Full Custom Player Studio';

  @override
  String get stgbAudiobookCoverDeck => 'Audiobook Cover Artwork Deck';

  @override
  String get stgbTitleAuthorChapter => 'Title, Author & Chapter Label';

  @override
  String get stgbSeekBarWaveformScrubber =>
      'Seek Bar & Waveform Canvas Scrubber';

  @override
  String get stgbMainControlsCluster =>
      'Main Play / Pause / Skip (±10s) Cluster';

  @override
  String get stgbSpeedVolumeControls => 'Speed Selector & Volume Controls';

  @override
  String get stgbPremadeChaptersTrigger =>
      'Premade Sliding Chapters Panel Trigger';

  @override
  String get stgbBgUploadedApplied =>
      'Background image uploaded and applied across all UI!';

  @override
  String get stgbEnterValidImageUrl =>
      'Please enter a valid HTTP or HTTPS image URL.';

  @override
  String get stgbCustomBgUrlApplied => 'Custom background URL applied!';

  @override
  String get stgbCustomBgIntro =>
      'Upload your own photo or choose a curated wallpaper. Theme colors and moving ambient lights softly blend into the background for a unified look.';

  @override
  String get stgbUploading => 'Uploading...';

  @override
  String get stgbUploadPhotoFromDevice => 'Upload Photo from Device';

  @override
  String get stgbResetToDefaultBg => 'Reset to Default Background';

  @override
  String get stgbBgResetDefault => 'Background reset to default theme.';

  @override
  String get stgbPasteImageUrlHint => 'Or paste image URL (https://...)';

  @override
  String get stgbApply => 'Apply';

  @override
  String get stgbCuratedDarkWallpapers => 'CURATED DARK WALLPAPERS';

  @override
  String get stgbWallpaperBlendControls =>
      'WALLPAPER & LIGHT BLENDING CONTROLS';

  @override
  String get stgbPhotoVisibility => 'Photo Visibility / Darkness';

  @override
  String get stgbPhotoSoftBlur => 'Photo Soft Blur';

  @override
  String get stgbThemeTintOverlay => 'Theme Color Tint Overlay';

  @override
  String get stgbBlendAmbientLights => 'Blend Moving Ambient Lights';

  @override
  String get stgbBlendAmbientLightsDesc =>
      'Softly illuminates and animates theme lights over your wallpaper';

  @override
  String get stgbCustomBgWallpaperCaps => 'CUSTOM BACKGROUND & WALLPAPER';

  @override
  String get stgbCustomWallpaperBlend => 'Custom Wallpaper & Lighting Blend';

  @override
  String get stgbCustomBgActiveBlend =>
      'Custom background active with ambient light blending';

  @override
  String get stgbUploadOrChooseWallpaper =>
      'Upload photos or choose curated dark wallpapers';

  @override
  String get stgbSmartRecsCaps =>
      'SMART RECOMMENDATIONS (\"BECAUSE YOU HAVE ON YOUR LIST\")';

  @override
  String get stgbCuratedCollections => 'CURATED COLLECTIONS';

  @override
  String get stgbHeroBannerSpotlight => 'HERO BANNER & SPOTLIGHT';

  @override
  String get stgbPosterCardsDensity => 'POSTER CARDS & DENSITY';

  @override
  String get stgbHeaderShortcuts => 'HEADER SHORTCUTS & BUTTONS';

  @override
  String get stgbLiveLightingPreview => 'LIVE LIGHTING ENGINE PREVIEW';

  @override
  String get stgbMovingAmbientLights => 'Moving Ambient Lights & Glows';

  @override
  String get stgbMovingAmbientLightsDesc =>
      'Drifting faded light waves & floating color orbs in background';

  @override
  String get stgbLightingPatternPosition => 'Lighting Pattern & Position';

  @override
  String get stgbGlowStrengthIntensity => 'Glow Strength / Intensity';

  @override
  String get stgbMotionFlowSpeed => 'Motion Flow Speed';

  @override
  String get stgbSmartRecommendations => 'Smart Recommendations';

  @override
  String get stgbSmartRecommendationsDesc =>
      'Configure personalized & algorithmic recommendation sliders';

  @override
  String get stgbBecauseYouHave => '\"Because You Have...\" (My List)';

  @override
  String get stgbBecauseYouHaveDesc =>
      'BestSimilar recommendations based on titles saved in My List';

  @override
  String get stgbBecauseYoureWatching => '\"Because You\'re Watching...\"';

  @override
  String get stgbBecauseYoureWatchingDesc =>
      'BestSimilar recommendations based on active Continue Watching titles';

  @override
  String get stgbTraktRecommendations => 'Trakt Recommendations';

  @override
  String get stgbTraktRecommendationsDesc =>
      'Personalized recommendations computed by Trakt';

  @override
  String get stgbRequiresTraktLogin =>
      'Requires Trakt login in Settings -> Trakt';

  @override
  String get stgbSimklRecommendations => 'Simkl Recommendations';

  @override
  String get stgbSimklRecommendationsDesc =>
      'Top-rated & personalized suggestions from Simkl';

  @override
  String get stgbRequiresSimklLogin =>
      'Requires Simkl login in Settings -> Simkl';

  @override
  String get stgbRecSlidersPosition =>
      'Recommendation Sliders Position on Home Page';

  @override
  String get stgbCollections => 'Collections';

  @override
  String get stgbCollectionsDesc =>
      'Show curated collection rails on the Home page';

  @override
  String get stgbShowHeroBanner => 'Show Hero Spotlight Banner';

  @override
  String get stgbShowHeroBannerDesc =>
      'Featured rotation banner at the top of the home page';

  @override
  String get stgbSpotlightStyle => 'Spotlight Style';

  @override
  String get stgbAutoRotateSpotlight => 'Auto-Rotate Spotlight';

  @override
  String get stgbAutoRotateSpotlightDesc =>
      'Cycles through featured titles automatically';

  @override
  String get stgbAmbientBackdropLighting => 'Ambient Backdrop Lighting';

  @override
  String get stgbAmbientBackdropLightingDesc =>
      'Soft diffused color glow behind active hero poster';

  @override
  String get stgbPosterSizeDensity => 'Poster Size & Grid Density';

  @override
  String get stgbShowImdbBadges => 'Show IMDB Rating Badges';

  @override
  String get stgbShowImdbBadgesDesc =>
      'Display rating star pill on poster corners';

  @override
  String get stgbPosterHoverZoom => 'Poster Hover Zoom Scale';

  @override
  String get stgbTvAiringCalendar => 'TV Airing Calendar';

  @override
  String get stgbTvAiringCalendarDesc =>
      'Show TV Calendar buttons on Home bar & sliders';

  @override
  String get stgbAiRecQuiz => 'AI Recommendation Quiz';

  @override
  String get stgbAiRecQuizDesc => 'Show AI Quiz button on Home & Search bars';

  @override
  String get stgbReset => 'Reset';

  @override
  String get stgbEnableLiquidGlass => 'Enable Liquid Glass';

  @override
  String get stgbEnableLiquidGlassDesc =>
      'Real-time refraction shaders, jelly springs, and lenses';

  @override
  String get stgbPresets => 'PRESETS';

  @override
  String get stgbPhysicsOptical => 'PHYSICS & OPTICAL PARAMETERS';

  @override
  String get stgbHoverScaleImpact => 'Hover Scale Impact';

  @override
  String get stgbHoverScaleImpactDesc =>
      'Magnification amount applied to the player glass controls on hover';

  @override
  String get stgbWobbleElasticity => 'Wobble & Fluid Elasticity';

  @override
  String get stgbWobbleElasticityDesc =>
      'Spring bounce intensity and deformation responsiveness';

  @override
  String get stgbRefractionIndex => 'Optical Refraction Index';

  @override
  String get stgbRefractionIndexDesc =>
      'Light bending and background warp index inside glass lenses';

  @override
  String get stgbLensMagnification => 'Lens Magnification';

  @override
  String get stgbLensMagnificationDesc =>
      'Underlying zoom factor seen through the glass volume';

  @override
  String get stgbChromaticAberration => 'Chromatic Aberration (Prism Split)';

  @override
  String get stgbChromaticAberrationDesc =>
      'Separates RGB spectrum colors along optical glass bevels';

  @override
  String get stgbFrostedGlassBlur => 'Frosted Glass Blur';

  @override
  String get stgbFrostedGlassBlurDesc =>
      'Gaussian blur diffusion applied behind glass components';

  @override
  String get stgbSpecularShimmer => 'Specular Light & Shimmer';

  @override
  String get stgbSpecularShimmerDesc =>
      'Glossy specular reflection and border illumination intensity';

  @override
  String get stgbBorderWidth => 'Border Width';

  @override
  String get stgbBorderWidthDesc =>
      'Thickness of the refractive outer boundary edge';

  @override
  String get stgbLiveInteractivePreview => 'LIVE INTERACTIVE PREVIEW';

  @override
  String get stgbPreviewEnableGlass => 'PREVIEW (ENABLE GLASS ABOVE)';

  @override
  String get stgbHoverTapPreview =>
      'Hover or tap the icons to preview spring wobble & scale';

  @override
  String get stgbLiveSpotlightHero => 'LIVE SPOTLIGHT & HERO BANNER';

  @override
  String get stgbChannelCardsDensity => 'CHANNEL CARDS & POSTER DENSITY';

  @override
  String get stgbSectionsCategoryManager => 'SECTIONS & CATEGORY MANAGER';

  @override
  String get stgbPortalsPlaylistsModal => 'PORTALS & PLAYLISTS MODAL';

  @override
  String get stgbPortalBrowserGuide => 'PORTAL BROWSER & CHANNEL GUIDE';

  @override
  String get stgbStreamSources => 'STREAM SOURCES';

  @override
  String get stgbShowLiveSpotlight => 'Show Live Spotlight Banner';

  @override
  String get stgbShowLiveSpotlightDesc =>
      'Featured championship matches and top broadcast channels at the top';

  @override
  String get stgbHeroBannerStyle => 'Hero Banner Style';

  @override
  String get stgbAutoRotateChannels => 'Auto-Rotate Channels';

  @override
  String get stgbAutoRotateChannelsDesc =>
      'Automatically cycle through featured live events';

  @override
  String get stgbRotationInterval => 'Rotation Interval';

  @override
  String get stgbChannelCardSize => 'Channel Card Size';

  @override
  String get stgbCardHoverZoom => 'Card Hover Scale Zoom';

  @override
  String get stgbShowLiveHdBadge => 'Show LIVE / HD Stream Badge';

  @override
  String get stgbShowLiveHdBadgeDesc =>
      'Display radiant live broadcast badge on channel corners';

  @override
  String get stgbShowChannelCategoryTag => 'Show Channel Category Tag';

  @override
  String get stgbShowChannelCategoryTagDesc =>
      'Show category label below channel name';

  @override
  String get stgbShowFeedHealthBadge => 'Show Feed Health Badge';

  @override
  String get stgbShowFeedHealthBadgeDesc =>
      'Mark a channel as alive, unchecked or dead on the Boxing row';

  @override
  String get stgbChannelCategoriesSections => 'Channel Categories & Sections';

  @override
  String get stgbToggleLiveTvRows => 'Toggle visibility of Live TV rows';

  @override
  String get stgbResetAll => 'Reset All';

  @override
  String get stgbPortalCardStyle => 'Portal Card Display Style';

  @override
  String get stgbShowPortalExpiry => 'Show Portal Expiry Date';

  @override
  String get stgbShowPortalExpiryDesc =>
      'Display subscription expiration tag on portal cards';

  @override
  String get stgbShowMaxConnections => 'Show Max Active Connections Tag';

  @override
  String get stgbShowMaxConnectionsDesc =>
      'Display current and max concurrent streaming connections';

  @override
  String get stgbDefaultStartingTab => 'Default Starting Tab';

  @override
  String get stgbChannelStreamLayout => 'Channel Stream Layout Mode';

  @override
  String get stgbGridStreamColumns => 'Grid Stream Columns';

  @override
  String get stgbCategorySidebarWidth => 'Category Sidebar Width';

  @override
  String get stgbShowChannelLogos => 'Show Channel Stream Logos';

  @override
  String get stgbShowChannelLogosDesc =>
      'Display channel poster and logos in stream rows';

  @override
  String get stgbShowEpgNowPlaying => 'Show EPG \"Now Playing\" Snippet';

  @override
  String get stgbShowEpgNowPlayingDesc =>
      'Display current television guide title below channel';

  @override
  String get stgbShowCategoryCounts => 'Show Category Stream Counts';

  @override
  String get stgbShowCategoryCountsDesc =>
      'Show number of available streams next to category names';

  @override
  String get stgbIncludeFreePublicSources => 'Include Free Public Sources';

  @override
  String get stgbIncludeFreePublicSourcesDesc =>
      'Add public M3U playlists (e.g. iptv-org) to a channel\'s stream list';

  @override
  String get stgbDiscoveryPosterCards => 'DISCOVERY & POSTER CARDS';

  @override
  String get stgbMangaReaderViewer => 'MANGA READER & CHAPTER VIEWER';

  @override
  String get stgbEnableMovingLighting => 'Enable Moving Ambient Lighting';

  @override
  String get stgbShowContinueReading => 'Show \"Continue Reading\" Slider';

  @override
  String get stgbShowContinueReadingDesc =>
      'Display your active reading history at the top of the Manga page';

  @override
  String get stgbMangaCardDensity => 'Manga Poster Card Density';

  @override
  String get stgbShowContentTypeBadge =>
      'Show Content Type Badge (Manga/Manhwa)';

  @override
  String get stgbShowPublicationYear => 'Show Publication Year on Cards';

  @override
  String get stgbPosterHoverGlow => 'Poster Card Hover Glow Effect';

  @override
  String get stgbShowDesktopScrollTrack => 'Show Desktop Scroll Track';

  @override
  String get stgbDefaultReadingMode => 'Default Reading Mode';

  @override
  String get stgbPageWidthConstraint => 'Page Reading Width Constraint';

  @override
  String get stgbReaderBgAtmosphere => 'Reader Background Atmosphere';

  @override
  String get stgbControlToolbarStyle => 'Control Toolbar Style';

  @override
  String get stgbVerticalPageGap => 'Vertical Page Gap';

  @override
  String get stgbShowPageThumbnails => 'Show Page Deck / Thumbnail Previews';

  @override
  String get stgbShowPageThumbnailsDesc =>
      'Interactive visual tray of thumbnail previews for instant page jumping';

  @override
  String get stgbShowPageScrubber => 'Show Page Scrubber Slider';

  @override
  String get stgbEnableNextChapterPreview =>
      'Enable Next Chapter Preview Card Deck';

  @override
  String get stgbEnableNextChapterPreviewDesc =>
      'Rich glass deck card at the end of each chapter with chapter art and direct launch';

  @override
  String get stgbMusicPlayerStudio => 'Music Player Studio';

  @override
  String get stgbCustomMusicStudio => 'Custom Music Player Studio';

  @override
  String get stgbMusicStudioDesc =>
      'Design the fullscreen player, drag components, customize physics & liquid glass';

  @override
  String get stgbApplyActive => 'Apply Active';

  @override
  String get stgbFullscreenLiveStudio => 'FULLSCREEN LIVE STUDIO';

  @override
  String get stgbSyncedLyrics => 'Synced Lyrics';

  @override
  String get stgbPlayingQueue => 'Playing Queue';

  @override
  String get stgbSyncedLyricsSandbox => 'Synced Lyrics Sandbox';

  @override
  String get stgbPlayingQueueSandbox => 'Playing Queue Sandbox (4 Tracks)';

  @override
  String get stgbArtworkTurntable => 'Artwork & Turntable';

  @override
  String get stgbAlbumArtTurntable => 'Album Art & Vinyl Turntable';

  @override
  String get stgbTrackArtistAlbum => 'Track, Artist & Album Titles';

  @override
  String get stgbTrackTitleQuality => 'Track Title & Quality Badge';

  @override
  String get stgbLosslessQualityBadge => 'Lossless Hi-Res Audio Quality Badge';

  @override
  String get stgbPrimaryControlsMusic =>
      'Primary Controls (Play, Pause, Skip, Shuffle, Repeat)';

  @override
  String get stgbSecondaryControlsMusic => 'Secondary Controls (Volume Slider)';

  @override
  String get stgbLyricsQueueButtons => 'Synced Lyrics & Queue Quick Buttons';

  @override
  String get stgbFullscreenArranger => 'Fullscreen Player Drag & Drop Arranger';

  @override
  String get stgbFullscreenArrangerDesc =>
      'Hold and drag any block to reorder the layout of your fullscreen player in real-time.';

  @override
  String get stgbSeekBarScrubberEngine => 'Seek Bar Canvas Scrubber Engine';

  @override
  String get stgbSeekBarScrubberEngineDesc =>
      'Select how audio waveforms and scrubbing tracks render across your music player.';

  @override
  String get stgbPlayButtonAesthetic => 'Play Button Aesthetic & Style';

  @override
  String get stgbHoverTouchPhysicsEngine => 'Hover & Touch Physics Engine';

  @override
  String get stgbHoverTouchPhysicsEngineDesc =>
      'Select the interactive physics feedback applied when hovering or pressing controls.';

  @override
  String get stgbLivePhysicsTestPad => 'Live Physics Testing Pad';

  @override
  String get stgbArtworkTurntablePresentation =>
      'Artwork & Turntable Presentation';

  @override
  String get stgbArtworkTurntablePresentationDesc =>
      'Select how album covers, vinyl turntable animations, and cards display in the player.';

  @override
  String get stgbVisualThemePalette => 'VISUAL THEME PALETTE';

  @override
  String get stgbAmbientAtmosphereGlow => 'AMBIENT ATMOSPHERE & GLOW';

  @override
  String get stgbDiscoveryCatalogConfig => 'DISCOVERY & CATALOG CONFIGURATION';

  @override
  String get stgbFullscreenPlayerPresets => 'FULLSCREEN PLAYER PRESETS';

  @override
  String get stgbCustomPlayerEngineDesigner => 'CUSTOM PLAYER ENGINE DESIGNER';

  @override
  String get stgbMovingBgAmbientLighting =>
      'Moving Background Ambient Lighting';

  @override
  String get stgbMovingBgAmbientLightingDesc =>
      'Dynamic moving glowing orbs reacting with your theme accent colors';

  @override
  String get stgbAmbientLightPattern => 'Ambient Light Pattern';

  @override
  String get stgbShowHeroShowcase => 'Show Hero Spotlight Showcase';

  @override
  String get stgbMusicHeroDesc =>
      'Featured bestselling album & track showcase at the top of the music page';

  @override
  String get stgbShowLosslessBadges => 'Show Lossless Hi-Res Audio Badges';

  @override
  String get stgbShowLosslessBadgesDesc =>
      'Displays FLAC / Hi-Res lossless stream indicators on music cards and player';

  @override
  String get stgbMusicCardDensity => 'Music Card & Grid Density';

  @override
  String get stgbFullPlayerEngine => 'FULL PLAYER ENGINE';

  @override
  String get stgbCustomizeFullscreenDesc =>
      'Customize the Fullscreen Player. Drag & drop blocks, waveform equalizers, vinyl turntable & liquid glass buttons.';

  @override
  String get stgbLiveWaveformPreview => 'Live Waveform & Controls Preview';

  @override
  String get stgbOpenFullStudio => 'Open Full Studio ➔';

  @override
  String tv2RemovedStreamFeeds(Object count) {
    return 'Removed $count stream feed(s)';
  }

  @override
  String tv2SearchChannelsHint(Object count) {
    return 'Search $count channels (e.g. 1080p, 4K, feed name)...';
  }

  @override
  String tv2DeleteSelectedFeeds(Object count) {
    return 'Delete ($count)';
  }

  @override
  String tv2FoundFeedsOfTotal(Object found, Object total) {
    return 'Found $found of $total feeds';
  }

  @override
  String tv2LiveFeedsAvailable(Object count) {
    return '$count live stream feeds available';
  }

  @override
  String tv2NoFeedsMatch(Object query) {
    return 'No feeds match \"$query\"';
  }

  @override
  String tv2ServerNumber(Object number) {
    return 'Server $number';
  }

  @override
  String tv2ChannelsCountCaps(Object count) {
    return '$count CHANNELS';
  }

  @override
  String get tv2Add => 'Add';

  @override
  String tv2FeedStopped(Object error) {
    return 'This feed stopped: $error';
  }

  @override
  String tv2BufferingName(Object name) {
    return 'Buffering $name…';
  }

  @override
  String tv2NoOtherSource(Object reason) {
    return '$reason No other source for this channel.';
  }

  @override
  String tv2AllSourcesFailed(Object count) {
    return 'All $count sources for this channel failed.';
  }

  @override
  String tv2SourcesFailedInRow(Object count) {
    return '$count sources failed in a row. Pick another source from the list.';
  }

  @override
  String tv2AspectMode(Object mode) {
    return 'ASPECT: $mode';
  }

  @override
  String tv2ChannelPosition(Object current, Object total, Object portal) {
    return 'Channel $current/$total · $portal';
  }

  @override
  String tv2SourcePosition(Object current, Object total, Object portal) {
    return 'Source $current/$total · $portal';
  }

  @override
  String get tv2TryAgain => 'Try again';

  @override
  String tv2RemovedPortals(Object count) {
    return 'Removed $count portal(s)';
  }

  @override
  String tv2RemovedAllPortals(Object count) {
    return 'Removed all $count portals';
  }

  @override
  String tv2RemovedPlaylists(Object count) {
    return 'Removed $count playlist(s)';
  }

  @override
  String tv2RemovedAllPlaylists(Object count) {
    return 'Removed all $count playlists';
  }

  @override
  String tv2XtreamPanelsCount(Object count) {
    return 'Xtream Panels ($count)';
  }

  @override
  String tv2M3uPlaylistsCount(Object count) {
    return 'M3U Playlists ($count)';
  }

  @override
  String tv2DeleteSelectedPortals(Object count) {
    return 'Delete ($count)';
  }

  @override
  String tv2AllPortalsCount(Object count) {
    return 'All ($count)';
  }

  @override
  String tv2MyPortalsCount(Object count) {
    return 'My Portals ($count)';
  }

  @override
  String tv2FavoritesStarCount(Object count) {
    return 'Favorites ⭐ ($count)';
  }

  @override
  String tv2NoVerifiedPortalsHint(Object source) {
    return 'No verified portals. Tap \"Generate Portals\" ($source) to auto-discover.';
  }

  @override
  String tv2NoPortalsInFilter(Object filter) {
    return 'No portals found in \"$filter\" filter.';
  }

  @override
  String tv2CopiedText(Object text) {
    return 'Copied: $text';
  }

  @override
  String tv2ExpShort(Object expiry) {
    return 'Exp: $expiry';
  }

  @override
  String tv2ConnShort(Object active, Object max) {
    return 'Conn: $active/$max';
  }

  @override
  String tv2DeleteSelectedPlaylists(Object count) {
    return 'Delete ($count)';
  }

  @override
  String tv2PlaylistChannelsSource(Object count, Object source) {
    return '$count channels $source';
  }

  @override
  String get tv2XtreamPanels => 'Xtream Panels';

  @override
  String get tv2M3uPlaylists => 'M3U Playlists';

  @override
  String get tv2VerifyAndSave => 'Verify & Save';

  @override
  String get tv2FetchAndSave => 'Fetch & Save';

  @override
  String tv2GridColumns(Object cols) {
    return '$cols Cols';
  }

  @override
  String tv2FailedLoadContent(Object error) {
    return 'Failed to load content: $error';
  }

  @override
  String tv2NoPlayableStreamNamed(Object name) {
    return '\"$name\" has no playable stream. Reconnect the portal or remove it and add another.';
  }

  @override
  String tv2CategoriesTotal(Object count) {
    return '$count total';
  }

  @override
  String tv2ExpiryLabel(Object expiry) {
    return 'Expiry: $expiry';
  }

  @override
  String tv2ConnectionsLabel(Object active, Object max) {
    return 'Connections: $active/$max';
  }

  @override
  String tv2StopHealthCheck(Object checked, Object total) {
    return 'Stop ($checked/$total)';
  }

  @override
  String tv2ConnAndExpiry(Object active, Object max, Object expiry) {
    return 'Conn: $active/$max • $expiry';
  }

  @override
  String tv2NoStreamsMatching(Object query) {
    return 'No streams matching \"$query\"';
  }

  @override
  String tv2SeriesEpisodes(Object series) {
    return '$series Episodes';
  }

  @override
  String tv2EpisodeNumber(Object episode) {
    return 'Episode $episode';
  }

  @override
  String get tv2AllCategories => 'All Categories';

  @override
  String tv2NowAiringOn(Object channel) {
    return 'Now Airing on $channel';
  }

  @override
  String tv2GuideProgress(
    Object start,
    Object stop,
    Object minutes,
    Object percent,
  ) {
    return '$start – $stop · $minutes mins elapsed ($percent% complete)';
  }

  @override
  String ani2ResumeEpModal(Object episode) {
    return 'Resume Ep $episode';
  }

  @override
  String ani2TotalEpsModal(Object count) {
    return '($count total)';
  }

  @override
  String get ani2SubCapsModal => 'SUB';

  @override
  String get ani2DubCapsModal => 'DUB';

  @override
  String ani2ResumeEp(Object episode) {
    return 'Resume Ep $episode';
  }

  @override
  String ani2TotalEps(Object count) {
    return '($count total)';
  }

  @override
  String get ani2SubCaps => 'SUB';

  @override
  String get ani2DubCaps => 'DUB';

  @override
  String ani2CurrentlyAiringHits(Object season) {
    return 'Currently airing hits · $season';
  }

  @override
  String ani2EpisodesCount(Object count) {
    return '$count Episodes';
  }

  @override
  String ani2SortLabel(Object sort) {
    return 'Sort: $sort';
  }

  @override
  String ani2TvSeriesResults(Object count) {
    return '$count Results';
  }

  @override
  String ani2MoviesResults(Object count) {
    return '$count Results';
  }

  @override
  String ani2OvasResults(Object count) {
    return '$count Results';
  }

  @override
  String ani2NoPlayableStreamsEp(Object episode) {
    return 'No playable streams found for Episode $episode.';
  }

  @override
  String ani2TitleEpisode(Object title, Object episode) {
    return '$title - Episode $episode';
  }

  @override
  String ani2NoCategorySources(Object category) {
    return 'No $category sources found.';
  }

  @override
  String get ani2Sub => 'Sub';

  @override
  String get ani2Dub => 'Dub';

  @override
  String ai2FailedGenerateRecs(Object error) {
    return 'Failed to generate recommendations: $error';
  }

  @override
  String ai2RatedOfThree(Object rated) {
    return '$rated/3 rated';
  }

  @override
  String ai2DiscoverRecsCount(Object count) {
    return 'Discover Recommendations ($count Titles)';
  }

  @override
  String ai2TitleNumber(Object number) {
    return 'Title #$number';
  }

  @override
  String ai2CinemaPicksCount(Object count) {
    return '$count cinema picks tailored to your taste profile';
  }

  @override
  String ai2MatchPercent(Object percent) {
    return '$percent% match';
  }

  @override
  String ply2VideoTrack(Object id) {
    return 'Video $id';
  }

  @override
  String ply2SubtitleTrack(Object index) {
    return 'Subtitle $index';
  }

  @override
  String ply2ErrorPrefix(Object error) {
    return 'Error: $error';
  }

  @override
  String ply2DebridTryingAnother(Object service, Object notice) {
    return '$service $notice • Trying another';
  }

  @override
  String ply2TrackNumber(Object number) {
    return 'Track $number';
  }

  @override
  String ply2SwitchedEmbeddedSub(Object title) {
    return 'Switched to embedded subtitle: $title';
  }

  @override
  String ply2DownloadingSubtitle(Object language) {
    return 'Downloading $language subtitle...';
  }

  @override
  String ply2SubtitleLoaded(Object language, Object lines) {
    return '$language subtitle loaded ($lines lines)';
  }

  @override
  String ply2CouldNotLoadSubtitle(Object error) {
    return 'Could not load subtitle: $error';
  }

  @override
  String ply2PlaybackErrorMsg(Object error) {
    return 'Playback error: $error';
  }

  @override
  String ply2SelectAnotherSourceBelow(Object message) {
    return '$message Please select another source below.';
  }

  @override
  String ply2BufferingEpisode(Object season, Object episode, Object title) {
    return 'Buffering S$season:E$episode - $title...';
  }

  @override
  String ply2DownloadFailedStart(Object error) {
    return 'Download failed to start: $error';
  }

  @override
  String ply2PartWithTitle(Object part, Object title) {
    return 'Part $part$title';
  }

  @override
  String ply2TrackIdx(Object index) {
    return 'Track $index';
  }

  @override
  String ply2AudioSyncOffset(Object sign, Object seconds) {
    return 'AUDIO SYNC: $sign${seconds}s';
  }

  @override
  String ply2PartCaps(Object part) {
    return 'PART $part';
  }

  @override
  String mnz2StreamUrlFor(Object name) {
    return 'Stream URL for $name';
  }

  @override
  String mnz2ActiveStreams(Object count) {
    return '$count Stream(s)';
  }

  @override
  String get mnz2CustomUrl => 'Custom URL';

  @override
  String dsc2NoCatalogsForType(Object type) {
    return 'No catalogs available for \"$type\"';
  }

  @override
  String dsc2CatalogRequiresSelecting(Object fields) {
    return 'This catalog requires selecting $fields before loading titles.';
  }

  @override
  String dsc2SelectExtra(Object first, Object rest) {
    return 'Select $first$rest';
  }

  @override
  String dsc2EnterExtra(Object name) {
    return 'Enter $name';
  }

  @override
  String dsc2EnterExtraName(Object name) {
    return 'Enter $name';
  }

  @override
  String dsc2TypeExtraHere(Object name) {
    return 'Type $name here...';
  }

  @override
  String dsc2AllExtra(Object name) {
    return 'All $name';
  }

  @override
  String dsc2SearchWithinCatalog(Object catalog) {
    return 'Search within $catalog...';
  }

  @override
  String dsc2GenreQuery(Object query) {
    return 'Genre: $query';
  }

  @override
  String dsc2SearchQuery(Object query) {
    return 'Search: $query';
  }

  @override
  String dsc2NoResultsFor(Object query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get dsc2Apply => 'Apply';

  @override
  String dl3EpisodeNumber(Object episode) {
    return 'Episode $episode';
  }

  @override
  String dl3ConfirmDeleteTask(Object title) {
    return 'Are you sure you want to delete \"$title\" and remove the file from storage?';
  }

  @override
  String dl3ActiveAndDownloaded(Object active, Object completed) {
    return '$active active • $completed downloaded';
  }

  @override
  String dl3FolderPath(Object path) {
    return 'Folder path: $path';
  }

  @override
  String dl3PeersCount(Object count) {
    return '$count peers';
  }

  @override
  String dl3FailedReason(Object error) {
    return 'Failed: $error';
  }

  @override
  String dl3PausedPercent(Object percent) {
    return 'Paused ($percent%)';
  }

  @override
  String dl3ProgressSpeedEta(Object percent, Object speed, Object eta) {
    return '$percent% • $speed • ETA: $eta';
  }

  @override
  String dl3FolderLabel(Object path) {
    return 'Folder: $path';
  }

  @override
  String dl3PathLabel(Object path) {
    return 'Path: $path';
  }

  @override
  String dl3EpisodeOffline(Object season, Object episode) {
    return 'S$season:E$episode • Offline';
  }

  @override
  String dl3YearOffline(Object year) {
    return '$year • Offline';
  }

  @override
  String dl3DeviceStorageUsed(Object used, Object total) {
    return 'Device Storage: $used Used of $total';
  }

  @override
  String dl3FreeSpace(Object free) {
    return '$free Free';
  }

  @override
  String cal2NoEpisodesOnNetwork(Object network) {
    return 'No episodes on $network for this day';
  }

  @override
  String cal2EpisodesAiring(Object count) {
    return '$count Episodes Airing';
  }

  @override
  String get cal2ShowAllNetworks => 'Show All Networks';

  @override
  String ctl2SelectExtra(Object name) {
    return 'Select $name';
  }

  @override
  String ctl2AllExtra(Object name) {
    return 'All $name';
  }

  @override
  String ara2FailedLoadDetails(Object error) {
    return 'Failed to load anime details: $error';
  }

  @override
  String get ara2Retry => 'Retry';

  @override
  String ara2NoArabicStreamsEp(Object episode) {
    return 'No playable Arabic streams found for Episode $episode.';
  }

  @override
  String ara2FailedLoadArabicStreams(Object error) {
    return 'Failed to load Arabic streams: $error';
  }

  @override
  String ara2TitleEpisode(Object title, Object episode) {
    return '$title - Episode $episode';
  }

  @override
  String mus2AddedTrackToPlaylist(Object track, Object playlist) {
    return 'Added \"$track\" to \"$playlist\"';
  }

  @override
  String mus2CreatedPlaylist(Object name) {
    return 'Created playlist \"$name\"';
  }

  @override
  String mus2RemovedFromDownloads(Object title) {
    return 'Removed \"$title\" from downloads';
  }

  @override
  String mus2AddedToDownloadQueue(Object title) {
    return 'Added \"$title\" to download queue';
  }

  @override
  String mus2RemovedFromPlaylist(Object playlist) {
    return 'Removed from \"$playlist\"';
  }

  @override
  String mus2AddedToPlaylist(Object playlist) {
    return 'Added to \"$playlist\"';
  }

  @override
  String mus2TracksTabCount(Object count) {
    return 'Tracks ($count)';
  }

  @override
  String mus2ArtistsTabCount(Object count) {
    return 'Artists ($count)';
  }

  @override
  String mus2AlbumsTabCount(Object count) {
    return 'Albums ($count)';
  }

  @override
  String mus2PlaylistsTabCount(Object count) {
    return 'Playlists ($count)';
  }

  @override
  String mus2NoResultsFor(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String mus2FavouriteTracksCount(Object count) {
    return '$count favourite tracks';
  }

  @override
  String mus2QueueCount(Object count) {
    return 'Queue ($count)';
  }

  @override
  String mus2OfflineTracksSize(Object count, Object size) {
    return '$count offline tracks • $size MB';
  }

  @override
  String mus2TrackNumber(Object number) {
    return 'Track $number';
  }

  @override
  String mus2DownloadingPercent(Object percent) {
    return 'Downloading $percent%';
  }

  @override
  String mus2TracksCount(Object count) {
    return '$count Tracks';
  }

  @override
  String mus2AddedAlbumTracksToQueue(Object count, Object album) {
    return 'Added $count tracks from \"$album\" to download queue';
  }

  @override
  String mus2CuratedByTracks(Object creator, Object count) {
    return 'Curated by $creator • $count tracks';
  }

  @override
  String mus2AddedPlaylistTracksToQueue(Object count, Object playlist) {
    return 'Added $count tracks from \"$playlist\" to download queue';
  }

  @override
  String mus2CustomPlaylistTracks(Object count) {
    return 'Custom Playlist • $count tracks';
  }

  @override
  String mus2OfflineTracksStorage(Object count, Object size) {
    return '$count offline tracks • $size MB storage';
  }

  @override
  String mus2NoDownloadedTracksMatch(Object query) {
    return 'No downloaded tracks match \"$query\"';
  }

  @override
  String mus2DeleteFromOfflineStorage(Object title) {
    return 'Delete \"$title\" from offline storage?';
  }

  @override
  String mus2ExtractingStreamFor(Object title) {
    return 'Extracting stream for \"$title\"...';
  }

  @override
  String mus2DownloadingTrackPercent(Object title, Object percent) {
    return 'Downloading \"$title\" ($percent%)';
  }

  @override
  String mus2InQueueCount(Object count) {
    return '$count in queue';
  }

  @override
  String get mus2RadioStationsLiveStreams => 'Radio Stations & Live Streams';

  @override
  String get mus2ContinuousMusicChannels =>
      'Continuous music channels tuned to your mood.';

  @override
  String abk2FailedToLoadChapters(Object error) {
    return 'Failed to load chapters: $error';
  }

  @override
  String abk2PreparingChapter(Object title) {
    return 'Preparing $title...';
  }

  @override
  String abk2ResolvingAudioVia(Object service) {
    return 'Resolving audio via $service cloud...';
  }

  @override
  String abk2PlaybackErrorErr(Object error) {
    return 'Playback Error: $error';
  }

  @override
  String abk2PlaybackError(Object error) {
    return 'Playback Error: $error';
  }

  @override
  String abk2ChapterNumber(Object number) {
    return 'Chapter $number';
  }

  @override
  String abk2ChapterOfTotalBook(Object current, Object total, Object book) {
    return 'Chapter $current of $total • $book';
  }

  @override
  String abk2ChaptersCountUpper(Object count) {
    return '$count CHAPTERS';
  }

  @override
  String get abk2AudioPlayerStyleStudio => 'Audio Player Style & Studio';

  @override
  String get abk2SelectPlayerDesignPreset => 'Select Player Design Preset';

  @override
  String get abk2SeekBarScrubberStyle => 'Seek Bar Scrubber Style';

  @override
  String get abk2PlayPauseButtonStyle => 'Play / Pause Button Style';

  @override
  String get abk2Autoplay => 'Autoplay';

  @override
  String get abk2OpenChaptersPanel => 'Open Chapters Panel';

  @override
  String get abk2AudiobookChapters => 'Audiobook Chapters';

  @override
  String abk2FailedToFetchAudiobooks(Object error) {
    return 'Failed to fetch audiobooks: $error';
  }

  @override
  String abk2ChapterOfTotal(Object current, Object total) {
    return 'Chapter $current of $total';
  }

  @override
  String abk2ResumeTimeLeft(Object remaining) {
    return 'Resume ($remaining left)';
  }

  @override
  String abk2VoiceLabel(Object voice) {
    return 'Voice: $voice';
  }

  @override
  String abk2GeneratingPercent(Object percent) {
    return 'Generating $percent%';
  }

  @override
  String abk2AuthorLocal(Object author) {
    return '$author • Local';
  }

  @override
  String abk2ResumeChapterNumber(Object number) {
    return 'Chapter $number';
  }

  @override
  String abk2PercentCompleted(Object percent) {
    return '$percent% completed';
  }

  @override
  String abk2UploadedPartsGenerationStarted(Object count) {
    return 'Uploaded $count parts — generation started in background!';
  }

  @override
  String abk2GenerationFailed(Object error) {
    return 'Generation failed: $error';
  }

  @override
  String abk2RemoveFromGenerationList(Object name) {
    return 'Remove \"$name\" from the generation list?';
  }

  @override
  String abk2SelectedAudioFiles(Object count) {
    return 'Selected $count audio file(s):';
  }

  @override
  String abk2GenerationQueueCompleted(Object count) {
    return 'GENERATION QUEUE & COMPLETED ($count)';
  }

  @override
  String abk2DownloadedBooksFromLibrary(Object count) {
    return 'DOWNLOADED BOOKS FROM LIBRARY ($count)';
  }

  @override
  String abk2FileSizeMb(Object size) {
    return 'Size: $size MB';
  }

  @override
  String abk2SynthesizingPercent(Object percent) {
    return 'Synthesizing $percent%';
  }

  @override
  String abk2JobVoiceLabel(Object voice) {
    return 'Voice: $voice';
  }

  @override
  String abk2ImportedAudiobooksCount(Object count) {
    return 'IMPORTED AUDIOBOOKS ($count)';
  }

  @override
  String abk2AuthorPartsSize(Object author, Object parts, Object size) {
    return '$author • $parts part(s) ($size MB)';
  }

  @override
  String abk2DeleteFromLibrary(Object title) {
    return 'Delete \"$title\" from your library?';
  }

  @override
  String get abk2StreamUrlCopied => 'Stream URL copied to clipboard!';

  @override
  String get abk2RemoveGenerationJob => 'Remove Generation Job?';

  @override
  String get abk2AiEpubGeneratorTts => 'AI EPUB Generator (TTS)';

  @override
  String get abk2MyUploadedAudiobooks => 'My Uploaded Audiobooks';

  @override
  String get abk2DeleteAudiobook => 'Delete Audiobook?';

  @override
  String bk2FailedToDownloadBook(Object error) {
    return 'Failed to download book: $error';
  }

  @override
  String bk2PageOfTotal(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String bk2ChapterOfTotal(Object current, Object total) {
    return 'Chapter $current of $total';
  }

  @override
  String bk2PercentCompleted(Object percent) {
    return '$percent% Completed';
  }

  @override
  String bk2DownloadingPercent(Object percent) {
    return 'Downloading $percent%...';
  }

  @override
  String get bk2Information => 'Information';

  @override
  String get bk2Overview => 'Overview';

  @override
  String bk2FailedToLoadBooks(Object error) {
    return 'Failed to load books: $error';
  }

  @override
  String bk2ResultsFor(Object query) {
    return 'Results for \"$query\"';
  }

  @override
  String bk2FontSizeMargins(Object size, Object margins) {
    return 'Font Size: $size pt · Margins: $margins';
  }

  @override
  String bk2AuthorPercentRead(Object author, Object percent) {
    return '$author · $percent% read';
  }

  @override
  String get bk2AllFormats => 'All Formats';

  @override
  String bk2FailedToOpenBook(Object title, Object error) {
    return 'Failed to open \"$title\": $error';
  }

  @override
  String bk2PercentMinsLeft(Object percent, Object mins) {
    return '$percent% · ~$mins min left';
  }

  @override
  String get bk2BackToLibrary => 'Back to Library';

  @override
  String get bk2Retry => 'Retry';

  @override
  String bk2PdfPageOfTotal(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String bk2PageNumber(Object page) {
    return 'Page $page';
  }

  @override
  String bk2SliderAuthorPercentRead(Object author, Object percent) {
    return '$author · $percent% read';
  }

  @override
  String bk2SliderPositionPercentRead(Object position, Object percent) {
    return '$position · $percent% read';
  }

  @override
  String mg2NoChaptersMatching(Object query) {
    return 'No chapters matching \"$query\"';
  }

  @override
  String mg2ChapterNumber(Object number) {
    return 'Chapter $number';
  }

  @override
  String mg2PageOfTotal(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String mg2ResumeChapter(Object number) {
    return 'Resume Chapter $number';
  }

  @override
  String get mg2Synopsis => 'Synopsis';

  @override
  String mg2GenreManga(Object genre) {
    return '$genre Manga';
  }

  @override
  String mg2PercentRead(Object percent) {
    return '$percent% read';
  }

  @override
  String mg2AuthorPercentRead(Object author, Object percent) {
    return '$author · $percent% read';
  }

  @override
  String mg2CurrentChapterNumber(Object number) {
    return 'Chapter $number';
  }

  @override
  String mg2NextChapterNumber(Object number) {
    return 'Chapter $number';
  }

  @override
  String mg2ReaderPageOfTotal(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String mg2ReaderPageSlashTotal(Object current, Object total) {
    return 'Page $current / $total';
  }

  @override
  String mg2PageModeLabel(Object mode) {
    return 'Page Mode: $mode';
  }

  @override
  String mg2AtmosphereLabel(Object atmosphere) {
    return 'Atmosphere: $atmosphere';
  }

  @override
  String get bk2Typography => 'Typography';

  @override
  String get bk2Theme => 'Theme';

  @override
  String get bk2Layout => 'Layout';

  @override
  String stgcAddonConnectedTo(Object name, Object service) {
    return '$name connected to $service';
  }

  @override
  String stgcAddonInstalled(Object name) {
    return '$name installed successfully!';
  }

  @override
  String stgcRemoveAddonQ(Object name) {
    return 'Remove $name?';
  }

  @override
  String get stgcRepoAdded => 'Repository added successfully!';

  @override
  String get stgcInstallRepoPluginsQ => 'Install Repository Plugins?';

  @override
  String stgcInstalledFromRepo(Object count) {
    return 'Successfully installed $count plugins from repository!';
  }

  @override
  String stgcInstallError(Object error) {
    return 'Installation error: $error';
  }

  @override
  String stgcRemoveExtQ(Object name) {
    return 'Remove $name?';
  }

  @override
  String stgcRemoveCountPluginsQ(Object count) {
    return 'Remove $count plugin(s)?';
  }

  @override
  String stgcConfirmRemoveAllCs(Object count) {
    return 'Are you sure you want to remove all $count installed CloudStream plugins? All downloaded plugin files (.jar/.cs3) will be deleted.';
  }

  @override
  String stgcConfirmRemoveSelectedCs(Object count) {
    return 'Are you sure you want to remove the $count selected CloudStream plugins? Their downloaded files will be deleted from your device.';
  }

  @override
  String stgcRemovedCountPlugins(Object count) {
    return 'Successfully removed $count plugin(s).';
  }

  @override
  String stgcRemoveCount(Object count) {
    return 'Remove ($count)';
  }

  @override
  String stgcRemoveRepoQ(Object name) {
    return 'Remove $name?';
  }

  @override
  String get stgcAddonsExtensions => 'Addons & Extensions';

  @override
  String stgcAddonsTotal(Object count) {
    return '$count Total';
  }

  @override
  String stgcRemoveSelectedCount(Object count) {
    return 'Remove ($count)';
  }

  @override
  String stgcInstalledTotal(Object count) {
    return '$count Total';
  }

  @override
  String stgcReposCount(Object count) {
    return '$count Repos';
  }

  @override
  String stgcRuntimeSetupError(Object error) {
    return 'Runtime setup error: $error';
  }

  @override
  String stgcAddonSubtitlesProvider(Object version) {
    return 'v$version  ·  Subtitles Provider';
  }

  @override
  String stgcAddonCatalogs(Object version, Object count, Object subtitles) {
    return 'v$version  ·  $count catalog(s)$subtitles';
  }

  @override
  String get stgcAddonSubtitlesSuffix => '  ·  Subtitles';

  @override
  String stgcLabelCount(Object label, Object count) {
    return '$label ($count)';
  }

  @override
  String stgcUsesYourServiceKey(Object service) {
    return 'Uses your $service key';
  }

  @override
  String stgcPluginInstalled(Object name) {
    return '$name installed successfully!';
  }

  @override
  String stgcPluginUninstalled(Object name) {
    return '$name uninstalled.';
  }

  @override
  String stgcInstalledCountPlugins(Object count) {
    return 'Successfully installed $count plugins!';
  }

  @override
  String stgcRemoveListPluginsQ(Object count) {
    return 'Remove $count plugin(s)?';
  }

  @override
  String stgcConfirmUninstallList(Object count) {
    return 'Are you sure you want to uninstall all $count installed plugins from this list? Their downloaded files will be removed.';
  }

  @override
  String stgcRemoveAllListCount(Object count) {
    return 'Remove All ($count)';
  }

  @override
  String stgcUninstalledCount(Object count) {
    return 'Successfully uninstalled $count plugins.';
  }

  @override
  String stgcRemoveAllCount(Object count) {
    return 'Remove All ($count)';
  }

  @override
  String stgcInstallAllCount(Object count) {
    return 'Install All ($count)';
  }

  @override
  String stgcNoPluginsMatching(Object query) {
    return 'No plugins matching \"$query\"';
  }

  @override
  String get stgcAllMatchingInstalled =>
      'All matching plugins are already installed!';

  @override
  String stgcRepoNameAdded(Object name) {
    return '$name added successfully!';
  }

  @override
  String stgcInstallRepoNamePluginsQ(Object name) {
    return 'Install $name Plugins?';
  }

  @override
  String stgcRepoIncludesPlugins(Object count, Object sample) {
    return 'This repository includes $count plugins ($sample...). Install all plugins now so their stream sources appear immediately?';
  }

  @override
  String stgcPluginsInstalledReady(Object count) {
    return '$count plugins installed and ready!';
  }

  @override
  String stgcMarketplaceSubtitle(Object count) {
    return '$count repos · Direct install links & verified providers';
  }

  @override
  String stgcNoReposFound(Object query) {
    return 'No repositories found for \"$query\"';
  }

  @override
  String stgcRepoPluginsCount(Object count) {
    return '$count Plugins';
  }

  @override
  String stgcCopiedLink(Object url) {
    return 'Copied link: $url';
  }

  @override
  String stgcContainsPlugins(Object plugins) {
    return 'Contains: $plugins';
  }

  @override
  String stgcViewAllPlugins(Object count) {
    return 'View all $count plugins';
  }

  @override
  String stgcDebridKeyVerified(Object provider, Object user) {
    return '$provider key verified ($user) & set as active provider!';
  }

  @override
  String stgcDebridKeySaved(Object provider) {
    return '$provider key saved & set as active provider!';
  }

  @override
  String stgcDebridKeyCleared(Object provider) {
    return '$provider key cleared.';
  }

  @override
  String get stgcDebridCloudStreaming => 'Debrid & Cloud Streaming';

  @override
  String stgcServiceNoKey(Object service) {
    return '$service has no API key saved. Please enter and save your key below.';
  }

  @override
  String stgcDebridActivatedVia(Object service) {
    return 'Debrid streaming activated via $service';
  }

  @override
  String stgcSelectedNoKey(Object service) {
    return '$service selected, but has no API key saved yet. Please enter and save your key below.';
  }

  @override
  String stgcActiveDebridSet(Object service) {
    return 'Active Debrid service set to $service';
  }

  @override
  String stgcRdLoggedInAs(Object user) {
    return 'Logged in as $user';
  }

  @override
  String stgcTorboxAccount(Object account) {
    return 'Account: $account';
  }

  @override
  String stgcAllDebridAccount(Object account) {
    return 'Account: $account';
  }

  @override
  String stgcDebridLinkAccount(Object account) {
    return 'Account: $account';
  }

  @override
  String get stgcPurposeTrakt =>
      'Identifies the Trakt application the pairing flow asks for a device code on, and stamps every Trakt API call.';

  @override
  String get stgcServiceKeysIntro =>
      'Lumora talks to several third-party services. Any key you save here replaces the one this build uses and takes effect immediately, with no restart.';

  @override
  String get stgcServiceKeysUnobtainable =>
      'These cannot be obtained: each is a credential for a third-party service that did not issue it to Lumora, so leave its field blank unless you have your own. A private build can supply its own with --dart-define, and blanking the registry entry in the source disables only that one source.';

  @override
  String get stgcServiceKeysStoredLocally =>
      'Every value is stored only on this device and is never shown back in these fields.';

  @override
  String stgcPasteKeyFirst(Object label) {
    return 'Paste a key for $label first.';
  }

  @override
  String stgcKeySavedInUse(Object label) {
    return '$label key saved and now in use.';
  }

  @override
  String stgcLabelKeyCleared(Object label) {
    return '$label key cleared.';
  }

  @override
  String stgcPasteYourKey(Object label) {
    return 'Paste your $label key';
  }

  @override
  String get stgcServiceApiKeys => 'Service API Keys';

  @override
  String get stgcVideoUpscaling => 'Video & Upscaling';

  @override
  String get stgcUpscalingIntro =>
      'Real-time GLSL upscaling on the video engine. Anime4K reconstructs line art; AMD FSR upscales live action and film. Pick one family — they are never combined.';

  @override
  String get stgcFsrDesc =>
      'AMD FidelityFX edge-adaptive upscaling, for live action and film. Upscales without sharpening, so it is the safe FSR option. Runs on any GPU, unlike NVIDIA RTX Video.';

  @override
  String get stgcFsrCasDesc =>
      'FSR with contrast-adaptive sharpening. Adds bite to soft or low-bitrate video. On a 2K or 4K source this can look worse than no upscaling at all.';

  @override
  String get stgcAppearanceInterface => 'Appearance & Interface';

  @override
  String get stgcSkiaRecommended =>
      'Skia is recommended on Windows here — Impeller coincided with an NVIDIA driver crash.';

  @override
  String get stgcSimklPinFailed => 'Failed to request Simkl PIN code.';

  @override
  String get stgcSimklSync => 'Simkl Synchronization';

  @override
  String stgcSimklLoggedInAs(Object user) {
    return 'Logged in as $user';
  }

  @override
  String get stgcPinCopied => 'PIN copied to clipboard!';

  @override
  String get stgcSyncingSimkl => 'Syncing with Simkl...';

  @override
  String get stgcSimklSyncDone => 'Simkl sync complete!';

  @override
  String get stgcTraktSync => 'Trakt.tv Synchronization';

  @override
  String get stgcCodeCopied => 'Code copied to clipboard!';

  @override
  String get stgcSyncingTrakt => 'Syncing with Trakt.tv...';

  @override
  String get stgcTraktSyncDone => 'Trakt sync complete!';

  @override
  String stgcTraktLoggedInAs(Object user) {
    return 'Logged in as $user';
  }

  @override
  String stgcTraktNeedsClientId(Object url) {
    return 'Trakt needs a Client ID before it can pair. Create a free app at $url, then paste its Client ID in Settings > Service API Keys. The Client Secret from the same app is optional.';
  }

  @override
  String get stgcTraktRejected =>
      'Trakt rejected the pairing request. Check the Client ID in Settings > Service API Keys - and add the Client Secret if Trakt requires one for your app.';

  @override
  String get stgcTmdbApiKey => 'TMDb API Key';

  @override
  String get stgcTmdbIntro =>
      'Add your own free TMDb key to rank the six \"The 90s\" rails by TMDb vote counts, and to cover the TMDb lookups the built-in scrapers make. Get a key at themoviedb.org.';

  @override
  String get stgcTmdbStoredLocally =>
      'The key is stored only on this device. This app ships with no key, and a built-in fallback keeps the scraper lookups working without one. Clearing your key restores the built-in 1990s picks.';

  @override
  String stgcAboutVersion(Object version) {
    return 'Version $version • Next-Gen Streaming Hub';
  }

  @override
  String get stgcAboutLegalese =>
      'Lumora, Copyright (C) 2026 JTing904\nhttps://github.com/JTing904/Lumora\nBased on ZPlay, Copyright (C) 2026 tzero86\nBased on PlayTorrio V3, Copyright (C) 2026 Ayman\nhttps://github.com/tzero86/ZPlay\nhttps://github.com/ayman708-UX/PlayTorrioV3\n\nThis program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.';

  @override
  String stgcUpdateCheckError(Object error) {
    return 'Error checking updates: $error';
  }

  @override
  String stgcInstalledVersion(Object version, Object build) {
    return 'Installed Version: v$version (Build $build)';
  }

  @override
  String get stgcAudiobookStudioApplied =>
      'Custom Player Studio layout applied & set as active player!';

  @override
  String stgcPreviewSpeed(Object speed) {
    return '${speed}x Speed';
  }

  @override
  String stgcPositionN(Object n) {
    return 'Position #$n';
  }

  @override
  String stgcHoverToFeel(Object effect) {
    return 'Hover your cursor or tap below to feel \"$effect\" in real-time:';
  }

  @override
  String stgcTestEffect(Object effect) {
    return 'Test \"$effect\"';
  }

  @override
  String get stgcAudiobookUiStudio => 'Audiobook UI & Player Studio';

  @override
  String stgcAuroraThemedTo(Object palette) {
    return 'Soft flowing glowing orbs and aurora waves themed to $palette';
  }

  @override
  String get stgcCustomBgWallpaper => 'Custom Background & Wallpaper';

  @override
  String stgcWallpaperActiveWith(Object palette) {
    return 'Wallpaper active with $palette ambient lighting';
  }

  @override
  String stgcDefaultThemeBg(Object palette) {
    return 'Default $palette theme background';
  }

  @override
  String stgcAppliedWallpaper(Object title) {
    return 'Applied \"$title\" wallpaper';
  }

  @override
  String get stgcHomeUiThemes => 'Home Page UI';

  @override
  String get stgcDropImagelessRails =>
      'Drops a Home rail when none of its titles can show a picture. A landscape tile has no name under it, so such a rail is a row of blank rectangles.';

  @override
  String stgcIntervalSeconds(Object seconds) {
    return 'Interval: ${seconds}s';
  }

  @override
  String get stgcLiquidGlassReset => 'Liquid Glass settings reset to defaults.';

  @override
  String get stgcLiveTvSportsUi => 'Live TV & Sports UI';

  @override
  String stgcNSeconds(Object seconds) {
    return '$seconds seconds';
  }

  @override
  String stgcNColumns(Object cols) {
    return '$cols Columns';
  }

  @override
  String get stgcXtreamPanels => 'Xtream Panels';

  @override
  String get stgcM3uPlaylists => 'M3U Playlists';

  @override
  String get stgcMangaUiAtmosphere => 'Manga UI & Reader Atmosphere';

  @override
  String get stgcMusicStudioApplied =>
      'Custom Fullscreen Player Studio layout set as active player!';

  @override
  String get stgcMusicUiAtmosphere => 'Music UI & Player Atmosphere';

  @override
  String get wgShellPressBackAgain => 'Press back again to exit';

  @override
  String get wgAniSeriesBadge => 'SERIES';

  @override
  String wgAniEpisodeCountShort(Object count) {
    return '$count EPS';
  }

  @override
  String get wgAniFeaturedAnime => 'FEATURED ANIME';

  @override
  String wgAniEpisodeCount(Object count) {
    return '$count Episodes';
  }

  @override
  String get wgAniPlayEpisodeOne => 'Play Ep 1';

  @override
  String wgComTabTitleCount(Object label, Object count) {
    return '$label, $count titles';
  }

  @override
  String get wgComTrailer => 'Trailer';

  @override
  String get wgComTrailerUnavailable => 'Trailer unavailable';

  @override
  String get wgComTrailerCannotPlay =>
      'This trailer could not be played in the app.';

  @override
  String get wgComCloseTrailer => 'Close trailer';

  @override
  String get wgComUnmuteTrailer => 'Unmute trailer';

  @override
  String get wgComMuteTrailer => 'Mute trailer';

  @override
  String get wgIptvLiveBadge => 'LIVE';

  @override
  String get wgIptvHdLive => 'HD Live';

  @override
  String get wgIptvHealthAlive => 'ALIVE';

  @override
  String get wgIptvHealthUnchecked => 'UNCHECKED';

  @override
  String get wgIptvHealthDead => 'DEAD';

  @override
  String get wgIptvLiveBroadcast => 'LIVE BROADCAST';

  @override
  String get wgIptvHeroTagline =>
      'Instant live multi-source streaming with real-time stream resolution & high-framerate playback.';

  @override
  String get wgIptvWatchLive => 'Watch Live';

  @override
  String get wgIptvStreamFeeds => 'Stream Feeds';

  @override
  String wgIptvRemovedPortals(Object count, Object plural) {
    return 'Removed $count portal$plural';
  }

  @override
  String wgIptvRemovedAllPortals(Object count) {
    return 'Removed all $count portals';
  }

  @override
  String wgIptvRemovedPlaylists(Object count, Object plural) {
    return 'Removed $count playlist$plural';
  }

  @override
  String wgIptvRemovedAllPlaylists(Object count) {
    return 'Removed all $count playlists';
  }

  @override
  String get wgIptvSearchChannels => 'Search channels...';

  @override
  String get wgIptvFinding => 'Finding…';

  @override
  String get wgIptvGenerate => 'Generate';

  @override
  String get wgIptvChoosePortalSource => 'Choose Portal Source';

  @override
  String get wgIptvCloudVault => 'Cloud Vault';

  @override
  String get wgIptvRedditCommunities => 'Reddit Communities';

  @override
  String get wgIptvRedditPastes => 'Live shared pastes from subreddits';

  @override
  String get wgIptvAddPortal => 'Add Portal';

  @override
  String get wgIptvDone => 'Done';

  @override
  String get wgIptvManage => 'Manage';

  @override
  String get wgIptvDeselectAll => 'Deselect All';

  @override
  String get wgIptvSelectAll => 'Select All';

  @override
  String wgIptvDeleteSelectedPortals(Object count) {
    return 'Delete ($count)';
  }

  @override
  String get wgIptvDeleteAll => 'Delete All';

  @override
  String get wgIptvAddXtreamPortal => 'Add Xtream Codes Portal';

  @override
  String get wgIptvServerUrlLabel =>
      'Server URL (e.g. http://example.com:8080)';

  @override
  String get wgIptvUsername => 'Username';

  @override
  String get wgIptvPassword => 'Password';

  @override
  String get wgIptvVerifySave => 'Verify & Save';

  @override
  String wgIptvChipAll(Object count) {
    return 'All ($count)';
  }

  @override
  String wgIptvChipCloudVault(Object count) {
    return 'Cloud Vault ($count)';
  }

  @override
  String wgIptvChipFavorites(Object count) {
    return 'Favorites ⭐ ($count)';
  }

  @override
  String get wgIptvNoXtreamPortals => 'No Xtream portals loaded';

  @override
  String get wgIptvNoMatchingChannels => 'No matching channels';

  @override
  String get wgIptvCopyLogin => 'Copy Login (url:user:pass)';

  @override
  String wgIptvCopiedText(Object text) {
    return 'Copied: $text';
  }

  @override
  String get wgIptvRemoveFavorite => 'Remove Favorite';

  @override
  String get wgIptvAddToFavorites => 'Add to Favorites';

  @override
  String get wgIptvRemovePortal => 'Remove Portal';

  @override
  String wgIptvExpiryShort(Object expiry) {
    return 'Exp: $expiry';
  }

  @override
  String wgIptvConnShort(Object active, Object max) {
    return 'Conn: $active/$max';
  }

  @override
  String wgIptvGroupExpiry(Object expiry) {
    return 'Exp: $expiry';
  }

  @override
  String wgIptvGroupConn(Object active, Object max) {
    return 'Conn: $active/$max';
  }

  @override
  String get wgIptvNoLiveChannelsPortal =>
      'No live channels available for this portal';

  @override
  String wgIptvLiveChannelCount(Object count) {
    return '$count live channels';
  }

  @override
  String get wgIptvAddM3uUrl => 'Add M3U URL';

  @override
  String wgIptvDeleteSelectedM3u(Object count) {
    return 'Delete ($count)';
  }

  @override
  String get wgIptvAddM3uSubscription => 'Add M3U Playlist Subscription';

  @override
  String get wgIptvPlaylistName => 'Playlist Name';

  @override
  String get wgIptvM3uUrlLabel => 'M3U / M3U8 URL';

  @override
  String get wgIptvFetchSave => 'Fetch & Save';

  @override
  String get wgIptvNoM3uPlaylists => 'No M3U playlists loaded';

  @override
  String get wgIptvCopyPlaylistUrl => 'Copy Playlist URL';

  @override
  String get wgIptvRemovePlaylist => 'Remove Playlist';

  @override
  String wgIptvPlaylistChannelsSource(Object count, Object source) {
    return '$count channels$source';
  }

  @override
  String get wgIptvNoChannelsPlaylist => 'No channels in this playlist';

  @override
  String wgIptvChannelCount(Object count) {
    return '$count channels';
  }

  @override
  String get wgMgaUnknownYear => 'Unknown Year';

  @override
  String get wgMgaCategories => 'Manga Categories';

  @override
  String get wgMgaFilterCategories => 'Filter categories...';

  @override
  String get wgMgaNoMatchingCategories => 'No matching categories';

  @override
  String get wgMgaResetAllCategories => 'Reset to All Categories';

  @override
  String get wgMovSeriesBadge => 'SERIES';

  @override
  String get wgMovAnimeBadge => 'ANIME';

  @override
  String get wgPlySurround51 => '5.1 Surround';

  @override
  String get wgPlySurround71 => '7.1 Surround';

  @override
  String wgPlyAudioChannels(Object count) {
    return '$count ch';
  }

  @override
  String wgPlySeasonLabel(Object season) {
    return 'Season $season';
  }

  @override
  String get wgPlySeasonOne => 'Season 1';

  @override
  String wgPlySeasonEpisodeSummary(Object season, Object count) {
    return '$season • $count Episodes';
  }

  @override
  String wgPlySeasonTab(Object season) {
    return 'Season $season';
  }

  @override
  String wgPlyEpisodeFallback(Object episode) {
    return 'Episode $episode';
  }

  @override
  String wgPlyEpisodeBadge(Object episode) {
    return 'EP $episode';
  }

  @override
  String wgPlySeasonEpisodeBadge(Object season, Object episode) {
    return 'S$season : E$episode';
  }

  @override
  String wgPlySleepMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String get wgPlySubtitleSizeCaps => 'SUBTITLE SIZE';

  @override
  String get wgPlyDecreaseSize => 'Decrease size';

  @override
  String get wgPlyIncreaseSize => 'Increase size';

  @override
  String get wgPlyResetTo100 => 'Reset to 100%';

  @override
  String get wgPlySubBarClose => 'Close';

  @override
  String get wgPlySubAppearance => 'Subtitle Appearance';

  @override
  String get wgPlySubAppearanceSubtitle =>
      'libass / libmpv hardware-rendered subtitles';

  @override
  String get wgPlyResetSubDefaults => 'Reset Subtitle Defaults';

  @override
  String get wgPlySubModalClose => 'Close';

  @override
  String get wgPlySubTabTypography => 'Typography';

  @override
  String get wgPlySubTabColors => 'Colors & Box';

  @override
  String get wgPlySubTabOutline => 'Outline & Shadow';

  @override
  String get wgPlySubTabPosition => 'Position';

  @override
  String get wgPlySubTabAdvanced => 'Advanced / ASS';

  @override
  String get wgPlySubFontFamily => 'FONT FAMILY';

  @override
  String get wgPlySubDefaultFont => 'Default (Lumora Subfont)';

  @override
  String wgPlySubBaseFontSize(Object size) {
    return 'BASE FONT SIZE (${size}pt)';
  }

  @override
  String wgPlySubScaleMultiplier(Object percent) {
    return 'SCALE MULTIPLIER ($percent%)';
  }

  @override
  String get wgPlySubBold => 'Bold Text';

  @override
  String get wgPlySubItalic => 'Italic Text';

  @override
  String get wgPlySubTextColor => 'SUBTITLE TEXT COLOR';

  @override
  String get wgPlySubBackgroundBox =>
      'BACKGROUND BOX (ACCESSIBILITY & READABILITY)';

  @override
  String get wgPlySubOutlineColor => 'OUTLINE / BORDER COLOR';

  @override
  String wgPlySubOutlineThickness(Object size) {
    return 'OUTLINE THICKNESS (${size}px)';
  }

  @override
  String wgPlySubShadowOffset(Object size) {
    return 'DROP SHADOW OFFSET (${size}px)';
  }

  @override
  String get wgPlySubHorizontalAlign => 'HORIZONTAL ALIGNMENT';

  @override
  String get wgPlySubAlignLeft => 'Left';

  @override
  String get wgPlySubAlignCenter => 'Center';

  @override
  String get wgPlySubAlignRight => 'Right';

  @override
  String wgPlySubBottomMargin(Object size) {
    return 'BOTTOM MARGIN / OFFSET (${size}px)';
  }

  @override
  String wgPlySubVerticalPosition(Object percent) {
    return 'VERTICAL POSITION ($percent%)';
  }

  @override
  String get wgPlyAssPreserveTitle =>
      'Preserve Anime & SSA/ASS Styling (Recommended)';

  @override
  String get wgPlyAssPreserveDesc =>
      'Leaves SSA/ASS anime subtitles untouched to preserve custom karaoke, styling & positions. Plain SRT/VTT are styled with your custom theme.';

  @override
  String get wgPlyAssScaleTitle => 'Scale Only';

  @override
  String get wgPlyAssScaleDesc =>
      'Applies size scaling to SSA/ASS scripts while preserving their fonts, colors, and author typography.';

  @override
  String get wgPlyAssOverrideTitle => 'Override Colors & Outlines';

  @override
  String get wgPlyAssOverrideDesc =>
      'Applies your custom colors and outlines on top of SSA/ASS subtitle scripts.';

  @override
  String get wgPlyAssForceTitle => 'Force Full Override (Aggressive)';

  @override
  String get wgPlyAssForceDesc =>
      'Forces all custom fonts, colors, and styles onto all subtitle formats (may break anime effects).';

  @override
  String get wgPlySubRenderingEngine => 'SUBTITLE RENDERING ENGINE';

  @override
  String get wgPlyFlutterSubEngine => 'Flutter Subtitle Engine (Recommended)';

  @override
  String get wgPlyFlutterSubEngineDesc =>
      '100% reliable hardware-accelerated subtitle overlay across Android, iOS, Windows, Mac, and Linux with full styling support.';

  @override
  String get wgPlyMpvLibassEngine => 'Native MPV libass Engine';

  @override
  String get wgPlyMpvLibassEngineDesc =>
      'Direct GPU video texture rendering powered by libass with bundled Poppins font and SSA/ASS script layout support.';

  @override
  String get wgPlyAssOverrideMode => 'SSA / ASS FANSUB SCRIPT OVERRIDE MODE';

  @override
  String get wgPlyCopyStreamUrl => 'Copy Stream URL';

  @override
  String wgPlySyncSaveError(Object error) {
    return 'Error saving sync: $error';
  }

  @override
  String get wgPlySyncHintSection =>
      'Tap first & last line of section, then tap line playing now and Sync from here.';

  @override
  String get wgPlySyncHintFirst =>
      'Tap the line you hear right now, then tap Sync from here.';

  @override
  String get wgPlySyncHintSecond =>
      'Point 1 set. If subtitles drift later on, tap Sync from here at a later line.';

  @override
  String get wgPlySyncMinChars => '3+ chars';

  @override
  String wgSrchMagnetNoFiles(Object service) {
    return '$service returned no files for this magnet.';
  }

  @override
  String get wgSrchMagnetMetadataFailed =>
      'Could not retrieve torrent metadata from swarm. Check peer connectivity.';

  @override
  String wgSrchUsingProvider(Object provider) {
    return 'Using $provider for files...';
  }

  @override
  String get wgSrchConnectingPeers => 'Connecting to swarm peers...';

  @override
  String get wgSrchGatheringFiles => 'Gathering file list & stream metadata';

  @override
  String get wgSrchMagnetReadFailed => 'Failed to Read Magnet';

  @override
  String get wgSrchTryAgain => 'Try Again';

  @override
  String get wgSrchNoFilesMatch => 'No files match filter';

  @override
  String wgSrchProviderCloud(Object provider) {
    return '$provider Cloud';
  }

  @override
  String get wgSrchP2pSwarm => 'P2P Swarm';

  @override
  String wgSrchFileCount(Object count, Object unit) {
    return '$count $unit';
  }

  @override
  String wgSrchVideoCount(Object count, Object unit) {
    return '$count $unit';
  }

  @override
  String get wgSrchFilterFilesHint => 'Filter files by name...';

  @override
  String wgSrchChipAll(Object count) {
    return 'All ($count)';
  }

  @override
  String wgSrchChipVideos(Object count) {
    return 'Videos ($count)';
  }

  @override
  String wgSrchChipOther(Object count) {
    return 'Other ($count)';
  }

  @override
  String get wgSrchPlay => 'Play';

  @override
  String get wgSrchNonVideo => 'Non-video';

  @override
  String get wgSrchKeySpace => 'Space';

  @override
  String get wgSrchKeyClear => 'Clear';

  @override
  String get wgSrchKeySearch => 'Search';

  @override
  String get wgUpdAvailableCaps => 'UPDATE AVAILABLE';

  @override
  String wgUpdVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get wgUpdCurrent => 'Current';

  @override
  String get wgUpdLatest => 'Latest';

  @override
  String get wgUpdWhatsNew => 'WHAT\'S NEW';

  @override
  String get wgUpdNoReleaseNotes =>
      'No release notes were published for this version.';

  @override
  String get wgUpdIosRedirect =>
      'iOS: You\'ll be redirected to GitHub to download the IPA';

  @override
  String get wgUpdMacRedirect =>
      'macOS: You\'ll be redirected to GitHub to download';

  @override
  String get wgUpdDownloading => 'Downloading...';

  @override
  String get wgUpdLater => 'Later';

  @override
  String get wgUpdUpdateNow => 'Update Now';

  @override
  String get wgUpdNotVerified => 'Update could not be verified';

  @override
  String get wgUpdCancel => 'Cancel';

  @override
  String get wgUpdOpenReleasePage => 'Open release page';

  @override
  String wgIptvChipMyPortals(Object count) {
    return 'My Portals ($count)';
  }

  @override
  String get wgUpdNoChecksum =>
      'This release does not publish a SHA-256 checksum, so Lumora will not install it automatically. Open the release page and verify the download yourself before installing it.';

  @override
  String get wgUpdInstallPermission =>
      'Allow \"Install unknown apps\" for Lumora in Android settings, then try again.';

  @override
  String wgUpdFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String wgUpdDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get wgUpdChecksumMismatch =>
      'The update\'s checksum did not match, so the download was deleted.';

  @override
  String get wgUpdSignatureConflictHint =>
      'The install can fail with \"App not installed as package conflicts with an existing package\" when the previously installed copy was signed with a different key. Uninstall that copy once and install again; export your settings first from Settings → Backup & Restore (JSON) to keep them.';

  @override
  String get wgUpdDownloadComplete => 'Download complete';

  @override
  String get wgUpdWillCloseAndInstall =>
      'Lumora will close and install the update.';

  @override
  String get wgUpdDownloadedTo => 'Update downloaded to:';

  @override
  String get wgUpdMakeExecutable => 'Make the file executable and run it:';

  @override
  String get wgUpdOpenFolder => 'Open folder';

  @override
  String get wgUpdCloseAndInstall => 'Close and install now';

  @override
  String get wgUpdOk => 'OK';

  @override
  String get updatesCheckFailed =>
      'Couldn\'t check for updates. Check your connection and try again.';

  @override
  String detailsRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get authTagline => 'Light, shadow and every story worth watching';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authInviteCode => 'Invite code';

  @override
  String get authInviteHint =>
      'An invite code is needed once, to create your account. Ask the admin for one.';

  @override
  String get authSubmitSignIn => 'Sign in';

  @override
  String get authSubmitSignUp => 'Create account';

  @override
  String get authWorking => 'Please wait…';

  @override
  String get authErrInvalidInvite =>
      'This invite code is not valid, or has been used.';

  @override
  String get authErrInviteMissing => 'Enter your invite code.';

  @override
  String get authErrWrongPassword => 'Wrong email or password.';

  @override
  String get authErrEmailTaken =>
      'This email already has an account. Sign in instead.';

  @override
  String get authErrWeakPassword => 'Use a password of at least 6 characters.';

  @override
  String get authErrInvalidEmail => 'That email address doesn\'t look right.';

  @override
  String get authErrEmailNotConfirmed =>
      'Confirm your email first: open the link we sent you.';

  @override
  String get authErrNetwork =>
      'Can\'t reach the server. Check your connection.';

  @override
  String get authErrUnknown => 'Something went wrong. Please try again.';

  @override
  String get authConfirmEmail =>
      'Account created. Open the link in your email, then sign in.';

  @override
  String get accountSection => 'Account';

  @override
  String accountSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get accountAdmin => 'Admin';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutSubtitle => 'Sign out of Lumora on this device';

  @override
  String get inviteManage => 'Invite codes';

  @override
  String get inviteManageSubtitle =>
      'Make codes for friends to create an account';

  @override
  String get invitesTitle => 'Invite codes';

  @override
  String get invitesIntro =>
      'Each code creates one account, once. Give it to a friend; they enter it when they create their account.';

  @override
  String get invitesNote => 'Note (optional, e.g. who it\'s for)';

  @override
  String invitesGenerate(int count) {
    return 'Make $count';
  }

  @override
  String invitesCopied(String code) {
    return 'Copied $code';
  }

  @override
  String get invitesCopy => 'Copy';

  @override
  String get invitesEmpty => 'No invite codes yet.';

  @override
  String get invitesUnused => 'Not used yet';

  @override
  String invitesUsedBy(String email) {
    return 'Used by $email';
  }

  @override
  String invitesCount(int total, int unused) {
    return '$total codes · $unused unused';
  }

  @override
  String get invitesLoadFailed => 'Couldn\'t load the codes.';

  @override
  String get invitesCreateFailed => 'Couldn\'t make codes.';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authCreateAccount => 'Create your account';

  @override
  String get authSignInSubtitle =>
      'Sign in to pick up your list and what you were watching.';

  @override
  String get authSignUpSubtitle =>
      'Use the invite code a friend gave you. Each code works once.';

  @override
  String get authFirstTime => 'New here?';

  @override
  String get authUseInvite => 'Sign up with an invite code';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authSignInInstead => 'Sign in';

  @override
  String get authDragToTurn => 'Drag to turn';

  @override
  String authSwitchFigure(String name) {
    return 'Show $name';
  }

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authPasswordHint => 'At least 6 characters';

  @override
  String get authInviteFieldHint => 'ABCD-2345';

  @override
  String get splashLoading => 'Starting';

  @override
  String homeTodayTop(int rank) {
    return 'Top $rank today';
  }

  @override
  String get homeKindSeries => 'Series';

  @override
  String get homeKindMovie => 'Film';

  @override
  String get homeHeroNext => 'Next';

  @override
  String get homeHeroPrevious => 'Previous';

  @override
  String homeHeroSlide(int index) {
    return 'Slide $index';
  }

  @override
  String get moreAiPicks => 'AI picks';

  @override
  String get moreCalendar => 'Airing calendar';

  @override
  String get browseMoviesTv => 'Movies & TV';

  @override
  String get browseCollections => 'Collections';

  @override
  String get browseManga => 'Manga';

  @override
  String get browseBooks => 'Books';

  @override
  String get browseAudiobooks => 'Audiobooks';

  @override
  String get browseMusic => 'Music';

  @override
  String get liveCatPremier => 'Premier Live Broadcasts';

  @override
  String get liveCatEspn => 'ESPN & College Basketball (NCAA)';

  @override
  String get liveCatUsSports => 'US Major Leagues & Sports';

  @override
  String get liveCatSoccer => 'Global Football & Soccer';

  @override
  String get liveCatBoxing => 'Boxing';

  @override
  String get liveCatCombat => 'Combat & Martial Arts';

  @override
  String get liveCatRacing => 'Motorsport & Racing';

  @override
  String get liveCatMovies => 'Movies & Premium Networks';

  @override
  String get liveCatNews => '24/7 Global News Networks';

  @override
  String get liveCatArabic => 'Arabic & Regional Hub';

  @override
  String get liveCatDiscovery => 'Discovery & Documentaries';

  @override
  String get liveCatKids => 'Kids & Family';

  @override
  String get liveCatUs => 'US Region';

  @override
  String get liveCatUk => 'UK Region';

  @override
  String get liveCatCanada => 'Canada Region';

  @override
  String get liveCatBayArea => 'Bay Area';

  @override
  String get liveCatIntlSports => 'International Sports';

  @override
  String get liveSubtitle => 'Live channels from your sources';

  @override
  String listSummary(int count) {
    return '$count saved';
  }

  @override
  String get dscRequired => 'Required';

  @override
  String get dscEnter => 'Enter';

  @override
  String get dscTypeTv => 'TV';

  @override
  String get dscTypeChannel => 'Channels';

  @override
  String get tvStatusStopped => 'Stopped.';

  @override
  String get tvStatusDiscovering => 'Discovering fresh portals…';

  @override
  String get tvStatusNoMore => 'No more portals available.';

  @override
  String tvStatusVerifying(int count) {
    return 'Verifying $count portals…';
  }

  @override
  String tvStatusVerifyingProgress(int done, int total, int active) {
    return 'Verifying portals $done/$total · $active active';
  }

  @override
  String tvStatusScanning(int count) {
    return 'Scanning $count portals in parallel…';
  }

  @override
  String tvStatusFound(int count) {
    return 'Found $count streams · verifying health…';
  }

  @override
  String tvStatusSniffing(int checked, int total, int live) {
    return 'Sniffing $checked/$total · $live verified live';
  }

  @override
  String tvGuideFromPanel(String channel) {
    return 'Programme data comes from the channel\'s own panel, so it appears once one of your portals has a verified live feed for $channel.';
  }

  @override
  String get liveCatSports => 'Sports';

  @override
  String get liveCatSoccerShort => 'Soccer';

  @override
  String get liveCatMoviesShort => 'Movies';

  @override
  String get liveCatNewsShort => 'News';

  @override
  String get authWithGoogle => 'Continue with Google';

  @override
  String get authWithFacebook => 'Continue with Facebook';

  @override
  String get authOr => 'or';

  @override
  String get authRedeemTitle => 'One invite code, once';

  @override
  String get authRedeemBody =>
      'Lumora is invite-only. The first time you sign in with GitHub or Discord, enter the invite code a friend gave you.';

  @override
  String get authRedeemAction => 'Continue';

  @override
  String get authRedeemSwitch => 'Use another account';

  @override
  String get authOAuthFailed => 'Couldn\'t open the sign-in page.';

  @override
  String get authWithGithub => 'Continue with GitHub';

  @override
  String get authWithDiscord => 'Continue with Discord';

  @override
  String get authForgot => 'Forgot password?';

  @override
  String get authForgotNeedEmail => 'Enter your email above first.';

  @override
  String authForgotSent(String email) {
    return 'A reset link is on its way to $email. Open it on this device to set a new password.';
  }

  @override
  String get authNewPasswordTitle => 'Set a new password';

  @override
  String authNewPasswordBody(String email) {
    return 'Choose a new password for $email.';
  }

  @override
  String get authNewPasswordAction => 'Save password';

  @override
  String get authNewPasswordSaved => 'Password changed.';

  @override
  String get authResetCodeTitle => 'Check your email';

  @override
  String authResetCodeBody(String email) {
    return 'We sent a code to $email. Enter it here, on any device you read the email on.';
  }

  @override
  String get authResetCode => 'Code';

  @override
  String get authResetCodeHint => 'The digits in the email';

  @override
  String get authResetVerify => 'Continue';

  @override
  String get authResetWrongCode =>
      'That code is wrong or has expired. Send a new one.';

  @override
  String get authResetResend => 'Send again';

  @override
  String get authResetBack => 'Back to sign in';

  @override
  String get authErrSamePassword =>
      'That\'s your current password. Choose a different one.';

  @override
  String get authNewPasswordKeep => 'Keep my current password';

  @override
  String get filterLoading => 'Loading…';

  @override
  String get filterEmptyOrFailed =>
      'Nothing to show. These filters may have no matches, or the list couldn\'t load.';

  @override
  String get filterMoreFailed => 'Couldn\'t load more.';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileNameLabel => 'Nickname';

  @override
  String get profileNameHint => 'What friends see';

  @override
  String get profileColorLabel => 'Avatar colour';

  @override
  String get profileSave => 'Save';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get profileSaveFailed =>
      'Couldn\'t save. Check your connection and try again.';

  @override
  String whatsNewTitle(String version) {
    return 'What\'s new in Lumora $version';
  }

  @override
  String get whatsNewDone => 'Got it';

  @override
  String get newEpBadge => 'New';

  @override
  String newEpCode(String season, String episode) {
    return 'S$season E$episode';
  }

  @override
  String get newEpRail => 'New episodes';

  @override
  String newEpAirsNext(String date) {
    return 'Next $date';
  }

  @override
  String newEpMonthDay(String month, String day) {
    return '$month/$day';
  }

  @override
  String get newEpCalTitle => 'My shows calendar';

  @override
  String get newEpCalSubtitle => 'When the series in My List air next';

  @override
  String get newEpCalEmptyTitle => 'No series in My List yet';

  @override
  String get newEpCalEmptyBody =>
      'Add series to My List to see their new episodes here';

  @override
  String get newEpCalNoneThisDay => 'None of your series air this day';

  @override
  String get newEpCalChecking => 'Checking air dates…';

  @override
  String get mangaGenreAll => 'All';

  @override
  String get mangaGenreAction => 'Action';

  @override
  String get mangaGenreAdventure => 'Adventure';

  @override
  String get mangaGenreComedy => 'Comedy';

  @override
  String get mangaGenreDrama => 'Drama';

  @override
  String get mangaGenreFantasy => 'Fantasy';

  @override
  String get mangaGenreHistorical => 'Historical';

  @override
  String get mangaGenreHorror => 'Horror';

  @override
  String get mangaGenreIsekai => 'Isekai';

  @override
  String get mangaGenreMartialArts => 'Martial Arts';

  @override
  String get mangaGenreMystery => 'Mystery';

  @override
  String get mangaGenrePsychological => 'Psychological';

  @override
  String get mangaGenreRomance => 'Romance';

  @override
  String get mangaGenreSchoolLife => 'School Life';

  @override
  String get mangaGenreSciFi => 'Sci-fi';

  @override
  String get mangaGenreSeinen => 'Seinen';

  @override
  String get mangaGenreShounen => 'Shounen';

  @override
  String get mangaGenreSliceOfLife => 'Slice of Life';

  @override
  String get mangaGenreSports => 'Sports';

  @override
  String get mangaGenreSupernatural => 'Supernatural';

  @override
  String get mangaGenreTragedy => 'Tragedy';

  @override
  String get mangaTypeManga => 'Manga';

  @override
  String get mangaTypeManhwa => 'Manhwa';

  @override
  String get mangaTypeManhua => 'Manhua';

  @override
  String get mangaModeWebtoon => 'Vertical scroll (webtoon)';

  @override
  String get mangaModeLtr => 'Pages, left to right';

  @override
  String get mangaModeRtl => 'Pages, right to left (manga)';

  @override
  String get mangaWidthFull => 'Full screen';

  @override
  String get mangaWidthCompact => 'Compact';

  @override
  String get mangaWidthStandard => 'Standard';

  @override
  String get mangaWidthWide => 'Wide';

  @override
  String get mangaBgPitchBlack => 'Pitch Black';

  @override
  String get mangaBgDeepCharcoal => 'Deep Charcoal';

  @override
  String get mangaBgDarkSlate => 'Dark Slate';

  @override
  String get mangaBgSepiaDark => 'Sepia Dark';

  @override
  String get mangaDensityCompact => 'Compact';

  @override
  String get mangaDensityStandard => 'Standard';

  @override
  String get mangaDensitySpacious => 'Spacious';

  @override
  String mangaChapterShort(String number) {
    return 'Ch. $number';
  }

  @override
  String get mangaPageTitle => 'Manga';

  @override
  String get mangaPageSubtitle =>
      'Manga, manhwa and manhua to read on any screen';

  @override
  String get mangaReaderSettings => 'Reader';

  @override
  String booksChapterShort(String number) {
    return 'Ch. $number';
  }

  @override
  String booksChapterOfTotal(String current, String total) {
    return 'Ch. $current of $total';
  }

  @override
  String booksFontSizePt(String size) {
    return '$size pt';
  }

  @override
  String booksFontSizePx(String size) {
    return '$size px';
  }

  @override
  String get booksPreviewSample =>
      '“It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.”';

  @override
  String get booksPageTitle => 'Books';

  @override
  String get booksPageSubtitle =>
      'Find a book, download it once, read it anywhere';

  @override
  String get booksReaderStyle => 'Reading style';

  @override
  String get booksShowControls => 'Show controls';

  @override
  String get musArtistsHeading => 'Artists';

  @override
  String get musAlbumsHeading => 'Albums';

  @override
  String get musPlaylistsHeading => 'Playlists';

  @override
  String get musGenrePopHits => 'Pop Hits';

  @override
  String get musGenreRockClassics => 'Rock Classics';

  @override
  String get musGenreHeavyMetal => 'Heavy Metal';

  @override
  String get musGenreClassicalPiano => 'Classical Piano';

  @override
  String musHiResLossless(String quality) {
    return 'Hi-Res Lossless · $quality';
  }

  @override
  String musHiResLosslessAudio(String quality) {
    return '$quality · Hi-Res lossless audio';
  }

  @override
  String get musPlayTip => 'Play';

  @override
  String get musPauseTip => 'Pause';

  @override
  String get musPreviousTip => 'Previous';

  @override
  String get musNextTip => 'Next';

  @override
  String get musRepeatTip => 'Repeat';

  @override
  String get musLikeTip => 'Like';

  @override
  String get musAddToPlaylistTip => 'Add to playlist';

  @override
  String get musLyricsTip => 'Lyrics';

  @override
  String get musQueueTip => 'Queue';

  @override
  String get musClosePlayerTip => 'Close player';

  @override
  String get musMoreTip => 'More';

  @override
  String get musRemoveFromQueueTip => 'Remove from queue';

  @override
  String get musRemoveFromPlaylistTip => 'Remove from playlist';

  @override
  String get musClearSearchTip => 'Clear search';

  @override
  String get musCancelDownloadTip => 'Cancel download';

  @override
  String get musNowPlayingKicker => 'Now playing';

  @override
  String get abkCatFantasy => 'Fantasy';

  @override
  String get abkCatSciFi => 'Sci-Fi';

  @override
  String get abkCatMystery => 'Mystery';

  @override
  String get abkCatThriller => 'Thriller';

  @override
  String get abkCatNonFiction => 'Non-Fiction';

  @override
  String get abkCatSelfHelp => 'Self-Help';

  @override
  String get abkCatHorror => 'Horror';

  @override
  String get abkCatRomance => 'Romance';

  @override
  String get abkCatAdventure => 'Adventure';

  @override
  String get abkCatClassics => 'Classics';

  @override
  String abkTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get abkTorrentSource => 'AudiobookBay · torrent';

  @override
  String get abkAiGenerated => 'AI generated';

  @override
  String get abkAiGeneratedKokoro => 'AI generated · Kokoro TTS';

  @override
  String get abkUnknownAuthor => 'Unknown author';

  @override
  String abkSplitMessage(String words, String parts, String list) {
    return 'This book has about $words words. It will be split into $parts parts along chapter boundaries and queued:\n\n$list';
  }

  @override
  String abkSplitPartLine(String name, String words) {
    return '• $name (about $words words)';
  }

  @override
  String get abkBackTip => 'Back';

  @override
  String get abkPlaybackSpeedTip => 'Playback speed';

  @override
  String get abkRemoveFromContinue => 'Remove from Continue Listening?';

  @override
  String get abkClearSearchTip => 'Clear search';

  @override
  String get abkDeleteJobTip => 'Remove';

  @override
  String get playerSubPreviewSample => 'Lumora • Sample subtitle preview';

  @override
  String get abkDensityCompact => 'Compact';

  @override
  String get abkDensityStandard => 'Standard';

  @override
  String get abkDensitySpacious => 'Spacious';

  @override
  String get abkPresetModern => 'Classic';

  @override
  String get abkPresetVinyl => 'Turntable';

  @override
  String get abkPresetCapsule => 'Minimal';

  @override
  String get abkPresetCanvas => 'Big cover';

  @override
  String get abkPresetCustom => 'Custom';

  @override
  String get abkSeekWaveform => 'Waveform';

  @override
  String get abkSeekGradient => 'Bar';

  @override
  String get abkSeekSlider => 'Slider';

  @override
  String get abkSeekRing => 'Ring';

  @override
  String get abkButtonCircle => 'Circle';

  @override
  String get abkButtonGlass => 'Outline';

  @override
  String get abkButtonSquare => 'Square';

  @override
  String get abkButtonPill => 'Pill';

  @override
  String get profilePhotoUpload => 'Upload photo';

  @override
  String get profilePhotoRemove => 'Remove photo';

  @override
  String get profilePhotoFailed =>
      'Couldn\'t upload that photo. Try another image.';

  @override
  String get booksAlignLeft => 'Align left';

  @override
  String get booksAlignJustify => 'Justify';

  @override
  String get wgPlyAspectFit => 'Fit to screen (Contain)';

  @override
  String get wgPlyAspectCover => 'Fill screen (Crop/Zoom)';

  @override
  String get wgPlyAspectStretch => 'Stretch to fill';

  @override
  String get wgPlySubColorWhite => 'White';

  @override
  String get wgPlySubColorCinemaYellow => 'Cinema Yellow';

  @override
  String get wgPlySubColorAmberGold => 'Amber Gold';

  @override
  String get wgPlySubColorElectricCyan => 'Electric Cyan';

  @override
  String get wgPlySubColorNeonGreen => 'Neon Green';

  @override
  String get wgPlySubColorVibrantOrange => 'Vibrant Orange';

  @override
  String get wgPlySubColorSoftRose => 'Soft Rose';

  @override
  String get wgPlySubColorLightGray => 'Light Gray';

  @override
  String get wgPlySubColorBlack => 'Black';

  @override
  String get wgPlySubColorDarkSlate => 'Dark Slate';

  @override
  String get wgPlySubColorGold => 'Gold';

  @override
  String get wgPlySubColorCrimson => 'Crimson';

  @override
  String get wgPlySubColorNeonCyan => 'Neon Cyan';

  @override
  String get wgPlySubBoxNone => 'None';

  @override
  String wgPlySubBoxDark(String percent) {
    return '$percent% Dark';
  }

  @override
  String get wgPlySubBoxSolid => '100% Solid';

  @override
  String get wgPlySubBoxIndigo => '50% Indigo';

  @override
  String get wgPlySubBoxDescTransparent => 'Transparent';

  @override
  String get wgPlySubBoxDescSubtle => 'Subtle';

  @override
  String get wgPlySubBoxDescStandard => 'Standard Box';

  @override
  String get wgPlySubBoxDescHighContrast => 'High Contrast';

  @override
  String get wgPlySubBoxDescOpaque => 'Opaque Black';

  @override
  String get wgPlySubBoxDescSlate => 'Slate Tint';

  @override
  String get tvDescEspn =>
      'ESPN+, ESPN, ESPN2, ESPNU, NCAA Men\'s & Women\'s CBB, SEC & ACC';

  @override
  String get tvDescCombat => 'UFC Fight Pass, WWE, AEW, World Boxing & PPV';

  @override
  String get musRailTrending => '🔥 Top Global & Trending Hits';

  @override
  String get musRailPop => '🌟 Pop Essentials';

  @override
  String get musRailHipHop => '🎙️ Hip-Hop & Rap Heavyweights';

  @override
  String get musRailElectronic => '🎧 Electronic, Dance & EDM';

  @override
  String get musRailRock => '🎸 Rock Classics & Alternative';

  @override
  String get musRailSoundtracks => '🎬 Film & Anime Soundtracks';

  @override
  String get musRailChill => '🌙 Chill, Lofi & Ambient Beats';

  @override
  String abkDebridCouldNotResolveAudio(String service) {
    return '$service could not resolve the audio stream.';
  }

  @override
  String get abkAudioStreamUrlUnresolved =>
      'The audio stream URL could not be resolved.';

  @override
  String get abkCatalogueUnavailableTitle =>
      'The online audiobook catalogue isn\'t available in this build';

  @override
  String get abkCatalogueUnavailableBody =>
      'You can still import your own MP3 or M4B audiobooks, or turn an EPUB into an audiobook, in the Studio.';

  @override
  String get abkCatalogueUnavailableBodyImportOnly =>
      'You can still import your own MP3 or M4B audiobooks in the Studio.';

  @override
  String get abkHubSubtitleOwnLibrary => 'Your own audiobooks, ready to listen';

  @override
  String get detailsSpecials => 'Specials';
}
