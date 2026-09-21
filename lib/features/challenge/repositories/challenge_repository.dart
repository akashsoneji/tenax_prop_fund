import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/challenge_models.dart';

/// Loads challenge catalogue and pricing data from the live REST API.
class ChallengeRepository {
  ChallengeRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<ChallengeData>> getPlans({String currency = 'USD'}) {
    return ApiEnvelope.guard<ChallengeData>(
      () => _api.get<Map<String, dynamic>>(
        '/challenges',
        query: {'currency': currency},
      ),
      (data) => ChallengeData.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  Future<ApiResponse<ChallengeData>> compare({String currency = 'USD'}) {
    return ApiEnvelope.guard<ChallengeData>(
      () => _api.post<Map<String, dynamic>>(
        '/challenges/compare?currency=$currency',
      ),
      (data) => ChallengeData.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  Future<ApiResponse<ChallengeQuote>> quote({
    required int planVersionId,
    List<int> addonIds = const [],
    String currency = 'USD',
  }) {
    return ApiEnvelope.guard<ChallengeQuote>(
      () => _api.post<Map<String, dynamic>>(
        '/challenges/quote?currency=$currency',
        data: {
          'plan_version_id': planVersionId,
          'addon_ids': addonIds,
        },
      ),
      (data) => ChallengeQuote.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  /// Validates a coupon against a plan version and returns the discounted quote.
  /// The server surfaces an invalid coupon as a top-level `message`, so error
  /// toasting is disabled here and the caller shows the message inline instead.
  Future<ApiResponse<ChallengeQuote>> applyCoupon({
    required int planVersionId,
    required String couponCode,
  }) {
    return ApiEnvelope.guard<ChallengeQuote>(
      () => _api.post<Map<String, dynamic>>(
        '/challenges/coupon',
        data: {
          'plan_version_id': planVersionId,
          'coupon_code': couponCode,
        },
      ),
      (data) => ChallengeQuote.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
      showErrorToast: false,
    );
  }

  /// Creates an order for the configured plan and returns the payment path
  /// (`free` / `manual` / `gateway`).
  Future<ApiResponse<PurchaseResult>> purchase({
    required int planVersionId,
    List<int> addonIds = const [],
    String? couponCode,
    required int paymentMethodId,
    required bool isManual,
  }) {
    return ApiEnvelope.guard<PurchaseResult>(
      () => _api.post<Map<String, dynamic>>(
        '/challenges/purchase',
        data: {
          'plan_version_id': planVersionId,
          'addon_ids': addonIds,
          'coupon_code': couponCode,
          'payment_method_id': paymentMethodId,
          'is_manual': isManual,
        },
      ),
      (data) => PurchaseResult.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }
}
