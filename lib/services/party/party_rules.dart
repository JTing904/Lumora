/// Rules a 一起看 room follows: who may move it, which messages are stale,
/// how long a guest waits for a host that dropped, and which sources can be
/// shared.
///
/// Kept out of `watch_party_service.dart` and `player_screen.dart`: the
/// service talks to Supabase Realtime and the screen owns a `media_kit`
/// `Player`, and no test can build either, so the rules are driven here.
library;

/// The title and episode a room's position belongs to.
///
/// The source is left out on purpose: a host whose source died and was
/// replaced is still at the same moment of the same episode, while a host on
/// another episode is not, whichever source either is on.
String partyMediaKey({
  required String id,
  String? episodeId,
  int? season,
  int? episode,
}) {
  if (episodeId != null) return '$id|$episodeId';
  if (season != null || episode != null) return '$id|$season:$episode';
  return id;
}

/// Whether [url] only plays on the device that made it: a loopback proxy
/// (the Mega anime sources stream through `http://127.0.0.1:<port>`), a
/// private-network address, or a name that only resolves on this network.
///
/// Such a link sent to a guest points at the guest's own device or home
/// network instead, so it is never shared; the guest finds a source of its
/// own for the same episode.
bool isDeviceLocalUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) return false;
  final String host = uri.host.toLowerCase();
  if (host.isEmpty) return false;
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.lan') ||
      host.endsWith('.internal') ||
      host.endsWith('.home.arpa')) {
    return true;
  }
  // IPv6 hosts arrive without their brackets.
  if (host.contains(':')) {
    return host == '::1' ||
        host == '::' ||
        host.startsWith('fe8') ||
        host.startsWith('fe9') ||
        host.startsWith('fea') ||
        host.startsWith('feb') ||
        host.startsWith('fc') ||
        host.startsWith('fd') ||
        host.startsWith('::ffff:127.') ||
        host.startsWith('::ffff:10.') ||
        host.startsWith('::ffff:192.168.');
  }
  final List<int>? ip = _ipv4(host);
  if (ip == null) return false;
  final int a = ip[0];
  final int b = ip[1];
  return a == 127 ||
      a == 10 ||
      a == 0 ||
      (a == 192 && b == 168) ||
      (a == 172 && b >= 16 && b <= 31) ||
      (a == 169 && b == 254) ||
      (a == 100 && b >= 64 && b <= 127);
}

List<int>? _ipv4(String host) {
  final List<String> parts = host.split('.');
  if (parts.length != 4) return null;
  final List<int> out = <int>[];
  for (final String p in parts) {
    final int? n = int.tryParse(p);
    if (n == null || n < 0 || n > 255) return null;
    out.add(n);
  }
  return out;
}

/// Whether a room may hand [url] to a guest's player at all: a web address,
/// and not one on the host's own device or network.
bool isShareableSourceUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) return false;
  final String scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  return !isDeviceLocalUrl(url);
}

/// Orders the room's play, pause and seek against the host's heartbeat.
///
/// Every play, pause or seek anyone makes carries the next number in the
/// room's count, and the host's heartbeat carries the last number it had
/// applied when it was sent. A guest who paused used to be played again by a
/// heartbeat the host had sent a moment before it heard the pause: that
/// heartbeat now carries an older number and is set aside. The host is the
/// one who settles two moves made at once, so a heartbeat carrying the same
/// number as this device's is followed.
class PartyActionClock {
  PartyActionClock({this.patience = const Duration(seconds: 6)});

  /// How long a heartbeat that has not caught up is set aside. A move the
  /// host never heard (a dropped message) would otherwise leave this device
  /// deaf to the room for good.
  final Duration patience;

  int _act = 0;
  DateTime? _movedAt;

  /// The newest move this device knows of.
  int get current => _act;

  /// This device moved the room: the number its message carries.
  int next(DateTime now) {
    _movedAt = now;
    return ++_act;
  }

