import 'package:get/get.dart';

import '../controllers/support_controller.dart';
import '../repositories/support_repository.dart';

/// Wires [SupportController] (and its repository) lazily for the Support
/// screen. Registered lazily so the flow only allocates when the user opens
/// the route.
class SupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupportRepository>(() => SupportRepository());
    Get.lazyPut<SupportController>(
      () => SupportController(Get.find<SupportRepository>()),
    );
  }
}
