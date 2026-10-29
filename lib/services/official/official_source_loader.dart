/// Turns a watch screen's title and episode into "Official on YouTube" rows.
///
/// The Flutter-side half of [OfficialYouTubeSource]: it gathers the show's
/// names (the addon's English name, TMDb's simplified and traditional Chinese
/// and original titles), works out the running episode number from the
/// seasons before this one, and dresses each match as a [StreamSource] the
/// source list can draw. The row carries no stream URL - only the watch URL as
/// `externalUrl` and [OfficialYouTubeSource.providerId] - so the auto-picker
/// and the player's fallback chain can never treat it as a stream.
library;

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import '../../l10n/generated/app_localizations.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/movie/video.dart';
import '../../models/stream/stream_model.dart';
import '../metadata/episode_art.dart';
import '../metadata/title_kind_service.dart';
import 'official_episode_matcher.dart';
import 'official_youtube_source.dart';

abstract final class OfficialSourceLoader {
  static const Duration _nameTimeout = Duration(seconds: 4);

  /// Whether [source] is an official-upload row.
  static bool isOfficial(StreamSource source) =>
      source.providerId == OfficialYouTubeSource.providerId;

  /// `behaviorHints` key set on a row that is a multi-episode compilation.
  static const String compilationHint = 'officialCompilation';

  /// Whether [source] is an official multi-episode compilation, which records
  /// no progress (see `OfficialProgressTracker`).
  static bool isCompilation(StreamSource source) =>
      isOfficial(source) && source.behaviorHints?[compilationHint] == true;

  /// The official row's addon name in every app language. A saved session
  /// keeps the name in the language the app had when it was saved.
  static Set<String> get officialAddonNames => {
    for (final locale in AppLocalizations.supportedLocales)
      lookupAppLocalizations(locale).officialYouTubeName,
  };

  /// Whether a saved session's [addonName] is an official-upload row's.
  static bool isOfficialAddonName(String? addonName) =>
      addonName != null && officialAddonNames.contains(addonName);

  /// The YouTube video id an official row plays, or null for any other row.
  static String? videoIdOf(StreamSource source) {
    if (!isOfficial(source)) return null;
    final url = source.externalUrl;
    if (url == null) return null;
    final id = Uri.tryParse(url)?.queryParameters['v'];
    return id != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)
        ? id
        : null;
  }

  /// The official rows for [detail] / [episode]; empty when there are none
  /// or anything failed.
  static Future<List<StreamSource>> load({
    required MovieDetail detail,
    required Video? episode,
    required String type,
    required AppLocalizations l10n,
    OfficialYouTubeSource? source,
  }) async {
    try {
      final isEpisode = episode != null && episode.episode != null;
      final names = await _names(detail, type);
      final season = isEpisode ? episode.season : null;
      final query = OfficialQuery(
        names: names,
        season: season,
        episode: isEpisode ? episode.episode : null,
        previousSeasonsEpisodes: isEpisode
            ? await _episodesBefore(detail, season, episode.episode!)
            : null,
      );
      final matches = await (source ?? OfficialYouTubeSource.instance).find(
        query,
        region: PlatformDispatcher.instance.locale.countryCode,
      );
      return [for (final m in matches) _row(m, l10n)];
    } catch (_) {
      return const <StreamSource>[];
    }
  }

  static Future<List<String>> _names(MovieDetail detail, String type) async {
    final names = <String>[
      detail.name,
      if (detail.localName != null) detail.localName!,
    ];
    Future<TitleKindFacts?> facts(String language) =>
        TitleKindService.forImdbId(
          detail.id,
          type: type,
          language: language,
        ).timeout(_nameTimeout, onTimeout: () => null).catchError((_) => null);

    final found = await Future.wait([
      facts('en-US'),
      facts('zh-CN'),
      facts('zh-TW'),
    ]);
    for (final f in found) {
      if (f == null) continue;
      if (f.localTitle != null) names.add(f.localTitle!);
      if (f.originalTitle != null) names.add(f.originalTitle!);
    }
    return names;
  }

  /// Regular episodes in the seasons before [season], from the detail's own
  /// episode list; null when [season] is the first or nothing is known.
  /// How many episodes air before [season]x[episode], for the running
  /// number official channels title uploads with.
  ///
  /// TMDb's air order first ([EpisodeArt.runningNumber]): summing the addon's
  /// earlier seasons undercounts whenever the addon files episodes as
  /// specials, and every later episode then played the wrong upload.
  static Future<int?> _episodesBefore(
    MovieDetail detail,
    int? season,
    int episode,
  ) async {
    if (season != null && season > 1) {
      final running = await EpisodeArt.runningNumber(
        detail,
        season: season,
        episode: episode,
      ).timeout(_nameTimeout, onTimeout: () => null);
      if (running != null) {
        final before = running - episode;
        return before > 0 ? before : null;
      }
    }
    return _previousSeasonsEpisodes(detail, season);
  }

  static int? _previousSeasonsEpisodes(MovieDetail detail, int? season) {
    if (season == null || season <= 1) return null;
    var count = 0;
    for (final v in detail.videos) {
      final s = v.season;
      if (s != null && s > 0 && s < season && v.episode != null) count++;
    }
    return count == 0 ? null : count;
  }

  static StreamSource _row(OfficialMatch m, AppLocalizations l10n) {
    final channel = m.channel?.name ?? m.upload.channelName ?? '';
    final note =
        m.kind == OfficialMatchKind.compilation &&
            m.rangeStart != null &&
            m.rangeEnd != null
        ? '${l10n.officialYouTubeCompilation(m.rangeStart!, m.rangeEnd!)}\n'
              '${l10n.officialYouTubeRowNote}'
        : l10n.officialYouTubeRowNote;
    return StreamSource(
      name: channel.isEmpty
          ? l10n.officialYouTubeName
          : '${l10n.officialYouTubeName} · $channel',
      title: m.upload.title,
      description: note,
      externalUrl: OfficialYouTubeSource.watchUrl(m.upload.videoId),
      addonName: l10n.officialYouTubeName,
      providerId: OfficialYouTubeSource.providerId,
      providerName: channel,
      behaviorHints: m.kind == OfficialMatchKind.compilation
          ? const {compilationHint: true}
          : null,
    );
  }
}
