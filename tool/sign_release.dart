// Signs a release's SHA256SUMS so the in-app updater can tell Lumora's own
// releases from anything else published under the repository.
//
//   dart run tool/sign_release.dart --init <private-key-file>
//       makes a key pair (once); prints the public key for
//       lib/services/updater/release_signature.dart.
//   dart run tool/sign_release.dart <private-key-file> <SHA256SUMS>
//       writes <SHA256SUMS>.sig next to it; upload both with the release.
//
// The private key never goes in the repository.
import 'dart:convert';
import 'dart:io';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

void main(List<String> args) {
  if (args.length == 2 && args[0] == '--init') {
    final file = File(args[1]);
    if (file.existsSync()) {
      stderr.writeln('${file.path} already exists; not overwriting it.');
      exit(1);
    }
    final pair = ed.generateKey();
    file.writeAsStringSync(base64.encode(pair.privateKey.bytes));
    stdout.writeln('public key: ${base64.encode(pair.publicKey.bytes)}');
    return;
  }
  if (args.length != 2) {
    stderr.writeln('usage: sign_release.dart [--init] <key> [SHA256SUMS]');
    exit(64);
  }
  final key = ed.PrivateKey(base64.decode(File(args[0]).readAsStringSync().trim()));
  final sums = File(args[1]);
  final signature = ed.sign(key, sums.readAsBytesSync());
  File('${sums.path}.sig').writeAsStringSync(base64.encode(signature));
  stdout.writeln('wrote ${sums.path}.sig');
}
