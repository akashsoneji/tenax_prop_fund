import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../app/flavor/flavor_config.dart';
import '../../settings/controllers/settings_controller.dart';

/// Pre-warms the Markets-tab chart at app launch using a [HeadlessInAppWebView]
/// that loads the flavor's REMOTE chart URL (see [FlavorConfig.chartUrl]) off
/// screen during boot. The on-screen [ChartInAppWebView] then attaches this
/// already-loaded instance for a near-instant paint instead of a cold load.
///
/// The chart is warmed with the LAST symbol the user viewed (persisted in
/// secure storage). When no symbol was ever selected — or the user is logged
/// out — it falls back to [defaultSymbol] (XAUUSD). The theme parameter follows
/// the user's chosen theme so a dark app opens a dark chart with no reload.
///
/// Registered as a permanent GetX singleton; `main()` calls [init] in a
/// post-frame callback (the headless webview needs the engine up first).
class ChartPreloadService extends GetxService {
  ChartPreloadService(this._config, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlavorConfig _config;
  final FlutterSecureStorage _storage;

  HeadlessInAppWebView? headlessWebView;
  bool isReady = false;

  /// Default symbol the Markets tab opens on when nothing was persisted (e.g.
  /// a logged-out or first-run user).
  static const defaultSymbol = 'XAUUSD';

  /// Secure-storage key holding the last symbol the user viewed on the chart.
  static const _lastSymbolKey = 'chart_last_symbol';

  /// Theme resolved once at boot; the warm instance and the Markets tab must
  /// request the SAME URL, otherwise a theme mismatch forces a full reload.
  bool _dark = true;

  /// The symbol the warm webview was booted with. Frozen in [init] to the
  /// persisted last symbol (or [defaultSymbol]). It must NOT change afterwards,
  /// otherwise [preloadUrl] would change and force the on-screen webview to do a
  /// full reload (the "blink") instead of a fast in-place JS symbol switch.
  String _bootSymbol = defaultSymbol;

  /// The symbol the pre-warmed instance is currently showing. The Markets tab
  /// reads this to seed its initial selection so the warm chart is reused as-is.
  String get currentSymbol => _bootSymbol;

  /// The remote chart URL preloaded at boot. The Markets tab reuses this exact
  /// string so the warm webview is never reloaded for a differing URL.
  String get preloadUrl => _config.chartUrl(_bootSymbol, dark: _dark);

  Future<ChartPreloadService> init() async {
    // Guard against a double warm-up (post-frame callback + any other caller).
    if (headlessWebView != null) return this;

    // Resolve the real theme now (the app's first frame is up), so the warmed
    // chart matches what the tab will ask for — no first-open reload.
    _dark = _resolveDark();

    // Restore the last symbol the user viewed; fall back to the default when
    // none was ever saved (logged-out / first run).
    _bootSymbol = await _readLastSymbol();

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(preloadUrl),
        // iOS: serve the cached shell/bundle when present (the 491KB chart
        // bundle is immutable), hitting the network only on a cold cache.
        cachePolicy: URLRequestCachePolicy.RETURN_CACHE_DATA_ELSE_LOAD,
      ),
      // A real off-screen size is REQUIRED — the default 0x0 makes the chart
      // skip layout/rendering, so it would still render from scratch on attach.
      initialSize: const Size(1080, 1920),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: true,
        // Android counterpart of the iOS cachePolicy above: prefer the on-disk
        // cache and fall back to the network only when nothing is cached, so the
        // 2nd+ launch skips re-downloading the immutable chart bundle.
        cacheEnabled: true,
        cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
        domStorageEnabled: true,
        databaseEnabled: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        supportZoom: false,
      ),
      onLoadStart: (controller, url) {
        if (kDebugMode) {
          debugPrint('[ChartPreloadService] headless onLoadStart: $url');
        }
      },
      onLoadStop: (controller, url) {
        if (kDebugMode) {
          debugPrint('[ChartPreloadService] headless onLoadStop: $url');
        }
        // HTML finished, but the chart CANVAS is still booting. Flip [isReady]
        // only once it is actually painted so the on-screen webview can attach
        // and reveal instantly instead of polling the canvas behind a loader.
        unawaited(_markReadyWhenPainted(controller));
      },
    );

    await headlessWebView?.run();
    return this;
  }

  /// Polls the headless page until the TradingView chart CANVAS is painted AND
  /// its size has stayed the SAME across several consecutive polls, then marks
  /// the service ready. HTML `onLoadStop` fires well before the charting library
  /// finishes its multi-stage boot (shell → init → state restore → datafeed
  /// redraw); each stage re-lays-out the canvas. Waiting for a STABLE canvas is
  /// what lets the on-screen webview reveal a fully-drawn chart with no visible
  /// re-refresh, instead of flipping ready on the first paint mid-boot.
  Future<void> _markReadyWhenPainted(InAppWebViewController controller) async {
    const canvasSize = '''
      (function() {
        var c = document.querySelector('canvas');
        if (!c || !(c.width > 0 && c.height > 0)) return '';
        return c.width + 'x' + c.height;
      })();
    ''';
    var last = '';
    var stable = 0;
    for (var attempt = 0; attempt < 100; attempt++) {
      String size = '';
      try {
        final res = await controller.evaluateJavascript(source: canvasSize);
        if (res is String) size = res;
      } catch (_) {
        // Controller can momentarily reject eval during boot — keep polling.
      }
      if (size.isNotEmpty && size == last) {
        if (++stable >= 4) break;
      } else {
        stable = 0;
        last = size;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    isReady = true;
    if (kDebugMode) {
      debugPrint('[ChartPreloadService] canvas settled — ready');
    }
  }

  /// Persists [symbol] as the last-viewed chart symbol so the NEXT launch warms
  /// the chart on it. Deliberately does NOT touch [_bootSymbol] — changing it
  /// would alter [preloadUrl] and force a full webview reload (blink) instead of
  /// the in-place JS symbol switch used during the session.
  Future<void> saveSymbol(String symbol) async {
    if (symbol.isEmpty) return;
    await _storage.write(key: _lastSymbolKey, value: symbol);
  }

  Future<String> _readLastSymbol() async {
    try {
      final saved = await _storage.read(key: _lastSymbolKey);
      if (saved != null && saved.isNotEmpty) return saved;
    } catch (_) {
      // Secure storage can throw on some platforms/first run — fall back.
    }
    return defaultSymbol;
  }

  bool _resolveDark() {
    final mode = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>().themeMode
        : ThemeMode.system;
    switch (mode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding
                .instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  @override
  void onClose() {
    headlessWebView?.dispose();
    super.onClose();
  }
}
