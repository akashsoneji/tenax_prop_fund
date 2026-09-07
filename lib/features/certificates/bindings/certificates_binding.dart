import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/certificates_controller.dart';
import '../repositories/certificates_repository.dart';

/// Wires [CertificatesController] (and its repository) for the Certificates
/// screen. Registered lazily so the flow only allocates when the user opens the
/// route.
class CertificatesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CertificatesRepository>(
      () => CertificatesRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<CertificatesController>(
      () => CertificatesController(Get.find<CertificatesRepository>()),
    );
  }
}
