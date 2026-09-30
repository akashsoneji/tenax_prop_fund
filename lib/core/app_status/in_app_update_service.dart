import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../logger/app_logger.dart';

/// Outcome of [InAppUpdateService.downloadAndInstall].
///
/// * [success]  — installer intent fired successfully. The user still needs
///   to tap "Install" in the system dialog; this only tells us the hand-off
///   worked.
/// * [downloadError] — the APK could not be downloaded (HTTP error, network
///   drop, disk full).
/// * [installError]  — download completed but the OS refused to open the
///   installer. On Android 8+ this almost always means the user has NOT
///   enabled "Install unknown apps" for this app in Settings.
enum DownloadResult { success, downloadError, installError }

/// Downloads an APK from a direct URL and hands it to the OS installer.
/// Android only — iOS updates always route to the App Store URL.
class InAppUpdateService {
  InAppUpdateService._();

  static InAppUpdateService? _instance;
  static InAppUpdateService get instance =>
      _instance ??= InAppUpdateService._();

  /// Path to the last downloaded APK — used by the dialog when the user taps
  /// "Open installer again" without re-downloading.
  String? _lastApkPath;
  String? get lastApkPath => _lastApkPath;

  /// URLs may look like `https://host/download.php?filename=app.apk` — check
  /// the path AND any query value for a `.apk` suffix.
  bool isApkUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.apk')) return true;
    try {
      final uri = Uri.parse(lower);
      if (uri.path.endsWith('.apk')) return true;
      for (final v in uri.queryParameters.values) {
        if (v.endsWith('.apk')) return true;
      }
    } catch (_) {}
    return lower.contains('.apk');
  }

  Future<DownloadResult> downloadAndInstall(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    File? file;
    try {
      file = await _download(url, onProgress: onProgress);
    } catch (e, st) {
      log.e('InAppUpdateService: download failed', error: e, stackTrace: st);
      return DownloadResult.downloadError;
    }
    if (file == null) return DownloadResult.downloadError;
    _lastApkPath = file.path;
    return _install(file.path);
  }

  /// Re-launches the installer for the last downloaded APK. Useful when the
  /// user dismisses the OS installer accidentally, or when "Install unknown
  /// apps" was disabled and they've just turned it on.
  Future<DownloadResult> reopenInstaller() async {
    final path = _lastApkPath;
    if (path == null || !File(path).existsSync()) {
      return DownloadResult.installError;
    }
    return _install(path);
  }

  Future<File?> _download(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url));
      final res = await client.send(req);
      if (res.statusCode != 200) {
        log.e('InAppUpdateService: HTTP ${res.statusCode} for $url');
        return null;
      }
      final total = res.contentLength ?? -1;
      // Prefer the app's external directory on Android: OEM installers
      // (Samsung / Xiaomi / Oppo) sometimes refuse to install from the
      // internal cache dir even with a FileProvider. Falls back to the
      // temporary directory when external storage is unavailable.
      final dir = Platform.isAndroid
          ? (await getExternalStorageDirectory() ??
              await getTemporaryDirectory())
          : await getTemporaryDirectory();
      final file = File(
        '${dir.path}/update_${DateTime.now().millisecondsSinceEpoch}.apk',
      );
      final sink = file.openWrite();
      var received = 0;
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress?.call((received / total).clamp(0.0, 1.0));
        }
      }
      await sink.close();
      log.d('InAppUpdateService: downloaded ${file.path} ($received bytes)');
      return file;
    } finally {
      client.close();
    }
  }

  Future<DownloadResult> _install(String path) async {
    try {
      final r = await OpenFilex.open(
        path,
        type: 'application/vnd.android.package-archive',
      );
      log.d('InAppUpdateService: installer result=${r.type} msg=${r.message}');
      switch (r.type) {
        case ResultType.done:
          return DownloadResult.success;
        case ResultType.permissionDenied:
        case ResultType.noAppToOpen:
        case ResultType.fileNotFound:
        case ResultType.error:
          return DownloadResult.installError;
      }
    } catch (e, st) {
      log.e('InAppUpdateService: install threw', error: e, stackTrace: st);
      return DownloadResult.installError;
    }
  }
}
