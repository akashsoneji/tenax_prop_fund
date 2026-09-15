import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/payout_method.dart';

/// Loads configured payout methods from the live finance API.
class PayoutMethodsRepository {
  PayoutMethodsRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<List<PayoutMethod>>> getPayoutMethods() async {
    final response = await _api.get<dynamic>('/finance/methods');
    final body = response.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      return ApiResponse.failure(
        body is Map<String, dynamic>
            ? body['message']?.toString() ?? 'Unable to load payout methods'
            : 'Unable to load payout methods',
      );
    }
    final data = body['data'];
    final methods = data is Map<String, dynamic> ? data['methods'] : null;
    return ApiResponse.success(
      methods is List
          ? methods.whereType<Map<String, dynamic>>().map(PayoutMethod.fromJson).toList()
          : <PayoutMethod>[],
    );
  }

  Future<ApiResponse<void>> createPayoutMethod({
    required String type,
    required String label,
    required String currency,
    required Map<String, dynamic> details,
  }) async {
    final response = await _api.post<dynamic>(
      '/finance/methods',
      data: {
        'type': type,
        'label': label,
        'currency': currency,
        'is_default': true,
        'details': details,
      },
    );
    final body = response.data;
    if (body is Map<String, dynamic> && body['success'] == true) {
      return ApiResponse.success(null);
    }
    return ApiResponse.failure(
      body is Map<String, dynamic>
          ? body['message']?.toString() ?? 'Unable to add payout method'
          : 'Unable to add payout method',
    );
  }
}
