import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/accounts_models.dart';

/// Single source of truth for Account Center data. Calls the live
/// `GET /accounts?status=all&phase=all` endpoint (standard
/// `{success, message, data[], meta}` envelope). Every owned account comes back
/// in one page (`status=all&phase=all`) so the screen filters client-side
/// without a refetch per tab. The controller and view never change when the
/// data source does — that is the point of this layer.
class AccountsRepository {
  AccountsRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<AccountsData>> getAccounts() {
    return ApiEnvelope.guard<AccountsData>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.accounts,
        query: const {'status': 'all', 'phase': 'all'},
      ),
      (data) => AccountsData.fromList(data is List ? data : const []),
    );
  }
}
