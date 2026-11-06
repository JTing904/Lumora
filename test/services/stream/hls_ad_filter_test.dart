import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/stream/hls_ad_filter.dart';

/// The playlists under test/fixtures/hls are real 中文资源站 playlists, cut
/// down and with every host, folder and file name replaced by a made-up one of
/// the same shape. Each [_fixtures] entry is the address the original was
/// served from.
const _fixtures = <String, String>{
  'ads_encrypted_no_iv':
      'https://cdn2.example.test/20240516/aF8pDgcH/955kb/hls/index.m3u8',
  'ads_midroll_absolute':
      'https://cdn4.example.test/20251108/gyLwFSPF/1096kb/hls/index.m3u8',
  'ads_labelled_relative':
      'https://cdn5.example.test/20251024/2848_xrw729nf/2000k/hls/mixed.m3u8',
  'ads_cue_out':
      'https://cdn6.example.test:65/videos/20250205/23b11k22472v554yu707386k/z50444/index.m3u8',
  'ads_adjump': 'https://cdn7.example.test/video/pmcycwyfinvi4/HD/index.m3u8',
  'ads_short_clip':
      'https://cdn10.example.test/20260702/VOzLUTvK/2000kb/hls/index.m3u8',
  'clean_discontinuities':
      'https://cdn11.example.test/20240718/76811_5o047690/3000k/hls/mixed.m3u8',
  'clean_encrypted_relative_key':
      'https://cdn13.example.test/play/l7tiK8va/index.m3u8',
  'clean_cut_ads':
      'https://cdn15.example.test/xbz0/477152/32/IQDBbKlxf61/video/9714p_1114/hls/index.m3u8',
};

String _fixture(String name) =>
    File('test/fixtures/hls/$name.m3u8').readAsStringSync();

HlsCleanResult _cleanFixture(String name) =>
    HlsAdFilter.clean(_fixture(name), Uri.parse(_fixtures[name]!));

class _Seg {
  _Seg(this.uri, this.seconds, this.iv, this.key);
  final String uri;
  final double seconds;

  /// The IV a player would decrypt it with, or null when it is not encrypted.
  final String? iv;
  final String? key;
}

/// The segments of [playlist] with the key and IV a player would use for each:
/// an explicit IV as written, otherwise the media sequence number.
List<_Seg> _segments(String playlist) {
  final out = <_Seg>[];
  var sequence = 0;
  String? keyUri;
  String? keyIv;
  var encrypted = false;
  double? seconds;
  for (final raw in playlist.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
      sequence = int.parse(line.split(':')[1]);
    } else if (line.startsWith('#EXT-X-KEY:')) {
      encrypted = !line.contains('METHOD=NONE');
      keyUri = RegExp(r'URI="([^"]*)"').firstMatch(line)?.group(1);
      keyIv = RegExp(r'IV=0x([0-9a-fA-F]+)').firstMatch(line)?.group(1);
    } else if (line.startsWith('#EXTINF:')) {
      seconds = double.parse(RegExp(r'[0-9.]+').stringMatch(line)!);
    } else if (line.isNotEmpty && !line.startsWith('#')) {
      final iv = !encrypted
          ? null
          : (keyIv ?? sequence.toRadixString(16).padLeft(32, '0'))
                .toLowerCase()
                .padLeft(32, '0');
      out.add(_Seg(line, seconds ?? 0, iv, encrypted ? keyUri : null));
      sequence++;
    }
  }
  return out;
}

double _seconds(List<_Seg> segments) =>
    segments.fold(0.0, (s, e) => s + e.seconds);

String _dir(String uri) => uri.substring(0, uri.lastIndexOf('/'));

/// A playlist built from blocks: [(directory, segment count, seconds each)]
/// with a discontinuity between every two. Names are numbered per block.
String _playlist(
  List<(String, int, double)> blocks, {
  bool discontinuities = true,
  bool endlist = true,
}) {
  final b = StringBuffer(
    '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:10\n',
  );
  b.writeln('#EXT-X-MEDIA-SEQUENCE:0');
  for (var i = 0; i < blocks.length; i++) {
    final (dir, count, seconds) = blocks[i];
    if (i > 0 && discontinuities) b.writeln('#EXT-X-DISCONTINUITY');
    for (var n = 0; n < count; n++) {
      b.writeln('#EXTINF:$seconds,');
      b.writeln('$dir/${i}_$n.ts');
    }
  }
  if (endlist) b.writeln('#EXT-X-ENDLIST');
  return b.toString();
}

