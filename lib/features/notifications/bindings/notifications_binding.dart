import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/notifications_controller.dart';
import '../repositories/notifications_repository.dart';

/// Wires [NotificationsController] (and its repository) for the Notifications
/// screen. Registered lazily so the flow only allocates when the user opens the
/// route.
class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsRepository>(
      () => NotificationsRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<NotificationsController>(
      () => NotificationsController(Get.find<NotificationsRepository>()),
    );
  }
}
