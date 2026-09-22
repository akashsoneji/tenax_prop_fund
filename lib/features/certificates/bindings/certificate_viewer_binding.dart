import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/certificate_viewer_controller.dart';
import '../models/certificate_model.dart';
import '../repositories/certificates_repository.dart';

/// Wires [CertificateViewerController] for the single-certificate viewer. The
/// [Certificate] arrives as route arguments; the repository is shared with the
/// list screen when that one is still alive.
class CertificateViewerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CertificatesRepository>(
      () => CertificatesRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<CertificateViewerController>(
      () => CertificateViewerController(
        Get.find<CertificatesRepository>(),
        Get.arguments as Certificate,
      ),
    );
  }
}
