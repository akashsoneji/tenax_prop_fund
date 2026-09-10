import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/kyc_docs_controller.dart';
import '../repositories/kyc_repository.dart';

class KycDocsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<KycRepository>()) {
      Get.lazyPut<KycRepository>(() => KycRepository(Get.find<ApiClient>()));
    }
    Get.lazyPut<KycDocsController>(
      () => KycDocsController(Get.find<KycRepository>()),
    );
  }
}
