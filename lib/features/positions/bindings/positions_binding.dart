import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../accounts/repositories/accounts_repository.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import '../controllers/positions_controller.dart';
import '../repositories/positions_repository.dart';
import '../services/account_ws_service.dart';
import '../services/positions_ws_service.dart';

/// Wires the Positions feature. The two trade sockets ([PositionsWsService],
/// [AccountWsService]) are registered permanently in `InitialBinding` (so the
/// account summary keeps ticking regardless of which tab is showing); this
/// binding only lazily wires the per-screen controller + its REST repository.
class PositionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PositionsRepository>(
      () => PositionsRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<AccountsRepository>(
      () => AccountsRepository(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<PositionsController>(
      () => PositionsController(
        Get.find<PositionsRepository>(),
        Get.find<PositionsWsService>(),
        Get.find<AccountWsService>(),
        Get.find<MarketWatchV2Service>(),
        Get.find<AccountsRepository>(),
      ),
    );
  }
}
