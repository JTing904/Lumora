import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/widgets/player/player_playback_rules.dart';

void main() {
  group('AttemptToken', () {
    test('the attempt in flight is current', () {
      final token = AttemptToken();
      final ticket = token.begin();
      expect(token.isCurrent(ticket), isTrue);
      expect(token.current, ticket);
    });

    test('a replaced attempt is stale, so its late answer is dropped', () {
      final token = AttemptToken();
      final first = token.begin();
      final second = token.begin();
      expect(token.isCurrent(first), isFalse);
      expect(token.isCurrent(second), isTrue);
    });

    test('work that shares the attempt goes stale with it', () {
      // A reopen on mpv rides the open's ticket rather than taking its own,
      // and a source change while it is in flight makes both stale.
      final token = AttemptToken();
      token.begin();
      final reopen = token.current;
      expect(token.isCurrent(reopen), isTrue);
      token.begin();
      expect(token.isCurrent(reopen), isFalse);
    });
  });

  group('recoveryResumeAt', () {
    const resume = Duration(minutes: 12);

    test('a source that never played keeps the resume point', () {
      expect(
        recoveryResumeAt(
          carried: resume,
          showedPicture: false,
          openedAt: resume,
          live: resume,
        ),
        resume,
      );
    });

    test('a source that died mid-film continues from where it stopped', () {
      expect(
        recoveryResumeAt(
          carried: resume,
          showedPicture: true,
          openedAt: resume,
          live: const Duration(minutes: 34),
        ),
        const Duration(minutes: 34),
      );
    });

    test('a picture that never moved past the open is not progress', () {
      expect(
        recoveryResumeAt(
          carried: resume,
          showedPicture: true,
          openedAt: resume,
          live: resume,
        ),
        resume,
      );
    });

    test('the place a played source reached outlives a dead successor', () {
      // The next source opened at 34 min and died before its first frame:
      // the chain must not fall back to the 12 min it started with.
      expect(
        recoveryResumeAt(
          carried: const Duration(minutes: 34),
          showedPicture: false,
          openedAt: const Duration(minutes: 34),
          live: Duration.zero,
        ),
        const Duration(minutes: 34),
      );
    });

    test('a play with no resume point gains one once a source has played', () {
      expect(
        recoveryResumeAt(
          carried: null,
          showedPicture: true,
          openedAt: Duration.zero,
          live: const Duration(minutes: 5),
        ),
        const Duration(minutes: 5),
      );
    });
  });

  group('streamIsTheTitle', () {
    test('a 1:29 clip served for a 46 min episode is not the episode', () {
      expect(streamIsTheTitle(const Duration(seconds: 89), '46 min'), isFalse);
    });

    test('the episode itself is', () {
      expect(streamIsTheTitle(const Duration(minutes: 44), '46 min'), isTrue);
    });

    test('with no runtime or no length there is nothing to judge by', () {
      expect(streamIsTheTitle(const Duration(seconds: 89), null), isTrue);
      expect(streamIsTheTitle(Duration.zero, '46 min'), isTrue);
    });

    test('a short title is not judged at all', () {
      expect(streamIsTheTitle(const Duration(minutes: 2), '7 min'), isTrue);
    });
  });

  group('StateEdge', () {
    test('a state repeated by every tick is reported once', () {
      final edge = StateEdge<String>();
      expect(edge.entered('ready'), isTrue);
      expect(edge.entered('ended'), isTrue);
      expect(edge.entered('ended'), isFalse);
      expect(edge.entered('ended'), isFalse);
    });

    test('leaving and coming back counts again', () {
      // Seeking back from the end and playing to it a second time ends the
      // stream a second time.
      final edge = StateEdge<String>();
      edge.entered('ended');
      edge.entered('ready');
      expect(edge.entered('ended'), isTrue);
    });

    test('a new stream starts with nothing reported', () {
      final edge = StateEdge<String>();
      edge.entered('ended');
      edge.reset();
      expect(edge.entered('ended'), isTrue);
    });
  });

  group('FullscreenCarry', () {
    test('a player opened windowed leaves full screen when left', () {
      final carry = FullscreenCarry();
      final before = carry.enter(isFullscreen: false);
      expect(
        carry.leave(
          wasFullscreenBefore: before,
          handingOver: false,
          isFullscreen: true,
        ),
        isTrue,
      );
    });

    test('the next episode keeps full screen', () {
      final carry = FullscreenCarry();
      final before = carry.enter(isFullscreen: false);
      expect(
        carry.leave(
          wasFullscreenBefore: before,
          handingOver: true,
          isFullscreen: true,
        ),
        isFalse,
      );
      // The next episode opens in full screen, and leaving it still returns
      // the window to how it was before the first episode.
      final next = carry.enter(isFullscreen: true);
      expect(next, isFalse);
      expect(
        carry.leave(
          wasFullscreenBefore: next,
          handingOver: false,
          isFullscreen: true,
        ),
        isTrue,
      );
    });

    test("full screen that was the viewer's before stays theirs", () {
      final carry = FullscreenCarry();
      final before = carry.enter(isFullscreen: true);
      expect(before, isTrue);
      expect(
        carry.leave(
          wasFullscreenBefore: before,
          handingOver: false,
          isFullscreen: true,
        ),
        isFalse,
      );
    });

    test('a hand-over is read once', () {
      final carry = FullscreenCarry();
      carry.leave(
        wasFullscreenBefore: false,
        handingOver: true,
        isFullscreen: true,
      );
      carry.enter(isFullscreen: true);
      // A later, unrelated player opened in full screen owns it again.
      expect(carry.enter(isFullscreen: true), isTrue);
    });
  });
}
