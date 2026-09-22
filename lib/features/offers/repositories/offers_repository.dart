import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/offer_models.dart';

/// Single source of truth for offers data. Fetches the live
/// `GET /growth/offers` endpoint (standard `{success, message, data}` envelope)
/// and maps `data` into [OffersData].
class OffersRepository {
  OffersRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<OffersData>> getOffers() {
    return ApiEnvelope.guard<OffersData>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.offers),
      (data) => OffersData.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }
}
