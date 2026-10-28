/// Music's overlays own the remote's Back while they are up.
///
/// Android delivers Back to the shell's root guard, not to the page's key
/// handler, so a page that only listened for Escape let one press skip every
/// overlay and leave Music altogether. The page now claims the press through
/// `AppShellController.claimBack` while an overlay is open, and only while its
/// slot is the one on screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zplay/pages/music/lu_media_kit.dart';
import 'package:zplay/pages/music/music_page.dart';
import 'package:zplay/services/layout/form_factor.dart';
import 'package:zplay/shell/app_shell_scope.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late ValueNotifier<ShellSlot> slot;

  AppShellController newShell() {
    slot = ValueNotifier(ShellSlot.browse);
    return AppShellController(
      current: slot,
      onSelect: (next) {
        slot.value = next;
        return true;
      },
      formFactor: () => FormFactor.television,
    );
  }

  Future<void> mount(WidgetTester tester, AppShellController shell) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScope(controller: shell, child: const MusicPage()),
      ),
    );
    await tester.pump();
  }

  /// The shortcuts sheet is the one overlay that needs neither a track nor
  /// a network fetch, so it stands in for all of them.
  Finder shortcutsTitle() => find.text('Keyboard Shortcuts');

  FocusNode pill(WidgetTester tester, String label) {
    final text = find.descendant(
      of: find.byType(LuPillTabs<MusicView>),
      matching: find.text(label),
    );
    return Focus.of(tester.element(text));
  }

  testWidgets('Back closes the open overlay instead of leaving Music', (
    tester,
  ) async {
    final shell = newShell();
    await mount(tester, shell);
    expect(shell.hasBackClaim, isFalse, reason: 'nothing open, nothing held');

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();
    expect(shortcutsTitle(), findsOneWidget);
    expect(shell.hasBackClaim, isTrue);

    // The shell's guard runs the claim instead of its go-Home policy.
    expect(shell.consumeBackClaim(), isTrue);
    await tester.pump();
    expect(shortcutsTitle(), findsNothing);
    expect(
      shell.hasBackClaim,
      isFalse,
      reason: 'with nothing left open the next press is the shell\'s again',
    );
    expect(slot.value, ShellSlot.browse);
  });

  testWidgets('focus returns to the control that opened the overlay', (
    tester,
  ) async {
    final shell = newShell();
    await mount(tester, shell);

    final library = pill(tester, MusicView.library.label);
    library.requestFocus();
    await tester.pump();
    expect(library.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();
    expect(shortcutsTitle(), findsOneWidget);
    expect(
      library.hasFocus,
      isFalse,
      reason: 'the page under an overlay is out of the remote\'s reach',
    );

    shell.consumeBackClaim();
    await tester.pump();
    await tester.pump();
    expect(library.hasFocus, isTrue);
  });

  testWidgets('no claim is held while another slot is on screen', (
    tester,
  ) async {
    final shell = newShell();
    await mount(tester, shell);

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();
    expect(shell.hasBackClaim, isTrue);

    slot.value = ShellSlot.home;
    expect(
      shell.hasBackClaim,
      isFalse,
      reason: 'a hidden page must not eat the press of the page on screen',
    );

    slot.value = ShellSlot.browse;
    expect(shell.hasBackClaim, isTrue);
  });

  testWidgets('Escape unwinds the same way and the claim dies with the page', (
    tester,
  ) async {
    final shell = newShell();
    await mount(tester, shell);

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(shortcutsTitle(), findsNothing);
    expect(shell.hasBackClaim, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();
    expect(shell.hasBackClaim, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(shell.hasBackClaim, isFalse);
  });
}
