import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/rewards_controller.dart';
import '../repositories/rewards_repository.dart';

/// Wires [RewardsController] (and its repository) for the Rewards screen.
/// Registered lazily so the rewards flow only allocates when the user opens
/// the route.
class RewardsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RewardsRepository>(
      () => RewardsRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<RewardsController>(
      () => RewardsController(Get.find<RewardsRepository>()),
    );
  }
}
