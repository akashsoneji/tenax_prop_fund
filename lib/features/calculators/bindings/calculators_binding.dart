import 'package:get/get.dart';

import '../controllers/calculators_controller.dart';

/// Wires [CalculatorsController] lazily when the Calculators route opens.
class CalculatorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CalculatorsController>(() => CalculatorsController());
  }
}
