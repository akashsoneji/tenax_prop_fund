import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../chart/services/chart_preload_service.dart';
import '../../../chart/widgets/chart_in_app_webview.dart';
import '../../../positions/controllers/positions_controller.dart';
import '../../../positions/models/positions_models.dart';
import '../../../symbols/services/market_watch_v2_service.dart';
import '../../widgets/floating_trade_panel.dart';

/// Markets tab — a full-screen embedded live chart with a floating trade
/// ticket. The active symbol is the app-wide [MarketWatchV2Service.selectedSymbol]
/// so tapping a card on the Trade tab switches here and loads that symbol. The
/// WebView is preloaded at boot via [ChartPreloadService] and symbol changes are
/// applied via JS injection (no reload flash).
class MarketsTabView extends StatelessWidget {
  const MarketsTabView({super.key});

  static const _symbols = <String>[
    ChartPreloadService.defaultSymbol,
    'EURUSD',
    'GBPUSD',
    'USDJPY',
    'BTCUSD',
    'ETHUSD',
  ];

  @override
  Widget build(BuildContext context) {
    final market = Get.find<MarketWatchV2Service>();
    return SafeArea(
      child: Obx(() {
        final symbol = market.selectedSymbol.value;
        // Union of the presets and the live-selected symbol so the picker always
        // contains the current one even if it came from the Trade list.
        final symbols = <String>{symbol, ..._symbols}.toList();
        return Column(
          children: [
            Expanded(
              // URL follows the SELECTED symbol (same theme as the warm boot
              // URL, so the preloaded symbol still attaches without a reload).
              // Symbol switching still prefers fast JS injection; the URL is the
              // fallback the webview hard-loads when the page exposes no hook.
              child: ChartInAppWebView(
                url: Get.find<ChartPreloadService>().urlFor(symbol),
                symbol: symbol,
              ),
            ),
            FloatingTradePanel(
              symbol: symbol,
              symbols: symbols,
              onSymbolSelected: (s) {
                market.selectSymbol(s);
                Get.find<ChartPreloadService>().saveSymbol(s);
              },
              onSubmit: (ticket) async {
                await Get.find<PositionsController>().placeMarketOrder(
                  symbol: ticket.symbol,
                  volume: ticket.volume,
                  orderType: ticket.side == TradeSide.buy
                      ? OrderType.buyMarket
                      : OrderType.sellMarket,
                  takeProfit: ticket.takeProfit,
                  stopLoss: ticket.stopLoss,
                );
              },
            ),
          ],
        );
      }),
    );
  }
}
