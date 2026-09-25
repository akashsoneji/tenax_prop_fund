import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/referral_history_controller.dart';
import '../repositories/referral_repository.dart';

/// Wires [ReferralHistoryController] for the commission history route. Reuses
/// the repository if the Refer & earn screen already registered it.
class ReferralHistoryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ReferralRepository>()) {
      Get.lazyPut<ReferralRepository>(
        () => ReferralRepository(Get.find<ApiClient>()),
      );
    }
    Get.lazyPut<ReferralHistoryController>(
      () => ReferralHistoryController(Get.find<ReferralRepository>()),
    );
  }
}
