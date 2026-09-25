import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../billing/controllers/billing_controller.dart';
import '../../billing/repositories/billing_repository.dart';
import '../../payout_methods/controllers/payout_methods_controller.dart';
import '../../payout_methods/repositories/payout_methods_repository.dart';
import '../controllers/payout_history_controller.dart';
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
    Get.lazyPut<ExtendedRewardsController>(
      () => ExtendedRewardsController(Get.find<RewardsRepository>()),
    );
    Get.lazyPut<PayoutHistoryController>(
      () => PayoutHistoryController(Get.find<RewardsRepository>()),
    );
    Get.lazyPut<BillingRepository>(
      () => BillingRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<BillingController>(
      () => BillingController(Get.find<BillingRepository>()),
    );
    Get.lazyPut<PayoutMethodsRepository>(
      () => PayoutMethodsRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<PayoutMethodsController>(
      () => PayoutMethodsController(Get.find<PayoutMethodsRepository>()),
    );
  }
}
