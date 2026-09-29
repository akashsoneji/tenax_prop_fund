import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../app/flavor/flavor_config.dart';
import '../../../core/network/api_interceptor.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import 'chart_warmer.dart';

/// Pre-warms the PORTRAIT Markets-tab chart at app launch using the shared
/// [ChartWarmer] machinery: a [HeadlessInAppWebView] loads the flavor's remote
/// chart URL (see [FlavorConfig.chartUrl]) off screen during boot, and the
/// on-screen `ChartInAppWebView` attaches that already-loaded instance for a
/// near-instant paint instead of a cold load.
///
/// The chart is warmed with the LAST symbol the user viewed (persisted in
/// secure storage). When no symbol was ever selected — or the user is logged
/// out — it falls back to [defaultSymbol] (XAUUSD). The theme parameter follows
/// the user's chosen theme so a dark app opens a dark chart with no reload.
///
/// Landscape has its OWN warmer (`ChartLandscapePreloadService`) because the
/// charting library re-creates its widget on resize — see [ChartWarmer].
///
/// Registered as a permanent GetX singleton; `main()` calls [init] in a
/// post-frame callback (the headless webview needs the engine up first).
class ChartPreloadService extends ChartWarmer {
  ChartPreloadService(this._config, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlavorConfig _config;
  final FlutterSecureStorage _storage;

  @override
  String get traceTag => 'ChartPreload';

  /// Default symbol the Markets tab opens on when nothing was persisted (e.g.
  /// a logged-out or first-run user).
  static const defaultSymbol = 'XAUUSD';

  /// Secure-storage key holding the last symbol the user viewed on the chart.
  static const lastSymbolKey = 'chart_last_symbol';

  /// True while the landscape full-screen route owns the warm instance.
  ///
  /// A headless webview can back only ONE on-screen webview, and two live
  /// chart webviews make the platform drop a render surface (the portrait
  /// chart goes blank). So the Markets tab watches this flag and unmounts its
  /// webview — releasing the claim — before the full-screen route attaches the
  /// SAME already-painted instance. One chart, handed over, so full screen
  /// opens instantly with no second warm-up.
  final fullscreenActive = false.obs;

  /// Theme resolved once at boot; the warm instance and the Markets tab must
  /// request the SAME URL, otherwise a theme mismatch forces a full reload.
  bool _dark = true;

  /// Theme the warm instance booted with. The landscape warmer reads this so
  /// both orientations request an identically-themed chart URL.
  bool get isDark => _dark;

  /// The symbol the warm webview was booted with. Frozen in [init] to the
  /// persisted last symbol (or [defaultSymbol]). It must NOT change afterwards,
  /// otherwise [preloadUrl] would change and force the on-screen webview to do a
  /// full reload (the "blink") instead of a fast in-place JS symbol switch.
  String _bootSymbol = defaultSymbol;

  /// The symbol the pre-warmed instance is currently showing. The Markets tab
  /// reads this to seed its initial selection so the warm chart is reused as-is.
  @override
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
    _dark = resolveDark();

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

    // Warmed at the PORTRAIT screen size: the charting library rebuilds its
    // widget on every resize, so warming at an arbitrary size would guarantee a
    // re-init — and 2-3 visible redraws — the moment the instance is attached.
    await warmUp(url: preloadUrl, size: portraitSize());
    return this;
  }

  /// Screen size with the SHORT edge as width — the portrait viewport, however
  /// the device happens to be rotated while the app boots.
  @protected
  Size portraitSize() {
    final size = screenSize();
    final shortest = size.width < size.height ? size.width : size.height;
    final longest = size.width < size.height ? size.height : size.width;
    return Size(shortest, longest);
  }

  /// Pushes a route that shows its own chart (e.g. Pending Order) while the
  /// Charts tab stays mounted underneath.
  ///
  /// Two live chart webviews make the platform drop a render surface (the tab's
  /// chart comes back blank), and the second one could not claim the warm
  /// instance anyway. So the tab's webview is unmounted first — releasing the
  /// claim — and the pushed screen attaches the SAME painted instance. The
  /// previous flag is restored, not forced to false, so a push from inside full
  /// screen (portrait already handed off) does not remount the tab mid-landscape.
  Future<T?> whileHandedOff<T>(Future<T?>? Function() push) async {
    final previous = fullscreenActive.value;
    fullscreenActive.value = true;
    // One frame so the tab rebuilds without its webview and release() runs
    // before the pushed screen claims.
    await WidgetsBinding.instance.endOfFrame;
    try {
      return await push();
    } finally {
      // The push resolves when the route STARTS popping; its chart is disposed
      // only after the exit animation. Remounting the tab before that makes its
      // claim fail, so it cold-loads a second webview and ends up blank.
      await waitUntilReleased();
      fullscreenActive.value = previous;
    }
  }

  /// Persists [symbol] as the last-viewed chart symbol so the NEXT launch warms
  /// the chart on it. Deliberately does NOT touch [_bootSymbol] — changing it
  /// would alter [preloadUrl] and force a full webview reload (blink) instead of
  /// the in-place JS symbol switch used during the session.
  Future<void> saveSymbol(String symbol) async {
    if (symbol.isEmpty) return;
    await _storage.write(key: lastSymbolKey, value: symbol);
  }

  /// Symbol to warm the chart on: the persisted last-viewed symbol for a
  /// logged-in user, [defaultSymbol] for a logged-out one (their stored symbol
  /// belongs to the previous session and must not leak into a fresh launch).
  Future<String> _resolveBootSymbol() async {
    try {
      final token = await _storage.read(key: ApiInterceptor.tokenKey);
      if (token == null || token.isEmpty) return defaultSymbol;
      final saved = await _storage.read(key: lastSymbolKey);
      if (saved != null && saved.isNotEmpty) return saved;
    } catch (_) {
      // Secure storage can throw on some platforms/first run — fall back.
    }
    return defaultSymbol;
  }

  /// Resolves the effective dark/light flag from the user's theme preference.
  /// Shared with the landscape warmer so both request the same chart theme.
  static bool resolveDark() {
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
}
