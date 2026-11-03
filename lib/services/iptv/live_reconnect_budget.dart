/// How many times the live player may reopen one frozen source before it
/// gives up on it and moves to the next.
///
/// The allowance used to be refilled every time `open()` returned, and
/// `open()` returns as soon as the request is sent, not when frames arrive.
/// So a feed that froze, was reopened, and froze again never used up its
/// allowance, and the player reconnected to it forever instead of failing
/// over. Now the allowance only comes back once the reopened feed has really
/// played for [recoveredAfter], counted from small forward steps of the
/// position so a stale or jumping report from the previous feed does not
/// count as playback.
class LiveReconnectBudget {
  LiveReconnectBudget({
    this.maxReconnects = 3,
    this.recoveredAfter = const Duration(seconds: 20),
  });

  final int maxReconnects;

  /// Playback a reopened feed needs before it counts as working again. Longer
  /// than the watchdog's ten-second stall window, so a feed that plays a few
  /// buffered seconds after each reopen and then freezes still runs out.
  final Duration recoveredAfter;

  /// The largest position step counted as playback; anything bigger is a
  /// jump (a new stream's clock, a seek), not frames being shown.
  static const Duration _maxStep = Duration(seconds: 5);

  int _used = 0;
  Duration? _last;
  Duration _played = Duration.zero;

  /// Reconnects spent on the current source.
  int get used => _used;

  /// A different source, or the user asking to try again: a full allowance.
  void reset() {
    _used = 0;
    _restartProgress();
  }

  /// The current source is being (re)opened. Progress is measured afresh,
  /// but the allowance is not refilled.
  void opened() => _restartProgress();

  /// A position report from the player.
  void position(Duration position) {
    final last = _last;
    _last = position;
    if (last == null) return;
    final step = position - last;
    if (step <= Duration.zero || step > _maxStep) return;
    _played += step;
    if (_played >= recoveredAfter) _used = 0;
  }

  /// The feed froze. Returns true when it may be reopened (spending one
  /// reconnect) and false when the allowance is spent and the player should
  /// move on to the next source.
  bool tryReconnect() {
    if (_used >= maxReconnects) return false;
    _used++;
    return true;
  }

  void _restartProgress() {
    _last = null;
    _played = Duration.zero;
  }
}
