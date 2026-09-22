import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/certificate_model.dart';
import '../repositories/certificates_repository.dart';

/// Drives the Certificates screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<CertificatesData>`.
class CertificatesController extends BaseController<CertificatesData> {
  CertificatesController(this._repository);

  final CertificatesRepository _repository;

  @override
  Future<ApiResponse<CertificatesData>> fetch() =>
      _repository.getCertificates();

  @override
  bool isEmpty(CertificatesData data) => data.certificates.isEmpty;

  /// Opens the certificate viewer. A locked certificate has no document to
  /// render, so it only explains why instead of pushing an empty screen.
  void openCertificate(Certificate certificate) {
    if (!certificate.earned) {
      AppToast.info('certificates.lockedHint'.tr);
      return;
    }
    Get.toNamed(AppRoutes.certificateViewer, arguments: certificate);
  }
}
