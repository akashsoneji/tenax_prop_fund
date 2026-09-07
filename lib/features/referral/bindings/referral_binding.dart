import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/referral_controller.dart';
import '../repositories/referral_repository.dart';

/// Wires [ReferralController] (and its repository) for the "Refer & earn"
/// screen. Registered lazily so the flow only allocates when the user opens the
/// route.
class ReferralBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferralRepository>(
      () => ReferralRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<ReferralController>(
      () => ReferralController(Get.find<ReferralRepository>()),
    );
  }
}
