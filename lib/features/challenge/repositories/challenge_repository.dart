import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/challenge_models.dart';

/// Loads challenge catalogue and pricing data from the live REST API.
class ChallengeRepository {
  ChallengeRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<ChallengeData>> getPlans({String currency = 'USD'}) {
    return ApiEnvelope.guard<ChallengeData>(
      () => _api.get<Map<String, dynamic>>(
        '/challenges',
        query: {'currency': currency},
      ),
      (data) => ChallengeData.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  Future<ApiResponse<ChallengeData>> compare({String currency = 'USD'}) {
    return ApiEnvelope.guard<ChallengeData>(
      () => _api.post<Map<String, dynamic>>(
        '/challenges/compare?currency=$currency',
      ),
      (data) => ChallengeData.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  Future<ApiResponse<ChallengeQuote>> quote({
    required int planVersionId,
    List<int> addonIds = const [],
    String currency = 'USD',
  }) {
    return ApiEnvelope.guard<ChallengeQuote>(
      () => _api.post<Map<String, dynamic>>(
        '/challenges/quote?currency=$currency',
        data: {
          'plan_version_id': planVersionId,
          'addon_ids': addonIds,
        },
      ),
      (data) => ChallengeQuote.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }
}
