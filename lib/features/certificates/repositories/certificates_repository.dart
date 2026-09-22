import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/certificate_model.dart';

/// Single source of truth for certificate data. Fetches the live
/// `GET /growth/certificates` list and, for a single earned certificate, the
/// rendered document behind `GET /growth/certificates/{id}/download`.
class CertificatesRepository {
  CertificatesRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<CertificatesData>> getCertificates() {
    return ApiEnvelope.guard<CertificatesData>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.certificates),
      (data) => CertificatesData.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  Future<ApiResponse<CertificateDocument>> getCertificateDocument(int id) {
    return ApiEnvelope.guard<CertificateDocument>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.certificateDownload(id),
      ),
      (data) => CertificateDocument.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }
}
