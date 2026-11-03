import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../layout/device_profile.dart';

/// Centralized window and fullscreen state manager for desktop and mobile.
class WindowService with WindowListener {
  static final WindowService instance = WindowService._internal();
  WindowService._internal();

  final ValueNotifier<bool> isFullscreenNotifier = ValueNotifier<bool>(false);
  bool _isTransitioning = false;

  bool get isFullscreen => isFullscreenNotifier.value;
  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> initialize() async {
    if (!isDesktop) return;
    try {
      windowManager.addListener(this);
      final isFs = await windowManager.isFullScreen();
      isFullscreenNotifier.value = isFs;
    } catch (e) {
      debugPrint('[WindowService] initialize error: $e');
    }
  }

  void dispose() {
    if (isDesktop) {
      windowManager.removeListener(this);
    }
  }

  /// The system bars outside a fullscreen player on Android and iOS. A phone
  /// shows its status and navigation bars, drawn edge to edge (the pages
  /// already pay for the top inset, see `AppShell._layout`); a television has
  /// no bars worth showing, so it stays immersive.
  SystemUiMode get _normalMobileUiMode => DeviceProfile.isTelevision
      ? SystemUiMode.immersiveSticky
      : SystemUiMode.edgeToEdge;

  /// The players currently open in fullscreen on a phone or television. A set
  /// rather than a flag because a player replaced by the next one is disposed
  /// only after its successor has opened, and its exit must not bring the
  /// bars back over the new player.
  final Set<Object> _fullscreenPlayers = <Object>{};

  /// Puts the system bars into the app's normal mode, unless a fullscreen
  /// player is open. A no-op on desktop.
  Future<void> applyNormalSystemUi() async {
    if (isDesktop || kIsWeb || _fullscreenPlayers.isNotEmpty) return;
    try {
      await SystemChrome.setEnabledSystemUIMode(_normalMobileUiMode);
    } catch (e) {
      debugPrint('[WindowService] applyNormalSystemUi error: $e');
    }
  }

  /// A player opening on a phone or television: hides the system bars. On a
  /// phone it also marks [isFullscreenNotifier], so the player's fullscreen
  /// button shows the right state. [owner] is the player's state; pass the
  /// same object to [leavePlayerFullscreen]. A desktop player does not go
  /// fullscreen on entry, so this is a no-op there.
  Future<void> enterPlayerFullscreen(Object owner) async {
    if (isDesktop || kIsWeb) return;
    _fullscreenPlayers.add(owner);
    if (!DeviceProfile.isTelevision) isFullscreenNotifier.value = true;
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e) {
      debugPrint('[WindowService] enterPlayerFullscreen error: $e');
    }
  }

  /// A player closing on a phone or television: once no other player is open,
  /// back to the normal bars, whatever the fullscreen button was last left at.
  /// Safe to call more than once for the same [owner] (on pop and again on
  /// dispose). A no-op on desktop, where each player decides whether to leave
  /// window fullscreen.
  Future<void> leavePlayerFullscreen(Object owner) async {
    if (isDesktop || kIsWeb) return;
    if (!_fullscreenPlayers.remove(owner)) return;
    if (_fullscreenPlayers.isNotEmpty) return;
    isFullscreenNotifier.value = false;
    await applyNormalSystemUi();
  }

  /// Executes true borderless OS fullscreen toggle covering the Windows taskbar.
  Future<void> toggleFullscreen() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      if (!isDesktop) {
        // Mobile fallback
        final next = !isFullscreenNotifier.value;
        isFullscreenNotifier.value = next;
        if (next) {
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersiveSticky,
          );
        } else {
          await SystemChrome.setEnabledSystemUIMode(_normalMobileUiMode);
        }
        return;
      }

      final isCurrentlyFs = await windowManager.isFullScreen();
      if (isCurrentlyFs || isFullscreenNotifier.value) {
        await windowManager.setFullScreen(false);
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        }
        isFullscreenNotifier.value = false;
      } else {
        // Crucial for Windows: unmaximize first to drop the 8px DWM resize frame
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        }
        await windowManager.setFullScreen(true);
        isFullscreenNotifier.value = true;
      }
    } catch (e) {
      debugPrint('[WindowService] toggleFullscreen error: $e');
    } finally {
      _isTransitioning = false;
    }
  }

  /// Alias for toggleFullscreen
  Future<void> toggleFullScreen() => toggleFullscreen();

  /// Forces exit from fullscreen (e.g. when leaving player screen).
  Future<void> exitFullscreen() async {
    if (!isDesktop) {
      if (isFullscreenNotifier.value) {
        isFullscreenNotifier.value = false;
        await SystemChrome.setEnabledSystemUIMode(_normalMobileUiMode);
      }
      return;
    }
    if (_isTransitioning) return;
    _isTransitioning = true;
    try {
      final isCurrentlyFs = await windowManager.isFullScreen();
      if (isCurrentlyFs || isFullscreenNotifier.value) {
        await windowManager.setFullScreen(false);
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        }
        isFullscreenNotifier.value = false;
      }
    } catch (e) {
      debugPrint('[WindowService] exitFullscreen error: $e');
    } finally {
      _isTransitioning = false;
    }
  }

  // ── WindowListener Callbacks (Synchronize OS events) ──

  @override
  void onWindowEnterFullScreen() {
    isFullscreenNotifier.value = true;
  }

  @override
  void onWindowLeaveFullScreen() {
    isFullscreenNotifier.value = false;
  }

  @override
  void onWindowRestore() {
    windowManager.isFullScreen().then((isFs) {
      isFullscreenNotifier.value = isFs;
    });
  }

  @override
  void onWindowUnmaximize() {
    windowManager.isFullScreen().then((isFs) {
      isFullscreenNotifier.value = isFs;
    });
  }

  @override
  void onWindowMaximize() {
    windowManager.isFullScreen().then((isFs) {
      isFullscreenNotifier.value = isFs;
    });
  }
}
