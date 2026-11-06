import 'dart:async';

import 'package:flutter/foundation.dart';

import '../subtitles/subtitle_parser.dart';

/// Reads the lines of the video's own subtitle track while it plays, so the
/// downloaded subtitle can be compared with a subtitle that is known to be in
/// time (the container's, cut for this very video).
///
/// libmpv is the only way to get them: the audio filters that could have
/// measured the sound (`astats` and the like) are not in the libmpv this app
/// ships, so there is no audio to listen to on mpv. Its secondary subtitle
/// track is the way in. The embedded track is selected as the secondary one,
/// hidden, and mpv reports each line's start and end as it comes up
/// (`secondary-sub-start`/`-end`). Those are the cue's own times, not shifted
/// by `sub-delay` or `sub-speed`, so what is read here is the track exactly
/// as the file has it, whatever timing the viewer gave the downloaded one.
///
/// It only reads lines and never shows them, so it does not change what the
/// viewer sees or hears.
class MpvSubtitleReference {
  MpvSubtitleReference(this._platform);

  /// The media_kit `NativePlayer`, kept dynamic like the rest of the player
  /// screen's property access so a Media3-only build never touches it.
  final dynamic _platform;

  static const String _observed = 'secondary-sub-text';

  /// Text subtitle codecs. Picture-based tracks (PGS, DVD, DVB) have no text
  /// for mpv to report.
  static const Set<String> textCodecs = {
    'subrip',
    'srt',
    'ass',
    'ssa',
    'mov_text',
    'webvtt',
    'text',
    'subviewer',
    'subviewer1',
    'microdvd',
    'jacosub',
    'sami',
    'realtext',
    'stl',
    'vplayer',
    'pjs',
    'mpl2',
  };

  /// The most lines kept; a feature film has 2000 or so.
  static const int _maxCues = 4000;

  final List<SubCue> _cues = <SubCue>[];
  final Set<int> _seen = <int>{};
  bool _running = false;
  int _run = 0;
  String _lastText = '';

  /// Told of each new line.
  VoidCallback? onCue;

  bool get isRunning => _running;
  List<SubCue> get cues => List<SubCue>.unmodifiable(_cues);
  int get cueCount => _cues.length;

  /// Picks one of the file's own text tracks and starts reading it. Returns
  /// false when there is none (or this is not libmpv), in which case nothing
  /// was changed.
  Future<bool> start() async {
    final platform = _platform;
    if (platform == null || _running) return _running;
    final run = ++_run;
    try {
      final track = await _pickTrack();
      if (track == null || run != _run) return false;
      _cues.clear();
      _seen.clear();
      _lastText = '';
      // The secondary track is mpv's, not the app's: hidden, and with its
      // own delay at zero so a `sub-delay` older libmpv shared between the
      // two cannot move what is read.
      await platform.setProperty('secondary-sid', track.toString());
      await platform.setProperty('secondary-sub-visibility', 'no');
      try {
        await platform.setProperty('secondary-sub-delay', '0');
      } catch (_) {}
      // `observeProperty` refuses a second observer of one property; a
      // restart after a source change arrives here with the old one gone,
      // but make sure.
      try {
        await platform.unobserveProperty(_observed);
      } catch (_) {}
      await platform.observeProperty(_observed, _onText);
      _running = true;
      debugPrint('[SubAutoSync] reading embedded subtitle track $track');
      return true;
    } catch (e) {
      debugPrint('[SubAutoSync] embedded reference unavailable: $e');
      return false;
    }
  }

  /// Stops reading and lets go of the secondary track.
  Future<void> stop() async {
    _run++;
    if (!_running) return;
    _running = false;
    final platform = _platform;
    try {
      await platform.unobserveProperty(_observed);
    } catch (_) {}
    try {
      await platform.setProperty('secondary-sid', 'no');
    } catch (_) {}
  }

  /// The file's own text subtitle track to read, or null: not the one the
  /// viewer is watching, not a downloaded one, not a forced-lines-only one.
  Future<int?> _pickTrack() async {
    final platform = _platform;
    final count =
        int.tryParse(
          await platform.getProperty('track-list/count') as String,
        ) ??
        0;
    final primary = int.tryParse(await platform.getProperty('sid') as String);
    int? best;
    var bestRank = 1 << 30;
    for (var i = 0; i < count; i++) {
      Future<String> prop(String k) async =>
          (await platform.getProperty('track-list/$i/$k')) as String;
      if (await prop('type') != 'sub') continue;
      if (await prop('external') == 'yes') continue;
      final codec = (await prop('codec')).toLowerCase();
      if (!textCodecs.contains(codec)) continue;
      final id = int.tryParse(await prop('id'));
      if (id == null || id == primary) continue;
      final title = (await prop('title')).toLowerCase();
      // Forced tracks carry only the foreign-language lines; commentary and
      // signs tracks are sparse. The rest are all the whole dialogue.
      var rank = 10;
      if (title.contains('forced') || title.contains('强制')) rank = 100;
      if (title.contains('sign') || title.contains('song')) rank = 90;
      if (title.contains('commentary')) rank = 95;
      if (await prop('default') == 'yes') rank -= 1;
      if (rank < bestRank) {
        bestRank = rank;
        best = id;
      }
    }
    return best;
  }

  Future<void> _onText(String text) async {
    // mpv tells the observer on every playback tick, not only when the line
    // changes.
    if (text.isEmpty) {
      _lastText = '';
      return;
    }
    if (text == _lastText) return;
    final platform = _platform;
    final start = double.tryParse(
      await platform.getProperty('secondary-sub-start') as String,
    );
    final end = double.tryParse(
      await platform.getProperty('secondary-sub-end') as String,
    );
    if (start == null || end == null) return;
    _lastText = text;
    if (!(end > start) || end - start > 30) return;
    // Two lines never start at the same millisecond on one track.
    if (!_seen.add((start * 1000).round())) return;
    if (_cues.length >= _maxCues) return;
    _cues.add(SubCue(start: start, end: end, text: text));
    onCue?.call();
  }
}
