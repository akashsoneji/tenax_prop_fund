import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/offers_controller.dart';
import '../repositories/offers_repository.dart';

/// Wires [OffersController] (and its repository) for the "My offers" screen.
/// Registered lazily so the offers flow only allocates when the user opens the
/// route.
class OffersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OffersRepository>(
      () => OffersRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<OffersController>(
      () => OffersController(Get.find<OffersRepository>()),
    );
  }
}
