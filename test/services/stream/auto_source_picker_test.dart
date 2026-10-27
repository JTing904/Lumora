import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/models/stream/stream_model.dart';
import 'package:zplay/services/stream/auto_source_picker.dart';

StreamSource _direct(String name, {String quality = '1080p'}) => StreamSource(
  name: name,
  title: '$name $quality',
  url: 'https://example.test/$name.m3u8',
  addonName: 'ZPlayHTTP',
);

StreamSource _torrent(String name, int seeders, {String size = '5.5 GB'}) =>
    StreamSource(
      name: name,
      title: '$name 1080p $size 👤 $seeders',
      infoHash: name.padRight(40, '0'),
      addonName: 'Torrentio',
    );

void main() {
  test('the first link to answer alive leads, not the first ranked', () async {
    final slow = _direct('slow');
    final fast = _direct('fast');
    final picker = AutoSourcePicker(
      probe: (s) => Future.delayed(
        Duration(milliseconds: identical(s, slow) ? 200 : 20),
        () => true,
      ),
    );
    final pick = await picker.pick([slow, fast]);
    expect(pick!.source, same(fast));
    expect(pick.alternatives, [fast, slow]);
  });

  test('a link the probe failed stays queued, behind the ones it passed', () async {
    final failed = _direct('failed');
    final ok = _direct('ok');
    final picker = AutoSourcePicker(probe: (s) async => !identical(s, failed));
    final pick = await picker.pick([failed, ok]);
    expect(pick!.alternatives, [ok, failed]);
  });

  test('links go before torrents even when every probe failed', () async {
    final link = _direct('link');
    final torrent = _torrent('torrent', 500);
    final picker = AutoSourcePicker(probe: (_) async => false);
    final pick = await picker.pick([torrent, link]);
    expect(pick!.source, same(link));
    expect(pick.alternatives, [link, torrent]);
  });

  test('with no link, the best-seeded torrent leads and 0 seeds is dropped', () async {
    final none = _torrent('none', 0);
    final few = _torrent('few', 3);
    final many = _torrent('many', 120);
    final picker = AutoSourcePicker(probe: (_) async => false);
    final pick = await picker.pick([none, few, many]);
    expect(pick!.source, same(many));
    expect(pick.alternatives, isNot(contains(none)));
  });

  test('a torrent the connection cannot carry goes last', () async {
    // 29 GB over 145 minutes is about 27 Mbps; a 6 Mbps line carries 4.8.
    final huge = _torrent('huge', 1700, size: '29.1 GB');
    final small = _torrent('small', 40, size: '2.5 GB');
    final picker = AutoSourcePicker(probe: (_) async => false)
      ..bandwidthMbps = 6
      ..runtimeMinutes = 145;
    final pick = await picker.pick([huge, small]);
    expect(pick!.source, same(small));
    expect(picker.tooHeavy(huge), isTrue);
    expect(picker.tooHeavy(small), isFalse);
  });

  test('a fast line may take the heavy one', () {
    final huge = _torrent('huge', 1700, size: '29.1 GB');
    final picker = AutoSourcePicker()
      ..bandwidthMbps = 100
      ..runtimeMinutes = 145;
    expect(picker.tooHeavy(huge), isFalse);
  });

  test('the viewer\'s quality choice caps the pick', () async {
    final uhd = _direct('uhd', quality: '2160p');
    final hd = _direct('hd', quality: '720p');
    final picker = AutoSourcePicker(probe: (_) async => true)
      ..bandwidthMbps = 100
      ..qualityCap = '720p';
    final pick = await picker.pick([uhd, hd]);
    expect(pick!.source, same(hd));
  });

  test('original language goes before a dub', () async {
    final dub = StreamSource(
      name: 'rive',
      title: '[Rive - Citadel] 720p | Kannada',
      url: 'https://example.test/kn.m3u8',
      addonName: 'ZPlayHTTP',
    );
    final original = _direct('original', quality: '720p');
    final picker = AutoSourcePicker(probe: (_) async => false);
    final pick = await picker.pick([dub, original]);
    expect(pick!.alternatives, [original, dub]);
  });

  test('"ita" only counts as a whole word', () async {
    final capital = _direct('Capital');
    final italian = StreamSource(
      name: 'x',
      title: 'Movie.2026.iTA-ENG.1080p',
      url: 'https://example.test/it.m3u8',
      addonName: 'ZPlayHTTP',
    );
    final picker = AutoSourcePicker(probe: (_) async => false);
    final pick = await picker.pick([italian, capital]);
    expect(pick!.alternatives, [capital, italian]);
  });

  test('a probe that hangs counts as failed, and the link stays queued', () async {
    final hangs = _direct('hangs');
    final picker = AutoSourcePicker(
      probe: (_) => Future.delayed(const Duration(seconds: 5), () => true),
      probeTimeout: const Duration(milliseconds: 50),
    );
    final pick = await picker.pick([hangs]);
    expect(pick!.source, same(hangs));
    expect(
      picker.dead[AutoSourcePicker.keyOf(hangs)],
      SourceDeadReason.unreachable,
    );
  });

  test('a link that sends the viewer to a website is never picked', () async {
    final web = StreamSource(
      name: 'web',
      externalUrl: 'https://example.test/watch',
      addonName: 'X',
    );
    final picker = AutoSourcePicker(probe: (_) async => true);
    expect(await picker.pick([web]), isNull);
  });

  test('an alternate cut goes behind the regular release, even when faster', () async {
    // Into the Spider-Verse: Vadapav's Alt-Universe Cut answered first and
    // opened with the filmmakers talking.
    final altCut = StreamSource(
      name: 'Vadapav',
      title: 'Spider-Man.Into.the.Spider-Verse.2018.Alt-Universe.Cut.1080p',
      url: 'https://example.test/alt.mkv',
      addonName: 'ZPlayHTTP',
    );
    final regular = _direct('regular');
    final picker = AutoSourcePicker(
      probe: (s) => Future.delayed(
        Duration(milliseconds: identical(s, altCut) ? 10 : 80),
        () => true,
      ),
    );
    final pick = await picker.pick([altCut, regular]);
    expect(pick!.source, same(regular));
    expect(pick.alternatives.last, same(altCut));
  });

  test('a big file link is weighed by its size over the runtime', () {
    // 5.75 GB over 117 minutes is about 6.6 Mbps.
    final mkv = StreamSource(
      name: 'Vadapav',
      title: 'Film.2018.1080p.mkv 5.75 GB',
      url: 'https://example.test/film.mkv',
      addonName: 'ZPlayHTTP',
    );
    final picker = AutoSourcePicker()
      ..runtimeMinutes = 117
      ..bandwidthMbps = 6;
    expect(picker.tooHeavy(mkv), isTrue);
    picker.bandwidthMbps = 20;
    expect(picker.tooHeavy(mkv), isFalse);
  });

  test('a row that is an error message is never queued', () async {
    final blocked = StreamSource(
      name: 'A111477',
      title: '⛔ Spammy IP — st.111477.xyz/slowdown',
      url: 'https://example.test/slowdown',
      addonName: 'ZPlayHTTP',
    );
    final ok = _direct('ok');
    final picker = AutoSourcePicker(probe: (_) async => true);
    final pick = await picker.pick([blocked, ok]);
    expect(pick!.alternatives, [ok]);
  });
}
