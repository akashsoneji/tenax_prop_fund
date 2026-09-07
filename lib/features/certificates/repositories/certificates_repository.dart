import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/certificate_model.dart';

/// Single source of truth for certificate data. Currently returns static demo
/// certificates instead of calling the live `GET /growth/certificates`
/// endpoint. The [ApiClient] dependency is retained so the repository can be
/// switched back to a live fetch without changing its callers.
class CertificatesRepository {
  CertificatesRepository(this._api);

  // ignore: unused_field
  final ApiClient _api;

  Future<ApiResponse<List<Certificate>>> getCertificates() =>
      Future.value(ApiResponse.success(_demoCertificates));

  static const List<Certificate> _demoCertificates = [
    Certificate(
      title: 'Funded Trader',
      description: 'Awarded when you pass the challenge and receive funding.',
      status: CertificateStatus.earned,
    ),
    Certificate(
      title: 'Consistency Master',
      description: 'Keep your daily results steady across 30 trading days.',
      status: CertificateStatus.locked,
      progress: 0.6,
    ),
  ];
}
