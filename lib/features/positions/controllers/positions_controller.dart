import 'package:get/get.dart';

import '../../../core/state/data_state.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../accounts/controllers/accounts_controller.dart';
import '../../accounts/models/accounts_models.dart';
import '../../accounts/repositories/accounts_repository.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/models/dashboard_models.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import '../models/positions_models.dart';
import '../repositories/positions_repository.dart';
import '../services/account_ws_service.dart';
import '../services/positions_ws_service.dart';

/// The three tabs of the Positions screen.
enum PositionsTab { market, pending, history }

/// Drives the Positions/Trade screen: the Market/Pending/History switch, the
/// live open positions + pending orders (from [PositionsWsService]), the live
/// account summary (from [AccountWsService]), and the REST-backed close / cancel
/// / history actions (via [PositionsRepository]).
///
/// Business logic is ported from white_label's `TradingController`; only the
/// wiring (tenax services + account resolution) differs.
class PositionsController extends GetxController {
  PositionsController(
    this._repository,
    this._positionsWs,
    this._accountWs,
    this._marketWatch,
    this._accountsRepository,
  );

  final PositionsRepository _repository;
  final PositionsWsService _positionsWs;
  final AccountWsService _accountWs;
  final MarketWatchV2Service _marketWatch;
  final AccountsRepository _accountsRepository;

  final selectedTab = PositionsTab.market.obs;

  /// The trading account number driving all sockets + trade calls.
  final tradingAccount = ''.obs;

  /// History state (loaded lazily when the History tab is first opened).
  final history = <HistoryEntry>[].obs;
  final historyLoading = false.obs;
  final historyError = RxnString();
  bool _historyLoaded = false;

  /// True while a close/cancel request is in flight (disables the buttons).
  final busy = false.obs;

  // --- Live socket-backed reads (bind with Obx) -----------------------------

  /// Open positions as display models, newest first (as the socket sends them).
  List<TradePosition> get openPositions =>
      _positionsWs.openPositions.map((p) => p.toTradePosition()).toList();

  /// Pending orders as display models.
  List<TradePosition> get pendingOrders =>
      _positionsWs.pendingOrders.map((o) => o.toTradePosition()).toList();

  RxList<TradingPosition> get rawPositions => _positionsWs.openPositions;
  RxList<PendingOrder> get rawPending => _positionsWs.pendingOrders;

  /// Live account summary (balance/credit/equity/margin/free/level/profit).
  Rx<AccountInfo> get account => _accountWs.account;

  @override
  void onInit() {
    super.onInit();
    _resolveAccount();
  }

  void selectTab(PositionsTab tab) {
    selectedTab.value = tab;
    if (tab == PositionsTab.history && !_historyLoaded) {
      loadHistory();
    }
  }

  /// Resolves the current trading account NUMBER (the visible `login`, e.g.
  /// `901160`) for the auth/trade frames.
  ///
  /// The trade sockets need the account's LOGIN number, but the Home dashboard
  /// snapshot only carries the account DB `id`. So the accounts list
  /// (`AccountRow` has both `id` and `login`) is the source of truth: fetch it,
  /// then pick the row that matches the Home focus id if there is one, otherwise
  /// the first funded/active row.
  ///
  /// Kept in ONE place so it's trivial to swap once tenax adds a global
  /// active-account singleton.
  Future<void> _resolveAccount() async {
    final loadedRows = _loadedAccountRows();
    if (loadedRows != null) {
      _selectAccount(loadedRows);
      return;
    }

    final res = await _accountsRepository.getAccounts();
    if (isClosed) return;
    final data = res.data;
    if (!res.success || data == null || data.accounts.isEmpty) return;
    _selectAccount(data.accounts);
  }

  List<AccountRow>? _loadedAccountRows() {
    if (!Get.isRegistered<AccountsController>()) return null;
    final state = Get.find<AccountsController>().state;
    if (state is! DataSuccess<AccountsData> || state.data.accounts.isEmpty) {
      return null;
    }
    return state.data.accounts;
  }

  void _selectAccount(List<AccountRow> rows) {
    final focusId = _focusedAccountId();
    if (focusId != null) {
      final match = rows.where((a) => a.id == focusId);
      if (match.isNotEmpty) {
        _applyAccount(match.first.login);
        return;
      }
    }

    final preferred = rows.firstWhere(
      (a) => a.tab == AccountTab.funded || a.tab == AccountTab.active,
      orElse: () => rows.first,
    );
    _applyAccount(preferred.login);
  }

