import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/stream/stream_model.dart';
import '../account/account_service.dart';
import 'party_rules.dart';

export 'party_rules.dart' show HostPresenceChange;

/// What a room is watching: the title, the episode and the source the host
/// opened, enough for a guest to open the same thing.
@immutable
class PartyMedia {
  const PartyMedia({
    required this.id,
    required this.type,
    required this.title,
    required this.source,
    this.year,
    this.poster,
    this.backdrop,
    this.episodeId,
    this.season,
    this.episode,
  });

  final String id;
  final String type;
  final String title;
  final String? year;
  final String? poster;
  final String? backdrop;
  final String? episodeId;
  final int? season;
  final int? episode;

  /// The host's source. Null on a guest when the host's source only plays on
  /// the host's device (see [sourceShared]): the guest then finds a source of
  /// its own for the same episode.
  final StreamSource? source;

  /// The title and episode, without the source: the position a room reports
  /// belongs to this.
  String get key => partyMediaKey(
    id: id,
    episodeId: episodeId,
    season: season,
    episode: episode,
  );

  /// Whether a guest can open [source] as it is. The Mega anime sources play
  /// through a proxy on the host's own computer (`http://127.0.0.1:...`),
  /// which on a guest's device points at nothing.
  bool get sourceShared => isShareableSourceUrl(source?.url);

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'year': year,
    'poster': poster,
    'backdrop': backdrop,
    'episodeId': episodeId,
    'season': season,
    'episode': episode,
    'source': sourceShared ? sourceToJson(source!) : null,
    if (!sourceShared) 'sourceLocal': true,
  };

  static PartyMedia? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    var source = sourceFromJson(m['source']);
    final id = m['id'];
    final type = m['type'];
    final title = m['title'];
    // A host whose source stays on its device says so and sends none; any
    // other state without a source is not one.
    if (id is! String ||
        type is! String ||
        title is! String ||
        (source == null && m['sourceLocal'] != true)) {
      return null;
    }
    // Only a web address is opened as it came. A link to the guest's own
    // device or network, or to anything but a web page, is not one to open
    // unasked: the guest finds a source of its own instead.
    if (source != null && !isShareableSourceUrl(source.url)) source = null;
    int? asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : null);
    String? asStr(Object? v) => v is String && v.isNotEmpty ? v : null;
    return PartyMedia(
      id: id,
      type: type,
      title: title,
      year: asStr(m['year']),
      poster: asStr(m['poster']),
      backdrop: asStr(m['backdrop']),
      episodeId: asStr(m['episodeId']),
      season: asInt(m['season']),
      episode: asInt(m['episode']),
      source: source,
    );
  }

  /// The fields a player needs to open [s] again on another device. Torrent
  /// and subtitle fields stay behind: the app plays neither from a room.
  ///
  /// The headers go along: most hosts that need them (a Referer, an Origin,
  /// a token the scraper fetched) refuse the stream without them, so the
  /// guest could not play the link otherwise. They are what the scraper
  /// sent, not the viewer's own credentials, and only the room's members
  /// receive them.
  static Map<String, dynamic> sourceToJson(StreamSource s) => {
    'name': s.name,
    'title': s.title,
    'description': s.description,
    'url': s.url,
    'externalUrl': s.externalUrl,
    'addonName': s.addonName,
    'providerId': s.providerId,
    'providerName': s.providerName,
    'headers': s.headers,
    'behaviorHints': s.behaviorHints,
  };

  static StreamSource? sourceFromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final addon = m['addonName'];
    if (addon is! String) return null;
    final headers = m['headers'];
    final hints = m['behaviorHints'];
    return StreamSource(
      name: m['name'] as String?,
      title: m['title'] as String?,
      description: m['description'] as String?,
      url: m['url'] as String?,
      externalUrl: m['externalUrl'] as String?,
      addonName: addon,
      providerId: m['providerId'] as String?,
      providerName: m['providerName'] as String?,
      headers: headers is Map
          ? headers.map((k, v) => MapEntry('$k', '$v'))
          : null,
      behaviorHints: hints is Map ? Map<String, dynamic>.from(hints) : null,
    );
  }
}

