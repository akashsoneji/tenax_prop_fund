import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../../payout_methods/models/payout_method.dart';
import '../models/referral_models.dart';

/// One page of the commission history: the rows plus the pagination meta so
/// the controller knows whether more pages exist.
class ReferralCommissionsPage {
  const ReferralCommissionsPage({required this.items, required this.meta});

  final List<Referral> items;
  final PageMeta meta;
}

/// Single source of truth for referral data. Fetches the live
/// `GET /growth/referrals` endpoint (standard `{success, message, data}`
/// envelope) and maps `data` through [ReferralData.fromProps]. The controller
/// and view do not change when the data source does — that is the point of
/// this layer.
class ReferralRepository {
  ReferralRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<ReferralData>> getReferral() {
    return ApiEnvelope.guard<ReferralData>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.referrals),
      (data) => ReferralData.fromProps(
        (data as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  /// Paged commission history. `data` is a flat array; `meta` carries paging.
  Future<ApiResponse<ReferralCommissionsPage>> getCommissions({int page = 1}) {
    return ApiEnvelope.guardBody<ReferralCommissionsPage>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.referralCommissions,
        query: {'page': page},
      ),
      (body) {
        final list = (body['data'] as List?) ?? const [];
        final items = list
            .whereType<Map<String, dynamic>>()
            .map(Referral.fromJson)
            .toList();
        final meta = body['meta'] is Map<String, dynamic>
            ? PageMeta.fromJson(body['meta'] as Map<String, dynamic>)
            : PageMeta.empty;
        return ReferralCommissionsPage(items: items, meta: meta);
      },
    );
  }

  /// Saved payout destinations (`data.methods[]`) the withdrawal is sent to.
  Future<ApiResponse<List<PayoutMethod>>> getPayoutMethods() {
    return ApiEnvelope.guard<List<PayoutMethod>>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.financeMethods),
      (data) {
        final methods = data is Map ? data['methods'] : data;
        return methods is List
            ? methods
                  .whereType<Map<String, dynamic>>()
                  .map(PayoutMethod.fromJson)
                  .toList()
            : <PayoutMethod>[];
      },
    );
  }

  /// Requests a referral-earnings withdrawal. Returns the server's message
  /// (e.g. "finance will review it…") so the UI can show it verbatim.
  Future<ApiResponse<String>> withdraw({
    required double amount,
    required String payoutMethodId,
  }) {
    return ApiEnvelope.guardBody<String>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.referralWithdraw,
        data: {
          'amount': amount,
          'payout_method_id': int.tryParse(payoutMethodId) ?? payoutMethodId,
        },
      ),
      (body) => body['message'] as String? ?? '',
    );
  }
}
