import '../../services/account/account_service.dart';
import '../account/invite_codes_page.dart';
import '../../shell/app_shell_scope.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../services/addon/addon_manager.dart';
import '../../services/theme/app_theme_service.dart';
import '../../services/theme/design_tokens.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';
import '../../services/debrid/debrid_service.dart';
import '../../services/theme/glass_settings.dart';
import '../../services/trakt/trakt_service.dart';
import '../../services/simkl/simkl_service.dart';
import '../../services/metadata/tmdb_service.dart';
import '../../services/metadata/metadata_service.dart';
import '../../services/hero/hero_media_resolver.dart';
import '../../services/metadata/trailer_resolver.dart';
import '../../services/storage/app_image_cache.dart';
import '../../services/config/service_credentials.dart';

import 'appearance_settings_page.dart';
import 'video_settings_page.dart';
import 'debrid_settings_page.dart';
import 'addons_settings_page.dart';
import 'builtin_providers_settings_page.dart';
import 'trakt_settings_page.dart';
import 'simkl_settings_page.dart';
import 'tmdb_settings_page.dart';
import 'service_keys_settings_page.dart';
import 'updates_settings_page.dart';
import 'diagnostics_page.dart';
import 'language_settings_page.dart';
import 'about_settings_page.dart';
import '../../services/player/player_settings.dart';
import '../../services/p2p/p2p_settings_service.dart';
import '../../services/scraper/builtin_providers_settings_service.dart';
import '../../widgets/p2p/p2p_warning_dialog.dart';
import '../../services/discord/discord_rpc_service.dart';
import '../../services/backup/backup_restore_service.dart';
import '../../services/home/home_page_settings.dart';
import '../../services/content/content_settings.dart';


/// Third-party brand hues. These identify an external service, so they stay
/// outside the palette-derived token layer.
const Color _traktBrand = Color(0xFFED1C24);
const Color _simklBrand = Color(0xFF00ADFF);
const Color _discordBrand = Color(0xFF5865F2);