/// Where the room's playback is: playing or paused, at [position].
@immutable
class PartyPlayback {
  const PartyPlayback({
    required this.playing,
    required this.position,
    required this.from,
    this.seek = false,
    this.heartbeat = false,
    this.rate,
    this.mediaKey,
    this.reason,
    DateTime? at,
  }) : _at = at;

  final bool playing;
  final Duration position;

  /// The room's speed: the host's own, without the nudge drift correction
  /// puts on top. Null from a device that did not say.
  final double? rate;

  /// The [PartyMedia.key] [position] belongs to. A position heard for one
  /// episode means nothing on the next one.
  final String? mediaKey;

  /// Why, when the move was not a viewer's own: [reasonBackground] for a
  /// host whose app left the screen.
  final String? reason;

  static const reasonBackground = 'background';

  /// Who moved it.
  final String from;

  /// True for an explicit jump, which every viewer follows exactly; a
  /// heartbeat only corrects a viewer who has drifted.
  final bool seek;

  /// The host's periodic "this is where we are", not someone's action: it
  /// corrects drift quietly, without a notice.
  final bool heartbeat;

  final DateTime? _at;

  /// When [position] was true: heard, for a guest; sampled, for the host.
  DateTime? get at => _at;

  /// Where the room is now: [position], plus the time since it was heard
  /// while playing. A guest who joins opens the title a few seconds after
  /// the host's last message; opening at [position] itself put them behind,
  /// and the catch-up seeks that followed kept the picture black.
  Duration get positionNow {
    final at = _at;
    if (!playing || at == null) return position;
    final since = DateTime.now().difference(at);
    return position +
        (since > const Duration(minutes: 1) ? Duration.zero : since);
  }
}

@immutable
class PartyChat {
  const PartyChat({required this.from, required this.text, required this.at});

  final String from;
  final String text;
  final DateTime at;
}

@immutable
class PartyMember {
  const PartyMember({required this.id, required this.name, required this.host});

  final String id;
  final String name;
  final bool host;
}

/// The room this device is in.
@immutable
class PartyRoom {
  const PartyRoom({
    required this.code,
    required this.isHost,
    this.members = const [],
    this.guestsCanControl = true,
    this.hostUserId,
  });

  final String code;
  final bool isHost;
  final List<PartyMember> members;

  /// The host's account, as the host's `state` gives it.
  final String? hostUserId;

  /// Whether a guest's play, pause and seek move the room, or only the
  /// host's do. The host sets it.
  final bool guestsCanControl;

  /// Whether this device's own play, pause and seek should move the room.
  bool get canControl => isHost || guestsCanControl;

  PartyRoom copyWith({
    List<PartyMember>? members,
    bool? guestsCanControl,
    String? hostUserId,
  }) => PartyRoom(
    code: code,
    isHost: isHost,
    members: members ?? this.members,
    guestsCanControl: guestsCanControl ?? this.guestsCanControl,
    hostUserId: hostUserId ?? this.hostUserId,
  );
}

/// Something the room's connection did that the viewer should hear about.
enum PartyEvent {
  /// The host dropped out of the room; the guest waits for it.
  hostAway,

  /// The host is back.
  hostBack,

  /// This device lost the room and is reconnecting.
  reconnecting,

  /// This device is back in the room.
  reconnected,
}

/// Why this device is no longer in a room.
enum PartyEndReason {
  /// The viewer left, or the host ended it on this device.
  left,

  /// The host ended the room.
  ended,

  /// The host dropped out and did not come back in time.
  hostGone,

  /// This device lost the room and could not get back in.
  dropped,
}

