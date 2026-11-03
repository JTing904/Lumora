import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zplay/models/download/download_task_model.dart';
import 'package:zplay/services/download/download_files.dart';

DownloadTask _task({
  DownloadSourceType sourceType = DownloadSourceType.http,
  String? rawUrl,
  String? infoHash,
  int? fileIdx,
}) => DownloadTask(
  id: 't',
  title: 'Dune',
  mediaId: 'tmdb:438631',
  type: 'movie',
  sourceType: sourceType,
  sourceName: 's',
  rawUrl: rawUrl,
  infoHash: infoHash,
  fileIdx: fileIdx,
  targetFilePath: '/x/Dune.mp4',
  createdAt: DateTime(2026),
);

void main() {
  group('baseFilename', () {
    test('two titles with the same name get different files', () {
      final a = DownloadFiles.baseFilename(title: 'Dune', mediaId: 'tmdb:841');
      final b = DownloadFiles.baseFilename(
        title: 'Dune',
        mediaId: 'tmdb:438631',
      );
      expect(a, isNot(b));
      expect(a, 'Dune_tmdb_841');
    });

    test('episodes keep their SxxEyy and the id', () {
      expect(
        DownloadFiles.baseFilename(
          title: 'Show: Part 1',
          mediaId: 'tt123',
          season: 1,
          episode: 2,
        ),
        'Show_ Part 1_S01E02_tt123',
      );
    });

    test('an id never adds path separators', () {
      final name = DownloadFiles.baseFilename(
        title: 'X',
        mediaId: r'..\..\evil/id',
      );
      expect(name.contains('/'), isFalse);
      expect(name.contains(r'\'), isFalse);
    });
  });

  group('resume guard', () {
    test('a .part continues only for the source that started it', () {
      final a = DownloadFiles.sourceKey(_task(rawUrl: 'https://a/x.mp4'));
      final b = DownloadFiles.sourceKey(_task(rawUrl: 'https://b/x.mp4'));
      final recorded = DownloadFiles.sourceFingerprint(a);
      expect(
        DownloadFiles.canResume(recordedFingerprint: recorded, sourceKey: a),
        isTrue,
      );
      expect(
        DownloadFiles.canResume(recordedFingerprint: recorded, sourceKey: b),
        isFalse,
      );
    });

    test('a .part with no record is not trusted', () {
      expect(
        DownloadFiles.canResume(recordedFingerprint: null, sourceKey: 'url:a'),
        isFalse,
      );
    });

    test('debrid tasks are keyed by torrent, not the re-resolved link', () {
      final first = _task(
        sourceType: DownloadSourceType.debrid,
        rawUrl: 'https://rd/1',
        infoHash: 'ABC',
        fileIdx: 3,
      );
      final second = _task(
        sourceType: DownloadSourceType.debrid,
        rawUrl: 'https://rd/2',
        infoHash: 'abc',
        fileIdx: 3,
      );
      expect(DownloadFiles.sourceKey(first), DownloadFiles.sourceKey(second));
    });

    test('the sidecar never holds the URL itself', () {
      final key = DownloadFiles.sourceKey(
        _task(rawUrl: 'https://a/x.mp4?token=secret'),
      );
      expect(DownloadFiles.sourceFingerprint(key).contains('secret'), isFalse);
    });

    test('another source\'s .part is deleted, our own is kept', () async {
      final dir = await Directory.systemTemp.createTemp('dlfiles');
      addTearDown(() => dir.delete(recursive: true));
      final target = p.join(dir.path, 'Dune_tmdb_841.mp4');

      await DownloadFiles.claimPart(target, 'url:a');
      await File('$target.part').writeAsString('aaaa');
      expect(await DownloadFiles.keepPartOnlyFor(target, 'url:a'), isTrue);
      expect(await File('$target.part').exists(), isTrue);

      expect(await DownloadFiles.keepPartOnlyFor(target, 'url:b'), isFalse);
      expect(await File('$target.part').exists(), isFalse);
      expect(await File('$target.part.source').exists(), isFalse);
    });

    test('a legacy .part without a record starts over', () async {
      final dir = await Directory.systemTemp.createTemp('dlfiles');
      addTearDown(() => dir.delete(recursive: true));
      final target = p.join(dir.path, 'Dune.mp4');
      await File('$target.part').writeAsString('old');
      expect(await DownloadFiles.keepPartOnlyFor(target, 'url:a'), isFalse);
      expect(await File('$target.part').exists(), isFalse);
    });
  });
}
