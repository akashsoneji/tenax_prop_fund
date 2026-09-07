import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../chart/services/chart_preload_service.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/symbols_controller.dart';
import '../models/symbol_models.dart';
import '../services/market_watch_v2_service.dart';
import '../widgets/symbol_card.dart';

/// Full "Symbols & specs" screen — a scrolling list of symbol cards, each with
/// a header row (code + subtitle + Trade button) and a bordered 2x4 spec table.
/// Loading/error/empty are handled by [DataStateBuilder] on the controller's
/// `DataState<List<SymbolSpec>>`.
class SymbolsView extends StatelessWidget {
  const SymbolsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<SymbolsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'symbols.title'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Obx(
                () => DataStateBuilder<List<SymbolSpec>>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const SymbolListSkeleton(rows: 6),
                  builder: (data) => _SymbolsList(symbols: data),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded list: lazy ListView.builder of symbol cards.
// ---------------------------------------------------------------------------
class _SymbolsList extends StatelessWidget {
  const _SymbolsList({required this.symbols});
  final List<SymbolSpec> symbols;

  /// Select the tapped symbol app-wide, persist it for the chart, and jump to
  /// the Markets tab where the chart + trade ticket follow [selectedSymbol].
  void _openInMarkets(String code) {
    Get.find<MarketWatchV2Service>().selectSymbol(code);
    Get.find<ChartPreloadService>().saveSymbol(code);
    Get.find<HomeController>().selectTab(1);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: symbols.length,
      itemBuilder: (context, i) => Padding(
        padding: EdgeInsets.only(bottom: i == symbols.length - 1 ? 0 : 14),
        child: _Enter(
          delay: (0.05 * i).clamp(0.0, 0.5),
          child: SymbolCard(
            symbol: symbols[i],
            onTap: () => _openInMarkets(symbols[i].code),
          ),
        ),
      ),
    );
  }
}

/// Subtle fade + rise entrance, mirrors rewards_view.dart.
class _Enter extends StatelessWidget {
  const _Enter({required this.child, this.delay = 0.0});
  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Interval(delay, 1.0, curve: AppMotion.enter),
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
