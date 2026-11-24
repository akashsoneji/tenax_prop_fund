// Usage: dart run tool/encode_flavor_config.dart <flavor> [env]
//
// Reads config/flavors/<flavor>.json and writes build/secure_defines/<flavor>.json
// holding only FLAVOR, ENV and the scrambled config (CFG_BLOB + CFG_KEY). Pass
// that file to `flutter build --dart-define-from-file` so release binaries do
// not contain the client's URLs and keys as plain strings. A fresh random key
// is generated on every run.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:tenax_prop_flutter/app/flavor/config_cipher.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/encode_flavor_config.dart <flavor> [env]');
    exit(64);
  }
  final flavor = args[0];
  final env = args.length > 1 ? args[1] : 'production';

  final source = File('config/flavors/$flavor.json');
  if (!source.existsSync()) {
    stderr.writeln('Unknown flavor: $flavor (no ${source.path})');
    exit(66);
  }
  final config = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;

  final random = Random.secure();
  final key = List<int>.generate(32, (_) => random.nextInt(256));
  final blob = ConfigCipher.encode(jsonEncode(config), key);

  final output = File('build/secure_defines/$flavor.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode({
      'FLAVOR': flavor,
      'ENV': env,
      'CFG_BLOB': blob,
      'CFG_KEY': base64.encode(key),
    }));

  final hashes = (config['SIGNING_CERT_HASHES'] as String? ?? '').trim();
  if (hashes.isEmpty) {
    stderr.writeln(
      'WARNING: SIGNING_CERT_HASHES is empty in ${source.path}. '
      'Tamper (re-sign) detection stays OFF until the Play App Signing '
      'certificate SHA-256 is added.',
    );
  }
  stdout.writeln('Wrote ${output.path}');
}
