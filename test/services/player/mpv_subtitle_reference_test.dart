import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/player/mpv_subtitle_reference.dart';

/// The few libmpv properties the reader touches.
class _FakeMpv {
  _FakeMpv(this.tracks);

  /// Each track: type, id, codec, external, title, default.
  final List<Map<String, String>> tracks;
  final Map<String, String> props = {'sid': '3'};
  final Map<String, String> sets = {};
  Future<void> Function(String)? listener;

  Future<String> getProperty(String name) async {
    if (name == 'track-list/count') return '${tracks.length}';
    final m = RegExp(r'^track-list/(\d+)/(\w+)$').firstMatch(name);
    if (m != null) return tracks[int.parse(m[1]!)][m[2]!] ?? '';
    return props[name] ?? '';
  }

  Future<void> setProperty(String name, String value) async {
    sets[name] = value;
  }

  Future<void> observeProperty(
    String name,
    Future<void> Function(String) fn,
  ) async {
    listener = fn;
  }

  Future<void> unobserveProperty(String name) async {
    listener = null;
  }

  Future<void> line(String text, double start, double end) async {
    props['secondary-sub-start'] = '$start';
    props['secondary-sub-end'] = '$end';
    await listener!(text);
  }
}

Map<String, String> _sub(
  String id,
  String codec, {
  String external = 'no',
  String title = '',
  String def = 'no',
}) => {
  'type': 'sub',
  'id': id,
  'codec': codec,
  'external': external,
  'title': title,
  'default': def,
};

void main() {
  test('has nothing to read without a text track of the file', () async {
    final mpv = _FakeMpv([
      {'type': 'video', 'id': '1'},
      _sub('2', 'hdmv_pgs_subtitle'),
      _sub('3', 'subrip', external: 'yes'),
    ]);
    final ref = MpvSubtitleReference(mpv);
    expect(await ref.start(), isFalse);
    expect(mpv.sets, isEmpty);
  });

  test('reads the file\'s own track, hidden, without the forced one', () async {
    final mpv = _FakeMpv([
      {'type': 'video', 'id': '1'},
      _sub('2', 'subrip', title: 'Forced'),
      _sub('4', 'ass', title: 'English'),
      _sub('5', 'subrip', external: 'yes'),
    ]);
    final ref = MpvSubtitleReference(mpv);
    expect(await ref.start(), isTrue);
    expect(mpv.sets['secondary-sid'], '4');
    expect(mpv.sets['secondary-sub-visibility'], 'no');
    expect(mpv.sets['secondary-sub-delay'], '0');
    expect(mpv.listener, isNotNull);
  });

  test('never reads the track the viewer is watching', () async {
    final mpv = _FakeMpv([_sub('3', 'subrip')]);
    expect(await MpvSubtitleReference(mpv).start(), isFalse);
  });

  test('collects each line once, with the file\'s own times', () async {
    final mpv = _FakeMpv([_sub('2', 'subrip')]);
    final ref = MpvSubtitleReference(mpv);
    var told = 0;
    ref.onCue = () => told++;
    await ref.start();
    await mpv.line('Hello', 3.5, 5.2);
    // mpv repeats the observer on every tick while the line is up.
    await mpv.line('Hello', 3.5, 5.2);
    await mpv.line('', 3.5, 5.2);
    // The same words said again later are a new line.
    await mpv.line('Hello', 9.0, 10.0);
    await mpv.line('Nonsense', 20.0, 80.0);
    expect(ref.cues.map((c) => c.start), [3.5, 9.0]);
    expect(ref.cues.first.end, 5.2);
    expect(told, 2);
  });

  test('stop lets go of the track and the observer', () async {
    final mpv = _FakeMpv([_sub('2', 'subrip')]);
    final ref = MpvSubtitleReference(mpv);
    await ref.start();
    await ref.stop();
    expect(mpv.sets['secondary-sid'], 'no');
    expect(mpv.listener, isNull);
    expect(ref.isRunning, isFalse);
  });
}
