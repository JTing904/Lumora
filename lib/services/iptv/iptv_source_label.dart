import '../../l10n/l10n.dart';
import '../../models/iptv/iptv_models.dart';

/// The name a stream's source goes by on screen.
///
/// An Xtream portal has no display name of its own: `VerifiedPortal.name` is
/// the `user_info.username` the panel answered with, so it and
/// `portal.username` are both the login of the account. The sources list and
/// the player used to print that next to every stream. Outside the screens
/// where the user manages their own portals, a portal is named by its server
/// host instead, or "Server N" when there is no host. A playlist entry has no
/// account, and its `name` is the label the app wrote ("Free Sports
/// (iptv-org)", "Your playlist: …"), so that is kept.
abstract final class IptvSourceLabel {
  /// [position] is the 1-based number used when nothing else names the
  /// source.
  static String of(VerifiedPortal portal, {required int position}) {
    final fallback = l10nCurrent().tv2ServerNumber(position);
    return labelFor(
      username: portal.portal.username,
      name: portal.name,
      url: portal.portal.url,
      fallback: fallback,
    );
  }

  /// [of] without the localized fallback, for tests.
  static String labelFor({
    required String username,
    required String name,
    required String url,
    required String fallback,
  }) {
    final login = username.trim().toLowerCase();
    if (login.isEmpty) {
      // A playlist: its name is the app's own label, but never print a URL,
      // which can carry a token.
      final label = name.trim();
      if (label.isNotEmpty && !_looksLikeUrl(label)) return label;
      return _host(url) ?? fallback;
    }
    final host = _host(url);
    if (host == null || host.toLowerCase().contains(login)) return fallback;
    return host;
  }

  static bool _looksLikeUrl(String text) => text.contains('://');

  static String? _host(String url) {
    final uri = Uri.tryParse(url.trim());
    var host = uri?.host ?? '';
    if (host.isEmpty) return null;
    if (host.startsWith('www.')) host = host.substring(4);
    return host;
  }
}
