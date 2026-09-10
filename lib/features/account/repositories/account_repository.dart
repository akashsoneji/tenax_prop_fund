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

}
