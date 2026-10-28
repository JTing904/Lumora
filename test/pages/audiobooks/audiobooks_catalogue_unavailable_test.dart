/// A build without the audiobook catalogue credential explains itself and
/// points at the studio, instead of a search that always comes back empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/pages/audiobooks/audiobooks_page.dart';
import 'package:zplay/pages/music/lu_media_kit.dart';
import 'package:zplay/services/config/service_credentials.dart';
import 'package:zplay/ui/lu_button.dart';

const _catalogue = [
  ServiceCredential.audiobookSearch,
  ServiceCredential.audiobookService,
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(ServiceCredentials.buildTimeOverridesForTesting.clear);

  for (final size in const [Size(360, 740), Size(411, 860), Size(960, 540)]) {
    testWidgets('no credential: explains the missing catalogue at '
        '${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final credential in _catalogue) {
        ServiceCredentials.buildTimeOverridesForTesting[credential] = '';
      }

      await tester.pumpWidget(const MaterialApp(home: AudiobooksPage()));
      await tester.pump();

      expect(
        find.text(
          "The online audiobook catalogue isn't available in this build",
        ),
        findsOneWidget,
      );
      final studio = find.widgetWithText(LuButton, 'Open Studio');
      expect(studio, findsOneWidget);
      expect(tester.widget<LuButton>(studio).onPressed, isNotNull);

      // Nothing that promises catalogue results.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(LuPillTabs<String>), findsNothing);
      expect(find.textContaining('No audiobooks found'), findsNothing);
      expect(find.text('Featured Audiobooks'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('with a credential the search and genres are offered', (
    tester,
  ) async {
    ServiceCredentials.buildTimeOverridesForTesting[ServiceCredential
            .audiobookService] =
        'test-key';

    await tester.pumpWidget(const MaterialApp(home: AudiobooksPage()));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(LuPillTabs<String>), findsOneWidget);
    expect(
      find.text("The online audiobook catalogue isn't available in this build"),
      findsNothing,
    );
  });
}
