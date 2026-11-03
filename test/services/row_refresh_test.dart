import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/home/row_refresh.dart';

void main() {
  test('retries wait twice as long each time, up to five minutes', () {
    final r = RowRefresh();
    final delays = [for (var i = 0; i < 6; i++) r.nextDelay().inSeconds];
    expect(delays, [20, 40, 80, 160, 300, 300]);
    r.succeeded();
    expect(r.nextDelay(), const Duration(seconds: 20));
  });

  test('rows are stale six hours after a whole read', () {
    var now = DateTime(2026, 11, 3, 9);
    final r = RowRefresh(clock: () => now);
    expect(r.isStale, isFalse, reason: 'nothing read yet');
    r.loaded();
    now = now.add(const Duration(hours: 5, minutes: 59));
    expect(r.isStale, isFalse);
    now = now.add(const Duration(minutes: 1));
    expect(r.isStale, isTrue);
  });

  // testWidgets runs in fake time, so the timers below are stepped through.
  testWidgets('a scheduled retry runs once, and success cancels it', (
    tester,
  ) async {
    final r = RowRefresh();
    addTearDown(r.dispose);
    var runs = 0;
    r.scheduleRetry(() => runs++);
    await tester.pump(const Duration(seconds: 19));
    expect(runs, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(runs, 1);
    r.scheduleRetry(() => runs++);
    r.succeeded();
    await tester.pump(const Duration(minutes: 10));
    expect(runs, 1);
  });
}
