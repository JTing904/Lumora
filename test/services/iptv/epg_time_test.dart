import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/iptv/iptv_network.dart';

void main() {
  group('serverUtcOffset', () {
    test('reads the offset from time_now against timestamp_now', () {
      // 2024-06-01 12:00:00 UTC, on a panel two hours ahead (CEST).
      final offset = IptvClient.serverUtcOffset({
        'timezone': 'Europe/Berlin',
        'timestamp_now': 1717243200,
        'time_now': '2024-06-01 14:00:01',
      });
      expect(offset, const Duration(hours: 2));
    });

    test('handles zones behind UTC and half hours', () {
      expect(
        IptvClient.serverUtcOffset({
          'timestamp_now': '1717243200',
          'time_now': '2024-06-01 08:00:00',
        }),
        const Duration(hours: -4),
      );
      expect(
        IptvClient.serverUtcOffset({
          'timestamp_now': 1717243200,
          'time_now': '2024-06-01 17:30:00',
        }),
        const Duration(hours: 5, minutes: 30),
      );
    });

    test('falls back to a UTC timezone name, else unknown', () {
      expect(IptvClient.serverUtcOffset({'timezone': 'UTC'}), Duration.zero);
      expect(
        IptvClient.serverUtcOffset({'timezone': 'America/New_York'}),
        isNull,
      );
      expect(IptvClient.serverUtcOffset({}), isNull);
    });
  });

  group('parseEpgTime', () {
    test('Unix seconds need no offset', () {
      final t = IptvClient.parseEpgTime('1717243200')!;
      expect(t.toUtc(), DateTime.utc(2024, 6, 1, 12));
    });

    test('wall-clock strings are read on the panel clock', () {
      final t = IptvClient.parseEpgTime(
        '2024-06-01 14:00:00',
        serverOffset: const Duration(hours: 2),
      )!;
      expect(t.toUtc(), DateTime.utc(2024, 6, 1, 12));
    });

    test('a string with its own zone keeps it', () {
      final t = IptvClient.parseEpgTime(
        '2024-06-01T14:00:00+02:00',
        serverOffset: const Duration(hours: 9),
      )!;
      expect(t.toUtc(), DateTime.utc(2024, 6, 1, 12));
    });

    test('without an offset a wall-clock string stays device-local', () {
      final t = IptvClient.parseEpgTime('2024-06-01 14:00:00')!;
      expect(t.isUtc, isFalse);
      expect(t.hour, 14);
    });

    test('garbage is null', () {
      expect(IptvClient.parseEpgTime('soon'), isNull);
      expect(IptvClient.parseEpgTime(null), isNull);
    });
  });
}
