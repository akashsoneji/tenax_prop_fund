import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/faq_controller.dart';
import '../repositories/faq_repository.dart';

/// Wires [FaqController] (and its repository) lazily when the FAQ route opens.
class FaqBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FaqRepository>(() => FaqRepository(Get.find<ApiClient>()));
    Get.lazyPut<FaqController>(
      () => FaqController(Get.find<FaqRepository>()),
    );
  }
}
