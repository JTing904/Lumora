/// Turns a film's names and year into "Internet Archive · Public domain" rows.
///
/// The Flutter-side half of [InternetArchiveSource]: it gathers the film's
/// English names (the addon's name, TMDb's English and original titles),
/// reads the year, and dresses each match as a [StreamSource] with the
/// Archive's own MP4 as its URL, so the row plays in the normal player.
/// Films only: the Archive's curated collections hold feature films, not
/// numbered TV episodes, and a strict title + year match cannot place an
/// episode.
library;

import '../../l10n/generated/app_localizations.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/stream/stream_model.dart';
import '../metadata/title_kind_service.dart';
import 'internet_archive_source.dart';

abstract final class ArchiveSourceLoader {
  static const Duration _nameTimeout = Duration(seconds: 4);

  /// `behaviorHints` key holding the item's licence URL.
  static const String licenceHint = 'archiveLicence';

  /// `behaviorHints` key holding the item's page, for attribution.
  static const String pageHint = 'archivePage';

  /// Whether [source] is an Internet Archive row.
  static bool isArchive(StreamSource source) =>
      source.providerId == InternetArchiveSource.providerId;

  /// The first four-digit year in an app year ("1968", "1968–1970").
  static int? yearOf(String? year) {
    if (year == null) return null;
    final m = RegExp(r'(1[89]\d\d|20\d\d)').firstMatch(year);
    return m == null ? null : int.parse(m.group(1)!);
  }

  /// The rows for [detail]; empty for a series, without a year, or when
  /// anything failed.
  static Future<List<StreamSource>> load({
    required MovieDetail detail,
    required String type,
    required AppLocalizations l10n,
    InternetArchiveSource? source,
  }) async {
    try {
      if (type != 'movie' || detail.isCollection) return const [];
      final year = yearOf(detail.year);
      if (year == null) return const [];
      final names = <String>[detail.name];
      final facts = await TitleKindService.forImdbId(
        detail.id,
        type: type,
        language: 'en-US',
      ).timeout(_nameTimeout, onTimeout: () => null).catchError((_) => null);
      if (facts?.localTitle != null) names.add(facts!.localTitle!);
      if (facts?.originalTitle != null) names.add(facts!.originalTitle!);
      final films = await (source ?? InternetArchiveSource.instance).find(
        titles: names,
        year: year,
      );
      return [for (final f in films) row(f, l10n)];
    } catch (_) {
      return const <StreamSource>[];
    }
  }

  /// The licence as the row names it.
  static String licenceLabel(ArchiveLicence licence, AppLocalizations l10n) =>
      licence.publicDomain
      ? l10n.archiveLicencePublicDomain
      : l10n.archiveLicenceCc(licence.code ?? 'BY');

  static StreamSource row(ArchiveFilm f, AppLocalizations l10n) {
    final size = f.sizeBytes == null
        ? ''
        : ' · ${(f.sizeBytes! / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    final minutes = f.length == null
        ? ''
        : ' · ${l10n.archiveMinutes(f.length!.inMinutes)}';
    return StreamSource(
      name: l10n.archiveSourceName(licenceLabel(f.licence, l10n)),
      title: '${f.title} (${f.year})$minutes$size',
      description: l10n.archiveRowNote,
      url: f.streamUrl,
      addonName: 'Internet Archive',
      providerId: InternetArchiveSource.providerId,
      providerName: 'Internet Archive',
      behaviorHints: {
        'filename': f.fileName,
        licenceHint: f.licence.url,
        pageHint: f.pageUrl,
      },
    );
  }
}
