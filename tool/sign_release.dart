// Signs a release's SHA256SUMS so the in-app updater can tell Lumora's own
// releases from anything else published under the repository.
//
//   dart run tool/sign_release.dart --init <private-key-file>
//       makes a key pair (once); prints the public key for
//       lib/services/updater/release_signature.dart.
//   dart run tool/sign_release.dart <private-key-file> <SHA256SUMS> [--version X.Y.Z]
//       first makes SHA256SUMS begin with `# lumora-version X.Y.Z` (the
//       version in pubspec.yaml when --version is left out), then writes
//       <SHA256SUMS>.sig next to it; upload both with the release.
//
// The version line is signed with the checksums: the app installs a release
// only when its signed manifest names the release's own tag, so a signed
// manifest re-published under another tag (a downgrade) is refused. Clients
// up to 1.0.x skip the line as one that is not a checksum.
//
// The private key never goes in the repository.
import 'dart:convert';
import 'dart:io';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

final RegExp _versionPattern = RegExp(r'^\d+\.\d+\.\d+(-[0-9A-Za-z.]+)?$');
final RegExp _versionLine = RegExp(r'^﻿?#\s*lumora-version\b');

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

  final positional = <String>[];
  String? version;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--version' && i + 1 < args.length) {
      version = args[++i];
    } else if (args[i].startsWith('--version=')) {
      version = args[i].substring('--version='.length);
    } else {
      positional.add(args[i]);
    }
  }
  if (positional.length != 2) {
    stderr.writeln(
      'usage: sign_release.dart --init <key>\n'
      '       sign_release.dart <key> <SHA256SUMS> [--version X.Y.Z]',
    );
    exit(64);
  }

  version = (version ?? _pubspecVersion())?.trim();
  if (version != null && version.startsWith('v')) {
    version = version.substring(1);
  }
  if (version == null || !_versionPattern.hasMatch(version)) {
    stderr.writeln('not a release version: $version (expected X.Y.Z)');
    exit(64);
  }

  final key = ed.PrivateKey(
    base64.decode(File(positional[0]).readAsStringSync().trim()),
  );
  final sums = File(positional[1]);
  sums.writeAsStringSync(withVersionLine(sums.readAsStringSync(), version));
  final signature = ed.sign(key, sums.readAsBytesSync());
  File('${sums.path}.sig').writeAsStringSync(base64.encode(signature));
  stdout.writeln('${sums.path} now names version $version');
  stdout.writeln('wrote ${sums.path}.sig');
}

/// [manifest] beginning with `# lumora-version <version>`, in place of any
/// version line it already began with.
String withVersionLine(String manifest, String version) {
  final lines = const LineSplitter().convert(manifest);
  while (lines.isNotEmpty && _versionLine.hasMatch(lines.first)) {
    lines.removeAt(0);
  }
  return [
    '# lumora-version $version',
    ...lines,
  ].map((line) => '$line\n').join();
}

/// The `version:` in pubspec.yaml, without its build number.
String? _pubspecVersion() {
  for (final pubspec in [
    File.fromUri(Platform.script.resolve('../pubspec.yaml')),
    File('pubspec.yaml'),
  ]) {
    if (!pubspec.existsSync()) continue;
    for (final line in pubspec.readAsLinesSync()) {
      final match = RegExp(r'^version:\s*([^\s+#]+)').firstMatch(line);
      if (match != null) return match.group(1);
    }
  }
  return null;
}
