import '../../l10n/l10n.dart';
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../services/theme/design_tokens.dart';
import '../../services/updater/app_updater_service.dart';
import '../common/whole_line_viewport.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  StreamSubscription? _otaSub;

  @override
  void dispose() {
    _otaSub?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Already reduced to the changelog section and stripped of Markdown by the
    // service; this is the last empty-body guard before the box renders.
    final releaseNotes = widget.updateInfo.releaseNotesForDisplay.trim();
    return PopScope(
      canPop: !_isDownloading,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_isDownloading) {
          AppUpdaterService.dismissVersion(widget.updateInfo.latestVersion);
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: tokens.surfaceOverlay,
            borderRadius: ZplayRadius.lgAll,
            border: Border.all(
              color: tokens.accent.withValues(alpha: ZplayOpacity.textDisabled),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: tokens.accent.withValues(
                  alpha: ZplayOpacity.overlayHover,
                ),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(ZplaySpacing.s24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tokens.accent.withValues(
                        alpha: ZplayOpacity.overlayHover,
                      ),
                      tokens.accent.withValues(alpha: ZplayOpacity.borderFaint),
                    ],
                  ),
                  borderRadius: ZplayRadius.sheetTop,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(ZplaySpacing.s12),
                      decoration: BoxDecoration(
                        color: tokens.accent.withValues(
                          alpha: ZplayOpacity.overlayHover,
                        ),
                        borderRadius: ZplayRadius.smAll,
                      ),
                      child: Icon(
                        Icons.system_update_rounded,
                        color: tokens.accent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: ZplaySpacing.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10nCurrent().wgUpdAvailableCaps,
                            style: ZplayType.overline.toStyle(
                              color: tokens.accent,
                            ),
                          ),
                          const SizedBox(height: ZplaySpacing.s4),
                          Text(
                            l10nCurrent().wgUpdVersion(
                              widget.updateInfo.latestVersion,
                            ),
                            style: ZplayType.titleLarge.toStyle(
                              color: tokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(ZplaySpacing.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Version details container
                    Container(
                      padding: const EdgeInsets.all(ZplaySpacing.s16),
                      decoration: BoxDecoration(
                        color: tokens.borderSubtle,
                        borderRadius: ZplayRadius.smAll,
                        border: Border.fromBorderSide(tokens.hairline),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10nCurrent().wgUpdCurrent,
                                style: ZplayType.caption.toStyle(
                                  color: tokens.textMuted,
                                ),
                              ),
                              const SizedBox(height: ZplaySpacing.s4),
                              Text(
                                widget.updateInfo.currentVersion,
                                style: ZplayType.subtitle.toStyle(
                                  color: tokens.textEmphasis,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: tokens.accent,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l10nCurrent().wgUpdLatest,
                                style: ZplayType.caption.toStyle(
                                  color: tokens.textMuted,
                                ),
                              ),
                              const SizedBox(height: ZplaySpacing.s4),
                              Text(
                                widget.updateInfo.latestVersion,
                                style: ZplayType.subtitle.toStyle(
                                  color: tokens.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: ZplaySpacing.s20),

                    // Release notes header & box
                    Text(
                      l10nCurrent().wgUpdWhatsNew,
                      style: ZplayType.overline.toStyle(
                        color: tokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      padding: const EdgeInsets.all(ZplaySpacing.s16),
                      decoration: BoxDecoration(
                        color: tokens.bg.withValues(
                          alpha: ZplayOpacity.textSecondary,
                        ),
                        borderRadius: ZplayRadius.smAll,
                        border: Border.fromBorderSide(tokens.hairline),
                      ),
                      child: WholeLineViewport(
                        child: SingleChildScrollView(
                          child: Text(
                            releaseNotes.isEmpty
                                ? l10nCurrent().wgUpdNoReleaseNotes
                                : releaseNotes,
                            style: ZplayType.body.toStyle(
                              color: releaseNotes.isEmpty
                                  ? tokens.textMuted
                                  : tokens.textEmphasis,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (widget.updateInfo.isMacOS ||
                        widget.updateInfo.isIOS) ...[
                      const SizedBox(height: ZplaySpacing.s16),
                      Container(
                        padding: const EdgeInsets.all(ZplaySpacing.s12),
                        decoration: BoxDecoration(
                          color: tokens.warning.withValues(
                            alpha: ZplayOpacity.borderMedium,
                          ),
                          borderRadius: ZplayRadius.smAll,
                          border: Border.all(
                            color: tokens.warning.withValues(
                              alpha: ZplayOpacity.textDisabled,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: tokens.warning,
                              size: 20,
                            ),
                            const SizedBox(width: ZplaySpacing.s12),
                            Expanded(
                              child: Text(
                                widget.updateInfo.isIOS
                                    ? l10nCurrent().wgUpdIosRedirect
                                    : l10nCurrent().wgUpdMacRedirect,
                                style: ZplayType.bodySmall.toStyle(
                                  color: tokens.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_isDownloading) ...[
                      const SizedBox(height: ZplaySpacing.s20),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10nCurrent().wgUpdDownloading,
                                style: ZplayType.label.toStyle(
                                  color: tokens.accent,
                                ),
                              ),
                              Text(
                                '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                                style: ZplayType.labelNumeric.toStyle(
                                  color: tokens.textEmphasis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: ZplaySpacing.s8),
                          ClipRRect(
                            borderRadius: ZplayRadius.smAll,
                            child: LinearProgressIndicator(
                              value: _downloadProgress,
                              backgroundColor: tokens.borderStrong,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                tokens.accent,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Buttons
              if (!_isDownloading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ZplaySpacing.s24,
                    ZplaySpacing.s0,
                    ZplaySpacing.s24,
                    ZplaySpacing.s24,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            AppUpdaterService.dismissVersion(
                              widget.updateInfo.latestVersion,
                            );
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: ZplaySpacing.s16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: ZplayRadius.smAll,
                              side: tokens.hairlineStrong,
                            ),
                          ),
                          child: Text(
                            l10nCurrent().wgUpdLater,
                            style: ZplayType.label.toStyle(
                              color: tokens.textEmphasis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: ZplaySpacing.s12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _handleUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.accent,
                            foregroundColor: tokens.onAccent,
                            padding: const EdgeInsets.symmetric(
                              vertical: ZplaySpacing.s16,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: ZplayRadius.smAll,
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10nCurrent().wgUpdUpdateNow,
                                style: ZplayType.label.toStyle(),
                              ),
                              const SizedBox(width: ZplaySpacing.s8),
                              const Icon(Icons.download_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (kIsWeb) {
      await AppUpdaterService().openDownloadPage(widget.updateInfo.downloadUrl);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (Platform.isAndroid) {
      await _downloadAndInstallAndroid();
    } else if (Platform.isWindows || Platform.isLinux) {
      await _downloadAndInstallDesktop();
    } else {
      // macOS / iOS - open browser
      await AppUpdaterService().openDownloadPage(widget.updateInfo.downloadUrl);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String? get _expectedChecksum {
    final value = widget.updateInfo.sha256?.trim().toLowerCase();
    if (value == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
      return null;
    }
    return value;
  }

  Future<void> _offerUnverifiedRelease() async {
    if (!mounted) return;
    final openRelease = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.tokens.surfaceOverlay,
        title: Text(
          l10nCurrent().wgUpdNotVerified,
          style: ZplayType.title.toStyle(color: context.tokens.textPrimary),
        ),
        content: Text(
          l10nCurrent().wgUpdNoChecksum,
          style: ZplayType.body.toStyle(color: context.tokens.textEmphasis),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10nCurrent().wgUpdCancel,
              style: ZplayType.label.toStyle(
                color: context.tokens.textEmphasis,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.tokens.accent,
              foregroundColor: context.tokens.onAccent,
            ),
            child: Text(
              l10nCurrent().wgUpdOpenReleasePage,
              style: ZplayType.label.toStyle(),
            ),
          ),
        ],
      ),
    );
    if (openRelease == true) {
      await AppUpdaterService().openDownloadPage(
        widget.updateInfo.releasePageUrl ?? widget.updateInfo.downloadUrl,
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _downloadAndInstallAndroid() async {
    final checksum = _expectedChecksum;
    if (checksum == null) {
      await _offerUnverifiedRelease();
      return;
    }

    WakelockPlus.enable();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      _otaSub = OtaUpdate()
          .execute(
            widget.updateInfo.downloadUrl,
            destinationFilename:
                'Lumora_${widget.updateInfo.latestVersion}.apk',
            sha256checksum: checksum,
          )
          .listen(
            (OtaEvent event) {
              if (mounted) {
                setState(() {
                  switch (event.status) {
                    case OtaStatus.DOWNLOADING:
                      final value = event.value;
                      if (value != null) {
                        final numVal = num.tryParse(value.toString()) ?? 0;
                        _downloadProgress = (numVal / 100.0).clamp(0.0, 1.0);
                      }
                      break;
                    case OtaStatus.INSTALLING:
                      _downloadProgress = 1.0;
                      WakelockPlus.disable();
                      break;
                    case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                      _isDownloading = false;
                      WakelockPlus.disable();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10nCurrent().wgUpdInstallPermission),
                          duration: const Duration(seconds: 5),
                          backgroundColor: context.tokens.warning,
                        ),
                      );
                      Navigator.of(context).pop();
                      break;
                    case OtaStatus.ALREADY_RUNNING_ERROR:
                    case OtaStatus.INTERNAL_ERROR:
                    case OtaStatus.DOWNLOAD_ERROR:
                    case OtaStatus.CHECKSUM_ERROR:
                      _isDownloading = false;
                      WakelockPlus.disable();
                      _reportAndroidInstallFailure(
                        l10nCurrent().wgUpdFailed('${event.status}'),
                      );
                      Navigator.of(context).pop();
                      break;
                    default:
                      break;
                  }
                });
              }
            },
            onError: (error) {
              WakelockPlus.disable();
              if (mounted) {
                setState(() => _isDownloading = false);
                _reportAndroidInstallFailure(
                  l10nCurrent().wgUpdDownloadFailed('$error'),
                );
              }
            },
          );
    } catch (e) {
      WakelockPlus.disable();
      if (mounted) {
        setState(() => _isDownloading = false);
        _reportAndroidInstallFailure(l10nCurrent().wgUpdFailed('$e'));
      }
    }
  }

  /// Reports a failed Android install or download exactly once.
  ///
  /// Android refuses to install an APK signed with a different key than the
  /// installed copy, and ota_update surfaces that refusal as a bare status or
  /// platform exception. Without the hint the user reads "Update failed: …" and
  /// has no way to know a one-time uninstall is the fix. The hint lives here
  /// rather than in the dialog so it rides along with every Android failure
  /// path, and the current snackbar is replaced instead of queued so a failure
  /// that trips both the event stream and the error channel cannot stack the
  /// hint twice.
  void _reportAndroidInstallFailure(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$message\n\n${l10nCurrent().wgUpdSignatureConflictHint}',
          ),
          duration: const Duration(seconds: 10),
          backgroundColor: context.tokens.danger,
        ),
      );
  }

  Future<void> _downloadAndInstallDesktop() async {
    final checksum = _expectedChecksum;
    if (checksum == null) {
      await _offerUnverifiedRelease();
      return;
    }

    WakelockPlus.enable();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      Directory? downloadsDir;
      try {
        downloadsDir = await getDownloadsDirectory();
      } catch (_) {
        downloadsDir = null;
      }
      final dir = downloadsDir ?? await getTemporaryDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final extension = Platform.isWindows ? '.exe' : '.AppImage';
      final fileName = 'Lumora-${widget.updateInfo.latestVersion}$extension';
      final filePath = path.join(dir.path, fileName);
      final file = File(filePath);

      final request = http.Request(
        'GET',
        Uri.parse(widget.updateInfo.downloadUrl),
      );
      final response = await request.send();

      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;
      int lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        if (contentLength > 0 &&
            mounted &&
            (now - lastUpdateTime > 100 || downloadedBytes == contentLength)) {
          lastUpdateTime = now;
          final progress = downloadedBytes / contentLength;
          setState(() {
            _downloadProgress = progress;
          });
        }
      }

      await sink.close();
      final installer = File(filePath);

      final actualChecksum = (await sha256.bind(installer.openRead()).first)
          .toString()
          .toLowerCase();
      if (actualChecksum != checksum) {
        try {
          await installer.delete();
        } catch (_) {}
        throw const _ChecksumMismatch();
      }

      if (mounted) {
        WakelockPlus.disable();
        setState(() => _isDownloading = false);

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: context.tokens.surfaceOverlay,
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: context.tokens.success,
                  size: 32,
                ),
                const SizedBox(width: ZplaySpacing.s12),
                Text(
                  l10nCurrent().wgUpdDownloadComplete,
                  style: ZplayType.title.toStyle(
                    color: context.tokens.textPrimary,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Platform.isWindows
                      ? l10nCurrent().wgUpdWillCloseAndInstall
                      : l10nCurrent().wgUpdDownloadedTo,
                  style: ZplayType.body.toStyle(
                    color: context.tokens.textEmphasis,
                  ),
                ),
                if (!Platform.isWindows) ...[
                  const SizedBox(height: ZplaySpacing.s8),
                  Container(
                    padding: const EdgeInsets.all(ZplaySpacing.s12),
                    decoration: BoxDecoration(
                      color: context.tokens.bg.withValues(
                        alpha: ZplayOpacity.textSecondary,
                      ),
                      borderRadius: ZplayRadius.smAll,
                    ),
                    child: SelectableText(
                      filePath,
                      style: ZplayType.bodySmall
                          .toStyle(color: context.tokens.accent)
                          .copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: ZplaySpacing.s16),
                  Text(
                    '${l10nCurrent().wgUpdMakeExecutable}\n'
                    'chmod +x "$fileName"\n./$fileName',
                    style: ZplayType.body.toStyle(
                      color: context.tokens.textEmphasis,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!Platform.isWindows)
                TextButton(
                  onPressed: () async {
                    if (Platform.isLinux) {
                      await Process.run('xdg-open', [dir.path]);
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(
                    l10nCurrent().wgUpdOpenFolder,
                    style: ZplayType.label.toStyle(
                      color: context.tokens.textEmphasis,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: () async {
                  if (Platform.isWindows) {
                    // The installer sat in Downloads since it was checked:
                    // check it again right before it runs.
                    final now = (await sha256.bind(installer.openRead()).first)
                        .toString()
                        .toLowerCase();
                    if (now != checksum) {
                      try {
                        await installer.delete();
                      } catch (_) {}
                      if (context.mounted) Navigator.of(context).pop();
                      return;
                    }
                    await Process.start(
                      installer.path,
                      const [],
                      mode: ProcessStartMode.detached,
                    );
                    await Future.delayed(const Duration(seconds: 2));
                    exit(0);
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.tokens.accent,
                  foregroundColor: context.tokens.onAccent,
                ),
                child: Text(
                  Platform.isWindows
                      ? l10nCurrent().wgUpdCloseAndInstall
                      : l10nCurrent().wgUpdOk,
                ),
              ),
            ],
          ),
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      WakelockPlus.disable();
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is _ChecksumMismatch
                  ? l10nCurrent().wgUpdChecksumMismatch
                  : l10nCurrent().wgUpdDownloadFailed('$e'),
            ),
          ),
        );
      }
    }
  }
}

/// The downloaded installer's SHA-256 did not match the signed manifest.
class _ChecksumMismatch implements Exception {
  const _ChecksumMismatch();
}
