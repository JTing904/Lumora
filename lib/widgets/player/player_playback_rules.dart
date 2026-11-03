/// Rules the player screen follows around opening, ending and recovering a
/// stream.
///
/// Kept out of `player_screen.dart` for the same reason as
/// `player_screen_tap.dart`: the screen owns a `media_kit` `Player` and no
/// test can build it, so the rules are driven here.
library;

import '../../services/stream/auto_source_picker.dart';

/// Tells one asynchronous attempt from the one that replaced it.
///
/// An open, a subtitle search or a subtitle download starts, awaits, and
/// finishes later, by which time the viewer may be on another source or
/// another episode. The attempt takes a ticket as it starts and asks
/// [isCurrent] after every await, so a late answer is dropped instead of
/// landing on whatever replaced it.
class AttemptToken {
  int _current = 0;

  /// The ticket of the attempt in flight, for work that belongs to it
  /// without replacing it.
  int get current => _current;

  /// Starts a new attempt. Every ticket handed out before is stale from now.
  int begin() => ++_current;

  bool isCurrent(int ticket) => ticket == _current;
}

/// Reports a state once, on the change into it.
///
/// Media3's ready state arrives again with every 500 ms position tick, so a
/// reaction written as "while the state is ended" saved progress twice a
/// second at the end of every stream, and one written as "while it is in
/// error" could move the recovery chain on again before the switch away
/// from the failed engine had finished.
class StateEdge<T> {
  T? _last;

  /// Whether [state] differs from the one reported before it.
  bool entered(T state) {
    final bool changed = state != _last;
    _last = state;
    return changed;
  }

  /// Forgets the last state, for a new stream whose first report must count.
  void reset() => _last = null;
}

/// Where the recovery chain opens its next source.
///
/// [carried] is the place the chain has been carrying: the resume point the
/// play started with, or where an earlier source in the chain got to. A
/// source that showed a picture and played past [openedAt] - the offset it
/// was opened at - moved the viewer, so its [live] position is their place
/// now. Re-sending the original resume point instead rewound a viewer whose
/// source died twenty minutes in, and the next progress save then wrote
/// that rewind over their real progress.
///
/// The chain keeps switching after a source has played, rather than giving
/// up: its alternatives are the same title, so carrying on from the same
/// moment on another source is less of a surprise than an error screen in
/// the middle of a film.
Duration? recoveryResumeAt({
  required Duration? carried,
  required bool showedPicture,
  required Duration openedAt,
  required Duration live,
}) => showedPicture && live > openedAt ? live : carried;

/// Whether a stream of [length] can be the title whose Cinemeta runtime is
/// [runtime].
///
/// False for a trailer, a clip or a host's placeholder far shorter than the
/// title runs (see [isTooShortForRuntime]). Such a stream must not count as
/// watched: played to its end it used to mark the episode finished and move
/// on to the next one. True whenever there is nothing to judge by - no
/// runtime, or no length yet.
bool streamIsTheTitle(Duration length, String? runtime) {
  final Duration? expected = parseRuntime(runtime);
  if (expected == null || length <= Duration.zero) return true;
  return !isTooShortForRuntime(length, expected);
}

/// Keeps the window's full screen across a player screen replacing itself.
///
/// The next episode and a watch-party hand-over replace the player with a
/// new one. The old screen used to leave full screen as it went, because
/// full screen was not the viewer's when it opened, so every next episode
/// on a computer came back windowed. The leaving screen now hands its
/// answer to the next, and the chain leaves full screen only when the
/// viewer leaves the chain.
class FullscreenCarry {
  bool? _handedOver;

  /// For a screen opening with the window [isFullscreen]: whether that full
  /// screen was the viewer's before the player chain began, which is when
  /// leaving keeps it.
  bool enter({required bool isFullscreen}) {
    final bool? handedOver = _handedOver;
    _handedOver = null;
    return isFullscreen && (handedOver ?? true);
  }

  /// For a screen going away: whether to take the window out of full screen.
  /// A screen [handingOver] to its replacement never does.
  bool leave({
    required bool wasFullscreenBefore,
    required bool handingOver,
    required bool isFullscreen,
  }) {
    if (handingOver) {
      _handedOver = wasFullscreenBefore;
      return false;
    }
    return isFullscreen && !wasFullscreenBefore;
  }
}
