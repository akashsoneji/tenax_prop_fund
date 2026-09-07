import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/competitions_controller.dart';
import '../repositories/competitions_repository.dart';

/// Wires [CompetitionsController] (and its repository) lazily when the
/// Competitions route opens.
class CompetitionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompetitionsRepository>(
      () => CompetitionsRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<CompetitionsController>(
      () => CompetitionsController(Get.find<CompetitionsRepository>()),
    );
  }
}
