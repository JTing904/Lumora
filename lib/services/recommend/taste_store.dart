import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../account/library_sync.dart';
import '../account/account_scope.dart';

/// What makes a title the kind of title it is, for taste: where it is from,
/// whether it is animated, and whether it is a series or a film.
@immutable
class TasteFacets {
  const TasteFacets({
    required this.region,
    required this.animated,
    required this.series,
    this.genres = const [],
  });

  /// The first origin country TMDb lists ('CN', 'HK', 'JP', 'KR', 'US' ...),
  /// or '' when it lists none.
  final String region;
  final bool animated;
  final bool series;

  /// TMDb genre ids.
  final List<int> genres;

  /// The kind of title as one key: "CN|anim|tv" is 国漫, "HK|live|tv" is 港剧,
  /// "US|live|movie" is a Hollywood film.
  String get key =>
      '$region|${animated ? 'anim' : 'live'}|${series ? 'tv' : 'movie'}';

  Map<String, Object?> toJson() => {
    'r': region,
    'a': animated,
    's': series,
    'g': genres,
  };

  static TasteFacets? fromJson(Object? json) {
    if (json is! Map) return null;
    return TasteFacets(
      region: json['r']?.toString() ?? '',
      animated: json['a'] == true,
      series: json['s'] == true,
      genres: [
        for (final g in (json['g'] as List? ?? const []))
          if (g is int) g,
      ],
    );
  }
}

/// One title in the viewer's history, with every signal it has given.
@immutable
class TasteEntry {
  const TasteEntry({
    required this.id,
    required this.title,
    required this.series,
    required this.firstSeen,
    required this.lastSeen,
    this.progress = 0,
    this.finished = false,
    this.listed = false,
    this.rating = 0,
    this.facets,
  });

  /// The IMDb id the app plays the title by.
  final String id;
  final String title;
  final bool series;

  /// The furthest the viewer got, 0 to 1.
  final double progress;
  final bool finished;

  /// On 片单.
  final bool listed;

  /// 👍 is 1, 👎 is -1.
  final int rating;
  final DateTime firstSeen;
  final DateTime lastSeen;

  /// Looked up on TMDb after the entry is made; null until then.
  final TasteFacets? facets;

  TasteEntry copyWith({
    double? progress,
    bool? finished,
    bool? listed,
    int? rating,
    DateTime? lastSeen,
    TasteFacets? facets,
    String? title,
  }) => TasteEntry(
    id: id,
    title: title ?? this.title,
    series: series,
    firstSeen: firstSeen,
    lastSeen: lastSeen ?? this.lastSeen,
    progress: progress ?? this.progress,
    finished: finished ?? this.finished,
    listed: listed ?? this.listed,
    rating: rating ?? this.rating,
    facets: facets ?? this.facets,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    't': title,
    's': series,
    'p': progress,
    'f': finished,
    'l': listed,
    'r': rating,
    'fs': firstSeen.millisecondsSinceEpoch,
    'ls': lastSeen.millisecondsSinceEpoch,
    if (facets != null) 'x': facets!.toJson(),
  };

  static TasteEntry? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String) return null;
    DateTime at(Object? v) =>
        DateTime.fromMillisecondsSinceEpoch(v is int ? v : 0);
    return TasteEntry(
      id: json['id'] as String,
      title: json['t']?.toString() ?? '',
      series: json['s'] == true,
      progress: (json['p'] as num?)?.toDouble() ?? 0,
      finished: json['f'] == true,
      listed: json['l'] == true,
      rating: (json['r'] as num?)?.toInt() ?? 0,
      firstSeen: at(json['fs']),
      lastSeen: at(json['ls']),
      facets: TasteFacets.fromJson(json['x']),
    );
  }
}

/// The viewer's taste history, on this device.
///
/// Kept local for now; it is what syncs to the account once sign-in exists.
/// Capped to the [maxEntries] most recently seen titles.
abstract final class TasteStore {
  static const String _storageKey = 'lumora_taste_v1';
  static const int maxEntries = 400;

  static final ValueNotifier<Map<String, TasteEntry>> entries =
      ValueNotifier<Map<String, TasteEntry>>(const {});

  /// Loads the signed-in account's history (see [AccountScope]).
  static Future<void> initialize() async {
    entries.value = const {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AccountScope.key(_storageKey));
      if (raw == null) {
        entries.value = const {};
        return;
      }
      _apply(jsonDecode(raw));
    } catch (_) {}
  }

  static void _apply(Object? list) {
    if (list is! List) return;
    entries.value = {
      for (final e in list.map(TasteEntry.fromJson).whereType<TasteEntry>())
        e.id: e,
    };
  }

  /// The history as the account keeps it on the server.
  static Object? exportDocument() => [
    for (final e in entries.value.values) e.toJson(),
  ];

  /// Takes the account's history from the server.
  static Future<void> importDocument(Object? data) async {
    if (data is! List) return;
    _apply(data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AccountScope.key(_storageKey),
      jsonEncode(exportDocument()),
    );
  }

  /// Applies [change] to the entry for [id], creating it if it is new.
  static void update(
    String id, {
    required String title,
    required bool series,
    required TasteEntry Function(TasteEntry entry) change,
    DateTime? now,
  }) {
    if (id.isEmpty) return;
    final at = now ?? DateTime.now();
    final current =
        entries.value[id] ??
        TasteEntry(
          id: id,
          title: title,
          series: series,
          firstSeen: at,
          lastSeen: at,
        );
    final next = change(current);
    final map = Map<String, TasteEntry>.from(entries.value)..[id] = next;
    if (map.length > maxEntries) {
      final oldest = map.values.toList()
        ..sort((a, b) => a.lastSeen.compareTo(b.lastSeen));
      for (final e in oldest.take(map.length - maxEntries)) {
        map.remove(e.id);
      }
    }
    entries.value = map;
    _persist();
  }

  /// A playback progress report: the furthest point, and finished at 90%.
  static void recordProgress(
    String id, {
    required String title,
    required bool series,
    required double progress,
    DateTime? now,
  }) {
    update(
      id,
      title: title,
      series: series,
      now: now,
      change: (e) => e.copyWith(
        title: title,
        progress: progress > e.progress ? progress : e.progress,
        finished: e.finished || progress >= 0.9,
        lastSeen: now ?? DateTime.now(),
      ),
    );
  }

  static void recordListed(
    String id, {
    required String title,
    required bool series,
    required bool listed,
  }) {
    update(
      id,
      title: title,
      series: series,
      change: (e) => e.copyWith(listed: listed, lastSeen: DateTime.now()),
    );
  }

  /// 👍 (1), 👎 (-1) or neither (0).
  static void recordRating(
    String id, {
    required String title,
    required bool series,
    required int rating,
  }) {
    update(
      id,
      title: title,
      series: series,
      change: (e) => e.copyWith(rating: rating, lastSeen: DateTime.now()),
    );
  }

  static void setFacets(String id, TasteFacets facets) {
    final entry = entries.value[id];
    if (entry == null) return;
    entries.value = Map<String, TasteEntry>.from(entries.value)
      ..[id] = entry.copyWith(facets: facets);
    _persist();
  }

  static void _persist() {
    final encoded = jsonEncode([
      for (final e in entries.value.values) e.toJson(),
    ]);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(AccountScope.key(_storageKey), encoded))
        .then((_) => LibrarySync.changed('taste'))
        .catchError((_) {});
  }

  @visibleForTesting
  static void resetForTesting() => entries.value = const {};
}