/// 一起看: a private room where friends watch the same title in step.
///
/// A room is a private Supabase Realtime channel `party:<code>`; only
/// invited accounts may use one (the `realtime.messages` policies). Nothing
/// is stored and the video never passes through Supabase: each viewer
/// plays the source on their own device, and the room carries only the
/// small messages that keep them together.
///
/// * `state` - the host's title, source, position and speed. Sent when
///   someone joins (they ask with `hello`), when the host changes title or
///   episode, and every few seconds while playing, so a guest who drifted is
///   pulled back.
/// * `sync` - a play, pause, seek or speed change by whoever may control.
/// * `chat`, `react` - messages and emoji.
/// * `end` - the host ended the room.
///
/// Presence lists who is in the room. Only the host's `state`, `end` and
/// syncs count as the host's; see [PartyAuthority].
class WatchPartyService {
  WatchPartyService._();
  static final WatchPartyService instance = WatchPartyService._();

  final ValueNotifier<PartyRoom?> room = ValueNotifier(null);
  final ValueNotifier<PartyMedia?> media = ValueNotifier(null);
  final ValueNotifier<List<PartyChat>> chat = ValueNotifier(const []);

  final StreamController<PartyPlayback> _playback =
      StreamController.broadcast();
  final StreamController<String> _reactions = StreamController.broadcast();
  final StreamController<PartyChat> _incomingChat =
      StreamController.broadcast();
  final StreamController<PartyEvent> _events = StreamController.broadcast();

  /// Play, pause and seek from the room, for the player to apply.
  Stream<PartyPlayback> get playback => _playback.stream;

  /// Emoji sent by anyone in the room (this device's own included).
  Stream<String> get reactions => _reactions.stream;

  /// Chat lines from others, for a notice while the chat is closed.
  Stream<PartyChat> get incomingChat => _incomingChat.stream;

  /// The connection's ups and downs, for a notice.
  Stream<PartyEvent> get events => _events.stream;

  /// Why the last room ended; read when [room] turns null.
  PartyEndReason? endReason;

  /// The host's playback as last heard, so a guest can start in step.
  PartyPlayback? lastPlayback;

  RealtimeChannel? _channel;
  final String _clientId = _randomId(10);

  final PartyAuthority _authority = PartyAuthority();
  final PartyActionClock _clock = PartyActionClock();
  final HostAbsence _hostAbsence = HostAbsence();
  Timer? _hostGraceTimer;

  /// When this device lost the room's channel, while it is reconnecting.
  DateTime? _linkLostAt;
  Timer? _dropTimer;

  /// How long a lost channel may take to come back before the room is
  /// given up. The client rejoins on its own with backoff; a phone that
  /// changed networks is usually back within seconds.
  static const _dropAfter = Duration(seconds: 45);

  bool get active => room.value != null;

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _randomId(int length) {
    final r = Random.secure();
    return List.generate(
      length,
      (_) => _codeChars[r.nextInt(_codeChars.length)],
    ).join();
  }

