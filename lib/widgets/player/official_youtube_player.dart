/// Full-screen playback of an official upload, in YouTube's own embedded
/// player.
///
/// The video is never extracted: the page is YouTube's IFrame player inside a
/// webview, the same arrangement the trailer modal uses (`trailer_modal.dart`)
/// - a tiny local wrapper document loaded onto an https origin, because the
/// embed refuses a request with no referrer. Android gets the origin from
/// `loadHtmlString`'s `baseUrl`; WebView2 from a virtual host mapping.
///
/// **Remote and keyboard.** Flutter keeps focus on the stage, not the webview,
/// so a remote drives the player through the IFrame API: Select / Enter /
/// Space / Play-Pause toggles playback, Left / Right seek ten seconds, Up
/// reaches the Back control, and Back / Escape leave. Pointer users get
/// YouTube's own controls inside the frame.
///
/// **Failures.** YouTube's own error codes (100 gone, 101/150 not embeddable,
/// 152/153 blocked) are read back from the page and shown as one localized
/// message; there is no way out to YouTube, because Lumora does not send
/// viewers to a website to watch.
///
/// **Progress.** The page reports the IFrame API's state, `getCurrentTime()`
/// and `getDuration()`; [OfficialProgressTracker] turns that into saves on
/// pause, every 15 s while playing, at the end and on close, through
/// `ContinueWatchingService.saveProgress` - the stream player's own call, so
/// Continue Watching and the details page's watched marks (90%) follow. A
/// reopened episode starts where it was left unless it was finished. A
/// multi-episode compilation records nothing.
///
/// **一起看.** A room works here as in the stream player: the host's
/// position goes out every 2 s, and a play, pause or jump made in YouTube's
/// own controls is read off the page's reports (a state change, or a time
/// that is not where playing on would have put it) and sent to the room.
/// The room's moves come back through the IFrame API's playVideo,
/// pauseVideo and seekTo. The embed offers no fine speed steps, so a viewer
/// who drifts past 1 s jumps back into step instead of easing.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_windows/webview_flutter_windows.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../pages/party/join_party.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/movie/video.dart';
import '../../models/stream/stream_model.dart';
import '../../services/continue_watching/continue_watching_service.dart';
import '../../services/official/official_progress.dart';
import '../../services/party/watch_party_service.dart';
import '../../services/official/official_source_loader.dart';
import '../../services/theme/design_tokens.dart';
import '../common/focusable_card.dart';
import '../common/webview_environment.dart';
import '../party/watch_party_ui.dart';

class OfficialYouTubePlayer extends StatefulWidget {
  const OfficialYouTubePlayer({
    super.key,
    required this.videoId,
    required this.title,
    this.channelName,
    this.detail,
    this.episode,
    this.source,
    this.initialPosition,
  });

  /// An eleven-character YouTube video id.
  final String videoId;

  /// What is playing (the show and episode), for the top bar.
  final String title;

  /// The rights holder's channel, named under the title.
  final String? channelName;

  /// The title, episode and row being watched. With all of them, progress is
  /// written to Continue Watching and the episode is marked watched at 90%,
  /// exactly as the stream player does; without, nothing is recorded.
  final MovieDetail? detail;
  final Video? episode;
  final StreamSource? source;

