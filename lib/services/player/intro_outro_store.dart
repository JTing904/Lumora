import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/player/skip_segment_model.dart';

/// Where a show's opening ends and how long its closing runs, as the viewer
/// marked them in the player (跳过片头片尾).
///
/// IntroDB knows few Chinese titles, so a series' own times are set once by
/// hand and apply to every episode of it.
@immutable
class IntroOutro {
  const IntroOutro({this.introEnd, this.outroLength});

  /// The opening runs from 0 to here.
  final Duration? introEnd;

  /// The closing is this long, counted back from the end.
  final Duration? outroLength;

  bool get isEmpty => introEnd == null && outroLength == null;

  /// The marks as skip segments for an episode of [duration].
  List<MediaSkipSegment> segments(Duration duration) => [
    if (introEnd case final end? when end > Duration.zero)
      MediaSkipSegment(type: 'intro', startMs: 0, endMs: end.inMilliseconds),
    if (outroLength case final len?
        when duration > Duration.zero && len < duration)
      MediaSkipSegment(
        type: 'credits',
        startMs: (duration - len).inMilliseconds,
      ),
  ];
}

abstract final class IntroOutroStore {
  static const _prefix = 'lumora_intro_outro_';
  static const _autoSkipKey = 'lumora_auto_skip_intro';

  /// Jump over a marked opening without asking. On by default: whoever
  /// marked it wants it gone.
  static final ValueNotifier<bool> autoSkip = ValueNotifier(true);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    autoSkip.value = prefs.getBool(_autoSkipKey) ?? true;
  }

  static Future<void> setAutoSkip(bool value) async {
    autoSkip.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSkipKey, value);
  }

  static Future<IntroOutro> forShow(String showId) async {
    final prefs = await SharedPreferences.getInstance();
    final intro = prefs.getInt('$_prefix${showId}_intro');
    final outro = prefs.getInt('$_prefix${showId}_outro');
    return IntroOutro(
      introEnd: intro == null ? null : Duration(milliseconds: intro),
      outroLength: outro == null ? null : Duration(milliseconds: outro),
    );
  }

  static Future<void> save(String showId, IntroOutro value) async {
    final prefs = await SharedPreferences.getInstance();
    Future<void> put(String key, Duration? d) =>
        d == null ? prefs.remove(key) : prefs.setInt(key, d.inMilliseconds);
    await put('$_prefix${showId}_intro', value.introEnd);
    await put('$_prefix${showId}_outro', value.outroLength);
  }
}
