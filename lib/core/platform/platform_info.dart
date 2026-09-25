import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place to branch on platform for native look-and-feel. iOS gets
/// Cupertino-style controls; everything else gets Material. Widgets read this
/// instead of scattering Platform checks.
class PlatformInfo {
  const PlatformInfo._();

  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Value sent as `device_name` when creating a session — the backend lists it
  /// under the user's active sessions, so it must name the platform.
  static String get deviceName {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return Platform.operatingSystem;
  }
}