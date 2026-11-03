import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/iptv/iptv_models.dart';
import 'package:zplay/services/iptv/hardcoded_channels.dart';
import 'package:zplay/services/iptv/iptv_storage.dart';
import 'package:zplay/services/iptv/live_health_ordering.dart';
import 'package:zplay/services/iptv/stream_separator.dart';

ChannelHit _hit(String name, String id) => ChannelHit(
  portal: const VerifiedPortal(
    portal: IptvPortal(url: 'http://p.example', username: 'u', password: 'p'),
    name: 'p.example',
    expiry: '',
    maxConnections: '1',
    activeConnections: '0',
  ),
  stream: IptvStream(
    streamId: id,
    name: name,
    icon: '',
    categoryId: '1',
    containerExt: 'ts',
    kind: 'live',
  ),
  streamUrl: 'http://p.example/live/u/p/$id.ts',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreamSeparator.isSeparator', () {
    test('portal category headings', () {
      for (final name in [
        '##### ESPN PLUS #####',
        '# UK #',
        '===== USA =====',
        '-----',
        '--- SPORTS ---',
        '**** 24/7 ****',
        '▬▬▬ UK ▬▬▬',
        '|||||',
      ]) {
        expect(StreamSeparator.isSeparator(name), isTrue, reason: name);
      }
    });

    test('real channels, including ones with provider tags', () {
      for (final name in [
        'ESPN+',
        'ESPN PLUS 01',
        '|UK| Sky Sports Main Event',
        'US: ESPN 2 HD',
        '#1 Sports',
        'BBC One - HD',
        'CCTV-5 体育',
        '',
      ]) {
        expect(StreamSeparator.isSeparator(name), isFalse, reason: name);
      }
    });
  });

  test('a heading never matches a channel keyword', () {
    expect(
      HardcodedChannels.matches('##### ESPN PLUS #####', ['espn plus']),
      isFalse,
    );
    expect(HardcodedChannels.matches('ESPN PLUS 01', ['espn plus']), isTrue);
  });

  group('ranking and failover', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await IptvDeadUrlStore.instance.initialize();
    });

    test('headings sort after everything, without being dropped', () {
      final heading = _hit('##### ESPN PLUS #####', '1');
      final channel = _hit('ESPN PLUS 01', '2');
      final sorted = IptvHealthOrdering.sort([heading, channel]);
      expect(sorted, [channel, heading]);
    });

    test('failover never lands on a heading', () {
      final channel = _hit('ESPN PLUS 01', '1');
      final heading = _hit('===== ESPN =====', '2');
      expect(
        IptvHealthOrdering.nextUntriedIndex([channel, heading], 0, {}),
        isNull,
      );
    });
  });
}
