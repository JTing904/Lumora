import '../stream/stream_model.dart';

class Video {
  final String id;
  final String title;
  final int? season;
  final int? episode;
  final String? released;
  final String? thumbnail;
  final String? overview;
  final List<StreamSource> streams;

  /// The number viewers know this episode by when it differs from
  /// [episode]: a donghua the addon splits into seasons but TMDb (and its
  /// audience) counts straight through - 凡人修仙传 S8E22 is 第194集. Display
  /// only; [season] and [episode] stay what the addon and the sources use.
  final int? displayNumber;

  /// The number to show for this episode.
  int? get shownNumber => displayNumber ?? episode;

  Video({
    required this.id,
    required this.title,
    this.season,
    this.episode,
    this.released,
    this.thumbnail,
    this.overview,
    this.streams = const [],
    this.displayNumber,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    int? parseNum(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    final rawStreams = json['streams'] as List<dynamic>?;
    final parsedStreams = rawStreams != null
        ? rawStreams
              .whereType<Map>()
              .map(
                (s) => StreamSource.fromJson(
                  Map<String, dynamic>.from(s),
                  'TorBox',
                ),
              )
              .toList()
        : const <StreamSource>[];

    return Video(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Episode',
      season: parseNum(json['season']),
      episode: parseNum(json['episode'] ?? json['number']),
      released: json['released']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      overview: json['overview']?.toString() ?? json['description']?.toString(),
      streams: parsedStreams,
    );
  }
}