/// Import the profile pushed to the device, without navigating to it.
///
/// A compile-time constant, so a normal build carries the string and never the
/// value. It exists because reaching this dialog on a television is a dozen
/// D-pad presses, and a test that has to drive the remote cannot confirm which
/// row it pressed - only the screen it ended up on, which was the same problem
/// nine separate defects were diagnosed through.
const bool autoImportFromFile = bool.fromEnvironment('ZPLAY_AUTO_IMPORT');

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// One subscription for the hub row's set count; the notifiers are static
  /// finals, so the merge is built once instead of on every rebuild.
  static final Listenable _serviceCredentials = Listenable.merge([
    for (final credential in ServiceCredential.values)
      ServiceCredentials.notifier(credential),
  ]);

  final _debrid = DebridService();
  bool _useDebrid = false;
  String _debridProvider = 'None';
  String? _appVersion;
  bool _traktConnected = false;
  bool _simklConnected = false;

  void _showBackupRestoreDialog() {
    final passphraseController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final tokens = ctx.tokens;
        final l10n = l10nOf(ctx);
        return Dialog(
          backgroundColor: tokens.surfaceOverlay,
          shape: RoundedRectangleBorder(
            borderRadius: ZplayRadius.lgAll,
            side: tokens.hairlineStrong,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(ZplaySpacing.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tokens.success.withValues(
                            alpha: ZplayOpacity.overlayHover,
                          ),
                          borderRadius: ZplayRadius.smAll,
                        ),
                        child: Icon(
                          Icons.backup_rounded,
                          color: tokens.success,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.settingsBackupTitle,
                              style: ZplayType.title.toStyle(
                                color: tokens.textPrimary,
                              ),
                            ),
                            Text(
                              l10n.settingsBackupDialogSubtitle,
                              style: ZplayType.bodySmall.toStyle(
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: tokens.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        style: _iconButtonFocusStyle(tokens),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.settingsBackupDescription,
                    style: ZplayType.body.toStyle(color: tokens.textEmphasis),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passphraseController,
                    obscureText: true,
                    style: ZplayType.bodySmall.toStyle(
                      color: tokens.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.settingsPassphraseOptional,
                      helperText: l10n.settingsPassphraseHelper,
                      helperStyle: ZplayType.bodySmall.toStyle(
                        color: tokens.textSecondary,
                      ),
                      filled: true,
                      fillColor: tokens.surface,
                      border: OutlineInputBorder(
                        borderRadius: ZplayRadius.smAll,
                        borderSide: BorderSide(color: tokens.borderDefault),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: const RoundedRectangleBorder(
                              borderRadius: ZplayRadius.smAll,
                            ),
                          ),
                          icon: const Icon(
                            Icons.file_upload_outlined,
                            size: 18,
                          ),
                          label: Text(
                            l10n.settingsExportProfile,
                            style: ZplayType.label.toStyle(),
                          ),
                          onPressed: () async {
                            final passphrase = passphraseController.text;
                            if (passphrase.isNotEmpty &&
                                passphrase.length < 8) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.settingsPassphraseTooShort,
                                  ),
                                ),
                              );
                              return;
                            }
                            final jsonStr =
                                await BackupRestoreService.exportSettingsJson(
                                  passphrase: passphrase.isEmpty
                                      ? null
                                      : passphrase,
                                );
                            await Clipboard.setData(
                              ClipboardData(text: jsonStr),
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    passphrase.isEmpty
                                        ? l10n.settingsRedactedProfileCopied
                                        : l10n.settingsEncryptedProfileCopied,
                                  ),
                                  backgroundColor: tokens.success,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: tokens.textPrimary,
                            side: BorderSide(color: tokens.borderStrong),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: const RoundedRectangleBorder(
                              borderRadius: ZplayRadius.smAll,
                            ),
                          ),
                          icon: const Icon(
                            Icons.file_download_outlined,
                            size: 18,
                          ),
                          label: Text(
                            l10n.settingsImportJson,
                            style: ZplayType.label.toStyle(),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showImportJsonInputDialog(
                              initialPassphrase: passphraseController.text,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImportJsonInputDialog({String initialPassphrase = ''}) {
    final textController = TextEditingController();
    final passphraseController = TextEditingController(text: initialPassphrase);
    showDialog(
      context: context,
      builder: (ctx) {
        final tokens = ctx.tokens;
        final l10n = l10nOf(ctx);
        return Dialog(
          backgroundColor: tokens.surfaceOverlay,
          shape: RoundedRectangleBorder(
            borderRadius: ZplayRadius.lgAll,
            side: tokens.hairlineStrong,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(ZplaySpacing.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.file_download_outlined,
                        color: tokens.accent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.settingsPasteJsonTitle,
                        style: ZplayType.title.toStyle(
                          color: tokens.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: tokens.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        style: _iconButtonFocusStyle(tokens),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    maxLines: 8,
                    style: ZplayType.bodySmall
                        .toStyle(color: tokens.textPrimary)
                        .copyWith(fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: l10n.settingsPasteJsonHint,
                      hintStyle: ZplayType.bodySmall.toStyle(
                        color: tokens.textDisabled,
                      ),
                      filled: true,
                      fillColor: tokens.surface,
                      border: OutlineInputBorder(
                        borderRadius: ZplayRadius.smAll,
                        borderSide: BorderSide(color: tokens.borderDefault),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passphraseController,
                    obscureText: true,
                    style: ZplayType.bodySmall.toStyle(
                      color: tokens.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.settingsPassphraseEncrypted,
                      helperText: l10n.settingsPassphraseEncryptedHelper,
                      helperStyle: ZplayType.bodySmall.toStyle(
                        color: tokens.textSecondary,
                      ),
                      filled: true,
                      fillColor: tokens.surface,
                      border: OutlineInputBorder(
                        borderRadius: ZplayRadius.smAll,
                        borderSide: BorderSide(color: tokens.borderDefault),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          Icons.paste_rounded,
                          size: 16,
                          color: tokens.accent,
                        ),
                        label: Text(
                          l10n.settingsPasteFromClipboard,
                          style: ZplayType.label.toStyle(color: tokens.accent),
                        ),
                        onPressed: () async {
                          final data = await Clipboard.getData(
                            Clipboard.kTextPlain,
                          );
                          if (data?.text != null) {
                            textController.text = data!.text!;
                          }
                        },
                      ),
                      const Spacer(),
                      // A whole profile is ~200 KB of JSON. Typing that into a
                      // text field with a remote is not a task anyone should
                      // attempt, so a file already on the device is a first
                      // class way in rather than something a user has to work
                      // around.
                      TextButton.icon(
                        icon: Icon(
                          Icons.folder_open_rounded,
                          size: 16,
                          color: tokens.accent,
                        ),
                        label: Text(
                          l10n.settingsFromFile,
                          style: ZplayType.label.toStyle(color: tokens.accent),
                        ),
                        onPressed: () => _importFromFile(
                          passphrase: passphraseController.text,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.accent,
                          foregroundColor: tokens.onAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: ZplayRadius.smAll,
                          ),
                        ),
                        child: Text(
                          l10n.settingsRestoreNow,
                          style: ZplayType.label.toStyle(),
                        ),
                        onPressed: () async {
                          final txt = textController.text.trim();
                          if (txt.isEmpty) return;
                          try {
                            final msg =
                                await BackupRestoreService.importSettingsJson(
                                  txt,
                                  passphrase: passphraseController.text.isEmpty
                                      ? null
                                      : passphraseController.text,
                                );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (mounted) {
                              _loadOverviewState();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: tokens.success,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(l10n.settingsImportFailed('$e')),
                                backgroundColor: tokens.danger,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    BuiltinProvidersSettingsService.instance.init();
    _loadOverviewState();
    if (autoImportFromFile) {
      // After the first frame, so the dialog has a size to be laid out against
      // and the page behind it is already on screen. This is the scripted
      // route, so it searches the readable locations rather than putting a
      // file picker in front of a build that is meant to run unattended.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _importFromSearchPaths();
      });
    }
  }

  Future<void> _loadOverviewState() async {
    final useDebrid = await _debrid.getUseDebridForStreams();
    final provider = await _debrid.getSelectedService();
    final traktAuth = await TraktService.instance.isAuthenticated();
    final simklAuth = await SimklService.instance.isAuthenticated();
    final pkg = await PackageInfo.fromPlatform().catchError(
      (_) => PackageInfo(
        appName: 'ZPlay',
        packageName: 'io.github.tzero86.zplay',
        version: '1.1.6',
        buildNumber: '2019',
      ),
    );

    if (mounted) {
      setState(() {
        _useDebrid = useDebrid;
        _debridProvider = provider;
        _appVersion = pkg.version;
        _traktConnected = traktAuth;
        _simklConnected = simklAuth;
      });
    }
  }

  /// Imports a profile from a file already on the device.
  ///
  /// "From File" opens the system picker, so the person chooses the file and
  /// the picker grants the app access to it. Under Android 14 scoped storage
  /// that grant is the only way to read a file in Downloads, which is why the
  /// button cannot just open a fixed path: the path is what was denied.
  /// [autoImportFromFile] takes the other route below, which searches the
  /// locations the app can read without anyone choosing anything.
  Future<void> _importFromFile({String? passphrase}) async {
    FilePickerResult? picked;
    try {
      // `withData` asks Android for the bytes of the document the picker
      // granted. The SAF URI behind it is not a path this process may open.
      picked = await FilePicker.platform.pickFiles(
        // Not restricted to `.json`: a provider that reports a profile as
        // `text/plain` would otherwise hide it from the picker.
        type: FileType.any,
        withData: true,
        dialogTitle: l10nOf(context).settingsChooseProfile,
      );
    } catch (_) {
      // A television with no document picker installed. Fall back to the
      // locations the app can read on its own rather than a dead button.
      await _importFromSearchPaths(passphrase: passphrase);
      return;
    }
    if (picked == null || picked.files.isEmpty) return; // cancelled
    final file = picked.files.first;
    await _reportImport(
      () => BackupRestoreService.importPickedProfile(
        bytes: file.bytes,
        path: file.path,
        name: file.name,
        passphrase: passphrase,
      ),
    );
  }

  /// Imports the profile pushed to one of the locations the app can read.
  ///
  /// This is what [autoImportFromFile] drives, so a build without a remote in
  /// front of it exercises exactly the import a person gets.
  Future<void> _importFromSearchPaths({String? passphrase}) => _reportImport(
    () async => BackupRestoreService.importSettingsFromFile(
      await BackupRestoreService.importSearchPaths(),
      passphrase: passphrase,
    ),
  );

  /// Runs an import and reports the outcome, shared by both ways in.
  Future<void> _reportImport(Future<String> Function() import) async {
    final tokens = context.tokens;
    final navigator = Navigator.of(context);
    // "Restore Now" and "From File" run from the import dialog and need it
    // closed afterwards, but the startup import ([autoImportFromFile]) runs
    // from this page's own post-frame callback with nothing on top of it -
    // and this page is a slot in the shell's [IndexedStack], not a pushed
    // route, so the shell is the only route in the navigator. Popping there
    // took the shell off the stack: the app stayed alive with nothing left to
    // paint, a uniform black screen with no way back, which is what a readable
    // profile at startup used to do. Close what is open, never the app.
    final hasDialogToClose = navigator.canPop();
    try {
      final msg = await import();
      if (!mounted) return;
      if (hasDialogToClose) navigator.pop();
      _loadOverviewState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: tokens.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // The service names the locations it tried and says the app can only
      // read its own directory, which is more use than the exception's type.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is FileSystemException && e.message.isNotEmpty
                ? e.message
                : l10nOf(context).settingsImportFailed('$e'),
            style: ZplayType.bodySmall.toStyle(color: tokens.textPrimary),
          ),
          backgroundColor: tokens.danger,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  /// The "Clear cache" control: empties every cache the app holds in memory or
  /// on disk - the artwork store, the metadata lookups and the hero media
  /// table - and touches nothing else. Profile, addons, My List, watch history
  /// and the P2P preference all survive, which is the whole point: the
  /// grievance this answers is a stale artwork response sticking with no way
  /// out short of a reinstall, and a reinstall wipes exactly the state this
  /// deliberately leaves alone.
  ///
  /// Each step runs in its own guard. A step that fails is named in the report
  /// instead of being swallowed, and the steps after it still run - one broken
  /// store must not spare the caches behind it.
  Future<void> _confirmAndClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tokens = ctx.tokens;
        final l10n = l10nOf(ctx);
        return AlertDialog(
          backgroundColor: tokens.surfaceOverlay,
          shape: const RoundedRectangleBorder(borderRadius: ZplayRadius.lgAll),
          title: Text(
            l10n.settingsClearCacheConfirmTitle,
            style: ZplayType.title.toStyle(color: tokens.textPrimary),
          ),
          content: Text(
            l10n.settingsClearCacheConfirmBody,
            style: ZplayType.body.toStyle(color: tokens.textEmphasis),
          ),
          actions: [
            TextButton(
              child: Text(
                l10n.actionCancel,
                style: ZplayType.label.toStyle(color: tokens.textSecondary),
              ),
              onPressed: () => Navigator.pop(ctx, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: tokens.onAccent,
              ),
              child: Text(l10n.settingsClear),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final tokens = context.tokens;
    final l10n = l10nOf(context);
    final messenger = ScaffoldMessenger.of(context);

    // One label per step, so the report names the store that failed instead of
    // a generic "something went wrong".
    final failures = <String>[];
    try {
      await AppImageCache.emptyCache();
    } catch (e) {
      failures.add(
        l10n.settingsCacheArtwork(e.toString().replaceFirst('Exception: ', '')),
      );
    }
    try {
      MetadataService.clearCache();
    } catch (e) {
      failures.add(
        l10n.settingsCacheMetadata(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
    try {
      HeroMediaResolver.clearCache();
    } catch (e) {
      failures.add(
        l10n.settingsCacheHero(e.toString().replaceFirst('Exception: ', '')),
      );
    }
    try {
      TrailerResolver.clearCache();
    } catch (e) {
      failures.add(
        l10n.settingsCacheHero(e.toString().replaceFirst('Exception: ', '')),
      );
    }

    final cleared = failures.isEmpty
        ? l10n.settingsCacheCleared
        : l10n.settingsCacheClearedExcept(failures.join(l10n.listSeparator));
    messenger.showSnackBar(
      SnackBar(
        content: Text('$cleared ${l10n.settingsCacheClearedSuffix}'),
        backgroundColor: failures.isEmpty ? tokens.success : tokens.danger,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _navigateTo(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    // Refresh badges when returning
    _loadOverviewState();
  }

  /// The hub's sections, in order. The split pane's sidebar lists these, and
  /// [_buildSection] anchors each one with the matching key.
  ///
  /// These are stable ids, not copy: they key [_sectionKeys] and [_activeSection]
  /// across rebuilds, so translating them in place would move every anchor the
  /// moment the language changed. [_sectionLabel] maps an id to the words the
  /// user sees.
  static List<String> get _sectionLabels => [
    if (AccountService.configured) 'ACCOUNT',
    'PLAYBACK',
    'SOURCES',
    'INTEGRATIONS',
    'APPEARANCE',
    'CONTENT',
    'APP',
  ];

  /// One anchor per section, created once so a sidebar tap can scroll the
  /// content pane to its group.
  final Map<String, GlobalKey> _sectionKeys = {
    for (final label in _sectionLabels) label: GlobalKey(),
  };

  String _activeSection = _sectionLabels.first;

  /// Scrolls the content pane to [label]'s group and marks it current.
  ///
  /// The prototype's sidebar swaps the pane; here every section is one
  /// continuously scrolling hub - the structure the page already had - so the
  /// sidebar indexes it instead of replacing it. That keeps every row mounted
  /// (and so every `_navigateTo` destination where it was) while still giving a
  /// television a single press to reach a group instead of a dozen.
  void _jumpToSection(String label) {
    if (label == _activeSection) {
      _scrollToSection(label);
      return;
    }
    setState(() => _activeSection = label);
    _scrollToSection(label);
  }

  void _scrollToSection(String label) {
    final sectionContext = _sectionKeys[label]?.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: ZplayMotion.base,
      curve: ZplayMotion.standard,
      alignment: 0,
    );
  }

  /// One labelled section: an overline heading over a group of rows that rest
  /// on the page canvas, split by hairline dividers instead of one card per row.
  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = l10nOf(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountSignOut),
        content: Text(l10n.accountSignOutSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.stgaCancel),
          ),
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.accountSignOut),
          ),
        ],
      ),
    );
    if (yes == true) await AccountService.signOut();
  }

  Widget _buildSection(
    BuildContext context,
    String label, {
    required List<Widget> rows,
    bool first = false,
  }) {
    final title = _sectionLabel(l10nOf(context), label);
    return Column(
      key: _sectionKeys[label],
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: LuText.label.copyWith(
              color: LuColors.textFaint,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // One rounded card per group, its rows divided inside it.
        DecoratedBox(
          decoration: BoxDecoration(
            color: LuColors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            border: Border.all(color: LuColors.lineSoft),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: _dividerSeparated(rows, LuColors.lineSoft),
            ),
          ),
        ),
      ],
    );
  }

  /// Returns [rows] with a hairline divider between each pair, so a section's
  /// rows still read as one group without a surface around them.
  static List<Widget> _dividerSeparated(List<Widget> rows, Color dividerColor) {
    final children = <Widget>[];
    for (final row in rows) {
      if (children.isNotEmpty) {
        children.add(Divider(color: dividerColor, height: 1));
      }
      children.add(row);
    }
    return children;
  }

  /// The page header, carrying the page's icon-button focus state.
  ///
  /// The header's leading control is the framework's own - a `BackButton`, or a
  /// `CloseButton` on a fullscreen-dialog route - so there is no `leading` here
  /// to style, and `AppBar` has no style parameter for it. `IconButtonTheme`
  /// above the bar reaches whatever the framework puts there.
  ///
  /// `PreferredSize` because the scaffold's `appBar` slot takes a
  /// `PreferredSizeWidget` and `IconButtonTheme` is not one; it only restates
  /// the height `AppBar` reports itself.
  PreferredSizeWidget _appBar(BuildContext context, ZplayTokens tokens) {
    final bar = AppBar(
      // Transparent, no hairline: Settings is a shell slot, and the shell's nav
      // blends over every slot now. An opaque palette band pinned across the
      // strip the nav rests on is the seam that blend exists to remove - the
      // canvas below is the band, and the nav sits on it directly.
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      // No explicit leading: the framework already gates the back button on canPop,
      // so it vanishes in the shell and returns if this page is pushed.
      toolbarHeight: 72,
      titleSpacing: MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
      title: Text(
        l10nOf(context).navMe,
        style: LuText.title.copyWith(fontSize: 30),
      ),
    );

    return PreferredSize(
      preferredSize: bar.preferredSize,
      child: IconButtonTheme(
        data: IconButtonThemeData(style: _iconButtonFocusStyle(tokens)),
        child: bar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addonCount = AddonManager.instance.addons.length;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final tokens = context.tokens;

    // The canvas wraps the `Scaffold`, not its `body`, so it paints behind the
    // (now transparent) header too: the nav bar rests on it and the title sits
    // on the same surface as the rows instead of on a strip of its own.
    return Theme(
      data: luTheme(),
      child: Scaffold(
        backgroundColor: LuColors.bg,
        appBar: _appBar(context, tokens),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // 240 dp of sidebar beside a readable pane is what the prototype's
            // split pane needs. Below that the two do not both fit, so the hub
            // stacks as the single column it was.
            final split = constraints.maxWidth >= 720;
            final content = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                // `SingleChildScrollView` + `Column`, not a `ListView`.
                //
                // A `ListView` builds only what is near the viewport, so on a
                // 540 dp television the sections below the fold have no element
                // and no `currentContext` - and the sidebar's `ensureVisible`
                // would silently do nothing for every section but the first few.
                // A settings hub is a dozen rows, so building them all costs
                // nothing and makes every anchor real.
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    split ? ZplaySpacing.s24 : ZplaySpacing.s16,
                    ZplaySpacing.s20,
                    split ? ZplaySpacing.s24 : ZplaySpacing.s16,
                    ZplaySpacing.s32 + bottomInset,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (AccountService.configured &&
                          AccountService.email != null) ...[
                        const _ProfileCard(),
                        const SizedBox(height: 32),
                      ],
                      if (AccountService.configured)
                        _buildSection(
                          context,
                          'ACCOUNT',
                          first: true,
                          rows: [
                            _SettingsNavRow(
                              icon: Icons.account_circle_rounded,
                              iconColor: tokens.accent,
                              title: l10nOf(
                                context,
                              ).accountSignedInAs(AccountService.email ?? ''),
                              subtitle: l10nOf(context).accountSignOutSubtitle,
                              valueText: l10nOf(context).accountSignOut,
                              onTap: () => _confirmSignOut(context),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: ContentSettings.isAdmin,
                              builder: (context, admin, _) => admin
                                  ? _SettingsNavRow(
                                      icon: Icons.confirmation_number_outlined,
                                      iconColor: tokens.accent,
                                      title: l10nOf(context).inviteManage,
                                      subtitle: l10nOf(
                                        context,
                                      ).inviteManageSubtitle,
                                      valueText: l10nOf(context).accountAdmin,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const InviteCodesPage(),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      _buildSection(
                        context,
                        'PLAYBACK',
                        first: !AccountService.configured,
                        rows: [
                          // 更多内容: manga, books, audiobooks, music and the
                          // other verticals that have no tab of their own.
                          _SettingsNavRow(
                            icon: Icons.grid_view_rounded,
                            iconColor: tokens.accent,
                            title: l10nOf(context).navMore,
                            subtitle: l10nOf(context).settingsMoreSubtitle,
                            onTap: () =>
                                AppShellScope.of(context)?.go(ShellSlot.browse),
                          ),
                          // Video & Anime4K Upscaling
                          ValueListenableBuilder<Anime4KPreset>(
                            valueListenable: PlayerSettings.anime4kPreset,
                            builder: (context, anime4kPreset, _) {
                              return _SettingsNavRow(
                                icon: Icons.auto_awesome_rounded,
                                iconColor: tokens.accent,
                                title: l10nOf(context).settingsVideoTitle,
                                subtitle: l10nOf(context).settingsVideoSubtitle,
                                valueText: anime4kPreset == Anime4KPreset.off
                                    ? l10nOf(context).stateOff
                                    : anime4kPreset.label
                                          .split('(')
                                          .first
                                          .trim(),
                                onTap: () =>
                                    _navigateTo(const VideoSettingsPage()),
                              );
                            },
                          ),
                          // Built-in P2P Torrent Source Toggle (ZPlay)
                          ValueListenableBuilder<bool>(
                            valueListenable: P2pSettingsService.isP2pEnabled,
                            builder: (context, isP2p, _) {
                              return _SettingsSwitchRow(
                                icon: Icons.hub_rounded,
                                iconColor: isP2p
                                    ? tokens.warning
                                    : tokens.textSecondary,
                                title: l10nOf(context).settingsP2pTitle,
                                subtitle: isP2p
                                    ? l10nOf(context).settingsP2pActiveSubtitle
                                    : l10nOf(
                                        context,
                                      ).settingsP2pDisabledSubtitle,
                                valueText: isP2p
                                    ? l10nOf(context).settingsP2pActiveValue
                                    : l10nOf(context).settingsP2pHttpValue,
                                value: isP2p,
                                onChanged: (val) async {
                                  await P2pSettingsService.setP2pEnabled(val);
                                },
                                onInfoTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const P2pWarningDialog(),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),

                      _buildSection(
                        context,
                        'SOURCES',
                        rows: [
                          // Metadata & Catalogs (Addons)
                          _SettingsNavRow(
                            icon: Icons.extension_rounded,
                            iconColor: tokens.accent,
                            title: l10nOf(context).settingsAddonsTitle,
                            subtitle: l10nOf(context).settingsAddonsSubtitle,
                            valueText: l10nOf(
                              context,
                            ).settingsAddonsInstalled(addonCount),
                            onTap: () =>
                                _navigateTo(const AddonsSettingsPage()),
                          ),
                          // Built-in Providers (ZPlayHTTP)
                          ListenableBuilder(
                            listenable:
                                BuiltinProvidersSettingsService.instance,
                            builder: (context, _) {
                              final isCustom = BuiltinProvidersSettingsService
                                  .instance
                                  .isCustom;
                              return _SettingsNavRow(
                                icon: Icons.dns_rounded,
                                iconColor: isCustom
                                    ? tokens.accent
                                    : tokens.success,
                                title: l10nOf(context).settingsBuiltinTitle,
                                subtitle: l10nOf(
                                  context,
                                ).settingsBuiltinSubtitle,
                                valueText: isCustom
                                    ? l10nOf(context).settingsBuiltinCustom
                                    : l10nOf(context).settingsBuiltinDefault,
                                onTap: () => _navigateTo(
                                  const BuiltinProvidersSettingsPage(),
                                ),
                              );
                            },
                          ),
                          // Debrid & Cloud Streaming
                          _SettingsNavRow(
                            icon: Icons.cloud_download_rounded,
                            iconColor: tokens.accent,
                            title: l10nOf(context).settingsDebridTitle,
                            subtitle: l10nOf(context).settingsDebridSubtitle,
                            valueText: _useDebrid
                                ? (_debridProvider != 'None'
                                      ? _debridProvider
                                      : l10nOf(context).stateActive)
                                : l10nOf(context).stateDisabled,
                            onTap: () =>
                                _navigateTo(const DebridSettingsPage()),
                          ),
                        ],
                      ),

                      _buildSection(
                        context,
                        'INTEGRATIONS',
                        rows: [
                          // Trakt Sync
                          _SettingsNavRow(
                            icon: Icons.movie_filter_rounded,
                            iconColor: _traktBrand,
                            title: l10nOf(context).settingsTraktTitle,
                            subtitle: l10nOf(context).settingsTraktSubtitle,
                            valueText: _traktConnected
                                ? l10nOf(context).stateConnected
                                : l10nOf(context).stateOffline,
                            onTap: () => _navigateTo(const TraktSettingsPage()),
                          ),
                          // Simkl Sync
                          _SettingsNavRow(
                            icon: Icons.tv_rounded,
                            iconColor: _simklBrand,
                            title: l10nOf(context).settingsSimklTitle,
                            subtitle: l10nOf(context).settingsSimklSubtitle,
                            valueText: _simklConnected
                                ? l10nOf(context).stateConnected
                                : l10nOf(context).stateOffline,
                            onTap: () => _navigateTo(const SimklSettingsPage()),
                          ),
                          // TMDb API Key (bring your own)
                          ListenableBuilder(
                            listenable: TmdbService.apiKey,
                            builder: (context, _) => _SettingsNavRow(
                              icon: Icons.theaters_rounded,
                              iconColor: tokens.accent,
                              title: l10nOf(context).settingsTmdbTitle,
                              subtitle: l10nOf(context).settingsTmdbSubtitle,
                              valueText: TmdbService.isConfigured
                                  ? l10nOf(context).settingsTmdbYourKey
                                  : l10nOf(context).stateNotSet,
                              onTap: () =>
                                  _navigateTo(const TmdbSettingsPage()),
                            ),
                          ),
                          // Service API Keys (bring your own)
                          ListenableBuilder(
                            listenable: _serviceCredentials,
                            builder: (context, _) {
                              final provided = ServiceCredential.values
                                  .where(ServiceCredentials.isUserProvided)
                                  .length;
                              return _SettingsNavRow(
                                icon: Icons.key_rounded,
                                iconColor: tokens.accent,
                                title: l10nOf(context).settingsServiceKeysTitle,
                                subtitle: l10nOf(
                                  context,
                                ).settingsServiceKeysSubtitle,
                                valueText: l10nOf(context)
                                    .settingsServiceKeysCount(
                                      provided,
                                      ServiceCredential.values.length,
                                    ),
                                onTap: () => _navigateTo(
                                  const ServiceKeysSettingsPage(),
                                ),
                              );
                            },
                          ),
                          // Discord Rich Presence (Desktop Only)
                          if (Platform.isWindows ||
                              Platform.isLinux ||
                              Platform.isMacOS)
                            ValueListenableBuilder<bool>(
                              valueListenable:
                                  DiscordRpcService.instance.isEnabled,
                              builder: (context, isDiscordEnabled, _) {
                                return _SettingsSwitchRow(
                                  icon: Icons.sports_esports_rounded,
                                  iconColor: isDiscordEnabled
                                      ? _discordBrand
                                      : tokens.textSecondary,
                                  title: l10nOf(context).settingsDiscordTitle,
                                  subtitle: isDiscordEnabled
                                      ? l10nOf(
                                          context,
                                        ).settingsDiscordEnabledSubtitle
                                      : l10nOf(
                                          context,
                                        ).settingsDiscordDisabledSubtitle,
                                  valueText: isDiscordEnabled
                                      ? l10nOf(context).stateActive
                                      : l10nOf(context).stateDisabled,
                                  value: isDiscordEnabled,
                                  onChanged: (val) async {
                                    await DiscordRpcService.instance.setEnabled(
                                      val,
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ),

                      _buildSection(
                        context,
                        'APPEARANCE',
                        rows: [
                          // Appearance & Interface
                          ValueListenableBuilder<bool>(
                            valueListenable: GlassSettings.enabled,
                            builder: (context, glassEnabled, _) {
                              return ValueListenableBuilder<AppThemePalette>(
                                valueListenable: AppThemeService.currentPalette,
                                builder: (context, currentPalette, _) {
                                  return _SettingsNavRow(
                                    icon: Icons.palette_rounded,
                                    iconColor: tokens.accent,
                                    title: l10nOf(
                                      context,
                                    ).settingsAppearanceTitle,
                                    subtitle: l10nOf(
                                      context,
                                    ).settingsAppearanceSubtitle,
                                    valueText: glassEnabled
                                        ? '${currentPalette.name} · ${l10nOf(context).settingsGlassOn}'
                                        : currentPalette.name,
                                    onTap: () => _navigateTo(
                                      const AppearanceSettingsPage(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),

                      _buildSection(
                        context,
                        'CONTENT',
                        rows: [
                          // TV Airing Calendar Toggle
                          ValueListenableBuilder<bool>(
                            valueListenable: HomePageSettings.enableCalendar,
                            builder: (context, isCalEnabled, _) {
                              return _SettingsSwitchRow(
                                icon: Icons.calendar_month_rounded,
                                iconColor: isCalEnabled
                                    ? tokens.info
                                    : tokens.textSecondary,
                                title: l10nOf(context).settingsCalendarTitle,
                                subtitle: isCalEnabled
                                    ? l10nOf(context).settingsCalendarOnSubtitle
                                    : l10nOf(
                                        context,
                                      ).settingsCalendarOffSubtitle,
                                valueText: isCalEnabled
                                    ? l10nOf(context).stateEnabled
                                    : l10nOf(context).stateDisabled,
                                value: isCalEnabled,
                                onChanged: (val) async {
                                  await HomePageSettings.setEnableCalendar(val);
                                },
                              );
                            },
                          ),
                          // AI Recommendation Quiz Toggle
                          ValueListenableBuilder<bool>(
                            valueListenable: HomePageSettings.enableAiQuiz,
                            builder: (context, isAiEnabled, _) {
                              return _SettingsSwitchRow(
                                icon: Icons.auto_awesome_rounded,
                                iconColor: isAiEnabled
                                    ? tokens.accent
                                    : tokens.textSecondary,
                                title: l10nOf(context).settingsAiQuizTitle,
                                subtitle: isAiEnabled
                                    ? l10nOf(context).settingsAiQuizOnSubtitle
                                    : l10nOf(context).settingsAiQuizOffSubtitle,
                                valueText: isAiEnabled
                                    ? l10nOf(context).stateEnabled
                                    : l10nOf(context).stateDisabled,
                                value: isAiEnabled,
                                onChanged: (val) async {
                                  await HomePageSettings.setEnableAiQuiz(val);
                                },
                              );
                            },
                          ),
                          // Adult Content (18+) Global Switch - admins only
                          ValueListenableBuilder<bool>(
                            valueListenable: ContentSettings.isAdmin,
                            builder: (context, isAdmin, _) => !isAdmin
                                ? const SizedBox.shrink()
                                : ValueListenableBuilder<bool>(
                            valueListenable: ContentSettings.adultEnabled,
                            builder: (context, isAdultOn, _) {
                              return _SettingsSwitchRow(
                                icon: Icons.eighteen_up_rating_rounded,
                                iconColor: isAdultOn
                                    ? tokens.danger
                                    : tokens.textSecondary,
                                title: l10nOf(context).settingsAdultTitle,
                                subtitle: isAdultOn
                                    ? l10nOf(context).settingsAdultOnSubtitle
                                    : l10nOf(context).settingsAdultOffSubtitle,
                                valueText: isAdultOn
                                    ? l10nOf(context).stateOn
                                    : l10nOf(context).stateOff,
                                value: isAdultOn,
                                onChanged: (val) async {
                                  await ContentSettings.setAdultEnabled(val);
                                },
                              );
                            },
                          ),
                          ),
                        ],
                      ),

                      _buildSection(
                        context,
                        'APP',
                        rows: [
                          // Backup & Restore (JSON)
                          _SettingsNavRow(
                            icon: Icons.backup_rounded,
                            iconColor: tokens.accent,
                            title: l10nOf(context).settingsBackupTitle,
                            subtitle: l10nOf(context).settingsBackupSubtitle,
                            valueText: 'JSON',
                            onTap: _showBackupRestoreDialog,
                          ),
                          // Cache cleanup (artwork + metadata, never user state)
                          _SettingsNavRow(
                            icon: Icons.cleaning_services_rounded,
                            iconColor: tokens.accent,
                            title: l10nOf(context).settingsClearCacheTitle,
                            subtitle: l10nOf(
                              context,
                            ).settingsClearCacheSubtitle,
                            onTap: _confirmAndClearCache,
                          ),
                          // App Updates & System
                          _SettingsNavRow(
                            icon: Icons.system_update_rounded,
                            iconColor: tokens.accent,
                            title: l10nOf(context).settingsUpdatesTitle,
                            subtitle: l10nOf(context).settingsUpdatesSubtitle,
                            valueText: _appVersion != null
                                ? 'v$_appVersion'
                                : l10nOf(context).settingsUpdatesCheck,
                            onTap: () =>
                                _navigateTo(const UpdatesSettingsPage()),
                          ),
                          // Diagnostics (local-only report)
                          _SettingsNavRow(
                            icon: Icons.monitor_heart_outlined,
                            iconColor: tokens.accent,
                            title: l10nOf(context).diagnosticsTitle,
                            subtitle: l10nOf(
                              context,
                            ).settingsDiagnosticsSubtitle,
                            onTap: () => _navigateTo(const DiagnosticsPage()),
                          ),
                          // Language (English / Arabic / system)
                          _SettingsNavRow(
                            icon: Icons.translate_rounded,
                            iconColor: tokens.accent,
                            title: l10nOf(context).languageTitle,
                            subtitle: l10nOf(context).settingsLanguageSubtitle,
                            onTap: () =>
                                _navigateTo(const LanguageSettingsPage()),
                          ),
                          // About ZPlay
                          _SettingsNavRow(
                            icon: Icons.info_outline_rounded,
                            iconColor: tokens.accent,
                            title: l10nOf(context).settingsAboutTitle,
                            subtitle: l10nOf(context).settingsAboutSubtitle,
                            onTap: () => _navigateTo(const AboutSettingsPage()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );

            if (!split) return content;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsSidebar(
                  sections: [
                    for (final id in _sectionLabels)
                      (id: id, label: _sectionLabel(l10nOf(context), id)),
                  ],
                  active: _activeSection,
                  onSelected: _jumpToSection,
                ),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Row
// ─────────────────────────────────────────────────────────────────────────────

/// A navigating settings row inside a grouped section: bare 20 px leading icon,
/// title and subtitle, with the row's value right-aligned ahead of the chevron.
class _SettingsNavRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? valueText;
  final VoidCallback onTap;

  const _SettingsNavRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.valueText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The whole row is the control and the ring is the row's own rect: on a
    // television the ring says what a press hits, and the whole row does.
    return LuFocusable(
      onTap: onTap,
      lift: 1,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      builder: (context, hi) => _SettingsRowBody(
        icon: icon,
        title: title,
        subtitle: subtitle,
        valueText: valueText,
        highlighted: hi,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 22,
          color: LuColors.textFaint,
        ),
      ),
    );
  }
}

/// One settings row's anatomy: a gold glyph in a soft disc, the name and what
/// it does, the value it holds, and the trailing control.
class _SettingsRowBody extends StatelessWidget {
  const _SettingsRowBody({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.highlighted,
    required this.trailing,
    this.valueText,
    this.titleTrailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final Widget trailing;
  final String? valueText;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: LuMotion.focus,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0x0FFFFFFF) : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x1FF2B544),
            ),
            child: Icon(icon, size: 19, color: LuColors.gold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: LuText.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: highlighted
                              ? LuColors.goldLight
                              : LuColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 6),
                      titleTrailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: LuText.caption.copyWith(color: LuColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (valueText != null) ...[
            const SizedBox(width: 12),
            // Capped, so on a narrow phone it gives way to the title rather
            // than pushing it to nothing.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width < 600 ? 72 : 220,
              ),
              child: Text(
                valueText!,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: LuText.caption.copyWith(
                  color: highlighted ? LuColors.text : LuColors.textMuted,
                ),
                maxLines: 1,
              ),
            ),
          ],
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Switch Row
// ─────────────────────────────────────────────────────────────────────────────

/// A toggle settings row inside a grouped section. Same anatomy as
/// [_SettingsNavRow], with the switch at the trailing edge instead of a chevron.
class _SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? valueText;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onInfoTap;

  const _SettingsSwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.valueText,
    required this.value,
    required this.onChanged,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    // The row is the focus target and its activation runs the same
    // [onChanged] the switch runs, so a remote and a pointer change the setting
    // identically.
    return LuFocusable(
      onTap: () => onChanged(!value),
      lift: 1,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      builder: (context, hi) => _SettingsRowBody(
        icon: icon,
        title: title,
        subtitle: subtitle,
        valueText: valueText,
        highlighted: hi,
        titleTrailing: onInfoTap == null
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: LuColors.textMuted,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                tooltip: l10nOf(context).settingsP2pInfoTooltip,
                onPressed: onInfoTap,
              ),
        // `ExcludeFocus`: the row is the focus target; a pointer still lands
        // on the switch itself.
        trailing: ExcludeFocus(
          child: Transform.scale(
            scale: 0.9,
            child: Switch.adaptive(
              value: value,
              activeThumbColor: LuColors.onGold,
              activeTrackColor: LuColors.gold,
              inactiveThumbColor: LuColors.textMuted,
              inactiveTrackColor: const Color(0x1FFFFFFF),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

/// What a settings section id is called in the active language.
///
/// The id stays English because it is the anchor key; only this mapping is
/// copy. An unknown id falls through unchanged, which keeps a section added by
/// a future change visible (in its own words) instead of blank.
String _sectionLabel(AppLocalizations l10n, String id) => switch (id) {
  'ACCOUNT' => l10n.accountSection,
  'PLAYBACK' => l10n.settingsSectionPlayback,
  'SOURCES' => l10n.settingsSectionSources,
  'INTEGRATIONS' => l10n.settingsSectionIntegrations,
  'APPEARANCE' => l10n.settingsSectionAppearance,
  'CONTENT' => l10n.settingsSectionContent,
  'APP' => l10n.settingsSectionApp,
  _ => id,
};

/// What a focused `IconButton` looks like on this page.
///
/// The theme gives every Material button a visible focus state - a
/// full-strength accent overlay and a 2 px accent border - but `IconButton`
/// does not read `elevatedButtonTheme`, `outlinedButtonTheme` or
/// `textButtonTheme`; it falls back to the framework's 12% tint, which is the
/// same invisible-at-ten-feet default the settings rows were left in.
///
/// It matters on a television here: the P2P row's advisory button and the two
/// dialog close buttons are `IconButton`s, and a remote lands on each of them
/// in the middle of the settings flow. Same answer the theme gives `TextButton`,
/// so the indicator is one convention rather than two.
ButtonStyle _iconButtonFocusStyle(ZplayTokens tokens) {
  return ButtonStyle(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) return tokens.accent;
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.pressed)) {
        return tokens.accentSubtle;
      }
      return null;
    }),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Split Pane
// ─────────────────────────────────────────────────────────────────────────────

/// The hub's section index, down the left of the split pane.
///
/// The prototype's settings screen is a split pane, and this is the part of it
/// that fits a hub whose subpages are pushed routes rather than swapped panels:
/// the sidebar names the groups, the pane keeps every group, and selecting a
/// name scrolls to it. Nothing that was reachable before is now behind a
/// selection, which is what a panel-swapping sidebar would have done to the
/// rows of five sections at a time.
class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({
    required this.sections,
    required this.active,
    required this.onSelected,
  });

  /// Section id plus the words to draw for it. The id is what selection and
  /// scrolling travel on, so changing language never moves the active anchor.
  final List<({String id, String label})> sections;
  final String active;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 8, 24),
        children: [
          for (final section in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SettingsSidebarItem(
                label: section.label,
                selected: section.id == active,
                onTap: () => onSelected(section.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// One section name in [_SettingsSidebar]: gold when current.
class _SettingsSidebarItem extends StatelessWidget {
  const _SettingsSidebarItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LuFocusable(
      onTap: onTap,
      lift: 1,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      builder: (context, hi) => AnimatedContainer(
        duration: LuMotion.focus,
        // 48 dp and up: the ten-foot floor.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0x1FF2B544)
              : (hi ? const Color(0x0FFFFFFF) : Colors.transparent),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LuText.body.copyWith(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? LuColors.gold : LuColors.textSoft,
          ),
        ),
      ),
    );
  }
}

/// Who is signed in: the gold initial, the account and, for an admin, the
/// badge.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final email = AccountService.email ?? '';
    final initial = email.isEmpty ? '?' : email.characters.first.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x26F2B544), Color(0x0AF2B544)],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: const Color(0x33F2B544)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: LuColors.gold,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: LuFonts.display,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: LuColors.onGold,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuText.heading,
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<bool>(
                  valueListenable: ContentSettings.isAdmin,
                  builder: (context, admin, _) => Text(
                    admin ? l10nOf(context).accountAdmin : 'Lumora',
                    style: LuText.caption.copyWith(
                      color: admin ? LuColors.gold : LuColors.textMuted,
                      fontWeight: admin ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
