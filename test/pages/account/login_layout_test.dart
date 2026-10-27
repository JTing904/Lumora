import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/pages/account/login_page.dart';
import 'package:zplay/pages/account/splash_page.dart';
import 'package:zplay/ui/figure_turntable.dart';

void main() {
  for (final size in const [
    Size(1440, 900),
    Size(1920, 1080),
    Size(390, 844),
    Size(960, 540),
  ]) {
    testWidgets('the sign-in page fits ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage(figure: LuFigure.grey)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byType(FigureTurntable), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);

      await tester.ensureVisible(find.text('Sign up with an invite code'));
      await tester.pump();
      await tester.tap(find.text('Sign up with an invite code'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.text('Invite code'), findsOneWidget);
    });
  }

  testWidgets('the figure can be changed', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: LoginPage(figure: LuFigure.grey)),
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Show 米色'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.widget<FigureTurntable>(find.byType(FigureTurntable).last).figure,
      LuFigure.beige,
    );
  });

  testWidgets('the splash hands over when its time is up', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(
          duration: const Duration(milliseconds: 800),
          onDone: () => done = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 500));
    expect(done, isTrue);
  });
}
