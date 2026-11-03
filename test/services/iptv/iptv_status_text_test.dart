import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/l10n/generated/app_localizations.dart';
import 'package:zplay/services/iptv/iptv_controller.dart';
import 'package:zplay/services/iptv/iptv_network.dart';

final _ascii = RegExp(r'^[\x00-\x7F]*$');

void main() {
  final zh = lookupAppLocalizations(const Locale('zh'));
  final en = lookupAppLocalizations(const Locale('en'));

  String summary(
    AppLocalizations l10n, {
    int found = 0,
    bool exhausted = false,
    bool canGetMore = false,
    int queued = 0,
  }) => IptvController.scrapeSummary(
    l10n,
    found: found,
    target: 5,
    exhausted: exhausted,
    canGetMore: canGetMore,
    queued: queued,
  );

  test('every portal search outcome has its own line', () {
    expect(summary(en, exhausted: true), en.tvStatusSourceEmpty);
    expect(summary(en, canGetMore: true), en.tvStatusNoNewTryAgain);
    expect(summary(en), en.tvStatusNoNew);
    expect(summary(en, found: 5), en.tvStatusFoundPortals(5));
    expect(
      summary(en, found: 2, exhausted: true),
      en.tvStatusFoundPortalsExhausted(2),
    );
    expect(summary(en, found: 2), en.tvStatusFoundPortalsStopped(2));
    expect(
      summary(en, found: 5, queued: 7),
      '${en.tvStatusFoundPortals(5)} ${en.tvStatusMoreQueued(7)}',
    );
  });

  test('the Chinese lines are Chinese', () {
    for (final line in [
      summary(zh, exhausted: true),
      summary(zh, canGetMore: true),
      summary(zh, found: 2, queued: 3),
      zh.tvStatusScrapeFailed,
      zh.tvStatusNoMatches,
      zh.tvStatusAliveNoNew(3),
      zh.tvStatusStreamsReady(1),
      zh.tvAddLoginFailed,
    ]) {
      expect(_ascii.hasMatch(line), isFalse, reason: line);
    }
  });

  test('stream counts read naturally in English', () {
    expect(en.tvStatusStreamsReady(1), '1 live stream ready.');
    expect(en.tvStatusStreamsReady(3), '3 live streams ready.');
  });

  test('portal sources are named in the app language', () {
    expect(CatalogSource.cloudVault.label, isNotEmpty);
    expect(CatalogSource.reddit.description, isNotEmpty);
  });
}
