import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../app/flavor/flavor_config.dart';
import '../../../core/network/api_interceptor.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../symbols/services/market_watch_v2_service.dart';

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

  /// True while an on-screen webview has the warm instance attached. A
  /// [HeadlessInAppWebView] can only back ONE [InAppWebView] at a time, so a
  /// second screen must fall back to its own (cache-backed) webview instead of
  /// stealing the instance out from under the first one.
  bool _claimed = false;

  /// Hands the warm instance to a caller, or null when it is already in use.
  HeadlessInAppWebView? claim() {
    if (headlessWebView == null || _claimed) return null;
    _claimed = true;
    _trace('claimed by on-screen webview (isReady=$isReady)');
    return headlessWebView;
  }

  /// Returns the warm instance to the pool when a screen is disposed.
  void release() {
    _claimed = false;
    _trace('released back to pool');
  }

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

  /// Chart URL for [symbol] built with the SAME theme the warm instance booted
  /// with. Asking for [currentSymbol] therefore returns exactly [preloadUrl]
  /// (warm attach, no reload), while any other symbol yields a distinct URL so
  /// the webview can hard-load that symbol when the in-page JS switch misses.
  String urlFor(String symbol) => _config.chartUrl(
        symbol.isEmpty ? _bootSymbol : symbol,
        dark: _dark,
      );

  Future<ChartPreloadService> init() async {
    // Guard against a double warm-up (post-frame callback + any other caller).
    if (headlessWebView != null) return this;

    // Resolve the real theme now (the app's first frame is up), so the warmed
    // chart matches what the tab will ask for — no first-open reload.
    _dark = _resolveDark();

    // Logged in → warm the LAST symbol the user viewed; logged out (or nothing
    // ever saved) → warm [defaultSymbol].
    _bootSymbol = await _resolveBootSymbol();

    // Keep the app-wide selection in step with the warmed symbol, otherwise the
    // Markets tab opens on its own default and the warm instance is discarded by
    // an immediate symbol switch/reload — exactly the cold load the preload
    // exists to avoid.
    if (Get.isRegistered<MarketWatchV2Service>()) {
      Get.find<MarketWatchV2Service>().selectSymbol(_bootSymbol);
    }

    _loadStartedAt = DateTime.now();
    _trace('init warming symbol=$_bootSymbol dark=$_dark url=$preloadUrl');

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(preloadUrl),
        // iOS: serve the cached shell/bundle when present (the 491KB chart
        // bundle is immutable), hitting the network only on a cold cache.
        cachePolicy: URLRequestCachePolicy.RETURN_CACHE_DATA_ELSE_LOAD,
      ),
      // A real off-screen size is REQUIRED — the default 0x0 makes the chart
      // skip layout/rendering. It must also match the size the chart will have
      // ON SCREEN: the charting library re-creates its widget on every resize,
      // so warming at an arbitrary size (1080x1920) guaranteed a re-init — and
      // 2-3 visible redraws — the moment the instance was attached.
      initialSize: _screenSize(),
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
        _loadStartedAt = DateTime.now();
        _trace('headless onLoadStart url=$url');
      },
      onLoadStop: (controller, url) {
        _trace('headless onLoadStop url=$url');
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
    var polls = 0;
    var resizes = 0;
    for (var attempt = 0; attempt < 100; attempt++) {
      polls++;
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
        // Each distinct canvas size is one re-layout of the charting library —
        // this counter is the measurable proxy for the visible "flicker".
        if (size.isNotEmpty) {
          resizes++;
          _trace('headless canvas resize #$resizes: "$last" -> "$size"');
        }
        stable = 0;
        last = size;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    isReady = true;
    _readyAt = DateTime.now();
    _trace('headless READY canvas=$last polls=$polls resizes=$resizes');
  }

  /// Wall-clock reference for the trace timestamps: when the headless page
  /// started loading. Everything after it is reported as `+Nms` so the debug log
  /// shows exactly where the seconds go.
  DateTime? _loadStartedAt;
  DateTime? _readyAt;

  /// Milliseconds the headless warm-up took to reach a settled canvas, or null
  /// while it is still warming. Read by the on-screen webview for its own trace.
  int? get warmupMs => (_loadStartedAt == null || _readyAt == null)
      ? null
      : _readyAt!.difference(_loadStartedAt!).inMilliseconds;

  /// Logical size of the device screen. The headless instance is warmed at this
  /// size so attaching it to a full-screen chart is (close to) a no-op resize
  /// instead of a re-layout that makes the library rebuild the chart widget.
  Size _screenSize() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    if (size.width <= 0 || size.height <= 0) return const Size(375, 812);
    return size;
  }

  void _trace(String message) {
    if (!kDebugMode) return;
    final started = _loadStartedAt;
    final offset = started == null
        ? ''
        : '+${DateTime.now().difference(started).inMilliseconds}ms ';
    debugPrint('[ChartPreload] $offset$message');
  }

  /// Persists [symbol] as the last-viewed chart symbol so the NEXT launch warms
  /// the chart on it. Deliberately does NOT touch [_bootSymbol] — changing it
  /// would alter [preloadUrl] and force a full webview reload (blink) instead of
  /// the in-place JS symbol switch used during the session.
  Future<void> saveSymbol(String symbol) async {
    if (symbol.isEmpty) return;
    await _storage.write(key: _lastSymbolKey, value: symbol);
  }

  /// Symbol to warm the chart on: the persisted last-viewed symbol for a
  /// logged-in user, [defaultSymbol] for a logged-out one (their stored symbol
  /// belongs to the previous session and must not leak into a fresh launch).
  Future<String> _resolveBootSymbol() async {
    try {
      final token = await _storage.read(key: ApiInterceptor.tokenKey);
      if (token == null || token.isEmpty) return defaultSymbol;
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
