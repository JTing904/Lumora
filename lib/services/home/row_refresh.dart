import 'dart:async';

import 'package:flutter/foundation.dart';

/// When a page of TMDb rows (Home, 电视剧 / 电影 / 动漫) reads them again.
///
/// A row that failed is asked again quietly after a delay that doubles with
/// each miss in a row ([firstRetry], twice that, ... up to [maxRetry]), so a
/// slow start or a dropped connection does not leave the row missing for
/// the session. Rows that loaded are read again once they are older than
/// [staleAfter], when the viewer comes back to the page.
class RowRefresh {
  RowRefresh({
    this.staleAfter = const Duration(hours: 6),
    this.firstRetry = const Duration(seconds: 20),
    this.maxRetry = const Duration(minutes: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration staleAfter;
  final Duration firstRetry;
  final Duration maxRetry;
  final DateTime Function() _clock;

  DateTime? _loadedAt;
  int _misses = 0;
  Timer? _timer;

  /// A whole read of the page has finished.
  void loaded() => _loadedAt = _clock();

  /// Whether the page's rows are old enough to read again.
  bool get isStale {
    final at = _loadedAt;
    return at != null && _clock().difference(at) >= staleAfter;
  }

  /// The wait before the next quiet retry; each call counts one more miss.
  Duration nextDelay() {
    final delay = firstRetry * (1 << _misses.clamp(0, 10));
    _misses++;
    return delay > maxRetry ? maxRetry : delay;
  }

  /// Runs [retry] after [nextDelay], replacing any retry already waiting.
  void scheduleRetry(VoidCallback retry) {
    _timer?.cancel();
    _timer = Timer(nextDelay(), retry);
  }

  /// Every row has loaded: the next miss waits [firstRetry] again.
  void succeeded() {
    _misses = 0;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => _timer?.cancel();
}
