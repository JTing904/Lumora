/// The transport bar laid out with every control it can carry, at the widths
/// it meets: the words-for-glyphs switch (1280 dp) must not push the row past
/// its edges at any of them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/widgets/player/player_transport.dart';

Widget _bar() => MaterialApp(
  home: Scaffold(
    backgroundColor: Colors.black,
    body: Align(
      alignment: Alignment.bottomCenter,
      child: PlayerTransport(
        isPlaying: true,
        position: const Duration(minutes: 12, seconds: 40),
        duration: const Duration(minutes: 145),
        volume: 0.7,
        isMuted: false,
        playbackRate: 1.25,
        isSubtitlesActive: true,
        subtitleLanguage: 'English',
        isSubSyncActive: false,
        isAudioActive: false,
        isFullscreen: false,
        hasPrevEpisode: true,
        hasNextEpisode: true,
        sourceQuality: '1080p',
        qualityCap: '1080p',
        onToggleQualityMenu: () {},
        onShowSources: () {},
        onToggleEpisodes: () {},
        onPrevEpisode: () {},
        onNextEpisode: () {},
        onPlayPause: () {},
        onSeek: (_) {},
        onSeekBack10: () {},
        onSeekForward10: () {},
        onVolumeChanged: (_) {},
        onToggleMute: () {},
        onToggleAspectMenu: () {},
        onToggleSpeedMenu: () {},
        onToggleAudioMenu: () {},
        onToggleSubtitleMenu: () {},
        onToggleSubSync: () {},
        onToggleFullscreen: () {},
      ),
    ),
  ),
);

void main() {
  for (final width in [800.0, 1100.0, 1279.0, 1280.0, 1456.0, 1920.0]) {
    testWidgets('every control fits at $width dp', (tester) async {
      tester.view.physicalSize = Size(width, 820);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_bar());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a wide window names the menus in words', (tester) async {
    tester.view.physicalSize = const Size(1456, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_bar());
    expect(find.text('Quality · 1080p'), findsOneWidget);
    expect(find.text('Speed 1.25x'), findsOneWidget);
    expect(find.text('Subtitles · English'), findsOneWidget);
    expect(find.text('Source · 1080p'), findsOneWidget);
  });
}
