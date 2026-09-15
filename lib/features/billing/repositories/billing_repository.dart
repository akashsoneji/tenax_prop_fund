import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/billing_models.dart';

/// Loads billing history from the live finance API.
class BillingRepository {
  BillingRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<BillingData>> getBilling({
    BillingFilter filter = BillingFilter.all,
    String status = 'all',
  }) async {
    final response = await _api.get<dynamic>(
      '/finance/transactions',
      query: {
        'type': filter == BillingFilter.all ? 'all' : filter.name,
        'status': status,
      },
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      return ApiResponse.failure('Unable to load billing history');
    }
    if (body['success'] != true) {
      return ApiResponse.failure(
        body['message']?.toString() ?? 'Unable to load billing history',
      );
    }
    return ApiResponse.success(BillingData.fromJson(body['data']));
  }

  Future<ApiResponse<String>> exportBilling() async {
    final response = await _api.get<dynamic>('/finance/transactions/export');
    final csv = response.data?.toString();
    if (csv == null || csv.isEmpty) {
      return ApiResponse.failure('Unable to export billing history');
    }
    return ApiResponse.success(csv);
  }
}
