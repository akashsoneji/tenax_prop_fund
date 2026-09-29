import 'package:get/get.dart';

import '../../../app/flavor/flavor_config.dart';
import '../../chart/services/chart_preload_service.dart';
import '../../positions/controllers/positions_controller.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import '../controllers/chart_landscape_controller.dart';
import '../services/chart_landscape_preload_service.dart';

/// Wires the landscape split view. Every business dependency is an already-
/// registered app-wide singleton, which is why the two orientations share one
/// set of business services. The chart warmer is the one deliberate
/// exception: [ChartLandscapePreloadService] is `fenix: true` so it survives
/// repeated visits to this route (warmed once, reused every time after) while
/// staying entirely separate from the portrait warmer.
class ChartLandscapeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChartLandscapePreloadService>(
      () => ChartLandscapePreloadService(Get.find<FlavorConfig>()),
      fenix: true,
    );
    Get.lazyPut<ChartLandscapeController>(
      () => ChartLandscapeController(
        marketWatch: Get.find<MarketWatchV2Service>(),
        positions: Get.find<PositionsController>(),
        preload: Get.find<ChartPreloadService>(),
        landscapeWarmer: Get.find<ChartLandscapePreloadService>(),
      ),
    );
  }
}
