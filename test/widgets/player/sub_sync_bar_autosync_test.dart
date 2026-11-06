import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/l10n/l10n.dart';
import 'package:zplay/services/subtitles/subtitle_autosync_settings.dart';
import 'package:zplay/services/subtitles/subtitle_parser.dart';
import 'package:zplay/widgets/player/sub_sync_bar.dart';
import 'package:zplay/widgets/player/subtitle_autosync_controller.dart';

void main() {
  late SubtitleAutoSyncController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SubtitleAutoSyncSettings.enabled.value = true;
    controller = SubtitleAutoSyncController(
      onApply: (d, r, {required auto}) async {},
      checkEvery: const Duration(hours: 1),
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SubSyncBar(
          autoSync: controller,
          delaySec: 0,
          onDelayChanged: (_) {},
          onClose: () {},
        ),
      ),
    ),
  );

  testWidgets('says what the auto-sync is doing and follows it', (
    tester,
  ) async {
    await pump(tester);
    final l10n = l10nCurrent();
    // No subtitle yet: nothing to report beyond the name of the switch.
    expect(find.text(l10n.subAutoSyncOn), findsOneWidget);

    controller.attachAudio(null);
    controller.setLiveReferenceAvailable(true);
    controller.begin(
      cues: [
        for (var i = 0; i < 30; i++)
          SubCue(start: i * 5.0, end: i * 5.0 + 2, text: 'x'),
      ],
      delaySec: 0,
    );
    await tester.pump();
    expect(find.text(l10n.subAutoSyncListening), findsOneWidget);

    controller.viewerMoved(1);
    await tester.pump();
    expect(find.text(l10n.subAutoSyncPaused), findsOneWidget);
    controller.end();
  });

  testWidgets('the switch turns auto-sync off and is remembered', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(SubtitleAutoSyncSettings.enabled.value, isFalse);
    expect(find.text(l10nCurrent().subAutoSyncOff), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('subtitle_autosync_enabled'), isFalse);
  });
}
