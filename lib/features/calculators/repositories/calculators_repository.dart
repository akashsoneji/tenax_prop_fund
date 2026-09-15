import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/calculator_models.dart';

class CalculatorsRepository {
  CalculatorsRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<CalculatorsData>> getCalculators() {
    return ApiEnvelope.guard<CalculatorsData>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.calculators),
      (data) => CalculatorsData.fromJson(
        data is Map ? Map<String, dynamic>.from(data) : const {},
      ),
    );
  }
}
