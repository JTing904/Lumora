import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/iptv/live_reconnect_budget.dart';

/// Feeds [seconds] of one-second position steps starting at [from].
void _play(LiveReconnectBudget budget, int from, int seconds) {
  for (var s = from; s <= from + seconds; s++) {
    budget.position(Duration(seconds: s));
  }
}

void main() {
  test('reopening a frozen feed does not refill the allowance', () {
    final budget = LiveReconnectBudget(maxReconnects: 3);
    for (var i = 0; i < 3; i++) {
      // The old code reset the count here, when open() returned.
      budget.opened();
      expect(budget.tryReconnect(), isTrue);
    }
    budget.opened();
    expect(budget.tryReconnect(), isFalse, reason: 'should fail over now');
  });

  test('a few buffered seconds after each reopen are not recovery', () {
    final budget = LiveReconnectBudget(maxReconnects: 2);
    for (var i = 0; i < 2; i++) {
      budget.opened();
      _play(budget, 0, 4);
      expect(budget.tryReconnect(), isTrue);
    }
    budget.opened();
    _play(budget, 0, 4);
    expect(budget.tryReconnect(), isFalse);
  });

  test('real playback after a reopen earns the allowance back', () {
    final budget = LiveReconnectBudget(maxReconnects: 1);
    expect(budget.tryReconnect(), isTrue);
    budget.opened();
    _play(budget, 0, 25);
    expect(budget.used, 0);
    expect(budget.tryReconnect(), isTrue);
  });

  test('a position jump is not playback', () {
    final budget = LiveReconnectBudget(maxReconnects: 1);
    expect(budget.tryReconnect(), isTrue);
    budget.opened();
    budget.position(Duration.zero);
    budget.position(const Duration(hours: 3));
    expect(budget.used, 1);
  });

  test('a new source starts with a full allowance', () {
    final budget = LiveReconnectBudget(maxReconnects: 1);
    expect(budget.tryReconnect(), isTrue);
    expect(budget.tryReconnect(), isFalse);
    budget.reset();
    expect(budget.tryReconnect(), isTrue);
  });
}
