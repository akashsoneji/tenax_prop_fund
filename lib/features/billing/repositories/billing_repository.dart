import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/billing_models.dart';

/// Single source of truth for billing data. Currently serves STATIC demo data
/// for the Billing history screen; the [ApiClient] dependency is retained so
/// the binding/controller wiring stays unchanged when live wiring returns.
class BillingRepository {
  BillingRepository(this._api);

  // ignore: unused_field
  final ApiClient _api;

  Future<ApiResponse<BillingData>> getBilling() {
    return Future.value(ApiResponse.success(_demoBilling));
  }
}

const _demoBilling = BillingData(
  stats: [
    BillingStat(label: 'Paid', value: '\$634'),
    BillingStat(label: 'Refunded', value: '\$69'),
    BillingStat(label: 'Net', value: '\$565'),
    BillingStat(label: 'Invoices', value: '4'),
  ],
  transactions: [
    BillingTransaction(
      title: 'Pipze 2-Step · \$100K Challenge',
      reference: 'INV-100482 · Aug 2 · Visa ··4821',
      amount: '\$335',
      status: BillingStatus.paid,
      category: BillingFilter.challenge,
    ),
    BillingTransaction(
      title: 'Pipze 1-Step · \$50K Challenge',
      reference: 'INV-100377 · Jul 18 · Visa ··4821',
      amount: '\$199',
      status: BillingStatus.paid,
      category: BillingFilter.challenge,
    ),
    BillingTransaction(
      title: 'Add-on · 90% Profit Split',
      reference: 'INV-100355 · Jul 4 · Mastercard ··9032',
      amount: '\$100',
      status: BillingStatus.paid,
      category: BillingFilter.addOn,
    ),
    BillingTransaction(
      title: 'Refund · \$25K Challenge',
      reference: 'INV-100301 · Jun 21 · Visa ··4821',
      amount: '-\$69',
      status: BillingStatus.refunded,
      category: BillingFilter.refund,
    ),
  ],
);
