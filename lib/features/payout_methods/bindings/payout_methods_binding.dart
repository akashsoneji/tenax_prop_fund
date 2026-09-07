import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/payout_methods_controller.dart';
import '../repositories/payout_methods_repository.dart';

/// Wires [PayoutMethodsController] (and its repository) for the Payout methods
/// screen. Registered lazily so the flow only allocates when the user opens the
/// route.
class PayoutMethodsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PayoutMethodsRepository>(
      () => PayoutMethodsRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<PayoutMethodsController>(
      () => PayoutMethodsController(Get.find<PayoutMethodsRepository>()),
    );
  }
}
