import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/reward_models.dart';

/// Loads reward balances, eligibility, accounts, and payout history from the
/// live finance API.
class RewardsRepository {
  RewardsRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<RewardsData>> getRewards({String status = ''}) async {
    final response = await _api.get<dynamic>(
      '/finance/rewards',
      query: {'status': status},
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

  Future<ApiResponse<void>> requestPayout({
    required double amount,
    required String currency,
    required String payoutMethodId,
    required String tradingAccountId,
  }) async {
    final response = await _api.post<dynamic>(
      '/finance/payouts',
      data: {
        'amount': amount,
        'currency': currency,
        'payout_method_id': int.tryParse(payoutMethodId) ?? payoutMethodId,
        'trading_account_id':
            int.tryParse(tradingAccountId) ?? tradingAccountId,
      },
    );
    final body = response.data;
    if (body is Map<String, dynamic> && body['success'] == true) {
      return ApiResponse.success(null);
    }
    final message = body is Map<String, dynamic>
        ? body['message']?.toString()
        : null;
    return ApiResponse.failure(message ?? 'Unable to request payout');
  }

}