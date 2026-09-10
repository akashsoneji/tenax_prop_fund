import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/referral_models.dart';

/// Single source of truth for referral data. Fetches the live
/// `GET /growth/referrals` endpoint (standard `{success, message, data}`
/// envelope) and maps `data` through [ReferralData.fromProps]. The controller
/// and view do not change when the data source does — that is the point of
/// this layer.
class ReferralRepository {
  ReferralRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<ReferralData>> getReferral() {
    return ApiEnvelope.guard<ReferralData>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.referrals),
      (data) => ReferralData.fromProps(
        (data as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
