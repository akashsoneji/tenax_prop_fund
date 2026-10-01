import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../features/accounts/repositories/accounts_repository.dart';
import '../../features/positions/controllers/positions_controller.dart';
import '../../features/positions/repositories/positions_repository.dart';
import '../../features/positions/services/account_ws_service.dart';
import '../../features/positions/services/positions_ws_service.dart';
import '../../features/symbols/services/market_watch_v2_service.dart';

/// Wires the Positions feature — the ONE place it is registered.
///
/// Positions is used by several screens (the Positions tab, the Home bento,
/// the trade ticket, the landscape chart), so any binding that hosts one of
/// them calls `PositionsBinding().dependencies()` instead of repeating this.
/// The two trade sockets ([PositionsWsService], [AccountWsService]) are
/// registered permanently in `InitialBinding`; this only lazily wires the
/// controller and its REST repository.
///
/// This lives in `lib/shared` by request; it is the one shared file that
/// imports feature code, because a binding has to know the classes it wires.
class PositionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PositionsRepository>(
      () => PositionsRepository(Get.find<ApiClient>()),
      fenix: true,
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
      fenix: true,
    );
  }
}
