import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/competition_models.dart';

/// Single source of truth for competition data. Fetches the live
/// `GET /growth/competitions` endpoint (standard `{success, message, data}`
/// envelope) and maps `data` through [CompetitionsData.fromJson]. The
/// controller and views do not change when the data source does.
class CompetitionsRepository {
  CompetitionsRepository(this._api);

  final ApiClient _api;

  /// Enters [competitionId] with [tradingAccountId]. The endpoint returns a
  /// null `data`, so the envelope's user-facing `message` is what comes back.
  Future<ApiResponse<String>> register({
    required int competitionId,
    required int tradingAccountId,
  }) {
    return ApiEnvelope.guardBody<String>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.competitionRegister,
        data: {
          'competition_id': competitionId,
          'trading_account_id': tradingAccountId,
        },
      ),
      (body) => body['message'] as String? ?? '',
    );
  }

  Future<ApiResponse<CompetitionsData>> getCompetitions() {
    return ApiEnvelope.guard<CompetitionsData>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.competitions),
      (data) => CompetitionsData.fromJson(
        (data as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
