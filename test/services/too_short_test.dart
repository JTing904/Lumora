import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/stream/auto_source_picker.dart';

void main() {
  test('runtimes as Cinemeta writes them', () {
    expect(parseRuntime('46 min'), const Duration(minutes: 46));
    expect(parseRuntime('1h 30min'), const Duration(minutes: 90));
    expect(parseRuntime('2h'), const Duration(minutes: 120));
    expect(parseRuntime('52'), const Duration(minutes: 52));
    expect(parseRuntime(null), isNull);
    expect(parseRuntime('N/A'), isNull);
  });

  test('a clip is not the episode, a short cut still is', () {
    const episode = Duration(minutes: 46);
    expect(isTooShortForRuntime(const Duration(seconds: 89), episode), isTrue);
    expect(isTooShortForRuntime(const Duration(minutes: 40), episode), isFalse);
    // A 7-minute short is never judged.
    expect(
      isTooShortForRuntime(
        const Duration(minutes: 1),
        const Duration(minutes: 7),
      ),
      isFalse,
    );
    // A long film's 20-minute stream is suspicious, but past a quarter hour
    // it may be a real part; it is left alone.
    expect(
      isTooShortForRuntime(
        const Duration(minutes: 20),
        const Duration(minutes: 120),
      ),
      isFalse,
    );
  });
}
