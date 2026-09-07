import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/kyc_controller.dart';
import '../repositories/kyc_repository.dart';

class KycBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KycRepository>(() => KycRepository(Get.find<ApiClient>()));
    Get.lazyPut<KycController>(
      () => KycController(Get.find<KycRepository>()),
    );
  }
}
