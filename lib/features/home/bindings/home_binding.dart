import 'package:get/get.dart';

import '../../../app/flavor/flavor_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/websocket/pusher_client.dart';
import '../../authentication/repositories/auth_repository.dart';
import '../controllers/home_controller.dart';
import '../repositories/home_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeRepository>(() => HomeRepository(Get.find<ApiClient>()));

    // Dedicated Pusher client for the Home live-equity feed. The URL is fully
    // flavor-driven (host + app key) via FlavorConfig.pusherWsUrl.
    Get.lazyPut<PusherClient>(
      () => PusherClient(Get.find<FlavorConfig>().pusherWsUrl),
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
