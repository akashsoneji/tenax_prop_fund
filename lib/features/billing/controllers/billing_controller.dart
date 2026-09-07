import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/billing_models.dart';
import '../repositories/billing_repository.dart';

/// Backs the Billing history screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<BillingData>`; this class
/// only adds the screen's UI state (the active filter) and the derived filtered
/// transaction list. Swap the repository for the real API and nothing here or in
/// the view changes.
class BillingController extends BaseController<BillingData> {
  BillingController(this._repository);

  final BillingRepository _repository;

  /// The active filter tab.
  final filter = BillingFilter.all.obs;

  void setFilter(BillingFilter f) => filter.value = f;

  @override
  Future<ApiResponse<BillingData>> fetch() => _repository.getBilling();

  @override
  bool isEmpty(BillingData data) => data.isEmpty;

  /// Transactions filtered by the active tab, from the loaded data.
  List<BillingTransaction> filteredTransactions(BillingData data) {
    if (filter.value == BillingFilter.all) return data.transactions;
    return data.transactions
        .where((t) => t.category == filter.value)
        .toList();
  }
}
