import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/certificate_model.dart';
import '../repositories/certificates_repository.dart';

/// Drives the Certificates screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<List<Certificate>>`;
/// swap the repository for the real API and nothing here or in the view
/// changes.
class CertificatesController extends BaseController<List<Certificate>> {
  CertificatesController(this._repository);

  final CertificatesRepository _repository;

  @override
  Future<ApiResponse<List<Certificate>>> fetch() =>
      _repository.getCertificates();

  @override
  bool isEmpty(List<Certificate> data) => data.isEmpty;
}
