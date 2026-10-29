import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/stream/stream_model.dart';
import '../account/account_service.dart';

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
  final StreamSource source;

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
    'source': sourceToJson(source),
  };

  static PartyMedia? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final source = sourceFromJson(m['source']);
    final id = m['id'];
    final type = m['type'];
    final title = m['title'];
    if (source == null ||
        id is! String ||
        type is! String ||
        title is! String) {
      return null;
    }
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
    DateTime? at,
  }) : _at = at;

  final bool playing;
  final Duration position;

  /// Who moved it.
  final String from;

  /// True for an explicit jump, which every viewer follows exactly; a
  /// heartbeat only corrects a viewer who has drifted.
  final bool seek;

  /// The host's periodic "this is where we are", not someone's action: it
  /// corrects drift quietly, without a notice.
  final bool heartbeat;

  final DateTime? _at;

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
  });

  final String code;
  final bool isHost;
  final List<PartyMember> members;

  /// Whether a guest's play, pause and seek move the room, or only the
  /// host's do. The host sets it.
  final bool guestsCanControl;

  /// Whether this device's own play, pause and seek should move the room.
  bool get canControl => isHost || guestsCanControl;

  PartyRoom copyWith({List<PartyMember>? members, bool? guestsCanControl}) =>
      PartyRoom(
        code: code,
        isHost: isHost,
        members: members ?? this.members,
        guestsCanControl: guestsCanControl ?? this.guestsCanControl,
      );
}

/// 一起看: a private room where friends watch the same title in step.
///
/// A room is a private Supabase Realtime channel `party:<code>`; only
/// invited accounts may use one (the `realtime.messages` policies). Nothing
/// is stored and the video never passes through Supabase: each viewer
/// plays the source on their own device, and the room carries only the
/// small messages that keep them together.
///
/// * `state` - the host's title, source and position. Sent when someone
///   joins (they ask with `hello`), when the host changes title or episode,
///   and every few seconds while playing, so a guest who drifted is pulled
///   back.
/// * `sync` - a play, pause or seek by whoever may control.
/// * `chat`, `react` - messages and emoji.
///
/// Presence lists who is in the room.
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

  /// Play, pause and seek from the room, for the player to apply.
  Stream<PartyPlayback> get playback => _playback.stream;

  /// Emoji sent by anyone in the room (this device's own included).
  Stream<String> get reactions => _reactions.stream;

  /// Chat lines from others, for a notice while the chat is closed.
  Stream<PartyChat> get incomingChat => _incomingChat.stream;

  /// The host's playback as last heard, so a guest can start in step.
  PartyPlayback? lastPlayback;

  RealtimeChannel? _channel;
  final String _clientId = _randomId(10);

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
    media.value = watching;
    room.value = PartyRoom(code: code, isHost: true);
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
      ..onBroadcast(
        event: 'end',
        callback: (_) {
          if (room.value?.isHost != true) unawaited(leave());
        },
      )
      ..onPresenceSync((_) => _onPresence());

    final subscribed = Completer<void>();
    channel.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.track({'id': _clientId, 'name': _myName, 'host': host});
        if (!subscribed.isCompleted) subscribed.complete();
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        if (!subscribed.isCompleted) {
          subscribed.completeError(
            StateError('Could not join the room: ${error ?? status}'),
          );
        }
      }
    });
    try {
      await subscribed.future.timeout(const Duration(seconds: 10));
    } catch (_) {
      await leave();
      rethrow;
    }
  }

  /// A broadcast's own payload, whichever shape the client hands over.
  static Map<String, dynamic> _body(Map<String, dynamic> p) {
    final inner = p['payload'];
    return inner is Map ? Map<String, dynamic>.from(inner) : p;
  }

  void _onPresence() {
    final ch = _channel;
    final r = room.value;
    if (ch == null || r == null) return;
    final members = <PartyMember>[
      for (final s in ch.presenceState())
        for (final p in s.presences)
          PartyMember(
            id: '${p.payload['id'] ?? s.key}',
            name: '${p.payload['name'] ?? '?'}',
            host: p.payload['host'] == true,
          ),
    ];
    room.value = r.copyWith(members: members);
    // A host that vanished without its `end` (closed the app, lost the
    // network) has ended the room: a guest left alone in it would never
    // hear another state. Only once the host has been seen, so a guest
    // arriving before the host's presence is synced does not leave.
    if (!r.isHost) {
      final hostHere = members.any((m) => m.host);
      if (hostHere) {
        _hostSeen = true;
      } else if (_hostSeen) {
        unawaited(leave());
      }
    }
  }

  bool _hostSeen = false;

  void _onState(Map<String, dynamic> b) {
    final r = room.value;
    if (r == null || r.isHost) return;
    final m = PartyMedia.fromJson(b['media']);
    if (m != null) media.value = m;
    final control = b['guestsCanControl'];
    if (control is bool && control != r.guestsCanControl) {
      room.value = r.copyWith(guestsCanControl: control);
    }
    final pb = _playbackOf(b, seek: false, heartbeat: true);
    if (pb != null) {
      lastPlayback = pb;
      _playback.add(pb);
    }
  }

  void _onSync(Map<String, dynamic> b) {
    final r = room.value;
    if (r == null) return;
    final from = b['from'];
    // A guest's move counts only while the host allows guests to control.
    if (b['host'] != true && !r.guestsCanControl) return;
    final pb = _playbackOf(b, seek: b['seek'] == true);
    if (pb == null || from == _clientId) return;
    lastPlayback = pb;
    _playback.add(pb);
  }

  PartyPlayback? _playbackOf(
    Map<String, dynamic> b, {
    required bool seek,
    bool heartbeat = false,
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
    return PartyPlayback(
      playing: playing,
      position: Duration(milliseconds: position),
      from: '${b['name'] ?? ''}',
      seek: seek,
      heartbeat: heartbeat,
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
    await _send('state', {
      'media': m.toJson(),
      'guestsCanControl': r.guestsCanControl,
      if (pb != null) 'playing': pb.playing,
      if (pb != null) 'positionMs': pb.position.inMilliseconds,
      'sentAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// The host's player reports where it is; sent on to guests as a heartbeat.
  void reportHostPosition({required bool playing, required Duration position}) {
    if (room.value?.isHost != true) return;
    hostPlayback = PartyPlayback(
      playing: playing,
      position: position,
      from: _myName,
    );
  }

  /// This device played, paused or seeked: the room follows when this
  /// device may control it.
  Future<void> sendPlayback({
    required bool playing,
    required Duration position,
    bool seek = false,
  }) async {
    final r = room.value;
    if (r == null || !r.canControl) return;
    reportHostPosition(playing: playing, position: position);
    await _send('sync', {
      'from': _clientId,
      'name': _myName,
      'host': r.isHost,
      'playing': playing,
      'positionMs': position.inMilliseconds,
      'seek': seek,
      'sentAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// The host moved to another title or episode.
  Future<void> setMedia(PartyMedia watching) async {
    if (room.value?.isHost != true) return;
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
  Future<void> leave() async {
    final ch = _channel;
    final wasHost = room.value?.isHost == true;
    _channel = null;
    room.value = null;
    media.value = null;
    chat.value = const [];
    lastPlayback = null;
    hostPlayback = null;
    _hostSeen = false;
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
        () => ch.sendBroadcastMessage(event: 'end', payload: const {}),
      );
    }
    await step('untrack', ch.untrack);
    await step('remove', () => Supabase.instance.client.removeChannel(ch));
    debugPrint('[WatchParty] left the room');
  }
}
