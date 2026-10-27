/// Guards the shell's top navigation bar on the form factors that use it.
///
/// The bar replaced the left rail (see `shell_rail.dart`): tablet, desktop and
/// television get a horizontal bar pinned to the top of the window, and the
/// phone keeps the bottom bar the prototype also shows. What has to survive is
/// that the bar is a real layout child - full width, a fixed 48 dp of content,
/// flush with the top edge - because that is what lets no page pad to clear it.
///
/// Measured on the device's own canvas. A Chromecast with Google TV reports
/// 1920x1080 at density 320, so Flutter divides by 2.0 and the canvas is
/// 960x540 dp - which is also below the 600 dp phone breakpoint, which is why
/// the television is classified by [DeviceProfile] and never by width.
library;

import 'package:flutter/material.dart';
import 'package:zplay/ui/lu_logo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/layout/device_profile.dart';
import 'package:zplay/shell/app_shell.dart';
import 'package:zplay/shell/shell_rail.dart';

void _noop(ShellSlot slot) {}

void _noopTv() {}

/// Pumps the bar on the television canvas.
///
/// The size is the one the device reports: 1920x1080 at density 320 is 960x540
/// dp. It is bound through `tester.view`, which the framework resets between
/// tests; wrapping a `MediaQuery` around `MaterialApp` instead does nothing,
/// because `MaterialApp` builds its own from the view and discards an outer one,
/// so the bar reads the harness default of 800x600 and a test written against a
/// television silently measures a desktop.
Future<void> _pump(WidgetTester tester, {required bool television}) async {
  tester.view.physicalSize = const Size(960, 540);
  tester.view.devicePixelRatio = 1.0;

  DeviceProfile.debugSetTelevision(value: television);
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: ShellRail(
          current: ShellSlot.home,
          onSelect: _noop,
          onLiveTv: _noopTv,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Pumps the bar on an arbitrary canvas, with the form factor coming from width.
Future<void> _pumpOn(
  WidgetTester tester, {
  required Size canvas,
  required bool television,
}) async {
  tester.view.physicalSize = canvas;
  tester.view.devicePixelRatio = 1.0;
  DeviceProfile.debugSetTelevision(value: television);
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: ShellRail(
          current: ShellSlot.home,
          onSelect: _noop,
          onLiveTv: _noopTv,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(() => DeviceProfile.debugSetTelevision(value: false));

  testWidgets('the bar is a full-width row pinned to the top', (tester) async {
    await _pump(tester, television: true);

    final bar = tester.getRect(find.byType(ShellRail));
    expect(
      bar,
      const Rect.fromLTWH(0, 0, 960, 64),
      reason:
          'full width, 48 dp of content, flush with the window top - which '
          'is what makes it a layout child rather than an overlay',
    );
  });

  testWidgets('and a desktop gets the same bar, not a rail', (tester) async {
    // A desk window is classified by width, so this is `expanded`. Measured at
    // 1920x1080 so the shortest side is over the 1024 breakpoint and this is not
    // silently a bottom bar.
    await _pumpOn(tester, canvas: const Size(1920, 1080), television: false);

    final bar = tester.getRect(find.byType(ShellRail));
    expect(bar, const Rect.fromLTWH(0, 0, 1920, 64));
  });

  testWidgets('the bar labels every destination', (tester) async {
    await _pump(tester, television: true);

    // The old 64 dp side rail was icons only because a quarter of a 960 dp
    // canvas is too much to spend on names. A horizontal bar has the width for
    // them, and the name is now the only mark: the glyph beside it repeated the
    // destination and competed with the underline that shows selection.
    for (final label in ['Home', 'Series', 'Movies', 'Anime', 'Live TV', 'My List']) {
      expect(find.text(label), findsWidgets, reason: '"$label" must be drawn');
    }
    expect(
      find.text('Live TV'),
      findsWidgets,
      reason: 'the prototype top bar carries the Live TV destination',
    );
    // The mark is drawn, not loaded: `ZplayLogo` paints a rounded square and a
    // glyph out of `tokens.accent`, so it cannot fall behind the palette the way
    // the old raster did. Asserting the widget rather than an `Image` is the
    // point - an asset here would have silently kept the previous accent.
    expect(
      find.byType(LuLogo),
      findsWidgets,
      reason: 'the mark is the brand anchor at this width',
    );
    // Destinations are names; the only glyphs are the two tools at the
    // trailing end, search and 我的, as in the mockup.
    final icons = tester
        .widgetList<Icon>(
          find.descendant(
            of: find.byType(ShellRail),
            matching: find.byType(Icon),
          ),
        )
        .map((i) => i.icon)
        .toSet();
    expect(icons, containsAll({Icons.search_rounded, Icons.person_rounded}));
  });

  testWidgets('the bar still names every row for a screen reader', (
    tester,
  ) async {
    await _pump(tester, television: true);
    final handle = tester.ensureSemantics();

    for (final label in [
      ...const ['Home', 'Series', 'Movies', 'Anime', 'Live TV', 'My List'],
      // Search and Me are glyphs in the bar, named for a screen reader.
      'Search',
      'Me',
    ]) {
      expect(
        find.bySemanticsLabel(label),
        findsWidgets,
        reason: '"$label" must survive as semantics as well as pixels',
      );
    }
    handle.dispose();
  });

  testWidgets('and the phone still gets its bottom bar, not the top one', (
    tester,
  ) async {
    // 390x844 is a phone: shortest side below 600, so `compact`. The bar must be
    // at the FOOT and 64 dp tall, which is the geometry the prototype hides the
    // top navbar behind. Laid out in a column the way the shell places it, so
    // the measurement is the bar's position and not the harness's alignment.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    DeviceProfile.debugSetTelevision(value: false);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              Spacer(),
              ShellRail(
                current: ShellSlot.home,
                onSelect: _noop,
                onLiveTv: _noopTv,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final bar = tester.getRect(find.byType(ShellRail));
    expect(bar.height, 64);
    expect(bar.top, 844 - 64, reason: 'the bottom bar is pinned to the foot');
    // The phone mockup's bar: each glyph with its name under it, short enough
    // that five fit across one phone, and each drawn whole.
    for (final label in ['Home', 'Search', 'My List', 'Downloads', 'Me']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    expect(
      find.byType(LuLogo),
      findsNothing,
      reason: 'the brand anchor belongs to the top bar',
    );
  });
}
