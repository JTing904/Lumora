/// What a tap on the video asks for.
///
/// A tap plays or pauses, as on YouTube and in desktop players; reaching for
/// the transport to pause was the complaint. On a computer a second click
/// within [PlayerScreenTap.doubleTapWindow] is a double-click: it toggles full
/// screen and puts playback back the way it was, since the first click of the
/// pair already played or paused.
///
/// Kept out of `player_screen.dart` for the same reason as
/// `player_touch_gesture.dart`: the screen owns a `media_kit` `Player` and no
/// test can build it, so the rule is driven here.
library;

enum PlayerTapAction {
  /// Play or pause, and bring the controls up.
  playPause,

  /// Toggle full screen and undo the play/pause the first click made.
  fullscreen,

  /// Only show or hide the controls: nothing is playing yet (opening, a
  /// source being changed, a menu open).
  controls,
}

class PlayerScreenTap {
  PlayerScreenTap({this.doubleTapWindow = const Duration(milliseconds: 280)});

  final Duration doubleTapWindow;

  DateTime? _lastPlayPause;

  /// How long a tap's play or pause waits before a 一起看 room hears of it.
  ///
  /// On a computer the click may be the first half of a double-click, whose
  /// second half takes the play or pause back. Sent at once, every
  /// double-click to full screen paused the whole room and played it again;
  /// held back for [doubleTapWindow], the pair never leaves this device.
  Duration roomDelay({required bool doubleClickFullscreen}) =>
      doubleClickFullscreen ? doubleTapWindow : Duration.zero;

  /// One tap at [now]. [canPlayPause] is false while nothing can be played or
  /// paused; [doubleClickFullscreen] is true on a computer.
  PlayerTapAction tap(
    DateTime now, {
    required bool canPlayPause,
    required bool doubleClickFullscreen,
  }) {
    if (!canPlayPause) {
      _lastPlayPause = null;
      return PlayerTapAction.controls;
    }
    final last = _lastPlayPause;
    if (doubleClickFullscreen &&
        last != null &&
        now.difference(last) < doubleTapWindow) {
      _lastPlayPause = null;
      return PlayerTapAction.fullscreen;
    }
    _lastPlayPause = now;
    return PlayerTapAction.playPause;
  }
}
