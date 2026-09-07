import 'package:get/get.dart';

import '../controllers/configure_controller.dart';

/// Wires [ConfigureController] lazily when the Configure route opens.
class ConfigureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConfigureController>(() => ConfigureController());
  }
}
