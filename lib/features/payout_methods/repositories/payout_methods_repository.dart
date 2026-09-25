import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../models/method_type.dart';
import '../models/payout_method.dart';

/// Payout-method CRUD + method types against the live finance API.
class PayoutMethodsRepository {
  PayoutMethodsRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<List<PayoutMethod>>> getPayoutMethods() async {
    final response = await _api.get<dynamic>(ApiEndpoints.financeMethods);
    final body = response.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      return ApiResponse.failure(_message(body, 'Unable to load payout methods'));
    }
    final data = body['data'];
    final methods = data is Map<String, dynamic> ? data['methods'] : data;
    return ApiResponse.success(
      methods is List
          ? methods.whereType<Map<String, dynamic>>().map(PayoutMethod.fromJson).toList()
          : <PayoutMethod>[],
    );
  }

  Future<ApiResponse<List<MethodType>>> getMethodTypes() async {
    final response = await _api.get<dynamic>(ApiEndpoints.financeMethodTypes);
    final body = response.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      return ApiResponse.failure(_message(body, 'Unable to load method types'));
    }
    final data = body['data'];
    final types = data is Map<String, dynamic>
        ? (data['method_types'] ?? data['types'])
        : data;
    return ApiResponse.success(
      types is List
          ? types.whereType<Map<String, dynamic>>().map(MethodType.fromJson).toList()
          : <MethodType>[],
    );
  }

  Future<ApiResponse<void>> createPayoutMethod({
    required String type,
    required String label,
    required String currency,
    required Map<String, dynamic> details,
  }) async {
    final response = await _api.post<dynamic>(
      ApiEndpoints.financeMethods,
      data: {
        'type': type,
        'label': label,
        'currency': currency,
        'is_default': true,
        'details': details,
      },
    );
    return _voidResult(response.data, 'Unable to add payout method');
  }

  Future<ApiResponse<void>> updatePayoutMethod({
    required String id,
    required String type,
    required String label,
    required String currency,
    required Map<String, dynamic> details,
  }) async {
    final response = await _api.put<dynamic>(
      '${ApiEndpoints.financeMethods}/$id',
      data: {
        'type': type,
        'label': label,
        'currency': currency,
        'details': details,
      },
    );
    return _voidResult(response.data, 'Unable to update payout method');
  }

  Future<ApiResponse<void>> deletePayoutMethod(String id) async {
    final response =
        await _api.delete<dynamic>('${ApiEndpoints.financeMethods}/$id');
    return _voidResult(response.data, 'Unable to delete payout method');
  }

  ApiResponse<void> _voidResult(dynamic body, String fallback) {
    if (body is Map<String, dynamic> && body['success'] == true) {
      return ApiResponse.success(null);
    }
    return ApiResponse.failure(_message(body, fallback));
  }

  String _message(dynamic body, String fallback) =>
      body is Map<String, dynamic>
          ? body['message']?.toString() ?? fallback
          : fallback;
}
