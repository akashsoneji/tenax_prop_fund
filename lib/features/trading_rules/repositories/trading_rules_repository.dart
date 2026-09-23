import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/rules_models.dart';

/// Single source of truth for Trading Rules data. Fetches the live
/// `GET /support/rules` rulebook (standard `{success, data}` envelope with
/// `data.tabs[]` and `data.sections{}`).
class TradingRulesRepository {
  TradingRulesRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<TradingRulesData>> getRules() {
    return ApiEnvelope.guard<TradingRulesData>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.supportRules),
      (data) => TradingRulesData.fromJson(
        data is Map ? data.cast<String, dynamic>() : const {},
      ),
    );
  }
}
