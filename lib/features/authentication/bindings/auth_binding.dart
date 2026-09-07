import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';

/// Wires the auth controller. The repository is an app-wide singleton
/// (registered in InitialBinding) so the session persists across routes and
/// logout can reach it from anywhere.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController(Get.find<AuthRepository>()));
  }
}
