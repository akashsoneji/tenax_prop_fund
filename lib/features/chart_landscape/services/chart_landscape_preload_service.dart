import 'package:flutter/widgets.dart';

import '../../../app/flavor/flavor_config.dart';
import '../../chart/services/chart_preload_service.dart';
import '../../chart/services/chart_warmer.dart';

/// Pre-warms the LANDSCAPE full-screen chart in its OWN off-screen
/// [HeadlessInAppWebView], separate from the portrait [ChartPreloadService].
///
/// The charting library re-creates its widget on every resize, so sharing a
/// single warm instance between portrait and landscape guaranteed a visible
/// re-init (and, worse, a full network reload) on every round trip between
/// the two — the bug this service exists to remove. Each orientation now
/// owns a persistently-warm instance sized for ITS OWN viewport, so entering
/// landscape after the first visit attaches an already-painted webview
/// instead of doing a cold load, and returning to portrait finds its own
/// instance exactly as it was left.
///
/// Warmed LAZILY (unlike the portrait service, which warms at app boot):
/// most sessions never open the landscape view, so there is no reason to pay
/// for a second headless webview until the user actually rotates in.
/// [ChartLandscapeController] triggers [ensureWarm] once rotation settles.
class ChartLandscapePreloadService extends ChartWarmer {
  ChartLandscapePreloadService(this._config);

  final FlavorConfig _config;

  @override
  String get traceTag => 'ChartLandscapePreload';

  String _symbol = ChartPreloadService.defaultSymbol;

  @override
  String get currentSymbol => _symbol;

  /// Chart URL for [symbol], themed identically to the portrait warmer (see
  /// [ChartPreloadService.resolveDark]) so neither orientation ever shows a
  /// mismatched theme.
  String urlFor(String symbol) => _config.chartUrl(
        symbol.isEmpty ? _symbol : symbol,
        dark: ChartPreloadService.resolveDark(),
      );

  /// Warms the instance on [symbol] at the landscape viewport size. A no-op
  /// once already warmed (see [ChartWarmer.warmUp]) — later rotations just
  /// reattach the same instance, even if the symbol has since changed, since
  /// the on-screen webview applies a symbol difference via an in-place JS
  /// switch rather than a reload.
  Future<void> ensureWarm(String symbol) async {
    if (symbol.isNotEmpty) _symbol = symbol;
    if (headlessWebView != null) return;
    await warmUp(url: urlFor(_symbol), size: landscapeSize());
  }

  /// Screen size with the LONG edge as width — the landscape viewport,
  /// however the device happens to be rotated when this is called.
  @protected
  Size landscapeSize() {
    final size = screenSize();
    final shortest = size.width < size.height ? size.width : size.height;
    final longest = size.width < size.height ? size.height : size.width;
    return Size(longest, shortest);
  }
}