  /// Where a resume asked to start; otherwise the saved position is used.
  final Duration? initialPosition;

  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Pushes the player. Does nothing for an id that is not a video id.
  static Future<void> open(
    BuildContext context, {
    required String videoId,
    required String title,
    String? channelName,
    MovieDetail? detail,
    Video? episode,
    StreamSource? source,
    Duration? initialPosition,
  }) async {
    if (!_idPattern.hasMatch(videoId)) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfficialYouTubePlayer(
          videoId: videoId,
          title: title,
          channelName: channelName,
          detail: detail,
          episode: episode,
          source: source,
          initialPosition: initialPosition,
        ),
      ),
    );
  }

  static const String host = 'official-embed.lumora.local';
  static const String origin = 'https://$host';
  static const String wrapperFile = 'index.html';

  /// The page-to-app channel name (Android `JavaScriptChannel`).
  static const String progressChannel = 'LumoraProgress';

  /// The wrapper document. [videoId] must already be a validated id; it is
  /// still JSON-encoded into the script so no character of it can be code.
  /// [startSeconds] resumes the video there.
  ///
  /// The page reports `{state, time, duration, error}` on every state change
  /// and every 5 seconds: to the Android channel when it exists, to WebView2's
  /// `chrome.webview` when that exists, and always into `lumoraState`, which
  /// the app also polls - so a platform whose channel stays silent still gets
  /// its progress.
  @visibleForTesting
  static String wrapperHtml(String videoId, {int? startSeconds}) {
    final id = jsonEncode(videoId).replaceAll('</', r'<\/');
    final start = (startSeconds != null && startSeconds > 0)
        ? 'start: ${startSeconds.toInt()},'
        : '';
    return '''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="referrer" content="strict-origin-when-cross-origin">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Player</title>
<style>
html,body{margin:0;padding:0;height:100%;background:#000;overflow:hidden}
#player,iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
</style>
</head>
<body>
<div id="player"></div>
<script>
(function () {
  var videoId = $id;
  var player = null;
  window.lumoraState = {
    ready: false, state: -1, error: 0, time: null, duration: null
  };
  function refresh() {
    try {
      if (!player || !player.getCurrentTime) return;
      window.lumoraState.time = player.getCurrentTime();
      var d = player.getDuration();
      if (d > 0) window.lumoraState.duration = d;
    } catch (x) {}
  }
  function report() {
    refresh();
    var msg = JSON.stringify(window.lumoraState);
    try {
      if (window.$progressChannel && window.$progressChannel.postMessage) {
        window.$progressChannel.postMessage(msg);
      }
    } catch (x) {}
    try {
      if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage(msg);
      }
    } catch (x) {}
  }
  function create() {
    if (player || !window.YT || !window.YT.Player) return;
    try {
      player = new YT.Player('player', {
        host: 'https://www.youtube-nocookie.com',
        videoId: videoId,
        width: '100%',
        height: '100%',
        playerVars: {
          autoplay: 1, playsinline: 1, rel: 0, fs: 1, controls: 1, $start
          enablejsapi: 1, origin: window.location.origin
        },
        events: {
          onReady: function (e) {
            window.lumoraState.ready = true;
            try { e.target.playVideo(); } catch (x) {}
            report();
          },
          onStateChange: function (e) {
            window.lumoraState.state = e.data;
            report();
          },
          onError: function (e) {
            window.lumoraState.error = e.data || 1;
            report();
          }
        }
      });
    } catch (x) { window.lumoraState.error = 1; }
  }
  setInterval(report, 5000);
  window.onYouTubeIframeAPIReady = create;
  window.lumoraToggle = function () {
    if (!player || !player.getPlayerState) return;
    if (player.getPlayerState() === 1) { player.pauseVideo(); }
    else { player.playVideo(); }
  };
  window.lumoraPlay = function () { if (player) player.playVideo(); };
  window.lumoraPause = function () { if (player) player.pauseVideo(); };
  window.lumoraSeekTo = function (t) {
    if (player && player.seekTo) player.seekTo(Math.max(0, t), true);
  };
  window.lumoraSeek = function (delta) {
    if (!player || !player.getCurrentTime) return;
    player.seekTo(Math.max(0, player.getCurrentTime() + delta), true);
  };
  window.lumoraStatus = function () {
    refresh();
    return JSON.stringify(window.lumoraState);
  };
  var tag = document.createElement('script');
  tag.src = 'https://www.youtube.com/iframe_api';
  tag.onerror = function () { window.lumoraState.error = 1; };
  document.head.appendChild(tag);
  // The API calls onYouTubeIframeAPIReady; YT.ready is the fallback queue.
  var tries = 0;
  var timer = setInterval(function () {
    tries++;
    try {
      if (window.YT && window.YT.ready) { window.YT.ready(create); }
    } catch (x) {}
    if (player || tries > 100) clearInterval(timer);
  }, 100);
})();
</script>
</body>
</html>
''';
  }

  @override
  State<OfficialYouTubePlayer> createState() => _OfficialYouTubePlayerState();
}

