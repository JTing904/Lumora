import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/movie/movie_detail.dart';
import '../../models/movie/video.dart';
import '../../services/account/account_service.dart';
import '../../services/metadata/metadata_service.dart';
import '../../services/party/watch_party_service.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_text_field.dart';
import '../../ui/lu_theme.dart';
import '../../utils/navigation/route_transitions.dart';
import '../player/player_screen.dart';

/// 加入一起看: asks for a room code, joins, and opens what the host is
/// watching at the host's position.
Future<void> showJoinPartyDialog(BuildContext context) async {
  if (!AccountService.signedIn) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(l10nCurrent().partyNeedSignIn)));
    return;
  }
  final media = await showDialog<PartyMedia>(
    context: context,
    builder: (ctx) => Theme(
      data: luTheme(),
      child: Dialog(
        backgroundColor: LuColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: _JoinForm(),
          ),
        ),
      ),
    ),
  );
  if (media == null || !context.mounted) return;
  await openPartyPlayer(context, media);
}

class _JoinForm extends StatefulWidget {
  const _JoinForm();

  @override
  State<_JoinForm> createState() => _JoinFormState();
}

class _JoinFormState extends State<_JoinForm> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final l10n = l10nCurrent();
    final code = WatchPartyService.normalizeCode(_code.text);
    if (!WatchPartyService.isValidCode(code)) {
      setState(() => _error = l10n.partyJoinFailed);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final media = await WatchPartyService.instance.join(code);
      if (!mounted) return;
      if (media == null) {
        setState(() {
          _busy = false;
          _error = l10n.partyJoinFailed;
        });
        return;
      }
      Navigator.of(context).pop(media);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.partyServiceDown;
        debugPrint('[WatchParty] join: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.partyJoin, style: LuText.heading),
        const SizedBox(height: 8),
        Text(l10n.partyJoinBody, style: LuText.bodySoft),
        const SizedBox(height: 16),
        LuTextField(
          label: l10n.partyJoinHint,
          controller: _code,
          code: true,
          autofocus: true,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _join(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: LuText.caption.copyWith(color: LuColors.danger)),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          alignment: WrapAlignment.end,
          children: [
            LuButton(
              label: l10n.commonCancel,
              kind: LuButtonKind.secondary,
              compact: true,
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
            ),
            LuButton(
              label: _busy ? l10n.partyJoining : l10n.partyJoinButton,
              icon: Icons.groups_rounded,
              compact: true,
              busy: _busy,
              onPressed: _join,
            ),
          ],
        ),
      ],
    );
  }
}

/// Opens the player on [media] at the room's last known position. With
/// [replace] the current route gives way, for a guest following the host
/// to another episode.
Future<void> openPartyPlayer(
  BuildContext context,
  PartyMedia media, {
  bool replace = false,
}) async {
  MovieDetail? detail;
  if (media.id.startsWith('tt')) {
    detail =
        await MetadataService.fetchMeta(
              baseUrl: 'https://v3-cinemeta.strem.io',
              type: media.type,
              imdbId: media.id,
            )
            .timeout(const Duration(seconds: 8), onTimeout: () => null)
            .catchError((Object _) => null);
  }
  detail ??= MovieDetail(
    id: media.id,
    type: media.type,
    name: media.title,
    poster: media.poster,
    background: media.backdrop,
    year: media.year,
  );

  Video? episode;
  if (media.episodeId != null || media.season != null) {
    episode = detail.videos
        .where(
          (v) =>
              v.id == media.episodeId ||
              (v.season == media.season && v.episode == media.episode),
        )
        .firstOrNull;
    episode ??= Video(
      id: media.episodeId ?? '${media.id}:${media.season}:${media.episode}',
      title: media.title,
      season: media.season,
      episode: media.episode,
    );
  }

  if (!context.mounted) return;
  final page = PlayerScreen(
    source: media.source,
    title: media.title,
    backdropUrl: media.backdrop ?? detail.background,
    detail: detail,
    episode: episode,
    initialPosition: WatchPartyService.instance.lastPlayback?.positionNow,
  );
  final route = CinematicSlideRoute(page: page);
  if (replace) {
    await Navigator.of(context).pushReplacement(route);
  } else {
    await Navigator.of(context).push(route);
  }
}
