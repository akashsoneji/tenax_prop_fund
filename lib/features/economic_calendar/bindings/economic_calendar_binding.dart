import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/economic_calendar_controller.dart';
import '../repositories/economic_calendar_repository.dart';

/// Wires [EconomicCalendarController] (and its repository) lazily when the route
/// opens.
class EconomicCalendarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EconomicCalendarRepository>(
        () => EconomicCalendarRepository(Get.find<ApiClient>()));
    Get.lazyPut<EconomicCalendarController>(
      () => EconomicCalendarController(Get.find<EconomicCalendarRepository>()),
    );
  }
}
