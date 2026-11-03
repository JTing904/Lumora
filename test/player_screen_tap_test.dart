/// A tap on the video plays or pauses; reaching for the transport to pause was
/// the complaint. `PlayerScreen` cannot be pumped, so the rule lives in
/// `player_screen_tap.dart` and is driven here.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/widgets/player/player_screen_tap.dart';

void main() {
  final t0 = DateTime(2026, 11, 3, 12);

  test('every tap on a phone plays or pauses', () {
    final tap = PlayerScreenTap();
    for (var i = 0; i < 3; i++) {
      expect(
        tap.tap(
          t0.add(Duration(milliseconds: 100 * i)),
          canPlayPause: true,
          doubleClickFullscreen: false,
        ),
        PlayerTapAction.playPause,
      );
    }
  });

  test('a double-click on a computer is full screen', () {
    final tap = PlayerScreenTap();
    expect(
      tap.tap(t0, canPlayPause: true, doubleClickFullscreen: true),
      PlayerTapAction.playPause,
    );
    expect(
      tap.tap(
        t0.add(const Duration(milliseconds: 200)),
        canPlayPause: true,
        doubleClickFullscreen: true,
      ),
      PlayerTapAction.fullscreen,
    );
    // The pair is spent: the next click starts over.
    expect(
      tap.tap(
        t0.add(const Duration(milliseconds: 350)),
        canPlayPause: true,
        doubleClickFullscreen: true,
      ),
      PlayerTapAction.playPause,
    );
  });

  test('two slow clicks are two plays or pauses', () {
    final tap = PlayerScreenTap();
    tap.tap(t0, canPlayPause: true, doubleClickFullscreen: true);
    expect(
      tap.tap(
        t0.add(const Duration(milliseconds: 600)),
        canPlayPause: true,
        doubleClickFullscreen: true,
      ),
      PlayerTapAction.playPause,
    );
  });

  test('while nothing can play, a tap only shows the controls', () {
    final tap = PlayerScreenTap();
    expect(
      tap.tap(t0, canPlayPause: false, doubleClickFullscreen: true),
      PlayerTapAction.controls,
    );
    // ...and does not count as the first half of a double-click.
    expect(
      tap.tap(
        t0.add(const Duration(milliseconds: 100)),
        canPlayPause: true,
        doubleClickFullscreen: true,
      ),
      PlayerTapAction.playPause,
    );
  });

  test('a room hears of a click only once it cannot be a double-click', () {
    final tap = PlayerScreenTap();
    // On a computer the click waits out the double-click window, so the
    // second click can take it back before the room is told.
    expect(tap.roomDelay(doubleClickFullscreen: true), tap.doubleTapWindow);
    // A touch screen has no double-click to wait for.
    expect(tap.roomDelay(doubleClickFullscreen: false), Duration.zero);
  });
}
