import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/kyc_controller.dart';
import '../repositories/kyc_repository.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<KycRepository>()) {
      Get.lazyPut<KycRepository>(() => KycRepository(Get.find<ApiClient>()));
    }
    final seed = Get.isRegistered<KycController>()
        ? Get.find<KycController>().profile
        : null;
    Get.lazyPut<EditProfileController>(
      () => EditProfileController(Get.find<KycRepository>(), seed: seed),
    );
  }
}
