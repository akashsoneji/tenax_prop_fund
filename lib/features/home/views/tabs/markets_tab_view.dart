import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/chart/chart_fullscreen_button.dart';
import '../../../../shared/widgets/trade/symbol_picker_chip.dart';
import '../../../../shared/widgets/trade/trade_ticket_panel.dart';
import '../../../chart/services/chart_preload_service.dart';
import '../../../chart/widgets/chart_in_app_webview.dart';
import '../../../positions/controllers/positions_controller.dart';
import '../../../positions/widgets/chart_account_badge.dart';
import '../../../symbols/services/favorites_service.dart';
import '../../../symbols/services/market_watch_v2_service.dart';

/// Markets tab — a full-screen embedded live chart with a docked trade ticket.
/// The active symbol is the app-wide [MarketWatchV2Service.selectedSymbol] so
/// tapping a card on the Trade tab switches here and loads that symbol. The
/// WebView is preloaded at boot via [ChartPreloadService] and symbol changes
/// are applied via JS injection (no reload flash).
///
/// The fullscreen control opens the landscape split view, which uses the same
/// ticket widget and the same services — only the arrangement differs.
class MarketsTabView extends StatefulWidget {
  const MarketsTabView({super.key});


  @override
  State<MarketsTabView> createState() => _MarketsTabViewState();
}

class _MarketsTabViewState extends State<MarketsTabView> {
  /// Hands this tab's already-painted chart over to the full-screen route.
  ///
  /// The warm instance can back only one on-screen webview, and two live chart
  /// webviews make the platform drop a render surface (the portrait chart goes
  /// blank). So instead of warming a second chart we UNMOUNT this one first —
  /// which releases the claim — wait a frame for the dispose to land, then
  /// navigate. Full screen then attaches the same instance, already painted,
  /// with no warm-up and no loader.
  Future<void> _openFullscreen(List<String> symbols) async {
    // Requested BEFORE navigating, not inside the new route's onInit: the OS
    // needs several frames to actually rotate, and starting it earlier means
    // the landscape route builds much closer to (ideally after) the real
    // rotation instead of racing it — that race is what showed up as sideways,
    // overlapping content on first open.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Back in portrait the tab re-mounts and re-claims the same warm instance.
    await Get.find<ChartPreloadService>().whileHandedOff(
      () => Get.toNamed<void>(AppRoutes.chartLandscape, arguments: symbols),
    );
  }

  @override
  Widget build(BuildContext context) {
    final market = Get.find<MarketWatchV2Service>();
    final favorites = Get.find<FavoritesService>();
    return SafeArea(
      child: Obx(() {
        final symbol = market.selectedSymbol.value;
        // The picker mirrors the Trade tab's favourites (add/remove reflects
        // live); the selected symbol is kept so the current one is always listed.
        final symbols = <String>{symbol, ...favorites.favoriteCodes}.toList();
        return Column(
          children: [
            _ChartTopBar(
              symbol: symbol,
              symbols: symbols,
              onSymbolSelected: (s) {
                market.selectSymbol(s);
                Get.find<ChartPreloadService>().saveSymbol(s);
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  // Deliberately OUTSIDE this Obx's rebuild scope. Anything
                  // that rebuilds the webview widget makes the chart reload or
                  // blink, so it owns the narrowest possible listener.
                  const Positioned.fill(child: _PortraitChart()),
                  // Positioned(
                  //   top: 8.h,
                  //   right: 8.w,
                  //   child: ChartFullscreenButton(
                  //     onTap: () => _openFullscreen(symbols),
                  //   ),
                  // ),
                ],
              ),
            ),
            TradeTicketPanel(
              symbol: symbol,
              onSubmit: (ticket) =>
                  Get.find<PositionsController>().placeTicket(ticket),
            ),
          ],
        );
      }),
    );
  }
}

/// Top bar of the Charts tab: symbol picker in the left corner, floating P/L +
/// account switcher in the right corner.
class _ChartTopBar extends StatelessWidget {
  const _ChartTopBar({
    required this.symbol,
    required this.symbols,
    required this.onSymbolSelected,
  });

  final String symbol;
  final List<String> symbols;
  final ValueChanged<String> onSymbolSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 6.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SymbolPickerChip(
                symbol: symbol,
                symbols: symbols,
                onSelected: onSymbolSelected,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          ChartAccountBadge(controller: Get.find<PositionsController>()),
        ],
      ),
    );
  }
}

/// The portrait chart, isolated so the webview is created ONCE and then left
/// alone.
///
/// This is deliberately NOT an `Obx`. A reactive builder re-runs on every
/// notification from anything it touched — including a repeat write of the
/// same symbol — and each re-run rebuilds the `ChartInAppWebView` element,
/// which the platform treats as a fresh load. That was the chart reloading
/// itself 2-3 times after opening. Instead the symbol is watched explicitly
/// and only a REAL change is pushed down as a prop, where the webview's
/// `didUpdateWidget` applies it in place via JS.
class _PortraitChart extends StatefulWidget {
  const _PortraitChart();

  @override
  State<_PortraitChart> createState() => _PortraitChartState();
}

class _PortraitChartState extends State<_PortraitChart> {
  final _market = Get.find<MarketWatchV2Service>();
  final _preload = Get.find<ChartPreloadService>();

  late String _symbol = _market.selectedSymbol.value.isEmpty
      ? _preload.currentSymbol
      : _market.selectedSymbol.value;
  late bool _handedOff = _preload.fullscreenActive.value;

  final _subs = <Worker>[];

  @override
  void initState() {
    super.initState();
    _subs.add(
      ever<String>(_market.selectedSymbol, (next) {
        if (!mounted || next.isEmpty || next == _symbol) return;
        setState(() => _symbol = next);
      }),
    );
    _subs.add(
      ever<bool>(_preload.fullscreenActive, (active) {
        if (!mounted || active == _handedOff) return;
        setState(() => _handedOff = active);
      }),
    );
  }

  @override
  void dispose() {
    for (final worker in _subs) {
      worker.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // While full screen owns the warm instance this renders a plain surface:
    // the webview must be GONE, not merely hidden, for the claim to transfer.
    // Switching bottom tabs must NOT unmount it — the element would be rebuilt
    // on return, re-running the loader and paint check (a visible reload).
    if (_handedOff) {
      return ColoredBox(color: Theme.of(context).colorScheme.surface);
    }
    // URL follows the selected symbol using the same theme the warm instance
    // booted with, so the preloaded symbol attaches without a reload.
    return ChartInAppWebView(
      url: _preload.urlFor(_symbol),
      symbol: _symbol,
    );
  }
}