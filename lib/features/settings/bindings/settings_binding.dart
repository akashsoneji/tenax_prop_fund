import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/security_controller.dart';
import '../repositories/security_repository.dart';

/// SettingsController is a permanent singleton registered before runApp, so it
/// is not wired here. The Security section's controller/repository are, since
/// they only live for as long as the Settings route.
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SecurityRepository>(
      () => SecurityRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<SecurityController>(
      () => SecurityController(Get.find<SecurityRepository>()),
    );
  }
}
