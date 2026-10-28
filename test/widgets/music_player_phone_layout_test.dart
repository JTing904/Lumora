/// The expanded music player on a short phone, and the page's overlays once
/// the track under them is gone.
///
/// The phone layout used to be a non-scrolling column with the artwork sized
/// from the screen alone, so 360x640 overflowed once the panels row joined the
/// transport. And the expanded player's flag outlived the track it drew: with
/// playback stopped nothing was on screen, yet the page behind stayed out of
/// the remote's reach.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/music/music_track.dart';
import 'package:zplay/pages/music/lu_media_kit.dart';
import 'package:zplay/pages/music/music_page.dart';
import 'package:zplay/services/layout/form_factor.dart';
import 'package:zplay/services/music/music_player_controller.dart';
import 'package:zplay/shell/app_shell_scope.dart';
import 'package:zplay/widgets/music/music_waveform_seekbar.dart';

const _track = MusicTrack(
  id: 'phone-layout-1',
  title: 'A Rather Long Track Title That Will Not Fit',
  artist: 'An Artist',
  album: 'An Album',
  coverUrl: '',
  durationSeconds: 240,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final controller = MusicPlayerController.instance;

  Future<void> loadTrack(WidgetTester tester) async {
    // The controller publishes the track before it reaches for a player, and
    // nothing in a widget test can play one, so the load stops there.
    // ignore: unawaited_futures
    controller.playTrack(_track);
    await tester.pump();
    expect(controller.hasTrack, isTrue);
  }

  Future<void> unloadTrack(WidgetTester tester) async {
    // ignore: unawaited_futures
    controller.stop();
    await tester.pump();
  }

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets(
      'the expanded player fits ${size.width}x${size.height} without overflow',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const MaterialApp(home: MusicPage()));
        await tester.pump();
        await loadTrack(tester);
        addTearDown(() => controller.stop());

        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(MusicWaveformSeekbar), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Every control the phone player draws is on screen, down to the
        // panels row at the bottom.
        final queue = find.byTooltip('Queue');
        if (queue.evaluate().isNotEmpty) {
          final rect = tester.getRect(queue.first);
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }

        await unloadTrack(tester);
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  }

  testWidgets('a stopped track takes its expanded player and the focus lock '
      'with it', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final slot = ValueNotifier(ShellSlot.browse);
    final shell = AppShellController(
      current: slot,
      onSelect: (next) {
        slot.value = next;
        return true;
      },
      formFactor: () => FormFactor.television,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScope(controller: shell, child: const MusicPage()),
      ),
    );
    await tester.pump();
    await loadTrack(tester);
    addTearDown(() => controller.stop());

    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(shell.hasBackClaim, isTrue);

    await unloadTrack(tester);
    await tester.pump();
    expect(
      shell.hasBackClaim,
      isFalse,
      reason: 'nothing is drawn over the page, so nothing holds the press',
    );

    final pillText = find.descendant(
      of: find.byType(LuPillTabs<MusicView>),
      matching: find.text(MusicView.library.label),
    );
    final pill = Focus.of(tester.element(pillText));
    pill.requestFocus();
    await tester.pump();
    expect(
      pill.hasFocus,
      isTrue,
      reason: 'the page is reachable again once the overlay is gone',
    );

    // With no track, F has nothing to expand and must not lock the page.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(pill.hasFocus, isTrue);
  });

  testWidgets('no claim is held while Browse shows another vertical', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final slot = ValueNotifier(ShellSlot.browse);
    final shell = AppShellController(
      current: slot,
      onSelect: (next) {
        slot.value = next;
        return true;
      },
      formFactor: () => FormFactor.television,
    );
    final vertical = ValueNotifier(1);
    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScope(
          controller: shell,
          child: ValueListenableBuilder<int>(
            valueListenable: vertical,
            builder: (context, index, _) => IndexedStack(
              index: index,
              children: const [SizedBox.expand(), MusicPage()],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();
    expect(shell.hasBackClaim, isTrue);

    vertical.value = 0;
    await tester.pump();
    expect(
      shell.hasBackClaim,
      isFalse,
      reason: 'a hidden vertical must not eat the press of the one on screen',
    );

    vertical.value = 1;
    await tester.pump();
    expect(shell.hasBackClaim, isTrue);
  });
}
