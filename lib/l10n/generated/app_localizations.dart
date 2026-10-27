import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Lumora'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get navBrowse;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navLiveTv.
  ///
  /// In en, this message translates to:
  /// **'Live TV'**
  String get navLiveTv;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCopyReport.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get actionCopyReport;

  /// No description provided for @actionSaveReport.
  ///
  /// In en, this message translates to:
  /// **'Save report'**
  String get actionSaveReport;

  /// No description provided for @actionCopyDiagnostic.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostic'**
  String get actionCopyDiagnostic;

  /// No description provided for @shellFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get shellFullscreen;

  /// No description provided for @shellExitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit Fullscreen'**
  String get shellExitFullscreen;

  /// No description provided for @shellFullscreenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen (F11)'**
  String get shellFullscreenTooltip;

  /// No description provided for @shellExitFullscreenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Exit Fullscreen (F11)'**
  String get shellExitFullscreenTooltip;

  /// No description provided for @errorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load movies'**
  String get errorLoadFailed;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorUnknown;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @shortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get shortcutsTitle;

  /// No description provided for @shortcutsClose.
  ///
  /// In en, this message translates to:
  /// **'Close keyboard shortcuts'**
  String get shortcutsClose;

  /// No description provided for @shortcutsGroupAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get shortcutsGroupAnywhere;

  /// No description provided for @shortcutsGroupMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving around'**
  String get shortcutsGroupMoving;

  /// No description provided for @shortcutsGroupPlaying.
  ///
  /// In en, this message translates to:
  /// **'While playing'**
  String get shortcutsGroupPlaying;

  /// No description provided for @shortcutsGroupReading.
  ///
  /// In en, this message translates to:
  /// **'While reading'**
  String get shortcutsGroupReading;

  /// No description provided for @shortcutsShowSheet.
  ///
  /// In en, this message translates to:
  /// **'Show this sheet'**
  String get shortcutsShowSheet;

  /// No description provided for @shortcutsShowSheetNote.
  ///
  /// In en, this message translates to:
  /// **'Also Shift + /'**
  String get shortcutsShowSheetNote;

  /// No description provided for @shortcutsToggleFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Toggle fullscreen'**
  String get shortcutsToggleFullscreen;

  /// No description provided for @shortcutsLeaveFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Leave fullscreen, or close what is open'**
  String get shortcutsLeaveFullscreen;

  /// No description provided for @shortcutsLeaveFullscreenNote.
  ///
  /// In en, this message translates to:
  /// **'Never navigates away from a page by itself'**
  String get shortcutsLeaveFullscreenNote;

  /// No description provided for @shortcutsMyList.
  ///
  /// In en, this message translates to:
  /// **'My List and Downloads'**
  String get shortcutsMyList;

  /// No description provided for @shortcutsSearchMacNote.
  ///
  /// In en, this message translates to:
  /// **'Cmd + K on macOS'**
  String get shortcutsSearchMacNote;

  /// No description provided for @shortcutsSettingsMacNote.
  ///
  /// In en, this message translates to:
  /// **'Cmd + , on macOS'**
  String get shortcutsSettingsMacNote;

  /// No description provided for @shortcutsPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play or pause'**
  String get shortcutsPlayPause;

  /// No description provided for @shortcutsPlayPauseNote.
  ///
  /// In en, this message translates to:
  /// **'K does the same'**
  String get shortcutsPlayPauseNote;

  /// No description provided for @shortcutsSeek.
  ///
  /// In en, this message translates to:
  /// **'Back or forward 10 seconds'**
  String get shortcutsSeek;

  /// No description provided for @shortcutsSeekNote.
  ///
  /// In en, this message translates to:
  /// **'The arrow keys do this too, when the video has focus'**
  String get shortcutsSeekNote;

  /// No description provided for @shortcutsMute.
  ///
  /// In en, this message translates to:
  /// **'Mute or unmute'**
  String get shortcutsMute;

  /// No description provided for @shortcutsAspect.
  ///
  /// In en, this message translates to:
  /// **'Change how the video fills the screen'**
  String get shortcutsAspect;

  /// No description provided for @shortcutsPage.
  ///
  /// In en, this message translates to:
  /// **'Previous or next page or chapter'**
  String get shortcutsPage;

  /// No description provided for @shortcutsLine.
  ///
  /// In en, this message translates to:
  /// **'Down or up a line, in focus mode'**
  String get shortcutsLine;

  /// No description provided for @nowPlayingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Now playing, {title}, {subtitle}'**
  String nowPlayingSemantics(String title, String subtitle);

  /// No description provided for @nowPlayingOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Open the full player'**
  String get nowPlayingOpenHint;

  /// No description provided for @playerPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get playerPrevious;

  /// No description provided for @playerNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get playerNext;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionPlayback.
  ///
  /// In en, this message translates to:
  /// **'PLAYBACK'**
  String get settingsSectionPlayback;

  /// No description provided for @settingsSectionSources.
  ///
  /// In en, this message translates to:
  /// **'SOURCES'**
  String get settingsSectionSources;

  /// No description provided for @settingsSectionIntegrations.
  ///
  /// In en, this message translates to:
  /// **'INTEGRATIONS'**
  String get settingsSectionIntegrations;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionContent.
  ///
  /// In en, this message translates to:
  /// **'CONTENT'**
  String get settingsSectionContent;

  /// No description provided for @settingsSectionApp.
  ///
  /// In en, this message translates to:
  /// **'APP'**
  String get settingsSectionApp;

  /// No description provided for @stateEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get stateEnabled;

  /// No description provided for @stateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get stateDisabled;

  /// No description provided for @stateActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get stateActive;

  /// No description provided for @stateOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get stateOffline;

  /// No description provided for @stateConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get stateConnected;

  /// No description provided for @stateNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get stateNotSet;

  /// No description provided for @stateOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get stateOn;

  /// No description provided for @stateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get stateOff;

  /// No description provided for @settingsVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Video & Upscaling'**
  String get settingsVideoTitle;

  /// No description provided for @settingsVideoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anime4K neural GLSL shader presets and GPU pipeline'**
  String get settingsVideoSubtitle;

  /// No description provided for @settingsP2pTitle.
  ///
  /// In en, this message translates to:
  /// **'Built-in P2P Torrent Source'**
  String get settingsP2pTitle;

  /// No description provided for @settingsP2pActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lumora torrent swarms (Knaben, TorrentGalaxy) active'**
  String get settingsP2pActiveSubtitle;

  /// No description provided for @settingsP2pDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'P2P disabled. Using only direct HTTP streaming (ZPlayHTTP)'**
  String get settingsP2pDisabledSubtitle;

  /// No description provided for @settingsP2pActiveValue.
  ///
  /// In en, this message translates to:
  /// **'P2P Active'**
  String get settingsP2pActiveValue;

  /// No description provided for @settingsP2pHttpValue.
  ///
  /// In en, this message translates to:
  /// **'HTTP Only'**
  String get settingsP2pHttpValue;

  /// No description provided for @settingsP2pInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'P2P Advisory Details'**
  String get settingsP2pInfoTooltip;

  /// No description provided for @settingsAddonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Addons'**
  String get settingsAddonsTitle;

  /// No description provided for @settingsAddonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stremio catalogs and content providers'**
  String get settingsAddonsSubtitle;

  /// No description provided for @settingsAddonsInstalled.
  ///
  /// In en, this message translates to:
  /// **'{count} Installed'**
  String settingsAddonsInstalled(int count);

  /// No description provided for @settingsBuiltinTitle.
  ///
  /// In en, this message translates to:
  /// **'Built-in Providers'**
  String get settingsBuiltinTitle;

  /// No description provided for @settingsBuiltinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ZPlayHTTP streaming sources, priority order & toggles'**
  String get settingsBuiltinSubtitle;

  /// No description provided for @settingsBuiltinCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settingsBuiltinCustom;

  /// No description provided for @settingsBuiltinDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsBuiltinDefault;

  /// No description provided for @settingsDebridTitle.
  ///
  /// In en, this message translates to:
  /// **'Debrid & Cloud Streaming'**
  String get settingsDebridTitle;

  /// No description provided for @settingsDebridSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-Debrid, TorBox, AllDebrid, Premiumize & Debrid-Link'**
  String get settingsDebridSubtitle;

  /// No description provided for @settingsTraktTitle.
  ///
  /// In en, this message translates to:
  /// **'Trakt.tv Sync'**
  String get settingsTraktTitle;

  /// No description provided for @settingsTraktSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cross-device watchlist, history & playback synchronization'**
  String get settingsTraktSubtitle;

  /// No description provided for @settingsSimklTitle.
  ///
  /// In en, this message translates to:
  /// **'Simkl Sync'**
  String get settingsSimklTitle;

  /// No description provided for @settingsSimklSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cross-device Movies, TV & Anime synchronization'**
  String get settingsSimklSubtitle;

  /// No description provided for @settingsTmdbTitle.
  ///
  /// In en, this message translates to:
  /// **'TMDb API Key'**
  String get settingsTmdbTitle;

  /// No description provided for @settingsTmdbSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your own key for the ranked 1990s rails and scraper metadata'**
  String get settingsTmdbSubtitle;

  /// No description provided for @settingsTmdbYourKey.
  ///
  /// In en, this message translates to:
  /// **'Your key'**
  String get settingsTmdbYourKey;

  /// No description provided for @settingsServiceKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Service API Keys'**
  String get settingsServiceKeysTitle;

  /// No description provided for @settingsServiceKeysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitles, audiobooks and scraper keys you supply yourself'**
  String get settingsServiceKeysSubtitle;

  /// No description provided for @settingsServiceKeysCount.
  ///
  /// In en, this message translates to:
  /// **'{provided} of {total} set'**
  String settingsServiceKeysCount(int provided, int total);

  /// No description provided for @settingsDiscordTitle.
  ///
  /// In en, this message translates to:
  /// **'Discord Rich Presence'**
  String get settingsDiscordTitle;

  /// No description provided for @settingsDiscordEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcasting movies, shows, music & live activity to Discord'**
  String get settingsDiscordEnabledSubtitle;

  /// No description provided for @settingsDiscordDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disabled. Activity is hidden from Discord'**
  String get settingsDiscordDisabledSubtitle;

  /// No description provided for @settingsAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Interface'**
  String get settingsAppearanceTitle;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Liquid Glass setup, color themes, and Home Page UI'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsGlassOn.
  ///
  /// In en, this message translates to:
  /// **'Glass ON'**
  String get settingsGlassOn;

  /// No description provided for @settingsCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'TV Airing Calendar'**
  String get settingsCalendarTitle;

  /// No description provided for @settingsCalendarOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar buttons active on Home top bar and section headers'**
  String get settingsCalendarOnSubtitle;

  /// No description provided for @settingsCalendarOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar disabled and hidden across all pages'**
  String get settingsCalendarOffSubtitle;

  /// No description provided for @settingsAiQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Recommendation Quiz'**
  String get settingsAiQuizTitle;

  /// No description provided for @settingsAiQuizOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI Taste Profile Quiz active on Home and Search bars'**
  String get settingsAiQuizOnSubtitle;

  /// No description provided for @settingsAiQuizOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI quiz disabled and hidden across all pages'**
  String get settingsAiQuizOffSubtitle;

  /// No description provided for @settingsAdultTitle.
  ///
  /// In en, this message translates to:
  /// **'Adult Content'**
  String get settingsAdultTitle;

  /// No description provided for @settingsAdultOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'18+ catalogs, search results and sources are enabled'**
  String get settingsAdultOnSubtitle;

  /// No description provided for @settingsAdultOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden. No 18+ catalogs, search results or sources are fetched'**
  String get settingsAdultOffSubtitle;

  /// No description provided for @settingsBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get settingsBackupTitle;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export or import settings, theme and library progress (JSON)'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsBackupDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cross-device JSON configuration'**
  String get settingsBackupDialogSubtitle;

  /// No description provided for @settingsBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Exports your settings, theme, My List and progress. Leave the passphrase blank for a redacted profile that keeps credentials, IPTV portals and addon URLs on this device. A passphrase encrypts a full profile with them included.'**
  String get settingsBackupDescription;

  /// No description provided for @settingsPassphraseOptional.
  ///
  /// In en, this message translates to:
  /// **'Passphrase (optional)'**
  String get settingsPassphraseOptional;

  /// No description provided for @settingsPassphraseHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters for an encrypted full profile.'**
  String get settingsPassphraseHelper;

  /// No description provided for @settingsExportProfile.
  ///
  /// In en, this message translates to:
  /// **'Export Profile'**
  String get settingsExportProfile;

  /// No description provided for @settingsPassphraseTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters for the passphrase.'**
  String get settingsPassphraseTooShort;

  /// No description provided for @settingsRedactedProfileCopied.
  ///
  /// In en, this message translates to:
  /// **'Redacted profile copied. Credentials, portals and addons stay on this device.'**
  String get settingsRedactedProfileCopied;

  /// No description provided for @settingsEncryptedProfileCopied.
  ///
  /// In en, this message translates to:
  /// **'Encrypted full profile copied. Keep the passphrase safe; it cannot be recovered.'**
  String get settingsEncryptedProfileCopied;

  /// No description provided for @settingsImportJson.
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get settingsImportJson;

  /// No description provided for @settingsPasteJsonTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste Configuration JSON'**
  String get settingsPasteJsonTitle;

  /// No description provided for @settingsPasteJsonHint.
  ///
  /// In en, this message translates to:
  /// **'Paste backup JSON here...'**
  String get settingsPasteJsonHint;

  /// No description provided for @settingsPassphraseEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Passphrase (encrypted profiles)'**
  String get settingsPassphraseEncrypted;

  /// No description provided for @settingsPassphraseEncryptedHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for a redacted profile. Encrypted profiles need the passphrase they were exported with.'**
  String get settingsPassphraseEncryptedHelper;

  /// No description provided for @settingsPasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get settingsPasteFromClipboard;

  /// No description provided for @settingsFromFile.
  ///
  /// In en, this message translates to:
  /// **'From File'**
  String get settingsFromFile;

  /// No description provided for @settingsRestoreNow.
  ///
  /// In en, this message translates to:
  /// **'Restore Now'**
  String get settingsRestoreNow;

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String settingsImportFailed(String error);

  /// No description provided for @settingsChooseProfile.
  ///
  /// In en, this message translates to:
  /// **'Choose a Lumora profile'**
  String get settingsChooseProfile;

  /// No description provided for @settingsClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCacheTitle;

  /// No description provided for @settingsClearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drop cached artwork & metadata. Sign-in, addons, My List & history stay'**
  String get settingsClearCacheSubtitle;

  /// No description provided for @settingsClearCacheConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get settingsClearCacheConfirmTitle;

  /// No description provided for @settingsClearCacheConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Removes cached artwork and metadata so fresh copies are fetched. This does not sign you out or remove addons - your profile, My List, watch history and settings stay exactly as they are.'**
  String get settingsClearCacheConfirmBody;

  /// No description provided for @settingsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClear;

  /// No description provided for @settingsCacheArtwork.
  ///
  /// In en, this message translates to:
  /// **'artwork cache ({error})'**
  String settingsCacheArtwork(String error);

  /// No description provided for @settingsCacheMetadata.
  ///
  /// In en, this message translates to:
  /// **'metadata cache ({error})'**
  String settingsCacheMetadata(String error);

  /// No description provided for @settingsCacheHero.
  ///
  /// In en, this message translates to:
  /// **'hero artwork cache ({error})'**
  String settingsCacheHero(String error);

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared.'**
  String get settingsCacheCleared;

  /// No description provided for @settingsCacheClearedExcept.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared except the {failures}.'**
  String settingsCacheClearedExcept(String failures);

  /// No description provided for @settingsCacheClearedSuffix.
  ///
  /// In en, this message translates to:
  /// **'You are still signed in - addons, My List, watch history and settings are untouched.'**
  String get settingsCacheClearedSuffix;

  /// No description provided for @settingsUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'App Updates'**
  String get settingsUpdatesTitle;

  /// No description provided for @settingsUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check for latest software versions and patches'**
  String get settingsUpdatesSubtitle;

  /// No description provided for @settingsUpdatesCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get settingsUpdatesCheck;

  /// No description provided for @settingsDiagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App, device and player state (redacted) you can copy or save'**
  String get settingsDiagnosticsSubtitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chinese, English, or follow the device'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Lumora'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Architecture, video engine, and credits'**
  String get settingsAboutSubtitle;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local app, device and player report (no telemetry)'**
  String get diagnosticsSubtitle;

  /// No description provided for @diagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'A local-only snapshot of this install: app and device details, player settings, the stream engine state and the recent crash breadcrumbs. Credentials, addon URLs, IPTV portals and playlist links are never included. Nothing is uploaded - the report only exists once you copy or save it.'**
  String get diagnosticsDescription;

  /// No description provided for @diagnosticsSectionDevice.
  ///
  /// In en, this message translates to:
  /// **'DEVICE'**
  String get diagnosticsSectionDevice;

  /// No description provided for @diagnosticsSectionPlayerEngine.
  ///
  /// In en, this message translates to:
  /// **'PLAYER & ENGINE'**
  String get diagnosticsSectionPlayerEngine;

  /// No description provided for @diagnosticsSectionBreadcrumbs.
  ///
  /// In en, this message translates to:
  /// **'CRASH BREADCRUMBS'**
  String get diagnosticsSectionBreadcrumbs;

  /// No description provided for @diagnosticsSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get diagnosticsSummary;

  /// No description provided for @diagnosticsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get diagnosticsNotAvailable;

  /// No description provided for @diagnosticsBreadcrumbCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recorded • last {shown} shown'**
  String diagnosticsBreadcrumbCount(int count, int shown);

  /// No description provided for @diagnosticsBreadcrumbs.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get diagnosticsBreadcrumbs;

  /// No description provided for @diagnosticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No breadcrumbs recorded yet.'**
  String get diagnosticsEmpty;

  /// No description provided for @diagnosticsCopied.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics report copied.'**
  String get diagnosticsCopied;

  /// No description provided for @diagnosticsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic report copied to clipboard'**
  String get diagnosticsCopiedToClipboard;

  /// No description provided for @diagnosticsCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the report'**
  String get diagnosticsCopyFailed;

  /// No description provided for @diagnosticsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the report'**
  String get diagnosticsSaveFailed;

  /// No description provided for @diagnosticsSaved.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics saved to {path}'**
  String diagnosticsSaved(String path);

  /// No description provided for @searchHintTv.
  ///
  /// In en, this message translates to:
  /// **'Search for a movie or series'**
  String get searchHintTv;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search movies, series, or paste links'**
  String get searchHint;

  /// No description provided for @searchVoice.
  ///
  /// In en, this message translates to:
  /// **'Search by voice'**
  String get searchVoice;

  /// No description provided for @searchVoiceDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. Allow it for Lumora to search by voice.'**
  String get searchVoiceDenied;

  /// No description provided for @searchAiQuiz.
  ///
  /// In en, this message translates to:
  /// **'AI Taste Quiz'**
  String get searchAiQuiz;

  /// No description provided for @searchPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get searchPaste;

  /// No description provided for @searchFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Search could not reach its sources'**
  String get searchFailureTitle;

  /// No description provided for @searchFailureBody.
  ///
  /// In en, this message translates to:
  /// **'{failed} of {total} sources did not respond'**
  String searchFailureBody(int failed, int total);

  /// No description provided for @searchFailureAdvice.
  ///
  /// In en, this message translates to:
  /// **'A dead addon or an expired provider runtime is fixed in Addons.'**
  String get searchFailureAdvice;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResults(String query);

  /// No description provided for @searchingMoreSources.
  ///
  /// In en, this message translates to:
  /// **'Searching more sources...'**
  String get searchingMoreSources;

  /// No description provided for @searchPartialFailure.
  ///
  /// In en, this message translates to:
  /// **'Partial Source Failure: {sources} did not respond. Other sources answered normally, so the results below are real but incomplete.'**
  String searchPartialFailure(String sources);

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get searchRecent;

  /// No description provided for @searchClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get searchClearAll;

  /// No description provided for @searchTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending & Suggested'**
  String get searchTrending;

  /// No description provided for @searchNothingToSuggest.
  ///
  /// In en, this message translates to:
  /// **'Nothing to suggest yet'**
  String get searchNothingToSuggest;

  /// No description provided for @searchNothingToSuggestBody.
  ///
  /// In en, this message translates to:
  /// **'Search for a title above, or connect an addon in Settings to have something to search.'**
  String get searchNothingToSuggestBody;

  /// No description provided for @searchPinnedSpine.
  ///
  /// In en, this message translates to:
  /// **'PINNED SPINE'**
  String get searchPinnedSpine;

  /// No description provided for @searchCloudstreamSection.
  ///
  /// In en, this message translates to:
  /// **'CloudStream • {provider}'**
  String searchCloudstreamSection(String provider);

  /// No description provided for @searchCloudstreamExtension.
  ///
  /// In en, this message translates to:
  /// **'CloudStream Extension'**
  String get searchCloudstreamExtension;

  /// No description provided for @searchTitlesSection.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get searchTitlesSection;

  /// No description provided for @searchImdbSuggestions.
  ///
  /// In en, this message translates to:
  /// **'IMDb suggestions'**
  String get searchImdbSuggestions;

  /// No description provided for @searchDirectStream.
  ///
  /// In en, this message translates to:
  /// **'Direct Stream'**
  String get searchDirectStream;

  /// No description provided for @searchSourceTitleLookup.
  ///
  /// In en, this message translates to:
  /// **'Title lookup'**
  String get searchSourceTitleLookup;

  /// No description provided for @playerSeekBack.
  ///
  /// In en, this message translates to:
  /// **'Seek -10s'**
  String get playerSeekBack;

  /// No description provided for @playerSeekForward.
  ///
  /// In en, this message translates to:
  /// **'Seek +10s'**
  String get playerSeekForward;

  /// No description provided for @playerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @playerMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get playerMute;

  /// No description provided for @playerUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get playerUnmute;

  /// No description provided for @playerPreviousEpisode.
  ///
  /// In en, this message translates to:
  /// **'Previous Episode'**
  String get playerPreviousEpisode;

  /// No description provided for @playerNextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Next Episode'**
  String get playerNextEpisode;

  /// No description provided for @playerEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get playerEpisodes;

  /// No description provided for @playerAspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio (C)'**
  String get playerAspectRatio;

  /// No description provided for @playerPlaybackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playerPlaybackSpeed;

  /// No description provided for @playerAudioTracks.
  ///
  /// In en, this message translates to:
  /// **'Audio Tracks'**
  String get playerAudioTracks;

  /// No description provided for @playerSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get playerSubtitles;

  /// No description provided for @playerSubtitleSync.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Sync'**
  String get playerSubtitleSync;

  /// No description provided for @playerFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen (F)'**
  String get playerFullscreen;

  /// No description provided for @playerExitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit Fullscreen (F)'**
  String get playerExitFullscreen;

  /// No description provided for @playerVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume {percent}%'**
  String playerVolume(int percent);

  /// No description provided for @playerSeekPosition.
  ///
  /// In en, this message translates to:
  /// **'{position} of {duration}'**
  String playerSeekPosition(String position, String duration);

  /// No description provided for @a11yOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get a11yOpenDetails;

  /// No description provided for @a11yResume.
  ///
  /// In en, this message translates to:
  /// **'Resume {title}, {percent}% watched'**
  String a11yResume(String title, int percent);

  /// No description provided for @emptyMyList.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty'**
  String get emptyMyList;

  /// No description provided for @emptyMyListBody.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite movies and TV shows to watch anytime'**
  String get emptyMyListBody;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App language. System follows your device.'**
  String get languageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;

  /// No description provided for @a11yResumePlayback.
  ///
  /// In en, this message translates to:
  /// **'Resume playback'**
  String get a11yResumePlayback;

  /// No description provided for @playerPlaybackPosition.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get playerPlaybackPosition;

  /// No description provided for @playerVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get playerVolumeLabel;

  /// No description provided for @homePlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get homePlay;

  /// No description provided for @homeMoreInfo.
  ///
  /// In en, this message translates to:
  /// **'More Info'**
  String get homeMoreInfo;

  /// No description provided for @homeTrailer.
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get homeTrailer;

  /// No description provided for @homeContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get homeContinueWatching;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get homeSeeAll;

  /// No description provided for @homeCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get homeCalendar;

  /// No description provided for @homeTop10.
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Top 10'**
  String get homeTop10;

  /// No description provided for @homeLoadingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Loading your library...'**
  String get homeLoadingLibrary;

  /// No description provided for @homeEmptyShelf.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the shelf yet. Add an addon in Settings, or pull down to refresh.'**
  String get homeEmptyShelf;

  /// No description provided for @homeMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m left'**
  String homeMinutesLeft(int minutes);

  /// No description provided for @homeBecauseOnList.
  ///
  /// In en, this message translates to:
  /// **'Because you have \"{title}\" on your list'**
  String homeBecauseOnList(String title);

  /// No description provided for @homeBecauseWatching.
  ///
  /// In en, this message translates to:
  /// **'Because you\'re watching \"{title}\"'**
  String homeBecauseWatching(String title);

  /// No description provided for @homeBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Recommendations based on {title}'**
  String homeBasedOn(String title);

  /// No description provided for @homeTraktRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You (Trakt)'**
  String get homeTraktRecommended;

  /// No description provided for @homeTraktRecommendedSub.
  ///
  /// In en, this message translates to:
  /// **'Personalized based on your Trakt watch history'**
  String get homeTraktRecommendedSub;

  /// No description provided for @homeTrendingWeek.
  ///
  /// In en, this message translates to:
  /// **'Trending This Week'**
  String get homeTrendingWeek;

  /// No description provided for @homeTrendingWeekSub.
  ///
  /// In en, this message translates to:
  /// **'What Trakt viewers are watching right now'**
  String get homeTrendingWeekSub;

  /// No description provided for @homePopularNow.
  ///
  /// In en, this message translates to:
  /// **'Popular Now'**
  String get homePopularNow;

  /// No description provided for @homePopularNowSub.
  ///
  /// In en, this message translates to:
  /// **'Most-watched titles across Trakt'**
  String get homePopularNowSub;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get homeComingSoon;

  /// No description provided for @homeComingSoonSub.
  ///
  /// In en, this message translates to:
  /// **'Most anticipated upcoming releases'**
  String get homeComingSoonSub;

  /// No description provided for @homeFromTrakt.
  ///
  /// In en, this message translates to:
  /// **'From Trakt'**
  String get homeFromTrakt;

  /// No description provided for @homeSimklRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You (Simkl)'**
  String get homeSimklRecommended;

  /// No description provided for @homeSimklRecommendedSub.
  ///
  /// In en, this message translates to:
  /// **'Top-rated & personalized suggestions from Simkl'**
  String get homeSimklRecommendedSub;

  /// No description provided for @catalogPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular {type}'**
  String catalogPopular(String type);

  /// No description provided for @catalogNew.
  ///
  /// In en, this message translates to:
  /// **'New {type}'**
  String catalogNew(String type);

  /// No description provided for @catalogTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated {type}'**
  String catalogTopRated(String type);

  /// No description provided for @typeMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get typeMovies;

  /// No description provided for @typeSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get typeSeries;

  /// No description provided for @typeAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get typeAnime;

  /// No description provided for @typeCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get typeCollections;

  /// No description provided for @kindMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get kindMovie;

  /// No description provided for @kindSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get kindSeries;

  /// No description provided for @kindAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get kindAnime;

  /// No description provided for @detailsPlayMovie.
  ///
  /// In en, this message translates to:
  /// **'Play Movie'**
  String get detailsPlayMovie;

  /// No description provided for @detailsPlayEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Play Episodes'**
  String get detailsPlayEpisodes;

  /// No description provided for @detailsPlayFirstMovie.
  ///
  /// In en, this message translates to:
  /// **'Play First Movie'**
  String get detailsPlayFirstMovie;

  /// No description provided for @detailsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume · {time}'**
  String detailsResume(String time);

  /// No description provided for @detailsResumeEpisode.
  ///
  /// In en, this message translates to:
  /// **'Resume E{episode} · {time}'**
  String detailsResumeEpisode(int episode, String time);

  /// No description provided for @detailsLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get detailsLibrary;

  /// No description provided for @detailsInLibrary.
  ///
  /// In en, this message translates to:
  /// **'In Library'**
  String get detailsInLibrary;

  /// No description provided for @detailsSeasonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Season} other{{count} Seasons}}'**
  String detailsSeasonCount(int count);

  /// No description provided for @detailsSeason.
  ///
  /// In en, this message translates to:
  /// **'Season {season}'**
  String detailsSeason(int season);

  /// No description provided for @detailsEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get detailsEpisodes;

  /// No description provided for @detailsCollectionMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies in Collection'**
  String get detailsCollectionMovies;

  /// No description provided for @detailsSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar Content'**
  String get detailsSimilar;

  /// No description provided for @detailsMoreLikeThis.
  ///
  /// In en, this message translates to:
  /// **'More Like This'**
  String get detailsMoreLikeThis;

  /// No description provided for @detailsCast.
  ///
  /// In en, this message translates to:
  /// **'Top Cast & Characters'**
  String get detailsCast;

  /// No description provided for @detailsReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get detailsReadMore;

  /// No description provided for @detailsShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get detailsShowLess;

  /// No description provided for @detailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Details unavailable.'**
  String get detailsUnavailable;

  /// No description provided for @detailsGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get detailsGoBack;

  /// No description provided for @detailsEpisodeBadge.
  ///
  /// In en, this message translates to:
  /// **'E{episode}'**
  String detailsEpisodeBadge(String episode);

  /// No description provided for @detailsPartBadge.
  ///
  /// In en, this message translates to:
  /// **'PART {part}'**
  String detailsPartBadge(String part);

  /// No description provided for @detailsWatchedTo.
  ///
  /// In en, this message translates to:
  /// **'Watched to {time}'**
  String detailsWatchedTo(String time);

  /// No description provided for @searchKindAnime.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get searchKindAnime;

  /// No description provided for @searchKindAnimeMovie.
  ///
  /// In en, this message translates to:
  /// **'Animated film'**
  String get searchKindAnimeMovie;

  /// No description provided for @searchKindLiveSeries.
  ///
  /// In en, this message translates to:
  /// **'Live-action series'**
  String get searchKindLiveSeries;

  /// No description provided for @searchKindSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get searchKindSeries;

  /// No description provided for @searchKindMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get searchKindMovie;

  /// No description provided for @searchFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String searchFilterAll(int count);

  /// No description provided for @searchFilterAnime.
  ///
  /// In en, this message translates to:
  /// **'Animation {count}'**
  String searchFilterAnime(int count);

  /// No description provided for @searchFilterSeries.
  ///
  /// In en, this message translates to:
  /// **'Series {count}'**
  String searchFilterSeries(int count);

  /// No description provided for @searchFilterMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies {count}'**
  String searchFilterMovies(int count);

  /// No description provided for @searchFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing of this kind.'**
  String get searchFilterEmpty;

  /// No description provided for @searchResumeEpisode.
  ///
  /// In en, this message translates to:
  /// **'Watched to S{season} E{episode}'**
  String searchResumeEpisode(int season, int episode);

  /// No description provided for @searchResumeMovie.
  ///
  /// In en, this message translates to:
  /// **'Started watching'**
  String get searchResumeMovie;

  /// No description provided for @searchHot.
  ///
  /// In en, this message translates to:
  /// **'Popular searches'**
  String get searchHot;

  /// No description provided for @searchNoPoster.
  ///
  /// In en, this message translates to:
  /// **'No poster'**
  String get searchNoPoster;

  /// No description provided for @watchSources.
  ///
  /// In en, this message translates to:
  /// **'Watch Sources'**
  String get watchSources;

  /// No description provided for @watchSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching sources...'**
  String get watchSearching;

  /// No description provided for @watchFoundSearching.
  ///
  /// In en, this message translates to:
  /// **'{count} found · Searching...'**
  String watchFoundSearching(int count);

  /// No description provided for @watchFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 source found} other{{count} sources found}}'**
  String watchFound(int count);

  /// No description provided for @watchFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String watchFilterAll(int count);

  /// No description provided for @watchFilterDebrid.
  ///
  /// In en, this message translates to:
  /// **'{service} ({count})'**
  String watchFilterDebrid(String service, int count);

  /// No description provided for @watchFilterTorrents.
  ///
  /// In en, this message translates to:
  /// **'Torrents ({count})'**
  String watchFilterTorrents(int count);

  /// No description provided for @watchFilterDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct ({count})'**
  String watchFilterDirect(int count);

  /// No description provided for @watchSeedsAll.
  ///
  /// In en, this message translates to:
  /// **'All Seeds'**
  String get watchSeedsAll;

  /// No description provided for @watchSeedsMost.
  ///
  /// In en, this message translates to:
  /// **'Most Seeds'**
  String get watchSeedsMost;

  /// No description provided for @watchSeedsMostLong.
  ///
  /// In en, this message translates to:
  /// **'Most Seeds (High to Low)'**
  String get watchSeedsMostLong;

  /// No description provided for @watchSeedsAtLeast.
  ///
  /// In en, this message translates to:
  /// **'{count}+ Seeds'**
  String watchSeedsAtLeast(int count);

  /// No description provided for @watchSeedsActive.
  ///
  /// In en, this message translates to:
  /// **'Active Seeds'**
  String get watchSeedsActive;

  /// No description provided for @watchSeedsActiveLong.
  ///
  /// In en, this message translates to:
  /// **'Active Seeds (>0)'**
  String get watchSeedsActiveLong;

  /// No description provided for @watchSizeAll.
  ///
  /// In en, this message translates to:
  /// **'All Sizes'**
  String get watchSizeAll;

  /// No description provided for @watchSizeLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get watchSizeLargest;

  /// No description provided for @watchSizeSmallest.
  ///
  /// In en, this message translates to:
  /// **'Smallest'**
  String get watchSizeSmallest;

  /// No description provided for @watchSizeLargestFirst.
  ///
  /// In en, this message translates to:
  /// **'Largest First'**
  String get watchSizeLargestFirst;

  /// No description provided for @watchSizeSmallestFirst.
  ///
  /// In en, this message translates to:
  /// **'Smallest First'**
  String get watchSizeSmallestFirst;

  /// No description provided for @watchAllSources.
  ///
  /// In en, this message translates to:
  /// **'All Sources'**
  String get watchAllSources;

  /// No description provided for @watchAllAudio.
  ///
  /// In en, this message translates to:
  /// **'All Audio'**
  String get watchAllAudio;

  /// No description provided for @watchAudioMulti.
  ///
  /// In en, this message translates to:
  /// **'🌐 Multi-Audio'**
  String get watchAudioMulti;

  /// No description provided for @watchAudioEnglish.
  ///
  /// In en, this message translates to:
  /// **'🇺🇸 English / Original'**
  String get watchAudioEnglish;

  /// No description provided for @watchAudioHindi.
  ///
  /// In en, this message translates to:
  /// **'🇮🇳 Hindi / Indian'**
  String get watchAudioHindi;

  /// No description provided for @watchAudioGerman.
  ///
  /// In en, this message translates to:
  /// **'🇩🇪 German'**
  String get watchAudioGerman;

  /// No description provided for @watchAudioFrench.
  ///
  /// In en, this message translates to:
  /// **'🇫🇷 French'**
  String get watchAudioFrench;

  /// No description provided for @watchAudioCastilian.
  ///
  /// In en, this message translates to:
  /// **'🇪🇸 Spanish (Castilian)'**
  String get watchAudioCastilian;

  /// No description provided for @watchAudioLatino.
  ///
  /// In en, this message translates to:
  /// **'🇲🇽 Spanish (Latin)'**
  String get watchAudioLatino;

  /// No description provided for @watchAudioSpanish.
  ///
  /// In en, this message translates to:
  /// **'🌎 All Spanish'**
  String get watchAudioSpanish;

  /// No description provided for @watchAudioRussian.
  ///
  /// In en, this message translates to:
  /// **'🇷🇺 Russian'**
  String get watchAudioRussian;

  /// No description provided for @watchAudioJapanese.
  ///
  /// In en, this message translates to:
  /// **'🇯🇵 Japanese'**
  String get watchAudioJapanese;

  /// No description provided for @watchAudioItalian.
  ///
  /// In en, this message translates to:
  /// **'🇮🇹 Italian'**
  String get watchAudioItalian;

  /// No description provided for @watchSeedersFilter.
  ///
  /// In en, this message translates to:
  /// **'Seeders Filter'**
  String get watchSeedersFilter;

  /// No description provided for @watchSizeFilter.
  ///
  /// In en, this message translates to:
  /// **'File Size Filter'**
  String get watchSizeFilter;

  /// No description provided for @watchProviderFilter.
  ///
  /// In en, this message translates to:
  /// **'Source Provider'**
  String get watchProviderFilter;

  /// No description provided for @watchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get watchUnavailable;

  /// No description provided for @watchSeeds.
  ///
  /// In en, this message translates to:
  /// **'{count} Seeds'**
  String watchSeeds(int count);

  /// No description provided for @watchMagnetCopied.
  ///
  /// In en, this message translates to:
  /// **'Magnet link copied to clipboard'**
  String get watchMagnetCopied;

  /// No description provided for @watchCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get watchCopied;

  /// No description provided for @watchCopyMagnet.
  ///
  /// In en, this message translates to:
  /// **'Copy Magnet Link'**
  String get watchCopyMagnet;

  /// No description provided for @watchNoSources.
  ///
  /// In en, this message translates to:
  /// **'No sources found'**
  String get watchNoSources;

  /// No description provided for @watchNoSourcesBody.
  ///
  /// In en, this message translates to:
  /// **'No streams found. Install more addons from Settings or try another title.'**
  String get watchNoSourcesBody;

  /// No description provided for @watchInstallAddons.
  ///
  /// In en, this message translates to:
  /// **'Install Addons'**
  String get watchInstallAddons;

  /// No description provided for @watchAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto (recommended)'**
  String get watchAutoTitle;

  /// No description provided for @watchAutoIdle.
  ///
  /// In en, this message translates to:
  /// **'Plays the fastest source that is this title'**
  String get watchAutoIdle;

  /// No description provided for @watchAutoPicking.
  ///
  /// In en, this message translates to:
  /// **'Finding the fastest source…'**
  String get watchAutoPicking;

  /// No description provided for @watchAutoNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing here plays by itself. Pick one below to try.'**
  String get watchAutoNone;

  /// No description provided for @watchDeadNoSeeds.
  ///
  /// In en, this message translates to:
  /// **'0 seeders · probably won\'t play'**
  String get watchDeadNoSeeds;

  /// No description provided for @watchDeadUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect'**
  String get watchDeadUnreachable;

  /// No description provided for @detailsSourceAuto.
  ///
  /// In en, this message translates to:
  /// **'Source: Auto'**
  String get detailsSourceAuto;

  /// No description provided for @detailsSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Source: Manual'**
  String get detailsSourceManual;

  /// No description provided for @playerSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed {rate}x'**
  String playerSpeedLabel(String rate);

  /// No description provided for @playerSubtitlesWith.
  ///
  /// In en, this message translates to:
  /// **'Subtitles · {language}'**
  String playerSubtitlesWith(String language);

  /// No description provided for @playerSubtitlesOff.
  ///
  /// In en, this message translates to:
  /// **'Subtitles · Off'**
  String get playerSubtitlesOff;

  /// No description provided for @playerSourceWith.
  ///
  /// In en, this message translates to:
  /// **'Source · {quality}'**
  String playerSourceWith(String quality);

  /// No description provided for @playerSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get playerSource;

  /// No description provided for @playerSubChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get playerSubChinese;

  /// No description provided for @playerSubEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get playerSubEnglish;

  /// No description provided for @panelNoStreamsEpisode.
  ///
  /// In en, this message translates to:
  /// **'No streams found for this episode'**
  String get panelNoStreamsEpisode;

  /// No description provided for @panelNoStreamsTitle.
  ///
  /// In en, this message translates to:
  /// **'No streams found for this title'**
  String get panelNoStreamsTitle;

  /// No description provided for @panelEmptyEpisodeBody.
  ///
  /// In en, this message translates to:
  /// **'Try going back to episodes and choosing another episode or provider.'**
  String get panelEmptyEpisodeBody;

  /// No description provided for @panelEmptyTitleBody.
  ///
  /// In en, this message translates to:
  /// **'Try another provider for this title, or close this panel and check your addons in Settings.'**
  String get panelEmptyTitleBody;

  /// No description provided for @panelBackToEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Back to Episodes'**
  String get panelBackToEpisodes;

  /// No description provided for @panelEpisode.
  ///
  /// In en, this message translates to:
  /// **'Episode {episode}'**
  String panelEpisode(String episode);

  /// No description provided for @panelAllProviders.
  ///
  /// In en, this message translates to:
  /// **'All providers · watching via {addon}'**
  String panelAllProviders(String addon);

  /// No description provided for @panelClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get panelClose;

  /// No description provided for @panelSearchingAll.
  ///
  /// In en, this message translates to:
  /// **'Searching every provider…'**
  String get panelSearchingAll;

  /// No description provided for @panelRescrape.
  ///
  /// In en, this message translates to:
  /// **'Rescrape Sources'**
  String get panelRescrape;

  /// No description provided for @panelScrapingMore.
  ///
  /// In en, this message translates to:
  /// **'Scraping additional sources...'**
  String get panelScrapingMore;

  /// No description provided for @panelStreamSource.
  ///
  /// In en, this message translates to:
  /// **'Stream Source'**
  String get panelStreamSource;

  /// No description provided for @playerNotResponding.
  ///
  /// In en, this message translates to:
  /// **'This stream is not responding - the source may be expired.'**
  String get playerNotResponding;

  /// No description provided for @playerNotRespondingPick.
  ///
  /// In en, this message translates to:
  /// **'This stream is not responding - the source may be expired. Pick another source below.'**
  String get playerNotRespondingPick;

  /// No description provided for @playerTryingAnother.
  ///
  /// In en, this message translates to:
  /// **'This source is not responding • Trying another source'**
  String get playerTryingAnother;

  /// No description provided for @playerInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get playerInitializing;

  /// No description provided for @playerBuffering.
  ///
  /// In en, this message translates to:
  /// **'Buffering {label}...'**
  String playerBuffering(String label);

  /// No description provided for @playerEpisodeLabel.
  ///
  /// In en, this message translates to:
  /// **'S{season}:E{episode} - {title}'**
  String playerEpisodeLabel(String season, String episode, String title);

  /// No description provided for @playerGatheringPeers.
  ///
  /// In en, this message translates to:
  /// **'Gathering metadata & peers...'**
  String get playerGatheringPeers;

  /// No description provided for @playerUsingDebrid.
  ///
  /// In en, this message translates to:
  /// **'Using {service} for files...'**
  String playerUsingDebrid(String service);

  /// No description provided for @playerSourceFailed.
  ///
  /// In en, this message translates to:
  /// **'Source failed to play. Please select another source below.'**
  String get playerSourceFailed;

  /// No description provided for @playerOpenError.
  ///
  /// In en, this message translates to:
  /// **'Media Open Error: Stream server quota exceeded or invalid media format.\nPlease select another stream.'**
  String get playerOpenError;

  /// No description provided for @playerTestingOthers.
  ///
  /// In en, this message translates to:
  /// **'Testing other sources for you'**
  String get playerTestingOthers;

  /// No description provided for @playerTrying.
  ///
  /// In en, this message translates to:
  /// **'Trying {source}.'**
  String playerTrying(String source);

  /// No description provided for @playerAttempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt {attempt} of {max}'**
  String playerAttempt(String attempt, String max);

  /// No description provided for @playerChooseMyself.
  ///
  /// In en, this message translates to:
  /// **'Choose a source myself'**
  String get playerChooseMyself;

  /// No description provided for @playerChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another source'**
  String get playerChooseAnother;

  /// No description provided for @playerGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get playerGoBack;

  /// No description provided for @playerBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get playerBack;

  /// No description provided for @playerScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get playerScreenshot;

  /// No description provided for @playerDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get playerDownloading;

  /// No description provided for @playerDownloadMedia.
  ///
  /// In en, this message translates to:
  /// **'Download Media'**
  String get playerDownloadMedia;

  /// No description provided for @playerLockScreen.
  ///
  /// In en, this message translates to:
  /// **'Lock Screen'**
  String get playerLockScreen;

  /// No description provided for @playerCast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get playerCast;

  /// No description provided for @playerLocked.
  ///
  /// In en, this message translates to:
  /// **'Screen is locked. Tap the lock icon to unlock.'**
  String get playerLocked;

  /// No description provided for @playerUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get playerUnlock;

  /// No description provided for @playerMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get playerMuted;

  /// No description provided for @playerCannotSeek.
  ///
  /// In en, this message translates to:
  /// **'This source cannot seek • Starting from the beginning'**
  String get playerCannotSeek;

  /// No description provided for @playerSubDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download subtitle'**
  String get playerSubDownloadFailed;

  /// No description provided for @playerSubSynced.
  ///
  /// In en, this message translates to:
  /// **'Subtitle timing synchronized and saved!'**
  String get playerSubSynced;

  /// No description provided for @playerDownloadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Download already in progress in background.'**
  String get playerDownloadInProgress;

  /// No description provided for @playerAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'This media is already downloaded.'**
  String get playerAlreadyDownloaded;

  /// No description provided for @playerDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started in background. Track progress in Downloads tab.'**
  String get playerDownloadStarted;

  /// No description provided for @playerUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Stream URL copied to clipboard'**
  String get playerUrlCopied;

  /// No description provided for @playerNoUrl.
  ///
  /// In en, this message translates to:
  /// **'No active stream URL available to copy.'**
  String get playerNoUrl;

  /// No description provided for @playerSubSyncEmbedded.
  ///
  /// In en, this message translates to:
  /// **'Subtitle sync is not supported for embedded subtitles. Please select an external subtitle.'**
  String get playerSubSyncEmbedded;

  /// No description provided for @playerSubSyncNeedExternal.
  ///
  /// In en, this message translates to:
  /// **'Please load an external subtitle to use subtitle sync.'**
  String get playerSubSyncNeedExternal;

  /// No description provided for @playerSubSyncEmbeddedShort.
  ///
  /// In en, this message translates to:
  /// **'Subtitle sync is not supported for embedded subtitles.'**
  String get playerSubSyncEmbeddedShort;

  /// No description provided for @playerSpeechSyncNeedsFile.
  ///
  /// In en, this message translates to:
  /// **'Speech sync requires an external subtitle file.'**
  String get playerSpeechSyncNeedsFile;

  /// No description provided for @playerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss (✕)'**
  String get playerDismiss;

  /// No description provided for @playerSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get playerSources;

  /// No description provided for @playerQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get playerQuality;

  /// No description provided for @playerQualityWith.
  ///
  /// In en, this message translates to:
  /// **'Quality · {quality}'**
  String playerQualityWith(String quality);

  /// No description provided for @playerQualityAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get playerQualityAuto;

  /// No description provided for @playerQualityAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Best your connection carries'**
  String get playerQualityAutoNote;

  /// No description provided for @playerQualityAutoMeasured.
  ///
  /// In en, this message translates to:
  /// **'Best for your {mbps} Mbps'**
  String playerQualityAutoMeasured(String mbps);

  /// No description provided for @playerQualityPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing now'**
  String get playerQualityPlaying;

  /// No description provided for @playerQualitySources.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 source} other{{count} sources}}'**
  String playerQualitySources(int count);

  /// No description provided for @playerQualityNone.
  ///
  /// In en, this message translates to:
  /// **'No source in {quality} for this title'**
  String playerQualityNone(String quality);

  /// No description provided for @p2pAdvisory.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY & NETWORK ADVISORY'**
  String get p2pAdvisory;

  /// No description provided for @p2pTitle.
  ///
  /// In en, this message translates to:
  /// **'P2P Torrent Streaming Notice'**
  String get p2pTitle;

  /// No description provided for @p2pExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get p2pExit;

  /// No description provided for @p2pQuestion.
  ///
  /// In en, this message translates to:
  /// **'Would you like to turn off the built-in P2P torrent source and use only direct HTTP streaming?'**
  String get p2pQuestion;

  /// No description provided for @p2pBody.
  ///
  /// In en, this message translates to:
  /// **'P2P (peer-to-peer torrent) streaming connects directly to public torrent swarms to download and seed video pieces. In certain countries and regions, unencrypted torrent activity may be monitored and could result in warning letters or notices from your Internet Service Provider (ISP).'**
  String get p2pBody;

  /// No description provided for @p2pDirectTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Stream'**
  String get p2pDirectTitle;

  /// No description provided for @p2pDirectBody.
  ///
  /// In en, this message translates to:
  /// **'Safe direct HTTPS web streams. No torrenting or peer uploading.'**
  String get p2pDirectBody;

  /// No description provided for @p2pTorrentTitle.
  ///
  /// In en, this message translates to:
  /// **'Torrent Engine'**
  String get p2pTorrentTitle;

  /// No description provided for @p2pTorrentBody.
  ///
  /// In en, this message translates to:
  /// **'P2P swarms (Knaben, TorrentGalaxy). Involves peer data sharing.'**
  String get p2pTorrentBody;

  /// No description provided for @p2pNote.
  ///
  /// In en, this message translates to:
  /// **'Note: You can easily toggle the built-in P2P source back on or off anytime in Settings.'**
  String get p2pNote;

  /// No description provided for @p2pDontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Show Again'**
  String get p2pDontShowAgain;

  /// No description provided for @p2pTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Yes, Turn Off P2P'**
  String get p2pTurnOff;

  /// No description provided for @p2pTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'P2P torrent source turned off. Direct streams will be used.'**
  String get p2pTurnedOff;

  /// No description provided for @recommendFor.
  ///
  /// In en, this message translates to:
  /// **'For you · {kind}'**
  String recommendFor(String kind);

  /// No description provided for @recommendBecause.
  ///
  /// In en, this message translates to:
  /// **'Because you watch a lot of {kind}'**
  String recommendBecause(String kind);

  /// No description provided for @detailsLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get detailsLike;

  /// No description provided for @detailsDislike.
  ///
  /// In en, this message translates to:
  /// **'Not for me'**
  String get detailsDislike;

  /// No description provided for @subRefreshOnline.
  ///
  /// In en, this message translates to:
  /// **'Refresh Online Subtitles'**
  String get subRefreshOnline;

  /// No description provided for @subSyncBar.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Sync Bar'**
  String get subSyncBar;

  /// No description provided for @subAppearance.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Appearance'**
  String get subAppearance;

  /// No description provided for @subSpeechSync.
  ///
  /// In en, this message translates to:
  /// **'Speech Text Sync'**
  String get subSpeechSync;

  /// No description provided for @subOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get subOff;

  /// No description provided for @subEmbedded.
  ///
  /// In en, this message translates to:
  /// **'Embedded'**
  String get subEmbedded;

  /// No description provided for @subEmbeddedCaps.
  ///
  /// In en, this message translates to:
  /// **'EMBEDDED'**
  String get subEmbeddedCaps;

  /// No description provided for @subAllLanguages.
  ///
  /// In en, this message translates to:
  /// **'All Languages'**
  String get subAllLanguages;

  /// No description provided for @subAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get subAll;

  /// No description provided for @subHearingImpaired.
  ///
  /// In en, this message translates to:
  /// **'HI / CC'**
  String get subHearingImpaired;

  /// No description provided for @subForced.
  ///
  /// In en, this message translates to:
  /// **'Forced'**
  String get subForced;

  /// No description provided for @subForcedCaps.
  ///
  /// In en, this message translates to:
  /// **'FORCED'**
  String get subForcedCaps;

  /// No description provided for @subLanguages.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGES'**
  String get subLanguages;

  /// No description provided for @subSearchOnline.
  ///
  /// In en, this message translates to:
  /// **'Search Online'**
  String get subSearchOnline;

  /// No description provided for @subSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching subtitles...'**
  String get subSearching;

  /// No description provided for @subNone.
  ///
  /// In en, this message translates to:
  /// **'No subtitles available.'**
  String get subNone;

  /// No description provided for @subSearchProviders.
  ///
  /// In en, this message translates to:
  /// **'Search Online Providers'**
  String get subSearchProviders;

  /// No description provided for @subSearchingMore.
  ///
  /// In en, this message translates to:
  /// **'Searching additional subtitles online...'**
  String get subSearchingMore;

  /// No description provided for @subFindMore.
  ///
  /// In en, this message translates to:
  /// **'Find more subtitles'**
  String get subFindMore;

  /// No description provided for @speedTitle.
  ///
  /// In en, this message translates to:
  /// **'PLAYBACK SPEED'**
  String get speedTitle;

  /// No description provided for @speedNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal (1.0×)'**
  String get speedNormal;

  /// No description provided for @speedSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'SLEEP TIMER'**
  String get speedSleepTimer;

  /// No description provided for @audioTracksTitle.
  ///
  /// In en, this message translates to:
  /// **'AUDIO TRACKS'**
  String get audioTracksTitle;

  /// No description provided for @audioDefaultPlaying.
  ///
  /// In en, this message translates to:
  /// **'Default audio stream playing.'**
  String get audioDefaultPlaying;

  /// No description provided for @audioSyncOffset.
  ///
  /// In en, this message translates to:
  /// **'Audio Sync Offset'**
  String get audioSyncOffset;

  /// No description provided for @aspectTitle.
  ///
  /// In en, this message translates to:
  /// **'ASPECT RATIO'**
  String get aspectTitle;

  /// No description provided for @aspectSubtitleScale.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Size Scale'**
  String get aspectSubtitleScale;

  /// No description provided for @episodesScrollUp.
  ///
  /// In en, this message translates to:
  /// **'Scroll Up'**
  String get episodesScrollUp;

  /// No description provided for @episodesScrollDown.
  ///
  /// In en, this message translates to:
  /// **'Scroll Down'**
  String get episodesScrollDown;

  /// No description provided for @episodesPrevSeasons.
  ///
  /// In en, this message translates to:
  /// **'Previous Seasons'**
  String get episodesPrevSeasons;

  /// No description provided for @episodesNextSeasons.
  ///
  /// In en, this message translates to:
  /// **'Next Seasons'**
  String get episodesNextSeasons;

  /// No description provided for @episodesPlaying.
  ///
  /// In en, this message translates to:
  /// **'PLAYING'**
  String get episodesPlaying;

  /// No description provided for @episodesSelectSources.
  ///
  /// In en, this message translates to:
  /// **'Select Sources'**
  String get episodesSelectSources;

  /// No description provided for @syncTextSync.
  ///
  /// In en, this message translates to:
  /// **'Text Sync'**
  String get syncTextSync;

  /// No description provided for @syncDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get syncDiscard;

  /// No description provided for @syncDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get syncDone;

  /// No description provided for @syncDriftActive.
  ///
  /// In en, this message translates to:
  /// **'Drift correction active (2 anchor points). Fine-tune with buttons.'**
  String get syncDriftActive;

  /// No description provided for @syncFixSectionCaps.
  ///
  /// In en, this message translates to:
  /// **'FIX SECTION'**
  String get syncFixSectionCaps;

  /// No description provided for @syncTimingCaps.
  ///
  /// In en, this message translates to:
  /// **'SUBTITLE TIMING'**
  String get syncTimingCaps;

  /// No description provided for @syncSelectRange.
  ///
  /// In en, this message translates to:
  /// **'Select Range & Sync'**
  String get syncSelectRange;

  /// No description provided for @syncSpeechDialogue.
  ///
  /// In en, this message translates to:
  /// **'Speech Dialogue Sync'**
  String get syncSpeechDialogue;

  /// No description provided for @syncSearchDialogue.
  ///
  /// In en, this message translates to:
  /// **'Search dialogue...'**
  String get syncSearchDialogue;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get syncNow;

  /// No description provided for @syncFromHere.
  ///
  /// In en, this message translates to:
  /// **'Sync from here'**
  String get syncFromHere;

  /// No description provided for @syncJumpHere.
  ///
  /// In en, this message translates to:
  /// **'Jump here'**
  String get syncJumpHere;

  /// No description provided for @syncJumpNow.
  ///
  /// In en, this message translates to:
  /// **'Jump to now'**
  String get syncJumpNow;

  /// No description provided for @syncSelecting.
  ///
  /// In en, this message translates to:
  /// **'Selecting'**
  String get syncSelecting;

  /// No description provided for @syncFixSection.
  ///
  /// In en, this message translates to:
  /// **'Fix section'**
  String get syncFixSection;

  /// No description provided for @syncReset.
  ///
  /// In en, this message translates to:
  /// **'Reset timing'**
  String get syncReset;

  /// No description provided for @syncSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get syncSaving;

  /// No description provided for @syncSave.
  ///
  /// In en, this message translates to:
  /// **'Save Timing'**
  String get syncSave;

  /// No description provided for @listRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove from My List?'**
  String get listRemoveConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @listRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get listRemove;

  /// No description provided for @listTitle.
  ///
  /// In en, this message translates to:
  /// **'My List'**
  String get listTitle;

  /// No description provided for @listSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get listSyncing;

  /// No description provided for @listSynced.
  ///
  /// In en, this message translates to:
  /// **'Cloud Synced'**
  String get listSynced;

  /// No description provided for @listFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter saved titles'**
  String get listFilter;

  /// No description provided for @listSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get listSortRecent;

  /// No description provided for @listSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get listSortTitle;

  /// No description provided for @listSortYear.
  ///
  /// In en, this message translates to:
  /// **'Release Year'**
  String get listSortYear;

  /// No description provided for @listSearch.
  ///
  /// In en, this message translates to:
  /// **'Search saved titles...'**
  String get listSearch;

  /// No description provided for @listEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty'**
  String get listEmpty;

  /// No description provided for @listNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No titles found'**
  String get listNoMatch;

  /// No description provided for @listEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite movies and TV shows to watch anytime'**
  String get listEmptyBody;

  /// No description provided for @listNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search query or filter settings'**
  String get listNoMatchBody;

  /// No description provided for @listResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get listResetFilters;

  /// No description provided for @dlFileMissing.
  ///
  /// In en, this message translates to:
  /// **'File not found on disk. It may have been moved or deleted.'**
  String get dlFileMissing;

  /// No description provided for @dlDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Download'**
  String get dlDeleteTitle;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @dlList.
  ///
  /// In en, this message translates to:
  /// **'Download list'**
  String get dlList;

  /// No description provided for @dlActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dlActive;

  /// No description provided for @dlDone.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get dlDone;

  /// No description provided for @dlTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get dlTitle;

  /// No description provided for @dlOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Downloads Folder'**
  String get dlOpenFolder;

  /// No description provided for @dlNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active downloads'**
  String get dlNoActive;

  /// No description provided for @dlNoActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Media you download from the video player will show up here.'**
  String get dlNoActiveBody;

  /// No description provided for @dlTorrent.
  ///
  /// In en, this message translates to:
  /// **'P2P Torrent'**
  String get dlTorrent;

  /// No description provided for @dlDebrid.
  ///
  /// In en, this message translates to:
  /// **'Cloud Debrid'**
  String get dlDebrid;

  /// No description provided for @dlDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct HTTP'**
  String get dlDirect;

  /// No description provided for @dlUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get dlUnknownError;

  /// No description provided for @dlResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get dlResume;

  /// No description provided for @dlRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry / Reconnect'**
  String get dlRetry;

  /// No description provided for @dlOpenLocation.
  ///
  /// In en, this message translates to:
  /// **'Open Folder Location'**
  String get dlOpenLocation;

  /// No description provided for @dlNoDone.
  ///
  /// In en, this message translates to:
  /// **'No downloaded media'**
  String get dlNoDone;

  /// No description provided for @dlNoDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Completed downloads will appear here for offline playback.'**
  String get dlNoDoneBody;

  /// No description provided for @dlOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline Media'**
  String get dlOffline;

  /// No description provided for @animeLoadFailedArabic.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Arabic Anime catalog. Check your internet connection.'**
  String get animeLoadFailedArabic;

  /// No description provided for @animeLoadFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Anime catalog. Please check your internet connection or retry.'**
  String get animeLoadFailedRetry;

  /// No description provided for @animeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Anime catalog. Check your internet connection.'**
  String get animeLoadFailed;

  /// No description provided for @animeCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load anime'**
  String get animeCouldNotLoad;

  /// No description provided for @animeTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending on AniList'**
  String get animeTrending;

  /// No description provided for @animeTrendingSub.
  ///
  /// In en, this message translates to:
  /// **'Top popular and trending series'**
  String get animeTrendingSub;

  /// No description provided for @animeSeasonPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular This Season (AniList Sync)'**
  String get animeSeasonPopular;

  /// No description provided for @animeMasterpieces.
  ///
  /// In en, this message translates to:
  /// **'All-Time Masterpieces'**
  String get animeMasterpieces;

  /// No description provided for @animeMasterpiecesSub.
  ///
  /// In en, this message translates to:
  /// **'Critically acclaimed top rated anime'**
  String get animeMasterpiecesSub;

  /// No description provided for @animeNextSeason.
  ///
  /// In en, this message translates to:
  /// **'Anticipated Next Season'**
  String get animeNextSeason;

  /// No description provided for @animeNextSeasonSub.
  ///
  /// In en, this message translates to:
  /// **'Upcoming anime you cannot miss'**
  String get animeNextSeasonSub;

  /// No description provided for @animeAction.
  ///
  /// In en, this message translates to:
  /// **'Action & Adventure'**
  String get animeAction;

  /// No description provided for @animeActionSub.
  ///
  /// In en, this message translates to:
  /// **'High octane battles and epic journeys'**
  String get animeActionSub;

  /// No description provided for @animeRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance & Drama'**
  String get animeRomance;

  /// No description provided for @animeRomanceSub.
  ///
  /// In en, this message translates to:
  /// **'Heartfelt emotional stories'**
  String get animeRomanceSub;

  /// No description provided for @animeFantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy & Isekai'**
  String get animeFantasy;

  /// No description provided for @animeFantasySub.
  ///
  /// In en, this message translates to:
  /// **'Magical realms and alternate worlds'**
  String get animeFantasySub;

  /// No description provided for @animeSciFi.
  ///
  /// In en, this message translates to:
  /// **'Sci-Fi & Cyberpunk'**
  String get animeSciFi;

  /// No description provided for @animeSciFiSub.
  ///
  /// In en, this message translates to:
  /// **'Futuristic technologies and dystopian worlds'**
  String get animeSciFiSub;

  /// No description provided for @animeCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Anime catalogue'**
  String get animeCatalogue;

  /// No description provided for @animeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search anime'**
  String get animeSearch;

  /// No description provided for @animeAnilistDetails.
  ///
  /// In en, this message translates to:
  /// **'AniList Details'**
  String get animeAnilistDetails;

  /// No description provided for @animeSortTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get animeSortTrending;

  /// No description provided for @animeSortPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get animeSortPopular;

  /// No description provided for @animeSortTop.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get animeSortTop;

  /// No description provided for @animeSortFavorited.
  ///
  /// In en, this message translates to:
  /// **'Most Favorited'**
  String get animeSortFavorited;

  /// No description provided for @animeSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get animeSortNewest;

  /// No description provided for @animeSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get animeSortOldest;

  /// No description provided for @animeSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (A-Z)'**
  String get animeSortTitle;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @animeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search anime, movies, OVAs...'**
  String get animeSearchHint;

  /// No description provided for @animeSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get animeSortBy;

  /// No description provided for @animeGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get animeGenre;

  /// No description provided for @animeYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get animeYear;

  /// No description provided for @animeSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get animeSeason;

  /// No description provided for @animeFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get animeFormat;

  /// No description provided for @animeStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get animeStatus;

  /// No description provided for @animeReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get animeReset;

  /// No description provided for @animeNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No anime found matching your criteria'**
  String get animeNoMatch;

  /// No description provided for @animeNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or clearing filters'**
  String get animeNoMatchBody;

  /// No description provided for @animeTvSeries.
  ///
  /// In en, this message translates to:
  /// **'Anime TV Series'**
  String get animeTvSeries;

  /// No description provided for @animeMovies.
  ///
  /// In en, this message translates to:
  /// **'Anime Movies'**
  String get animeMovies;

  /// No description provided for @animeAddToList.
  ///
  /// In en, this message translates to:
  /// **'ADD TO LIST'**
  String get animeAddToList;

  /// No description provided for @animeCast.
  ///
  /// In en, this message translates to:
  /// **'Characters & Cast'**
  String get animeCast;

  /// No description provided for @animeRelations.
  ///
  /// In en, this message translates to:
  /// **'Franchise & Relations'**
  String get animeRelations;

  /// No description provided for @animeAlsoLike.
  ///
  /// In en, this message translates to:
  /// **'You May Also Like'**
  String get animeAlsoLike;

  /// No description provided for @animeWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get animeWatching;

  /// No description provided for @animePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan to Watch'**
  String get animePlan;

  /// No description provided for @animeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get animeCompleted;

  /// No description provided for @animeDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get animeDropped;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Lumora'**
  String get aboutTitle;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Movies, series and anime in one place'**
  String get aboutTagline;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Lumora brings movies, TV series, anime and live TV together in one app, and picks the source that plays fastest for you.'**
  String get aboutBody;

  /// No description provided for @aboutTech.
  ///
  /// In en, this message translates to:
  /// **'CORE TECHNOLOGIES'**
  String get aboutTech;

  /// No description provided for @aboutTechEngine.
  ///
  /// In en, this message translates to:
  /// **'High-Performance Video Engine'**
  String get aboutTechEngine;

  /// No description provided for @aboutTechSources.
  ///
  /// In en, this message translates to:
  /// **'Debrid & Multi-Source Scrapers'**
  String get aboutTechSources;

  /// No description provided for @aboutTechSourcesBody.
  ///
  /// In en, this message translates to:
  /// **'Direct high-speed cloud playback via Real-Debrid, TorBox, and Stremio addons.'**
  String get aboutTechSourcesBody;

  /// No description provided for @aboutTechGlass.
  ///
  /// In en, this message translates to:
  /// **'Liquid Glass GLSL Shaders'**
  String get aboutTechGlass;

  /// No description provided for @aboutTechGlassBody.
  ///
  /// In en, this message translates to:
  /// **'Custom real-time optical refraction, lenses, and fluid physics.'**
  String get aboutTechGlassBody;

  /// No description provided for @aboutTechSync.
  ///
  /// In en, this message translates to:
  /// **'Trakt & Cloud Synchronization'**
  String get aboutTechSync;

  /// No description provided for @aboutTechSyncBody.
  ///
  /// In en, this message translates to:
  /// **'Cross-platform watchlist, episode tracking, and playback scrobbling.'**
  String get aboutTechSyncBody;

  /// No description provided for @aboutCredits.
  ///
  /// In en, this message translates to:
  /// **'CREDITS & LICENCE'**
  String get aboutCredits;

  /// No description provided for @aboutZplayCredit.
  ///
  /// In en, this message translates to:
  /// **'Lumora is built on ZPlay by tzero86'**
  String get aboutZplayCredit;

  /// No description provided for @aboutPlaytorrio.
  ///
  /// In en, this message translates to:
  /// **'Based on PlayTorrio V3'**
  String get aboutPlaytorrio;

  /// No description provided for @aboutPlaytorrioCredit.
  ///
  /// In en, this message translates to:
  /// **'Original project by Ayman (@ayman708-UX)'**
  String get aboutPlaytorrioCredit;

  /// No description provided for @aboutFontLicense.
  ///
  /// In en, this message translates to:
  /// **'Poppins is bundled under the SIL Open Font License 1.1.'**
  String get aboutFontLicense;

  /// No description provided for @aboutTmdb.
  ///
  /// In en, this message translates to:
  /// **'This product uses the TMDB API but is not endorsed or certified by TMDB.'**
  String get aboutTmdb;

  /// No description provided for @aboutGplBody.
  ///
  /// In en, this message translates to:
  /// **'Lumora is a modified version of ZPlay, itself a modified version of PlayTorrio V3, distributed under the GNU General Public License v3.0. Tap to read the licence.'**
  String get aboutGplBody;

  /// No description provided for @updatesUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Lumora is up to date!'**
  String get updatesUpToDate;

  /// No description provided for @updatesTitle.
  ///
  /// In en, this message translates to:
  /// **'App Updates & System'**
  String get updatesTitle;

  /// No description provided for @updatesBody.
  ///
  /// In en, this message translates to:
  /// **'Keep Lumora up to date with the latest features, security patches, and performance improvements.'**
  String get updatesBody;

  /// No description provided for @updatesChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get updatesChecking;

  /// No description provided for @updatesCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get updatesCheck;

  /// No description provided for @updatesChannels.
  ///
  /// In en, this message translates to:
  /// **'RELEASE CHANNELS'**
  String get updatesChannels;

  /// No description provided for @updatesStable.
  ///
  /// In en, this message translates to:
  /// **'Official Stable Channel'**
  String get updatesStable;

  /// No description provided for @updatesStableBody.
  ///
  /// In en, this message translates to:
  /// **'Direct GitHub release distribution with automated checksum verification.'**
  String get updatesStableBody;

  /// No description provided for @updatesInApp.
  ///
  /// In en, this message translates to:
  /// **'Seamless In-App Patching'**
  String get updatesInApp;

  /// No description provided for @updatesInAppBody.
  ///
  /// In en, this message translates to:
  /// **'Downloads and applies executable updates directly without manual file downloads.'**
  String get updatesInAppBody;

  /// No description provided for @provTitle.
  ///
  /// In en, this message translates to:
  /// **'Built-in Providers'**
  String get provTitle;

  /// No description provided for @provResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset Providers Order?'**
  String get provResetConfirm;

  /// No description provided for @provResetBody.
  ///
  /// In en, this message translates to:
  /// **'This will restore all 45 direct providers to their default order and re-enable any disabled providers.'**
  String get provResetBody;

  /// No description provided for @provDefaultMode.
  ///
  /// In en, this message translates to:
  /// **'Default Mode'**
  String get provDefaultMode;

  /// No description provided for @provDefaultModeBody.
  ///
  /// In en, this message translates to:
  /// **'Standard auto-sorting across all 45 providers'**
  String get provDefaultModeBody;

  /// No description provided for @provCustomMode.
  ///
  /// In en, this message translates to:
  /// **'Custom Mode'**
  String get provCustomMode;

  /// No description provided for @provCustomModeBody.
  ///
  /// In en, this message translates to:
  /// **'Manual provider order, toggles & priority scraping'**
  String get provCustomModeBody;

  /// No description provided for @provDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get provDefault;

  /// No description provided for @provDefaultShort.
  ///
  /// In en, this message translates to:
  /// **'Standard auto-sorting'**
  String get provDefaultShort;

  /// No description provided for @provCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get provCustom;

  /// No description provided for @provCustomShort.
  ///
  /// In en, this message translates to:
  /// **'Manual order & toggles'**
  String get provCustomShort;

  /// No description provided for @provDefaultActive.
  ///
  /// In en, this message translates to:
  /// **'Default Mode Active'**
  String get provDefaultActive;

  /// No description provided for @provDefaultActiveBody.
  ///
  /// In en, this message translates to:
  /// **'In Default mode all providers run at once and results are sorted by resolution (4K, 1080p, 720p) and file size.'**
  String get provDefaultActiveBody;

  /// No description provided for @provSwitchCustom.
  ///
  /// In en, this message translates to:
  /// **'Switch to Custom Mode'**
  String get provSwitchCustom;

  /// No description provided for @provPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority Scrape & Result Sorting'**
  String get provPriority;

  /// No description provided for @provPriorityBody.
  ///
  /// In en, this message translates to:
  /// **'Providers at the top scrape first, and their results always show at the top, whatever their size or quality.'**
  String get provPriorityBody;

  /// No description provided for @provSearch.
  ///
  /// In en, this message translates to:
  /// **'Search providers (e.g. CineSrc)...'**
  String get provSearch;

  /// No description provided for @provSearch2.
  ///
  /// In en, this message translates to:
  /// **'Search providers (e.g. CineSrc, Dulo)...'**
  String get provSearch2;

  /// No description provided for @provEnableAll.
  ///
  /// In en, this message translates to:
  /// **'Enable All'**
  String get provEnableAll;

  /// No description provided for @provDisableAll.
  ///
  /// In en, this message translates to:
  /// **'Disable All'**
  String get provDisableAll;

  /// No description provided for @provClearToReorder.
  ///
  /// In en, this message translates to:
  /// **'Clear search to drag & reorder'**
  String get provClearToReorder;

  /// No description provided for @provMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move Up'**
  String get provMoveUp;

  /// No description provided for @provMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
  String get provMoveDown;

  /// No description provided for @navSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get navSeries;

  /// No description provided for @navMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get navMovies;

  /// No description provided for @navAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get navAnime;

  /// No description provided for @navMyList.
  ///
  /// In en, this message translates to:
  /// **'My List'**
  String get navMyList;

  /// No description provided for @navMyListShort.
  ///
  /// In en, this message translates to:
  /// **'My List'**
  String get navMyListShort;

  /// No description provided for @navDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get navDownloads;

  /// No description provided for @navMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navMe;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @catTrendingSeries.
  ///
  /// In en, this message translates to:
  /// **'Trending series'**
  String get catTrendingSeries;

  /// No description provided for @catCnDrama.
  ///
  /// In en, this message translates to:
  /// **'Chinese dramas'**
  String get catCnDrama;

  /// No description provided for @catHkDrama.
  ///
  /// In en, this message translates to:
  /// **'Hong Kong dramas'**
  String get catHkDrama;

  /// No description provided for @catKrDrama.
  ///
  /// In en, this message translates to:
  /// **'Korean dramas'**
  String get catKrDrama;

  /// No description provided for @catUsDrama.
  ///
  /// In en, this message translates to:
  /// **'American series'**
  String get catUsDrama;

  /// No description provided for @catTwDrama.
  ///
  /// In en, this message translates to:
  /// **'Taiwanese dramas'**
  String get catTwDrama;

  /// No description provided for @catJpDrama.
  ///
  /// In en, this message translates to:
  /// **'Japanese dramas'**
  String get catJpDrama;

  /// No description provided for @catGbDrama.
  ///
  /// In en, this message translates to:
  /// **'British series'**
  String get catGbDrama;

  /// No description provided for @catTopSeries.
  ///
  /// In en, this message translates to:
  /// **'Top rated series'**
  String get catTopSeries;

  /// No description provided for @catTrendingMovies.
  ///
  /// In en, this message translates to:
  /// **'Trending films'**
  String get catTrendingMovies;

  /// No description provided for @catNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'In cinemas'**
  String get catNowPlaying;

  /// No description provided for @catChineseMovies.
  ///
  /// In en, this message translates to:
  /// **'Chinese-language films'**
  String get catChineseMovies;

  /// No description provided for @catHkMovies.
  ///
  /// In en, this message translates to:
  /// **'Hong Kong films'**
  String get catHkMovies;

  /// No description provided for @catUsMovies.
  ///
  /// In en, this message translates to:
  /// **'Hollywood'**
  String get catUsMovies;

  /// No description provided for @catKrMovies.
  ///
  /// In en, this message translates to:
  /// **'Korean films'**
  String get catKrMovies;

  /// No description provided for @catJpMovies.
  ///
  /// In en, this message translates to:
  /// **'Japanese films'**
  String get catJpMovies;

  /// No description provided for @catAnimatedMovies.
  ///
  /// In en, this message translates to:
  /// **'Animated films'**
  String get catAnimatedMovies;

  /// No description provided for @catTopMovies.
  ///
  /// In en, this message translates to:
  /// **'Top rated films'**
  String get catTopMovies;

  /// No description provided for @catTrendingAnime.
  ///
  /// In en, this message translates to:
  /// **'Trending animation'**
  String get catTrendingAnime;

  /// No description provided for @catDonghua.
  ///
  /// In en, this message translates to:
  /// **'Chinese animation'**
  String get catDonghua;

  /// No description provided for @catJpAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get catJpAnime;

  /// No description provided for @catTopAnime.
  ///
  /// In en, this message translates to:
  /// **'Top rated animation'**
  String get catTopAnime;

  /// No description provided for @catAddToList.
  ///
  /// In en, this message translates to:
  /// **'Add to My List'**
  String get catAddToList;

  /// No description provided for @catDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get catDetails;

  /// No description provided for @catEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show here yet. These rows come from TMDb; check the TMDb key in Settings.'**
  String get catEmpty;

  /// No description provided for @settingsMoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manga, books, audiobooks, music and collections'**
  String get settingsMoreSubtitle;

  /// No description provided for @homeResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeResume;

  /// No description provided for @homeResumeEpisode.
  ///
  /// In en, this message translates to:
  /// **'Resume E{episode}'**
  String homeResumeEpisode(int episode);

  /// No description provided for @cwEpisode.
  ///
  /// In en, this message translates to:
  /// **'E{episode}'**
  String cwEpisode(int episode);

  /// No description provided for @cwSeasonEpisode.
  ///
  /// In en, this message translates to:
  /// **'S{season} E{episode}'**
  String cwSeasonEpisode(int season, int episode);

  /// No description provided for @cwMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get cwMovie;

  /// No description provided for @cwRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from Continue Watching'**
  String get cwRemove;

  /// No description provided for @catRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get catRecentlyUpdated;

  /// No description provided for @heroSeriesBadge.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get heroSeriesBadge;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get filterRegion;

  /// No description provided for @filterGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get filterGenre;

  /// No description provided for @filterYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get filterYear;

  /// No description provided for @filterSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get filterSort;

  /// No description provided for @filterSortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get filterSortPopular;

  /// No description provided for @filterSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get filterSortNewest;

  /// No description provided for @filterSortRating.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get filterSortRating;

  /// No description provided for @filterRegionCn.
  ///
  /// In en, this message translates to:
  /// **'Mainland China'**
  String get filterRegionCn;

  /// No description provided for @filterRegionHk.
  ///
  /// In en, this message translates to:
  /// **'Hong Kong'**
  String get filterRegionHk;

  /// No description provided for @filterRegionTw.
  ///
  /// In en, this message translates to:
  /// **'Taiwan'**
  String get filterRegionTw;

  /// No description provided for @filterRegionKr.
  ///
  /// In en, this message translates to:
  /// **'Korea'**
  String get filterRegionKr;

  /// No description provided for @filterRegionJp.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get filterRegionJp;

  /// No description provided for @filterRegionUs.
  ///
  /// In en, this message translates to:
  /// **'US'**
  String get filterRegionUs;

  /// No description provided for @filterRegionGb.
  ///
  /// In en, this message translates to:
  /// **'UK'**
  String get filterRegionGb;

  /// No description provided for @filterRegionTh.
  ///
  /// In en, this message translates to:
  /// **'Thailand'**
  String get filterRegionTh;

  /// No description provided for @filterRegionIn.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get filterRegionIn;

  /// No description provided for @filterRegionWest.
  ///
  /// In en, this message translates to:
  /// **'Western'**
  String get filterRegionWest;

  /// No description provided for @filterGenreAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get filterGenreAction;

  /// No description provided for @filterGenreComedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get filterGenreComedy;

  /// No description provided for @filterGenreDrama.
  ///
  /// In en, this message translates to:
  /// **'Drama'**
  String get filterGenreDrama;

  /// No description provided for @filterGenreRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get filterGenreRomance;

  /// No description provided for @filterGenreSciFi.
  ///
  /// In en, this message translates to:
  /// **'Sci-fi'**
  String get filterGenreSciFi;

  /// No description provided for @filterGenreFantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get filterGenreFantasy;

  /// No description provided for @filterGenreHorror.
  ///
  /// In en, this message translates to:
  /// **'Horror'**
  String get filterGenreHorror;

  /// No description provided for @filterGenreThriller.
  ///
  /// In en, this message translates to:
  /// **'Thriller'**
  String get filterGenreThriller;

  /// No description provided for @filterGenreCrime.
  ///
  /// In en, this message translates to:
  /// **'Crime'**
  String get filterGenreCrime;

  /// No description provided for @filterGenreMystery.
  ///
  /// In en, this message translates to:
  /// **'Mystery'**
  String get filterGenreMystery;

  /// No description provided for @filterGenreAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get filterGenreAdventure;

  /// No description provided for @filterGenreWar.
  ///
  /// In en, this message translates to:
  /// **'War'**
  String get filterGenreWar;

  /// No description provided for @filterGenreFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get filterGenreFamily;

  /// No description provided for @filterGenreDocumentary.
  ///
  /// In en, this message translates to:
  /// **'Documentary'**
  String get filterGenreDocumentary;

  /// No description provided for @filterGenreActionAdventure.
  ///
  /// In en, this message translates to:
  /// **'Action & adventure'**
  String get filterGenreActionAdventure;

  /// No description provided for @filterGenreSciFiFantasy.
  ///
  /// In en, this message translates to:
  /// **'Sci-fi & fantasy'**
  String get filterGenreSciFiFantasy;

  /// No description provided for @filterGenreWarPolitics.
  ///
  /// In en, this message translates to:
  /// **'War & politics'**
  String get filterGenreWarPolitics;

  /// No description provided for @filterGenreReality.
  ///
  /// In en, this message translates to:
  /// **'Variety'**
  String get filterGenreReality;

  /// No description provided for @filterGenreKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get filterGenreKids;

  /// No description provided for @filterYears2020s.
  ///
  /// In en, this message translates to:
  /// **'2020s'**
  String get filterYears2020s;

  /// No description provided for @filterYears2010s.
  ///
  /// In en, this message translates to:
  /// **'2010s'**
  String get filterYears2010s;

  /// No description provided for @filterYears2000s.
  ///
  /// In en, this message translates to:
  /// **'2000s'**
  String get filterYears2000s;

  /// No description provided for @filterYearsOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get filterYearsOlder;

  /// No description provided for @filterNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters.'**
  String get filterNoResults;

  /// No description provided for @filterLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get filterLoadMore;

  /// No description provided for @heroMovieBadge.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get heroMovieBadge;

  /// No description provided for @introOutroTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip intro & credits'**
  String get introOutroTitle;

  /// No description provided for @introOutroButton.
  ///
  /// In en, this message translates to:
  /// **'Intro/credits'**
  String get introOutroButton;

  /// No description provided for @introOutroAuto.
  ///
  /// In en, this message translates to:
  /// **'Skip intro automatically'**
  String get introOutroAuto;

  /// No description provided for @introOutroOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get introOutroOn;

  /// No description provided for @introOutroOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get introOutroOff;

  /// No description provided for @introOutroIntro.
  ///
  /// In en, this message translates to:
  /// **'Intro ends'**
  String get introOutroIntro;

  /// No description provided for @introOutroOutro.
  ///
  /// In en, this message translates to:
  /// **'Credits start'**
  String get introOutroOutro;

  /// No description provided for @introOutroSetHere.
  ///
  /// In en, this message translates to:
  /// **'Set to now'**
  String get introOutroSetHere;

  /// No description provided for @introOutroClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get introOutroClear;

  /// No description provided for @introOutroHint.
  ///
  /// In en, this message translates to:
  /// **'Press “Set to now” where the intro ends or the credits start; every episode of this show is skipped the same way.'**
  String get introOutroHint;

  /// No description provided for @introSkipped.
  ///
  /// In en, this message translates to:
  /// **'Intro skipped'**
  String get introSkipped;

  /// No description provided for @upNextIn.
  ///
  /// In en, this message translates to:
  /// **'Next episode in {seconds}s'**
  String upNextIn(int seconds);

  /// No description provided for @upNextPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get upNextPlayNow;

  /// No description provided for @upNextCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get upNextCancel;

  /// No description provided for @skipIntro.
  ///
  /// In en, this message translates to:
  /// **'Skip Intro'**
  String get skipIntro;

  /// No description provided for @skipRecap.
  ///
  /// In en, this message translates to:
  /// **'Skip Recap'**
  String get skipRecap;

  /// No description provided for @skipCredits.
  ///
  /// In en, this message translates to:
  /// **'Skip Credits'**
  String get skipCredits;

  /// No description provided for @skipPreview.
  ///
  /// In en, this message translates to:
  /// **'Skip Preview'**
  String get skipPreview;

  /// No description provided for @detailsPlayEpisode.
  ///
  /// In en, this message translates to:
  /// **'Play E{episode}'**
  String detailsPlayEpisode(int episode);

  /// No description provided for @detailsPlaySeasonEpisode.
  ///
  /// In en, this message translates to:
  /// **'Play S{season} E{episode}'**
  String detailsPlaySeasonEpisode(int season, int episode);

  /// No description provided for @detailsWatched.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get detailsWatched;

  /// No description provided for @playerTooShort.
  ///
  /// In en, this message translates to:
  /// **'This source is only {minutes} min long, not the episode. Pick another source.'**
  String playerTooShort(int minutes);

  /// No description provided for @playerTooShortNext.
  ///
  /// In en, this message translates to:
  /// **'This source is only {minutes} min long, not the episode. Trying the next one…'**
  String playerTooShortNext(int minutes);

  /// No description provided for @abkAudiobookDetails.
  ///
  /// In en, this message translates to:
  /// **'Audiobook Details'**
  String get abkAudiobookDetails;

  /// No description provided for @abkChaptersAudioFiles.
  ///
  /// In en, this message translates to:
  /// **'Chapters & Audio Files'**
  String get abkChaptersAudioFiles;

  /// No description provided for @abkCouldNotLoadChapters.
  ///
  /// In en, this message translates to:
  /// **'Could not load chapters'**
  String get abkCouldNotLoadChapters;

  /// No description provided for @abkNoPlayableChaptersFound.
  ///
  /// In en, this message translates to:
  /// **'No playable chapters found.'**
  String get abkNoPlayableChaptersFound;

  /// No description provided for @abkPlayFirstChapter.
  ///
  /// In en, this message translates to:
  /// **'Play First Chapter'**
  String get abkPlayFirstChapter;

  /// No description provided for @abkInitializingChapter.
  ///
  /// In en, this message translates to:
  /// **'Initializing chapter...'**
  String get abkInitializingChapter;

  /// No description provided for @abkFetchingTorrentMetadataPeers.
  ///
  /// In en, this message translates to:
  /// **'Fetching torrent metadata & peers...'**
  String get abkFetchingTorrentMetadataPeers;

  /// No description provided for @abkAudioPlayerDesignPreset.
  ///
  /// In en, this message translates to:
  /// **'Audio player design preset'**
  String get abkAudioPlayerDesignPreset;

  /// No description provided for @abkSeekBarScrubberStyle.
  ///
  /// In en, this message translates to:
  /// **'Seek bar scrubber style'**
  String get abkSeekBarScrubberStyle;

  /// No description provided for @abkPlayPauseButtonStyle.
  ///
  /// In en, this message translates to:
  /// **'Play pause button style'**
  String get abkPlayPauseButtonStyle;

  /// No description provided for @abkOpenDragDropPlayerStudio.
  ///
  /// In en, this message translates to:
  /// **'Open Drag & Drop Player Studio'**
  String get abkOpenDragDropPlayerStudio;

  /// No description provided for @abkCustomizeAudioPlayer.
  ///
  /// In en, this message translates to:
  /// **'Customize Audio Player'**
  String get abkCustomizeAudioPlayer;

  /// No description provided for @abkChaptersList.
  ///
  /// In en, this message translates to:
  /// **'Chapters List'**
  String get abkChaptersList;

  /// No description provided for @abkRetryChapter.
  ///
  /// In en, this message translates to:
  /// **'Retry Chapter'**
  String get abkRetryChapter;

  /// No description provided for @abkPreviousChapter.
  ///
  /// In en, this message translates to:
  /// **'Previous Chapter'**
  String get abkPreviousChapter;

  /// No description provided for @abkRewind10s.
  ///
  /// In en, this message translates to:
  /// **'Rewind 10s'**
  String get abkRewind10s;

  /// No description provided for @abkForward10s.
  ///
  /// In en, this message translates to:
  /// **'Forward 10s'**
  String get abkForward10s;

  /// No description provided for @abkNextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next Chapter'**
  String get abkNextChapter;

  /// No description provided for @abkPauseCaps.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get abkPauseCaps;

  /// No description provided for @abkPlayCaps.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get abkPlayCaps;

  /// No description provided for @abkFilterChaptersByName.
  ///
  /// In en, this message translates to:
  /// **'Filter chapters by name...'**
  String get abkFilterChaptersByName;

  /// No description provided for @abkVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get abkVolume;

  /// No description provided for @abkCustomizeAudiobookSection.
  ///
  /// In en, this message translates to:
  /// **'Customize Audiobook Section'**
  String get abkCustomizeAudiobookSection;

  /// No description provided for @abkPosterCardDensity.
  ///
  /// In en, this message translates to:
  /// **'Poster Card Density'**
  String get abkPosterCardDensity;

  /// No description provided for @abkAudiobookPosterCardDensity.
  ///
  /// In en, this message translates to:
  /// **'Audiobook poster card density'**
  String get abkAudiobookPosterCardDensity;

  /// No description provided for @abkFeaturedHeroSpotlightCarousel.
  ///
  /// In en, this message translates to:
  /// **'Featured Hero Spotlight Carousel'**
  String get abkFeaturedHeroSpotlightCarousel;

  /// No description provided for @abkMovingAmbientBackgroundGlow.
  ///
  /// In en, this message translates to:
  /// **'Moving Ambient Background Glow'**
  String get abkMovingAmbientBackgroundGlow;

  /// No description provided for @abkShowContinueListeningCarousel.
  ///
  /// In en, this message translates to:
  /// **'Show \"Continue Listening\" Carousel'**
  String get abkShowContinueListeningCarousel;

  /// No description provided for @abkOpenPlayerStudioThemes.
  ///
  /// In en, this message translates to:
  /// **'Open Player Studio & Themes'**
  String get abkOpenPlayerStudioThemes;

  /// No description provided for @abkAudiobookHub.
  ///
  /// In en, this message translates to:
  /// **'Audiobook Hub'**
  String get abkAudiobookHub;

  /// No description provided for @abkExploreStreamListenToThousandsOf.
  ///
  /// In en, this message translates to:
  /// **'Explore, stream & listen to thousands of stories'**
  String get abkExploreStreamListenToThousandsOf;

  /// No description provided for @abkAudiobookGeneratorStudio.
  ///
  /// In en, this message translates to:
  /// **'Audiobook Generator & Studio'**
  String get abkAudiobookGeneratorStudio;

  /// No description provided for @abkAudiobookCustomizer.
  ///
  /// In en, this message translates to:
  /// **'Audiobook Customizer'**
  String get abkAudiobookCustomizer;

  /// No description provided for @abkSearchAudiobooksByTitleAuthorOr.
  ///
  /// In en, this message translates to:
  /// **'Search audiobooks by title, author, or genre...'**
  String get abkSearchAudiobooksByTitleAuthorOr;

  /// No description provided for @abkAudiobookGenres.
  ///
  /// In en, this message translates to:
  /// **'Audiobook genres'**
  String get abkAudiobookGenres;

  /// No description provided for @abkSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get abkSearchResults;

  /// No description provided for @abkFeaturedAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'Featured Audiobooks'**
  String get abkFeaturedAudiobooks;

  /// No description provided for @abkScrapingHighQualityAudiobookSources.
  ///
  /// In en, this message translates to:
  /// **'Scraping high-quality audiobook sources...'**
  String get abkScrapingHighQualityAudiobookSources;

  /// No description provided for @abkCouldNotLoadAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'Could not load audiobooks'**
  String get abkCouldNotLoadAudiobooks;

  /// No description provided for @abkNoAudiobooksFoundTryAnotherSearch.
  ///
  /// In en, this message translates to:
  /// **'No audiobooks found. Try another search query.'**
  String get abkNoAudiobooksFoundTryAnotherSearch;

  /// No description provided for @abkNowPlayingAudiobook.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING AUDIOBOOK'**
  String get abkNowPlayingAudiobook;

  /// No description provided for @abkSpotlightFeatured.
  ///
  /// In en, this message translates to:
  /// **'SPOTLIGHT FEATURED'**
  String get abkSpotlightFeatured;

  /// No description provided for @abkListenNow.
  ///
  /// In en, this message translates to:
  /// **'Listen Now'**
  String get abkListenNow;

  /// No description provided for @abkContinueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue Listening'**
  String get abkContinueListening;

  /// No description provided for @abkAiAudiobookStudioEpubGenerator.
  ///
  /// In en, this message translates to:
  /// **'AI Audiobook Studio & EPUB Generator'**
  String get abkAiAudiobookStudioEpubGenerator;

  /// No description provided for @abkGenerateAudiobooksFromEpubsOrImport.
  ///
  /// In en, this message translates to:
  /// **'Generate audiobooks from EPUBs or import your own MP3/M4B audiobooks.'**
  String get abkGenerateAudiobooksFromEpubsOrImport;

  /// No description provided for @abkOpenStudio.
  ///
  /// In en, this message translates to:
  /// **'Open Studio'**
  String get abkOpenStudio;

  /// No description provided for @abkMyGeneratedUploadedAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'My Generated & Uploaded Audiobooks'**
  String get abkMyGeneratedUploadedAudiobooks;

  /// No description provided for @abkStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get abkStudio;

  /// No description provided for @abkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get abkFailed;

  /// No description provided for @abkPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get abkPlay;

  /// No description provided for @abkEpubExceeds250kWords.
  ///
  /// In en, this message translates to:
  /// **'EPUB Exceeds 250k Words'**
  String get abkEpubExceeds250kWords;

  /// No description provided for @abkCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get abkCancel;

  /// No description provided for @abkSplitGenerate.
  ///
  /// In en, this message translates to:
  /// **'Split & Generate'**
  String get abkSplitGenerate;

  /// No description provided for @abkUploadCompleteGenerationStarted.
  ///
  /// In en, this message translates to:
  /// **'Upload complete — AI Audiobook generation started!'**
  String get abkUploadCompleteGenerationStarted;

  /// No description provided for @abkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get abkRemove;

  /// No description provided for @abkAddPersonalAudiobook.
  ///
  /// In en, this message translates to:
  /// **'Add Personal Audiobook'**
  String get abkAddPersonalAudiobook;

  /// No description provided for @abkAudiobookTitle.
  ///
  /// In en, this message translates to:
  /// **'Audiobook Title'**
  String get abkAudiobookTitle;

  /// No description provided for @abkAuthorNarrator.
  ///
  /// In en, this message translates to:
  /// **'Author / Narrator'**
  String get abkAuthorNarrator;

  /// No description provided for @abkSelectCoverArt.
  ///
  /// In en, this message translates to:
  /// **'Select Cover Art'**
  String get abkSelectCoverArt;

  /// No description provided for @abkChangeCover.
  ///
  /// In en, this message translates to:
  /// **'Change Cover'**
  String get abkChangeCover;

  /// No description provided for @abkImportToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Import to Library'**
  String get abkImportToLibrary;

  /// No description provided for @abkAudiobookStudioGenerator.
  ///
  /// In en, this message translates to:
  /// **'Audiobook Studio & Generator'**
  String get abkAudiobookStudioGenerator;

  /// No description provided for @abkAudiobookStudioTabs.
  ///
  /// In en, this message translates to:
  /// **'Audiobook studio tabs'**
  String get abkAudiobookStudioTabs;

  /// No description provided for @abkRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get abkRefreshStatus;

  /// No description provided for @abkNoGeneratedAudiobooksYet.
  ///
  /// In en, this message translates to:
  /// **'No generated audiobooks yet'**
  String get abkNoGeneratedAudiobooksYet;

  /// No description provided for @abkPickAnEpubAboveToSynthesize.
  ///
  /// In en, this message translates to:
  /// **'Pick an EPUB above to synthesize high-quality voice narrations.'**
  String get abkPickAnEpubAboveToSynthesize;

  /// No description provided for @abkAiNarratorVoiceKokoroEngine.
  ///
  /// In en, this message translates to:
  /// **'AI Narrator Voice (Kokoro Engine)'**
  String get abkAiNarratorVoiceKokoroEngine;

  /// No description provided for @abkRescanBooks.
  ///
  /// In en, this message translates to:
  /// **'Rescan Books'**
  String get abkRescanBooks;

  /// No description provided for @abkGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get abkGenerate;

  /// No description provided for @abkAnalyzingUploadingBook.
  ///
  /// In en, this message translates to:
  /// **'Analyzing & Uploading Book...'**
  String get abkAnalyzingUploadingBook;

  /// No description provided for @abkSelectExternalEpubFile.
  ///
  /// In en, this message translates to:
  /// **'Select External EPUB File'**
  String get abkSelectExternalEpubFile;

  /// No description provided for @abkPickAnyEpubFileFromYour.
  ///
  /// In en, this message translates to:
  /// **'Pick any .epub file from your device. Large books (>250k words) are auto-split.'**
  String get abkPickAnyEpubFileFromYour;

  /// No description provided for @abkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get abkCompleted;

  /// No description provided for @abkPlayInApp.
  ///
  /// In en, this message translates to:
  /// **'Play in App'**
  String get abkPlayInApp;

  /// No description provided for @abkCopyStreamUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy Stream URL'**
  String get abkCopyStreamUrl;

  /// No description provided for @abkUploadPersonalAudiobookFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload Personal Audiobook Files'**
  String get abkUploadPersonalAudiobookFiles;

  /// No description provided for @abkImportYourOwnMp3M4bM4a.
  ///
  /// In en, this message translates to:
  /// **'Import your own .mp3, .m4b, .m4a, or .flac audiobooks to listen offline.'**
  String get abkImportYourOwnMp3M4bM4a;

  /// No description provided for @abkNoPersonalAudiobooksAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No personal audiobooks added yet'**
  String get abkNoPersonalAudiobooksAddedYet;

  /// No description provided for @abkTapTheBannerAboveToImport.
  ///
  /// In en, this message translates to:
  /// **'Tap the banner above to import audio files from your device.'**
  String get abkTapTheBannerAboveToImport;

  /// No description provided for @abkDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get abkDelete;

  /// No description provided for @bkResumeReading.
  ///
  /// In en, this message translates to:
  /// **'Resume Reading'**
  String get bkResumeReading;

  /// No description provided for @bkReadNow.
  ///
  /// In en, this message translates to:
  /// **'Read Now'**
  String get bkReadNow;

  /// No description provided for @bkGenerateAiAudiobookTts.
  ///
  /// In en, this message translates to:
  /// **'Generate AI Audiobook (TTS)'**
  String get bkGenerateAiAudiobookTts;

  /// No description provided for @bkDeleteDownloadedFile.
  ///
  /// In en, this message translates to:
  /// **'Delete downloaded file'**
  String get bkDeleteDownloadedFile;

  /// No description provided for @bkPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get bkPublisher;

  /// No description provided for @bkSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get bkSeries;

  /// No description provided for @bkLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get bkLanguage;

  /// No description provided for @bkFileFormat.
  ///
  /// In en, this message translates to:
  /// **'File Format'**
  String get bkFileFormat;

  /// No description provided for @bkSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get bkSize;

  /// No description provided for @bkDiscoverBooks.
  ///
  /// In en, this message translates to:
  /// **'Discover Books'**
  String get bkDiscoverBooks;

  /// No description provided for @bkCouldNotLoadBooks.
  ///
  /// In en, this message translates to:
  /// **'Could not load books'**
  String get bkCouldNotLoadBooks;

  /// No description provided for @bkNoBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get bkNoBooksFound;

  /// No description provided for @bkTrySearchingForAnotherTitleAuthor.
  ///
  /// In en, this message translates to:
  /// **'Try searching for another title, author, or language'**
  String get bkTrySearchingForAnotherTitleAuthor;

  /// No description provided for @bkSearchMillionsOfBooksAuthors.
  ///
  /// In en, this message translates to:
  /// **'Search millions of books & authors...'**
  String get bkSearchMillionsOfBooksAuthors;

  /// No description provided for @bkFontEngine.
  ///
  /// In en, this message translates to:
  /// **'Font Engine:'**
  String get bkFontEngine;

  /// No description provided for @bkReaderFontEngine.
  ///
  /// In en, this message translates to:
  /// **'Reader font engine'**
  String get bkReaderFontEngine;

  /// No description provided for @bkCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get bkCompact;

  /// No description provided for @bkStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get bkStandard;

  /// No description provided for @bkWide.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get bkWide;

  /// No description provided for @bkBookFormats.
  ///
  /// In en, this message translates to:
  /// **'Book formats'**
  String get bkBookFormats;

  /// No description provided for @bkTableOfContentsT.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents (T)'**
  String get bkTableOfContentsT;

  /// No description provided for @bkFocusModeLineByLine.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode (Line-by-Line)'**
  String get bkFocusModeLineByLine;

  /// No description provided for @bkAppearanceCustomization.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Customization'**
  String get bkAppearanceCustomization;

  /// No description provided for @bkToggleFullscreenF.
  ///
  /// In en, this message translates to:
  /// **'Toggle Fullscreen (F)'**
  String get bkToggleFullscreenF;

  /// No description provided for @bkPreviousChapterLeftArrow.
  ///
  /// In en, this message translates to:
  /// **'Previous Chapter (Left Arrow)'**
  String get bkPreviousChapterLeftArrow;

  /// No description provided for @bkNextChapterRightArrow.
  ///
  /// In en, this message translates to:
  /// **'Next Chapter (Right Arrow)'**
  String get bkNextChapterRightArrow;

  /// No description provided for @bkUnableToOpenBook.
  ///
  /// In en, this message translates to:
  /// **'Unable to open book'**
  String get bkUnableToOpenBook;

  /// No description provided for @bkNoReadableChaptersFound.
  ///
  /// In en, this message translates to:
  /// **'No readable chapters found.'**
  String get bkNoReadableChaptersFound;

  /// No description provided for @bkTableOfContents.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get bkTableOfContents;

  /// No description provided for @bkNoTableOfContentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No table of contents available'**
  String get bkNoTableOfContentsAvailable;

  /// No description provided for @bkBackToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Back to Library'**
  String get bkBackToLibrary;

  /// No description provided for @bkZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get bkZoomIn;

  /// No description provided for @bkZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get bkZoomOut;

  /// No description provided for @bkFullscreenF.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen (F)'**
  String get bkFullscreenF;

  /// No description provided for @bkPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get bkPreviousPage;

  /// No description provided for @bkNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get bkNextPage;

  /// No description provided for @bkZoomOutCtrl.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out (Ctrl -)'**
  String get bkZoomOutCtrl;

  /// No description provided for @bkZoomInCtrl.
  ///
  /// In en, this message translates to:
  /// **'Zoom In (Ctrl +)'**
  String get bkZoomInCtrl;

  /// No description provided for @bkResetZoom.
  ///
  /// In en, this message translates to:
  /// **'Reset Zoom (100%)'**
  String get bkResetZoom;

  /// No description provided for @bkFocusModeActive.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode Active'**
  String get bkFocusModeActive;

  /// No description provided for @bkExitFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Exit Focus Mode'**
  String get bkExitFocusMode;

  /// No description provided for @bkExitEsc.
  ///
  /// In en, this message translates to:
  /// **'Exit (Esc)'**
  String get bkExitEsc;

  /// No description provided for @bkTapAboveBelowToMoveKeys.
  ///
  /// In en, this message translates to:
  /// **'Tap above/below to move · ↑ ↓ keys to navigate'**
  String get bkTapAboveBelowToMoveKeys;

  /// No description provided for @bkPreviousLineUpArrow.
  ///
  /// In en, this message translates to:
  /// **'Previous Line (Up Arrow)'**
  String get bkPreviousLineUpArrow;

  /// No description provided for @bkNextLineDownArrowSpace.
  ///
  /// In en, this message translates to:
  /// **'Next Line (Down Arrow / Space)'**
  String get bkNextLineDownArrowSpace;

  /// No description provided for @bkCloseSettings.
  ///
  /// In en, this message translates to:
  /// **'Close Settings'**
  String get bkCloseSettings;

  /// No description provided for @bkAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get bkAppearance;

  /// No description provided for @bkReset.
  ///
  /// In en, this message translates to:
  /// **'Reset ✓'**
  String get bkReset;

  /// No description provided for @bkResetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get bkResetToDefaults;

  /// No description provided for @bkSerif.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get bkSerif;

  /// No description provided for @bkSans.
  ///
  /// In en, this message translates to:
  /// **'Sans'**
  String get bkSans;

  /// No description provided for @bkDyslexic.
  ///
  /// In en, this message translates to:
  /// **'Dyslexic'**
  String get bkDyslexic;

  /// No description provided for @bkMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get bkMono;

  /// No description provided for @bkFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get bkFontFamily;

  /// No description provided for @bkFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get bkFontSize;

  /// No description provided for @bkLineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get bkLineHeight;

  /// No description provided for @bkAlignment.
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get bkAlignment;

  /// No description provided for @bkFirstLineIndent.
  ///
  /// In en, this message translates to:
  /// **'First-Line Indent'**
  String get bkFirstLineIndent;

  /// No description provided for @bkReadingThemes.
  ///
  /// In en, this message translates to:
  /// **'Reading Themes'**
  String get bkReadingThemes;

  /// No description provided for @bkLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get bkLight;

  /// No description provided for @bkSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get bkSepia;

  /// No description provided for @bkDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get bkDark;

  /// No description provided for @bkAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED'**
  String get bkAmoled;

  /// No description provided for @bkReaderBrightness.
  ///
  /// In en, this message translates to:
  /// **'Reader Brightness'**
  String get bkReaderBrightness;

  /// No description provided for @bkPageMargins.
  ///
  /// In en, this message translates to:
  /// **'Page Margins'**
  String get bkPageMargins;

  /// No description provided for @bkBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get bkBalanced;

  /// No description provided for @bkReadingMode.
  ///
  /// In en, this message translates to:
  /// **'Reading Mode'**
  String get bkReadingMode;

  /// No description provided for @bkContinuousScroll.
  ///
  /// In en, this message translates to:
  /// **'Continuous Scroll'**
  String get bkContinuousScroll;

  /// No description provided for @bkPaginatedTurns.
  ///
  /// In en, this message translates to:
  /// **'Paginated Turns'**
  String get bkPaginatedTurns;

  /// No description provided for @mgChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get mgChapters;

  /// No description provided for @mgNoChaptersFound.
  ///
  /// In en, this message translates to:
  /// **'No chapters found.'**
  String get mgNoChaptersFound;

  /// No description provided for @mgChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get mgChapter;

  /// No description provided for @mgPreviousChapterPage.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter page'**
  String get mgPreviousChapterPage;

  /// No description provided for @mgNextChapterPage.
  ///
  /// In en, this message translates to:
  /// **'Next chapter page'**
  String get mgNextChapterPage;

  /// No description provided for @mgSearchChapters.
  ///
  /// In en, this message translates to:
  /// **'Search chapters...'**
  String get mgSearchChapters;

  /// No description provided for @mgClearChapterSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear chapter search'**
  String get mgClearChapterSearch;

  /// No description provided for @mgStartReading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get mgStartReading;

  /// No description provided for @mgBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get mgBack;

  /// No description provided for @mgCustomizeMangaSection.
  ///
  /// In en, this message translates to:
  /// **'Customize Manga Section'**
  String get mgCustomizeMangaSection;

  /// No description provided for @mgClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get mgClose;

  /// No description provided for @mgPosterCardDensity.
  ///
  /// In en, this message translates to:
  /// **'Poster Card Density'**
  String get mgPosterCardDensity;

  /// No description provided for @mgMangaPosterCardDensity.
  ///
  /// In en, this message translates to:
  /// **'Manga poster card density'**
  String get mgMangaPosterCardDensity;

  /// No description provided for @mgMovingAmbientBackgroundGlow.
  ///
  /// In en, this message translates to:
  /// **'Moving Ambient Background Glow'**
  String get mgMovingAmbientBackgroundGlow;

  /// No description provided for @mgShowContinueReadingSlider.
  ///
  /// In en, this message translates to:
  /// **'Show \"Continue Reading\" Slider'**
  String get mgShowContinueReadingSlider;

  /// No description provided for @mgShowContentTypeBadgeOnPosters.
  ///
  /// In en, this message translates to:
  /// **'Show Content Type Badge on Posters'**
  String get mgShowContentTypeBadgeOnPosters;

  /// No description provided for @mgMoreAppearanceReaderSettings.
  ///
  /// In en, this message translates to:
  /// **'More Appearance & Reader Settings'**
  String get mgMoreAppearanceReaderSettings;

  /// No description provided for @mgContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get mgContinueReading;

  /// No description provided for @mgSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get mgSearchResults;

  /// No description provided for @mgDiscoverManga.
  ///
  /// In en, this message translates to:
  /// **'Discover Manga'**
  String get mgDiscoverManga;

  /// No description provided for @mgFilteredByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filtered by category'**
  String get mgFilteredByCategory;

  /// No description provided for @mgResetToAllCategories.
  ///
  /// In en, this message translates to:
  /// **'Reset to All Categories'**
  String get mgResetToAllCategories;

  /// No description provided for @mgNoMangaFound.
  ///
  /// In en, this message translates to:
  /// **'No manga found'**
  String get mgNoMangaFound;

  /// No description provided for @mgSearchMangaManhwaManhua.
  ///
  /// In en, this message translates to:
  /// **'Search Manga, Manhwa, Manhua...'**
  String get mgSearchMangaManhwaManhua;

  /// No description provided for @mgClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get mgClearSearch;

  /// No description provided for @mgRemoveFromContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Remove from Continue Reading'**
  String get mgRemoveFromContinueReading;

  /// No description provided for @mgReaderSettingsLayout.
  ///
  /// In en, this message translates to:
  /// **'Reader Settings & Layout'**
  String get mgReaderSettingsLayout;

  /// No description provided for @mgReadingOrientationMode.
  ///
  /// In en, this message translates to:
  /// **'Reading Orientation Mode'**
  String get mgReadingOrientationMode;

  /// No description provided for @mgReadingOrientationModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reading orientation mode'**
  String get mgReadingOrientationModeLabel;

  /// No description provided for @mgPageReadingWidthConstraint.
  ///
  /// In en, this message translates to:
  /// **'Page Reading Width Constraint'**
  String get mgPageReadingWidthConstraint;

  /// No description provided for @mgPageReadingWidthConstraintLabel.
  ///
  /// In en, this message translates to:
  /// **'Page reading width constraint'**
  String get mgPageReadingWidthConstraintLabel;

  /// No description provided for @mgReaderBackgroundAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Reader Background Atmosphere'**
  String get mgReaderBackgroundAtmosphere;

  /// No description provided for @mgShowPageDeckPreviewsDrawer.
  ///
  /// In en, this message translates to:
  /// **'Show Page Deck Previews Drawer'**
  String get mgShowPageDeckPreviewsDrawer;

  /// No description provided for @mgShowNextChapterDeckCard.
  ///
  /// In en, this message translates to:
  /// **'Show Next Chapter Deck Card'**
  String get mgShowNextChapterDeckCard;

  /// No description provided for @mgNoPagesFoundForThisChapter.
  ///
  /// In en, this message translates to:
  /// **'No pages found for this chapter.'**
  String get mgNoPagesFoundForThisChapter;

  /// No description provided for @mgYouAreAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up!'**
  String get mgYouAreAllCaughtUp;

  /// No description provided for @mgUpNext.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT'**
  String get mgUpNext;

  /// No description provided for @mgChapterFinished.
  ///
  /// In en, this message translates to:
  /// **'CHAPTER FINISHED'**
  String get mgChapterFinished;

  /// No description provided for @mgReadNextChapter.
  ///
  /// In en, this message translates to:
  /// **'Read Next Chapter'**
  String get mgReadNextChapter;

  /// No description provided for @mgBackToMangaDetails.
  ///
  /// In en, this message translates to:
  /// **'Back to Manga Details'**
  String get mgBackToMangaDetails;

  /// No description provided for @mgPageDeckPreview.
  ///
  /// In en, this message translates to:
  /// **'Page Deck Preview'**
  String get mgPageDeckPreview;

  /// No description provided for @mgReaderCustomization.
  ///
  /// In en, this message translates to:
  /// **'Reader Customization'**
  String get mgReaderCustomization;

  /// No description provided for @mgPreviousChapter.
  ///
  /// In en, this message translates to:
  /// **'Previous Chapter'**
  String get mgPreviousChapter;

  /// No description provided for @mgZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out (-)'**
  String get mgZoomOut;

  /// No description provided for @mgZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In (+)'**
  String get mgZoomIn;

  /// No description provided for @mgTogglePageDeck.
  ///
  /// In en, this message translates to:
  /// **'Toggle Page Deck'**
  String get mgTogglePageDeck;

  /// No description provided for @mgNextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next Chapter'**
  String get mgNextChapter;

  /// No description provided for @mgReaderAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Reader Atmosphere:'**
  String get mgReaderAtmosphere;

  /// No description provided for @mgWebtoonScroll.
  ///
  /// In en, this message translates to:
  /// **'Webtoon Scroll'**
  String get mgWebtoonScroll;

  /// No description provided for @mgHorizontalLtr.
  ///
  /// In en, this message translates to:
  /// **'Horizontal LTR'**
  String get mgHorizontalLtr;

  /// No description provided for @mgHorizontalRtl.
  ///
  /// In en, this message translates to:
  /// **'Horizontal RTL'**
  String get mgHorizontalRtl;

  /// No description provided for @musHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get musHome;

  /// No description provided for @musSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get musSearch;

  /// No description provided for @musBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get musBrowse;

  /// No description provided for @musRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get musRadio;

  /// No description provided for @musLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get musLibrary;

  /// No description provided for @musLoadingArtistDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading artist details...'**
  String get musLoadingArtistDetails;

  /// No description provided for @musLoadingAlbum.
  ///
  /// In en, this message translates to:
  /// **'Loading album...'**
  String get musLoadingAlbum;

  /// No description provided for @musLoadingPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Loading playlist...'**
  String get musLoadingPlaylist;

  /// No description provided for @musSeekBack5s.
  ///
  /// In en, this message translates to:
  /// **'Seek -5s'**
  String get musSeekBack5s;

  /// No description provided for @musSeekForward5s.
  ///
  /// In en, this message translates to:
  /// **'Seek +5s'**
  String get musSeekForward5s;

  /// No description provided for @musMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get musMuted;

  /// No description provided for @musUnmuted.
  ///
  /// In en, this message translates to:
  /// **'Unmuted'**
  String get musUnmuted;

  /// No description provided for @musNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get musNewPlaylist;

  /// No description provided for @musEnterPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter playlist title...'**
  String get musEnterPlaylistTitle;

  /// No description provided for @musCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get musCancel;

  /// No description provided for @musCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get musCreate;

  /// No description provided for @musDownloadedOfflineTapToRemove.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Offline (Tap to Remove)'**
  String get musDownloadedOfflineTapToRemove;

  /// No description provided for @musDownloadingQueued.
  ///
  /// In en, this message translates to:
  /// **'Downloading / Queued...'**
  String get musDownloadingQueued;

  /// No description provided for @musDownloadTrackOffline.
  ///
  /// In en, this message translates to:
  /// **'Download Track Offline'**
  String get musDownloadTrackOffline;

  /// No description provided for @musSaveToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Save to Playlist'**
  String get musSaveToPlaylist;

  /// No description provided for @musNoCustomPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No custom playlists yet'**
  String get musNoCustomPlaylistsYet;

  /// No description provided for @musCreateFirstPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create First Playlist'**
  String get musCreateFirstPlaylist;

  /// No description provided for @musSavedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saved to Library'**
  String get musSavedToLibrary;

  /// No description provided for @musRemovedFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Removed from Library'**
  String get musRemovedFromLibrary;

  /// No description provided for @musNewAlbumReleases.
  ///
  /// In en, this message translates to:
  /// **'New Album Releases'**
  String get musNewAlbumReleases;

  /// No description provided for @musCuratedChartsMixes.
  ///
  /// In en, this message translates to:
  /// **'Curated Charts & Mixes'**
  String get musCuratedChartsMixes;

  /// No description provided for @musSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get musSearchResults;

  /// No description provided for @musSearchToFindTracksArtistsAlbums.
  ///
  /// In en, this message translates to:
  /// **'Search to find tracks, artists, albums and playlists'**
  String get musSearchToFindTracksArtistsAlbums;

  /// No description provided for @musSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get musSongs;

  /// No description provided for @musHipHopRap.
  ///
  /// In en, this message translates to:
  /// **'Hip-Hop & Rap'**
  String get musHipHopRap;

  /// No description provided for @musElectronicEdm.
  ///
  /// In en, this message translates to:
  /// **'Electronic & EDM'**
  String get musElectronicEdm;

  /// No description provided for @musChillLofiBeats.
  ///
  /// In en, this message translates to:
  /// **'Chill Lofi Beats'**
  String get musChillLofiBeats;

  /// No description provided for @musRBSoul.
  ///
  /// In en, this message translates to:
  /// **'R&B & Soul'**
  String get musRBSoul;

  /// No description provided for @musSoundtracksGaming.
  ///
  /// In en, this message translates to:
  /// **'Soundtracks & Gaming'**
  String get musSoundtracksGaming;

  /// No description provided for @musJazzBlues.
  ///
  /// In en, this message translates to:
  /// **'Jazz & Blues'**
  String get musJazzBlues;

  /// No description provided for @musBrowseMoodsGenres.
  ///
  /// In en, this message translates to:
  /// **'Browse Moods & Genres'**
  String get musBrowseMoodsGenres;

  /// No description provided for @musPopRadio.
  ///
  /// In en, this message translates to:
  /// **'Pop Radio'**
  String get musPopRadio;

  /// No description provided for @musRapHipHop.
  ///
  /// In en, this message translates to:
  /// **'Rap & Hip-Hop'**
  String get musRapHipHop;

  /// No description provided for @musRockMix.
  ///
  /// In en, this message translates to:
  /// **'Rock Mix'**
  String get musRockMix;

  /// No description provided for @musDanceElectro.
  ///
  /// In en, this message translates to:
  /// **'Dance & Electro'**
  String get musDanceElectro;

  /// No description provided for @musRBStation.
  ///
  /// In en, this message translates to:
  /// **'R&B Station'**
  String get musRBStation;

  /// No description provided for @musLofiAmbient.
  ///
  /// In en, this message translates to:
  /// **'Lofi & Ambient'**
  String get musLofiAmbient;

  /// No description provided for @musHeavyMetalStation.
  ///
  /// In en, this message translates to:
  /// **'Heavy Metal Station'**
  String get musHeavyMetalStation;

  /// No description provided for @musJazzClub.
  ///
  /// In en, this message translates to:
  /// **'Jazz Club'**
  String get musJazzClub;

  /// No description provided for @musYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your Library'**
  String get musYourLibrary;

  /// No description provided for @musNoLikedSongsYet.
  ///
  /// In en, this message translates to:
  /// **'No liked songs yet'**
  String get musNoLikedSongsYet;

  /// No description provided for @musLikedSongs.
  ///
  /// In en, this message translates to:
  /// **'Liked Songs'**
  String get musLikedSongs;

  /// No description provided for @musDownloadedSongs.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Songs'**
  String get musDownloadedSongs;

  /// No description provided for @musCustomPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Custom Playlists'**
  String get musCustomPlaylists;

  /// No description provided for @musRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get musRecentlyPlayed;

  /// No description provided for @musSearchShort.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get musSearchShort;

  /// No description provided for @musSearchMusic.
  ///
  /// In en, this message translates to:
  /// **'Search music…'**
  String get musSearchMusic;

  /// No description provided for @musSearchSongsArtistsAlbumsPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists, albums, playlists...'**
  String get musSearchSongsArtistsAlbumsPlaylists;

  /// No description provided for @musMusicPlayerStudio.
  ///
  /// In en, this message translates to:
  /// **'Music Player Studio'**
  String get musMusicPlayerStudio;

  /// No description provided for @musMusicAtmosphereSettings.
  ///
  /// In en, this message translates to:
  /// **'Music Atmosphere Settings'**
  String get musMusicAtmosphereSettings;

  /// No description provided for @musAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get musAppSettings;

  /// No description provided for @musMusicView.
  ///
  /// In en, this message translates to:
  /// **'Music view'**
  String get musMusicView;

  /// No description provided for @musAudioSourceQuality.
  ///
  /// In en, this message translates to:
  /// **'Audio Source & Quality'**
  String get musAudioSourceQuality;

  /// No description provided for @musChooseExtractionEngine.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred music extraction engine'**
  String get musChooseExtractionEngine;

  /// No description provided for @musFlacLosslessQobuzHiRes.
  ///
  /// In en, this message translates to:
  /// **'FLAC Lossless (Qobuz Hi-Res)'**
  String get musFlacLosslessQobuzHiRes;

  /// No description provided for @musStudioMasterQualityDesc.
  ///
  /// In en, this message translates to:
  /// **'Studio master quality up to 24-bit/192kHz with zero compression'**
  String get musStudioMasterQualityDesc;

  /// No description provided for @musLossless.
  ///
  /// In en, this message translates to:
  /// **'LOSSLESS'**
  String get musLossless;

  /// No description provided for @musYoutubeAudio.
  ///
  /// In en, this message translates to:
  /// **'YouTube Audio'**
  String get musYoutubeAudio;

  /// No description provided for @musYoutubeAudioDesc.
  ///
  /// In en, this message translates to:
  /// **'High-speed audio extraction with intelligent track & duration matching'**
  String get musYoutubeAudioDesc;

  /// No description provided for @musFast.
  ///
  /// In en, this message translates to:
  /// **'FAST'**
  String get musFast;

  /// No description provided for @musTopChartHit.
  ///
  /// In en, this message translates to:
  /// **'TOP CHART HIT'**
  String get musTopChartHit;

  /// No description provided for @musPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play Now'**
  String get musPlayNow;

  /// No description provided for @musTrendingArtists.
  ///
  /// In en, this message translates to:
  /// **'Trending Artists'**
  String get musTrendingArtists;

  /// No description provided for @musDownloadedOffline.
  ///
  /// In en, this message translates to:
  /// **'Downloaded (Offline)'**
  String get musDownloadedOffline;

  /// No description provided for @musQueuedForDownload.
  ///
  /// In en, this message translates to:
  /// **'Queued for download'**
  String get musQueuedForDownload;

  /// No description provided for @musDownloadTrack.
  ///
  /// In en, this message translates to:
  /// **'Download Track'**
  String get musDownloadTrack;

  /// No description provided for @musSyncedLyrics.
  ///
  /// In en, this message translates to:
  /// **'Synced Lyrics'**
  String get musSyncedLyrics;

  /// No description provided for @musNoLyricsFoundForThisTrack.
  ///
  /// In en, this message translates to:
  /// **'No lyrics found for this track.'**
  String get musNoLyricsFoundForThisTrack;

  /// No description provided for @musClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get musClear;

  /// No description provided for @musQueueIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get musQueueIsEmpty;

  /// No description provided for @musPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get musPlayAll;

  /// No description provided for @musTopSongs.
  ///
  /// In en, this message translates to:
  /// **'Top Songs'**
  String get musTopSongs;

  /// No description provided for @musAlbumsDiscography.
  ///
  /// In en, this message translates to:
  /// **'Albums & Discography'**
  String get musAlbumsDiscography;

  /// No description provided for @musAlbum.
  ///
  /// In en, this message translates to:
  /// **'ALBUM'**
  String get musAlbum;

  /// No description provided for @musPlayAlbum.
  ///
  /// In en, this message translates to:
  /// **'Play Album'**
  String get musPlayAlbum;

  /// No description provided for @musDownloadAlbum.
  ///
  /// In en, this message translates to:
  /// **'Download Album'**
  String get musDownloadAlbum;

  /// No description provided for @musPlayPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Play Playlist'**
  String get musPlayPlaylist;

  /// No description provided for @musDownloadPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Download Playlist'**
  String get musDownloadPlaylist;

  /// No description provided for @musDownloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get musDownloadAll;

  /// No description provided for @musNoTracksInThisPlaylistYet.
  ///
  /// In en, this message translates to:
  /// **'No tracks in this playlist yet'**
  String get musNoTracksInThisPlaylistYet;

  /// No description provided for @musPlayingQueue.
  ///
  /// In en, this message translates to:
  /// **'Playing Queue'**
  String get musPlayingQueue;

  /// No description provided for @musTogglePlayPause.
  ///
  /// In en, this message translates to:
  /// **'Toggle Play / Pause'**
  String get musTogglePlayPause;

  /// No description provided for @musSeek5SecondsBackward.
  ///
  /// In en, this message translates to:
  /// **'Seek -5 seconds backward'**
  String get musSeek5SecondsBackward;

  /// No description provided for @musSeek5SecondsForward.
  ///
  /// In en, this message translates to:
  /// **'Seek +5 seconds forward'**
  String get musSeek5SecondsForward;

  /// No description provided for @musToggleMuteUnmute.
  ///
  /// In en, this message translates to:
  /// **'Toggle Mute / Unmute'**
  String get musToggleMuteUnmute;

  /// No description provided for @musToggleQueueDrawer.
  ///
  /// In en, this message translates to:
  /// **'Toggle Queue Drawer'**
  String get musToggleQueueDrawer;

  /// No description provided for @musToggleFullscreenNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Toggle Fullscreen Now Playing'**
  String get musToggleFullscreenNowPlaying;

  /// No description provided for @musShowShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Show Shortcuts'**
  String get musShowShortcuts;

  /// No description provided for @musKeyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get musKeyboardShortcuts;

  /// No description provided for @musShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get musShuffle;

  /// No description provided for @musSearchOffline.
  ///
  /// In en, this message translates to:
  /// **'Search offline...'**
  String get musSearchOffline;

  /// No description provided for @musNoOfflineDownloadsYetTapThe.
  ///
  /// In en, this message translates to:
  /// **'No offline downloads yet.\nTap the download icon on any song, album, or playlist to listen offline.'**
  String get musNoOfflineDownloadsYetTapThe;

  /// No description provided for @musDeleteFromDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete from downloads'**
  String get musDeleteFromDownloads;

  /// No description provided for @musDeleteDownloadedSong.
  ///
  /// In en, this message translates to:
  /// **'Delete Downloaded Song'**
  String get musDeleteDownloadedSong;

  /// No description provided for @musDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get musDelete;

  /// No description provided for @tvLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get tvLiveBadge;

  /// No description provided for @tvCancelSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel Selection'**
  String get tvCancelSelection;

  /// No description provided for @tvManageDeleteChannels.
  ///
  /// In en, this message translates to:
  /// **'Manage / Delete Channels'**
  String get tvManageDeleteChannels;

  /// No description provided for @tvDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get tvDeselectAll;

  /// No description provided for @tvSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get tvSelectAll;

  /// No description provided for @tvStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get tvStop;

  /// No description provided for @tvScanningPortals.
  ///
  /// In en, this message translates to:
  /// **'Scanning all verified portals in parallel…'**
  String get tvScanningPortals;

  /// No description provided for @tvNoAliveStreams.
  ///
  /// In en, this message translates to:
  /// **'No alive streams discovered yet.'**
  String get tvNoAliveStreams;

  /// No description provided for @tvTapScanMoreHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Scan More Portals\" to discover fresh feeds.'**
  String get tvTapScanMoreHint;

  /// No description provided for @tvClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get tvClearSearch;

  /// No description provided for @tvFreeBadge.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get tvFreeBadge;

  /// No description provided for @tvWatchLive.
  ///
  /// In en, this message translates to:
  /// **'Watch Live'**
  String get tvWatchLive;

  /// No description provided for @tvScanMore.
  ///
  /// In en, this message translates to:
  /// **'Scan More'**
  String get tvScanMore;

  /// No description provided for @tvChannelListAndSchedule.
  ///
  /// In en, this message translates to:
  /// **'Channel list and programme schedule'**
  String get tvChannelListAndSchedule;

  /// No description provided for @tvDescPremier.
  ///
  /// In en, this message translates to:
  /// **'Top worldwide sporting events and championship channels'**
  String get tvDescPremier;

  /// No description provided for @tvDescBoxing.
  ///
  /// In en, this message translates to:
  /// **'Sky Sports Box Office, DAZN, TNT Sports Box Office & free combat channels'**
  String get tvDescBoxing;

  /// No description provided for @tvDescUs.
  ///
  /// In en, this message translates to:
  /// **'ABC News Live, CBS News 24/7, NBC News Now, Weather Channel & more'**
  String get tvDescUs;

  /// No description provided for @tvDescUk.
  ///
  /// In en, this message translates to:
  /// **'BBC One UK, ITV News, Sky News UK, Channel 4 & more'**
  String get tvDescUk;

  /// No description provided for @tvDescIntlSports.
  ///
  /// In en, this message translates to:
  /// **'Willow Cricket, Fox Soccer Plus, GolTV, TUDN, Viaplay & more'**
  String get tvDescIntlSports;

  /// No description provided for @tvManagePortalsPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Manage Portals & Playlists'**
  String get tvManagePortalsPlaylists;

  /// No description provided for @tvSearchChannels.
  ///
  /// In en, this message translates to:
  /// **'Search Channels'**
  String get tvSearchChannels;

  /// No description provided for @tvSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tvSettings;

  /// No description provided for @tvMultiStreamsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Multi Streams (Multi-View Window)'**
  String get tvMultiStreamsTooltip;

  /// No description provided for @tvMultiStreams.
  ///
  /// In en, this message translates to:
  /// **'Multi Streams'**
  String get tvMultiStreams;

  /// No description provided for @tvQuickChannels.
  ///
  /// In en, this message translates to:
  /// **'Quick Channels'**
  String get tvQuickChannels;

  /// No description provided for @tvAddQuickChannel.
  ///
  /// In en, this message translates to:
  /// **'Add Quick Channel'**
  String get tvAddQuickChannel;

  /// No description provided for @tvAddChannel.
  ///
  /// In en, this message translates to:
  /// **'Add Channel'**
  String get tvAddChannel;

  /// No description provided for @tvChannelName.
  ///
  /// In en, this message translates to:
  /// **'Channel Name'**
  String get tvChannelName;

  /// No description provided for @tvRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get tvRequired;

  /// No description provided for @tvShortCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Short Code (optional)'**
  String get tvShortCodeOptional;

  /// No description provided for @tvCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get tvCategory;

  /// No description provided for @tvKeywordsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Keywords (comma-separated)'**
  String get tvKeywordsCommaSeparated;

  /// No description provided for @tvKeywordsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. cnn, news, international'**
  String get tvKeywordsHint;

  /// No description provided for @tvGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get tvGradient;

  /// No description provided for @tvCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tvCancel;

  /// No description provided for @tvConnectingToStream.
  ///
  /// In en, this message translates to:
  /// **'Connecting to stream…'**
  String get tvConnectingToStream;

  /// No description provided for @tvChannelNoSources.
  ///
  /// In en, this message translates to:
  /// **'This channel has no stream sources.'**
  String get tvChannelNoSources;

  /// No description provided for @tvFeedWouldNotPlay.
  ///
  /// In en, this message translates to:
  /// **'This feed would not play.'**
  String get tvFeedWouldNotPlay;

  /// No description provided for @tvFeedStalled.
  ///
  /// In en, this message translates to:
  /// **'This feed stalled and would not keep playing.'**
  String get tvFeedStalled;

  /// No description provided for @tvAspectFitContain.
  ///
  /// In en, this message translates to:
  /// **'ASPECT: FIT (CONTAIN)'**
  String get tvAspectFitContain;

  /// No description provided for @tvAspectFillZoomCrop.
  ///
  /// In en, this message translates to:
  /// **'ASPECT: FILL (ZOOM / CROP)'**
  String get tvAspectFillZoomCrop;

  /// No description provided for @tvAspectStretchFill.
  ///
  /// In en, this message translates to:
  /// **'ASPECT: STRETCH (FILL)'**
  String get tvAspectStretchFill;

  /// No description provided for @tvReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get tvReconnecting;

  /// No description provided for @tvMuted.
  ///
  /// In en, this message translates to:
  /// **'MUTED'**
  String get tvMuted;

  /// No description provided for @tvPlayerLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get tvPlayerLive;

  /// No description provided for @tvPlayerVod.
  ///
  /// In en, this message translates to:
  /// **'VOD'**
  String get tvPlayerVod;

  /// No description provided for @tvCategoryChannels.
  ///
  /// In en, this message translates to:
  /// **'Category Channels'**
  String get tvCategoryChannels;

  /// No description provided for @tvAlternativeFeeds.
  ///
  /// In en, this message translates to:
  /// **'Alternative Feeds'**
  String get tvAlternativeFeeds;

  /// No description provided for @tvExitFullscreenF11.
  ///
  /// In en, this message translates to:
  /// **'Exit Fullscreen (F11)'**
  String get tvExitFullscreenF11;

  /// No description provided for @tvFullscreenF11.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen (F11)'**
  String get tvFullscreenF11;

  /// No description provided for @tvSeekBack10.
  ///
  /// In en, this message translates to:
  /// **'Seek -10s'**
  String get tvSeekBack10;

  /// No description provided for @tvSeekForward10.
  ///
  /// In en, this message translates to:
  /// **'Seek +10s'**
  String get tvSeekForward10;

  /// No description provided for @tvFitShort.
  ///
  /// In en, this message translates to:
  /// **'FIT'**
  String get tvFitShort;

  /// No description provided for @tvZoomShort.
  ///
  /// In en, this message translates to:
  /// **'ZOOM'**
  String get tvZoomShort;

  /// No description provided for @tvStretchShort.
  ///
  /// In en, this message translates to:
  /// **'STRETCH'**
  String get tvStretchShort;

  /// No description provided for @tvStreamFeeds.
  ///
  /// In en, this message translates to:
  /// **'Stream Feeds'**
  String get tvStreamFeeds;

  /// No description provided for @tvCustomizePortalsModal.
  ///
  /// In en, this message translates to:
  /// **'Customize Portals Modal'**
  String get tvCustomizePortalsModal;

  /// No description provided for @tvCardDisplayStyle.
  ///
  /// In en, this message translates to:
  /// **'Card Display Style'**
  String get tvCardDisplayStyle;

  /// No description provided for @tvShowPortalExpiry.
  ///
  /// In en, this message translates to:
  /// **'Show Portal Expiry Date'**
  String get tvShowPortalExpiry;

  /// No description provided for @tvShowMaxConnections.
  ///
  /// In en, this message translates to:
  /// **'Show Max Connections'**
  String get tvShowMaxConnections;

  /// No description provided for @tvDefaultStartingTab.
  ///
  /// In en, this message translates to:
  /// **'Default Starting Tab'**
  String get tvDefaultStartingTab;

  /// No description provided for @tvPortalsAndPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Portals & Playlists'**
  String get tvPortalsAndPlaylists;

  /// No description provided for @tvIptvPortalsAndPlaylists.
  ///
  /// In en, this message translates to:
  /// **'IPTV Portals & Playlists'**
  String get tvIptvPortalsAndPlaylists;

  /// No description provided for @tvCustomizeModalStyle.
  ///
  /// In en, this message translates to:
  /// **'Customize Modal Style'**
  String get tvCustomizeModalStyle;

  /// No description provided for @tvFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding…'**
  String get tvFinding;

  /// No description provided for @tvGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get tvGenerate;

  /// No description provided for @tvGeneratePortals.
  ///
  /// In en, this message translates to:
  /// **'Generate Portals'**
  String get tvGeneratePortals;

  /// No description provided for @tvChoosePortalSource.
  ///
  /// In en, this message translates to:
  /// **'Choose Portal Source'**
  String get tvChoosePortalSource;

  /// No description provided for @tvCloudVault.
  ///
  /// In en, this message translates to:
  /// **'Cloud Vault'**
  String get tvCloudVault;

  /// No description provided for @tvCloudVaultDesc.
  ///
  /// In en, this message translates to:
  /// **'High-speed cloud database with live IPTV servers'**
  String get tvCloudVaultDesc;

  /// No description provided for @tvRedditCommunities.
  ///
  /// In en, this message translates to:
  /// **'Reddit Communities'**
  String get tvRedditCommunities;

  /// No description provided for @tvRedditDesc.
  ///
  /// In en, this message translates to:
  /// **'Scrapes live shared pastes from subreddits'**
  String get tvRedditDesc;

  /// No description provided for @tvPortalsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tvPortalsAdd;

  /// No description provided for @tvAddPortal.
  ///
  /// In en, this message translates to:
  /// **'Add Portal'**
  String get tvAddPortal;

  /// No description provided for @tvDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tvDone;

  /// No description provided for @tvManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get tvManage;

  /// No description provided for @tvPortalsDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get tvPortalsDeselectAll;

  /// No description provided for @tvPortalsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get tvPortalsSelectAll;

  /// No description provided for @tvDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get tvDeleteAll;

  /// No description provided for @tvAddXtreamPortal.
  ///
  /// In en, this message translates to:
  /// **'Add Xtream Codes Portal'**
  String get tvAddXtreamPortal;

  /// No description provided for @tvUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get tvUsername;

  /// No description provided for @tvPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get tvPassword;

  /// No description provided for @tvShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show Password'**
  String get tvShowPassword;

  /// No description provided for @tvHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide Password'**
  String get tvHidePassword;

  /// No description provided for @tvCopyLogin.
  ///
  /// In en, this message translates to:
  /// **'Copy Login (url:user:pass)'**
  String get tvCopyLogin;

  /// No description provided for @tvRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove Favorite'**
  String get tvRemoveFavorite;

  /// No description provided for @tvAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get tvAddToFavorites;

  /// No description provided for @tvRemovePortal.
  ///
  /// In en, this message translates to:
  /// **'Remove Portal'**
  String get tvRemovePortal;

  /// No description provided for @tvAddM3u.
  ///
  /// In en, this message translates to:
  /// **'Add M3U'**
  String get tvAddM3u;

  /// No description provided for @tvAddM3uUrl.
  ///
  /// In en, this message translates to:
  /// **'Add M3U URL'**
  String get tvAddM3uUrl;

  /// No description provided for @tvAddM3uSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add M3U Playlist Subscription'**
  String get tvAddM3uSubscription;

  /// No description provided for @tvPlaylistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get tvPlaylistName;

  /// No description provided for @tvM3uUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'M3U / M3U8 URL'**
  String get tvM3uUrlLabel;

  /// No description provided for @tvNoM3uPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No M3U playlists saved.'**
  String get tvNoM3uPlaylists;

  /// No description provided for @tvCopyPlaylistUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy Playlist URL'**
  String get tvCopyPlaylistUrl;

  /// No description provided for @tvRemovePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove Playlist'**
  String get tvRemovePlaylist;

  /// No description provided for @tvIptvPortal.
  ///
  /// In en, this message translates to:
  /// **'IPTV Portal'**
  String get tvIptvPortal;

  /// No description provided for @tvCustomizePortalBrowser.
  ///
  /// In en, this message translates to:
  /// **'Customize Portal Browser'**
  String get tvCustomizePortalBrowser;

  /// No description provided for @tvChannelLayoutMode.
  ///
  /// In en, this message translates to:
  /// **'Channel Stream Layout Mode'**
  String get tvChannelLayoutMode;

  /// No description provided for @tvGridColumns.
  ///
  /// In en, this message translates to:
  /// **'Grid Stream Columns'**
  String get tvGridColumns;

  /// No description provided for @tvShowChannelLogos.
  ///
  /// In en, this message translates to:
  /// **'Show Channel Stream Logos'**
  String get tvShowChannelLogos;

  /// No description provided for @tvShowEpgNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Show EPG \"Now Playing\" Snippet'**
  String get tvShowEpgNowPlaying;

  /// No description provided for @tvShowCategoryCounts.
  ///
  /// In en, this message translates to:
  /// **'Show Category Stream Counts'**
  String get tvShowCategoryCounts;

  /// No description provided for @tvFavoritesStar.
  ///
  /// In en, this message translates to:
  /// **'⭐ Favorites'**
  String get tvFavoritesStar;

  /// No description provided for @tvLiveChannels.
  ///
  /// In en, this message translates to:
  /// **'Live Channels'**
  String get tvLiveChannels;

  /// No description provided for @tvMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get tvMovies;

  /// No description provided for @tvSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get tvSeries;

  /// No description provided for @tvBrowserLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get tvBrowserLive;

  /// No description provided for @tvBrowserVod.
  ///
  /// In en, this message translates to:
  /// **'VOD'**
  String get tvBrowserVod;

  /// No description provided for @tvBrowserSeriesBadge.
  ///
  /// In en, this message translates to:
  /// **'SERIES'**
  String get tvBrowserSeriesBadge;

  /// No description provided for @tvSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get tvSelectCategory;

  /// No description provided for @tvFilterCategories.
  ///
  /// In en, this message translates to:
  /// **'Filter categories…'**
  String get tvFilterCategories;

  /// No description provided for @tvBrowserBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tvBrowserBack;

  /// No description provided for @tvLiveTv.
  ///
  /// In en, this message translates to:
  /// **'Live TV'**
  String get tvLiveTv;

  /// No description provided for @tvTvSeries.
  ///
  /// In en, this message translates to:
  /// **'TV Series'**
  String get tvTvSeries;

  /// No description provided for @tvSearchChannelsHint.
  ///
  /// In en, this message translates to:
  /// **'Search channels…'**
  String get tvSearchChannelsHint;

  /// No description provided for @tvCheckHealth.
  ///
  /// In en, this message translates to:
  /// **'Check Health'**
  String get tvCheckHealth;

  /// No description provided for @tvCustomizeBrowserLayout.
  ///
  /// In en, this message translates to:
  /// **'Customize Portal Browser Layout'**
  String get tvCustomizeBrowserLayout;

  /// No description provided for @tvCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get tvCustomize;

  /// No description provided for @tvLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get tvLive;

  /// No description provided for @tvSearchInCategory.
  ///
  /// In en, this message translates to:
  /// **'Search in this category…'**
  String get tvSearchInCategory;

  /// No description provided for @tvCouldNotLoadPortal.
  ///
  /// In en, this message translates to:
  /// **'Could not load this portal'**
  String get tvCouldNotLoadPortal;

  /// No description provided for @tvNoFavoritedChannels.
  ///
  /// In en, this message translates to:
  /// **'No Favorited Channels'**
  String get tvNoFavoritedChannels;

  /// No description provided for @tvFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the star icon on any channel to save it to your Favorites.'**
  String get tvFavoritesHint;

  /// No description provided for @tvNoStreamsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No streams available in this category.'**
  String get tvNoStreamsInCategory;

  /// No description provided for @tvEpgNow.
  ///
  /// In en, this message translates to:
  /// **'NOW: '**
  String get tvEpgNow;

  /// No description provided for @tvEpgNext.
  ///
  /// In en, this message translates to:
  /// **'   NEXT: '**
  String get tvEpgNext;

  /// No description provided for @tvLiveStreamFeed.
  ///
  /// In en, this message translates to:
  /// **'Live Stream Feed'**
  String get tvLiveStreamFeed;

  /// No description provided for @tvRemoveFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get tvRemoveFromFavorites;

  /// No description provided for @tvBrowserAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get tvBrowserAddToFavorites;

  /// No description provided for @tvCouldNotLoadEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Could not load episodes'**
  String get tvCouldNotLoadEpisodes;

  /// No description provided for @tvSearchBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tvSearchBack;

  /// No description provided for @tvSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search 60+ live channels, leagues, networks…'**
  String get tvSearchHint;

  /// No description provided for @tvChannelCategories.
  ///
  /// In en, this message translates to:
  /// **'Channel categories'**
  String get tvChannelCategories;

  /// No description provided for @tvNoChannelsMatch.
  ///
  /// In en, this message translates to:
  /// **'No channels match your search.'**
  String get tvNoChannelsMatch;

  /// No description provided for @tvLiveBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Live broadcast'**
  String get tvLiveBroadcast;

  /// No description provided for @tvUpcomingOnChannel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming On This Channel'**
  String get tvUpcomingOnChannel;

  /// No description provided for @tvNothingElseListed.
  ///
  /// In en, this message translates to:
  /// **'Nothing else listed for this channel.'**
  String get tvNothingElseListed;

  /// No description provided for @tvNoProgrammeGuide.
  ///
  /// In en, this message translates to:
  /// **'No programme guide for this channel yet.'**
  String get tvNoProgrammeGuide;

  /// No description provided for @tvFindLiveStreams.
  ///
  /// In en, this message translates to:
  /// **'Find Live Streams'**
  String get tvFindLiveStreams;

  /// No description provided for @tvGuideLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get tvGuideLive;

  /// No description provided for @tvWatchLiveStream.
  ///
  /// In en, this message translates to:
  /// **'Watch Live Stream'**
  String get tvWatchLiveStream;

  /// No description provided for @tvScheduledProgramme.
  ///
  /// In en, this message translates to:
  /// **'Scheduled programme'**
  String get tvScheduledProgramme;

  /// No description provided for @aniPlayEp1Modal.
  ///
  /// In en, this message translates to:
  /// **'Play Ep 1'**
  String get aniPlayEp1Modal;

  /// No description provided for @aniJumpToEpModal.
  ///
  /// In en, this message translates to:
  /// **'Jump to ep #'**
  String get aniJumpToEpModal;

  /// No description provided for @aniPlayEp1.
  ///
  /// In en, this message translates to:
  /// **'Play Ep 1'**
  String get aniPlayEp1;

  /// No description provided for @aniJumpToEp.
  ///
  /// In en, this message translates to:
  /// **'Jump to ep #'**
  String get aniJumpToEp;

  /// No description provided for @aniGeneralTab.
  ///
  /// In en, this message translates to:
  /// **'🇯🇵 General'**
  String get aniGeneralTab;

  /// No description provided for @aniArabicAnimeTab.
  ///
  /// In en, this message translates to:
  /// **'🇸🇦 Arabic Anime'**
  String get aniArabicAnimeTab;

  /// No description provided for @aniSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get aniSettings;

  /// No description provided for @aniWatchS1E1.
  ///
  /// In en, this message translates to:
  /// **'Watch S1:E1'**
  String get aniWatchS1E1;

  /// No description provided for @aniArabicToggle.
  ///
  /// In en, this message translates to:
  /// **'🇸🇦 Arabic'**
  String get aniArabicToggle;

  /// No description provided for @aniAnimeToggle.
  ///
  /// In en, this message translates to:
  /// **'🇯🇵 Anime'**
  String get aniAnimeToggle;

  /// No description provided for @aniOvasOnasSpecials.
  ///
  /// In en, this message translates to:
  /// **'OVAs, ONAs & Specials'**
  String get aniOvasOnasSpecials;

  /// No description provided for @aniTrendingAnime.
  ///
  /// In en, this message translates to:
  /// **'Trending Anime'**
  String get aniTrendingAnime;

  /// No description provided for @aniPopularThisSeason.
  ///
  /// In en, this message translates to:
  /// **'Popular This Season'**
  String get aniPopularThisSeason;

  /// No description provided for @aniAllTimeTopRated.
  ///
  /// In en, this message translates to:
  /// **'All-Time Top Rated'**
  String get aniAllTimeTopRated;

  /// No description provided for @aniCascadingExtractors.
  ///
  /// In en, this message translates to:
  /// **'Cascading native anime extractors…'**
  String get aniCascadingExtractors;

  /// No description provided for @aniSubtitleOrDub.
  ///
  /// In en, this message translates to:
  /// **'Subtitle or dub'**
  String get aniSubtitleOrDub;

  /// No description provided for @aniStreamAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get aniStreamAll;

  /// No description provided for @aniSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get aniSources;

  /// No description provided for @aniExtractingStreams.
  ///
  /// In en, this message translates to:
  /// **'Extracting MegaPlay, VidWish, AllAnime & Miruro streams...'**
  String get aniExtractingStreams;

  /// No description provided for @aniRetryScraping.
  ///
  /// In en, this message translates to:
  /// **'Retry Scraping'**
  String get aniRetryScraping;

  /// No description provided for @aniStreamSource.
  ///
  /// In en, this message translates to:
  /// **'Stream Source'**
  String get aniStreamSource;

  /// No description provided for @aniStreamDubBadge.
  ///
  /// In en, this message translates to:
  /// **'DUB'**
  String get aniStreamDubBadge;

  /// No description provided for @aniStreamSubBadge.
  ///
  /// In en, this message translates to:
  /// **'SUB'**
  String get aniStreamSubBadge;

  /// No description provided for @aiAnalyzingStorylines.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your favorite storylines & themes...'**
  String get aiAnalyzingStorylines;

  /// No description provided for @aiStudyingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Studying your storytelling and mood preferences...'**
  String get aiStudyingPreferences;

  /// No description provided for @aiFindingMatches.
  ///
  /// In en, this message translates to:
  /// **'Finding high-precision cinema matches...'**
  String get aiFindingMatches;

  /// No description provided for @aiPolishingRecs.
  ///
  /// In en, this message translates to:
  /// **'Polishing your personalized recommendations...'**
  String get aiPolishingRecs;

  /// No description provided for @aiBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get aiBack;

  /// No description provided for @aiRecommendationQuiz.
  ///
  /// In en, this message translates to:
  /// **'Recommendation Quiz'**
  String get aiRecommendationQuiz;

  /// No description provided for @aiRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get aiRetake;

  /// No description provided for @aiWhatDoYouLike.
  ///
  /// In en, this message translates to:
  /// **'What do you like to watch?'**
  String get aiWhatDoYouLike;

  /// No description provided for @aiQuizIntro.
  ///
  /// In en, this message translates to:
  /// **'Rate 3 or more movies or TV shows. Choose what you liked or disliked, and select key elements to generate pinpoint AI recommendations.'**
  String get aiQuizIntro;

  /// No description provided for @aiAddAnotherTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Another Title'**
  String get aiAddAnotherTitle;

  /// No description provided for @aiRate3ToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Rate 3 Titles to Unlock Recommendations'**
  String get aiRate3ToUnlock;

  /// No description provided for @aiRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this title'**
  String get aiRemoveTitle;

  /// No description provided for @aiSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search movie or TV series...'**
  String get aiSearchHint;

  /// No description provided for @aiNeedIdeas.
  ///
  /// In en, this message translates to:
  /// **'Need ideas?'**
  String get aiNeedIdeas;

  /// No description provided for @aiHowWasExperience.
  ///
  /// In en, this message translates to:
  /// **'How was your experience with it?'**
  String get aiHowWasExperience;

  /// No description provided for @aiLovedIt.
  ///
  /// In en, this message translates to:
  /// **'Loved it ❤️'**
  String get aiLovedIt;

  /// No description provided for @aiLikedIt.
  ///
  /// In en, this message translates to:
  /// **'Liked it 👍'**
  String get aiLikedIt;

  /// No description provided for @aiItWasOkay.
  ///
  /// In en, this message translates to:
  /// **'It was okay 😐'**
  String get aiItWasOkay;

  /// No description provided for @aiDisliked.
  ///
  /// In en, this message translates to:
  /// **'Disliked 👎'**
  String get aiDisliked;

  /// No description provided for @aiWhatStoodOut.
  ///
  /// In en, this message translates to:
  /// **'What stood out? (Pick key elements or write a note):'**
  String get aiWhatStoodOut;

  /// No description provided for @aiFetchingTags.
  ///
  /// In en, this message translates to:
  /// **'Fetching reason tags...'**
  String get aiFetchingTags;

  /// No description provided for @aiNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional notes or specifics (optional)...'**
  String get aiNotesHint;

  /// No description provided for @aiSynthesizing.
  ///
  /// In en, this message translates to:
  /// **'Synthesizing taste vectors with multi-signal AI...'**
  String get aiSynthesizing;

  /// No description provided for @aiYourMatches.
  ///
  /// In en, this message translates to:
  /// **'Your Personalized Matches'**
  String get aiYourMatches;

  /// No description provided for @plyMedia3EngineError.
  ///
  /// In en, this message translates to:
  /// **'Playback error on the Media3 engine'**
  String get plyMedia3EngineError;

  /// No description provided for @plyRefusedByProvider.
  ///
  /// In en, this message translates to:
  /// **'Refused by provider'**
  String get plyRefusedByProvider;

  /// No description provided for @plyNoticeRefused.
  ///
  /// In en, this message translates to:
  /// **'refused this source'**
  String get plyNoticeRefused;

  /// No description provided for @plyNotReadyYet.
  ///
  /// In en, this message translates to:
  /// **'Not ready yet'**
  String get plyNotReadyYet;

  /// No description provided for @plyNoticeNotReady.
  ///
  /// In en, this message translates to:
  /// **'does not have this source ready yet'**
  String get plyNoticeNotReady;

  /// No description provided for @plyAccountRejected.
  ///
  /// In en, this message translates to:
  /// **'Account rejected'**
  String get plyAccountRejected;

  /// No description provided for @plyNoticeAccountRejected.
  ///
  /// In en, this message translates to:
  /// **'rejected the account'**
  String get plyNoticeAccountRejected;

  /// No description provided for @plyTemporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable'**
  String get plyTemporarilyUnavailable;

  /// No description provided for @plyNoticeCouldNotServe.
  ///
  /// In en, this message translates to:
  /// **'could not serve this source'**
  String get plyNoticeCouldNotServe;

  /// No description provided for @plyWaitingForData.
  ///
  /// In en, this message translates to:
  /// **'⏳ Waiting for this source to deliver data'**
  String get plyWaitingForData;

  /// No description provided for @plyBlackScreenSoftware.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Black screen detected • Switched to Software Mode'**
  String get plyBlackScreenSoftware;

  /// No description provided for @plyDecoderResynced.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Decoder failed at this resolution • Hardware decoding re-synced'**
  String get plyDecoderResynced;

  /// No description provided for @plyMaxBoost.
  ///
  /// In en, this message translates to:
  /// **'MAX BOOST'**
  String get plyMaxBoost;

  /// No description provided for @plyBoost.
  ///
  /// In en, this message translates to:
  /// **'BOOST'**
  String get plyBoost;

  /// No description provided for @ply2xSpeed.
  ///
  /// In en, this message translates to:
  /// **'2X Speed'**
  String get ply2xSpeed;

  /// No description provided for @plyAspectFillCrop.
  ///
  /// In en, this message translates to:
  /// **'ASPECT: FILL / CROP (ZOOM)'**
  String get plyAspectFillCrop;

  /// No description provided for @plyAspectStretch.
  ///
  /// In en, this message translates to:
  /// **'ASPECT: STRETCH TO FILL'**
  String get plyAspectStretch;

  /// No description provided for @plyAspectFit.
  ///
  /// In en, this message translates to:
  /// **'ASPECT: FIT TO SCREEN'**
  String get plyAspectFit;

  /// No description provided for @plyDirector.
  ///
  /// In en, this message translates to:
  /// **'DIRECTOR'**
  String get plyDirector;

  /// No description provided for @plyDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get plyDismiss;

  /// No description provided for @plyAudioDubLanguage.
  ///
  /// In en, this message translates to:
  /// **'Audio & Dub Language'**
  String get plyAudioDubLanguage;

  /// No description provided for @plyUnknownSource.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get plyUnknownSource;

  /// No description provided for @mnzRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get mnzRestoring;

  /// No description provided for @mnzPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Playback error'**
  String get mnzPlaybackError;

  /// No description provided for @mnzSwitchingFeed.
  ///
  /// In en, this message translates to:
  /// **'Switching feed...'**
  String get mnzSwitchingFeed;

  /// No description provided for @mnzSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Switch failed'**
  String get mnzSwitchFailed;

  /// No description provided for @mnzCustomStream.
  ///
  /// In en, this message translates to:
  /// **'Custom Stream'**
  String get mnzCustomStream;

  /// No description provided for @mnzConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get mnzConnecting;

  /// No description provided for @mnzSelectChannel.
  ///
  /// In en, this message translates to:
  /// **'Select Channel'**
  String get mnzSelectChannel;

  /// No description provided for @mnzStreamDetails.
  ///
  /// In en, this message translates to:
  /// **'Stream Details'**
  String get mnzStreamDetails;

  /// No description provided for @mnzStreamName.
  ///
  /// In en, this message translates to:
  /// **'Stream Name'**
  String get mnzStreamName;

  /// No description provided for @mnzLiveStream.
  ///
  /// In en, this message translates to:
  /// **'Live Stream'**
  String get mnzLiveStream;

  /// No description provided for @mnzDiscoveringStream.
  ///
  /// In en, this message translates to:
  /// **'Discovering stream...'**
  String get mnzDiscoveringStream;

  /// No description provided for @mnzNoActiveFeeds.
  ///
  /// In en, this message translates to:
  /// **'No active feeds found'**
  String get mnzNoActiveFeeds;

  /// No description provided for @mnzConnectingToFeed.
  ///
  /// In en, this message translates to:
  /// **'Connecting to feed...'**
  String get mnzConnectingToFeed;

  /// No description provided for @mnzFailedToLoadFeed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feed'**
  String get mnzFailedToLoadFeed;

  /// No description provided for @mnzCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mnzCancel;

  /// No description provided for @mnzAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mnzAdd;

  /// No description provided for @mnzAddLiveFeed.
  ///
  /// In en, this message translates to:
  /// **'Add Live Stream Feed'**
  String get mnzAddLiveFeed;

  /// No description provided for @mnzBackToLiveTv.
  ///
  /// In en, this message translates to:
  /// **'Back to Live TV'**
  String get mnzBackToLiveTv;

  /// No description provided for @mnzMultiStreams.
  ///
  /// In en, this message translates to:
  /// **'MULTI STREAMS'**
  String get mnzMultiStreams;

  /// No description provided for @mnzPreviousLayout.
  ///
  /// In en, this message translates to:
  /// **'Previous Layout'**
  String get mnzPreviousLayout;

  /// No description provided for @mnzNextLayout.
  ///
  /// In en, this message translates to:
  /// **'Next Layout'**
  String get mnzNextLayout;

  /// No description provided for @mnzDoneRearranging.
  ///
  /// In en, this message translates to:
  /// **'Done Rearranging'**
  String get mnzDoneRearranging;

  /// No description provided for @mnzRearrangeStreams.
  ///
  /// In en, this message translates to:
  /// **'Rearrange Streams'**
  String get mnzRearrangeStreams;

  /// No description provided for @mnzMuteAll.
  ///
  /// In en, this message translates to:
  /// **'Mute All'**
  String get mnzMuteAll;

  /// No description provided for @mnzClearAllWindows.
  ///
  /// In en, this message translates to:
  /// **'Clear All Windows'**
  String get mnzClearAllWindows;

  /// No description provided for @dscCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get dscCustom;

  /// No description provided for @dscNoAdultSources.
  ///
  /// In en, this message translates to:
  /// **'No 18+ sources yet.\nMark an addon as 18+ in Settings → Addons, or install one.'**
  String get dscNoAdultSources;

  /// No description provided for @dscNoTitlesInCatalog.
  ///
  /// In en, this message translates to:
  /// **'No titles found in this catalog'**
  String get dscNoTitlesInCatalog;

  /// No description provided for @dscSelectRequiredFilter.
  ///
  /// In en, this message translates to:
  /// **'Select Required Filter'**
  String get dscSelectRequiredFilter;

  /// No description provided for @dscCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dscCancel;

  /// No description provided for @dscDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get dscDiscover;

  /// No description provided for @dscSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get dscSearchHint;

  /// No description provided for @dscSearchCatalog.
  ///
  /// In en, this message translates to:
  /// **'Search catalog'**
  String get dscSearchCatalog;

  /// No description provided for @colFranchises.
  ///
  /// In en, this message translates to:
  /// **'Franchises'**
  String get colFranchises;

  /// No description provided for @colMemoryLane.
  ///
  /// In en, this message translates to:
  /// **'Memory Lane'**
  String get colMemoryLane;

  /// No description provided for @colCuratedTitle.
  ///
  /// In en, this message translates to:
  /// **'Curated Franchises & Eras'**
  String get colCuratedTitle;

  /// No description provided for @colCuratedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hand-picked film packs, in watch order.'**
  String get colCuratedSubtitle;

  /// No description provided for @colBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get colBack;

  /// No description provided for @calBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get calBack;

  /// No description provided for @calTitle.
  ///
  /// In en, this message translates to:
  /// **'TV Shows Airing Calendar'**
  String get calTitle;

  /// No description provided for @calSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming broadcast & streaming episodes with live network filters'**
  String get calSubtitle;

  /// No description provided for @calFilterShows.
  ///
  /// In en, this message translates to:
  /// **'Filter shows...'**
  String get calFilterShows;

  /// No description provided for @calToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get calToday;

  /// No description provided for @calTomorrow.
  ///
  /// In en, this message translates to:
  /// **'TOMORROW'**
  String get calTomorrow;

  /// No description provided for @calNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network:'**
  String get calNetwork;

  /// No description provided for @calNoEpisodesThisDay.
  ///
  /// In en, this message translates to:
  /// **'No episodes found for this day'**
  String get calNoEpisodesThisDay;

  /// No description provided for @calTryAllNetworks.
  ///
  /// In en, this message translates to:
  /// **'Try selecting \"All\" or a different network above'**
  String get calTryAllNetworks;

  /// No description provided for @calSelectAnotherDay.
  ///
  /// In en, this message translates to:
  /// **'Select another day from the timeline above'**
  String get calSelectAnotherDay;

  /// No description provided for @hmCinemaUniverse.
  ///
  /// In en, this message translates to:
  /// **'Your Cinema Universe'**
  String get hmCinemaUniverse;

  /// No description provided for @hmAiTasteQuiz.
  ///
  /// In en, this message translates to:
  /// **'AI Taste Quiz'**
  String get hmAiTasteQuiz;

  /// No description provided for @hmTvAiringCalendar.
  ///
  /// In en, this message translates to:
  /// **'TV Airing Calendar'**
  String get hmTvAiringCalendar;

  /// No description provided for @ctlNoItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get ctlNoItemsFound;

  /// No description provided for @ctlSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get ctlSearchHint;

  /// No description provided for @ctlAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ctlAll;

  /// No description provided for @araResolvingServers.
  ///
  /// In en, this message translates to:
  /// **'Resolving servers…'**
  String get araResolvingServers;

  /// No description provided for @araCrackingServerMap.
  ///
  /// In en, this message translates to:
  /// **'Cracking Arabic server map…'**
  String get araCrackingServerMap;

  /// No description provided for @stgaAddStremioAddon.
  ///
  /// In en, this message translates to:
  /// **'Add Stremio Addon'**
  String get stgaAddStremioAddon;

  /// No description provided for @stgaPasteStremioManifestHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the Stremio addon manifest.json URL to install catalogs, metadata, streams, or subtitles.'**
  String get stgaPasteStremioManifestHint;

  /// No description provided for @stgaCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get stgaCancel;

  /// No description provided for @stgaInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get stgaInstall;

  /// No description provided for @stgaRemoveAddonBody.
  ///
  /// In en, this message translates to:
  /// **'Its catalogs and metadata will be removed from your home page.'**
  String get stgaRemoveAddonBody;

  /// No description provided for @stgaRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get stgaRemove;

  /// No description provided for @stgaInstallRepoPluginsBody.
  ///
  /// In en, this message translates to:
  /// **'Would you like to install all plugins from this repository now so their streaming sources become available immediately on the watch screen?'**
  String get stgaInstallRepoPluginsBody;

  /// No description provided for @stgaBrowseLater.
  ///
  /// In en, this message translates to:
  /// **'Browse Later'**
  String get stgaBrowseLater;

  /// No description provided for @stgaInstallAllNow.
  ///
  /// In en, this message translates to:
  /// **'Install All Now'**
  String get stgaInstallAllNow;

  /// No description provided for @stgaInstallingPlugins.
  ///
  /// In en, this message translates to:
  /// **'Installing Plugins'**
  String get stgaInstallingPlugins;

  /// No description provided for @stgaPreparingRuntime.
  ///
  /// In en, this message translates to:
  /// **'Preparing runtime...'**
  String get stgaPreparingRuntime;

  /// No description provided for @stgaAddCloudStreamRepo.
  ///
  /// In en, this message translates to:
  /// **'Add CloudStream Repository'**
  String get stgaAddCloudStreamRepo;

  /// No description provided for @stgaPasteRepoUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the repository URL (supports cloudstreamrepo://, repo.json, or plugins.json).'**
  String get stgaPasteRepoUrlHint;

  /// No description provided for @stgaBrowseMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Browse Marketplace'**
  String get stgaBrowseMarketplace;

  /// No description provided for @stgaAddRepository.
  ///
  /// In en, this message translates to:
  /// **'Add Repository'**
  String get stgaAddRepository;

  /// No description provided for @stgaCsExtensionWillUninstall.
  ///
  /// In en, this message translates to:
  /// **'This CloudStream extension will be uninstalled.'**
  String get stgaCsExtensionWillUninstall;

  /// No description provided for @stgaRemoveRepoBody.
  ///
  /// In en, this message translates to:
  /// **'Plugins from this repository will not be deleted, but repository updates will no longer be fetched.'**
  String get stgaRemoveRepoBody;

  /// No description provided for @stgaStremioAddons.
  ///
  /// In en, this message translates to:
  /// **'Stremio Addons'**
  String get stgaStremioAddons;

  /// No description provided for @stgaStremioTabDescription.
  ///
  /// In en, this message translates to:
  /// **'Addons provide metadata, catalogs, and streaming sources. Hold and drag to reorder priority. Providers higher up load and appear first in watch sources.'**
  String get stgaStremioTabDescription;

  /// No description provided for @stgaInstalledProvidersAddons.
  ///
  /// In en, this message translates to:
  /// **'INSTALLED PROVIDERS & ADDONS'**
  String get stgaInstalledProvidersAddons;

  /// No description provided for @stgaNoAddonsInstalled.
  ///
  /// In en, this message translates to:
  /// **'No Addons Installed'**
  String get stgaNoAddonsInstalled;

  /// No description provided for @stgaNoAddonsHint.
  ///
  /// In en, this message translates to:
  /// **'Click \"Add Addon\" above to install a Stremio manifest URL.'**
  String get stgaNoAddonsHint;

  /// No description provided for @stgaDebridAddons.
  ///
  /// In en, this message translates to:
  /// **'DEBRID ADDONS'**
  String get stgaDebridAddons;

  /// No description provided for @stgaDebridAddonsDescription.
  ///
  /// In en, this message translates to:
  /// **'Installs the addon for the Debrid provider selected in Settings and fills your saved key in at request time, so the key is never stored twice.'**
  String get stgaDebridAddonsDescription;

  /// No description provided for @stgaDebridAddonsPlaceholderNote.
  ///
  /// In en, this message translates to:
  /// **'Addons that take the key as a plain URL parameter accept a {realdebrid} style placeholder. Addons that hide it inside a base64 config blob have to be pasted fully configured instead.'**
  String stgaDebridAddonsPlaceholderNote(String realdebrid);

  /// No description provided for @stgaCloudStreamTabDescription.
  ///
  /// In en, this message translates to:
  /// **'CloudStream (.cs3) extensions provide stream providers directly from popular media sites. Extensions run locally in a sandboxed sidecar or native ART engine.'**
  String get stgaCloudStreamTabDescription;

  /// No description provided for @stgaCsEngineReady.
  ///
  /// In en, this message translates to:
  /// **'CloudStream Engine Ready'**
  String get stgaCsEngineReady;

  /// No description provided for @stgaRuntimeSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Runtime Setup Required'**
  String get stgaRuntimeSetupRequired;

  /// No description provided for @stgaNativeEngineActive.
  ///
  /// In en, this message translates to:
  /// **'Native engine active and listening for queries.'**
  String get stgaNativeEngineActive;

  /// No description provided for @stgaDownloadingRuntime.
  ///
  /// In en, this message translates to:
  /// **'Downloading runtime components...'**
  String get stgaDownloadingRuntime;

  /// No description provided for @stgaRequiresRuntimeHost.
  ///
  /// In en, this message translates to:
  /// **'Requires runtime host to execute .cs3 bytecode.'**
  String get stgaRequiresRuntimeHost;

  /// No description provided for @stgaRequiresSidecarRuntime.
  ///
  /// In en, this message translates to:
  /// **'Requires sidecar runtime to execute .cs3 bytecode.'**
  String get stgaRequiresSidecarRuntime;

  /// No description provided for @stgaRepoMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Repository Marketplace'**
  String get stgaRepoMarketplace;

  /// No description provided for @stga45PlusRepos.
  ///
  /// In en, this message translates to:
  /// **'45+ Repos'**
  String get stga45PlusRepos;

  /// No description provided for @stgaRepoMarketplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse curated Turkish, 3rabi, English, Hindi & global repos with direct install links.'**
  String get stgaRepoMarketplaceDescription;

  /// No description provided for @stgaBrowseAvailablePlugins.
  ///
  /// In en, this message translates to:
  /// **'Browse Available Plugins'**
  String get stgaBrowseAvailablePlugins;

  /// No description provided for @stgaDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get stgaDeselectAll;

  /// No description provided for @stgaSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get stgaSelectAll;

  /// No description provided for @stgaInstalledExtensions.
  ///
  /// In en, this message translates to:
  /// **'INSTALLED EXTENSIONS'**
  String get stgaInstalledExtensions;

  /// No description provided for @stgaInstalledCsExtensions.
  ///
  /// In en, this message translates to:
  /// **'INSTALLED CLOUDSTREAM EXTENSIONS'**
  String get stgaInstalledCsExtensions;

  /// No description provided for @stgaNoExtensionsInstalled.
  ///
  /// In en, this message translates to:
  /// **'No Extensions Installed'**
  String get stgaNoExtensionsInstalled;

  /// No description provided for @stgaNoExtensionsHint.
  ///
  /// In en, this message translates to:
  /// **'Click \"Browse Available Plugins\" to find and install extensions.'**
  String get stgaNoExtensionsHint;

  /// No description provided for @stgaRepositories.
  ///
  /// In en, this message translates to:
  /// **'REPOSITORIES'**
  String get stgaRepositories;

  /// No description provided for @stgaNoReposHint.
  ///
  /// In en, this message translates to:
  /// **'No custom repositories added. Click \"Add Repository\" to subscribe to a CloudStream repository.'**
  String get stgaNoReposHint;

  /// No description provided for @stgaInstallAllFromRepoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Install all plugins from this repository'**
  String get stgaInstallAllFromRepoTooltip;

  /// No description provided for @stgaBrowseRepoPlugins.
  ///
  /// In en, this message translates to:
  /// **'Browse repository plugins'**
  String get stgaBrowseRepoPlugins;

  /// No description provided for @stgaRemoveRepository.
  ///
  /// In en, this message translates to:
  /// **'Remove repository'**
  String get stgaRemoveRepository;

  /// No description provided for @stgaSetupEngine.
  ///
  /// In en, this message translates to:
  /// **'Setup Engine'**
  String get stgaSetupEngine;

  /// No description provided for @stgaBuiltinTorrServer.
  ///
  /// In en, this message translates to:
  /// **'Built-in TorrServer P2P streaming engine'**
  String get stgaBuiltinTorrServer;

  /// No description provided for @stgaBuiltinHttpScrapers.
  ///
  /// In en, this message translates to:
  /// **'Built-in multi-source fast HTTP scrapers'**
  String get stgaBuiltinHttpScrapers;

  /// No description provided for @stgaMoveUpPriority.
  ///
  /// In en, this message translates to:
  /// **'Move up in priority'**
  String get stgaMoveUpPriority;

  /// No description provided for @stgaMoveDownPriority.
  ///
  /// In en, this message translates to:
  /// **'Move down in priority'**
  String get stgaMoveDownPriority;

  /// No description provided for @stgaBuiltinTorrent.
  ///
  /// In en, this message translates to:
  /// **'BUILT-IN TORRENT'**
  String get stgaBuiltinTorrent;

  /// No description provided for @stgaBuiltinHttp.
  ///
  /// In en, this message translates to:
  /// **'BUILT-IN HTTP'**
  String get stgaBuiltinHttp;

  /// No description provided for @stgaRemoveAddon.
  ///
  /// In en, this message translates to:
  /// **'Remove addon'**
  String get stgaRemoveAddon;

  /// No description provided for @stgaFunctions.
  ///
  /// In en, this message translates to:
  /// **'FUNCTIONS'**
  String get stgaFunctions;

  /// No description provided for @stgaCatalogs.
  ///
  /// In en, this message translates to:
  /// **'Catalogs'**
  String get stgaCatalogs;

  /// No description provided for @stgaSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get stgaSearch;

  /// No description provided for @stgaSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get stgaSources;

  /// No description provided for @stgaSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get stgaSubtitles;

  /// No description provided for @stgaInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get stgaInstalling;

  /// No description provided for @stgaAddAddon.
  ///
  /// In en, this message translates to:
  /// **'Add Addon'**
  String get stgaAddAddon;

  /// No description provided for @stgaConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get stgaConnecting;

  /// No description provided for @stgaConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get stgaConnect;

  /// No description provided for @stgaDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get stgaDisconnect;

  /// No description provided for @stgaConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get stgaConnected;

  /// No description provided for @stgaNoDebridProviderYet.
  ///
  /// In en, this message translates to:
  /// **'No Debrid provider is set up yet'**
  String get stgaNoDebridProviderYet;

  /// No description provided for @stgaSetupDebridFirst.
  ///
  /// In en, this message translates to:
  /// **'Set up a Debrid provider in Settings first, then come back to connect it.'**
  String get stgaSetupDebridFirst;

  /// No description provided for @stgaCsDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'CloudStream scraping & streaming provider'**
  String get stgaCsDefaultDescription;

  /// No description provided for @stgaAvailablePlugins.
  ///
  /// In en, this message translates to:
  /// **'Available Plugins'**
  String get stgaAvailablePlugins;

  /// No description provided for @stgaAvailableCsPlugins.
  ///
  /// In en, this message translates to:
  /// **'Available CloudStream Plugins'**
  String get stgaAvailableCsPlugins;

  /// No description provided for @stgaSearchPluginsHint.
  ///
  /// In en, this message translates to:
  /// **'Search plugins (e.g. Sflix, SuperStream)...'**
  String get stgaSearchPluginsHint;

  /// No description provided for @stgaNoPluginsInRepos.
  ///
  /// In en, this message translates to:
  /// **'No plugins found in added repositories.\nPlease add a CloudStream repository URL first.'**
  String get stgaNoPluginsInRepos;

  /// No description provided for @stgaInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get stgaInstalled;

  /// No description provided for @stgaUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get stgaUninstall;

  /// No description provided for @stgaInstallRepoPluginsNowQ.
  ///
  /// In en, this message translates to:
  /// **'Would you like to install plugins from this repository now?'**
  String get stgaInstallRepoPluginsNowQ;

  /// No description provided for @stgaLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get stgaLater;

  /// No description provided for @stgaInstallingRepoPlugins.
  ///
  /// In en, this message translates to:
  /// **'Installing Repository Plugins'**
  String get stgaInstallingRepoPlugins;

  /// No description provided for @stgaInstallingExtensions.
  ///
  /// In en, this message translates to:
  /// **'Installing extensions...'**
  String get stgaInstallingExtensions;

  /// No description provided for @stgaMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get stgaMarketplace;

  /// No description provided for @stgaRefreshListFromWeb.
  ///
  /// In en, this message translates to:
  /// **'Refresh list from web'**
  String get stgaRefreshListFromWeb;

  /// No description provided for @stgaSearchRepoOrPluginHint.
  ///
  /// In en, this message translates to:
  /// **'Search repository or plugin (e.g. Turkish, 3rabi, DiziBox, Shahid)...'**
  String get stgaSearchRepoOrPluginHint;

  /// No description provided for @stgaAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get stgaAdded;

  /// No description provided for @stgaAddingRepository.
  ///
  /// In en, this message translates to:
  /// **'Adding Repository...'**
  String get stgaAddingRepository;

  /// No description provided for @stgaInstallRepository.
  ///
  /// In en, this message translates to:
  /// **'Install Repository'**
  String get stgaInstallRepository;

  /// No description provided for @stgaInstallAllPlugins.
  ///
  /// In en, this message translates to:
  /// **'Install All Plugins'**
  String get stgaInstallAllPlugins;

  /// No description provided for @stgaBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get stgaBrowse;

  /// No description provided for @stgaHidePlugins.
  ///
  /// In en, this message translates to:
  /// **'Hide plugins'**
  String get stgaHidePlugins;

  /// No description provided for @stgaPastedKeyFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Pasted key from clipboard'**
  String get stgaPastedKeyFromClipboard;

  /// No description provided for @stgaDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get stgaDismiss;

  /// No description provided for @stgaDebridPageDescription.
  ///
  /// In en, this message translates to:
  /// **'Stream torrents and magnet links instantly through high-speed cloud debrid providers without local peer-to-peer downloading.'**
  String get stgaDebridPageDescription;

  /// No description provided for @stgaUseDebridForStreams.
  ///
  /// In en, this message translates to:
  /// **'Use Debrid for Streams'**
  String get stgaUseDebridForStreams;

  /// No description provided for @stgaRouteTorrentsThroughCloud.
  ///
  /// In en, this message translates to:
  /// **'Route torrent links through cloud servers'**
  String get stgaRouteTorrentsThroughCloud;

  /// No description provided for @stgaSelectDebridAndSaveKey.
  ///
  /// In en, this message translates to:
  /// **'Select an active Debrid provider and save your API key below.'**
  String get stgaSelectDebridAndSaveKey;

  /// No description provided for @stgaDebridDisabledLocal.
  ///
  /// In en, this message translates to:
  /// **'Debrid streaming disabled. Using local engine.'**
  String get stgaDebridDisabledLocal;

  /// No description provided for @stgaDebridToggleNote.
  ///
  /// In en, this message translates to:
  /// **'When enabled, all torrents from Lumora and Stremio addons are resolved exclusively through your active Debrid provider without touching the local torrent engine.'**
  String get stgaDebridToggleNote;

  /// No description provided for @stgaActiveProvider.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE PROVIDER'**
  String get stgaActiveProvider;

  /// No description provided for @stgaSelectDefaultDebrid.
  ///
  /// In en, this message translates to:
  /// **'Select Default Debrid Provider'**
  String get stgaSelectDefaultDebrid;

  /// No description provided for @stgaDebridProviderNote.
  ///
  /// In en, this message translates to:
  /// **'Lumora will send requests to this provider when streaming.'**
  String get stgaDebridProviderNote;

  /// No description provided for @stgaProviderCredentials.
  ///
  /// In en, this message translates to:
  /// **'PROVIDER CREDENTIALS'**
  String get stgaProviderCredentials;

  /// No description provided for @stgaGetTokenRealDebrid.
  ///
  /// In en, this message translates to:
  /// **'Get token from real-debrid.com/apitoken'**
  String get stgaGetTokenRealDebrid;

  /// No description provided for @stgaGetKeyTorBox.
  ///
  /// In en, this message translates to:
  /// **'Get key from torbox.app/settings'**
  String get stgaGetKeyTorBox;

  /// No description provided for @stgaGetKeyAllDebrid.
  ///
  /// In en, this message translates to:
  /// **'Get key from alldebrid.com/apikeys'**
  String get stgaGetKeyAllDebrid;

  /// No description provided for @stgaAccountConnected.
  ///
  /// In en, this message translates to:
  /// **'Account: Connected'**
  String get stgaAccountConnected;

  /// No description provided for @stgaGetKeyPremiumize.
  ///
  /// In en, this message translates to:
  /// **'Get key from premiumize.me/account'**
  String get stgaGetKeyPremiumize;

  /// No description provided for @stgaGetKeyDebridLink.
  ///
  /// In en, this message translates to:
  /// **'Get key from debrid-link.com/webapp/apikey'**
  String get stgaGetKeyDebridLink;

  /// No description provided for @stgaActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get stgaActiveBadge;

  /// No description provided for @stgaPasteApiKeyToken.
  ///
  /// In en, this message translates to:
  /// **'Paste API Key / Token'**
  String get stgaPasteApiKeyToken;

  /// No description provided for @stgaClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get stgaClear;

  /// No description provided for @stgaShowKey.
  ///
  /// In en, this message translates to:
  /// **'Show Key'**
  String get stgaShowKey;

  /// No description provided for @stgaHideKey.
  ///
  /// In en, this message translates to:
  /// **'Hide Key'**
  String get stgaHideKey;

  /// No description provided for @stgaPasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get stgaPasteFromClipboard;

  /// No description provided for @stgaSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get stgaSave;

  /// No description provided for @stgaPurposeWyzie.
  ///
  /// In en, this message translates to:
  /// **'Searches the Wyzie subtitle catalogue for movies and episodes.'**
  String get stgaPurposeWyzie;

  /// No description provided for @stgaPurposeAudiobookSearch.
  ///
  /// In en, this message translates to:
  /// **'Mints the anonymous token the Audionest audiobook search API requires.'**
  String get stgaPurposeAudiobookSearch;

  /// No description provided for @stgaPurposeAudiobookService.
  ///
  /// In en, this message translates to:
  /// **'Bearer for the Audionest audiobook search endpoint.'**
  String get stgaPurposeAudiobookService;

  /// No description provided for @stgaPurposePaper2audio.
  ///
  /// In en, this message translates to:
  /// **'Firebase key for the paper2audio PDF to audiobook backend.'**
  String get stgaPurposePaper2audio;

  /// No description provided for @stgaPurposeVidgod.
  ///
  /// In en, this message translates to:
  /// **'Bearer for the VidGod cloud cache behind ZPlayHTTP streams.'**
  String get stgaPurposeVidgod;

  /// No description provided for @stgaPurposeFilms365.
  ///
  /// In en, this message translates to:
  /// **'Bearer for the Films365 direct stream API.'**
  String get stgaPurposeFilms365;

  /// No description provided for @stgaPurposeTraktSecret.
  ///
  /// In en, this message translates to:
  /// **'Exchanges the device code for a Trakt access token.'**
  String get stgaPurposeTraktSecret;

  /// No description provided for @stgaSourceUser.
  ///
  /// In en, this message translates to:
  /// **'Your key is in use.'**
  String get stgaSourceUser;

  /// No description provided for @stgaSourceBuildTime.
  ///
  /// In en, this message translates to:
  /// **'Supplied at build time for this build.'**
  String get stgaSourceBuildTime;

  /// No description provided for @stgaSourceInherited.
  ///
  /// In en, this message translates to:
  /// **'Running on the value this app ships with.'**
  String get stgaSourceInherited;

  /// No description provided for @stgaSourceNone.
  ///
  /// In en, this message translates to:
  /// **'No key available, so this source stays off.'**
  String get stgaSourceNone;

  /// No description provided for @stgaPastedKeyFromClipboardDot.
  ///
  /// In en, this message translates to:
  /// **'Pasted key from clipboard.'**
  String get stgaPastedKeyFromClipboardDot;

  /// No description provided for @stgaKeysYouCanObtain.
  ///
  /// In en, this message translates to:
  /// **'KEYS YOU CAN OBTAIN'**
  String get stgaKeysYouCanObtain;

  /// No description provided for @stgaBorrowedCredentials.
  ///
  /// In en, this message translates to:
  /// **'BORROWED CREDENTIALS'**
  String get stgaBorrowedCredentials;

  /// No description provided for @stgaRelated.
  ///
  /// In en, this message translates to:
  /// **'RELATED'**
  String get stgaRelated;

  /// No description provided for @stgaSavedBadge.
  ///
  /// In en, this message translates to:
  /// **'SAVED'**
  String get stgaSavedBadge;

  /// No description provided for @stgaClearKey.
  ///
  /// In en, this message translates to:
  /// **'Clear key'**
  String get stgaClearKey;

  /// No description provided for @stgaTmdbApiKey.
  ///
  /// In en, this message translates to:
  /// **'TMDb API Key'**
  String get stgaTmdbApiKey;

  /// No description provided for @stgaTmdbRowDescription.
  ///
  /// In en, this message translates to:
  /// **'Ranks the 1990s rails and covers the scraper metadata lookups.'**
  String get stgaTmdbRowDescription;

  /// No description provided for @stgbGpuUpscaling.
  ///
  /// In en, this message translates to:
  /// **'GPU Upscaling'**
  String get stgbGpuUpscaling;

  /// No description provided for @stgbUpscalingPresets.
  ///
  /// In en, this message translates to:
  /// **'UPSCALING PRESETS'**
  String get stgbUpscalingPresets;

  /// No description provided for @stgbDisabledOff.
  ///
  /// In en, this message translates to:
  /// **'Disabled (Off)'**
  String get stgbDisabledOff;

  /// No description provided for @stgbStandardPlaybackDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard video playback without GLSL neural filters. Lowest GPU overhead.'**
  String get stgbStandardPlaybackDesc;

  /// No description provided for @stgbStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get stgbStandard;

  /// No description provided for @stgbModeAFast.
  ///
  /// In en, this message translates to:
  /// **'Mode A — Fast / Balanced'**
  String get stgbModeAFast;

  /// No description provided for @stgbModeAFastDesc.
  ///
  /// In en, this message translates to:
  /// **'Sharp line restoration & 2x CNN upscale. Best for 1080p anime and balanced GPU power.'**
  String get stgbModeAFastDesc;

  /// No description provided for @stgbRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get stgbRecommended;

  /// No description provided for @stgbModeAHq.
  ///
  /// In en, this message translates to:
  /// **'Mode A — High Quality (Ultra)'**
  String get stgbModeAHq;

  /// No description provided for @stgbModeAHqDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum perceptual fidelity using Very Large CNNs. Recommended for discrete GPUs (RTX/Radeon).'**
  String get stgbModeAHqDesc;

  /// No description provided for @stgbUltraQuality.
  ///
  /// In en, this message translates to:
  /// **'Ultra Quality'**
  String get stgbUltraQuality;

  /// No description provided for @stgbModeBSoft.
  ///
  /// In en, this message translates to:
  /// **'Mode B — Soft / Denoise'**
  String get stgbModeBSoft;

  /// No description provided for @stgbModeBSoftDesc.
  ///
  /// In en, this message translates to:
  /// **'Smooth line reconstruction and artifact reduction. Best for blurry, compressed, or older anime.'**
  String get stgbModeBSoftDesc;

  /// No description provided for @stgbDenoise.
  ///
  /// In en, this message translates to:
  /// **'Denoise'**
  String get stgbDenoise;

  /// No description provided for @stgbModeCDeblur.
  ///
  /// In en, this message translates to:
  /// **'Mode C — Deblur & Scale'**
  String get stgbModeCDeblur;

  /// No description provided for @stgbModeCDeblurDesc.
  ///
  /// In en, this message translates to:
  /// **'Aggressive deblurring and scaling. Best for 480p and 720p low-resolution anime episodes.'**
  String get stgbModeCDeblurDesc;

  /// No description provided for @stgbDeblur.
  ///
  /// In en, this message translates to:
  /// **'Deblur'**
  String get stgbDeblur;

  /// No description provided for @stgbFsrSmooth.
  ///
  /// In en, this message translates to:
  /// **'FSR 1.0 — Smooth'**
  String get stgbFsrSmooth;

  /// No description provided for @stgbLiveAction.
  ///
  /// In en, this message translates to:
  /// **'Live action'**
  String get stgbLiveAction;

  /// No description provided for @stgbFsrSharp.
  ///
  /// In en, this message translates to:
  /// **'FSR 1.0 — Sharp'**
  String get stgbFsrSharp;

  /// No description provided for @stgbUseWithCare.
  ///
  /// In en, this message translates to:
  /// **'Use with care'**
  String get stgbUseWithCare;

  /// No description provided for @stgbPipelineCompat.
  ///
  /// In en, this message translates to:
  /// **'PIPELINE & COMPATIBILITY'**
  String get stgbPipelineCompat;

  /// No description provided for @stgbPlaybackStartApply.
  ///
  /// In en, this message translates to:
  /// **'Playback Start Application'**
  String get stgbPlaybackStartApply;

  /// No description provided for @stgbPlaybackStartApplyDesc.
  ///
  /// In en, this message translates to:
  /// **'Shaders are configured before playback begins. Changing a preset applies to the next opened stream or video.'**
  String get stgbPlaybackStartApplyDesc;

  /// No description provided for @stgbHwDecoderAccel.
  ///
  /// In en, this message translates to:
  /// **'Hardware Decoder Acceleration'**
  String get stgbHwDecoderAccel;

  /// No description provided for @stgbHwDecoderAccelDesc.
  ///
  /// In en, this message translates to:
  /// **'media_kit uses native auto-safe hardware decoding to feed GPU texture memory directly into the GLSL shader pass.'**
  String get stgbHwDecoderAccelDesc;

  /// No description provided for @stgbPlatformRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Platform Recommendation'**
  String get stgbPlatformRecommendation;

  /// No description provided for @stgbPlatformRecommendationDesc.
  ///
  /// In en, this message translates to:
  /// **'For desktop (Windows/macOS/Linux), Mode A HQ provides crystal-clear lines. For mobile devices, Mode A Fast offers smooth 60fps playback.'**
  String get stgbPlatformRecommendationDesc;

  /// No description provided for @stgbHwAccelDecoding.
  ///
  /// In en, this message translates to:
  /// **'HARDWARE ACCELERATION & DECODING'**
  String get stgbHwAccelDecoding;

  /// No description provided for @stgbAllPlatforms.
  ///
  /// In en, this message translates to:
  /// **'All Platforms'**
  String get stgbAllPlatforms;

  /// No description provided for @stgbAutoSafeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Auto-Safe (Recommended)'**
  String get stgbAutoSafeRecommended;

  /// No description provided for @stgbAutoSafeDesc.
  ///
  /// In en, this message translates to:
  /// **'GPU hardware decoding with safe driver fallbacks. Best efficiency for most PCs and devices.'**
  String get stgbAutoSafeDesc;

  /// No description provided for @stgbDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get stgbDefault;

  /// No description provided for @stgbSoftwareDecoding.
  ///
  /// In en, this message translates to:
  /// **'Software Decoding (Crash-Proof)'**
  String get stgbSoftwareDecoding;

  /// No description provided for @stgbSoftwareDecodingDesc.
  ///
  /// In en, this message translates to:
  /// **'Pure CPU decoding via FFmpeg libavcodec. Eliminates black screens and driver lockups on older GPUs or virtual machines.'**
  String get stgbSoftwareDecodingDesc;

  /// No description provided for @stgbFullyReliable.
  ///
  /// In en, this message translates to:
  /// **'100% Reliable'**
  String get stgbFullyReliable;

  /// No description provided for @stgbDirectHardware.
  ///
  /// In en, this message translates to:
  /// **'Direct Hardware'**
  String get stgbDirectHardware;

  /// No description provided for @stgbDirectHardwareDesc.
  ///
  /// In en, this message translates to:
  /// **'Direct GPU decoding (Direct3D 11 / MediaCodec / VAAPI). Fastest on modern high-end graphics.'**
  String get stgbDirectHardwareDesc;

  /// No description provided for @stgbMaxGpu.
  ///
  /// In en, this message translates to:
  /// **'Max GPU'**
  String get stgbMaxGpu;

  /// No description provided for @stgbPlaybackEngine.
  ///
  /// In en, this message translates to:
  /// **'PLAYBACK ENGINE'**
  String get stgbPlaybackEngine;

  /// No description provided for @stgbMpvOnly.
  ///
  /// In en, this message translates to:
  /// **'mpv only'**
  String get stgbMpvOnly;

  /// No description provided for @stgbExoPlayerFastest.
  ///
  /// In en, this message translates to:
  /// **'Android\'s ExoPlayer (Fastest at 4K)'**
  String get stgbExoPlayerFastest;

  /// No description provided for @stgbExoPlayerDesc.
  ///
  /// In en, this message translates to:
  /// **'Decodes straight into a surface, so 4K arrives without being copied out of the decoder first. On a 2 GB television that is the difference between 904 ms and over 1,900 ms of delay, and between no dropped frames and one and a half a second. Subtitles are rendered by Android, so the styling options below do not apply here.'**
  String get stgbExoPlayerDesc;

  /// No description provided for @stgbFasterAt4k.
  ///
  /// In en, this message translates to:
  /// **'Faster at 4K'**
  String get stgbFasterAt4k;

  /// No description provided for @stgbMpvFullSubtitle.
  ///
  /// In en, this message translates to:
  /// **'mpv (Full subtitle control)'**
  String get stgbMpvFullSubtitle;

  /// No description provided for @stgbMpvDesc.
  ///
  /// In en, this message translates to:
  /// **'The bundled engine. Plays torrents and live streams, offers the complete subtitle styling surface below, and supports the upscaling presets. Decoded frames are copied through a texture, which is what makes 4K stutter on small televisions.'**
  String get stgbMpvDesc;

  /// No description provided for @stgbMostFeatures.
  ///
  /// In en, this message translates to:
  /// **'Most features'**
  String get stgbMostFeatures;

  /// No description provided for @stgbTorrentsLiveUseMpv.
  ///
  /// In en, this message translates to:
  /// **'Torrents and live TV always use mpv'**
  String get stgbTorrentsLiveUseMpv;

  /// No description provided for @stgbTorrentsLiveUseMpvDesc.
  ///
  /// In en, this message translates to:
  /// **'Whichever engine you pick here, torrent sources and live channels play through mpv, because Android\'s player cannot open them. The choice applies to films, series and anything else fetched over plain HTTP.'**
  String get stgbTorrentsLiveUseMpvDesc;

  /// No description provided for @stgbAutoRecoverBlack.
  ///
  /// In en, this message translates to:
  /// **'Auto-Recover Black Screens'**
  String get stgbAutoRecoverBlack;

  /// No description provided for @stgbActiveWatchdog.
  ///
  /// In en, this message translates to:
  /// **'Active Watchdog'**
  String get stgbActiveWatchdog;

  /// No description provided for @stgbActiveWatchdogDesc.
  ///
  /// In en, this message translates to:
  /// **'Monitors stream startup. If audio plays for 2.5s without video frames, or a GPU decoder error occurs, the player recovers automatically. On Android it switches to software decoding only up to 1080p and re-syncs the hardware decoder above that, because a software 4K decoder needs more memory than the device has. A source that is merely not delivering data yet is waited on rather than treated as a decoder fault.'**
  String get stgbActiveWatchdogDesc;

  /// No description provided for @stgbAndroidRenderingEngine.
  ///
  /// In en, this message translates to:
  /// **'ANDROID RENDERING ENGINE'**
  String get stgbAndroidRenderingEngine;

  /// No description provided for @stgbDirectSurface.
  ///
  /// In en, this message translates to:
  /// **'Direct Surface (SurfaceView)'**
  String get stgbDirectSurface;

  /// No description provided for @stgbZeroCopy.
  ///
  /// In en, this message translates to:
  /// **'Zero-Copy'**
  String get stgbZeroCopy;

  /// No description provided for @stgbOffTextureView.
  ///
  /// In en, this message translates to:
  /// **'Off (TextureView)'**
  String get stgbOffTextureView;

  /// No description provided for @stgbDirectSurfaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Uses Flutter SurfaceProducer to render frames directly to hardware surface without texture blitting. Significantly boosts 4K/60fps playback and reduces battery usage on Android. (Keep disabled if your device experiences display glitches).'**
  String get stgbDirectSurfaceDesc;

  /// No description provided for @stgbAppearanceIntro.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune the visual atmosphere, custom wallpaper background, color palettes, and interface layouts.'**
  String get stgbAppearanceIntro;

  /// No description provided for @stgbInterfaceAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'INTERFACE & ATMOSPHERE'**
  String get stgbInterfaceAtmosphere;

  /// No description provided for @stgbCustomBgWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Custom Background & Wallpaper'**
  String get stgbCustomBgWallpaper;

  /// No description provided for @stgbCustomBgWallpaperDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload custom photos, choose curated dark wallpapers, and blend theme ambient lighting'**
  String get stgbCustomBgWallpaperDesc;

  /// No description provided for @stgbCustomActive.
  ///
  /// In en, this message translates to:
  /// **'Custom Active'**
  String get stgbCustomActive;

  /// No description provided for @stgbDefaultTheme.
  ///
  /// In en, this message translates to:
  /// **'Default Theme'**
  String get stgbDefaultTheme;

  /// No description provided for @stgbLiquidGlassSetup.
  ///
  /// In en, this message translates to:
  /// **'Liquid Glass Setup'**
  String get stgbLiquidGlassSetup;

  /// No description provided for @stgbLiquidGlassSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust hover impact, wobble spring physics, lens refraction, and chromatic aberration'**
  String get stgbLiquidGlassSetupDesc;

  /// No description provided for @stgbDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get stgbDisabled;

  /// No description provided for @stgbHomeUiThemes.
  ///
  /// In en, this message translates to:
  /// **'Home Page UI & Themes'**
  String get stgbHomeUiThemes;

  /// No description provided for @stgbHomeUiThemesDesc.
  ///
  /// In en, this message translates to:
  /// **'Color schemes, \"Because you have on your list\" smart slider, hero spotlight, and card density'**
  String get stgbHomeUiThemesDesc;

  /// No description provided for @stgbLiveTvSportsUi.
  ///
  /// In en, this message translates to:
  /// **'Live TV & Sports UI'**
  String get stgbLiveTvSportsUi;

  /// No description provided for @stgbLiveTvSportsUiDesc.
  ///
  /// In en, this message translates to:
  /// **'Broadcast hero spotlight, channel card density, category ordering, and live badge styling'**
  String get stgbLiveTvSportsUiDesc;

  /// No description provided for @stgbSpotlightOn.
  ///
  /// In en, this message translates to:
  /// **'Spotlight ON'**
  String get stgbSpotlightOn;

  /// No description provided for @stgbCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get stgbCompact;

  /// No description provided for @stgbContent.
  ///
  /// In en, this message translates to:
  /// **'CONTENT'**
  String get stgbContent;

  /// No description provided for @stgbMangaUiReader.
  ///
  /// In en, this message translates to:
  /// **'Manga UI & Reader Atmosphere'**
  String get stgbMangaUiReader;

  /// No description provided for @stgbMangaUiReaderDesc.
  ///
  /// In en, this message translates to:
  /// **'Ambient moving lighting, card density, reading layout widths, webtoon/horizontal modes, and page deck preview'**
  String get stgbMangaUiReaderDesc;

  /// No description provided for @stgbWebtoon.
  ///
  /// In en, this message translates to:
  /// **'Webtoon'**
  String get stgbWebtoon;

  /// No description provided for @stgbHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get stgbHorizontal;

  /// No description provided for @stgbPlayback.
  ///
  /// In en, this message translates to:
  /// **'PLAYBACK'**
  String get stgbPlayback;

  /// No description provided for @stgbAudiobookUiStudio.
  ///
  /// In en, this message translates to:
  /// **'Audiobook UI & Player Studio'**
  String get stgbAudiobookUiStudio;

  /// No description provided for @stgbAudiobookUiStudioDesc.
  ///
  /// In en, this message translates to:
  /// **'Hero spotlight, 5 distinct player designs, drag & drop modular studio, waveform canvas scrubber, and custom controls'**
  String get stgbAudiobookUiStudioDesc;

  /// No description provided for @stgbMusicUiStudio.
  ///
  /// In en, this message translates to:
  /// **'Music UI & Player Studio'**
  String get stgbMusicUiStudio;

  /// No description provided for @stgbMusicUiStudioDesc.
  ///
  /// In en, this message translates to:
  /// **'Hero spotlight, lossless badges, and fullscreen player studio for layout, seekbar, physics & turntable styling'**
  String get stgbMusicUiStudioDesc;

  /// No description provided for @stgbDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'DIAGNOSTICS'**
  String get stgbDiagnostics;

  /// No description provided for @stgbGraphicsBackend.
  ///
  /// In en, this message translates to:
  /// **'Graphics Backend'**
  String get stgbGraphicsBackend;

  /// No description provided for @stgbRestartToApplyBackend.
  ///
  /// In en, this message translates to:
  /// **'Restart the app to apply — the backend is fixed when the engine starts.'**
  String get stgbRestartToApplyBackend;

  /// No description provided for @stgbSkiaRecommended.
  ///
  /// In en, this message translates to:
  /// **'Skia (Recommended)'**
  String get stgbSkiaRecommended;

  /// No description provided for @stgbSimklIntro.
  ///
  /// In en, this message translates to:
  /// **'Connect your Simkl account to synchronize Movies, TV Shows, and Anime watchlists, continue watching progress, and custom lists.'**
  String get stgbSimklIntro;

  /// No description provided for @stgbConnected.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get stgbConnected;

  /// No description provided for @stgbDisconnected.
  ///
  /// In en, this message translates to:
  /// **'DISCONNECTED'**
  String get stgbDisconnected;

  /// No description provided for @stgbCheckingCredentials.
  ///
  /// In en, this message translates to:
  /// **'Checking credentials...'**
  String get stgbCheckingCredentials;

  /// No description provided for @stgbSimklSignInPin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with PIN to activate Simkl cloud sync'**
  String get stgbSimklSignInPin;

  /// No description provided for @stgbDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get stgbDisconnect;

  /// No description provided for @stgbConnectSimkl.
  ///
  /// In en, this message translates to:
  /// **'Connect Simkl'**
  String get stgbConnectSimkl;

  /// No description provided for @stgbSimklEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter this PIN code at simkl.com/pin:'**
  String get stgbSimklEnterPin;

  /// No description provided for @stgbOpenSimklPin.
  ///
  /// In en, this message translates to:
  /// **'Open simkl.com/pin'**
  String get stgbOpenSimklPin;

  /// No description provided for @stgbSimklWaitingPin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for PIN approval on simkl.com...'**
  String get stgbSimklWaitingPin;

  /// No description provided for @stgbCloudSyncControls.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync Controls'**
  String get stgbCloudSyncControls;

  /// No description provided for @stgbSyncSimklWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Sync Simkl Watchlist & Continue Watching'**
  String get stgbSyncSimklWatchlist;

  /// No description provided for @stgbSimklManualPull.
  ///
  /// In en, this message translates to:
  /// **'Manually triggers an immediate pull from Simkl'**
  String get stgbSimklManualPull;

  /// No description provided for @stgbTraktIntro.
  ///
  /// In en, this message translates to:
  /// **'Connect your Trakt.tv account to seamlessly synchronize your watch history, watchlist, continue watching progress, and ratings across all your devices.'**
  String get stgbTraktIntro;

  /// No description provided for @stgbTraktSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to activate two-way cloud sync'**
  String get stgbTraktSignIn;

  /// No description provided for @stgbPairAccount.
  ///
  /// In en, this message translates to:
  /// **'Pair Account'**
  String get stgbPairAccount;

  /// No description provided for @stgbTraktEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter this activation code at trakt.tv/activate:'**
  String get stgbTraktEnterCode;

  /// No description provided for @stgbOpenTraktActivate.
  ///
  /// In en, this message translates to:
  /// **'Open trakt.tv/activate'**
  String get stgbOpenTraktActivate;

  /// No description provided for @stgbTraktWaitingAuth.
  ///
  /// In en, this message translates to:
  /// **'Waiting for authorization on trakt.tv...'**
  String get stgbTraktWaitingAuth;

  /// No description provided for @stgbSyncWatchlistNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Watchlist & Continue Watching Now'**
  String get stgbSyncWatchlistNow;

  /// No description provided for @stgbTraktManualPull.
  ///
  /// In en, this message translates to:
  /// **'Manually triggers an immediate pull from Trakt'**
  String get stgbTraktManualPull;

  /// No description provided for @stgbConnectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get stgbConnectedStatus;

  /// No description provided for @stgbTmdbKeyRejected.
  ///
  /// In en, this message translates to:
  /// **'That key was rejected by TMDb'**
  String get stgbTmdbKeyRejected;

  /// No description provided for @stgbTmdbUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach TMDb'**
  String get stgbTmdbUnreachable;

  /// No description provided for @stgbTmdbPasteFirst.
  ///
  /// In en, this message translates to:
  /// **'Paste a TMDb API key first.'**
  String get stgbTmdbPasteFirst;

  /// No description provided for @stgbTmdbKeySaved.
  ///
  /// In en, this message translates to:
  /// **'TMDb key saved. The 1990s rails now use TMDb ranks.'**
  String get stgbTmdbKeySaved;

  /// No description provided for @stgbTmdbKeyCleared.
  ///
  /// In en, this message translates to:
  /// **'TMDb key cleared. The built-in 1990s picks are back.'**
  String get stgbTmdbKeyCleared;

  /// No description provided for @stgbPastedKey.
  ///
  /// In en, this message translates to:
  /// **'Pasted key from clipboard.'**
  String get stgbPastedKey;

  /// No description provided for @stgbDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get stgbDismiss;

  /// No description provided for @stgbTmdbCredential.
  ///
  /// In en, this message translates to:
  /// **'TMDB CREDENTIAL'**
  String get stgbTmdbCredential;

  /// No description provided for @stgbCredits.
  ///
  /// In en, this message translates to:
  /// **'CREDITS'**
  String get stgbCredits;

  /// No description provided for @stgbSaved.
  ///
  /// In en, this message translates to:
  /// **'SAVED'**
  String get stgbSaved;

  /// No description provided for @stgbTmdbSavedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. Enter a new key to replace it.'**
  String get stgbTmdbSavedOnDevice;

  /// No description provided for @stgbTmdbFreeKey.
  ///
  /// In en, this message translates to:
  /// **'Free key from themoviedb.org'**
  String get stgbTmdbFreeKey;

  /// No description provided for @stgbTmdbPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your TMDb API key'**
  String get stgbTmdbPasteHint;

  /// No description provided for @stgbShowKey.
  ///
  /// In en, this message translates to:
  /// **'Show Key'**
  String get stgbShowKey;

  /// No description provided for @stgbHideKey.
  ///
  /// In en, this message translates to:
  /// **'Hide Key'**
  String get stgbHideKey;

  /// No description provided for @stgbPasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get stgbPasteFromClipboard;

  /// No description provided for @stgbSaveAndTest.
  ///
  /// In en, this message translates to:
  /// **'Save and test'**
  String get stgbSaveAndTest;

  /// No description provided for @stgbTmdbKeySavedTest.
  ///
  /// In en, this message translates to:
  /// **'A key is saved. Run a test to confirm it still works.'**
  String get stgbTmdbKeySavedTest;

  /// No description provided for @stgbTmdbNoKey.
  ///
  /// In en, this message translates to:
  /// **'No key saved yet, so the built-in picks are in use.'**
  String get stgbTmdbNoKey;

  /// No description provided for @stgbClearKey.
  ///
  /// In en, this message translates to:
  /// **'Clear key'**
  String get stgbClearKey;

  /// No description provided for @stgbAboutPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by embedded media_kit / libmpv with hardware-accelerated decoding.'**
  String get stgbAboutPoweredBy;

  /// No description provided for @stgbPlayerStudio.
  ///
  /// In en, this message translates to:
  /// **'Player Studio'**
  String get stgbPlayerStudio;

  /// No description provided for @stgbCustomAudiobookStudio.
  ///
  /// In en, this message translates to:
  /// **'Custom Audiobook Player Studio'**
  String get stgbCustomAudiobookStudio;

  /// No description provided for @stgbAudiobookStudioDesc.
  ///
  /// In en, this message translates to:
  /// **'Drag components, transform seekbars, customize button physics'**
  String get stgbAudiobookStudioDesc;

  /// No description provided for @stgbApplyAsActivePlayer.
  ///
  /// In en, this message translates to:
  /// **'Apply As Active Player'**
  String get stgbApplyAsActivePlayer;

  /// No description provided for @stgbStudioDesigner.
  ///
  /// In en, this message translates to:
  /// **'Studio Designer'**
  String get stgbStudioDesigner;

  /// No description provided for @stgbLivePreviewCanvas.
  ///
  /// In en, this message translates to:
  /// **'Live Preview Canvas'**
  String get stgbLivePreviewCanvas;

  /// No description provided for @stgbTestLiveCanvas.
  ///
  /// In en, this message translates to:
  /// **'Test Live Canvas'**
  String get stgbTestLiveCanvas;

  /// No description provided for @stgbBackToCustomizer.
  ///
  /// In en, this message translates to:
  /// **'Back to Customizer'**
  String get stgbBackToCustomizer;

  /// No description provided for @stgbLiveInteractiveCanvas.
  ///
  /// In en, this message translates to:
  /// **'LIVE INTERACTIVE CANVAS'**
  String get stgbLiveInteractiveCanvas;

  /// No description provided for @stgbCustomStudio.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM STUDIO'**
  String get stgbCustomStudio;

  /// No description provided for @stgbPremadeChaptersPanel.
  ///
  /// In en, this message translates to:
  /// **'Premade Chapters Panel'**
  String get stgbPremadeChaptersPanel;

  /// No description provided for @stgbPauseCaps.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get stgbPauseCaps;

  /// No description provided for @stgbPlayCaps.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get stgbPlayCaps;

  /// No description provided for @stgbPremadeChaptersPreview.
  ///
  /// In en, this message translates to:
  /// **'Premade Chapters Panel Preview'**
  String get stgbPremadeChaptersPreview;

  /// No description provided for @stgbDragDropLayout.
  ///
  /// In en, this message translates to:
  /// **'Drag & Drop Layout'**
  String get stgbDragDropLayout;

  /// No description provided for @stgbSeekBarCanvas.
  ///
  /// In en, this message translates to:
  /// **'Seek Bar Canvas'**
  String get stgbSeekBarCanvas;

  /// No description provided for @stgbPlayButtonPhysics.
  ///
  /// In en, this message translates to:
  /// **'Play Button & Physics'**
  String get stgbPlayButtonPhysics;

  /// No description provided for @stgbArtworkFrame.
  ///
  /// In en, this message translates to:
  /// **'Artwork & Frame'**
  String get stgbArtworkFrame;

  /// No description provided for @stgbArtworkVinylFrame.
  ///
  /// In en, this message translates to:
  /// **'Artwork & Vinyl Frame'**
  String get stgbArtworkVinylFrame;

  /// No description provided for @stgbChapterBookTitles.
  ///
  /// In en, this message translates to:
  /// **'Chapter & Book Titles'**
  String get stgbChapterBookTitles;

  /// No description provided for @stgbSeekBarScrubberCanvas.
  ///
  /// In en, this message translates to:
  /// **'Seek Bar Scrubber Canvas'**
  String get stgbSeekBarScrubberCanvas;

  /// No description provided for @stgbPrimaryControlsAudiobook.
  ///
  /// In en, this message translates to:
  /// **'Primary Controls (Play, Pause, Skip ±10s)'**
  String get stgbPrimaryControlsAudiobook;

  /// No description provided for @stgbSecondaryControlsAudiobook.
  ///
  /// In en, this message translates to:
  /// **'Secondary Controls (Speed Pill & Volume)'**
  String get stgbSecondaryControlsAudiobook;

  /// No description provided for @stgbPremadeChaptersButton.
  ///
  /// In en, this message translates to:
  /// **'Premade Chapters Panel Button'**
  String get stgbPremadeChaptersButton;

  /// No description provided for @stgbDragDropArranger.
  ///
  /// In en, this message translates to:
  /// **'Drag & Drop Component Arranger'**
  String get stgbDragDropArranger;

  /// No description provided for @stgbAudiobookArrangerDesc.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag any block to reorder the vertical layout of your audio player in real-time.'**
  String get stgbAudiobookArrangerDesc;

  /// No description provided for @stgbSeekBarStyles.
  ///
  /// In en, this message translates to:
  /// **'Seek Bar Canvas & Scrubber Styles'**
  String get stgbSeekBarStyles;

  /// No description provided for @stgbSeekBarStylesDesc.
  ///
  /// In en, this message translates to:
  /// **'Select how your progress bar and scrubber render inside your custom player canvas.'**
  String get stgbSeekBarStylesDesc;

  /// No description provided for @stgbPlayPauseStyle.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause Button Style'**
  String get stgbPlayPauseStyle;

  /// No description provided for @stgbHoverTouchPhysics.
  ///
  /// In en, this message translates to:
  /// **'Hover & Touch Physics'**
  String get stgbHoverTouchPhysics;

  /// No description provided for @stgbPhysicsPlayground.
  ///
  /// In en, this message translates to:
  /// **'Live Touch & Hover Physics Playground'**
  String get stgbPhysicsPlayground;

  /// No description provided for @stgbArtworkDisplayMode.
  ///
  /// In en, this message translates to:
  /// **'Artwork Display Mode'**
  String get stgbArtworkDisplayMode;

  /// No description provided for @stgbColorThemesAccents.
  ///
  /// In en, this message translates to:
  /// **'COLOR THEMES & ACCENTS'**
  String get stgbColorThemesAccents;

  /// No description provided for @stgbAmbientLightingGlows.
  ///
  /// In en, this message translates to:
  /// **'AMBIENT BACKGROUND LIGHTING & MOVING GLOWS'**
  String get stgbAmbientLightingGlows;

  /// No description provided for @stgbDiscoveryAudiobookPosters.
  ///
  /// In en, this message translates to:
  /// **'DISCOVERY & AUDIOBOOK POSTERS'**
  String get stgbDiscoveryAudiobookPosters;

  /// No description provided for @stgbChooseAudioPreset.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE AUDIO PLAYER PRESET'**
  String get stgbChooseAudioPreset;

  /// No description provided for @stgbMakeCustomAudiobookPlayer.
  ///
  /// In en, this message translates to:
  /// **'MAKE YOUR CUSTOM AUDIOBOOK PLAYER (DRAG & DROP STUDIO)'**
  String get stgbMakeCustomAudiobookPlayer;

  /// No description provided for @stgbEnableMovingAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Enable Moving Ambient Atmosphere'**
  String get stgbEnableMovingAtmosphere;

  /// No description provided for @stgbLightingFlowPattern.
  ///
  /// In en, this message translates to:
  /// **'Lighting Flow Pattern'**
  String get stgbLightingFlowPattern;

  /// No description provided for @stgbGlowStrengthOpacity.
  ///
  /// In en, this message translates to:
  /// **'Glow Strength / Opacity'**
  String get stgbGlowStrengthOpacity;

  /// No description provided for @stgbMotionDriftSpeed.
  ///
  /// In en, this message translates to:
  /// **'Motion Drift Speed'**
  String get stgbMotionDriftSpeed;

  /// No description provided for @stgbLiveAtmospherePreview.
  ///
  /// In en, this message translates to:
  /// **'Live Atmosphere Preview'**
  String get stgbLiveAtmospherePreview;

  /// No description provided for @stgbShowHeroCarousel.
  ///
  /// In en, this message translates to:
  /// **'Show Hero Spotlight Carousel'**
  String get stgbShowHeroCarousel;

  /// No description provided for @stgbAudiobookHeroDesc.
  ///
  /// In en, this message translates to:
  /// **'Featured bestselling audiobook showcase at the top of the hub'**
  String get stgbAudiobookHeroDesc;

  /// No description provided for @stgbShowContinueListening.
  ///
  /// In en, this message translates to:
  /// **'Show \"Continue Listening\" Carousel'**
  String get stgbShowContinueListening;

  /// No description provided for @stgbContinueListeningDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick resume cards with chapter progress bar and direct play'**
  String get stgbContinueListeningDesc;

  /// No description provided for @stgbAudiobookCardDensity.
  ///
  /// In en, this message translates to:
  /// **'Audiobook Poster Card Density'**
  String get stgbAudiobookCardDensity;

  /// No description provided for @stgbShowGenreBadges.
  ///
  /// In en, this message translates to:
  /// **'Show Quick Genre & Category Badges'**
  String get stgbShowGenreBadges;

  /// No description provided for @stgbShowAudiobookRuntime.
  ///
  /// In en, this message translates to:
  /// **'Show Audiobook Runtime / Total Duration'**
  String get stgbShowAudiobookRuntime;

  /// No description provided for @stgbPosterHoverGlowElevation.
  ///
  /// In en, this message translates to:
  /// **'Poster Card Hover Glow & Elevation'**
  String get stgbPosterHoverGlowElevation;

  /// No description provided for @stgbOpenStudio.
  ///
  /// In en, this message translates to:
  /// **'Open Studio'**
  String get stgbOpenStudio;

  /// No description provided for @stgbVisualPlayerStudio.
  ///
  /// In en, this message translates to:
  /// **'Visual Custom Player Studio'**
  String get stgbVisualPlayerStudio;

  /// No description provided for @stgbFullStudio.
  ///
  /// In en, this message translates to:
  /// **'FULL STUDIO'**
  String get stgbFullStudio;

  /// No description provided for @stgbVisualPlayerStudioDesc.
  ///
  /// In en, this message translates to:
  /// **'Drag & drop layout elements, procedural waveform canvases, liquid glass buttons, and premade chapters panel in real-time.'**
  String get stgbVisualPlayerStudioDesc;

  /// No description provided for @stgbEnterPlayerStudio.
  ///
  /// In en, this message translates to:
  /// **'Enter Custom Player Studio'**
  String get stgbEnterPlayerStudio;

  /// No description provided for @stgbInteractiveStudioPreview.
  ///
  /// In en, this message translates to:
  /// **'Interactive Studio Preview'**
  String get stgbInteractiveStudioPreview;

  /// No description provided for @stgbLiveCaps.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get stgbLiveCaps;

  /// No description provided for @stgbSeekBarScrubberStyle.
  ///
  /// In en, this message translates to:
  /// **'Seek Bar / Scrubber Style'**
  String get stgbSeekBarScrubberStyle;

  /// No description provided for @stgbPlayPauseStyling.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause Button Styling'**
  String get stgbPlayPauseStyling;

  /// No description provided for @stgbArtworkDisplayStyle.
  ///
  /// In en, this message translates to:
  /// **'Artwork Display Style'**
  String get stgbArtworkDisplayStyle;

  /// No description provided for @stgbButtonHoverPhysics.
  ///
  /// In en, this message translates to:
  /// **'Button Hover & Touch Physics'**
  String get stgbButtonHoverPhysics;

  /// No description provided for @stgbPlayerLayoutComponents.
  ///
  /// In en, this message translates to:
  /// **'Player Layout Components (Drag to Arrange)'**
  String get stgbPlayerLayoutComponents;

  /// No description provided for @stgbPlayerLayoutComponentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag any block to reorder how controls appear inside your player'**
  String get stgbPlayerLayoutComponentsDesc;

  /// No description provided for @stgbLiquidGlassPlayerBlur.
  ///
  /// In en, this message translates to:
  /// **'Liquid Glass Player Blur & Refraction'**
  String get stgbLiquidGlassPlayerBlur;

  /// No description provided for @stgbShowSpeedSelector.
  ///
  /// In en, this message translates to:
  /// **'Show Playback Speed Selector (0.5x - 2.5x)'**
  String get stgbShowSpeedSelector;

  /// No description provided for @stgbShowSkipButtons.
  ///
  /// In en, this message translates to:
  /// **'Show Skip Forward/Rewind Buttons (±10s)'**
  String get stgbShowSkipButtons;

  /// No description provided for @stgbShowChaptersDrawerButton.
  ///
  /// In en, this message translates to:
  /// **'Show Quick Chapters Sliding Drawer Button'**
  String get stgbShowChaptersDrawerButton;

  /// No description provided for @stgbLaunchFullStudio.
  ///
  /// In en, this message translates to:
  /// **'Launch Full Custom Player Studio'**
  String get stgbLaunchFullStudio;

  /// No description provided for @stgbAudiobookCoverDeck.
  ///
  /// In en, this message translates to:
  /// **'Audiobook Cover Artwork Deck'**
  String get stgbAudiobookCoverDeck;

  /// No description provided for @stgbTitleAuthorChapter.
  ///
  /// In en, this message translates to:
  /// **'Title, Author & Chapter Label'**
  String get stgbTitleAuthorChapter;

  /// No description provided for @stgbSeekBarWaveformScrubber.
  ///
  /// In en, this message translates to:
  /// **'Seek Bar & Waveform Canvas Scrubber'**
  String get stgbSeekBarWaveformScrubber;

  /// No description provided for @stgbMainControlsCluster.
  ///
  /// In en, this message translates to:
  /// **'Main Play / Pause / Skip (±10s) Cluster'**
  String get stgbMainControlsCluster;

  /// No description provided for @stgbSpeedVolumeControls.
  ///
  /// In en, this message translates to:
  /// **'Speed Selector & Volume Controls'**
  String get stgbSpeedVolumeControls;

  /// No description provided for @stgbPremadeChaptersTrigger.
  ///
  /// In en, this message translates to:
  /// **'Premade Sliding Chapters Panel Trigger'**
  String get stgbPremadeChaptersTrigger;

  /// No description provided for @stgbBgUploadedApplied.
  ///
  /// In en, this message translates to:
  /// **'Background image uploaded and applied across all UI!'**
  String get stgbBgUploadedApplied;

  /// No description provided for @stgbEnterValidImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid HTTP or HTTPS image URL.'**
  String get stgbEnterValidImageUrl;

  /// No description provided for @stgbCustomBgUrlApplied.
  ///
  /// In en, this message translates to:
  /// **'Custom background URL applied!'**
  String get stgbCustomBgUrlApplied;

  /// No description provided for @stgbCustomBgIntro.
  ///
  /// In en, this message translates to:
  /// **'Upload your own photo or choose a curated wallpaper. Theme colors and moving ambient lights softly blend into the background for a unified look.'**
  String get stgbCustomBgIntro;

  /// No description provided for @stgbUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get stgbUploading;

  /// No description provided for @stgbUploadPhotoFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo from Device'**
  String get stgbUploadPhotoFromDevice;

  /// No description provided for @stgbResetToDefaultBg.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default Background'**
  String get stgbResetToDefaultBg;

  /// No description provided for @stgbBgResetDefault.
  ///
  /// In en, this message translates to:
  /// **'Background reset to default theme.'**
  String get stgbBgResetDefault;

  /// No description provided for @stgbPasteImageUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Or paste image URL (https://...)'**
  String get stgbPasteImageUrlHint;

  /// No description provided for @stgbApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get stgbApply;

  /// No description provided for @stgbCuratedDarkWallpapers.
  ///
  /// In en, this message translates to:
  /// **'CURATED DARK WALLPAPERS'**
  String get stgbCuratedDarkWallpapers;

  /// No description provided for @stgbWallpaperBlendControls.
  ///
  /// In en, this message translates to:
  /// **'WALLPAPER & LIGHT BLENDING CONTROLS'**
  String get stgbWallpaperBlendControls;

  /// No description provided for @stgbPhotoVisibility.
  ///
  /// In en, this message translates to:
  /// **'Photo Visibility / Darkness'**
  String get stgbPhotoVisibility;

  /// No description provided for @stgbPhotoSoftBlur.
  ///
  /// In en, this message translates to:
  /// **'Photo Soft Blur'**
  String get stgbPhotoSoftBlur;

  /// No description provided for @stgbThemeTintOverlay.
  ///
  /// In en, this message translates to:
  /// **'Theme Color Tint Overlay'**
  String get stgbThemeTintOverlay;

  /// No description provided for @stgbBlendAmbientLights.
  ///
  /// In en, this message translates to:
  /// **'Blend Moving Ambient Lights'**
  String get stgbBlendAmbientLights;

  /// No description provided for @stgbBlendAmbientLightsDesc.
  ///
  /// In en, this message translates to:
  /// **'Softly illuminates and animates theme lights over your wallpaper'**
  String get stgbBlendAmbientLightsDesc;

  /// No description provided for @stgbCustomBgWallpaperCaps.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM BACKGROUND & WALLPAPER'**
  String get stgbCustomBgWallpaperCaps;

  /// No description provided for @stgbCustomWallpaperBlend.
  ///
  /// In en, this message translates to:
  /// **'Custom Wallpaper & Lighting Blend'**
  String get stgbCustomWallpaperBlend;

  /// No description provided for @stgbCustomBgActiveBlend.
  ///
  /// In en, this message translates to:
  /// **'Custom background active with ambient light blending'**
  String get stgbCustomBgActiveBlend;

  /// No description provided for @stgbUploadOrChooseWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Upload photos or choose curated dark wallpapers'**
  String get stgbUploadOrChooseWallpaper;

  /// No description provided for @stgbSmartRecsCaps.
  ///
  /// In en, this message translates to:
  /// **'SMART RECOMMENDATIONS (\"BECAUSE YOU HAVE ON YOUR LIST\")'**
  String get stgbSmartRecsCaps;

  /// No description provided for @stgbCuratedCollections.
  ///
  /// In en, this message translates to:
  /// **'CURATED COLLECTIONS'**
  String get stgbCuratedCollections;

  /// No description provided for @stgbHeroBannerSpotlight.
  ///
  /// In en, this message translates to:
  /// **'HERO BANNER & SPOTLIGHT'**
  String get stgbHeroBannerSpotlight;

  /// No description provided for @stgbPosterCardsDensity.
  ///
  /// In en, this message translates to:
  /// **'POSTER CARDS & DENSITY'**
  String get stgbPosterCardsDensity;

  /// No description provided for @stgbHeaderShortcuts.
  ///
  /// In en, this message translates to:
  /// **'HEADER SHORTCUTS & BUTTONS'**
  String get stgbHeaderShortcuts;

  /// No description provided for @stgbLiveLightingPreview.
  ///
  /// In en, this message translates to:
  /// **'LIVE LIGHTING ENGINE PREVIEW'**
  String get stgbLiveLightingPreview;

  /// No description provided for @stgbMovingAmbientLights.
  ///
  /// In en, this message translates to:
  /// **'Moving Ambient Lights & Glows'**
  String get stgbMovingAmbientLights;

  /// No description provided for @stgbMovingAmbientLightsDesc.
  ///
  /// In en, this message translates to:
  /// **'Drifting faded light waves & floating color orbs in background'**
  String get stgbMovingAmbientLightsDesc;

  /// No description provided for @stgbLightingPatternPosition.
  ///
  /// In en, this message translates to:
  /// **'Lighting Pattern & Position'**
  String get stgbLightingPatternPosition;

  /// No description provided for @stgbGlowStrengthIntensity.
  ///
  /// In en, this message translates to:
  /// **'Glow Strength / Intensity'**
  String get stgbGlowStrengthIntensity;

  /// No description provided for @stgbMotionFlowSpeed.
  ///
  /// In en, this message translates to:
  /// **'Motion Flow Speed'**
  String get stgbMotionFlowSpeed;

  /// No description provided for @stgbSmartRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Smart Recommendations'**
  String get stgbSmartRecommendations;

  /// No description provided for @stgbSmartRecommendationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure personalized & algorithmic recommendation sliders'**
  String get stgbSmartRecommendationsDesc;

  /// No description provided for @stgbBecauseYouHave.
  ///
  /// In en, this message translates to:
  /// **'\"Because You Have...\" (My List)'**
  String get stgbBecauseYouHave;

  /// No description provided for @stgbBecauseYouHaveDesc.
  ///
  /// In en, this message translates to:
  /// **'BestSimilar recommendations based on titles saved in My List'**
  String get stgbBecauseYouHaveDesc;

  /// No description provided for @stgbBecauseYoureWatching.
  ///
  /// In en, this message translates to:
  /// **'\"Because You\'re Watching...\"'**
  String get stgbBecauseYoureWatching;

  /// No description provided for @stgbBecauseYoureWatchingDesc.
  ///
  /// In en, this message translates to:
  /// **'BestSimilar recommendations based on active Continue Watching titles'**
  String get stgbBecauseYoureWatchingDesc;

  /// No description provided for @stgbTraktRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Trakt Recommendations'**
  String get stgbTraktRecommendations;

  /// No description provided for @stgbTraktRecommendationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Personalized recommendations computed by Trakt'**
  String get stgbTraktRecommendationsDesc;

  /// No description provided for @stgbRequiresTraktLogin.
  ///
  /// In en, this message translates to:
  /// **'Requires Trakt login in Settings -> Trakt'**
  String get stgbRequiresTraktLogin;

  /// No description provided for @stgbSimklRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Simkl Recommendations'**
  String get stgbSimklRecommendations;

  /// No description provided for @stgbSimklRecommendationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Top-rated & personalized suggestions from Simkl'**
  String get stgbSimklRecommendationsDesc;

  /// No description provided for @stgbRequiresSimklLogin.
  ///
  /// In en, this message translates to:
  /// **'Requires Simkl login in Settings -> Simkl'**
  String get stgbRequiresSimklLogin;

  /// No description provided for @stgbRecSlidersPosition.
  ///
  /// In en, this message translates to:
  /// **'Recommendation Sliders Position on Home Page'**
  String get stgbRecSlidersPosition;

  /// No description provided for @stgbCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get stgbCollections;

  /// No description provided for @stgbCollectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show curated collection rails on the Home page'**
  String get stgbCollectionsDesc;

  /// No description provided for @stgbShowHeroBanner.
  ///
  /// In en, this message translates to:
  /// **'Show Hero Spotlight Banner'**
  String get stgbShowHeroBanner;

  /// No description provided for @stgbShowHeroBannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Featured rotation banner at the top of the home page'**
  String get stgbShowHeroBannerDesc;

  /// No description provided for @stgbSpotlightStyle.
  ///
  /// In en, this message translates to:
  /// **'Spotlight Style'**
  String get stgbSpotlightStyle;

  /// No description provided for @stgbAutoRotateSpotlight.
  ///
  /// In en, this message translates to:
  /// **'Auto-Rotate Spotlight'**
  String get stgbAutoRotateSpotlight;

  /// No description provided for @stgbAutoRotateSpotlightDesc.
  ///
  /// In en, this message translates to:
  /// **'Cycles through featured titles automatically'**
  String get stgbAutoRotateSpotlightDesc;

  /// No description provided for @stgbAmbientBackdropLighting.
  ///
  /// In en, this message translates to:
  /// **'Ambient Backdrop Lighting'**
  String get stgbAmbientBackdropLighting;

  /// No description provided for @stgbAmbientBackdropLightingDesc.
  ///
  /// In en, this message translates to:
  /// **'Soft diffused color glow behind active hero poster'**
  String get stgbAmbientBackdropLightingDesc;

  /// No description provided for @stgbPosterSizeDensity.
  ///
  /// In en, this message translates to:
  /// **'Poster Size & Grid Density'**
  String get stgbPosterSizeDensity;

  /// No description provided for @stgbShowImdbBadges.
  ///
  /// In en, this message translates to:
  /// **'Show IMDB Rating Badges'**
  String get stgbShowImdbBadges;

  /// No description provided for @stgbShowImdbBadgesDesc.
  ///
  /// In en, this message translates to:
  /// **'Display rating star pill on poster corners'**
  String get stgbShowImdbBadgesDesc;

  /// No description provided for @stgbPosterHoverZoom.
  ///
  /// In en, this message translates to:
  /// **'Poster Hover Zoom Scale'**
  String get stgbPosterHoverZoom;

  /// No description provided for @stgbTvAiringCalendar.
  ///
  /// In en, this message translates to:
  /// **'TV Airing Calendar'**
  String get stgbTvAiringCalendar;

  /// No description provided for @stgbTvAiringCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'Show TV Calendar buttons on Home bar & sliders'**
  String get stgbTvAiringCalendarDesc;

  /// No description provided for @stgbAiRecQuiz.
  ///
  /// In en, this message translates to:
  /// **'AI Recommendation Quiz'**
  String get stgbAiRecQuiz;

  /// No description provided for @stgbAiRecQuizDesc.
  ///
  /// In en, this message translates to:
  /// **'Show AI Quiz button on Home & Search bars'**
  String get stgbAiRecQuizDesc;

  /// No description provided for @stgbReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get stgbReset;

  /// No description provided for @stgbEnableLiquidGlass.
  ///
  /// In en, this message translates to:
  /// **'Enable Liquid Glass'**
  String get stgbEnableLiquidGlass;

  /// No description provided for @stgbEnableLiquidGlassDesc.
  ///
  /// In en, this message translates to:
  /// **'Real-time refraction shaders, jelly springs, and lenses'**
  String get stgbEnableLiquidGlassDesc;

  /// No description provided for @stgbPresets.
  ///
  /// In en, this message translates to:
  /// **'PRESETS'**
  String get stgbPresets;

  /// No description provided for @stgbPhysicsOptical.
  ///
  /// In en, this message translates to:
  /// **'PHYSICS & OPTICAL PARAMETERS'**
  String get stgbPhysicsOptical;

  /// No description provided for @stgbHoverScaleImpact.
  ///
  /// In en, this message translates to:
  /// **'Hover Scale Impact'**
  String get stgbHoverScaleImpact;

  /// No description provided for @stgbHoverScaleImpactDesc.
  ///
  /// In en, this message translates to:
  /// **'Magnification amount applied to the player glass controls on hover'**
  String get stgbHoverScaleImpactDesc;

  /// No description provided for @stgbWobbleElasticity.
  ///
  /// In en, this message translates to:
  /// **'Wobble & Fluid Elasticity'**
  String get stgbWobbleElasticity;

  /// No description provided for @stgbWobbleElasticityDesc.
  ///
  /// In en, this message translates to:
  /// **'Spring bounce intensity and deformation responsiveness'**
  String get stgbWobbleElasticityDesc;

  /// No description provided for @stgbRefractionIndex.
  ///
  /// In en, this message translates to:
  /// **'Optical Refraction Index'**
  String get stgbRefractionIndex;

  /// No description provided for @stgbRefractionIndexDesc.
  ///
  /// In en, this message translates to:
  /// **'Light bending and background warp index inside glass lenses'**
  String get stgbRefractionIndexDesc;

  /// No description provided for @stgbLensMagnification.
  ///
  /// In en, this message translates to:
  /// **'Lens Magnification'**
  String get stgbLensMagnification;

  /// No description provided for @stgbLensMagnificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Underlying zoom factor seen through the glass volume'**
  String get stgbLensMagnificationDesc;

  /// No description provided for @stgbChromaticAberration.
  ///
  /// In en, this message translates to:
  /// **'Chromatic Aberration (Prism Split)'**
  String get stgbChromaticAberration;

  /// No description provided for @stgbChromaticAberrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Separates RGB spectrum colors along optical glass bevels'**
  String get stgbChromaticAberrationDesc;

  /// No description provided for @stgbFrostedGlassBlur.
  ///
  /// In en, this message translates to:
  /// **'Frosted Glass Blur'**
  String get stgbFrostedGlassBlur;

  /// No description provided for @stgbFrostedGlassBlurDesc.
  ///
  /// In en, this message translates to:
  /// **'Gaussian blur diffusion applied behind glass components'**
  String get stgbFrostedGlassBlurDesc;

  /// No description provided for @stgbSpecularShimmer.
  ///
  /// In en, this message translates to:
  /// **'Specular Light & Shimmer'**
  String get stgbSpecularShimmer;

  /// No description provided for @stgbSpecularShimmerDesc.
  ///
  /// In en, this message translates to:
  /// **'Glossy specular reflection and border illumination intensity'**
  String get stgbSpecularShimmerDesc;

  /// No description provided for @stgbBorderWidth.
  ///
  /// In en, this message translates to:
  /// **'Border Width'**
  String get stgbBorderWidth;

  /// No description provided for @stgbBorderWidthDesc.
  ///
  /// In en, this message translates to:
  /// **'Thickness of the refractive outer boundary edge'**
  String get stgbBorderWidthDesc;

  /// No description provided for @stgbLiveInteractivePreview.
  ///
  /// In en, this message translates to:
  /// **'LIVE INTERACTIVE PREVIEW'**
  String get stgbLiveInteractivePreview;

  /// No description provided for @stgbPreviewEnableGlass.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW (ENABLE GLASS ABOVE)'**
  String get stgbPreviewEnableGlass;

  /// No description provided for @stgbHoverTapPreview.
  ///
  /// In en, this message translates to:
  /// **'Hover or tap the icons to preview spring wobble & scale'**
  String get stgbHoverTapPreview;

  /// No description provided for @stgbLiveSpotlightHero.
  ///
  /// In en, this message translates to:
  /// **'LIVE SPOTLIGHT & HERO BANNER'**
  String get stgbLiveSpotlightHero;

  /// No description provided for @stgbChannelCardsDensity.
  ///
  /// In en, this message translates to:
  /// **'CHANNEL CARDS & POSTER DENSITY'**
  String get stgbChannelCardsDensity;

  /// No description provided for @stgbSectionsCategoryManager.
  ///
  /// In en, this message translates to:
  /// **'SECTIONS & CATEGORY MANAGER'**
  String get stgbSectionsCategoryManager;

  /// No description provided for @stgbPortalsPlaylistsModal.
  ///
  /// In en, this message translates to:
  /// **'PORTALS & PLAYLISTS MODAL'**
  String get stgbPortalsPlaylistsModal;

  /// No description provided for @stgbPortalBrowserGuide.
  ///
  /// In en, this message translates to:
  /// **'PORTAL BROWSER & CHANNEL GUIDE'**
  String get stgbPortalBrowserGuide;

  /// No description provided for @stgbStreamSources.
  ///
  /// In en, this message translates to:
  /// **'STREAM SOURCES'**
  String get stgbStreamSources;

  /// No description provided for @stgbShowLiveSpotlight.
  ///
  /// In en, this message translates to:
  /// **'Show Live Spotlight Banner'**
  String get stgbShowLiveSpotlight;

  /// No description provided for @stgbShowLiveSpotlightDesc.
  ///
  /// In en, this message translates to:
  /// **'Featured championship matches and top broadcast channels at the top'**
  String get stgbShowLiveSpotlightDesc;

  /// No description provided for @stgbHeroBannerStyle.
  ///
  /// In en, this message translates to:
  /// **'Hero Banner Style'**
  String get stgbHeroBannerStyle;

  /// No description provided for @stgbAutoRotateChannels.
  ///
  /// In en, this message translates to:
  /// **'Auto-Rotate Channels'**
  String get stgbAutoRotateChannels;

  /// No description provided for @stgbAutoRotateChannelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically cycle through featured live events'**
  String get stgbAutoRotateChannelsDesc;

  /// No description provided for @stgbRotationInterval.
  ///
  /// In en, this message translates to:
  /// **'Rotation Interval'**
  String get stgbRotationInterval;

  /// No description provided for @stgbChannelCardSize.
  ///
  /// In en, this message translates to:
  /// **'Channel Card Size'**
  String get stgbChannelCardSize;

  /// No description provided for @stgbCardHoverZoom.
  ///
  /// In en, this message translates to:
  /// **'Card Hover Scale Zoom'**
  String get stgbCardHoverZoom;

  /// No description provided for @stgbShowLiveHdBadge.
  ///
  /// In en, this message translates to:
  /// **'Show LIVE / HD Stream Badge'**
  String get stgbShowLiveHdBadge;

  /// No description provided for @stgbShowLiveHdBadgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Display radiant live broadcast badge on channel corners'**
  String get stgbShowLiveHdBadgeDesc;

  /// No description provided for @stgbShowChannelCategoryTag.
  ///
  /// In en, this message translates to:
  /// **'Show Channel Category Tag'**
  String get stgbShowChannelCategoryTag;

  /// No description provided for @stgbShowChannelCategoryTagDesc.
  ///
  /// In en, this message translates to:
  /// **'Show category label below channel name'**
  String get stgbShowChannelCategoryTagDesc;

  /// No description provided for @stgbShowFeedHealthBadge.
  ///
  /// In en, this message translates to:
  /// **'Show Feed Health Badge'**
  String get stgbShowFeedHealthBadge;

  /// No description provided for @stgbShowFeedHealthBadgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Mark a channel as alive, unchecked or dead on the Boxing row'**
  String get stgbShowFeedHealthBadgeDesc;

  /// No description provided for @stgbChannelCategoriesSections.
  ///
  /// In en, this message translates to:
  /// **'Channel Categories & Sections'**
  String get stgbChannelCategoriesSections;

  /// No description provided for @stgbToggleLiveTvRows.
  ///
  /// In en, this message translates to:
  /// **'Toggle visibility of Live TV rows'**
  String get stgbToggleLiveTvRows;

  /// No description provided for @stgbResetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get stgbResetAll;

  /// No description provided for @stgbPortalCardStyle.
  ///
  /// In en, this message translates to:
  /// **'Portal Card Display Style'**
  String get stgbPortalCardStyle;

  /// No description provided for @stgbShowPortalExpiry.
  ///
  /// In en, this message translates to:
  /// **'Show Portal Expiry Date'**
  String get stgbShowPortalExpiry;

  /// No description provided for @stgbShowPortalExpiryDesc.
  ///
  /// In en, this message translates to:
  /// **'Display subscription expiration tag on portal cards'**
  String get stgbShowPortalExpiryDesc;

  /// No description provided for @stgbShowMaxConnections.
  ///
  /// In en, this message translates to:
  /// **'Show Max Active Connections Tag'**
  String get stgbShowMaxConnections;

  /// No description provided for @stgbShowMaxConnectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Display current and max concurrent streaming connections'**
  String get stgbShowMaxConnectionsDesc;

  /// No description provided for @stgbDefaultStartingTab.
  ///
  /// In en, this message translates to:
  /// **'Default Starting Tab'**
  String get stgbDefaultStartingTab;

  /// No description provided for @stgbChannelStreamLayout.
  ///
  /// In en, this message translates to:
  /// **'Channel Stream Layout Mode'**
  String get stgbChannelStreamLayout;

  /// No description provided for @stgbGridStreamColumns.
  ///
  /// In en, this message translates to:
  /// **'Grid Stream Columns'**
  String get stgbGridStreamColumns;

  /// No description provided for @stgbCategorySidebarWidth.
  ///
  /// In en, this message translates to:
  /// **'Category Sidebar Width'**
  String get stgbCategorySidebarWidth;

  /// No description provided for @stgbShowChannelLogos.
  ///
  /// In en, this message translates to:
  /// **'Show Channel Stream Logos'**
  String get stgbShowChannelLogos;

  /// No description provided for @stgbShowChannelLogosDesc.
  ///
  /// In en, this message translates to:
  /// **'Display channel poster and logos in stream rows'**
  String get stgbShowChannelLogosDesc;

  /// No description provided for @stgbShowEpgNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Show EPG \"Now Playing\" Snippet'**
  String get stgbShowEpgNowPlaying;

  /// No description provided for @stgbShowEpgNowPlayingDesc.
  ///
  /// In en, this message translates to:
  /// **'Display current television guide title below channel'**
  String get stgbShowEpgNowPlayingDesc;

  /// No description provided for @stgbShowCategoryCounts.
  ///
  /// In en, this message translates to:
  /// **'Show Category Stream Counts'**
  String get stgbShowCategoryCounts;

  /// No description provided for @stgbShowCategoryCountsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show number of available streams next to category names'**
  String get stgbShowCategoryCountsDesc;

  /// No description provided for @stgbIncludeFreePublicSources.
  ///
  /// In en, this message translates to:
  /// **'Include Free Public Sources'**
  String get stgbIncludeFreePublicSources;

  /// No description provided for @stgbIncludeFreePublicSourcesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add public M3U playlists (e.g. iptv-org) to a channel\'s stream list'**
  String get stgbIncludeFreePublicSourcesDesc;

  /// No description provided for @stgbDiscoveryPosterCards.
  ///
  /// In en, this message translates to:
  /// **'DISCOVERY & POSTER CARDS'**
  String get stgbDiscoveryPosterCards;

  /// No description provided for @stgbMangaReaderViewer.
  ///
  /// In en, this message translates to:
  /// **'MANGA READER & CHAPTER VIEWER'**
  String get stgbMangaReaderViewer;

  /// No description provided for @stgbEnableMovingLighting.
  ///
  /// In en, this message translates to:
  /// **'Enable Moving Ambient Lighting'**
  String get stgbEnableMovingLighting;

  /// No description provided for @stgbShowContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Show \"Continue Reading\" Slider'**
  String get stgbShowContinueReading;

  /// No description provided for @stgbShowContinueReadingDesc.
  ///
  /// In en, this message translates to:
  /// **'Display your active reading history at the top of the Manga page'**
  String get stgbShowContinueReadingDesc;

  /// No description provided for @stgbMangaCardDensity.
  ///
  /// In en, this message translates to:
  /// **'Manga Poster Card Density'**
  String get stgbMangaCardDensity;

  /// No description provided for @stgbShowContentTypeBadge.
  ///
  /// In en, this message translates to:
  /// **'Show Content Type Badge (Manga/Manhwa)'**
  String get stgbShowContentTypeBadge;

  /// No description provided for @stgbShowPublicationYear.
  ///
  /// In en, this message translates to:
  /// **'Show Publication Year on Cards'**
  String get stgbShowPublicationYear;

  /// No description provided for @stgbPosterHoverGlow.
  ///
  /// In en, this message translates to:
  /// **'Poster Card Hover Glow Effect'**
  String get stgbPosterHoverGlow;

  /// No description provided for @stgbShowDesktopScrollTrack.
  ///
  /// In en, this message translates to:
  /// **'Show Desktop Scroll Track'**
  String get stgbShowDesktopScrollTrack;

  /// No description provided for @stgbDefaultReadingMode.
  ///
  /// In en, this message translates to:
  /// **'Default Reading Mode'**
  String get stgbDefaultReadingMode;

  /// No description provided for @stgbPageWidthConstraint.
  ///
  /// In en, this message translates to:
  /// **'Page Reading Width Constraint'**
  String get stgbPageWidthConstraint;

  /// No description provided for @stgbReaderBgAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Reader Background Atmosphere'**
  String get stgbReaderBgAtmosphere;

  /// No description provided for @stgbControlToolbarStyle.
  ///
  /// In en, this message translates to:
  /// **'Control Toolbar Style'**
  String get stgbControlToolbarStyle;

  /// No description provided for @stgbVerticalPageGap.
  ///
  /// In en, this message translates to:
  /// **'Vertical Page Gap'**
  String get stgbVerticalPageGap;

  /// No description provided for @stgbShowPageThumbnails.
  ///
  /// In en, this message translates to:
  /// **'Show Page Deck / Thumbnail Previews'**
  String get stgbShowPageThumbnails;

  /// No description provided for @stgbShowPageThumbnailsDesc.
  ///
  /// In en, this message translates to:
  /// **'Interactive visual tray of thumbnail previews for instant page jumping'**
  String get stgbShowPageThumbnailsDesc;

  /// No description provided for @stgbShowPageScrubber.
  ///
  /// In en, this message translates to:
  /// **'Show Page Scrubber Slider'**
  String get stgbShowPageScrubber;

  /// No description provided for @stgbEnableNextChapterPreview.
  ///
  /// In en, this message translates to:
  /// **'Enable Next Chapter Preview Card Deck'**
  String get stgbEnableNextChapterPreview;

  /// No description provided for @stgbEnableNextChapterPreviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Rich glass deck card at the end of each chapter with chapter art and direct launch'**
  String get stgbEnableNextChapterPreviewDesc;

  /// No description provided for @stgbMusicPlayerStudio.
  ///
  /// In en, this message translates to:
  /// **'Music Player Studio'**
  String get stgbMusicPlayerStudio;

  /// No description provided for @stgbCustomMusicStudio.
  ///
  /// In en, this message translates to:
  /// **'Custom Music Player Studio'**
  String get stgbCustomMusicStudio;

  /// No description provided for @stgbMusicStudioDesc.
  ///
  /// In en, this message translates to:
  /// **'Design the fullscreen player, drag components, customize physics & liquid glass'**
  String get stgbMusicStudioDesc;

  /// No description provided for @stgbApplyActive.
  ///
  /// In en, this message translates to:
  /// **'Apply Active'**
  String get stgbApplyActive;

  /// No description provided for @stgbFullscreenLiveStudio.
  ///
  /// In en, this message translates to:
  /// **'FULLSCREEN LIVE STUDIO'**
  String get stgbFullscreenLiveStudio;

  /// No description provided for @stgbSyncedLyrics.
  ///
  /// In en, this message translates to:
  /// **'Synced Lyrics'**
  String get stgbSyncedLyrics;

  /// No description provided for @stgbPlayingQueue.
  ///
  /// In en, this message translates to:
  /// **'Playing Queue'**
  String get stgbPlayingQueue;

  /// No description provided for @stgbSyncedLyricsSandbox.
  ///
  /// In en, this message translates to:
  /// **'Synced Lyrics Sandbox'**
  String get stgbSyncedLyricsSandbox;

  /// No description provided for @stgbPlayingQueueSandbox.
  ///
  /// In en, this message translates to:
  /// **'Playing Queue Sandbox (4 Tracks)'**
  String get stgbPlayingQueueSandbox;

  /// No description provided for @stgbArtworkTurntable.
  ///
  /// In en, this message translates to:
  /// **'Artwork & Turntable'**
  String get stgbArtworkTurntable;

  /// No description provided for @stgbAlbumArtTurntable.
  ///
  /// In en, this message translates to:
  /// **'Album Art & Vinyl Turntable'**
  String get stgbAlbumArtTurntable;

  /// No description provided for @stgbTrackArtistAlbum.
  ///
  /// In en, this message translates to:
  /// **'Track, Artist & Album Titles'**
  String get stgbTrackArtistAlbum;

  /// No description provided for @stgbTrackTitleQuality.
  ///
  /// In en, this message translates to:
  /// **'Track Title & Quality Badge'**
  String get stgbTrackTitleQuality;

  /// No description provided for @stgbLosslessQualityBadge.
  ///
  /// In en, this message translates to:
  /// **'Lossless Hi-Res Audio Quality Badge'**
  String get stgbLosslessQualityBadge;

  /// No description provided for @stgbPrimaryControlsMusic.
  ///
  /// In en, this message translates to:
  /// **'Primary Controls (Play, Pause, Skip, Shuffle, Repeat)'**
  String get stgbPrimaryControlsMusic;

  /// No description provided for @stgbSecondaryControlsMusic.
  ///
  /// In en, this message translates to:
  /// **'Secondary Controls (Volume Slider)'**
  String get stgbSecondaryControlsMusic;

  /// No description provided for @stgbLyricsQueueButtons.
  ///
  /// In en, this message translates to:
  /// **'Synced Lyrics & Queue Quick Buttons'**
  String get stgbLyricsQueueButtons;

  /// No description provided for @stgbFullscreenArranger.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen Player Drag & Drop Arranger'**
  String get stgbFullscreenArranger;

  /// No description provided for @stgbFullscreenArrangerDesc.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag any block to reorder the layout of your fullscreen player in real-time.'**
  String get stgbFullscreenArrangerDesc;

  /// No description provided for @stgbSeekBarScrubberEngine.
  ///
  /// In en, this message translates to:
  /// **'Seek Bar Canvas Scrubber Engine'**
  String get stgbSeekBarScrubberEngine;

  /// No description provided for @stgbSeekBarScrubberEngineDesc.
  ///
  /// In en, this message translates to:
  /// **'Select how audio waveforms and scrubbing tracks render across your music player.'**
  String get stgbSeekBarScrubberEngineDesc;

  /// No description provided for @stgbPlayButtonAesthetic.
  ///
  /// In en, this message translates to:
  /// **'Play Button Aesthetic & Style'**
  String get stgbPlayButtonAesthetic;

  /// No description provided for @stgbHoverTouchPhysicsEngine.
  ///
  /// In en, this message translates to:
  /// **'Hover & Touch Physics Engine'**
  String get stgbHoverTouchPhysicsEngine;

  /// No description provided for @stgbHoverTouchPhysicsEngineDesc.
  ///
  /// In en, this message translates to:
  /// **'Select the interactive physics feedback applied when hovering or pressing controls.'**
  String get stgbHoverTouchPhysicsEngineDesc;

  /// No description provided for @stgbLivePhysicsTestPad.
  ///
  /// In en, this message translates to:
  /// **'Live Physics Testing Pad'**
  String get stgbLivePhysicsTestPad;

  /// No description provided for @stgbArtworkTurntablePresentation.
  ///
  /// In en, this message translates to:
  /// **'Artwork & Turntable Presentation'**
  String get stgbArtworkTurntablePresentation;

  /// No description provided for @stgbArtworkTurntablePresentationDesc.
  ///
  /// In en, this message translates to:
  /// **'Select how album covers, vinyl turntable animations, and cards display in the player.'**
  String get stgbArtworkTurntablePresentationDesc;

  /// No description provided for @stgbVisualThemePalette.
  ///
  /// In en, this message translates to:
  /// **'VISUAL THEME PALETTE'**
  String get stgbVisualThemePalette;

  /// No description provided for @stgbAmbientAtmosphereGlow.
  ///
  /// In en, this message translates to:
  /// **'AMBIENT ATMOSPHERE & GLOW'**
  String get stgbAmbientAtmosphereGlow;

  /// No description provided for @stgbDiscoveryCatalogConfig.
  ///
  /// In en, this message translates to:
  /// **'DISCOVERY & CATALOG CONFIGURATION'**
  String get stgbDiscoveryCatalogConfig;

  /// No description provided for @stgbFullscreenPlayerPresets.
  ///
  /// In en, this message translates to:
  /// **'FULLSCREEN PLAYER PRESETS'**
  String get stgbFullscreenPlayerPresets;

  /// No description provided for @stgbCustomPlayerEngineDesigner.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM PLAYER ENGINE DESIGNER'**
  String get stgbCustomPlayerEngineDesigner;

  /// No description provided for @stgbMovingBgAmbientLighting.
  ///
  /// In en, this message translates to:
  /// **'Moving Background Ambient Lighting'**
  String get stgbMovingBgAmbientLighting;

  /// No description provided for @stgbMovingBgAmbientLightingDesc.
  ///
  /// In en, this message translates to:
  /// **'Dynamic moving glowing orbs reacting with your theme accent colors'**
  String get stgbMovingBgAmbientLightingDesc;

  /// No description provided for @stgbAmbientLightPattern.
  ///
  /// In en, this message translates to:
  /// **'Ambient Light Pattern'**
  String get stgbAmbientLightPattern;

  /// No description provided for @stgbShowHeroShowcase.
  ///
  /// In en, this message translates to:
  /// **'Show Hero Spotlight Showcase'**
  String get stgbShowHeroShowcase;

  /// No description provided for @stgbMusicHeroDesc.
  ///
  /// In en, this message translates to:
  /// **'Featured bestselling album & track showcase at the top of the music page'**
  String get stgbMusicHeroDesc;

  /// No description provided for @stgbShowLosslessBadges.
  ///
  /// In en, this message translates to:
  /// **'Show Lossless Hi-Res Audio Badges'**
  String get stgbShowLosslessBadges;

  /// No description provided for @stgbShowLosslessBadgesDesc.
  ///
  /// In en, this message translates to:
  /// **'Displays FLAC / Hi-Res lossless stream indicators on music cards and player'**
  String get stgbShowLosslessBadgesDesc;

  /// No description provided for @stgbMusicCardDensity.
  ///
  /// In en, this message translates to:
  /// **'Music Card & Grid Density'**
  String get stgbMusicCardDensity;

  /// No description provided for @stgbFullPlayerEngine.
  ///
  /// In en, this message translates to:
  /// **'FULL PLAYER ENGINE'**
  String get stgbFullPlayerEngine;

  /// No description provided for @stgbCustomizeFullscreenDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize the Fullscreen Player. Drag & drop blocks, waveform equalizers, vinyl turntable & liquid glass buttons.'**
  String get stgbCustomizeFullscreenDesc;

  /// No description provided for @stgbLiveWaveformPreview.
  ///
  /// In en, this message translates to:
  /// **'Live Waveform & Controls Preview'**
  String get stgbLiveWaveformPreview;

  /// No description provided for @stgbOpenFullStudio.
  ///
  /// In en, this message translates to:
  /// **'Open Full Studio ➔'**
  String get stgbOpenFullStudio;

  /// No description provided for @tv2RemovedStreamFeeds.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} stream feed(s)'**
  String tv2RemovedStreamFeeds(Object count);

  /// No description provided for @tv2SearchChannelsHint.
  ///
  /// In en, this message translates to:
  /// **'Search {count} channels (e.g. 1080p, 4K, feed name)...'**
  String tv2SearchChannelsHint(Object count);

  /// No description provided for @tv2DeleteSelectedFeeds.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String tv2DeleteSelectedFeeds(Object count);

  /// No description provided for @tv2FoundFeedsOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Found {found} of {total} feeds'**
  String tv2FoundFeedsOfTotal(Object found, Object total);

  /// No description provided for @tv2LiveFeedsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} live stream feeds available'**
  String tv2LiveFeedsAvailable(Object count);

  /// No description provided for @tv2NoFeedsMatch.
  ///
  /// In en, this message translates to:
  /// **'No feeds match \"{query}\"'**
  String tv2NoFeedsMatch(Object query);

  /// No description provided for @tv2ServerNumber.
  ///
  /// In en, this message translates to:
  /// **'Server {number}'**
  String tv2ServerNumber(Object number);

  /// No description provided for @tv2ChannelsCountCaps.
  ///
  /// In en, this message translates to:
  /// **'{count} CHANNELS'**
  String tv2ChannelsCountCaps(Object count);

  /// No description provided for @tv2Add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tv2Add;

  /// No description provided for @tv2FeedStopped.
  ///
  /// In en, this message translates to:
  /// **'This feed stopped: {error}'**
  String tv2FeedStopped(Object error);

  /// No description provided for @tv2BufferingName.
  ///
  /// In en, this message translates to:
  /// **'Buffering {name}…'**
  String tv2BufferingName(Object name);

  /// No description provided for @tv2NoOtherSource.
  ///
  /// In en, this message translates to:
  /// **'{reason} No other source for this channel.'**
  String tv2NoOtherSource(Object reason);

  /// No description provided for @tv2AllSourcesFailed.
  ///
  /// In en, this message translates to:
  /// **'All {count} sources for this channel failed.'**
  String tv2AllSourcesFailed(Object count);

  /// No description provided for @tv2SourcesFailedInRow.
  ///
  /// In en, this message translates to:
  /// **'{count} sources failed in a row. Pick another source from the list.'**
  String tv2SourcesFailedInRow(Object count);

  /// No description provided for @tv2AspectMode.
  ///
  /// In en, this message translates to:
  /// **'ASPECT: {mode}'**
  String tv2AspectMode(Object mode);

  /// No description provided for @tv2ChannelPosition.
  ///
  /// In en, this message translates to:
  /// **'Channel {current}/{total} · {portal}'**
  String tv2ChannelPosition(Object current, Object total, Object portal);

  /// No description provided for @tv2SourcePosition.
  ///
  /// In en, this message translates to:
  /// **'Source {current}/{total} · {portal}'**
  String tv2SourcePosition(Object current, Object total, Object portal);

  /// No description provided for @tv2TryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tv2TryAgain;

  /// No description provided for @tv2RemovedPortals.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} portal(s)'**
  String tv2RemovedPortals(Object count);

  /// No description provided for @tv2RemovedAllPortals.
  ///
  /// In en, this message translates to:
  /// **'Removed all {count} portals'**
  String tv2RemovedAllPortals(Object count);

  /// No description provided for @tv2RemovedPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} playlist(s)'**
  String tv2RemovedPlaylists(Object count);

  /// No description provided for @tv2RemovedAllPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Removed all {count} playlists'**
  String tv2RemovedAllPlaylists(Object count);

  /// No description provided for @tv2XtreamPanelsCount.
  ///
  /// In en, this message translates to:
  /// **'Xtream Panels ({count})'**
  String tv2XtreamPanelsCount(Object count);

  /// No description provided for @tv2M3uPlaylistsCount.
  ///
  /// In en, this message translates to:
  /// **'M3U Playlists ({count})'**
  String tv2M3uPlaylistsCount(Object count);

  /// No description provided for @tv2DeleteSelectedPortals.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String tv2DeleteSelectedPortals(Object count);

  /// No description provided for @tv2AllPortalsCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String tv2AllPortalsCount(Object count);

  /// No description provided for @tv2MyPortalsCount.
  ///
  /// In en, this message translates to:
  /// **'My Portals ({count})'**
  String tv2MyPortalsCount(Object count);

  /// No description provided for @tv2FavoritesStarCount.
  ///
  /// In en, this message translates to:
  /// **'Favorites ⭐ ({count})'**
  String tv2FavoritesStarCount(Object count);

  /// No description provided for @tv2NoVerifiedPortalsHint.
  ///
  /// In en, this message translates to:
  /// **'No verified portals. Tap \"Generate Portals\" ({source}) to auto-discover.'**
  String tv2NoVerifiedPortalsHint(Object source);

  /// No description provided for @tv2NoPortalsInFilter.
  ///
  /// In en, this message translates to:
  /// **'No portals found in \"{filter}\" filter.'**
  String tv2NoPortalsInFilter(Object filter);

  /// No description provided for @tv2CopiedText.
  ///
  /// In en, this message translates to:
  /// **'Copied: {text}'**
  String tv2CopiedText(Object text);

  /// No description provided for @tv2ExpShort.
  ///
  /// In en, this message translates to:
  /// **'Exp: {expiry}'**
  String tv2ExpShort(Object expiry);

  /// No description provided for @tv2ConnShort.
  ///
  /// In en, this message translates to:
  /// **'Conn: {active}/{max}'**
  String tv2ConnShort(Object active, Object max);

  /// No description provided for @tv2DeleteSelectedPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String tv2DeleteSelectedPlaylists(Object count);

  /// No description provided for @tv2PlaylistChannelsSource.
  ///
  /// In en, this message translates to:
  /// **'{count} channels {source}'**
  String tv2PlaylistChannelsSource(Object count, Object source);

  /// No description provided for @tv2XtreamPanels.
  ///
  /// In en, this message translates to:
  /// **'Xtream Panels'**
  String get tv2XtreamPanels;

  /// No description provided for @tv2M3uPlaylists.
  ///
  /// In en, this message translates to:
  /// **'M3U Playlists'**
  String get tv2M3uPlaylists;

  /// No description provided for @tv2VerifyAndSave.
  ///
  /// In en, this message translates to:
  /// **'Verify & Save'**
  String get tv2VerifyAndSave;

  /// No description provided for @tv2FetchAndSave.
  ///
  /// In en, this message translates to:
  /// **'Fetch & Save'**
  String get tv2FetchAndSave;

  /// No description provided for @tv2GridColumns.
  ///
  /// In en, this message translates to:
  /// **'{cols} Cols'**
  String tv2GridColumns(Object cols);

  /// No description provided for @tv2FailedLoadContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load content: {error}'**
  String tv2FailedLoadContent(Object error);

  /// No description provided for @tv2NoPlayableStreamNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has no playable stream. Reconnect the portal or remove it and add another.'**
  String tv2NoPlayableStreamNamed(Object name);

  /// No description provided for @tv2CategoriesTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String tv2CategoriesTotal(Object count);

  /// No description provided for @tv2ExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry: {expiry}'**
  String tv2ExpiryLabel(Object expiry);

  /// No description provided for @tv2ConnectionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Connections: {active}/{max}'**
  String tv2ConnectionsLabel(Object active, Object max);

  /// No description provided for @tv2StopHealthCheck.
  ///
  /// In en, this message translates to:
  /// **'Stop ({checked}/{total})'**
  String tv2StopHealthCheck(Object checked, Object total);

  /// No description provided for @tv2ConnAndExpiry.
  ///
  /// In en, this message translates to:
  /// **'Conn: {active}/{max} • {expiry}'**
  String tv2ConnAndExpiry(Object active, Object max, Object expiry);

  /// No description provided for @tv2NoStreamsMatching.
  ///
  /// In en, this message translates to:
  /// **'No streams matching \"{query}\"'**
  String tv2NoStreamsMatching(Object query);

  /// No description provided for @tv2SeriesEpisodes.
  ///
  /// In en, this message translates to:
  /// **'{series} Episodes'**
  String tv2SeriesEpisodes(Object series);

  /// No description provided for @tv2EpisodeNumber.
  ///
  /// In en, this message translates to:
  /// **'Episode {episode}'**
  String tv2EpisodeNumber(Object episode);

  /// No description provided for @tv2AllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get tv2AllCategories;

  /// No description provided for @tv2NowAiringOn.
  ///
  /// In en, this message translates to:
  /// **'Now Airing on {channel}'**
  String tv2NowAiringOn(Object channel);

  /// No description provided for @tv2GuideProgress.
  ///
  /// In en, this message translates to:
  /// **'{start} – {stop} · {minutes} mins elapsed ({percent}% complete)'**
  String tv2GuideProgress(
    Object start,
    Object stop,
    Object minutes,
    Object percent,
  );

  /// No description provided for @ani2ResumeEpModal.
  ///
  /// In en, this message translates to:
  /// **'Resume Ep {episode}'**
  String ani2ResumeEpModal(Object episode);

  /// No description provided for @ani2TotalEpsModal.
  ///
  /// In en, this message translates to:
  /// **'({count} total)'**
  String ani2TotalEpsModal(Object count);

  /// No description provided for @ani2SubCapsModal.
  ///
  /// In en, this message translates to:
  /// **'SUB'**
  String get ani2SubCapsModal;

  /// No description provided for @ani2DubCapsModal.
  ///
  /// In en, this message translates to:
  /// **'DUB'**
  String get ani2DubCapsModal;

  /// No description provided for @ani2ResumeEp.
  ///
  /// In en, this message translates to:
  /// **'Resume Ep {episode}'**
  String ani2ResumeEp(Object episode);

  /// No description provided for @ani2TotalEps.
  ///
  /// In en, this message translates to:
  /// **'({count} total)'**
  String ani2TotalEps(Object count);

  /// No description provided for @ani2SubCaps.
  ///
  /// In en, this message translates to:
  /// **'SUB'**
  String get ani2SubCaps;

  /// No description provided for @ani2DubCaps.
  ///
  /// In en, this message translates to:
  /// **'DUB'**
  String get ani2DubCaps;

  /// No description provided for @ani2CurrentlyAiringHits.
  ///
  /// In en, this message translates to:
  /// **'Currently airing hits · {season}'**
  String ani2CurrentlyAiringHits(Object season);

  /// No description provided for @ani2EpisodesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Episodes'**
  String ani2EpisodesCount(Object count);

  /// No description provided for @ani2SortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort: {sort}'**
  String ani2SortLabel(Object sort);

  /// No description provided for @ani2TvSeriesResults.
  ///
  /// In en, this message translates to:
  /// **'{count} Results'**
  String ani2TvSeriesResults(Object count);

  /// No description provided for @ani2MoviesResults.
  ///
  /// In en, this message translates to:
  /// **'{count} Results'**
  String ani2MoviesResults(Object count);

  /// No description provided for @ani2OvasResults.
  ///
  /// In en, this message translates to:
  /// **'{count} Results'**
  String ani2OvasResults(Object count);

  /// No description provided for @ani2NoPlayableStreamsEp.
  ///
  /// In en, this message translates to:
  /// **'No playable streams found for Episode {episode}.'**
  String ani2NoPlayableStreamsEp(Object episode);

  /// No description provided for @ani2TitleEpisode.
  ///
  /// In en, this message translates to:
  /// **'{title} - Episode {episode}'**
  String ani2TitleEpisode(Object title, Object episode);

  /// No description provided for @ani2NoCategorySources.
  ///
  /// In en, this message translates to:
  /// **'No {category} sources found.'**
  String ani2NoCategorySources(Object category);

  /// No description provided for @ani2Sub.
  ///
  /// In en, this message translates to:
  /// **'Sub'**
  String get ani2Sub;

  /// No description provided for @ani2Dub.
  ///
  /// In en, this message translates to:
  /// **'Dub'**
  String get ani2Dub;

  /// No description provided for @ai2FailedGenerateRecs.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate recommendations: {error}'**
  String ai2FailedGenerateRecs(Object error);

  /// No description provided for @ai2RatedOfThree.
  ///
  /// In en, this message translates to:
  /// **'{rated}/3 rated'**
  String ai2RatedOfThree(Object rated);

  /// No description provided for @ai2DiscoverRecsCount.
  ///
  /// In en, this message translates to:
  /// **'Discover Recommendations ({count} Titles)'**
  String ai2DiscoverRecsCount(Object count);

  /// No description provided for @ai2TitleNumber.
  ///
  /// In en, this message translates to:
  /// **'Title #{number}'**
  String ai2TitleNumber(Object number);

  /// No description provided for @ai2CinemaPicksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cinema picks tailored to your taste profile'**
  String ai2CinemaPicksCount(Object count);

  /// No description provided for @ai2MatchPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String ai2MatchPercent(Object percent);

  /// No description provided for @ply2VideoTrack.
  ///
  /// In en, this message translates to:
  /// **'Video {id}'**
  String ply2VideoTrack(Object id);

  /// No description provided for @ply2SubtitleTrack.
  ///
  /// In en, this message translates to:
  /// **'Subtitle {index}'**
  String ply2SubtitleTrack(Object index);

  /// No description provided for @ply2ErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String ply2ErrorPrefix(Object error);

  /// No description provided for @ply2DebridTryingAnother.
  ///
  /// In en, this message translates to:
  /// **'{service} {notice} • Trying another'**
  String ply2DebridTryingAnother(Object service, Object notice);

  /// No description provided for @ply2TrackNumber.
  ///
  /// In en, this message translates to:
  /// **'Track {number}'**
  String ply2TrackNumber(Object number);

  /// No description provided for @ply2SwitchedEmbeddedSub.
  ///
  /// In en, this message translates to:
  /// **'Switched to embedded subtitle: {title}'**
  String ply2SwitchedEmbeddedSub(Object title);

  /// No description provided for @ply2DownloadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading {language} subtitle...'**
  String ply2DownloadingSubtitle(Object language);

  /// No description provided for @ply2SubtitleLoaded.
  ///
  /// In en, this message translates to:
  /// **'{language} subtitle loaded ({lines} lines)'**
  String ply2SubtitleLoaded(Object language, Object lines);

  /// No description provided for @ply2CouldNotLoadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load subtitle: {error}'**
  String ply2CouldNotLoadSubtitle(Object error);

  /// No description provided for @ply2PlaybackErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Playback error: {error}'**
  String ply2PlaybackErrorMsg(Object error);

  /// No description provided for @ply2SelectAnotherSourceBelow.
  ///
  /// In en, this message translates to:
  /// **'{message} Please select another source below.'**
  String ply2SelectAnotherSourceBelow(Object message);

  /// No description provided for @ply2BufferingEpisode.
  ///
  /// In en, this message translates to:
  /// **'Buffering S{season}:E{episode} - {title}...'**
  String ply2BufferingEpisode(Object season, Object episode, Object title);

  /// No description provided for @ply2DownloadFailedStart.
  ///
  /// In en, this message translates to:
  /// **'Download failed to start: {error}'**
  String ply2DownloadFailedStart(Object error);

  /// No description provided for @ply2PartWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Part {part}{title}'**
  String ply2PartWithTitle(Object part, Object title);

  /// No description provided for @ply2TrackIdx.
  ///
  /// In en, this message translates to:
  /// **'Track {index}'**
  String ply2TrackIdx(Object index);

  /// No description provided for @ply2AudioSyncOffset.
  ///
  /// In en, this message translates to:
  /// **'AUDIO SYNC: {sign}{seconds}s'**
  String ply2AudioSyncOffset(Object sign, Object seconds);

  /// No description provided for @ply2PartCaps.
  ///
  /// In en, this message translates to:
  /// **'PART {part}'**
  String ply2PartCaps(Object part);

  /// No description provided for @mnz2StreamUrlFor.
  ///
  /// In en, this message translates to:
  /// **'Stream URL for {name}'**
  String mnz2StreamUrlFor(Object name);

  /// No description provided for @mnz2ActiveStreams.
  ///
  /// In en, this message translates to:
  /// **'{count} Stream(s)'**
  String mnz2ActiveStreams(Object count);

  /// No description provided for @mnz2CustomUrl.
  ///
  /// In en, this message translates to:
  /// **'Custom URL'**
  String get mnz2CustomUrl;

  /// No description provided for @dsc2NoCatalogsForType.
  ///
  /// In en, this message translates to:
  /// **'No catalogs available for \"{type}\"'**
  String dsc2NoCatalogsForType(Object type);

  /// No description provided for @dsc2CatalogRequiresSelecting.
  ///
  /// In en, this message translates to:
  /// **'This catalog requires selecting {fields} before loading titles.'**
  String dsc2CatalogRequiresSelecting(Object fields);

  /// No description provided for @dsc2SelectExtra.
  ///
  /// In en, this message translates to:
  /// **'Select {first}{rest}'**
  String dsc2SelectExtra(Object first, Object rest);

  /// No description provided for @dsc2EnterExtra.
  ///
  /// In en, this message translates to:
  /// **'Enter {name}'**
  String dsc2EnterExtra(Object name);

  /// No description provided for @dsc2EnterExtraName.
  ///
  /// In en, this message translates to:
  /// **'Enter {name}'**
  String dsc2EnterExtraName(Object name);

  /// No description provided for @dsc2TypeExtraHere.
  ///
  /// In en, this message translates to:
  /// **'Type {name} here...'**
  String dsc2TypeExtraHere(Object name);

  /// No description provided for @dsc2AllExtra.
  ///
  /// In en, this message translates to:
  /// **'All {name}'**
  String dsc2AllExtra(Object name);

  /// No description provided for @dsc2SearchWithinCatalog.
  ///
  /// In en, this message translates to:
  /// **'Search within {catalog}...'**
  String dsc2SearchWithinCatalog(Object catalog);

  /// No description provided for @dsc2GenreQuery.
  ///
  /// In en, this message translates to:
  /// **'Genre: {query}'**
  String dsc2GenreQuery(Object query);

  /// No description provided for @dsc2SearchQuery.
  ///
  /// In en, this message translates to:
  /// **'Search: {query}'**
  String dsc2SearchQuery(Object query);

  /// No description provided for @dsc2NoResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String dsc2NoResultsFor(Object query);

  /// No description provided for @dsc2Apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get dsc2Apply;

  /// No description provided for @dl3EpisodeNumber.
  ///
  /// In en, this message translates to:
  /// **'Episode {episode}'**
  String dl3EpisodeNumber(Object episode);

  /// No description provided for @dl3ConfirmDeleteTask.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\" and remove the file from storage?'**
  String dl3ConfirmDeleteTask(Object title);

  /// No description provided for @dl3ActiveAndDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{active} active • {completed} downloaded'**
  String dl3ActiveAndDownloaded(Object active, Object completed);

  /// No description provided for @dl3FolderPath.
  ///
  /// In en, this message translates to:
  /// **'Folder path: {path}'**
  String dl3FolderPath(Object path);

  /// No description provided for @dl3PeersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} peers'**
  String dl3PeersCount(Object count);

  /// No description provided for @dl3FailedReason.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String dl3FailedReason(Object error);

  /// No description provided for @dl3PausedPercent.
  ///
  /// In en, this message translates to:
  /// **'Paused ({percent}%)'**
  String dl3PausedPercent(Object percent);

  /// No description provided for @dl3ProgressSpeedEta.
  ///
  /// In en, this message translates to:
  /// **'{percent}% • {speed} • ETA: {eta}'**
  String dl3ProgressSpeedEta(Object percent, Object speed, Object eta);

  /// No description provided for @dl3FolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Folder: {path}'**
  String dl3FolderLabel(Object path);

  /// No description provided for @dl3PathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path: {path}'**
  String dl3PathLabel(Object path);

  /// No description provided for @dl3EpisodeOffline.
  ///
  /// In en, this message translates to:
  /// **'S{season}:E{episode} • Offline'**
  String dl3EpisodeOffline(Object season, Object episode);

  /// No description provided for @dl3YearOffline.
  ///
  /// In en, this message translates to:
  /// **'{year} • Offline'**
  String dl3YearOffline(Object year);

  /// No description provided for @dl3DeviceStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Device Storage: {used} Used of {total}'**
  String dl3DeviceStorageUsed(Object used, Object total);

  /// No description provided for @dl3FreeSpace.
  ///
  /// In en, this message translates to:
  /// **'{free} Free'**
  String dl3FreeSpace(Object free);

  /// No description provided for @cal2NoEpisodesOnNetwork.
  ///
  /// In en, this message translates to:
  /// **'No episodes on {network} for this day'**
  String cal2NoEpisodesOnNetwork(Object network);

  /// No description provided for @cal2EpisodesAiring.
  ///
  /// In en, this message translates to:
  /// **'{count} Episodes Airing'**
  String cal2EpisodesAiring(Object count);

  /// No description provided for @cal2ShowAllNetworks.
  ///
  /// In en, this message translates to:
  /// **'Show All Networks'**
  String get cal2ShowAllNetworks;

  /// No description provided for @ctl2SelectExtra.
  ///
  /// In en, this message translates to:
  /// **'Select {name}'**
  String ctl2SelectExtra(Object name);

  /// No description provided for @ctl2AllExtra.
  ///
  /// In en, this message translates to:
  /// **'All {name}'**
  String ctl2AllExtra(Object name);

  /// No description provided for @ara2FailedLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load anime details: {error}'**
  String ara2FailedLoadDetails(Object error);

  /// No description provided for @ara2Retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ara2Retry;

  /// No description provided for @ara2NoArabicStreamsEp.
  ///
  /// In en, this message translates to:
  /// **'No playable Arabic streams found for Episode {episode}.'**
  String ara2NoArabicStreamsEp(Object episode);

  /// No description provided for @ara2FailedLoadArabicStreams.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Arabic streams: {error}'**
  String ara2FailedLoadArabicStreams(Object error);

  /// No description provided for @ara2TitleEpisode.
  ///
  /// In en, this message translates to:
  /// **'{title} - Episode {episode}'**
  String ara2TitleEpisode(Object title, Object episode);

  /// No description provided for @mus2AddedTrackToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added \"{track}\" to \"{playlist}\"'**
  String mus2AddedTrackToPlaylist(Object track, Object playlist);

  /// No description provided for @mus2CreatedPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Created playlist \"{name}\"'**
  String mus2CreatedPlaylist(Object name);

  /// No description provided for @mus2RemovedFromDownloads.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{title}\" from downloads'**
  String mus2RemovedFromDownloads(Object title);

  /// No description provided for @mus2AddedToDownloadQueue.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to download queue'**
  String mus2AddedToDownloadQueue(Object title);

  /// No description provided for @mus2RemovedFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Removed from \"{playlist}\"'**
  String mus2RemovedFromPlaylist(Object playlist);

  /// No description provided for @mus2AddedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to \"{playlist}\"'**
  String mus2AddedToPlaylist(Object playlist);

  /// No description provided for @mus2TracksTabCount.
  ///
  /// In en, this message translates to:
  /// **'Tracks ({count})'**
  String mus2TracksTabCount(Object count);

  /// No description provided for @mus2ArtistsTabCount.
  ///
  /// In en, this message translates to:
  /// **'Artists ({count})'**
  String mus2ArtistsTabCount(Object count);

  /// No description provided for @mus2AlbumsTabCount.
  ///
  /// In en, this message translates to:
  /// **'Albums ({count})'**
  String mus2AlbumsTabCount(Object count);

  /// No description provided for @mus2PlaylistsTabCount.
  ///
  /// In en, this message translates to:
  /// **'Playlists ({count})'**
  String mus2PlaylistsTabCount(Object count);

  /// No description provided for @mus2NoResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String mus2NoResultsFor(Object query);

  /// No description provided for @mus2FavouriteTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} favourite tracks'**
  String mus2FavouriteTracksCount(Object count);

  /// No description provided for @mus2QueueCount.
  ///
  /// In en, this message translates to:
  /// **'Queue ({count})'**
  String mus2QueueCount(Object count);

  /// No description provided for @mus2OfflineTracksSize.
  ///
  /// In en, this message translates to:
  /// **'{count} offline tracks • {size} MB'**
  String mus2OfflineTracksSize(Object count, Object size);

  /// No description provided for @mus2TrackNumber.
  ///
  /// In en, this message translates to:
  /// **'Track {number}'**
  String mus2TrackNumber(Object number);

  /// No description provided for @mus2DownloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String mus2DownloadingPercent(Object percent);

  /// No description provided for @mus2TracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Tracks'**
  String mus2TracksCount(Object count);

  /// No description provided for @mus2AddedAlbumTracksToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks from \"{album}\" to download queue'**
  String mus2AddedAlbumTracksToQueue(Object count, Object album);

  /// No description provided for @mus2CuratedByTracks.
  ///
  /// In en, this message translates to:
  /// **'Curated by {creator} • {count} tracks'**
  String mus2CuratedByTracks(Object creator, Object count);

  /// No description provided for @mus2AddedPlaylistTracksToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks from \"{playlist}\" to download queue'**
  String mus2AddedPlaylistTracksToQueue(Object count, Object playlist);

  /// No description provided for @mus2CustomPlaylistTracks.
  ///
  /// In en, this message translates to:
  /// **'Custom Playlist • {count} tracks'**
  String mus2CustomPlaylistTracks(Object count);

  /// No description provided for @mus2OfflineTracksStorage.
  ///
  /// In en, this message translates to:
  /// **'{count} offline tracks • {size} MB storage'**
  String mus2OfflineTracksStorage(Object count, Object size);

  /// No description provided for @mus2NoDownloadedTracksMatch.
  ///
  /// In en, this message translates to:
  /// **'No downloaded tracks match \"{query}\"'**
  String mus2NoDownloadedTracksMatch(Object query);

  /// No description provided for @mus2DeleteFromOfflineStorage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" from offline storage?'**
  String mus2DeleteFromOfflineStorage(Object title);

  /// No description provided for @mus2ExtractingStreamFor.
  ///
  /// In en, this message translates to:
  /// **'Extracting stream for \"{title}\"...'**
  String mus2ExtractingStreamFor(Object title);

  /// No description provided for @mus2DownloadingTrackPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading \"{title}\" ({percent}%)'**
  String mus2DownloadingTrackPercent(Object title, Object percent);

  /// No description provided for @mus2InQueueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in queue'**
  String mus2InQueueCount(Object count);

  /// No description provided for @mus2RadioStationsLiveStreams.
  ///
  /// In en, this message translates to:
  /// **'Radio Stations & Live Streams'**
  String get mus2RadioStationsLiveStreams;

  /// No description provided for @mus2ContinuousMusicChannels.
  ///
  /// In en, this message translates to:
  /// **'Continuous music channels tuned to your mood.'**
  String get mus2ContinuousMusicChannels;

  /// No description provided for @abk2FailedToLoadChapters.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chapters: {error}'**
  String abk2FailedToLoadChapters(Object error);

  /// No description provided for @abk2PreparingChapter.
  ///
  /// In en, this message translates to:
  /// **'Preparing {title}...'**
  String abk2PreparingChapter(Object title);

  /// No description provided for @abk2ResolvingAudioVia.
  ///
  /// In en, this message translates to:
  /// **'Resolving audio via {service} cloud...'**
  String abk2ResolvingAudioVia(Object service);

  /// No description provided for @abk2PlaybackErrorErr.
  ///
  /// In en, this message translates to:
  /// **'Playback Error: {error}'**
  String abk2PlaybackErrorErr(Object error);

  /// No description provided for @abk2PlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Playback Error: {error}'**
  String abk2PlaybackError(Object error);

  /// No description provided for @abk2ChapterNumber.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String abk2ChapterNumber(Object number);

  /// No description provided for @abk2ChapterOfTotalBook.
  ///
  /// In en, this message translates to:
  /// **'Chapter {current} of {total} • {book}'**
  String abk2ChapterOfTotalBook(Object current, Object total, Object book);

  /// No description provided for @abk2ChaptersCountUpper.
  ///
  /// In en, this message translates to:
  /// **'{count} CHAPTERS'**
  String abk2ChaptersCountUpper(Object count);

  /// No description provided for @abk2AudioPlayerStyleStudio.
  ///
  /// In en, this message translates to:
  /// **'Audio Player Style & Studio'**
  String get abk2AudioPlayerStyleStudio;

  /// No description provided for @abk2SelectPlayerDesignPreset.
  ///
  /// In en, this message translates to:
  /// **'Select Player Design Preset'**
  String get abk2SelectPlayerDesignPreset;

  /// No description provided for @abk2SeekBarScrubberStyle.
  ///
  /// In en, this message translates to:
  /// **'Seek Bar Scrubber Style'**
  String get abk2SeekBarScrubberStyle;

  /// No description provided for @abk2PlayPauseButtonStyle.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause Button Style'**
  String get abk2PlayPauseButtonStyle;

  /// No description provided for @abk2Autoplay.
  ///
  /// In en, this message translates to:
  /// **'Autoplay'**
  String get abk2Autoplay;

  /// No description provided for @abk2OpenChaptersPanel.
  ///
  /// In en, this message translates to:
  /// **'Open Chapters Panel'**
  String get abk2OpenChaptersPanel;

  /// No description provided for @abk2AudiobookChapters.
  ///
  /// In en, this message translates to:
  /// **'Audiobook Chapters'**
  String get abk2AudiobookChapters;

  /// No description provided for @abk2FailedToFetchAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch audiobooks: {error}'**
  String abk2FailedToFetchAudiobooks(Object error);

  /// No description provided for @abk2ChapterOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Chapter {current} of {total}'**
  String abk2ChapterOfTotal(Object current, Object total);

  /// No description provided for @abk2ResumeTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Resume ({remaining} left)'**
  String abk2ResumeTimeLeft(Object remaining);

  /// No description provided for @abk2VoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice: {voice}'**
  String abk2VoiceLabel(Object voice);

  /// No description provided for @abk2GeneratingPercent.
  ///
  /// In en, this message translates to:
  /// **'Generating {percent}%'**
  String abk2GeneratingPercent(Object percent);

  /// No description provided for @abk2AuthorLocal.
  ///
  /// In en, this message translates to:
  /// **'{author} • Local'**
  String abk2AuthorLocal(Object author);

  /// No description provided for @abk2ResumeChapterNumber.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String abk2ResumeChapterNumber(Object number);

  /// No description provided for @abk2PercentCompleted.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completed'**
  String abk2PercentCompleted(Object percent);

  /// No description provided for @abk2UploadedPartsGenerationStarted.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {count} parts — generation started in background!'**
  String abk2UploadedPartsGenerationStarted(Object count);

  /// No description provided for @abk2GenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed: {error}'**
  String abk2GenerationFailed(Object error);

  /// No description provided for @abk2RemoveFromGenerationList.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from the generation list?'**
  String abk2RemoveFromGenerationList(Object name);

  /// No description provided for @abk2SelectedAudioFiles.
  ///
  /// In en, this message translates to:
  /// **'Selected {count} audio file(s):'**
  String abk2SelectedAudioFiles(Object count);

  /// No description provided for @abk2GenerationQueueCompleted.
  ///
  /// In en, this message translates to:
  /// **'GENERATION QUEUE & COMPLETED ({count})'**
  String abk2GenerationQueueCompleted(Object count);

  /// No description provided for @abk2DownloadedBooksFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOADED BOOKS FROM LIBRARY ({count})'**
  String abk2DownloadedBooksFromLibrary(Object count);

  /// No description provided for @abk2FileSizeMb.
  ///
  /// In en, this message translates to:
  /// **'Size: {size} MB'**
  String abk2FileSizeMb(Object size);

  /// No description provided for @abk2SynthesizingPercent.
  ///
  /// In en, this message translates to:
  /// **'Synthesizing {percent}%'**
  String abk2SynthesizingPercent(Object percent);

  /// No description provided for @abk2JobVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice: {voice}'**
  String abk2JobVoiceLabel(Object voice);

  /// No description provided for @abk2ImportedAudiobooksCount.
  ///
  /// In en, this message translates to:
  /// **'IMPORTED AUDIOBOOKS ({count})'**
  String abk2ImportedAudiobooksCount(Object count);

  /// No description provided for @abk2AuthorPartsSize.
  ///
  /// In en, this message translates to:
  /// **'{author} • {parts} part(s) ({size} MB)'**
  String abk2AuthorPartsSize(Object author, Object parts, Object size);

  /// No description provided for @abk2DeleteFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" from your library?'**
  String abk2DeleteFromLibrary(Object title);

  /// No description provided for @abk2StreamUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Stream URL copied to clipboard!'**
  String get abk2StreamUrlCopied;

  /// No description provided for @abk2RemoveGenerationJob.
  ///
  /// In en, this message translates to:
  /// **'Remove Generation Job?'**
  String get abk2RemoveGenerationJob;

  /// No description provided for @abk2AiEpubGeneratorTts.
  ///
  /// In en, this message translates to:
  /// **'AI EPUB Generator (TTS)'**
  String get abk2AiEpubGeneratorTts;

  /// No description provided for @abk2MyUploadedAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'My Uploaded Audiobooks'**
  String get abk2MyUploadedAudiobooks;

  /// No description provided for @abk2DeleteAudiobook.
  ///
  /// In en, this message translates to:
  /// **'Delete Audiobook?'**
  String get abk2DeleteAudiobook;

  /// No description provided for @bk2FailedToDownloadBook.
  ///
  /// In en, this message translates to:
  /// **'Failed to download book: {error}'**
  String bk2FailedToDownloadBook(Object error);

  /// No description provided for @bk2PageOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String bk2PageOfTotal(Object current, Object total);

  /// No description provided for @bk2ChapterOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Chapter {current} of {total}'**
  String bk2ChapterOfTotal(Object current, Object total);

  /// No description provided for @bk2PercentCompleted.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Completed'**
  String bk2PercentCompleted(Object percent);

  /// No description provided for @bk2DownloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%...'**
  String bk2DownloadingPercent(Object percent);

  /// No description provided for @bk2Information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get bk2Information;

  /// No description provided for @bk2Overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get bk2Overview;

  /// No description provided for @bk2FailedToLoadBooks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load books: {error}'**
  String bk2FailedToLoadBooks(Object error);

  /// No description provided for @bk2ResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Results for \"{query}\"'**
  String bk2ResultsFor(Object query);

  /// No description provided for @bk2FontSizeMargins.
  ///
  /// In en, this message translates to:
  /// **'Font Size: {size} pt · Margins: {margins}'**
  String bk2FontSizeMargins(Object size, Object margins);

  /// No description provided for @bk2AuthorPercentRead.
  ///
  /// In en, this message translates to:
  /// **'{author} · {percent}% read'**
  String bk2AuthorPercentRead(Object author, Object percent);

  /// No description provided for @bk2AllFormats.
  ///
  /// In en, this message translates to:
  /// **'All Formats'**
  String get bk2AllFormats;

  /// No description provided for @bk2FailedToOpenBook.
  ///
  /// In en, this message translates to:
  /// **'Failed to open \"{title}\": {error}'**
  String bk2FailedToOpenBook(Object title, Object error);

  /// No description provided for @bk2PercentMinsLeft.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · ~{mins} min left'**
  String bk2PercentMinsLeft(Object percent, Object mins);

  /// No description provided for @bk2BackToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Back to Library'**
  String get bk2BackToLibrary;

  /// No description provided for @bk2Retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get bk2Retry;

  /// No description provided for @bk2PdfPageOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String bk2PdfPageOfTotal(Object current, Object total);

  /// No description provided for @bk2PageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String bk2PageNumber(Object page);

  /// No description provided for @bk2SliderAuthorPercentRead.
  ///
  /// In en, this message translates to:
  /// **'{author} · {percent}% read'**
  String bk2SliderAuthorPercentRead(Object author, Object percent);

  /// No description provided for @bk2SliderPositionPercentRead.
  ///
  /// In en, this message translates to:
  /// **'{position} · {percent}% read'**
  String bk2SliderPositionPercentRead(Object position, Object percent);

  /// No description provided for @mg2NoChaptersMatching.
  ///
  /// In en, this message translates to:
  /// **'No chapters matching \"{query}\"'**
  String mg2NoChaptersMatching(Object query);

  /// No description provided for @mg2ChapterNumber.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String mg2ChapterNumber(Object number);

  /// No description provided for @mg2PageOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String mg2PageOfTotal(Object current, Object total);

  /// No description provided for @mg2ResumeChapter.
  ///
  /// In en, this message translates to:
  /// **'Resume Chapter {number}'**
  String mg2ResumeChapter(Object number);

  /// No description provided for @mg2Synopsis.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get mg2Synopsis;

  /// No description provided for @mg2GenreManga.
  ///
  /// In en, this message translates to:
  /// **'{genre} Manga'**
  String mg2GenreManga(Object genre);

  /// No description provided for @mg2PercentRead.
  ///
  /// In en, this message translates to:
  /// **'{percent}% read'**
  String mg2PercentRead(Object percent);

  /// No description provided for @mg2AuthorPercentRead.
  ///
  /// In en, this message translates to:
  /// **'{author} · {percent}% read'**
  String mg2AuthorPercentRead(Object author, Object percent);

  /// No description provided for @mg2CurrentChapterNumber.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String mg2CurrentChapterNumber(Object number);

  /// No description provided for @mg2NextChapterNumber.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String mg2NextChapterNumber(Object number);

  /// No description provided for @mg2ReaderPageOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String mg2ReaderPageOfTotal(Object current, Object total);

  /// No description provided for @mg2ReaderPageSlashTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {current} / {total}'**
  String mg2ReaderPageSlashTotal(Object current, Object total);

  /// No description provided for @mg2PageModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Page Mode: {mode}'**
  String mg2PageModeLabel(Object mode);

  /// No description provided for @mg2AtmosphereLabel.
  ///
  /// In en, this message translates to:
  /// **'Atmosphere: {atmosphere}'**
  String mg2AtmosphereLabel(Object atmosphere);

  /// No description provided for @bk2Typography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get bk2Typography;

  /// No description provided for @bk2Theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get bk2Theme;

  /// No description provided for @bk2Layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get bk2Layout;

  /// No description provided for @stgcAddonConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'{name} connected to {service}'**
  String stgcAddonConnectedTo(Object name, Object service);

  /// No description provided for @stgcAddonInstalled.
  ///
  /// In en, this message translates to:
  /// **'{name} installed successfully!'**
  String stgcAddonInstalled(Object name);

  /// No description provided for @stgcRemoveAddonQ.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String stgcRemoveAddonQ(Object name);

  /// No description provided for @stgcRepoAdded.
  ///
  /// In en, this message translates to:
  /// **'Repository added successfully!'**
  String get stgcRepoAdded;

  /// No description provided for @stgcInstallRepoPluginsQ.
  ///
  /// In en, this message translates to:
  /// **'Install Repository Plugins?'**
  String get stgcInstallRepoPluginsQ;

  /// No description provided for @stgcInstalledFromRepo.
  ///
  /// In en, this message translates to:
  /// **'Successfully installed {count} plugins from repository!'**
  String stgcInstalledFromRepo(Object count);

  /// No description provided for @stgcInstallError.
  ///
  /// In en, this message translates to:
  /// **'Installation error: {error}'**
  String stgcInstallError(Object error);

  /// No description provided for @stgcRemoveExtQ.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String stgcRemoveExtQ(Object name);

  /// No description provided for @stgcRemoveCountPluginsQ.
  ///
  /// In en, this message translates to:
  /// **'Remove {count} plugin(s)?'**
  String stgcRemoveCountPluginsQ(Object count);

  /// No description provided for @stgcConfirmRemoveAllCs.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all {count} installed CloudStream plugins? All downloaded plugin files (.jar/.cs3) will be deleted.'**
  String stgcConfirmRemoveAllCs(Object count);

  /// No description provided for @stgcConfirmRemoveSelectedCs.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the {count} selected CloudStream plugins? Their downloaded files will be deleted from your device.'**
  String stgcConfirmRemoveSelectedCs(Object count);

  /// No description provided for @stgcRemovedCountPlugins.
  ///
  /// In en, this message translates to:
  /// **'Successfully removed {count} plugin(s).'**
  String stgcRemovedCountPlugins(Object count);

  /// No description provided for @stgcRemoveCount.
  ///
  /// In en, this message translates to:
  /// **'Remove ({count})'**
  String stgcRemoveCount(Object count);

  /// No description provided for @stgcRemoveRepoQ.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String stgcRemoveRepoQ(Object name);

  /// No description provided for @stgcAddonsExtensions.
  ///
  /// In en, this message translates to:
  /// **'Addons & Extensions'**
  String get stgcAddonsExtensions;

  /// No description provided for @stgcAddonsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} Total'**
  String stgcAddonsTotal(Object count);

  /// No description provided for @stgcRemoveSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Remove ({count})'**
  String stgcRemoveSelectedCount(Object count);

  /// No description provided for @stgcInstalledTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} Total'**
  String stgcInstalledTotal(Object count);

  /// No description provided for @stgcReposCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Repos'**
  String stgcReposCount(Object count);

  /// No description provided for @stgcRuntimeSetupError.
  ///
  /// In en, this message translates to:
  /// **'Runtime setup error: {error}'**
  String stgcRuntimeSetupError(Object error);

  /// No description provided for @stgcAddonSubtitlesProvider.
  ///
  /// In en, this message translates to:
  /// **'v{version}  ·  Subtitles Provider'**
  String stgcAddonSubtitlesProvider(Object version);

  /// No description provided for @stgcAddonCatalogs.
  ///
  /// In en, this message translates to:
  /// **'v{version}  ·  {count} catalog(s){subtitles}'**
  String stgcAddonCatalogs(Object version, Object count, Object subtitles);

  /// No description provided for @stgcAddonSubtitlesSuffix.
  ///
  /// In en, this message translates to:
  /// **'  ·  Subtitles'**
  String get stgcAddonSubtitlesSuffix;

  /// No description provided for @stgcLabelCount.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String stgcLabelCount(Object label, Object count);

  /// No description provided for @stgcUsesYourServiceKey.
  ///
  /// In en, this message translates to:
  /// **'Uses your {service} key'**
  String stgcUsesYourServiceKey(Object service);

  /// No description provided for @stgcPluginInstalled.
  ///
  /// In en, this message translates to:
  /// **'{name} installed successfully!'**
  String stgcPluginInstalled(Object name);

  /// No description provided for @stgcPluginUninstalled.
  ///
  /// In en, this message translates to:
  /// **'{name} uninstalled.'**
  String stgcPluginUninstalled(Object name);

  /// No description provided for @stgcInstalledCountPlugins.
  ///
  /// In en, this message translates to:
  /// **'Successfully installed {count} plugins!'**
  String stgcInstalledCountPlugins(Object count);

  /// No description provided for @stgcRemoveListPluginsQ.
  ///
  /// In en, this message translates to:
  /// **'Remove {count} plugin(s)?'**
  String stgcRemoveListPluginsQ(Object count);

  /// No description provided for @stgcConfirmUninstallList.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to uninstall all {count} installed plugins from this list? Their downloaded files will be removed.'**
  String stgcConfirmUninstallList(Object count);

  /// No description provided for @stgcRemoveAllListCount.
  ///
  /// In en, this message translates to:
  /// **'Remove All ({count})'**
  String stgcRemoveAllListCount(Object count);

  /// No description provided for @stgcUninstalledCount.
  ///
  /// In en, this message translates to:
  /// **'Successfully uninstalled {count} plugins.'**
  String stgcUninstalledCount(Object count);

  /// No description provided for @stgcRemoveAllCount.
  ///
  /// In en, this message translates to:
  /// **'Remove All ({count})'**
  String stgcRemoveAllCount(Object count);

  /// No description provided for @stgcInstallAllCount.
  ///
  /// In en, this message translates to:
  /// **'Install All ({count})'**
  String stgcInstallAllCount(Object count);

  /// No description provided for @stgcNoPluginsMatching.
  ///
  /// In en, this message translates to:
  /// **'No plugins matching \"{query}\"'**
  String stgcNoPluginsMatching(Object query);

  /// No description provided for @stgcAllMatchingInstalled.
  ///
  /// In en, this message translates to:
  /// **'All matching plugins are already installed!'**
  String get stgcAllMatchingInstalled;

  /// No description provided for @stgcRepoNameAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added successfully!'**
  String stgcRepoNameAdded(Object name);

  /// No description provided for @stgcInstallRepoNamePluginsQ.
  ///
  /// In en, this message translates to:
  /// **'Install {name} Plugins?'**
  String stgcInstallRepoNamePluginsQ(Object name);

  /// No description provided for @stgcRepoIncludesPlugins.
  ///
  /// In en, this message translates to:
  /// **'This repository includes {count} plugins ({sample}...). Install all plugins now so their stream sources appear immediately?'**
  String stgcRepoIncludesPlugins(Object count, Object sample);

  /// No description provided for @stgcPluginsInstalledReady.
  ///
  /// In en, this message translates to:
  /// **'{count} plugins installed and ready!'**
  String stgcPluginsInstalledReady(Object count);

  /// No description provided for @stgcMarketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} repos · Direct install links & verified providers'**
  String stgcMarketplaceSubtitle(Object count);

  /// No description provided for @stgcNoReposFound.
  ///
  /// In en, this message translates to:
  /// **'No repositories found for \"{query}\"'**
  String stgcNoReposFound(Object query);

  /// No description provided for @stgcRepoPluginsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Plugins'**
  String stgcRepoPluginsCount(Object count);

  /// No description provided for @stgcCopiedLink.
  ///
  /// In en, this message translates to:
  /// **'Copied link: {url}'**
  String stgcCopiedLink(Object url);

  /// No description provided for @stgcContainsPlugins.
  ///
  /// In en, this message translates to:
  /// **'Contains: {plugins}'**
  String stgcContainsPlugins(Object plugins);

  /// No description provided for @stgcViewAllPlugins.
  ///
  /// In en, this message translates to:
  /// **'View all {count} plugins'**
  String stgcViewAllPlugins(Object count);

  /// No description provided for @stgcDebridKeyVerified.
  ///
  /// In en, this message translates to:
  /// **'{provider} key verified ({user}) & set as active provider!'**
  String stgcDebridKeyVerified(Object provider, Object user);

  /// No description provided for @stgcDebridKeySaved.
  ///
  /// In en, this message translates to:
  /// **'{provider} key saved & set as active provider!'**
  String stgcDebridKeySaved(Object provider);

  /// No description provided for @stgcDebridKeyCleared.
  ///
  /// In en, this message translates to:
  /// **'{provider} key cleared.'**
  String stgcDebridKeyCleared(Object provider);

  /// No description provided for @stgcDebridCloudStreaming.
  ///
  /// In en, this message translates to:
  /// **'Debrid & Cloud Streaming'**
  String get stgcDebridCloudStreaming;

  /// No description provided for @stgcServiceNoKey.
  ///
  /// In en, this message translates to:
  /// **'{service} has no API key saved. Please enter and save your key below.'**
  String stgcServiceNoKey(Object service);

  /// No description provided for @stgcDebridActivatedVia.
  ///
  /// In en, this message translates to:
  /// **'Debrid streaming activated via {service}'**
  String stgcDebridActivatedVia(Object service);

  /// No description provided for @stgcSelectedNoKey.
  ///
  /// In en, this message translates to:
  /// **'{service} selected, but has no API key saved yet. Please enter and save your key below.'**
  String stgcSelectedNoKey(Object service);

  /// No description provided for @stgcActiveDebridSet.
  ///
  /// In en, this message translates to:
  /// **'Active Debrid service set to {service}'**
  String stgcActiveDebridSet(Object service);

  /// No description provided for @stgcRdLoggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Logged in as {user}'**
  String stgcRdLoggedInAs(Object user);

  /// No description provided for @stgcTorboxAccount.
  ///
  /// In en, this message translates to:
  /// **'Account: {account}'**
  String stgcTorboxAccount(Object account);

  /// No description provided for @stgcAllDebridAccount.
  ///
  /// In en, this message translates to:
  /// **'Account: {account}'**
  String stgcAllDebridAccount(Object account);

  /// No description provided for @stgcDebridLinkAccount.
  ///
  /// In en, this message translates to:
  /// **'Account: {account}'**
  String stgcDebridLinkAccount(Object account);

  /// No description provided for @stgcPurposeTrakt.
  ///
  /// In en, this message translates to:
  /// **'Identifies the Trakt application the pairing flow asks for a device code on, and stamps every Trakt API call.'**
  String get stgcPurposeTrakt;

  /// No description provided for @stgcServiceKeysIntro.
  ///
  /// In en, this message translates to:
  /// **'Lumora talks to several third-party services. Any key you save here replaces the one this build uses and takes effect immediately, with no restart.'**
  String get stgcServiceKeysIntro;

  /// No description provided for @stgcServiceKeysUnobtainable.
  ///
  /// In en, this message translates to:
  /// **'These cannot be obtained: each is a credential for a third-party service that did not issue it to ZPlay, so leave its field blank unless you have your own. A private build can supply its own with --dart-define, and blanking the registry entry in the source disables only that one source.'**
  String get stgcServiceKeysUnobtainable;

  /// No description provided for @stgcServiceKeysStoredLocally.
  ///
  /// In en, this message translates to:
  /// **'Every value is stored only on this device and is never shown back in these fields.'**
  String get stgcServiceKeysStoredLocally;

  /// No description provided for @stgcPasteKeyFirst.
  ///
  /// In en, this message translates to:
  /// **'Paste a key for {label} first.'**
  String stgcPasteKeyFirst(Object label);

  /// No description provided for @stgcKeySavedInUse.
  ///
  /// In en, this message translates to:
  /// **'{label} key saved and now in use.'**
  String stgcKeySavedInUse(Object label);

  /// No description provided for @stgcLabelKeyCleared.
  ///
  /// In en, this message translates to:
  /// **'{label} key cleared.'**
  String stgcLabelKeyCleared(Object label);

  /// No description provided for @stgcPasteYourKey.
  ///
  /// In en, this message translates to:
  /// **'Paste your {label} key'**
  String stgcPasteYourKey(Object label);

  /// No description provided for @stgcServiceApiKeys.
  ///
  /// In en, this message translates to:
  /// **'Service API Keys'**
  String get stgcServiceApiKeys;

  /// No description provided for @stgcVideoUpscaling.
  ///
  /// In en, this message translates to:
  /// **'Video & Upscaling'**
  String get stgcVideoUpscaling;

  /// No description provided for @stgcUpscalingIntro.
  ///
  /// In en, this message translates to:
  /// **'Real-time GLSL upscaling on the video engine. Anime4K reconstructs line art; AMD FSR upscales live action and film. Pick one family — they are never combined.'**
  String get stgcUpscalingIntro;

  /// No description provided for @stgcFsrDesc.
  ///
  /// In en, this message translates to:
  /// **'AMD FidelityFX edge-adaptive upscaling, for live action and film. Upscales without sharpening, so it is the safe FSR option. Runs on any GPU, unlike NVIDIA RTX Video.'**
  String get stgcFsrDesc;

  /// No description provided for @stgcFsrCasDesc.
  ///
  /// In en, this message translates to:
  /// **'FSR with contrast-adaptive sharpening. Adds bite to soft or low-bitrate video. On a 2K or 4K source this can look worse than no upscaling at all.'**
  String get stgcFsrCasDesc;

  /// No description provided for @stgcAppearanceInterface.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Interface'**
  String get stgcAppearanceInterface;

  /// No description provided for @stgcSkiaRecommended.
  ///
  /// In en, this message translates to:
  /// **'Skia is recommended on Windows here — Impeller coincided with an NVIDIA driver crash.'**
  String get stgcSkiaRecommended;

  /// No description provided for @stgcSimklPinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to request Simkl PIN code.'**
  String get stgcSimklPinFailed;

  /// No description provided for @stgcSimklSync.
  ///
  /// In en, this message translates to:
  /// **'Simkl Synchronization'**
  String get stgcSimklSync;

  /// No description provided for @stgcSimklLoggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Logged in as {user}'**
  String stgcSimklLoggedInAs(Object user);

  /// No description provided for @stgcPinCopied.
  ///
  /// In en, this message translates to:
  /// **'PIN copied to clipboard!'**
  String get stgcPinCopied;

  /// No description provided for @stgcSyncingSimkl.
  ///
  /// In en, this message translates to:
  /// **'Syncing with Simkl...'**
  String get stgcSyncingSimkl;

  /// No description provided for @stgcSimklSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Simkl sync complete!'**
  String get stgcSimklSyncDone;

  /// No description provided for @stgcTraktSync.
  ///
  /// In en, this message translates to:
  /// **'Trakt.tv Synchronization'**
  String get stgcTraktSync;

  /// No description provided for @stgcCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard!'**
  String get stgcCodeCopied;

  /// No description provided for @stgcSyncingTrakt.
  ///
  /// In en, this message translates to:
  /// **'Syncing with Trakt.tv...'**
  String get stgcSyncingTrakt;

  /// No description provided for @stgcTraktSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Trakt sync complete!'**
  String get stgcTraktSyncDone;

  /// No description provided for @stgcTraktLoggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Logged in as {user}'**
  String stgcTraktLoggedInAs(Object user);

  /// No description provided for @stgcTraktNeedsClientId.
  ///
  /// In en, this message translates to:
  /// **'Trakt needs a Client ID before it can pair. Create a free app at {url}, then paste its Client ID in Settings > Service API Keys. The Client Secret from the same app is optional.'**
  String stgcTraktNeedsClientId(Object url);

  /// No description provided for @stgcTraktRejected.
  ///
  /// In en, this message translates to:
  /// **'Trakt rejected the pairing request. Check the Client ID in Settings > Service API Keys - and add the Client Secret if Trakt requires one for your app.'**
  String get stgcTraktRejected;

  /// No description provided for @stgcTmdbApiKey.
  ///
  /// In en, this message translates to:
  /// **'TMDb API Key'**
  String get stgcTmdbApiKey;

  /// No description provided for @stgcTmdbIntro.
  ///
  /// In en, this message translates to:
  /// **'Add your own free TMDb key to rank the six \"The 90s\" rails by TMDb vote counts, and to cover the TMDb lookups the built-in scrapers make. Get a key at themoviedb.org.'**
  String get stgcTmdbIntro;

  /// No description provided for @stgcTmdbStoredLocally.
  ///
  /// In en, this message translates to:
  /// **'The key is stored only on this device. This app ships with no key, and a built-in fallback keeps the scraper lookups working without one. Clearing your key restores the built-in 1990s picks.'**
  String get stgcTmdbStoredLocally;

  /// No description provided for @stgcAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} • Next-Gen Streaming Hub'**
  String stgcAboutVersion(Object version);

  /// No description provided for @stgcAboutLegalese.
  ///
  /// In en, this message translates to:
  /// **'Lumora, Copyright (C) 2026 JTing904\nhttps://github.com/JTing904/Lumora\nBased on ZPlay, Copyright (C) 2026 tzero86\nBased on PlayTorrio V3, Copyright (C) 2026 Ayman\nhttps://github.com/tzero86/ZPlay\nhttps://github.com/ayman708-UX/PlayTorrioV3\n\nThis program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.'**
  String get stgcAboutLegalese;

  /// No description provided for @stgcUpdateCheckError.
  ///
  /// In en, this message translates to:
  /// **'Error checking updates: {error}'**
  String stgcUpdateCheckError(Object error);

  /// No description provided for @stgcInstalledVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed Version: v{version} (Build {build})'**
  String stgcInstalledVersion(Object version, Object build);

  /// No description provided for @stgcAudiobookStudioApplied.
  ///
  /// In en, this message translates to:
  /// **'Custom Player Studio layout applied & set as active player!'**
  String get stgcAudiobookStudioApplied;

  /// No description provided for @stgcPreviewSpeed.
  ///
  /// In en, this message translates to:
  /// **'{speed}x Speed'**
  String stgcPreviewSpeed(Object speed);

  /// No description provided for @stgcPositionN.
  ///
  /// In en, this message translates to:
  /// **'Position #{n}'**
  String stgcPositionN(Object n);

  /// No description provided for @stgcHoverToFeel.
  ///
  /// In en, this message translates to:
  /// **'Hover your cursor or tap below to feel \"{effect}\" in real-time:'**
  String stgcHoverToFeel(Object effect);

  /// No description provided for @stgcTestEffect.
  ///
  /// In en, this message translates to:
  /// **'Test \"{effect}\"'**
  String stgcTestEffect(Object effect);

  /// No description provided for @stgcAudiobookUiStudio.
  ///
  /// In en, this message translates to:
  /// **'Audiobook UI & Player Studio'**
  String get stgcAudiobookUiStudio;

  /// No description provided for @stgcAuroraThemedTo.
  ///
  /// In en, this message translates to:
  /// **'Soft flowing glowing orbs and aurora waves themed to {palette}'**
  String stgcAuroraThemedTo(Object palette);

  /// No description provided for @stgcCustomBgWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Custom Background & Wallpaper'**
  String get stgcCustomBgWallpaper;

  /// No description provided for @stgcWallpaperActiveWith.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper active with {palette} ambient lighting'**
  String stgcWallpaperActiveWith(Object palette);

  /// No description provided for @stgcDefaultThemeBg.
  ///
  /// In en, this message translates to:
  /// **'Default {palette} theme background'**
  String stgcDefaultThemeBg(Object palette);

  /// No description provided for @stgcAppliedWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Applied \"{title}\" wallpaper'**
  String stgcAppliedWallpaper(Object title);

  /// No description provided for @stgcHomeUiThemes.
  ///
  /// In en, this message translates to:
  /// **'Home Page UI & Themes'**
  String get stgcHomeUiThemes;

  /// No description provided for @stgcDropImagelessRails.
  ///
  /// In en, this message translates to:
  /// **'Drops a Home rail when none of its titles can show a picture. A landscape tile has no name under it, so such a rail is a row of blank rectangles.'**
  String get stgcDropImagelessRails;

  /// No description provided for @stgcIntervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'Interval: {seconds}s'**
  String stgcIntervalSeconds(Object seconds);

  /// No description provided for @stgcLiquidGlassReset.
  ///
  /// In en, this message translates to:
  /// **'Liquid Glass settings reset to defaults.'**
  String get stgcLiquidGlassReset;

  /// No description provided for @stgcLiveTvSportsUi.
  ///
  /// In en, this message translates to:
  /// **'Live TV & Sports UI'**
  String get stgcLiveTvSportsUi;

  /// No description provided for @stgcNSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String stgcNSeconds(Object seconds);

  /// No description provided for @stgcNColumns.
  ///
  /// In en, this message translates to:
  /// **'{cols} Columns'**
  String stgcNColumns(Object cols);

  /// No description provided for @stgcXtreamPanels.
  ///
  /// In en, this message translates to:
  /// **'Xtream Panels'**
  String get stgcXtreamPanels;

  /// No description provided for @stgcM3uPlaylists.
  ///
  /// In en, this message translates to:
  /// **'M3U Playlists'**
  String get stgcM3uPlaylists;

  /// No description provided for @stgcMangaUiAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Manga UI & Reader Atmosphere'**
  String get stgcMangaUiAtmosphere;

  /// No description provided for @stgcMusicStudioApplied.
  ///
  /// In en, this message translates to:
  /// **'Custom Fullscreen Player Studio layout set as active player!'**
  String get stgcMusicStudioApplied;

  /// No description provided for @stgcMusicUiAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Music UI & Player Atmosphere'**
  String get stgcMusicUiAtmosphere;

  /// No description provided for @wgShellPressBackAgain.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get wgShellPressBackAgain;

  /// No description provided for @wgAniSeriesBadge.
  ///
  /// In en, this message translates to:
  /// **'SERIES'**
  String get wgAniSeriesBadge;

  /// No description provided for @wgAniEpisodeCountShort.
  ///
  /// In en, this message translates to:
  /// **'{count} EPS'**
  String wgAniEpisodeCountShort(Object count);

  /// No description provided for @wgAniFeaturedAnime.
  ///
  /// In en, this message translates to:
  /// **'FEATURED ANIME'**
  String get wgAniFeaturedAnime;

  /// No description provided for @wgAniEpisodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Episodes'**
  String wgAniEpisodeCount(Object count);

  /// No description provided for @wgAniPlayEpisodeOne.
  ///
  /// In en, this message translates to:
  /// **'Play Ep 1'**
  String get wgAniPlayEpisodeOne;

  /// No description provided for @wgComTabTitleCount.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count} titles'**
  String wgComTabTitleCount(Object label, Object count);

  /// No description provided for @wgComTrailer.
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get wgComTrailer;

  /// No description provided for @wgComTrailerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Trailer unavailable'**
  String get wgComTrailerUnavailable;

  /// No description provided for @wgComTrailerCannotPlay.
  ///
  /// In en, this message translates to:
  /// **'This trailer could not be played in the app.'**
  String get wgComTrailerCannotPlay;

  /// No description provided for @wgComCloseTrailer.
  ///
  /// In en, this message translates to:
  /// **'Close trailer'**
  String get wgComCloseTrailer;

  /// No description provided for @wgComUnmuteTrailer.
  ///
  /// In en, this message translates to:
  /// **'Unmute trailer'**
  String get wgComUnmuteTrailer;

  /// No description provided for @wgComMuteTrailer.
  ///
  /// In en, this message translates to:
  /// **'Mute trailer'**
  String get wgComMuteTrailer;

  /// No description provided for @wgIptvLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get wgIptvLiveBadge;

  /// No description provided for @wgIptvHdLive.
  ///
  /// In en, this message translates to:
  /// **'HD Live'**
  String get wgIptvHdLive;

  /// No description provided for @wgIptvHealthAlive.
  ///
  /// In en, this message translates to:
  /// **'ALIVE'**
  String get wgIptvHealthAlive;

  /// No description provided for @wgIptvHealthUnchecked.
  ///
  /// In en, this message translates to:
  /// **'UNCHECKED'**
  String get wgIptvHealthUnchecked;

  /// No description provided for @wgIptvHealthDead.
  ///
  /// In en, this message translates to:
  /// **'DEAD'**
  String get wgIptvHealthDead;

  /// No description provided for @wgIptvLiveBroadcast.
  ///
  /// In en, this message translates to:
  /// **'LIVE BROADCAST'**
  String get wgIptvLiveBroadcast;

  /// No description provided for @wgIptvHeroTagline.
  ///
  /// In en, this message translates to:
  /// **'Instant live multi-source streaming with real-time stream resolution & high-framerate playback.'**
  String get wgIptvHeroTagline;

  /// No description provided for @wgIptvWatchLive.
  ///
  /// In en, this message translates to:
  /// **'Watch Live'**
  String get wgIptvWatchLive;

  /// No description provided for @wgIptvStreamFeeds.
  ///
  /// In en, this message translates to:
  /// **'Stream Feeds'**
  String get wgIptvStreamFeeds;

  /// No description provided for @wgIptvRemovedPortals.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} portal{plural}'**
  String wgIptvRemovedPortals(Object count, Object plural);

  /// No description provided for @wgIptvRemovedAllPortals.
  ///
  /// In en, this message translates to:
  /// **'Removed all {count} portals'**
  String wgIptvRemovedAllPortals(Object count);

  /// No description provided for @wgIptvRemovedPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} playlist{plural}'**
  String wgIptvRemovedPlaylists(Object count, Object plural);

  /// No description provided for @wgIptvRemovedAllPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Removed all {count} playlists'**
  String wgIptvRemovedAllPlaylists(Object count);

  /// No description provided for @wgIptvSearchChannels.
  ///
  /// In en, this message translates to:
  /// **'Search channels...'**
  String get wgIptvSearchChannels;

  /// No description provided for @wgIptvFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding…'**
  String get wgIptvFinding;

  /// No description provided for @wgIptvGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get wgIptvGenerate;

  /// No description provided for @wgIptvChoosePortalSource.
  ///
  /// In en, this message translates to:
  /// **'Choose Portal Source'**
  String get wgIptvChoosePortalSource;

  /// No description provided for @wgIptvCloudVault.
  ///
  /// In en, this message translates to:
  /// **'Cloud Vault'**
  String get wgIptvCloudVault;

  /// No description provided for @wgIptvRedditCommunities.
  ///
  /// In en, this message translates to:
  /// **'Reddit Communities'**
  String get wgIptvRedditCommunities;

  /// No description provided for @wgIptvRedditPastes.
  ///
  /// In en, this message translates to:
  /// **'Live shared pastes from subreddits'**
  String get wgIptvRedditPastes;

  /// No description provided for @wgIptvAddPortal.
  ///
  /// In en, this message translates to:
  /// **'Add Portal'**
  String get wgIptvAddPortal;

  /// No description provided for @wgIptvDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get wgIptvDone;

  /// No description provided for @wgIptvManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get wgIptvManage;

  /// No description provided for @wgIptvDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get wgIptvDeselectAll;

  /// No description provided for @wgIptvSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get wgIptvSelectAll;

  /// No description provided for @wgIptvDeleteSelectedPortals.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String wgIptvDeleteSelectedPortals(Object count);

  /// No description provided for @wgIptvDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get wgIptvDeleteAll;

  /// No description provided for @wgIptvAddXtreamPortal.
  ///
  /// In en, this message translates to:
  /// **'Add Xtream Codes Portal'**
  String get wgIptvAddXtreamPortal;

  /// No description provided for @wgIptvServerUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL (e.g. http://example.com:8080)'**
  String get wgIptvServerUrlLabel;

  /// No description provided for @wgIptvUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get wgIptvUsername;

  /// No description provided for @wgIptvPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get wgIptvPassword;

  /// No description provided for @wgIptvVerifySave.
  ///
  /// In en, this message translates to:
  /// **'Verify & Save'**
  String get wgIptvVerifySave;

  /// No description provided for @wgIptvChipAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String wgIptvChipAll(Object count);

  /// No description provided for @wgIptvChipCloudVault.
  ///
  /// In en, this message translates to:
  /// **'Cloud Vault ({count})'**
  String wgIptvChipCloudVault(Object count);

  /// No description provided for @wgIptvChipFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites ⭐ ({count})'**
  String wgIptvChipFavorites(Object count);

  /// No description provided for @wgIptvNoXtreamPortals.
  ///
  /// In en, this message translates to:
  /// **'No Xtream portals loaded'**
  String get wgIptvNoXtreamPortals;

  /// No description provided for @wgIptvNoMatchingChannels.
  ///
  /// In en, this message translates to:
  /// **'No matching channels'**
  String get wgIptvNoMatchingChannels;

  /// No description provided for @wgIptvCopyLogin.
  ///
  /// In en, this message translates to:
  /// **'Copy Login (url:user:pass)'**
  String get wgIptvCopyLogin;

  /// No description provided for @wgIptvCopiedText.
  ///
  /// In en, this message translates to:
  /// **'Copied: {text}'**
  String wgIptvCopiedText(Object text);

  /// No description provided for @wgIptvRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove Favorite'**
  String get wgIptvRemoveFavorite;

  /// No description provided for @wgIptvAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get wgIptvAddToFavorites;

  /// No description provided for @wgIptvRemovePortal.
  ///
  /// In en, this message translates to:
  /// **'Remove Portal'**
  String get wgIptvRemovePortal;

  /// No description provided for @wgIptvExpiryShort.
  ///
  /// In en, this message translates to:
  /// **'Exp: {expiry}'**
  String wgIptvExpiryShort(Object expiry);

  /// No description provided for @wgIptvConnShort.
  ///
  /// In en, this message translates to:
  /// **'Conn: {active}/{max}'**
  String wgIptvConnShort(Object active, Object max);

  /// No description provided for @wgIptvGroupExpiry.
  ///
  /// In en, this message translates to:
  /// **'Exp: {expiry}'**
  String wgIptvGroupExpiry(Object expiry);

  /// No description provided for @wgIptvGroupConn.
  ///
  /// In en, this message translates to:
  /// **'Conn: {active}/{max}'**
  String wgIptvGroupConn(Object active, Object max);

  /// No description provided for @wgIptvNoLiveChannelsPortal.
  ///
  /// In en, this message translates to:
  /// **'No live channels available for this portal'**
  String get wgIptvNoLiveChannelsPortal;

  /// No description provided for @wgIptvLiveChannelCount.
  ///
  /// In en, this message translates to:
  /// **'{count} live channels'**
  String wgIptvLiveChannelCount(Object count);

  /// No description provided for @wgIptvAddM3uUrl.
  ///
  /// In en, this message translates to:
  /// **'Add M3U URL'**
  String get wgIptvAddM3uUrl;

  /// No description provided for @wgIptvDeleteSelectedM3u.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String wgIptvDeleteSelectedM3u(Object count);

  /// No description provided for @wgIptvAddM3uSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add M3U Playlist Subscription'**
  String get wgIptvAddM3uSubscription;

  /// No description provided for @wgIptvPlaylistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get wgIptvPlaylistName;

  /// No description provided for @wgIptvM3uUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'M3U / M3U8 URL'**
  String get wgIptvM3uUrlLabel;

  /// No description provided for @wgIptvFetchSave.
  ///
  /// In en, this message translates to:
  /// **'Fetch & Save'**
  String get wgIptvFetchSave;

  /// No description provided for @wgIptvNoM3uPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No M3U playlists loaded'**
  String get wgIptvNoM3uPlaylists;

  /// No description provided for @wgIptvCopyPlaylistUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy Playlist URL'**
  String get wgIptvCopyPlaylistUrl;

  /// No description provided for @wgIptvRemovePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove Playlist'**
  String get wgIptvRemovePlaylist;

  /// No description provided for @wgIptvPlaylistChannelsSource.
  ///
  /// In en, this message translates to:
  /// **'{count} channels{source}'**
  String wgIptvPlaylistChannelsSource(Object count, Object source);

  /// No description provided for @wgIptvNoChannelsPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No channels in this playlist'**
  String get wgIptvNoChannelsPlaylist;

  /// No description provided for @wgIptvChannelCount.
  ///
  /// In en, this message translates to:
  /// **'{count} channels'**
  String wgIptvChannelCount(Object count);

  /// No description provided for @wgMgaUnknownYear.
  ///
  /// In en, this message translates to:
  /// **'Unknown Year'**
  String get wgMgaUnknownYear;

  /// No description provided for @wgMgaCategories.
  ///
  /// In en, this message translates to:
  /// **'Manga Categories'**
  String get wgMgaCategories;

  /// No description provided for @wgMgaFilterCategories.
  ///
  /// In en, this message translates to:
  /// **'Filter categories...'**
  String get wgMgaFilterCategories;

  /// No description provided for @wgMgaNoMatchingCategories.
  ///
  /// In en, this message translates to:
  /// **'No matching categories'**
  String get wgMgaNoMatchingCategories;

  /// No description provided for @wgMgaResetAllCategories.
  ///
  /// In en, this message translates to:
  /// **'Reset to All Categories'**
  String get wgMgaResetAllCategories;

  /// No description provided for @wgMovSeriesBadge.
  ///
  /// In en, this message translates to:
  /// **'SERIES'**
  String get wgMovSeriesBadge;

  /// No description provided for @wgMovAnimeBadge.
  ///
  /// In en, this message translates to:
  /// **'ANIME'**
  String get wgMovAnimeBadge;

  /// No description provided for @wgPlySurround51.
  ///
  /// In en, this message translates to:
  /// **'5.1 Surround'**
  String get wgPlySurround51;

  /// No description provided for @wgPlySurround71.
  ///
  /// In en, this message translates to:
  /// **'7.1 Surround'**
  String get wgPlySurround71;

  /// No description provided for @wgPlyAudioChannels.
  ///
  /// In en, this message translates to:
  /// **'{count} ch'**
  String wgPlyAudioChannels(Object count);

  /// No description provided for @wgPlySeasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Season {season}'**
  String wgPlySeasonLabel(Object season);

  /// No description provided for @wgPlySeasonOne.
  ///
  /// In en, this message translates to:
  /// **'Season 1'**
  String get wgPlySeasonOne;

  /// No description provided for @wgPlySeasonEpisodeSummary.
  ///
  /// In en, this message translates to:
  /// **'{season} • {count} Episodes'**
  String wgPlySeasonEpisodeSummary(Object season, Object count);

  /// No description provided for @wgPlySeasonTab.
  ///
  /// In en, this message translates to:
  /// **'Season {season}'**
  String wgPlySeasonTab(Object season);

  /// No description provided for @wgPlyEpisodeFallback.
  ///
  /// In en, this message translates to:
  /// **'Episode {episode}'**
  String wgPlyEpisodeFallback(Object episode);

  /// No description provided for @wgPlyEpisodeBadge.
  ///
  /// In en, this message translates to:
  /// **'EP {episode}'**
  String wgPlyEpisodeBadge(Object episode);

  /// No description provided for @wgPlySeasonEpisodeBadge.
  ///
  /// In en, this message translates to:
  /// **'S{season} : E{episode}'**
  String wgPlySeasonEpisodeBadge(Object season, Object episode);

  /// No description provided for @wgPlySleepMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String wgPlySleepMinutes(Object minutes);

  /// No description provided for @wgPlySubtitleSizeCaps.
  ///
  /// In en, this message translates to:
  /// **'SUBTITLE SIZE'**
  String get wgPlySubtitleSizeCaps;

  /// No description provided for @wgPlyDecreaseSize.
  ///
  /// In en, this message translates to:
  /// **'Decrease size'**
  String get wgPlyDecreaseSize;

  /// No description provided for @wgPlyIncreaseSize.
  ///
  /// In en, this message translates to:
  /// **'Increase size'**
  String get wgPlyIncreaseSize;

  /// No description provided for @wgPlyResetTo100.
  ///
  /// In en, this message translates to:
  /// **'Reset to 100%'**
  String get wgPlyResetTo100;

  /// No description provided for @wgPlySubBarClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get wgPlySubBarClose;

  /// No description provided for @wgPlySubAppearance.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Appearance'**
  String get wgPlySubAppearance;

  /// No description provided for @wgPlySubAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'libass / libmpv hardware-rendered subtitles'**
  String get wgPlySubAppearanceSubtitle;

  /// No description provided for @wgPlyResetSubDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset Subtitle Defaults'**
  String get wgPlyResetSubDefaults;

  /// No description provided for @wgPlySubModalClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get wgPlySubModalClose;

  /// No description provided for @wgPlySubTabTypography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get wgPlySubTabTypography;

  /// No description provided for @wgPlySubTabColors.
  ///
  /// In en, this message translates to:
  /// **'Colors & Box'**
  String get wgPlySubTabColors;

  /// No description provided for @wgPlySubTabOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline & Shadow'**
  String get wgPlySubTabOutline;

  /// No description provided for @wgPlySubTabPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get wgPlySubTabPosition;

  /// No description provided for @wgPlySubTabAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced / ASS'**
  String get wgPlySubTabAdvanced;

  /// No description provided for @wgPlySubFontFamily.
  ///
  /// In en, this message translates to:
  /// **'FONT FAMILY'**
  String get wgPlySubFontFamily;

  /// No description provided for @wgPlySubDefaultFont.
  ///
  /// In en, this message translates to:
  /// **'Default (Lumora Subfont)'**
  String get wgPlySubDefaultFont;

  /// No description provided for @wgPlySubBaseFontSize.
  ///
  /// In en, this message translates to:
  /// **'BASE FONT SIZE ({size}pt)'**
  String wgPlySubBaseFontSize(Object size);

  /// No description provided for @wgPlySubScaleMultiplier.
  ///
  /// In en, this message translates to:
  /// **'SCALE MULTIPLIER ({percent}%)'**
  String wgPlySubScaleMultiplier(Object percent);

  /// No description provided for @wgPlySubBold.
  ///
  /// In en, this message translates to:
  /// **'Bold Text'**
  String get wgPlySubBold;

  /// No description provided for @wgPlySubItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic Text'**
  String get wgPlySubItalic;

  /// No description provided for @wgPlySubTextColor.
  ///
  /// In en, this message translates to:
  /// **'SUBTITLE TEXT COLOR'**
  String get wgPlySubTextColor;

  /// No description provided for @wgPlySubBackgroundBox.
  ///
  /// In en, this message translates to:
  /// **'BACKGROUND BOX (ACCESSIBILITY & READABILITY)'**
  String get wgPlySubBackgroundBox;

  /// No description provided for @wgPlySubOutlineColor.
  ///
  /// In en, this message translates to:
  /// **'OUTLINE / BORDER COLOR'**
  String get wgPlySubOutlineColor;

  /// No description provided for @wgPlySubOutlineThickness.
  ///
  /// In en, this message translates to:
  /// **'OUTLINE THICKNESS ({size}px)'**
  String wgPlySubOutlineThickness(Object size);

  /// No description provided for @wgPlySubShadowOffset.
  ///
  /// In en, this message translates to:
  /// **'DROP SHADOW OFFSET ({size}px)'**
  String wgPlySubShadowOffset(Object size);

  /// No description provided for @wgPlySubHorizontalAlign.
  ///
  /// In en, this message translates to:
  /// **'HORIZONTAL ALIGNMENT'**
  String get wgPlySubHorizontalAlign;

  /// No description provided for @wgPlySubAlignLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get wgPlySubAlignLeft;

  /// No description provided for @wgPlySubAlignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get wgPlySubAlignCenter;

  /// No description provided for @wgPlySubAlignRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get wgPlySubAlignRight;

  /// No description provided for @wgPlySubBottomMargin.
  ///
  /// In en, this message translates to:
  /// **'BOTTOM MARGIN / OFFSET ({size}px)'**
  String wgPlySubBottomMargin(Object size);

  /// No description provided for @wgPlySubVerticalPosition.
  ///
  /// In en, this message translates to:
  /// **'VERTICAL POSITION ({percent}%)'**
  String wgPlySubVerticalPosition(Object percent);

  /// No description provided for @wgPlyAssPreserveTitle.
  ///
  /// In en, this message translates to:
  /// **'Preserve Anime & SSA/ASS Styling (Recommended)'**
  String get wgPlyAssPreserveTitle;

  /// No description provided for @wgPlyAssPreserveDesc.
  ///
  /// In en, this message translates to:
  /// **'Leaves SSA/ASS anime subtitles untouched to preserve custom karaoke, styling & positions. Plain SRT/VTT are styled with your custom theme.'**
  String get wgPlyAssPreserveDesc;

  /// No description provided for @wgPlyAssScaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Scale Only'**
  String get wgPlyAssScaleTitle;

  /// No description provided for @wgPlyAssScaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Applies size scaling to SSA/ASS scripts while preserving their fonts, colors, and author typography.'**
  String get wgPlyAssScaleDesc;

  /// No description provided for @wgPlyAssOverrideTitle.
  ///
  /// In en, this message translates to:
  /// **'Override Colors & Outlines'**
  String get wgPlyAssOverrideTitle;

  /// No description provided for @wgPlyAssOverrideDesc.
  ///
  /// In en, this message translates to:
  /// **'Applies your custom colors and outlines on top of SSA/ASS subtitle scripts.'**
  String get wgPlyAssOverrideDesc;

  /// No description provided for @wgPlyAssForceTitle.
  ///
  /// In en, this message translates to:
  /// **'Force Full Override (Aggressive)'**
  String get wgPlyAssForceTitle;

  /// No description provided for @wgPlyAssForceDesc.
  ///
  /// In en, this message translates to:
  /// **'Forces all custom fonts, colors, and styles onto all subtitle formats (may break anime effects).'**
  String get wgPlyAssForceDesc;

  /// No description provided for @wgPlySubRenderingEngine.
  ///
  /// In en, this message translates to:
  /// **'SUBTITLE RENDERING ENGINE'**
  String get wgPlySubRenderingEngine;

  /// No description provided for @wgPlyFlutterSubEngine.
  ///
  /// In en, this message translates to:
  /// **'Flutter Subtitle Engine (Recommended)'**
  String get wgPlyFlutterSubEngine;

  /// No description provided for @wgPlyFlutterSubEngineDesc.
  ///
  /// In en, this message translates to:
  /// **'100% reliable hardware-accelerated subtitle overlay across Android, iOS, Windows, Mac, and Linux with full styling support.'**
  String get wgPlyFlutterSubEngineDesc;

  /// No description provided for @wgPlyMpvLibassEngine.
  ///
  /// In en, this message translates to:
  /// **'Native MPV libass Engine'**
  String get wgPlyMpvLibassEngine;

  /// No description provided for @wgPlyMpvLibassEngineDesc.
  ///
  /// In en, this message translates to:
  /// **'Direct GPU video texture rendering powered by libass with bundled Poppins font and SSA/ASS script layout support.'**
  String get wgPlyMpvLibassEngineDesc;

  /// No description provided for @wgPlyAssOverrideMode.
  ///
  /// In en, this message translates to:
  /// **'SSA / ASS FANSUB SCRIPT OVERRIDE MODE'**
  String get wgPlyAssOverrideMode;

  /// No description provided for @wgPlyCopyStreamUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy Stream URL'**
  String get wgPlyCopyStreamUrl;

  /// No description provided for @wgPlySyncSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving sync: {error}'**
  String wgPlySyncSaveError(Object error);

  /// No description provided for @wgPlySyncHintSection.
  ///
  /// In en, this message translates to:
  /// **'Tap first & last line of section, then tap line playing now and Sync from here.'**
  String get wgPlySyncHintSection;

  /// No description provided for @wgPlySyncHintFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap the line you hear right now, then tap Sync from here.'**
  String get wgPlySyncHintFirst;

  /// No description provided for @wgPlySyncHintSecond.
  ///
  /// In en, this message translates to:
  /// **'Point 1 set. If subtitles drift later on, tap Sync from here at a later line.'**
  String get wgPlySyncHintSecond;

  /// No description provided for @wgPlySyncMinChars.
  ///
  /// In en, this message translates to:
  /// **'3+ chars'**
  String get wgPlySyncMinChars;

  /// No description provided for @wgSrchMagnetNoFiles.
  ///
  /// In en, this message translates to:
  /// **'{service} returned no files for this magnet.'**
  String wgSrchMagnetNoFiles(Object service);

  /// No description provided for @wgSrchMagnetMetadataFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not retrieve torrent metadata from swarm. Check peer connectivity.'**
  String get wgSrchMagnetMetadataFailed;

  /// No description provided for @wgSrchUsingProvider.
  ///
  /// In en, this message translates to:
  /// **'Using {provider} for files...'**
  String wgSrchUsingProvider(Object provider);

  /// No description provided for @wgSrchConnectingPeers.
  ///
  /// In en, this message translates to:
  /// **'Connecting to swarm peers...'**
  String get wgSrchConnectingPeers;

  /// No description provided for @wgSrchGatheringFiles.
  ///
  /// In en, this message translates to:
  /// **'Gathering file list & stream metadata'**
  String get wgSrchGatheringFiles;

  /// No description provided for @wgSrchMagnetReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to Read Magnet'**
  String get wgSrchMagnetReadFailed;

  /// No description provided for @wgSrchTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get wgSrchTryAgain;

  /// No description provided for @wgSrchNoFilesMatch.
  ///
  /// In en, this message translates to:
  /// **'No files match filter'**
  String get wgSrchNoFilesMatch;

  /// No description provided for @wgSrchProviderCloud.
  ///
  /// In en, this message translates to:
  /// **'{provider} Cloud'**
  String wgSrchProviderCloud(Object provider);

  /// No description provided for @wgSrchP2pSwarm.
  ///
  /// In en, this message translates to:
  /// **'P2P Swarm'**
  String get wgSrchP2pSwarm;

  /// No description provided for @wgSrchFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {unit}'**
  String wgSrchFileCount(Object count, Object unit);

  /// No description provided for @wgSrchVideoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {unit}'**
  String wgSrchVideoCount(Object count, Object unit);

  /// No description provided for @wgSrchFilterFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Filter files by name...'**
  String get wgSrchFilterFilesHint;

  /// No description provided for @wgSrchChipAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String wgSrchChipAll(Object count);

  /// No description provided for @wgSrchChipVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos ({count})'**
  String wgSrchChipVideos(Object count);

  /// No description provided for @wgSrchChipOther.
  ///
  /// In en, this message translates to:
  /// **'Other ({count})'**
  String wgSrchChipOther(Object count);

  /// No description provided for @wgSrchPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get wgSrchPlay;

  /// No description provided for @wgSrchNonVideo.
  ///
  /// In en, this message translates to:
  /// **'Non-video'**
  String get wgSrchNonVideo;

  /// No description provided for @wgSrchKeySpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get wgSrchKeySpace;

  /// No description provided for @wgSrchKeyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get wgSrchKeyClear;

  /// No description provided for @wgSrchKeySearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get wgSrchKeySearch;

  /// No description provided for @wgUpdAvailableCaps.
  ///
  /// In en, this message translates to:
  /// **'UPDATE AVAILABLE'**
  String get wgUpdAvailableCaps;

  /// No description provided for @wgUpdVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String wgUpdVersion(Object version);

  /// No description provided for @wgUpdCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get wgUpdCurrent;

  /// No description provided for @wgUpdLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get wgUpdLatest;

  /// No description provided for @wgUpdWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'WHAT\'S NEW'**
  String get wgUpdWhatsNew;

  /// No description provided for @wgUpdNoReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'No release notes were published for this version.'**
  String get wgUpdNoReleaseNotes;

  /// No description provided for @wgUpdIosRedirect.
  ///
  /// In en, this message translates to:
  /// **'iOS: You\'ll be redirected to GitHub to download the IPA'**
  String get wgUpdIosRedirect;

  /// No description provided for @wgUpdMacRedirect.
  ///
  /// In en, this message translates to:
  /// **'macOS: You\'ll be redirected to GitHub to download'**
  String get wgUpdMacRedirect;

  /// No description provided for @wgUpdDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get wgUpdDownloading;

  /// No description provided for @wgUpdLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get wgUpdLater;

  /// No description provided for @wgUpdUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get wgUpdUpdateNow;

  /// No description provided for @wgUpdNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Update could not be verified'**
  String get wgUpdNotVerified;

  /// No description provided for @wgUpdCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get wgUpdCancel;

  /// No description provided for @wgUpdOpenReleasePage.
  ///
  /// In en, this message translates to:
  /// **'Open release page'**
  String get wgUpdOpenReleasePage;

  /// No description provided for @wgIptvChipMyPortals.
  ///
  /// In en, this message translates to:
  /// **'My Portals ({count})'**
  String wgIptvChipMyPortals(Object count);

  /// No description provided for @wgUpdNoChecksum.
  ///
  /// In en, this message translates to:
  /// **'This release does not publish a SHA-256 checksum, so Lumora will not install it automatically. Open the release page and verify the download yourself before installing it.'**
  String get wgUpdNoChecksum;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Light, shadow and every story worth watching'**
  String get authTagline;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get authInviteCode;

  /// No description provided for @authInviteHint.
  ///
  /// In en, this message translates to:
  /// **'An invite code is needed once, to create your account. Ask the admin for one.'**
  String get authInviteHint;

  /// No description provided for @authSubmitSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSubmitSignIn;

  /// No description provided for @authSubmitSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSubmitSignUp;

  /// No description provided for @authWorking.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get authWorking;

  /// No description provided for @authErrInvalidInvite.
  ///
  /// In en, this message translates to:
  /// **'This invite code is not valid, or has been used.'**
  String get authErrInvalidInvite;

  /// No description provided for @authErrInviteMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter your invite code.'**
  String get authErrInviteMissing;

  /// No description provided for @authErrWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get authErrWrongPassword;

  /// No description provided for @authErrEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Sign in instead.'**
  String get authErrEmailTaken;

  /// No description provided for @authErrWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use a password of at least 6 characters.'**
  String get authErrWeakPassword;

  /// No description provided for @authErrInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address doesn\'t look right.'**
  String get authErrInvalidEmail;

  /// No description provided for @authErrEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email first: open the link we sent you.'**
  String get authErrEmailNotConfirmed;

  /// No description provided for @authErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection.'**
  String get authErrNetwork;

  /// No description provided for @authErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrUnknown;

  /// No description provided for @authConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Account created. Open the link in your email, then sign in.'**
  String get authConfirmEmail;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @accountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String accountSignedInAs(String email);

  /// No description provided for @accountAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get accountAdmin;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Lumora on this device'**
  String get accountSignOutSubtitle;

  /// No description provided for @inviteManage.
  ///
  /// In en, this message translates to:
  /// **'Invite codes'**
  String get inviteManage;

  /// No description provided for @inviteManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make codes for friends to create an account'**
  String get inviteManageSubtitle;

  /// No description provided for @invitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite codes'**
  String get invitesTitle;

  /// No description provided for @invitesIntro.
  ///
  /// In en, this message translates to:
  /// **'Each code creates one account, once. Give it to a friend; they enter it when they create their account.'**
  String get invitesIntro;

  /// No description provided for @invitesNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional, e.g. who it\'s for)'**
  String get invitesNote;

  /// No description provided for @invitesGenerate.
  ///
  /// In en, this message translates to:
  /// **'Make {count}'**
  String invitesGenerate(int count);

  /// No description provided for @invitesCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied {code}'**
  String invitesCopied(String code);

  /// No description provided for @invitesCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get invitesCopy;

  /// No description provided for @invitesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No invite codes yet.'**
  String get invitesEmpty;

  /// No description provided for @invitesUnused.
  ///
  /// In en, this message translates to:
  /// **'Not used yet'**
  String get invitesUnused;

  /// No description provided for @invitesUsedBy.
  ///
  /// In en, this message translates to:
  /// **'Used by {email}'**
  String invitesUsedBy(String email);

  /// No description provided for @invitesCount.
  ///
  /// In en, this message translates to:
  /// **'{total} codes · {unused} unused'**
  String invitesCount(int total, int unused);

  /// No description provided for @invitesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the codes.'**
  String get invitesLoadFailed;

  /// No description provided for @invitesCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make codes.'**
  String get invitesCreateFailed;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccount;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to pick up your list and what you were watching.'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the invite code a friend gave you. Each code works once.'**
  String get authSignUpSubtitle;

  /// No description provided for @authFirstTime.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get authFirstTime;

  /// No description provided for @authUseInvite.
  ///
  /// In en, this message translates to:
  /// **'Sign up with an invite code'**
  String get authUseInvite;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authSignInInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInInstead;

  /// No description provided for @authDragToTurn.
  ///
  /// In en, this message translates to:
  /// **'Drag to turn'**
  String get authDragToTurn;

  /// No description provided for @authSwitchFigure.
  ///
  /// In en, this message translates to:
  /// **'Show {name}'**
  String authSwitchFigure(String name);

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get authPasswordHint;

  /// No description provided for @authInviteFieldHint.
  ///
  /// In en, this message translates to:
  /// **'ABCD-2345'**
  String get authInviteFieldHint;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get splashLoading;

  /// No description provided for @homeTodayTop.
  ///
  /// In en, this message translates to:
  /// **'Top {rank} today'**
  String homeTodayTop(int rank);

  /// No description provided for @homeKindSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get homeKindSeries;

  /// No description provided for @homeKindMovie.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get homeKindMovie;

  /// No description provided for @homeHeroNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get homeHeroNext;

  /// No description provided for @homeHeroPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get homeHeroPrevious;

  /// No description provided for @homeHeroSlide.
  ///
  /// In en, this message translates to:
  /// **'Slide {index}'**
  String homeHeroSlide(int index);

  /// No description provided for @moreAiPicks.
  ///
  /// In en, this message translates to:
  /// **'AI picks'**
  String get moreAiPicks;

  /// No description provided for @moreCalendar.
  ///
  /// In en, this message translates to:
  /// **'Airing calendar'**
  String get moreCalendar;

  /// No description provided for @browseMoviesTv.
  ///
  /// In en, this message translates to:
  /// **'Movies & TV'**
  String get browseMoviesTv;

  /// No description provided for @browseCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get browseCollections;

  /// No description provided for @browseManga.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get browseManga;

  /// No description provided for @browseBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get browseBooks;

  /// No description provided for @browseAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'Audiobooks'**
  String get browseAudiobooks;

  /// No description provided for @browseMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get browseMusic;

  /// No description provided for @liveCatPremier.
  ///
  /// In en, this message translates to:
  /// **'Premier Live Broadcasts'**
  String get liveCatPremier;

  /// No description provided for @liveCatEspn.
  ///
  /// In en, this message translates to:
  /// **'ESPN & College Basketball (NCAA)'**
  String get liveCatEspn;

  /// No description provided for @liveCatUsSports.
  ///
  /// In en, this message translates to:
  /// **'US Major Leagues & Sports'**
  String get liveCatUsSports;

  /// No description provided for @liveCatSoccer.
  ///
  /// In en, this message translates to:
  /// **'Global Football & Soccer'**
  String get liveCatSoccer;

  /// No description provided for @liveCatBoxing.
  ///
  /// In en, this message translates to:
  /// **'Boxing'**
  String get liveCatBoxing;

  /// No description provided for @liveCatCombat.
  ///
  /// In en, this message translates to:
  /// **'Combat & Martial Arts'**
  String get liveCatCombat;

  /// No description provided for @liveCatRacing.
  ///
  /// In en, this message translates to:
  /// **'Motorsport & Racing'**
  String get liveCatRacing;

  /// No description provided for @liveCatMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies & Premium Networks'**
  String get liveCatMovies;

  /// No description provided for @liveCatNews.
  ///
  /// In en, this message translates to:
  /// **'24/7 Global News Networks'**
  String get liveCatNews;

  /// No description provided for @liveCatArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic & Regional Hub'**
  String get liveCatArabic;

  /// No description provided for @liveCatDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery & Documentaries'**
  String get liveCatDiscovery;

  /// No description provided for @liveCatKids.
  ///
  /// In en, this message translates to:
  /// **'Kids & Family'**
  String get liveCatKids;

  /// No description provided for @liveCatUs.
  ///
  /// In en, this message translates to:
  /// **'US Region'**
  String get liveCatUs;

  /// No description provided for @liveCatUk.
  ///
  /// In en, this message translates to:
  /// **'UK Region'**
  String get liveCatUk;

  /// No description provided for @liveCatCanada.
  ///
  /// In en, this message translates to:
  /// **'Canada Region'**
  String get liveCatCanada;

  /// No description provided for @liveCatBayArea.
  ///
  /// In en, this message translates to:
  /// **'Bay Area'**
  String get liveCatBayArea;

  /// No description provided for @liveCatIntlSports.
  ///
  /// In en, this message translates to:
  /// **'International Sports'**
  String get liveCatIntlSports;

  /// No description provided for @liveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live channels from your sources'**
  String get liveSubtitle;

  /// No description provided for @listSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String listSummary(int count);

  /// No description provided for @dscRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get dscRequired;

  /// No description provided for @dscEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get dscEnter;

  /// No description provided for @dscTypeTv.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get dscTypeTv;

  /// No description provided for @dscTypeChannel.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get dscTypeChannel;

  /// No description provided for @tvStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped.'**
  String get tvStatusStopped;

  /// No description provided for @tvStatusDiscovering.
  ///
  /// In en, this message translates to:
  /// **'Discovering fresh portals…'**
  String get tvStatusDiscovering;

  /// No description provided for @tvStatusNoMore.
  ///
  /// In en, this message translates to:
  /// **'No more portals available.'**
  String get tvStatusNoMore;

  /// No description provided for @tvStatusVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying {count} portals…'**
  String tvStatusVerifying(int count);

  /// No description provided for @tvStatusVerifyingProgress.
  ///
  /// In en, this message translates to:
  /// **'Verifying portals {done}/{total} · {active} active'**
  String tvStatusVerifyingProgress(int done, int total, int active);

  /// No description provided for @tvStatusScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning {count} portals in parallel…'**
  String tvStatusScanning(int count);

  /// No description provided for @tvStatusFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count} streams · verifying health…'**
  String tvStatusFound(int count);

  /// No description provided for @tvStatusSniffing.
  ///
  /// In en, this message translates to:
  /// **'Sniffing {checked}/{total} · {live} verified live'**
  String tvStatusSniffing(int checked, int total, int live);

  /// No description provided for @tvGuideFromPanel.
  ///
  /// In en, this message translates to:
  /// **'Programme data comes from the channel\'s own panel, so it appears once one of your portals has a verified live feed for {channel}.'**
  String tvGuideFromPanel(String channel);

  /// No description provided for @liveCatSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get liveCatSports;

  /// No description provided for @liveCatSoccerShort.
  ///
  /// In en, this message translates to:
  /// **'Soccer'**
  String get liveCatSoccerShort;

  /// No description provided for @liveCatMoviesShort.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get liveCatMoviesShort;

  /// No description provided for @liveCatNewsShort.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get liveCatNewsShort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
