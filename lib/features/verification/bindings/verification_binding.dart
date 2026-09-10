import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../kyc/repositories/kyc_repository.dart';
import '../controllers/verification_controller.dart';

class VerificationBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<KycRepository>()) {
      Get.lazyPut<KycRepository>(() => KycRepository(Get.find<ApiClient>()));
    }
    Get.lazyPut<VerificationController>(
      () => VerificationController(Get.find<KycRepository>()),
    );
  }
}
