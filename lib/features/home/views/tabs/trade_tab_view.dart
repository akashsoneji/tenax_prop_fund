import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../symbols/controllers/symbols_controller.dart';
import '../../../symbols/repositories/symbols_repository.dart';
import '../../../symbols/views/symbols_view.dart';

/// Trade tab — the live "Symbols & specs" market-watch list (shimmer load +
/// streaming bid/ask from [MarketWatchV2Service]).
///
/// The controller is ensured here rather than relying on a binding, because the
/// home shell builds every tab up front (IndexedStack) and bindings do not
/// re-run on hot reload; this guarantees [SymbolsView] always finds it.
class TradeTabView extends StatelessWidget {
  const TradeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SymbolsRepository>()) {
      Get.lazyPut<SymbolsRepository>(() => SymbolsRepository(), fenix: true);
    }
    if (!Get.isRegistered<SymbolsController>()) {
      Get.lazyPut<SymbolsController>(
        () => SymbolsController(Get.find<SymbolsRepository>()),
        fenix: true,
      );
    }
    return const SymbolsView();
  }
}
