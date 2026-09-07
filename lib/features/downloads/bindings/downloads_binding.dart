import 'package:get/get.dart';

import '../controllers/downloads_controller.dart';
import '../repositories/downloads_repository.dart';

/// Wires [DownloadsController] (and its repository) lazily when the Downloads
/// route opens.
class DownloadsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DownloadsRepository>(() => DownloadsRepository());
    Get.lazyPut<DownloadsController>(
      () => DownloadsController(Get.find<DownloadsRepository>()),
    );
  }
}
