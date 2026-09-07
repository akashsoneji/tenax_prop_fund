import 'package:get/get.dart';

import '../controllers/symbols_controller.dart';
import '../repositories/symbols_repository.dart';

/// Wires [SymbolsController] (and its repository) lazily for the Symbols &
/// specs screen. The live-price [MarketWatchV2Service] is a permanent app-wide
/// singleton registered in `InitialBinding`, so it is not registered here.
class SymbolsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SymbolsRepository>(() => SymbolsRepository());
    Get.lazyPut<SymbolsController>(
      () => SymbolsController(Get.find<SymbolsRepository>()),
    );
  }
}
