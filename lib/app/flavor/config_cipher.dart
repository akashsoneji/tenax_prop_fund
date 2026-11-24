import 'dart:convert';
import 'dart:typed_data';

/// Scrambles the flavor config so release binaries carry one opaque base64
/// blob instead of readable URLs and keys.
///
/// This is obfuscation, not secrecy: the key ships in the same binary, so a
/// determined attacker who runs the app can still recover the values. It stops
/// `strings` / decompiler dumps from showing them at a glance. Pure Dart (no
/// Flutter import) so `tool/encode_flavor_config.dart` can share it.
class ConfigCipher {
  const ConfigCipher._();

  static String encode(String plain, List<int> key) =>
      base64.encode(_apply(utf8.encode(plain), key));

  static String decode(String blob, String keyBase64) =>
      utf8.decode(_apply(base64.decode(blob), base64.decode(keyBase64)));

  /// XORs [input] with a keystream from a key-seeded xorshift32 generator
  /// mixed with the key bytes. Symmetric: applying it twice restores input.
  static Uint8List _apply(List<int> input, List<int> key) {
    if (key.isEmpty) throw ArgumentError('ConfigCipher key must not be empty');

    var state = 0x811C9DC5;
    for (final byte in key) {
      state = ((state ^ byte) * 0x01000193) & 0xFFFFFFFF;
    }
    if (state == 0) state = 1;

    final out = Uint8List(input.length);
    for (var i = 0; i < input.length; i++) {
      state ^= (state << 13) & 0xFFFFFFFF;
      state ^= state >> 17;
      state ^= (state << 5) & 0xFFFFFFFF;
      out[i] = input[i] ^ (state & 0xFF) ^ key[i % key.length];
    }
    return out;
  }
}
