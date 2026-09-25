import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/reward_models.dart';

/// Loads reward balances, eligibility, accounts, payout history, and method
/// types from the live finance API.
/// One page of payout history plus its pagination meta.
class PayoutHistoryPage {
  const PayoutHistoryPage({required this.items, required this.meta});

  final List<PayoutHistoryItem> items;
  final PageMeta meta;
}

class RewardsRepository {
  RewardsRepository(this._api);

  final ApiClient _api;

  /// STEP 1 — Full rewards page (stats + accounts + methods + payouts).
  Future<ApiResponse<RewardsData>> getRewards({
    String status = 'all',
    int page = 1,
  }) async {
    final response = await _api.get<dynamic>(
      ApiEndpoints.financeRewards,
      query: {'status': status, 'page': page},
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      return ApiResponse.failure('Unable to load rewards');
    }
    if (body['success'] != true || body['data'] == null) {
      return ApiResponse.failure(
        body['message']?.toString() ?? 'Unable to load rewards',
      );
    }
    return ApiResponse.success(RewardsData.fromJson(body['data']));
  }

  /// STEP 2 — Payout method types (bank / usdt / upi) with field definitions.
  Future<ApiResponse<MethodTypesResponse>> getMethodTypes() async {
    final response = await _api.get<dynamic>(ApiEndpoints.financeMethodTypes);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      return ApiResponse.failure('Unable to load method types');
    }
    if (body['success'] != true || body['data'] == null) {
      return ApiResponse.failure(
        body['message']?.toString() ?? 'Unable to load method types',
      );
    }
    return ApiResponse.success(
        MethodTypesResponse.fromJson(body['data'] as Map<String, dynamic>));
  }

  /// STEP 3 — Saved payout methods.
  Future<ApiResponse<List<RewardPayoutMethod>>> getMethods() async {
    final response = await _api.get<dynamic>(ApiEndpoints.financeMethods);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      return ApiResponse.failure('Unable to load payout methods');
    }
    if (body['success'] != true || body['data'] == null) {
      return ApiResponse.failure(
        body['message']?.toString() ?? 'Unable to load payout methods',
      );
    }
    final methods = (body['data']['methods'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(RewardPayoutMethod.fromJson)
            .toList() ??
        <RewardPayoutMethod>[];
    return ApiResponse.success(methods);
  }

  /// STEP 4 — Add a payout method.
  Future<ApiResponse<void>> createMethod({
    required String type,
    required String label,
    required String currency,
    required Map<String, dynamic> details,
    bool isDefault = true,
  }) async {
    final payload = <String, dynamic>{
      'type': type,
      'label': label,
      'currency': currency,
      'is_default': isDefault,
      'details': details,
    };
    final response = await _api.post<dynamic>(
      ApiEndpoints.financeMethods,
      data: payload,
    );
    final body = response.data;
    if (body is Map<String, dynamic> && body['success'] == true) {
      return ApiResponse.success(null);
    }
    final message = body is Map<String, dynamic>
        ? body['message']?.toString()
        : null;
    return ApiResponse.failure(message ?? 'Unable to save method');
  }

  /// STEP 5 — Edit a payout method.
  Future<ApiResponse<void>> updateMethod({
    required int methodId,
    String? label,
    Map<String, dynamic>? details,
    bool? isDefault,
  }) async {
    final payload = <String, dynamic>{};
    if (label != null) payload['label'] = label;
    if (details != null) payload['details'] = details;
    if (isDefault != null) payload['is_default'] = isDefault;

    final response = await _api.put<dynamic>(
      '${ApiEndpoints.financeMethods}/$methodId',
      data: payload,
    );
    final body = response.data;
    if (body is Map<String, dynamic> && body['success'] == true) {
      return ApiResponse.success(null);
    }
    final message = body is Map<String, dynamic>
        ? body['message']?.toString()
        : null;
    return ApiResponse.failure(message ?? 'Unable to update method');
  }

  /// STEP 6 — Delete a payout method.
  Future<ApiResponse<void>> deleteMethod(int methodId) async {
    final response = await _api.delete<dynamic>(
      '${ApiEndpoints.financeMethods}/$methodId',
    );
    final body = response.data;
    if (body is Map<String, dynamic> && body['success'] == true) {
      return ApiResponse.success(null);
    }
    final message = body is Map<String, dynamic>
        ? body['message']?.toString()
        : null;
    return ApiResponse.failure(message ?? 'Unable to delete method');
  }

  /// STEP 7 — Submit payout (reward) request.
  Future<ApiResponse<void>> requestPayout({
    required double amount,
    required String currency,
    required String payoutMethodId,
    String? tradingAccountId,
    String? notes,
    String? currentPassword,
  }) async {
    final payload = <String, dynamic>{
      'amount': amount,
      'currency': currency,
      'payout_method_id':
          int.tryParse(payoutMethodId) ?? payoutMethodId,
      if (tradingAccountId != null)
        'trading_account_id':
            int.tryParse(tradingAccountId) ?? tradingAccountId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (currentPassword != null && currentPassword.isNotEmpty)
        'current_password': currentPassword,
    };
    // guard() catches the DioException a 422 throws (e.g. "No open payout
    // cycle is available right now.") and shows the server message as a toast.
    return ApiEnvelope.guard<void>(
      () => _api.post<dynamic>(ApiEndpoints.financePayouts, data: payload),
      (_) {},
    );
  }

  /// Paged payout requests (`GET /finance/payouts?status=&page=`). `data` is a
  /// flat list; `meta` carries `current_page` / `has_next` / `total`.
  Future<ApiResponse<PayoutHistoryPage>> getPayouts({
    String status = 'all',
    int page = 1,
  }) {
    return ApiEnvelope.guardBody<PayoutHistoryPage>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.financePayouts,
        query: {'status': status, 'page': page},
      ),
      (body) {
        final list = (body['data'] as List?) ?? const [];
        final meta = body['meta'] is Map<String, dynamic>
            ? PageMeta.fromJson(body['meta'] as Map<String, dynamic>)
            : PageMeta.empty;
        return PayoutHistoryPage(
          items: list
              .whereType<Map<String, dynamic>>()
              .map(PayoutHistoryItem.fromJson)
              .toList(),
          meta: meta,
        );
      },
    );
  }

  /// STEP 8 — Cancel a pending payout request.
  Future<ApiResponse<void>> cancelPayout(int payoutId) async {
    final response = await _api.post<dynamic>(
      ApiEndpoints.financePayoutCancel(payoutId),
    );
    final body = response.data;
    if (body is Map<String, dynamic> && body['success'] == true) {
      return ApiResponse.success(null);
    }
    final message = body is Map<String, dynamic>
        ? body['message']?.toString()
        : null;
    return ApiResponse.failure(message ?? 'Unable to cancel payout');
  }
}