const _film = 'https://v1.example.test/20240101/film/hls';
const _other = 'https://v1.example.test/20261031/ad/hls';
final _base = Uri.parse('https://v1.example.test/20240101/film/hls/index.m3u8');

void main() {
  group('real playlists with ads', () {
    test('mid-roll ads on absolute addresses are cut, the film is kept', () {
      final text = _fixture('ads_midroll_absolute');
      final result = _cleanFixture('ads_midroll_absolute');
      final before = _segments(text);
      final after = _segments(result.playlist);

      expect(result.changed, isTrue);
      expect(result.removedBlocks, 3);
      expect(result.removedSeconds, closeTo(3 * 17.6, 0.5));
      // What is left is one directory, and is every segment of the original
      // that was in that directory, in order.
      expect(after.map((s) => _dir(s.uri)).toSet(), hasLength(1));
      final filmDir = _dir(after.first.uri);
      expect(
        after.map((s) => s.uri),
        before.map((s) => s.uri).where((u) => _dir(u) == filmDir),
      );
      expect(
        _seconds(before) - _seconds(after),
        closeTo(result.removedSeconds, 0.01),
      );
    });

    test('ads marked "ad-injected" go, and relative film addresses are made '
        'absolute', () {
      final text = _fixture('ads_labelled_relative');
      final result = _cleanFixture('ads_labelled_relative');
      final after = _segments(result.playlist);

      expect(text, contains('ppvod-ad-injected'));
      expect(result.changed, isTrue);
      expect(result.removedSeconds, closeTo(25.8 * result.removedBlocks, 0.5));
      expect(after, isNotEmpty);
      expect(
        after.every(
          (s) => s.uri.startsWith(
            'https://cdn5.example.test/20251024/2848_xrw729nf/2000k/hls/',
          ),
        ),
        isTrue,
      );
    });

    test('a CUE-OUT span goes with its tags, over relative film addresses', () {
      final result = _cleanFixture('ads_cue_out');
      final after = _segments(result.playlist);

      expect(result.changed, isTrue);
      expect(result.removedSeconds, closeTo(17.57, 0.05));
      expect(result.playlist, isNot(contains('CUE-OUT')));
      expect(result.playlist, isNot(contains('CUE-IN')));
      expect(after.map((s) => _dir(s.uri)).toSet(), hasLength(1));
      expect(after.first.uri, startsWith('https://cdn6.example.test:65/'));
    });

    test('ads served from an /adjump/ folder are cut', () {
      final text = _fixture('ads_adjump');
      final result = _cleanFixture('ads_adjump');

      expect(text, contains('/adjump/'));
      expect(result.changed, isTrue);
      expect(result.playlist, isNot(contains('adjump')));
      expect(
        _segments(result.playlist).map((s) => _dir(s.uri)).toSet(),
        hasLength(1),
      );
    });

    test('a short clip with two ads has them cut', () {
      final result = _cleanFixture('ads_short_clip');
      expect(result.changed, isTrue);
      expect(result.removedBlocks, 2);
      expect(result.removedSeconds, closeTo(35.2, 0.5));
    });

    test('encrypted film, ads in the clear, no IV: every kept segment is '
        'still decrypted with the IV it had', () {
      final text = _fixture('ads_encrypted_no_iv');
      final result = _cleanFixture('ads_encrypted_no_iv');
      final before = _segments(
        HlsAdFilter.absolutize(
          text,
          Uri.parse(_fixtures['ads_encrypted_no_iv']!),
        ),
      );
      final after = _segments(result.playlist);

      expect(text, contains('METHOD=NONE'));
      expect(text, isNot(contains('IV=')));
      expect(result.changed, isTrue);

      // The IV came from the position in the playlist, which the cut moved.
      final ivBefore = {for (final s in before) s.uri: s.iv};
      expect(after, isNotEmpty);
      for (final s in after) {
        expect(s.iv, isNotNull, reason: s.uri);
        expect(s.iv, ivBefore[s.uri], reason: s.uri);
        expect(s.key, startsWith('https://cdn2.example.test/'));
      }
      // And nothing in the clear is left: the ads were the only such segments.
      expect(after.every((s) => s.iv != null), isTrue);
      expect(result.playlist, isNot(contains('METHOD=NONE')));
    });

    test('a cut at the start does not leave a discontinuity first', () {
      final result = HlsAdFilter.clean(
        _playlist([(_other, 4, 4.4), (_film, 40, 4)]),
        _base,
      );
      expect(result.removedSeconds, closeTo(17.6, 0.01));
      final lines = result.playlist.split('\n');
      final firstSegment = lines.indexWhere((l) => l.startsWith('#EXTINF'));
      expect(lines.take(firstSegment), isNot(contains('#EXT-X-DISCONTINUITY')));
    });
  });

  group('playlists without ads', () {
    test('are returned as they were, apart from absolute addresses', () {
      for (final name in [
        'clean_discontinuities',
        'clean_encrypted_relative_key',
      ]) {
        final text = _fixture(name);
        final base = Uri.parse(_fixtures[name]!);
        final result = HlsAdFilter.clean(text, base);
        expect(result.changed, isFalse, reason: name);
        expect(
          result.playlist,
          HlsAdFilter.absolutize(text, base),
          reason: name,
        );
        expect(result.playlist, isNot(contains('\n/')), reason: name);
      }
    });

    test('cut-out ads leave only empty discontinuity blocks, which is not '
        'something to remove', () {
      final text = _fixture('clean_cut_ads');
      final result = _cleanFixture('clean_cut_ads');
      expect(result.changed, isFalse);
      expect(
        _segments(result.playlist).map((s) => s.uri),
        _segments(
          HlsAdFilter.absolutize(text, Uri.parse(_fixtures['clean_cut_ads']!)),
        ).map((s) => s.uri),
      );
    });

    test('a relative key is resolved against the playlist', () {
      final text = _fixture('clean_encrypted_relative_key');
      expect(text, contains('URI="enc.key"'));
      expect(
        _cleanFixture('clean_encrypted_relative_key').playlist,
        contains('URI="https://cdn13.example.test/play/l7tiK8va/enc.key"'),
      );
    });
  });

  group('where the ads sit', () {
    test('at the start, in the middle and at the end', () {
      final text = _playlist([
        (_other, 4, 4.4),
        (_film, 30, 4),
        (_other, 4, 4.4),
        (_film, 30, 4),
        (_other, 4, 4.4),
      ]);
      final result = HlsAdFilter.clean(text, _base);
      expect(result.removedBlocks, 3);
      expect(result.removedSegments, 12);
      final after = _segments(result.playlist);
      expect(after, hasLength(60));
      expect(after.every((s) => s.uri.startsWith(_film)), isTrue);
      // The two halves of the film still have a discontinuity between them,
      // and nothing else does.
      expect('#EXT-X-DISCONTINUITY'.allMatches(result.playlist), hasLength(1));
      expect(result.playlist.trimRight(), endsWith('#EXT-X-ENDLIST'));
    });

    test('two ads in a row become one cut and one discontinuity', () {
      final text = _playlist([
        (_film, 30, 4),
        (_other, 3, 5),
        ('https://v2.example.test/20261101/ad/hls', 3, 5),
        (_film, 30, 4),
      ]);
      final result = HlsAdFilter.clean(text, _base);
      expect(result.removedBlocks, 2);
      expect('#EXT-X-DISCONTINUITY'.allMatches(result.playlist), hasLength(1));
    });

    test(
      'foreign segments with no discontinuity round them are not touched',
      () {
        final text = _playlist([
          (_film, 30, 4),
          (_other, 4, 4.4),
          (_film, 30, 4),
        ], discontinuities: false);
        final result = HlsAdFilter.clean(text, _base);
        expect(result.changed, isFalse);
        expect(_segments(result.playlist), hasLength(64));
      },
    );

    test('the same host under another name is still the film', () {
      final text = _playlist([
        (_film, 30, 4),
        ('https://v2.example.test/20240101/film/hls', 10, 4),
        (_film, 30, 4),
      ]);
      expect(HlsAdFilter.clean(text, _base).changed, isFalse);
    });
  });

  group('refuses', () {
    test('when the film is in two folders and neither is most of it', () {
      final text = _playlist([(_film, 30, 4), (_other, 30, 4)]);
      final result = HlsAdFilter.clean(text, _base);
      expect(result.changed, isFalse);
      expect(result.skipReason, isNotNull);
    });

    test('when the blocks would be more than a fifth of the playlist', () {
      // Three different blocks of 40 s beside 280 s: 30 percent, each one
      // seen once, none labelled.
      final text = _playlist([
        (_film, 35, 4),
        ('https://v2.example.test/a', 10, 4),
        (_film, 35, 4),
        ('https://v2.example.test/b', 10, 4),
        (_film, 35, 4),
        ('https://v2.example.test/c', 10, 4),
      ]);
      final result = HlsAdFilter.clean(text, _base);
      expect(result.changed, isFalse);
      expect(result.skipReason, contains('%'));
      expect(_segments(result.playlist), hasLength(135));
    });

    test('when even repeated, the blocks would be most of the playlist', () {
      final text = _playlist([
        (_film, 10, 4),
        (_other, 10, 4),
        (_film, 10, 4),
        (_other, 10, 4),
        (_film, 10, 4),
      ]);
      // 80 s of 200 s is 40 percent: past even the repeated limit.
      expect(HlsAdFilter.clean(text, _base).changed, isFalse);
    });

    test('a foreign block longer than two minutes is the film', () {
      final text = _playlist([
        (_film, 100, 4),
        ('https://v2.example.test/part2', 40, 4),
      ]);
      expect(HlsAdFilter.clean(text, _base).changed, isFalse);
    });

    test('a playlist of one folder is never touched, however many breaks', () {
      final text = _playlist([for (var i = 0; i < 20; i++) (_film, 5, 4)]);
      final result = HlsAdFilter.clean(text, _base);
      expect(result.changed, isFalse);
      expect(_segments(result.playlist), hasLength(100));
    });

    test('an empty or broken playlist comes back without throwing', () {
      expect(HlsAdFilter.clean('', _base).changed, isFalse);
      expect(HlsAdFilter.clean('#EXTM3U\n', _base).changed, isFalse);
      expect(HlsAdFilter.clean('<html>nope</html>', _base).changed, isFalse);
    });
  });

  group('labels', () {
    test('a labelled block goes even from the same folder', () {
      final text = _playlist([(_film, 40, 4), (_film, 4, 4), (_film, 40, 4)])
          .replaceFirst(
            '#EXT-X-DISCONTINUITY\n#EXTINF:4.0,\n$_film/1_0.ts',
            '# ppvod-ad-injected v1\n#EXT-X-DISCONTINUITY\n#EXTINF:4.0,\n$_film/1_0.ts',
          );
      final result = HlsAdFilter.clean(text, _base);
      expect(result.removedSegments, 4);
    });

    test('a repeated block named unlike the film goes even from the same '
        'folder', () {
      final film = [
        for (var i = 0; i < 40; i++) '#EXTINF:4,\n$_film/AbCdEf${i + 10}.ts',
      ].join('\n');
      final ad = [
        for (var i = 0; i < 4; i++) '#EXTINF:4,\n$_film/0000000000000$i.ts',
      ].join('\n');
      final text =
          '#EXTM3U\n#EXT-X-TARGETDURATION:4\n$film\n#EXT-X-DISCONTINUITY\n$ad\n'
          '#EXT-X-DISCONTINUITY\n$film\n#EXT-X-DISCONTINUITY\n$ad\n#EXT-X-ENDLIST\n';
      final result = HlsAdFilter.clean(text, _base);
      expect(result.removedBlocks, 2);
    });
  });

  group('what a cut takes with it', () {
    test('an explicit IV and the key are kept for the film after an ad', () {
      const key = '#EXT-X-KEY:METHOD=AES-128,URI="k.key",IV=0x0A';
      final text =
          '#EXTM3U\n#EXT-X-TARGETDURATION:4\n$key\n'
          '${[for (var i = 0; i < 30; i++) '#EXTINF:4,\n$_film/a$i.ts'].join('\n')}\n'
          '#EXT-X-DISCONTINUITY\n#EXT-X-KEY:METHOD=NONE\n'
          '${[for (var i = 0; i < 3; i++) '#EXTINF:4,\n$_other/x$i.ts'].join('\n')}\n'
          '#EXT-X-DISCONTINUITY\n$key\n'
          '${[for (var i = 0; i < 30; i++) '#EXTINF:4,\n$_film/b$i.ts'].join('\n')}\n'
          '#EXT-X-ENDLIST\n';
      final result = HlsAdFilter.clean(text, _base);
      final after = _segments(result.playlist);
      expect(result.removedSegments, 3);
      expect(after, hasLength(60));
      expect(after.every((s) => s.iv == '0a'.padLeft(32, '0')), isTrue);
      expect(after.every((s) => s.key == '$_film/k.key'), isTrue);
    });

    test('a byte range that continued the removed one gets its offset', () {
      String ranges(int count, String range) => [
        for (var i = 0; i < count; i++)
          '#EXTINF:4,\n#EXT-X-BYTERANGE:$range\n$_film/f.mp4',
      ].join('\n');
      final text =
          '#EXTM3U\n#EXT-X-TARGETDURATION:4\n'
          '#EXT-X-MAP:URI="init.mp4"\n'
          '#EXTINF:4,\n#EXT-X-BYTERANGE:1000@0\n$_film/f.mp4\n'
          '${ranges(19, '1000')}\n'
          '# ppvod-ad-injected v1\n#EXT-X-DISCONTINUITY\n'
          '${ranges(3, '500')}\n'
          '#EXT-X-DISCONTINUITY\n'
          '${ranges(20, '1000')}\n'
          '#EXT-X-ENDLIST\n';
      final result = HlsAdFilter.clean(text, _base);
      expect(result.removedSegments, 3);
      // The first range after the cut continued from the ad's, not the film's.
      expect(result.playlist, contains('#EXT-X-BYTERANGE:1000@21500'));
      expect(result.playlist, contains('#EXT-X-BYTERANGE:1000@40500'));
      expect(result.playlist, contains('#EXT-X-MAP:URI="$_film/init.mp4"'));
    });

    test('Windows line endings are read', () {
      final text = _playlist([
        (_film, 30, 4),
        (_other, 4, 4.4),
        (_film, 30, 4),
      ]).replaceAll('\n', '\r\n');
      final result = HlsAdFilter.clean(text, _base);
      expect(result.removedSegments, 4);
      expect(result.playlist, isNot(contains('\r')));
    });
  });

  group('master playlists', () {
    final masterBase = Uri.parse('https://cdn.example.test/a/b/index.m3u8');
    const master =
        '#EXTM3U\n'
        '#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=800000,RESOLUTION=1280x720\n'
        '/a/b/720/index.m3u8\n'
        '#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080\n'
        '1080/index.m3u8\n'
        '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="a",NAME="x",URI="audio/index.m3u8"\n';

    test('lists its variants with absolute addresses', () {
      final variants = HlsAdFilter.variants(master, masterBase);
      expect(variants.map((v) => v.uri), [
        'https://cdn.example.test/a/b/720/index.m3u8',
        'https://cdn.example.test/a/b/1080/index.m3u8',
      ]);
      expect(variants.map((v) => v.bandwidth), [800000, 2400000]);
      expect(variants.last.resolution, '1920x1080');
      expect(HlsAdFilter.isMaster(master), isTrue);
      expect(HlsAdFilter.isMaster(_playlist([(_film, 3, 4)])), isFalse);
    });

    test(
      'is made absolute throughout, and a variant can be pointed elsewhere',
      () {
        final out = HlsAdFilter.absolutize(
          master,
          masterBase,
          replace: (u) =>
              u.endsWith('/720/index.m3u8') ? 'file:///tmp/clean.m3u8' : null,
        );
        expect(out, contains('\nfile:///tmp/clean.m3u8\n'));
        expect(
          out,
          contains('\nhttps://cdn.example.test/a/b/1080/index.m3u8\n'),
        );
        expect(
          out,
          contains('URI="https://cdn.example.test/a/b/audio/index.m3u8"'),
        );
      },
    );

    test('the real master of an encrypted film resolves to its variant', () {
      final text = _fixture('master_single_variant');
      final variants = HlsAdFilter.variants(
        text,
        Uri.parse('https://cdn2.example.test/20240516/aF8pDgcH/index.m3u8'),
      );
      expect(variants.single.uri, _fixtures['ads_encrypted_no_iv']);
      expect(variants.single.bandwidth, 955000);
    });
  });

  test('looksLikePlaylist', () {
    expect(HlsAdFilter.looksLikePlaylist('\n #EXTM3U\n'), isTrue);
    expect(HlsAdFilter.looksLikePlaylist('<html>'), isFalse);
  });
}
