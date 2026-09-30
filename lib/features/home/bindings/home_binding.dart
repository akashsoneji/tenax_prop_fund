import 'package:get/get.dart';

import '../../../app/flavor/flavor_config.dart';
import '../../../app/flavor/flavor_resolver.dart';
import '../../../core/network/api_client.dart';
import '../../../core/websocket/pusher_client.dart';
import '../../accounts/controllers/accounts_controller.dart';
import '../../accounts/repositories/accounts_repository.dart';
import '../../authentication/repositories/auth_repository.dart';
import '../../positions/controllers/positions_controller.dart';
import '../../positions/repositories/positions_repository.dart';
import '../../positions/services/account_ws_service.dart';
import '../../positions/services/positions_ws_service.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import '../controllers/home_controller.dart';
import '../repositories/home_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeRepository>(() => HomeRepository(Get.find<ApiClient>()));

    // Tenax-design flavors replace the "More" bottom-nav tab with an "Accounts"
    // tab rendered inside the shell, so its controller must be available here.
    if (FlavorResolver.usesTenaxDesign) {
      Get.lazyPut<AccountsRepository>(
        () => AccountsRepository(Get.find<ApiClient>()),
      );
      Get.lazyPut<AccountsController>(
        () => AccountsController(Get.find<AccountsRepository>()),
      );
    }

    // Dedicated Pusher client for the Home live-equity feed. The URL is fully
    // flavor-driven (host + app key) via FlavorConfig.pusherWsUrl. Private
    // channels are signed via ApiClient.broadcastingAuth (POST /broadcasting/auth
    // with the bearer token) so `subscription_succeeded` + AccountStateUpdated
    // frames actually flow.
    Get.lazyPut<PusherClient>(
      () => PusherClient(
        Get.find<FlavorConfig>().pusherWsUrl,
        authResolver: Get.find<ApiClient>().broadcastingAuth,
      ),
      fenix: true,
    );

    // Positions tab lives inside the shell (both flavors), so its controller +
    // REST repository must be wired here. The two trade sockets are permanent
    // singletons (see InitialBinding) so the account summary keeps ticking.
    Get.lazyPut<AccountsRepository>(
      () => AccountsRepository(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<PositionsRepository>(
      () => PositionsRepository(Get.find<ApiClient>()),
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

    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<HomeRepository>(),
        Get.find<PusherClient>(),
        Get.find<AuthRepository>(),
      ),
    );
  }
}
