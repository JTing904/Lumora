import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/services/stream/network_speed.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NetworkSpeed.resetForTesting();
  });

  test('the first sample is the estimate', () {
    NetworkSpeed.recordLink(6);
    expect(NetworkSpeed.mbps.value, 6);
  });

  test('a link sample moves the estimate either way', () {
    NetworkSpeed.recordLink(10);
    NetworkSpeed.recordLink(5);
    expect(NetworkSpeed.mbps.value, closeTo(8, 0.01));
  });

  test('a slow torrent says nothing about the line', () {
    NetworkSpeed.recordLink(20);
    NetworkSpeed.recordTorrent(2);
    expect(NetworkSpeed.mbps.value, 20);
    NetworkSpeed.recordTorrent(40);
    expect(NetworkSpeed.mbps.value, 30);
  });

  test('nonsense samples are ignored', () {
    NetworkSpeed.recordLink(0);
    NetworkSpeed.recordLink(double.nan);
    expect(NetworkSpeed.mbps.value, isNull);
  });
}