  /// A play, pause or seek from someone else: false when a newer one has
  /// already been applied here, and the late one would undo it.
  bool acceptMove(int? act, DateTime now) {
    if (act == null) return true;
    if (act < _act) return false;
    _act = act;
    _movedAt = now;
    return true;
  }

  /// The host's heartbeat: false while it predates a move this device has
  /// already applied, for up to [patience] after that move.
  bool acceptHeartbeat(int? act, DateTime now) {
    if (act == null || act >= _act) {
      if (act != null) _act = act;
      return true;
    }
    final DateTime? moved = _movedAt;
    return moved == null || now.difference(moved) >= patience;
  }

  void reset() {
    _act = 0;
    _movedAt = null;
  }
}

/// What a guest does about a host missing from the room's presence.
enum HostPresenceChange {
  /// Nothing new.
  none,

  /// The host just went missing: wait for it, and say so.
  away,

  /// The host is back within the grace period.
  back,
}

/// Gives a host that dropped out of presence time to come back.
///
/// Presence loses a host whose network blinks, a phone that changes from
/// Wi-Fi to mobile data, a computer waking from sleep. A guest used to leave
/// the room the moment a presence sync came without the host, so every such
/// blink ended the room for everyone. A host that really left sends `end`;
/// one that is only missing gets [grace] to return.
class HostAbsence {
  HostAbsence({this.grace = const Duration(seconds: 25)});

  final Duration grace;

  bool _seen = false;
  DateTime? _goneSince;

  /// Whether the host is missing now, after having been here.
  bool get away => _goneSince != null;

  /// A presence sync at [now]. A guest that arrived before the host's
  /// presence was synced has not seen the host yet and does not wait.
  HostPresenceChange update({required bool hostHere, required DateTime now}) {
    if (hostHere) {
      _seen = true;
      if (_goneSince == null) return HostPresenceChange.none;
      _goneSince = null;
      return HostPresenceChange.back;
    }
    if (!_seen || _goneSince != null) return HostPresenceChange.none;
    _goneSince = now;
    return HostPresenceChange.away;
  }

  /// Whether the host has been missing for the whole grace period at [now].
  bool expired(DateTime now) {
    final DateTime? since = _goneSince;
    return since != null && now.difference(since) >= grace;
  }

  void reset() {
    _seen = false;
    _goneSince = null;
  }
}

/// Which member of the room may end it, change what it watches, or move it
/// when only the host may.
///
/// Every invited account can send anything on a room's channel, and a
/// message names its own sender. Receivers used to take a message's word for
/// it: anyone could send `end`, a `state` with a link of their choosing that
/// every guest then opened, or a `sync` marked as the host's to get past
/// 只有房主能控制播放. The host is now the member whose `state` answered this
/// device's `hello` when it joined, and only that member's `end`, `state`
/// and syncs count as the host's.
///
/// This holds against a member who claims to be the host; it cannot hold
/// against one who copies the host's id out of the room, since Realtime does
/// not say who sent a broadcast. Only the room's members know its code.
class PartyAuthority {
  String? _hostId;

  /// The host's client id, once known.
  String? get hostId => _hostId;

  /// This device opened the room.
  void hostIsMe(String clientId) => _hostId = clientId;

  /// A `state` from [from]: the first one fixes who the host is.
  bool acceptState(String? from) {
    if (from == null || from.isEmpty) return false;
    final String? host = _hostId;
    if (host == null) {
      _hostId = from;
      return true;
    }
    return from == host;
  }

  /// An `end` from [from].
  bool acceptEnd(String? from) => from != null && from == _hostId;

  /// A play, pause or seek from [from]: the host's always, anyone else's
  /// only while [guestsCanControl].
  bool acceptSync(String? from, {required bool guestsCanControl}) =>
      isHost(from) || guestsCanControl;

  /// Whether [id] is the host's client id.
  bool isHost(String? id) => id != null && _hostId != null && id == _hostId;

  void reset() => _hostId = null;
}
