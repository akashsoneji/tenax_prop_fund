import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/payout_method.dart';

/// Single source of truth for payout-method data. Currently serves STATIC DEMO
/// DATA; the [ApiClient] dependency is retained so this can be re-wired to the
/// live payout API without touching the binding or controller.
class PayoutMethodsRepository {
  PayoutMethodsRepository(this._api);

  // ignore: unused_field
  final ApiClient _api;

  Future<ApiResponse<List<PayoutMethod>>> getPayoutMethods() {
    return Future.value(
      ApiResponse.success(<PayoutMethod>[
        const PayoutMethod(
          name: 'Bank Transfer',
          meta: 'USD · 1–3 business days',
          description: 'Withdraw directly to your linked bank account.',
          isSetUp: true,
        ),
        const PayoutMethod(
          name: 'Crypto (USDT)',
          meta: 'TRC-20 · within 24 hours',
          description: 'Fast payouts to your USDT wallet address.',
        ),
      ]),
    );
  }
}
