/// Music and Audiobooks in the Lumora look lay out without overflow at a
/// phone's width, a desktop window and a television's 960x540.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/models/audiobook/audiobook_model.dart';
import 'package:zplay/pages/audiobooks/audiobook_detail_page.dart';
import 'package:zplay/pages/audiobooks/audiobooks_page.dart';
import 'package:zplay/pages/music/lu_media_kit.dart';
import 'package:zplay/pages/music/music_page.dart';
import 'package:zplay/services/config/service_credentials.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in const [Size(360, 740), Size(1280, 800), Size(960, 540)]) {
    testWidgets('Music lays out at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: MusicPage()));
      await tester.pump();

      expect(find.byType(LuPillTabs<MusicView>), findsOneWidget);
      for (final view in MusicView.values) {
        await tester.ensureVisible(find.text(view.label).first);
        await tester.pump();
        await tester.tap(find.text(view.label).first);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(360, 740), Size(1280, 800), Size(960, 540)]) {
    testWidgets('Audiobooks lay out at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // The genre pills belong to the online catalogue, which needs its
      // credential; the build without one is covered on its own.
      ServiceCredentials.buildTimeOverridesForTesting[ServiceCredential
              .audiobookService] =
          'test-key';
      addTearDown(ServiceCredentials.buildTimeOverridesForTesting.clear);

      await tester.pumpWidget(const MaterialApp(home: AudiobooksPage()));
      await tester.pump();
      expect(find.byType(LuPillTabs<String>), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: AudiobookDetailPage(
            audiobook: Audiobook(
              uuid: 'u',
              audioBookId: 'a',
              dynamicSlugId: 'd',
              title: 'A Book',
              author: 'An Author',
              coverImage: '',
              source: 'Archive',
              pageUrl: 'https://example.invalid',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('A Book'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
