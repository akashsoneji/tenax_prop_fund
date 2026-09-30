import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_status_controller.dart';
import 'maintenance_screen.dart';

/// Global overlay stacked over the MaterialApp so the maintenance screen can
/// take over the whole viewport regardless of the current route. The force
/// update dialog uses [Get.dialog] and does not need this overlay.
class AppStatusOverlay extends StatelessWidget {
  const AppStatusOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AppStatusController>()) return const SizedBox.shrink();
    final controller = Get.find<AppStatusController>();

    return Obx(() {
      if (!controller.isMaintenanceMode.value) return const SizedBox.shrink();
      return const Positioned.fill(child: MaintenanceScreen());
    });
  }
}
