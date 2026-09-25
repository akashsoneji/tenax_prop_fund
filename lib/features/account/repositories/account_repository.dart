import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/account_models.dart';

/// Single source of truth for the Account detail screen. All three tabs are on
/// live REST endpoints (standard `{success, data}` envelope):
///  - Overview  → `GET /accounts/{id}/overview` → [AccountData.fromJson]
///  - Platform  → `GET /accounts/{id}/platform?reveal=` → [PlatformData.fromJson]
///  - Reset     → `GET /accounts/{id}/reset` → [ResetData.fromJson]
class AccountRepository {
  AccountRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<AccountData>> getOverview(Object accountId) {
    return ApiEnvelope.guard<AccountData>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.accountDetail(accountId),
      ),
      (data) => AccountData.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  Future<ApiResponse<PlatformData>> getPlatform(
    Object accountId, {
    bool reveal = false,
  }) {
    return ApiEnvelope.guard<PlatformData>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.accountPlatform(accountId, reveal: reveal),
      ),
      (data) => PlatformData.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  Future<ApiResponse<ResetData>> getReset(Object accountId) {
    return ApiEnvelope.guard<ResetData>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.accountReset(accountId),
      ),
      (data) => ResetData.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  /// Confirms the reset purchase (`POST /accounts/{id}/reset`). Returns the
  /// created order id so the caller can open the Complete-payment screen.
  Future<ApiResponse<String>> confirmReset(
    Object accountId, {
    required int paymentMethodId,
    required bool isManual,
  }) {
    return ApiEnvelope.guard<String>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.accountReset(accountId),
        data: {
          'confirm': true,
          'payment_method_id': paymentMethodId,
          'is_manual': isManual,
        },
      ),
      (data) {
        final map = data is Map<String, dynamic> ? data : const {};
        final direct = map['order_id'] ??
            (map['order'] is Map ? (map['order'] as Map)['id'] : null);
        if (direct != null) return direct.toString();
        // The live API only returns the order inside the checkout path,
        // e.g. `/app/challenges/orders/58/pay`.
        final match = RegExp(r'/orders/(\d+)')
            .firstMatch(map['checkout_url']?.toString() ?? '');
        return match?.group(1) ?? '';
      },
    );
  }
}
