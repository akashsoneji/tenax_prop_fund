import 'package:package_info_plus/package_info_plus.dart';

/// Cached access to the installed app version/build/package name.
/// Mirrors the white_label `AppVersionService` — same singleton shape so the
/// business logic that reads it stays identical.
class AppVersionService {
  AppVersionService._();

  static AppVersionService? _instance;
  static AppVersionService get instance => _instance ??= AppVersionService._();

  PackageInfo? _info;
  bool _loading = false;

  Future<void> initialize() async {
    if (_info != null || _loading) return;
    _loading = true;
    try {
      _info = await PackageInfo.fromPlatform();
    } finally {
      _loading = false;
    }
  }

  Future<String> getVersion() async {
    await initialize();
    return _info?.version ?? '1.0.0';
  }

  Future<String> getBuildNumber() async {
    await initialize();
    return _info?.buildNumber ?? '1';
  }

  Future<String> getPackageName() async {
    await initialize();
    return _info?.packageName ?? '';
  }
}
