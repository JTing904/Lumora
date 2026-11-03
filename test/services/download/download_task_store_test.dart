import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zplay/services/download/download_task_store.dart';

void main() {
  late Directory support;
  late Directory documents;
  late DownloadTaskStore store;

  setUp(() async {
    final root = await Directory.systemTemp.createTemp('dlstore');
    support = Directory(p.join(root.path, 'support'));
    documents = Directory(p.join(root.path, 'documents'))..createSync();
    store = DownloadTaskStore(
      directory: () async => support,
      legacyDirectory: () async => documents,
    );
    addTearDown(() => root.delete(recursive: true));
  });

  File live() => File(p.join(support.path, DownloadTaskStore.fileName));
  String list(String id) => jsonEncode([
    {'id': id},
  ]);

  test('saves and loads the list', () async {
    await store.save(() => list('a'));
    final loaded = await store.load();
    expect(loaded!.single['id'], 'a');
    expect(await File('${live().path}.tmp').exists(), isFalse);
  });

  test(
    'saves made during a write collapse into one write of the latest',
    () async {
      var encodes = 0;
      var current = 'a';
      String encode() {
        encodes++;
        return list(current);
      }

      final first = store.save(encode);
      for (final id in ['b', 'c', 'd', 'e']) {
        current = id;
        unawaited(store.save(encode));
      }
      await first;

      expect(encodes, 2);
      expect((await store.load())!.single['id'], 'e');
    },
  );

  test('a corrupt live file falls back to the last good list', () async {
    await store.save(() => list('old'));
    await store.save(() => list('new'));
    await live().writeAsString('[{"id": "tru');

    final loaded = await store.load();
    expect(loaded!.single['id'], 'old');
    expect(await File('${live().path}.corrupt').exists(), isTrue);

    // The next write must not turn the corrupt file into the backup.
    await store.save(() => list('next'));
    expect(
      jsonDecode(await File('${live().path}.bak').readAsString()),
      isA<List>(),
    );
  });

  test('moves the old Documents file once', () async {
    final legacy = File(
      p.join(documents.path, DownloadTaskStore.legacyFileName),
    );
    await legacy.writeAsString(list('legacy'));

    expect((await store.load())!.single['id'], 'legacy');
    expect(await legacy.exists(), isFalse);
    expect(await live().exists(), isTrue);
    expect((await store.load())!.single['id'], 'legacy');
  });

  test('nothing saved yet loads as null', () async {
    expect(await store.load(), isNull);
  });
}
