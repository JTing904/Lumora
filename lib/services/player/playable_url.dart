/// Whether [url] is a stream address the player may open.
///
/// Sources hand the player addresses from third-party sites and playlists.
/// mpv also understands its own protocols (`edl://`, `lavf://`, `memory://`,
/// `av://`...), which read or build media from other inputs; none of those is
/// a stream a source should send, so only network streams and local files
/// pass.
bool isPlayableUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  // A downloaded file: `C:\...` or `/storage/...`. A network share
  // (`\\server\...`) is not: opening one sends the viewer's Windows login.
  if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(trimmed) ||
      (trimmed.startsWith('/') && !trimmed.startsWith('//'))) {
    return true;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return false;
  return const {
    'http',
    'https',
    'file',
    'rtmp',
    'rtmps',
    'rtsp',
    'rtp',
    'udp',
  }.contains(uri.scheme.toLowerCase());
}