  /// A typed code as the room's: upper case, without spaces or dashes.
  static String normalizeCode(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static bool isValidCode(String code) =>
      RegExp('^[$_codeChars]{6}\$').hasMatch(code);

  String get _myName {
    final n = AccountService.displayName.trim();
    return n.isEmpty ? '?' : n;
  }

  /// Opens a room for [watching] with this device as host; returns its code.
  Future<String> create(PartyMedia watching) async {
    await leave();
    final code = _randomId(6);
    endReason = null;
    _authority.hostIsMe(_clientId);
    media.value = watching;
    room.value = PartyRoom(
      code: code,
      isHost: true,
      hostUserId: AccountService.session.value?.user.id,
    );
    await _open(code, host: true);
    return code;
  }

  /// Joins room [code]. Completes with what the host is watching, or null
  /// when no host answered within [timeout] (a wrong code, or the host left).
  Future<PartyMedia?> join(
    String code, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await leave();
    endReason = null;
    room.value = PartyRoom(code: code, isHost: false);
    final first = Completer<PartyMedia?>();
    late final VoidCallback onMedia;
    onMedia = () {
      if (media.value != null && !first.isCompleted) {
        first.complete(media.value);
      }
    };
    media.addListener(onMedia);
    try {
      await _open(code, host: false);
      // Asked again a few times: the host may still be connecting.
      for (var i = 0; i < 4 && !first.isCompleted; i++) {
        await _send('hello', {'from': _clientId});
        await Future.any([
          first.future,
          Future<void>.delayed(
            Duration(milliseconds: timeout.inMilliseconds ~/ 4),
          ),
        ]);
      }
      final got = first.isCompleted ? await first.future : null;
      if (got == null) await leave();
      return got;
    } finally {
      media.removeListener(onMedia);
    }
  }

  Future<void> _open(String code, {required bool host}) async {
    final subscribed = Completer<void>();
    _subscribe(code, host: host, subscribed: subscribed);
    try {
      await subscribed.future.timeout(const Duration(seconds: 10));
    } catch (_) {
      await leave();
      rethrow;
    }
  }

  /// Opens the room's channel and keeps it open: tracked again whenever the
  /// client rejoins it, and opened anew when the server closes it.
  ///
  /// [subscribed] completes on the first join. A channel opened again after
  /// a close has none, and its failures only keep the room reconnecting
  /// until [_dropAfter] gives it up.
  void _subscribe(
    String code, {
    required bool host,
    Completer<void>? subscribed,
  }) {
    final client = Supabase.instance.client;
    final channel = client.channel(
      'party:$code',
      opts: RealtimeChannelConfig(private: true, key: _clientId),
    );
    _channel = channel;

    channel
      ..onBroadcast(
        event: 'hello',
        callback: (_) {
          if (room.value?.isHost == true) unawaited(sendState());
        },
      )
      ..onBroadcast(event: 'state', callback: (p) => _onState(_body(p)))
      ..onBroadcast(event: 'sync', callback: (p) => _onSync(_body(p)))
      ..onBroadcast(event: 'chat', callback: (p) => _onChat(_body(p)))
      ..onBroadcast(
        event: 'react',
        callback: (p) {
          final e = _body(p)['emoji'];
          if (e is String && e.isNotEmpty) _reactions.add(e);
        },
      )
      ..onBroadcast(event: 'end', callback: (p) => _onEnd(_body(p)))
      ..onPresenceSync((_) => _onPresence());

    var joined = false;
    channel.subscribe((status, error) async {
      // A channel this device has since left or replaced.
      if (!identical(_channel, channel)) return;
      switch (status) {
        case RealtimeSubscribeStatus.subscribed:
          joined = true;
          await channel.track({'id': _clientId, 'name': _myName, 'host': host});
          if (subscribed != null && !subscribed.isCompleted) {
            subscribed.complete();
          }
          _linkUp();
        case RealtimeSubscribeStatus.channelError:
        case RealtimeSubscribeStatus.timedOut:
          if (subscribed != null && !subscribed.isCompleted) {
            subscribed.completeError(
              StateError('Could not join the room: ${error ?? status}'),
            );
            return;
          }
          // The client rejoins an errored channel on its own, with backoff.
          // The room says it is reconnecting meanwhile, rather than going on
          // as if the others could still hear it.
          _linkDown();
        case RealtimeSubscribeStatus.closed:
          if (!joined) return;
          // The server closed it, and a closed channel is never rejoined:
          // the room is opened again.
          _linkDown();
          unawaited(_reopen(code, host: host, old: channel));
      }
    });
  }

  Future<void> _reopen(
    String code, {
    required bool host,
    required RealtimeChannel old,
  }) async {
    // A moment's pause, so a server that closes every join at once is not
    // asked again in a tight loop; the drop timer bounds the whole wait.
    // A closed channel has already taken itself off the socket.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!identical(_channel, old) || room.value?.code != code) return;
    debugPrint('[WatchParty] reopening the room');
    _subscribe(code, host: host);
  }

  void _linkDown() {
    if (_linkLostAt != null) return;
    _linkLostAt = DateTime.now();
    _events.add(PartyEvent.reconnecting);
    _dropTimer?.cancel();
    _dropTimer = Timer(_dropAfter, () {
      if (_linkLostAt == null || !active) return;
      debugPrint('[WatchParty] the room did not come back');
      unawaited(leave(reason: PartyEndReason.dropped));
    });
  }

  void _linkUp() {
    _dropTimer?.cancel();
    _dropTimer = null;
    if (_linkLostAt == null) return;
    _linkLostAt = null;
    _events.add(PartyEvent.reconnected);
    // Whatever was said while this device was away is lost: the host tells
    // the room where it is again, and a guest asks.
    if (room.value?.isHost == true) {
      unawaited(sendState());
    } else {
      unawaited(_send('hello', {'from': _clientId}));
    }
  }

  /// A broadcast's own payload, whichever shape the client hands over.
  static Map<String, dynamic> _body(Map<String, dynamic> p) {
    final inner = p['payload'];
    return inner is Map ? Map<String, dynamic>.from(inner) : p;
  }

  void _onEnd(Map<String, dynamic> b) {
    if (room.value == null || room.value!.isHost) return;
    final from = b['from'];
    if (!_authority.acceptEnd(from is String ? from : null)) {
      debugPrint('[WatchParty] an end not from the host, ignored');
      return;
    }
    unawaited(leave(reason: PartyEndReason.ended));
  }

  void _onPresence() {
    final ch = _channel;
    final r = room.value;
    if (ch == null || r == null) return;
    // The host is the member the room's authority names, not whichever
    // member says it is.
    final members = <PartyMember>[
      for (final s in ch.presenceState())
        for (final p in s.presences)
          PartyMember(
            id: '${p.payload['id'] ?? s.key}',
            name: '${p.payload['name'] ?? '?'}',
            host: _authority.isHost('${p.payload['id'] ?? s.key}'),
          ),
    ];
    room.value = r.copyWith(members: members);
    if (r.isHost) return;
    // A host missing from presence may only have lost its network for a
    // moment; one that really left sends `end`. The guest used to leave at
    // the first sync without the host, so every blink of the host's network
    // ended the room for everyone. It now waits a grace period first.
    final change = _hostAbsence.update(
      hostHere: members.any((m) => m.host),
      now: DateTime.now(),
    );
    switch (change) {
      case HostPresenceChange.away:
        _events.add(PartyEvent.hostAway);
        _hostGraceTimer?.cancel();
        _hostGraceTimer = Timer(_hostAbsence.grace, () {
          if (active && _hostAbsence.expired(DateTime.now())) {
            unawaited(leave(reason: PartyEndReason.hostGone));
          }
        });
      case HostPresenceChange.back:
        _hostGraceTimer?.cancel();
        _events.add(PartyEvent.hostBack);
      case HostPresenceChange.none:
        break;
    }
  }

  void _onState(Map<String, dynamic> b) {
    final r = room.value;
    if (r == null || r.isHost) return;
    final from = b['from'];
    final knewHost = _authority.hostId != null;
    if (!_authority.acceptState(from is String ? from : null)) {
      debugPrint('[WatchParty] a state not from the host, ignored');
      return;
    }
    final m = PartyMedia.fromJson(b['media']);
    final key = m?.key ?? media.value?.key;
    // The position goes in before the media: a guest following the host to
    // another episode opens it at [lastPlayback] the moment [media] changes,
    // and so used to open it where the previous episode had got to.
    if (m != null && m.key != media.value?.key) lastPlayback = null;
    final pb = _playbackOf(b, seek: false, heartbeat: true, mediaKey: key);
    final act = b['act'];
    final fresh = _clock.acceptHeartbeat(
      act is int ? act : null,
      DateTime.now(),
    );
    if (pb != null && fresh) lastPlayback = pb;
    final control = b['guestsCanControl'];
    final hostUid = b['hostUid'];
    if ((control is bool && control != r.guestsCanControl) ||
        (hostUid is String && hostUid != r.hostUserId)) {
      room.value = r.copyWith(
        guestsCanControl: control is bool ? control : null,
        hostUserId: hostUid is String ? hostUid : null,
      );
    }
    if (m != null) media.value = m;
    // The host is known only now: presence can say who it is.
    if (!knewHost) _onPresence();
    if (pb != null && fresh) _playback.add(pb);
  }

  void _onSync(Map<String, dynamic> b) {
    final r = room.value;
    if (r == null) return;
    final from = b['from'];
    if (from == _clientId) return;
    // A guest's move counts only while the host allows guests to control,
    // and a move is the host's only when it came from the host.
    if (!_authority.acceptSync(
      from is String ? from : null,
      guestsCanControl: r.guestsCanControl,
    )) {
      return;
    }
    // A move made on another episode (a guest still on the previous one) is
    // not a move on this one.
    final key = b['mediaKey'];
    final current = media.value?.key;
    if (key is String && current != null && key != current) return;
    final act = b['act'];
    if (!_clock.acceptMove(act is int ? act : null, DateTime.now())) return;
    final pb = _playbackOf(
      b,
      seek: b['seek'] == true,
      mediaKey: key is String ? key : current,
    );
    if (pb == null) return;
    lastPlayback = pb;
    _playback.add(pb);
  }

  PartyPlayback? _playbackOf(
    Map<String, dynamic> b, {
    required bool seek,
    bool heartbeat = false,
    String? mediaKey,
  }) {
    final ms = b['positionMs'];
    final playing = b['playing'];
    if (ms is! num || playing is! bool) return null;
    // A playing position was true when it was sent; by the time it lands
    // the sender has moved on by the time in transit. Device clocks are
    // network-synced closely enough for this, and the correction is capped
    // so a clock that is badly off cannot throw anyone far.
    var position = ms.toInt();
    final sentAt = b['sentAt'];
    if (playing && sentAt is num) {
      final transit = DateTime.now().millisecondsSinceEpoch - sentAt.toInt();
      position += transit.clamp(0, 2000);
    }
    final rate = b['rate'];
    final reason = b['reason'];
    return PartyPlayback(
      playing: playing,
      position: Duration(milliseconds: position),
      from: '${b['name'] ?? ''}',
      seek: seek,
      heartbeat: heartbeat,
      rate: rate is num && rate > 0 && rate <= 4 ? rate.toDouble() : null,
      mediaKey: mediaKey,
      reason: reason is String ? reason : null,
      at: DateTime.now(),
    );
  }

  void _onChat(Map<String, dynamic> b) {
    final text = b['text'];
    if (text is! String || text.trim().isEmpty) return;
    final line = PartyChat(
      from: '${b['name'] ?? '?'}',
      text: text.trim(),
      at: DateTime.now(),
    );
    _addChat(line);
    if (b['from'] != _clientId) _incomingChat.add(line);
  }

  void _addChat(PartyChat line) {
    final list = [...chat.value, line];
    chat.value = list.length > 200 ? list.sublist(list.length - 200) : list;
  }

  /// The host's current [media] and [playing] at [position], for guests.
  /// Heartbeats and a guest's `hello` both end up here.
  PartyPlayback? hostPlayback;

  Future<void> sendState() async {
    final r = room.value;
    final m = media.value;
    if (r == null || !r.isHost || m == null) return;
    final pb = hostPlayback;
    final usable = pb != null && (pb.mediaKey == null || pb.mediaKey == m.key);
    await _send('state', {
      'from': _clientId,
      'hostUid': r.hostUserId,
      'media': m.toJson(),
      'guestsCanControl': r.guestsCanControl,
      'act': _clock.current,
      if (usable) 'playing': pb.playing,
      // A `hello` is answered from the last sample, up to two seconds old.
      // It is run on to now here, by the clock that took it: the old
      // position stamped with the time of sending put a joining guest up to
      // two seconds behind.
      if (usable) 'positionMs': pb.positionNow.inMilliseconds,
      if (usable && pb.rate != null) 'rate': pb.rate,
      'sentAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// The host's player reports where it is; sent on to guests as a heartbeat.
  /// [rate] is the host's own speed, without any drift nudge.
  void reportHostPosition({
    required bool playing,
    required Duration position,
    double? rate,
  }) {
    if (room.value?.isHost != true) return;
    hostPlayback = PartyPlayback(
      playing: playing,
      position: position,
      from: _myName,
      rate: rate ?? hostPlayback?.rate,
      mediaKey: media.value?.key,
      at: DateTime.now(),
    );
  }

  /// This device played, paused, seeked or changed speed: the room follows
  /// when this device may control it. [reason] says why when it was not the
  /// viewer's own doing.
  Future<void> sendPlayback({
    required bool playing,
    required Duration position,
    bool seek = false,
    double? rate,
    String? reason,
  }) async {
    final r = room.value;
    if (r == null || !r.canControl) return;
    reportHostPosition(playing: playing, position: position, rate: rate);
    await _send('sync', {
      'from': _clientId,
      'name': _myName,
      'playing': playing,
      'positionMs': position.inMilliseconds,
      'seek': seek,
      if (rate != null) 'rate': rate,
      if (reason != null) 'reason': reason,
      'mediaKey': media.value?.key,
      'act': _clock.next(DateTime.now()),
      'sentAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// The host moved to another title or episode, or to another source.
  ///
  /// On another episode the position starts over at [startAt], where the
  /// host's player opens it. The last position heard belonged to the
  /// previous episode, and guests following the host used to open the new
  /// one at the old one's end.
  Future<void> setMedia(
    PartyMedia watching, {
    Duration startAt = Duration.zero,
  }) async {
    if (room.value?.isHost != true) return;
    if (media.value?.key != watching.key) {
      hostPlayback = PartyPlayback(
        playing: false,
        position: startAt,
        from: _myName,
        rate: hostPlayback?.rate,
        mediaKey: watching.key,
        at: DateTime.now(),
      );
    }
    media.value = watching;
    await sendState();
  }

  Future<void> setGuestsCanControl(bool value) async {
    final r = room.value;
    if (r == null || !r.isHost) return;
    room.value = r.copyWith(guestsCanControl: value);
    await sendState();
  }

  Future<void> sendChat(String text) async {
    final t = text.trim();
    if (t.isEmpty || room.value == null) return;
    final clipped = t.length > 300 ? t.substring(0, 300) : t;
    _addChat(PartyChat(from: _myName, text: clipped, at: DateTime.now()));
    await _send('chat', {'from': _clientId, 'name': _myName, 'text': clipped});
  }

  Future<void> sendReaction(String emoji) async {
    if (room.value == null) return;
    _reactions.add(emoji);
    await _send('react', {'from': _clientId, 'emoji': emoji});
  }

  Future<void> _send(String event, Map<String, dynamic> payload) async {
    final ch = _channel;
    if (ch == null) return;
    try {
      await ch.sendBroadcastMessage(event: event, payload: payload);
    } catch (e) {
      debugPrint('[WatchParty] $event not sent: $e');
    }
  }

  /// Leaves the room. A host leaving ends it for everyone.
  Future<void> leave({PartyEndReason reason = PartyEndReason.left}) async {
    final ch = _channel;
    final wasHost = room.value?.isHost == true;
    if (room.value != null) endReason = reason;
    _channel = null;
    _hostGraceTimer?.cancel();
    _dropTimer?.cancel();
    _linkLostAt = null;
    _authority.reset();
    _clock.reset();
    _hostAbsence.reset();
    room.value = null;
    media.value = null;
    chat.value = const [];
    lastPlayback = null;
    hostPlayback = null;
    if (ch == null) return;
    // Each step on its own deadline and its own catch: one that hung or
    // threw used to stop the rest, and a host that never got as far as
    // removing its channel stayed in the room for everyone else.
    Future<void> step(String what, Future<Object?> Function() run) async {
      try {
        await run().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('[WatchParty] leave: $what: $e');
      }
    }

    if (wasHost) {
      await step(
        'end',
        () =>
            ch.sendBroadcastMessage(event: 'end', payload: {'from': _clientId}),
      );
    }
    await step('untrack', ch.untrack);
    await step('remove', () => Supabase.instance.client.removeChannel(ch));
    debugPrint('[WatchParty] left the room');
  }
}
