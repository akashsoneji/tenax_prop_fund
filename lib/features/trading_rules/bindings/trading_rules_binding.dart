import 'package:get/get.dart';

import '../controllers/trading_rules_controller.dart';
import '../repositories/trading_rules_repository.dart';

/// Wires [TradingRulesController] (and its repository) for the Trading Rules
/// screen. Lazy: they only allocate when the user opens the route. Disposed
/// automatically by GetX when the route pops.
class TradingRulesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TradingRulesRepository>(() => TradingRulesRepository());
    Get.lazyPut<TradingRulesController>(
      () => TradingRulesController(Get.find<TradingRulesRepository>()),
    );
  }
}
