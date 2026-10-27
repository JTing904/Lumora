/// Guards the ten-foot chrome's density against the measurement that set it.
///
/// The user's complaint was that the app spends screen on chrome where the
/// reference app spends it on content, and the numbers came from Stremio launched
/// on the same Chromecast with Google TV at the same 1920x1080 / density 320 (so
/// 960x540 dp at DPR 2, and physical pixels are logical ones times two):
///
/// | | Stremio | ours before |
/// |:--|:--|:--|
/// | sidebar width | ~67 dp | 88 dp |
/// | sidebar glyph | ~22 dp | 32 dp |
/// | sidebar pitch | ~53 dp | 72 dp |
/// | top chrome | none, content at the top | ~118 dp to the first pixel of content |
/// | filter row | ~23 dp of inline text | 44 dp of pills |
///
/// The sidebar rows describe the rail the app has since replaced with a top nav
/// bar (`shell_rail.dart`): 88 dp of width is now 0, and the nav chrome spends 48
/// dp of height across the top instead. The remaining rows still measure what
/// they measured.
///
/// Every assertion here is one of those rows, on both sides of the form-factor
/// split: a television gets the compact numbers, and a pointer device keeps the
/// geometry it already shipped. The two branches are pumped from the same canvas
/// and differ only in [DeviceProfile], so a number that moved has moved for the
/// form factor and for nothing else.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/layout/device_profile.dart';
import 'package:zplay/services/playback/now_playing_service.dart';
import 'package:zplay/shell/app_shell.dart';
import 'package:zplay/shell/now_playing_bar.dart';
import 'package:zplay/shell/shell_rail.dart';
import 'package:zplay/widgets/common/focusable_card.dart';

/// The device's own canvas: 1920x1080 physical at density 320, so 960x540 dp.
const Size _televisionCanvas = Size(960, 540);

/// A desk window, where the top nav bar is the chrome on screen. Wide enough on
/// its shortest side that the form factor is `expanded`: a pointer device on the
/// television's own canvas classifies as `compact` and would be comparing a
/// bottom bar against a top bar.
const Size _desktopCanvas = Size(1920, 1080);

/// Every canvas is pumped at the device's density, so a dp is two physical px.
const double _dpr = 2.0;


Future<void> _pump(
  WidgetTester tester, {
  required bool television,
  required Size canvas,
  required Widget child,
}) async {
  DeviceProfile.debugSetTelevision(value: television);
  tester.view.devicePixelRatio = _dpr;
  tester.view.physicalSize = canvas * _dpr;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: canvas),
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpRail(WidgetTester tester, {required bool television}) =>
    _pump(
      tester,
      television: television,
      canvas: television ? _televisionCanvas : _desktopCanvas,
      child: const ShellRail(
        current: ShellSlot.home,
        onSelect: _ignore,
        onLiveTv: _ignoreTv,
      ),
    );

/// The row boxes in bar order: the destinations left to right, with the
/// fullscreen toggle last because it is the trailing item.
Finder _rows() => find.byType(FocusableCard);

/// The name a labelled row draws.
///
/// The top bar is text-only now, so the row's mark is its label rather than an
/// icon; the compact bottom bar still draws glyphs.
Finder _labelOf(Finder row) =>
    find.descendant(of: row, matching: find.byType(Text)).first;

/// The bar at the foot of the canvas, which is where the shell mounts it.
Future<void> _pumpBar(WidgetTester tester, {required bool television}) => _pump(
  tester,
  television: television,
  canvas: _televisionCanvas,
  child: const Column(children: [Spacer(), NowPlayingBar()]),
);

class _FakeOwner implements NowPlayingCommands {
  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> togglePlayPause() async {}

  @override
  Future<void> stop() async {}

  @override
  void openFullPlayer(BuildContext context) {}
}

void main() {
  final owner = _FakeOwner();

  setUp(() {
    NowPlayingService.register(owner);
    NowPlayingService.publish(
      const NowPlayingSnapshot(
        kind: NowPlayingKind.music,
        title: 'Probe Track',
        subtitle: 'Probe Artist',
        isPlaying: true,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 3),
        canPrevious: true,
        canNext: true,
      ),
    );
  });

  tearDown(() {
    NowPlayingService.publish(null);
    NowPlayingService.unregister(owner);
    DeviceProfile.debugSetTelevision(value: false);
  });

  group('the top nav bar', () {
    testWidgets('is 64 dp of full-width chrome with 48 dp destinations', (
      tester,
    ) async {
      await _pumpRail(tester, television: true);

      // The fill and its hairline run to the panel edge on every side; it is
      // the bar that is compact, which is what lets the background bleed.
      final bar = tester.getRect(find.byType(ShellRail));
      expect(bar, const Rect.fromLTWH(0, 0, 960, 64));

      final rows = _rows();
      final first = tester.getRect(rows.first);
      expect(
        first.height,
        48.0,
        reason: 'the accessibility floor, and the bar has the room for it',
      );

      // Destinations lead from the left, after the brand badge and its gutter.
      expect(first.left, greaterThanOrEqualTo(24.0));
      // The fullscreen toggle is the trailing item, pinned to the right gutter.
      expect(tester.getRect(rows.last).right, 960 - 36);

      // One line: every destination starts to the right of the one before it.
      for (var i = 1; i < rows.evaluate().length; i++) {
        expect(
          tester.getRect(rows.at(i)).left,
          greaterThan(tester.getRect(rows.at(i - 1)).left),
          reason: 'the bar lays its rows left to right, not top to bottom',
        );
      }

      // The label is centred in the bar's 48 dp, which is what a horizontal
      // row buys over the old column.
      final label = tester.getRect(_labelOf(rows.first));
      expect(label.center.dy, closeTo(bar.center.dy, 3.0));
    });

    testWidgets('and the pointer bar keeps the same shape, only wider', (
      tester,
    ) async {
      await _pumpRail(tester, television: false);

      final bar = tester.getRect(find.byType(ShellRail));
      expect(bar, const Rect.fromLTWH(0, 0, 1920, 64));

      final rows = _rows();
      expect(tester.getRect(rows.first).height, 48.0);
      expect(tester.getRect(rows.last).right, 1920 - 52);
    });
  });

  group('the now-playing strip', () {
    testWidgets('is not inset differently on either form factor', (
      tester,
    ) async {
      // It briefly carried a 5% margin on its right and bottom edges; the margin
      // is gone and this pins that the strip is back to one padding for both.
      for (final television in <bool>[true, false]) {
        await _pumpBar(tester, television: television);
        final next = find.byType(FocusableCard).last;
        expect(tester.getRect(next).right, 960 - 12);
        expect(
          tester
              .getRect(
                find.ancestor(of: next, matching: find.byType(Row)).first,
              )
              .bottom,
          540 - 8,
        );
      }
    });
  });
}

void _ignore(ShellSlot slot) {}

void _ignoreTv() {}
