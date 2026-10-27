import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/pages/anime/anime_search_page.dart';
import 'package:zplay/services/content/content_settings.dart';

void main() {
  tearDown(() => ContentSettings.adultEnabled.value = false);

  testWidgets('AnimeSearchPage hides the 18+ toggle unless the admin switch is on', (tester) async {
    ContentSettings.adultEnabled.value = false;
    await tester.pumpWidget(const MaterialApp(home: AnimeSearchPage()));
    expect(find.text('18+'), findsNothing);
  });

  testWidgets('AnimeSearchPage renders custom dropdown buttons, 18+ toggle, and search input', (tester) async {
    ContentSettings.adultEnabled.value = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimeSearchPage(),
      ),
    );

    // Verify search input
    expect(find.byType(TextField), findsOneWidget);

    // Verify 18+ toggle
    expect(find.text('18+'), findsOneWidget);

    // Verify custom dropdown filter buttons
    expect(find.textContaining('Sort:'), findsOneWidget);
    expect(find.text('Genre'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
    expect(find.text('Season'), findsOneWidget);
    expect(find.text('Format'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
  });
}
