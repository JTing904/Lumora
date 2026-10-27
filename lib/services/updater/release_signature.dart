import 'dart:convert';
import 'dart:typed_data';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

/// Lumora's release-signing public key. Its private half signs each release's
/// `SHA256SUMS` (see tool/sign_release.dart) and lives outside the
/// repository, so a release someone else manages to publish under the repo
/// does not verify.
const String _releasePublicKey = 'qICTInWzZlD/Znhn+DzwoqZU+012VBoUhIgtXTJDaXg=';

/// Whether [signatureBase64] is Lumora's signature over [manifest], the exact
/// bytes of a release's `SHA256SUMS`.
bool releaseManifestSigned(List<int> manifest, String signatureBase64) {
  try {
    final key = ed.PublicKey(base64.decode(_releasePublicKey));
    return ed.verify(
      key,
      Uint8List.fromList(manifest),
      base64.decode(signatureBase64.trim()),
    );
  } catch (_) {
    return false;
  }
}
