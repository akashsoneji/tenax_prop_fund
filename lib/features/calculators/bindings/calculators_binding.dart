import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/calculators_controller.dart';
import '../repositories/calculators_repository.dart';

/// Wires [CalculatorsController] lazily when the Calculators route opens.
class CalculatorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CalculatorsRepository>(
      () => CalculatorsRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<CalculatorsController>(
      () => CalculatorsController(Get.find<CalculatorsRepository>()),
    );
  }
}
