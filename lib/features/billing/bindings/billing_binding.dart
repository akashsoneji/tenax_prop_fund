import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/billing_controller.dart';
import '../repositories/billing_repository.dart';

/// Wires [BillingController] (and its repository) for the Billing history
/// screen. Registered lazily so the flow only allocates when the user opens the
/// route.
class BillingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillingRepository>(
      () => BillingRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<BillingController>(
      () => BillingController(Get.find<BillingRepository>()),
    );
  }
}
