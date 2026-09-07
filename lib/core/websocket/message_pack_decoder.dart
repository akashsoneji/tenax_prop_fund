import 'dart:typed_data';

import 'package:messagepack/messagepack.dart';

/// Decodes binary MessagePack frames from the `marketwatchv2` feed.
///
/// The trade engine sends ticks as MessagePack (~50-70% smaller than JSON and
/// several times faster to parse) with an optional text/JSON fallback. Server
/// payloads are arrays-of-arrays or maps; [decodeBinary] rebuilds the nested
/// Dart structure so callers see the same shape they would from `jsonDecode`.
class MessagePackDecoder {
  /// A WebSocket frame is binary when it arrives as bytes rather than a String.
  static bool isBinaryMessage(dynamic message) =>
      message is Uint8List || message is List<int>;

  /// Decodes [binaryData] to a nested Dart object, or `null` if it cannot be
  /// parsed (the caller then falls back to JSON / ignores the frame).
  static dynamic decodeBinary(Uint8List binaryData) {
    try {
      return _unpackValue(Unpacker(binaryData));
    } catch (_) {
      return null;
    }
  }

  /// Recursively unpacks one value. `messagepack` throws when the next token is
  /// not the requested type, so each type is attempted in most-likely order.
  static dynamic _unpackValue(Unpacker unpacker) {
    try {
      final length = unpacker.unpackListLength();
      return [for (var i = 0; i < length; i++) _unpackValue(unpacker)];
    } catch (_) {}

    try {
      final length = unpacker.unpackMapLength();
      final map = <String, dynamic>{};
      for (var i = 0; i < length; i++) {
        final key = unpacker.unpackString();
        if (key == null) break;
        map[key] = _unpackValue(unpacker);
      }
      return map;
    } catch (_) {}

    try {
      final str = unpacker.unpackString();
      if (str != null) return str;
    } catch (_) {}

    try {
      final dbl = unpacker.unpackDouble();
      if (dbl != null) return dbl;
    } catch (_) {}

    try {
      final intVal = unpacker.unpackInt();
      if (intVal != null) return intVal;
    } catch (_) {}

    try {
      final boolVal = unpacker.unpackBool();
      if (boolVal != null) return boolVal;
    } catch (_) {}

    return null;
  }
}
