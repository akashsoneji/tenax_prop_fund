import 'package:get/get.dart';

import '../../chart/services/chart_preload_service.dart';
import '../../positions/controllers/positions_controller.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import '../controllers/chart_landscape_controller.dart';

/// Wires the landscape split view. Every dependency is an already-registered
/// app-wide singleton — this binding creates nothing but the controller, which
/// is exactly why the two orientations share one set of business services.
class ChartLandscapeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChartLandscapeController>(
      () => ChartLandscapeController(
        marketWatch: Get.find<MarketWatchV2Service>(),
        positions: Get.find<PositionsController>(),
        preload: Get.find<ChartPreloadService>(),
      ),
    );
  }
}
