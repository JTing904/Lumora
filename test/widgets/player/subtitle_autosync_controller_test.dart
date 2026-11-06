import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/player/engine/audio_level.dart';
import 'package:zplay/services/subtitles/subtitle_offset_store.dart';
import 'package:zplay/services/subtitles/subtitle_parser.dart';
import 'package:zplay/widgets/player/subtitle_autosync_controller.dart';

List<SubCue> _cues(Random rnd, {double length = 900}) {
  final out = <SubCue>[];
  var t = 5.0;
  var i = 0;
  while (t < length) {
    final dur = 1.5 + rnd.nextDouble() * 2.5;
    out.add(SubCue(start: t, end: t + dur, text: 'line ${i++}'));
    t += dur + 1 + rnd.nextDouble() * 5;
  }
  return out;
}

List<AudioLevelSample> _audio(
  List<SubCue> cues, {
  required double offset,
  required double from,
  required double to,
  required Random rnd,
}) {
  final speech = <int>{};
  for (final c in cues) {
    final a = ((c.start + offset) / 0.1).round();
    final b = ((c.end + offset) / 0.1).round();
    for (var i = a; i < b; i++) {
      speech.add(i);
    }
  }
  return [
    for (var b = (from / 0.1).round(); b < (to / 0.1).round(); b++)
      AudioLevelSample(
        b * 0.1,
        speech.contains(b)
            ? -28 + rnd.nextDouble() * 8
            : -62 + rnd.nextDouble() * 6,
      ),
  ];
}

class _Applied {
  _Applied(this.delay, this.ratio, this.auto);
  final double delay;
  final double ratio;
  final bool auto;
}

