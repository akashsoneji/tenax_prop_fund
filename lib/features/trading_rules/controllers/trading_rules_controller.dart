import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../core/state/data_state.dart';
import '../models/rules_models.dart';
import '../repositories/trading_rules_repository.dart';

/// Drives the Trading Rules screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<TradingRulesData>`; this
/// class only adds the screen's UI state (the selected top tab, keyed by the
/// tab `value` the API returns).
class TradingRulesController extends BaseController<TradingRulesData> {
  TradingRulesController(this._repository);

  final TradingRulesRepository _repository;

  /// `value` of the currently selected tab. Empty until the first load.
  final selectedTab = ''.obs;

  List<RulesTab> get tabs {
    final current = state;
    return current is DataSuccess<TradingRulesData>
        ? current.data.tabs
        : const <RulesTab>[];
  }

  void selectTab(String value) {
    if (selectedTab.value == value) return;
    selectedTab.value = value;
  }

  @override
  Future<ApiResponse<TradingRulesData>> fetch() async {
    final res = await _repository.getRules();
    final data = res.data;
    if (data != null && data.tabs.isNotEmpty) {
      final hasSelection = data.tabs.any((t) => t.value == selectedTab.value);
      if (!hasSelection) selectedTab.value = data.tabs.first.value;
    }
    return res;
  }

  @override
  bool isEmpty(TradingRulesData data) => data.isEmpty;
}
