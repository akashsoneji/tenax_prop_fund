import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/accounts_models.dart';
import '../repositories/accounts_repository.dart';

/// Drives the "Account Center" screen. Data loading (skeleton / error / empty)
/// is handled by [BaseController] via a single `DataState<AccountsData>`; this
/// class only adds the screen's UI state (selected status tab, search query,
/// plan filter) and the derived list getter. Filtering is client-side because
/// the repository fetches every owned account in one call.
class AccountsController extends BaseController<AccountsData> {
  AccountsController(this._repository);

  final AccountsRepository _repository;

  /// Selected status tab (Active / Funded / Completed / Breached / All).
  final selectedTab = AccountTab.all.obs;

  /// Free-text login-ID search.
  final query = ''.obs;

  /// Selected plan filter; empty string = "All plans".
  final planFilter = ''.obs;

  void selectTab(AccountTab tab) => selectedTab.value = tab;
  void setQuery(String value) => query.value = value.trim();
  void setPlanFilter(String plan) => planFilter.value = plan;

  @override
  Future<ApiResponse<AccountsData>> fetch() => _repository.getAccounts();

  @override
  bool isEmpty(AccountsData data) => data.isEmpty;

  /// The accounts left after applying the tab, search and plan filters.
  List<AccountRow> visibleAccounts(AccountsData data) {
    final tab = selectedTab.value;
    final q = query.value.toLowerCase();
    final plan = planFilter.value;
    return data.accounts.where((a) {
      if (tab != AccountTab.all && a.tab != tab) return false;
      if (plan.isNotEmpty && a.planName != plan) return false;
      if (q.isNotEmpty && !a.login.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }
}
