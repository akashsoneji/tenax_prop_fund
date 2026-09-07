import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/rules_models.dart';
import '../repositories/trading_rules_repository.dart';

/// Drives the Trading Rules screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<TradingRulesData>`; this
/// class only adds the screen's UI state (the selected top tab). Swap the
/// repository for the real API and nothing here or in the view changes.
class TradingRulesController extends BaseController<TradingRulesData> {
  TradingRulesController(this._repository);

  final TradingRulesRepository _repository;

  // ---------------------------------------------------------------------------
  // Tab state
  // ---------------------------------------------------------------------------

  /// Currently selected top tab.
  final selectedTab = RulesTab.closes.obs;

  /// Cycle order for prev/next navigation gestures.
  static const _tabOrder = RulesTab.values;

  void selectTab(RulesTab tab) {
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
  }

  RulesTab get nextTab {
    final i = _tabOrder.indexOf(selectedTab.value);
    return _tabOrder[(i + 1) % _tabOrder.length];
  }

  @override
  Future<ApiResponse<TradingRulesData>> fetch() => _repository.getRules();

  @override
  bool isEmpty(TradingRulesData data) => data.isEmpty;
}
