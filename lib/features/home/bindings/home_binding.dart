import 'package:get/get.dart';

import '../../../app/flavor/flavor_config.dart';

import '../../../core/network/api_client.dart';
import '../../../core/websocket/pusher_client.dart';
import '../../../core/websocket/websocket_manager.dart';
import '../../accounts/controllers/accounts_controller.dart';
import '../../accounts/repositories/accounts_repository.dart';
import '../../authentication/repositories/auth_repository.dart';
import '../../../shared/bindings/positions_binding.dart';
import '../controllers/home_controller.dart';
import '../repositories/home_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeRepository>(() => HomeRepository(Get.find<ApiClient>()));

    // The "Accounts" bottom-nav tab is rendered inside the shell, so its
    // controller must be available here.
    Get.lazyPut<AccountsRepository>(
      () => AccountsRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<AccountsController>(
      () => AccountsController(Get.find<AccountsRepository>()),
    );

    // Dedicated Pusher client for the Home live-equity feed. The URL is fully
    // flavor-driven (host + app key) via FlavorConfig.pusherWsUrl. Private
    // channels are signed via ApiClient.broadcastingAuth (POST /broadcasting/auth
    // with the bearer token) so `subscription_succeeded` + AccountStateUpdated
    // frames actually flow.
    Get.lazyPut<PusherClient>(
      () => PusherClient(
        Get.find<FlavorConfig>().pusherWsUrl,
        Get.find<WebSocketManager>(),
        authResolver: Get.find<ApiClient>().broadcastingAuth,
      ),
      fenix: true,
    );

    // Positions tab lives inside the shell, so its controller + REST
    // repository must be wired here.
    PositionsBinding().dependencies();

    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<HomeRepository>(),
        Get.find<PusherClient>(),
        Get.find<AuthRepository>(),
      ),
    );
  }
}