  /// The focused account's DB id from the Home dashboard snapshot, if the
  /// [HomeController] is registered and already has data.
  int? _focusedAccountId() {
    if (!Get.isRegistered<HomeController>()) return null;
    final state = Get.find<HomeController>().state;
    if (state is! DataSuccess<DashboardData>) return null;
    final focusId = state.data.focus?.accountId;
    return (focusId == null || focusId == 0) ? null : focusId;
  }

  void _applyAccount(String account) {
    if (account.isEmpty) return;
    tradingAccount.value = account;
    _positionsWs.switchAccount(account);
    _accountWs.switchAccount(account);
  }

  /// Places a Buy/Sell market order for the currently focused trading account.
  Future<bool> placeMarketOrder({
    required String symbol,
    required double volume,
    required OrderType orderType,
  }) async {
    if (busy.value || symbol.isEmpty || volume <= 0) return false;
    busy.value = true;
    try {
      await _resolveAccount();
      if (tradingAccount.value.isEmpty) {
        AppToast.error('positions.account_unavailable'.tr);
        return false;
      }

      final response = await _repository.placeMarketOrder(
        symbol: symbol,
        volume: volume,
        type: orderType.apiString,
        tradingAccount: tradingAccount.value,
      );
      return response.success;
    } finally {
      if (!isClosed) busy.value = false;
    }
  }

  /// Closes one open position. For a FULL close (volume null) the row is removed
  /// optimistically; a PARTIAL close ([volume] set) keeps the row so the socket
  /// can update its remaining lots. Returns true on success.
  Future<bool> closePosition(TradePosition position, {double? volume}) async {
    if (busy.value) return false;
    busy.value = true;
    if (volume == null) {
      _positionsWs.removePositionOptimistic(position.orderId);
    }
    final res = await _repository.closePositionByPositionId(
      positionId: position.orderId,
      tradingAccount: position.mt5Account.isNotEmpty
          ? position.mt5Account
          : tradingAccount.value,
      volume: volume,
    );
    if (!isClosed) busy.value = false;
    return res.success;
  }

  /// Closes the selected group of positions from the Close All sheet.
  Future<void> closePositions(List<TradePosition> positions) async {
    if (busy.value || positions.isEmpty) return;
    busy.value = true;
    try {
      if (positions.length == _positionsWs.openPositions.length) {
        await _repository.closeAllPositions(tradingAccount: tradingAccount.value);
        return;
      }

      for (final position in positions) {
        final response = await _repository.closePositionByPositionId(
          positionId: position.orderId,
          tradingAccount: position.mt5Account.isNotEmpty
              ? position.mt5Account
              : tradingAccount.value,
          showSuccessToast: false,
        );
        if (!response.success) return;
      }
      AppToast.success('positions.close_selected_success'.tr);
    } finally {
      if (!isClosed) busy.value = false;
    }
  }

  /// Updates take-profit / stop-loss for [position]. Pass `0` to clear a level.
  /// Returns true on success so the caller can close the edit sheet.
  Future<bool> updateTPSL(
    TradePosition position, {
    num? takeProfit,
    num? stopLoss,
  }) async {
    if (busy.value) return false;
    busy.value = true;
    final res = await _repository.updateTPSL(
      tradingAccount:
          position.mt5Account.isNotEmpty ? position.mt5Account : tradingAccount.value,
      positionId: position.orderId,
      takeProfit: takeProfit,
      stopLoss: stopLoss,
    );
    if (!isClosed) busy.value = false;
    return res.success;
  }

  /// Cancels a pending order.
  Future<void> cancelPending(TradePosition order) async {
    if (busy.value) return;
    busy.value = true;
    _positionsWs.removePendingOptimistic(order.orderId);
    await _repository.cancelPendingOrder(
      orderId: order.orderId,
      tradingAccount: tradingAccount.value,
    );
    if (!isClosed) busy.value = false;
  }

  /// Loads closed-trade history for the current account (History tab).
  Future<void> loadHistory() async {
    historyLoading.value = true;
    historyError.value = null;
    final res = await _repository.getTradeHistory(
      tradingAccount: tradingAccount.value,
    );
    if (isClosed) return;
    _historyLoaded = true;
    historyLoading.value = false;
    if (res.success && res.data != null) {
      history.assignAll(res.data!);
    } else {
      historyError.value = res.message ?? 'state.error_title'.tr;
    }
  }

  /// Ensures the symbol of every open/pending row is subscribed on the shared
  /// market-watch socket so the card can show a live price if needed.
  void subscribeVisibleSymbols() {
    final symbols = <String>{
      for (final p in _positionsWs.openPositions) p.symbol,
      for (final o in _positionsWs.pendingOrders) o.symbol,
    }..removeWhere((s) => s.isEmpty);
    if (symbols.isNotEmpty) {
      _marketWatch.subscribeSymbols(symbols.toList());
    }
  }
}