void main() {
  late List<_Applied> applied;
  late List<AutoSyncChange> told;
  late StreamController<AudioLevelSample> audio;
  late DateTime now;
  late SubtitleAutoSyncController controller;

  setUp(() {
    applied = [];
    told = [];
    audio = StreamController<AudioLevelSample>(sync: true);
    now = DateTime(2026, 1, 1);
    controller = SubtitleAutoSyncController(
      onApply: (d, r, {required auto}) async =>
          applied.add(_Applied(d, r, auto)),
      onAligned: told.add,
      checkEvery: const Duration(hours: 1),
      clock: () => now,
    )..attachAudio(audio.stream);
  });

  tearDown(() {
    controller.dispose();
    audio.close();
  });

  void feed(Iterable<AudioLevelSample> samples) => samples.forEach(audio.add);

  test('waits, then moves a subtitle that runs 2.3 s early', () async {
    final rnd = Random(1);
    final cues = _cues(rnd);
    controller.begin(cues: cues, delaySec: 0);
    expect(controller.status, AutoSyncStatus.listening);
    feed(_audio(cues, offset: 2.3, from: 20, to: 80, rnd: rnd));
    await controller.tick();
    expect(applied, isEmpty, reason: 'a minute of film is not enough');

    feed(_audio(cues, offset: 2.3, from: 80, to: 300, rnd: rnd));
    await controller.tick();
    expect(applied, hasLength(1));
    expect(applied.single.delay, closeTo(2.3, 0.15));
    expect(applied.single.ratio, 1);
    expect(applied.single.auto, isTrue);
    expect(told, hasLength(1));
    expect(told.single.previousDelaySec, 0);
    expect(controller.status, AutoSyncStatus.aligned);
  });

  test('leaves a subtitle that is already in time', () async {
    final rnd = Random(2);
    final cues = _cues(rnd);
    controller.begin(cues: cues, delaySec: 1.0);
    feed(_audio(cues, offset: 1.1, from: 0, to: 300, rnd: rnd));
    await controller.tick();
    expect(applied, isEmpty);
    expect(controller.status, AutoSyncStatus.aligned);
  });

  test('stays out of it once the viewer moved the timing', () async {
    final rnd = Random(3);
    final cues = _cues(rnd);
    controller.begin(cues: cues, delaySec: 0);
    controller.viewerMoved(0.5);
    expect(controller.status, AutoSyncStatus.paused);
    feed(_audio(cues, offset: 2.3, from: 0, to: 300, rnd: rnd));
    await controller.tick();
    expect(applied, isEmpty);
  });

  test('does nothing while switched off', () async {
    final rnd = Random(4);
    final cues = _cues(rnd);
    controller.enabled = false;
    controller.begin(cues: cues, delaySec: 0);
    expect(controller.status, AutoSyncStatus.off);
    feed(_audio(cues, offset: 2.3, from: 0, to: 300, rnd: rnd));
    await controller.tick();
    expect(applied, isEmpty);
  });

  test('undo puts the old timing back and stops for this subtitle', () async {
    final rnd = Random(5);
    final cues = _cues(rnd);
    controller.begin(cues: cues, delaySec: 0.5);
    feed(_audio(cues, offset: 3.0, from: 0, to: 300, rnd: rnd));
    await controller.tick();
    expect(applied.single.delay, closeTo(3.0, 0.15));

    await controller.undo();
    expect(applied, hasLength(2));
    expect(applied.last.delay, 0.5);
    expect(applied.last.auto, isFalse);
    expect(controller.status, AutoSyncStatus.paused);

    now = now.add(const Duration(minutes: 5));
    feed(_audio(cues, offset: 3.0, from: 300, to: 600, rnd: rnd));
    await controller.tick();
    expect(applied, hasLength(2));
  });

  test('keeps a timing the viewer saved when it is close enough', () async {
    final rnd = Random(6);
    final cues = _cues(rnd);
    // Saved 1.5 s, the film wants 2.3: close enough to leave.
    controller.begin(
      cues: cues,
      delaySec: 1.5,
      savedTiming: const SubtitleTiming(1.5),
    );
    feed(_audio(cues, offset: 2.3, from: 0, to: 300, rnd: rnd));
    await controller.tick();
    expect(applied, isEmpty);
    expect(controller.status, AutoSyncStatus.aligned);
  });

  test('overrules a saved timing that is clearly wrong', () async {
    final rnd = Random(7);
    final cues = _cues(rnd);
    // Saved 0.4 s, the film wants 6 s.
    controller.begin(
      cues: cues,
      delaySec: 0.4,
      savedTiming: const SubtitleTiming(0.4),
    );
    feed(_audio(cues, offset: 6.0, from: 0, to: 400, rnd: rnd));
    await controller.tick();
    expect(applied, hasLength(1));
    expect(applied.single.delay, closeTo(6.0, 0.15));
  });

  test(
    'applies a stream subtitle reference at once, without listening',
    () async {
      final rnd = Random(8);
      final reference = _cues(rnd);
      final downloaded = [
        for (final c in reference)
          SubCue(start: c.start - 2.8, end: c.end - 2.8, text: c.text),
      ];
      controller.begin(
        cues: downloaded,
        delaySec: 0,
        streamReference: () async => reference,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.tick();
      expect(applied, hasLength(1));
      expect(applied.single.delay, closeTo(2.8, 0.15));
      expect(told.single.source, AutoSyncSource.streamSubtitle);
    },
  );

  test(
    'applies a stretch when the subtitle is for another frame rate',
    () async {
      final rnd = Random(9);
      final reference = _cues(rnd, length: 3000);
      const ratio = 25 / 23.976;
      final downloaded = [
        for (final c in reference)
          SubCue(start: c.start / ratio, end: c.end / ratio, text: c.text),
      ];
      controller.begin(
        cues: downloaded,
        delaySec: 0,
        streamReference: () async => reference,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.tick();
      expect(applied.single.ratio, closeTo(ratio, 1e-9));
      expect(told.single.stretched, isTrue);
    },
  );

  test('reads the video\'s own subtitle gathered while watching', () async {
    final rnd = Random(10);
    final reference = _cues(rnd);
    final downloaded = [
      for (final c in reference)
        SubCue(start: c.start + 4.0, end: c.end + 4.0, text: c.text),
    ];
    controller.attachAudio(null);
    controller.setLiveReferenceAvailable(true);
    controller.begin(cues: downloaded, delaySec: 0);
    expect(controller.status, AutoSyncStatus.listening);
    controller.setLiveReference(reference.take(15).toList());
    await controller.tick();
    expect(applied, isEmpty, reason: '15 lines are too few');
    controller.setLiveReference(reference.take(60).toList());
    await controller.tick();
    expect(applied.single.delay, closeTo(-4.0, 0.15));
    expect(told.single.source, AutoSyncSource.embeddedSubtitle);
  });

  test('says so when there is nothing to compare with', () {
    final rnd = Random(11);
    controller.attachAudio(null);
    controller.begin(cues: _cues(rnd), delaySec: 0);
    expect(controller.status, AutoSyncStatus.noSource);
  });

  test('notices a change of timing partway through', () async {
    final rnd = Random(12);
    final cues = _cues(rnd, length: 1500);
    controller.begin(cues: cues, delaySec: 0);
    feed(_audio(cues, offset: 2.3, from: 0, to: 300, rnd: rnd));
    await controller.tick();
    expect(applied.single.delay, closeTo(2.3, 0.15));

    // An ad break: from here on the sound is 5 s later against the lines.
    now = now.add(const Duration(seconds: 61));
    feed(_audio(cues, offset: 5.0, from: 300, to: 700, rnd: rnd));
    await controller.tick();
    expect(applied, hasLength(2));
    expect(applied.last.delay, closeTo(5.0, 0.15));
  });

  test('a new video starts with a clean slate', () async {
    final rnd = Random(13);
    final cues = _cues(rnd);
    controller.begin(cues: cues, delaySec: 0);
    feed(_audio(cues, offset: 2.0, from: 0, to: 100, rnd: rnd));
    expect(controller.listenedSec, greaterThan(90));
    controller.newSource();
    expect(controller.listenedSec, 0);
    expect(controller.status, AutoSyncStatus.off);
  });
}