class _OfficialYouTubePlayerState extends State<OfficialYouTubePlayer> {
  final FocusNode _stageNode = FocusNode(debugLabel: 'OfficialYouTubeStage');
  final FocusNode _backNode = FocusNode(debugLabel: 'OfficialYouTubeBack');

  Widget? _embed;
  WebviewController? _windows;
  WebViewController? _federated;
  StreamSubscription<dynamic>? _windowsMessages;
  bool _failed = false;
  Timer? _statusTimer;

  late final OfficialProgressTracker _tracker;

  /// Where the video starts (a resume), in seconds; null from the start.
  int? _startSeconds;

  // -- 一起看 --
  StreamSubscription<PartyPlayback>? _partySub;
  Timer? _partyHeartbeat;
  bool _showPartyChat = false;
  bool _partyHandingOver = false;
  bool _partyWasGuest = false;

  /// The page's last report: its IFrame state, time and when it came.
  int _ytState = -1;
  double? _ytTime;
  DateTime _ytAt = DateTime.now();
  bool _ytPlaying = false;

  /// The last report that was playing or paused (not buffering), or where
  /// the room last put the video: what a jump is measured against.
  double? _refTime;
  DateTime _refAt = DateTime.now();
  bool _refPlaying = false;

  /// Until then, a change on the page is the room's own move landing (or
  /// the video still opening), not the viewer's, and is not sent back.
  DateTime? _partyQuietUntil;
  DateTime? _lastPartySeek;

  @override
  void initState() {
    super.initState();
    final detail = widget.detail;
    final source = widget.source;
    // A compilation records nothing; see OfficialProgressTracker.
    final tracks =
        detail != null &&
        source != null &&
        !OfficialSourceLoader.isCompilation(source);
    _tracker = OfficialProgressTracker(
      enabled: tracks,
      onSave: (pos, dur) => ContinueWatchingService.saveProgress(
        detail: detail!,
        episode: widget.episode,
        source: source!,
        positionSeconds: pos,
        totalDurationSeconds: dur,
      ),
    );
    if (tracks) {
      _startSeconds = OfficialProgressTracker.resumeSeconds(
        explicit: widget.initialPosition,
        saved: OfficialProgressTracker.savedFor(
          ContinueWatchingService.activeItems.value,
          showId: detail.id,
          season: widget.episode?.season,
          episode: widget.episode?.episode,
          streamTitle: source.title ?? source.displayTitle,
          officialAddonNames: OfficialSourceLoader.officialAddonNames,
        ),
      );
    }
    _mount();
    _startParty();
  }

  @override
  void dispose() {
    _stopParty(leaveRoom: !_partyHandingOver);
    // Where the viewer stopped, from the last report (at most 1.5 s old).
    _tracker.close();
    _windowsMessages?.cancel();
    _statusTimer?.cancel();
    _windows?.dispose();
    _stageNode.dispose();
    _backNode.dispose();
    super.dispose();
  }

