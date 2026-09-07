import 'package:get/get.dart';

import '../controllers/edit_profile_controller.dart';
import '../controllers/kyc_controller.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    final seed = Get.isRegistered<KycController>()
        ? Get.find<KycController>().profile
        : null;
    Get.lazyPut<EditProfileController>(
      () => EditProfileController(seed: seed),
    );
  }
}