  Future<void> _mount() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        await _mountWebView2();
      } else {
        await _mountFederated();
      }
      _statusTimer = Timer.periodic(
        const Duration(milliseconds: 1500),
        (_) => _pollStatus(),
      );
    } catch (error) {
      debugPrint('[OfficialYouTubePlayer] embed failed: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _mountWebView2() async {
    if (await WebviewController.getWebViewVersion() == null) {
      throw StateError('no WebView2 runtime');
    }
    await WebviewEnvironment.ensureAutoplayPolicy();
    final controller = WebviewController();
    await controller.initialize();
    await controller.setBackgroundColor(Colors.black);
    // Links inside the embed ("Watch on YouTube", the logo) would open a
    // browser window; this is a player, not a way out to the site.
    await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'official_embed'),
    );
    await dir.create(recursive: true);
    await File(
      p.join(dir.path, OfficialYouTubePlayer.wrapperFile),
    ).writeAsString(
      OfficialYouTubePlayer.wrapperHtml(
        widget.videoId,
        startSeconds: _startSeconds,
      ),
    );
    // The page's `chrome.webview.postMessage` reports.
    _windowsMessages = controller.webMessage.listen(
      _onPageReport,
      onError: (_) {},
    );
    await controller.addVirtualHostNameMapping(
      OfficialYouTubePlayer.host,
      dir.path,
      WebviewHostResourceAccessKind.allow,
    );
    await controller.loadUrl(
      '${OfficialYouTubePlayer.origin}/${OfficialYouTubePlayer.wrapperFile}',
    );
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _windows = controller;
      _embed = Webview(controller);
    });
  }

  Future<void> _mountFederated() async {
    if (WebViewPlatform.instance == null) {
      throw StateError('no webview on this platform');
    }
    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.black);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        // The wrapper and YouTube's own frames only; a tap on the embed's
        // "Watch on YouTube" must not turn the player into the website.
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          final host = uri?.host ?? '';
          final ok =
              host == OfficialYouTubePlayer.host ||
              request.url.startsWith('about:') ||
              (!request.isMainFrame &&
                  (host.endsWith('youtube.com') ||
                      host.endsWith('youtube-nocookie.com') ||
                      host.endsWith('google.com') ||
                      host.endsWith('doubleclick.net')));
          return ok ? NavigationDecision.navigate : NavigationDecision.prevent;
        },
      ),
    );
    if (controller.platform is AndroidWebViewController) {
      // A remote is not a gesture; without this the episode opens paused.
      await (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    await controller.addJavaScriptChannel(
      OfficialYouTubePlayer.progressChannel,
      onMessageReceived: (message) => _onPageReport(message.message),
    );
    await controller.loadHtmlString(
      OfficialYouTubePlayer.wrapperHtml(
        widget.videoId,
        startSeconds: _startSeconds,
      ),
      baseUrl: '${OfficialYouTubePlayer.origin}/',
    );
    if (!mounted) return;
    setState(() {
      _federated = controller;
      _embed = WebViewWidget(controller: controller);
    });
  }

  Future<void> _run(String script) async {
    try {
      if (_windows != null) {
        await _windows!.executeScript(script);
      } else if (_federated != null) {
        await _federated!.runJavaScript(script);
      }
    } catch (_) {
      // The page is not ready yet; the press is simply lost.
    }
  }

  Future<void> _pollStatus() async {
    Object? raw;
    try {
      const script = 'window.lumoraStatus ? window.lumoraStatus() : ""';
      if (_windows != null) {
        raw = await _windows!.executeScript(script);
      } else if (_federated != null) {
        raw = await _federated!.runJavaScriptReturningResult(script);
      }
    } catch (_) {
      return;
    }
    _onPageReport(raw);
  }

  /// One `lumoraState` report, from a channel message or from the poll.
  void _onPageReport(Object? raw) {
    // Android returns the string JSON-quoted, WebView2 already decoded.
    Object? decoded = raw;
    for (var i = 0; i < 2 && decoded is String && decoded.isNotEmpty; i++) {
      try {
        decoded = jsonDecode(decoded);
      } catch (_) {
        break;
      }
    }
    if (decoded is! Map) return;
    final time = decoded['time'];
    final duration = decoded['duration'];
    final state = decoded['state'];
    _tracker.sample(
      position: time is num ? time.toDouble() : null,
      duration: duration is num ? duration.toDouble() : null,
      state: state is num ? state.toInt() : null,
    );
    _partySample(
      time: time is num ? time.toDouble() : null,
      state: state is num ? state.toInt() : null,
    );
    final error = decoded['error'];
    if (error is num && error != 0 && mounted && !_failed) {
      _statusTimer?.cancel();
      setState(() => _failed = true);
    }
  }

  // -- 一起看 --

  /// What this screen is playing, as a room describes it.
  PartyMedia? get _partyMedia {
    final detail = widget.detail;
    final source = widget.source;
    if (detail == null || source == null) return null;
    final ep = widget.episode;
    return PartyMedia(
      id: detail.id,
      type: detail.type,
      title: detail.displayName,
      year: detail.year,
      poster: detail.poster,
      backdrop: detail.background,
      episodeId: ep?.id,
      season: ep?.season,
      episode: ep?.episode,
      source: source,
    );
  }

  /// Whether the room is about what this screen shows.
  bool get _partyIsHere {
    final m = WatchPartyService.instance.media.value;
    if (m == null || m.id != widget.detail?.id) return false;
    final ep = widget.episode;
    if (m.episodeId == null && ep == null) return true;
    return m.episodeId == ep?.id ||
        (m.season == ep?.season && m.episode == ep?.episode);
  }

  /// Where the video is now: the last report, run on while playing (not
  /// while buffering, when the picture stands still).
  Duration get _positionNow {
    final t = _ytTime ?? 0;
    final run = _ytPlaying && _ytState == 1
        ? DateTime.now().difference(_ytAt).inMilliseconds / 1000.0
        : 0.0;
    return Duration(milliseconds: ((t + run) * 1000).round());
  }

  void _startParty() {
    final service = WatchPartyService.instance;
    _partySub = service.playback.listen(_onPartyPlayback);
    service.room.addListener(_onPartyRoom);
    service.media.addListener(_onPartyMedia);
    _partyWasGuest = service.room.value?.isHost == false;
    _partyHeartbeat = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _partyTick(),
    );
  }

  void _stopParty({required bool leaveRoom}) {
    final service = WatchPartyService.instance;
    _partySub?.cancel();
    _partyHeartbeat?.cancel();
    service.room.removeListener(_onPartyRoom);
    service.media.removeListener(_onPartyMedia);
    if (leaveRoom && service.active) unawaited(service.leave());
  }

  void _onPartyRoom() {
    if (!mounted) return;
    final service = WatchPartyService.instance;
    final room = service.room.value;
    if (room == null && _partyWasGuest) {
      final l10n = l10nCurrent();
      switch (service.endReason) {
        case PartyEndReason.ended:
          _notice(l10n.partyEnded);
        case PartyEndReason.hostGone:
          _notice(l10n.partyHostGone);
        case PartyEndReason.dropped:
          _notice(l10n.partyDropped);
        case PartyEndReason.left:
        case null:
          break;
      }
    }
    _partyWasGuest = room?.isHost == false;
    setState(() {
      if (room == null) _showPartyChat = false;
    });
  }

  /// A guest follows the host to another episode or title.
  void _onPartyMedia() {
    final service = WatchPartyService.instance;
    final m = service.media.value;
    if (!mounted || m == null || service.room.value?.isHost != false) return;
    if (_partyIsHere || _partyHandingOver) return;
    _partyHandingOver = true;
    _notice(l10nCurrent().partyFollowEpisode);
    unawaited(openPartyPlayer(context, m, replace: true));
  }

  void _partyTick() {
    final service = WatchPartyService.instance;
    if (!mounted || service.room.value?.isHost != true || _ytTime == null) {
      return;
    }
    service.reportHostPosition(playing: _ytPlaying, position: _positionNow);
    final m = _partyMedia;
    final current = service.media.value;
    if (m != null &&
        (current == null ||
            current.source?.url != m.source?.url ||
            current.key != m.key)) {
      unawaited(service.setMedia(m, startAt: _positionNow));
    } else {
      unawaited(service.sendState());
    }
  }

  /// One page report: a play, pause or jump the viewer made in YouTube's
  /// controls goes to the room.
  void _partySample({double? time, int? state}) {
    if (time == null) return;
    final wasPlaying = _ytPlaying;
    _ytTime = time;
    _ytAt = DateTime.now();
    if (state != null) _ytState = state;
    // Buffering keeps whatever it interrupted; ended and cued are stopped.
    if (_ytState == 1) {
      _ytPlaying = true;
    } else if (_ytState == 2 || _ytState == 0 || _ytState == 5) {
      _ytPlaying = false;
    }
    final now = DateTime.now();
    // The first frames: the start-up play is not a move anyone made.
    if (_partyQuietUntil == null) {
      if (_ytPlaying) _partyQuietUntil = now.add(const Duration(seconds: 2));
      return;
    }
    final service = WatchPartyService.instance;
    if (!service.active || !_partyIsHere || now.isBefore(_partyQuietUntil!)) {
      return;
    }
    // Buffering says nothing about where the viewer wants to be.
    if (_ytState != 1 && _ytState != 2) return;
    final position = Duration(milliseconds: (time * 1000).round());
    final jumped = _isJump(time);
    _refTime = time;
    _refAt = now;
    _refPlaying = _ytState == 1;
    final toggled = _ytPlaying != wasPlaying && (state == 1 || state == 2);
    if (!jumped && !toggled) return;
    final room = service.room.value;
    if (room != null && !room.canControl) {
      // Only the host moves this room: put the viewer back where it is.
      _notice(l10nCurrent().partyNoControl);
      final pb = service.lastPlayback;
      if (pb != null) _applyRoom(pb.playing, pb.positionNow, seek: true);
      return;
    }
    unawaited(
      service.sendPlayback(
        playing: _ytPlaying,
        position: position,
        seek: jumped,
      ),
    );
  }

  /// Whether the video moved to [time] by a jump rather than by playing on.
  ///
  /// Playing from the reference can reach anywhere from the reference itself
  /// (it stalled to buffer all the time since) to where steady playing would
  /// be; only a time outside that, with some slack, was a seek.
  bool _isJump(double time) {
    final ref = _refTime;
    if (ref == null) return false;
    final ran = _refPlaying
        ? DateTime.now().difference(_refAt).inMilliseconds / 1000.0
        : 0.0;
    return time < ref - 1.5 || time > ref + ran + 2.5;
  }

  /// Applies the room's play, pause or seek here; see the library comment.
  void _onPartyPlayback(PartyPlayback pb) {
    if (!mounted || !_partyIsHere || _ytTime == null) return;
    // A position heard for another episode means nothing here.
    final key = pb.mediaKey;
    if (key != null && key != WatchPartyService.instance.media.value?.key) {
      return;
    }
    final settling =
        _lastPartySeek != null &&
        DateTime.now().difference(_lastPartySeek!) < const Duration(seconds: 4);
    final off = (_positionNow - pb.position).inMilliseconds.abs() / 1000.0;
    final bool seek;
    if (pb.heartbeat) {
      seek = pb.playing && _ytPlaying && !settling && off > 1.0;
    } else {
      final threshold = pb.seek ? 0.5 : (pb.playing ? 1.0 : 0.3);
      seek = off > threshold && (pb.seek || !settling);
    }
    final changed = pb.playing != _ytPlaying;
    _applyRoom(pb.playing, pb.position, seek: seek);
    if (pb.heartbeat || pb.from.isEmpty) return;
    final l10n = l10nCurrent();
    if (pb.seek) {
      final t = pb.position;
      final mm = t.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = t.inSeconds.remainder(60).toString().padLeft(2, '0');
      final time = t.inHours > 0
          ? '${t.inHours}:$mm:$ss'
          : '${t.inMinutes}:$ss';
      _notice(l10n.partySeeked(pb.from, time));
    } else if (changed) {
      _notice(
        pb.playing ? l10n.partyResumed(pb.from) : l10n.partyPaused(pb.from),
      );
    }
  }

  /// Moves the page to the room's [playing] and [position]; the reports
  /// that follow are the room's move, not the viewer's.
  void _applyRoom(bool playing, Duration position, {required bool seek}) {
    final now = DateTime.now();
    if (!seek && playing == _ytPlaying) return;
    if (seek) {
      _lastPartySeek = now;
      _ytTime = position.inMilliseconds / 1000.0;
      _ytAt = now;
      _refTime = _ytTime;
      final t = _ytTime!.toStringAsFixed(2);
      _run('window.lumoraSeekTo && window.lumoraSeekTo($t)');
    }
    if (playing != _ytPlaying) {
      _ytPlaying = playing;
      _run(
        playing
            ? 'window.lumoraPlay && window.lumoraPlay()'
            : 'window.lumoraPause && window.lumoraPause()',
      );
    }
    _refAt = now;
    _refPlaying = playing;
    _refTime ??= _ytTime;
    _partyQuietUntil = now.add(const Duration(milliseconds: 1500));
  }

  /// False, with a notice, when a room is on this title and only its host
  /// may move playback.
  bool _partyAllowsMe() {
    final room = WatchPartyService.instance.room.value;
    if (room == null || room.canControl || !_partyIsHere) return true;
    _notice(l10nCurrent().partyNoControl);
    return false;
  }

  void _notice(String text) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openPartySheet() {
    unawaited(
      showWatchPartySheet(context, current: () => _partyMedia).then((_) {
        // A room just started here: the guests open at this frame.
        final service = WatchPartyService.instance;
        if (service.room.value?.isHost == true && _ytTime != null) {
          service.reportHostPosition(
            playing: _ytPlaying,
            position: _positionNow,
          );
          unawaited(service.sendState());
        }
        if (mounted) setState(() {});
      }),
    );
  }

  /// A round button in the top bar, drawn like Back.
  Widget _barButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(left: ZplaySpacing.s8),
      child: Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: FocusableCard(
            onTap: onTap,
            builder: (context, state) => CardFocusRing(
              focused: state.focused,
              radius: ZplayRadius.smAll,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active || state.highlighted
                      ? tokens.surfaceRaised
                      : Colors.transparent,
                  borderRadius: ZplayRadius.smAll,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: active ? tokens.accent : tokens.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    if (!_stageNode.hasPrimaryFocus) return KeyEventResult.ignored;
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space ||
            key == LogicalKeyboardKey.gameButtonA ||
            key == LogicalKeyboardKey.mediaPlayPause ||
            key == LogicalKeyboardKey.mediaPlay ||
            key == LogicalKeyboardKey.mediaPause)) {
      if (_partyAllowsMe()) {
        _run('window.lumoraToggle && window.lumoraToggle()');
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.mediaRewind) {
      if (_partyAllowsMe()) _run('window.lumoraSeek && window.lumoraSeek(-10)');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.mediaFastForward) {
      if (_partyAllowsMe()) _run('window.lumoraSeek && window.lumoraSeek(10)');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _backNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = l10nOf(context);
    final channel = widget.channelName;
    final subtitle = channel == null || channel.isEmpty
        ? l10n.officialYouTubeName
        : '${l10n.officialYouTubeName} · $channel';

    final party = WatchPartyService.instance;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            Positioned.fill(child: _page(tokens, l10n, subtitle, party)),
            // 一起看: emoji floating up and the latest chat line, then the chat.
            if (party.active)
              Positioned.fill(child: PartyOverlay(chatOpen: _showPartyChat)),
            if (_showPartyChat)
              Positioned.fill(
                child: PartyChatPanel(
                  onClose: () => setState(() => _showPartyChat = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _page(
    ZplayTokens tokens,
    AppLocalizations l10n,
    String subtitle,
    WatchPartyService party,
  ) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZplaySpacing.s8,
              ZplaySpacing.s4,
              ZplaySpacing.s16,
              ZplaySpacing.s4,
            ),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: l10n.officialYouTubeBack,
                  child: FocusableCard(
                    focusNode: _backNode,
                    onTap: () => Navigator.of(context).maybePop(),
                    builder: (context, state) => CardFocusRing(
                      focused: state.focused,
                      radius: ZplayRadius.smAll,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: state.highlighted
                              ? tokens.surfaceRaised
                              : Colors.transparent,
                          borderRadius: ZplayRadius.smAll,
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ZplaySpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZplayType.label
                            .copyWith(weight: FontWeight.w600)
                            .toStyle(color: tokens.textPrimary),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZplayType.caption.toStyle(
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (party.active)
                  _barButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: l10n.partyChat,
                    onTap: () => setState(() => _showPartyChat = true),
                  ),
                if (_partyMedia != null)
                  _barButton(
                    icon: Icons.groups_rounded,
                    label: l10n.partyTitle,
                    active: party.active,
                    onTap: _openPartySheet,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Focus(
              focusNode: _stageNode,
              autofocus: true,
              child: ColoredBox(color: Colors.black, child: _stage(tokens)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stage(ZplayTokens tokens) {
    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ZplaySpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10nOf(context).officialYouTubeUnavailable,
                textAlign: TextAlign.center,
                style: ZplayType.subtitle.toStyle(color: tokens.textPrimary),
              ),
              const SizedBox(height: ZplaySpacing.s4),
              Text(
                l10nOf(context).officialYouTubeUnavailableBody,
                textAlign: TextAlign.center,
                style: ZplayType.bodySmall.toStyle(color: tokens.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    final embed = _embed;
    if (embed == null) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: tokens.textMuted,
        ),
      );
    }
    return embed;
  }
}
