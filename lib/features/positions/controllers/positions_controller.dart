import 'dart:async';

import 'package:get/get.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/state/data_state.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/trade/trade_ticket.dart';
import '../../accounts/controllers/accounts_controller.dart';
import '../../accounts/models/accounts_models.dart';
import '../../accounts/repositories/accounts_repository.dart';
import '../../accounts/services/primary_account_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/models/dashboard_models.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import '../models/positions_models.dart';
import '../repositories/positions_repository.dart';
import '../services/account_ws_service.dart';
import '../services/positions_ws_service.dart';

/// The three tabs of the Positions screen.
enum PositionsTab { market, pending, history }

enum HistoryDirection { all, buy, sell }
enum HistoryProfitFilter { all, profitable, losing }

/// Date-range presets for the History tab filter.
enum HistoryRange {
  today,
  lastWeek,
  lastMonth,
  last3Months,
  last6Months,
  lastYear,
  custom;

  String get labelKey => switch (this) {
        HistoryRange.today => 'positions.range_today',
        HistoryRange.lastWeek => 'positions.range_last_week',
        HistoryRange.lastMonth => 'positions.range_last_month',
        HistoryRange.last3Months => 'positions.range_last_3_months',
        HistoryRange.last6Months => 'positions.range_last_6_months',
        HistoryRange.lastYear => 'positions.range_last_year',
        HistoryRange.custom => 'positions.range_custom',
      };
}

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

  /// All account rows the trader can switch between (for the header pill).
  final accountRows = <AccountRow>[].obs;

  /// History state (loaded lazily when the History tab is first opened).
  final history = <HistoryEntry>[].obs;
  final historyLoading = false.obs;
  final historyError = RxnString();
  final historyLoadingMore = false.obs;
  final historyPage = 1.obs;
  final historyHasMore = false.obs;
  final historyTotal = 0.obs;
  final historyProfit = 0.0.obs;
  final historySwap = 0.0.obs;
  final historyCommission = 0.0.obs;
  final historySymbol = ''.obs;
  final historyDirection = HistoryDirection.all.obs;
  final historyProfitFilter = HistoryProfitFilter.all.obs;

  List<HistoryEntry> get filteredHistory => history.where((entry) {
        final symbolMatches = historySymbol.value.isEmpty ||
            entry.symbol.toUpperCase() == historySymbol.value.toUpperCase();
        final directionMatches = switch (historyDirection.value) {
          HistoryDirection.all => true,
          HistoryDirection.buy => entry.isBuy,
          HistoryDirection.sell => !entry.isBuy,
        };
        final profitMatches = switch (historyProfitFilter.value) {
          HistoryProfitFilter.all => true,
          HistoryProfitFilter.profitable => entry.profit > 0,
          HistoryProfitFilter.losing => entry.profit < 0,
        };
        return symbolMatches && directionMatches && profitMatches;
      }).toList(growable: false);

  double get filteredHistoryProfit =>
      filteredHistory.fold<double>(0, (sum, entry) => sum + entry.profit);

  /// Active date-range filter for the History tab.
  final historyRange = HistoryRange.today.obs;
  final customFrom = Rxn<DateTime>();
  final customTo = Rxn<DateTime>();
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
    // Make sure the primary-account id is known BEFORE picking a default, so
    // the very first resolve on screen open honours `is_primary` instead of
    // racing ahead to "first funded/active".
    if (Get.isRegistered<PrimaryAccountService>()) {
      final svc = Get.find<PrimaryAccountService>();
      if (svc.primaryAccountId.value == null) await svc.refresh();
      if (isClosed) return;
    }

    final loadedRows = _loadedAccountRows();
    if (loadedRows != null) {
      _selectAccount(loadedRows);
      return;
    }

    final gen = ++_accountsGen;
    final res = await _accountsRepository.getAccounts();
    if (isClosed) return;
    // A newer fetch superseded this one; only skip when an account is already
    // selected, so order placement never ends up with an empty account.
    final isStale = gen != _accountsGen;
    if (isStale && tradingAccount.value.isNotEmpty) return;
    final data = res.data;
    if (!res.success || data == null || data.accounts.isEmpty) return;
    _selectAccount(data.accounts);
  }

  /// Bumped by every accounts fetch; an older reply never overwrites a newer
  /// account list.
  int _accountsGen = 0;

  List<AccountRow>? _loadedAccountRows() {
    if (!Get.isRegistered<AccountsController>()) return null;
    final state = Get.find<AccountsController>().state;
    if (state is! DataSuccess<AccountsData> || state.data.accounts.isEmpty) {
      return null;
    }
    return state.data.accounts;
  }

  /// Switches every socket + trade call to [row]'s login (header pill sheet).
  ///
  /// Also persists the pick as the user's primary account via
  /// `POST /mt5accounts/set-primary` in the background (same as the dashboard
  /// account switch), and refocuses the Home hero on the new id — so the whole
  /// app follows the account, not just the Positions sockets.
  void switchToAccount(AccountRow row) {
    if (row.login == tradingAccount.value) return;
    _applyAccount(row.login);

    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().selectAccount(row.id);
    }
    if (Get.isRegistered<PrimaryAccountService>()) {
      unawaited(Get.find<PrimaryAccountService>().setPrimary(row.id));
    }
  }


  /// Re-fetches the account list so the switch sheet shows current balance,
  /// equity and P/L (the cached rows are a snapshot from screen open).
  Future<void> refreshAccountRows() async {
    if (isRefreshingAccounts.value) return;
    isRefreshingAccounts.value = true;
    final gen = ++_accountsGen;
    final res = await _accountsRepository.getAccounts();
    if (isClosed) return;
    isRefreshingAccounts.value = false;
    if (gen != _accountsGen) return;
    final data = res.data;
    if (!res.success || data == null || data.accounts.isEmpty) return;
    accountRows.assignAll(_primaryFirst(data.accounts));
  }

  /// True while the switch sheet is re-fetching the account list.
  final isRefreshingAccounts = false.obs;

  /// The user's primary account id, if known (badge + ordering in the sheet).
  int? get primaryAccountId => _primaryAccountId();

  /// Tradable accounts only (breached/completed are dropped), primary first,
  /// the rest in API order.
  List<AccountRow> _primaryFirst(List<AccountRow> rows) {
    final primaryId = _primaryAccountId();
    final sorted = rows.where((a) => a.isTradable).toList();
    final index = sorted.indexWhere((a) => a.id == primaryId);
    if (index <= 0) return sorted;
    sorted.insert(0, sorted.removeAt(index));
    return sorted;
  }

  void _selectAccount(List<AccountRow> rows) {
    accountRows.assignAll(_primaryFirst(rows));
    final tradable = rows.where((a) => a.isTradable).toList();
    final focusId = _focusedAccountId() ?? _primaryAccountId();
    if (focusId != null) {
      final match = tradable.where((a) => a.id == focusId);
      if (match.isNotEmpty) {
        _applyAccount(match.first.login);
        return;
      }
    }

    _applyAccount(tradable.isNotEmpty ? tradable.first.login : rows.first.login);
  }

  /// The user's active/primary account id from [PrimaryAccountService]
  /// (`is_primary` in `GET /mt5accounts/get`), if already loaded. Used as the
  /// default focus ahead of "first funded/active" so the header (Floating P/L)
  /// opens on the account the user actually marked primary.
  int? _primaryAccountId() {
    if (!Get.isRegistered<PrimaryAccountService>()) return null;
    return Get.find<PrimaryAccountService>().primaryAccountId.value;
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

  /// Places the market order described by a [TradeTicket] from the shared
  /// `TradeTicketPanel`. Every ticket surface (portrait dock, landscape rail)
  /// submits through here so the side → [OrderType] and TP/SL mapping exists
  /// exactly once.
  Future<bool> placeTicket(TradeTicket ticket) {
    return placeMarketOrder(
      symbol: ticket.symbol,
      volume: ticket.volume,
      orderType: ticket.side == TradeSide.buy
          ? OrderType.buyMarket
          : OrderType.sellMarket,
      takeProfit: ticket.takeProfit,
      stopLoss: ticket.stopLoss,
    );
  }

  /// Places a Buy/Sell market order for the currently focused trading account.
  /// [takeProfit] and [stopLoss] are independent — pass either, both, or none.
  Future<bool> placeMarketOrder({
    required String symbol,
    required double volume,
    required OrderType orderType,
    double? takeProfit,
    double? stopLoss,
  }) async {
    if (busy.value || symbol.isEmpty || volume <= 0) return false;
    busy.value = true;
    try {
      await _resolveAccount();
      if (tradingAccount.value.isEmpty) {
        AppToast.error('positions.account_unavailable'.tr);
        return false;
      }

      log.i(
        'ORDER ▶ MARKET ${orderType.apiString.toUpperCase()} $symbol '
        'lots=$volume account=${tradingAccount.value} '
        'tp=${takeProfit ?? '-'} sl=${stopLoss ?? '-'}',
      );

      final response = await _repository.placeMarketOrder(
        symbol: symbol,
        volume: volume,
        type: orderType.apiString,
        tradingAccount: tradingAccount.value,
        takeProfit: takeProfit,
        stopLoss: stopLoss,
      );
      if (response.success) {
        log.i('ORDER ✅ MARKET ${orderType.apiString.toUpperCase()} '
            '$symbol lots=$volume placed');
      } else {
        log.e('ORDER ❌ MARKET ${orderType.apiString.toUpperCase()} '
            '$symbol lots=$volume failed: ${response.message ?? 'unknown error'}');
      }
      return response.success;
    } finally {
      if (!isClosed) busy.value = false;
    }
  }

  /// Places a pending (limit/stop) order for the currently focused trading
  /// account. [price] is the trigger level; TP/SL are sent only when set.
  Future<bool> placePendingOrder({
    required String symbol,
    required double volume,
    required OrderType orderType,
    required double price,
    double? limitPrice,
    double? takeProfit,
    double? stopLoss,
  }) async {
    if (busy.value || symbol.isEmpty || volume <= 0 || price <= 0) return false;
    busy.value = true;
    try {
      await _resolveAccount();
      if (tradingAccount.value.isEmpty) {
        AppToast.error('positions.account_unavailable'.tr);
        return false;
      }

      log.i(
        'ORDER ▶ PENDING ${orderType.apiString.toUpperCase()} $symbol '
        'lots=$volume price=$price limit=${limitPrice ?? '-'} '
        'account=${tradingAccount.value} '
        'tp=${takeProfit ?? '-'} sl=${stopLoss ?? '-'}',
      );

      final response = await _repository.placePendingOrder(
        symbol: symbol,
        volume: volume,
        type: orderType.apiString,
        price: price,
        limitPrice: limitPrice,
        tradingAccount: tradingAccount.value,
        takeProfit: takeProfit,
        stopLoss: stopLoss,
      );
      if (response.success) {
        log.i('ORDER ✅ PENDING ${orderType.apiString.toUpperCase()} '
            '$symbol lots=$volume price=$price placed');
      } else {
        log.e('ORDER ❌ PENDING ${orderType.apiString.toUpperCase()} '
            '$symbol lots=$volume price=$price failed: '
            '${response.message ?? 'unknown error'}');
      }
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
    try {
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
      return res.success;
    } finally {
      if (!isClosed) busy.value = false;
    }
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
  ///
  /// A PENDING row goes to the pending-order route (keyed by `order_id` and
  /// carrying the untouched trigger `price`); an open position goes to the
  /// position route. [isPending] defaults to whichever list the row is in, so
  /// existing Market-tab call sites keep their behaviour.
  Future<bool> updateTPSL(
    TradePosition position, {
    num? takeProfit,
    num? stopLoss,
    bool? isPending,
  }) async {
    if (busy.value) return false;
    busy.value = true;
    try {
      return await _submitTPSL(
        position,
        takeProfit: takeProfit,
        stopLoss: stopLoss,
        isPending: isPending,
      );
    } finally {
      if (!isClosed) busy.value = false;
    }
  }

  Future<bool> _submitTPSL(
    TradePosition position, {
    num? takeProfit,
    num? stopLoss,
    bool? isPending,
  }) async {
    final account = position.mt5Account.isNotEmpty
        ? position.mt5Account
        : tradingAccount.value;
    final pending = isPending ?? _isPendingRow(position.orderId);

    final res = pending
        ? await _repository.updatePendingOrderTPSL(
            tradingAccount: account,
            orderId: position.orderId,
            price: _pendingTriggerPrice(position),
            // The pending route clears a level with an explicit null; `0` is
            // how the position route spells the same thing.
            takeProfit: (takeProfit ?? 0) == 0 ? null : takeProfit,
            stopLoss: (stopLoss ?? 0) == 0 ? null : stopLoss,
          )
        : await _repository.updateTPSL(
            tradingAccount: account,
            positionId: position.orderId,
            takeProfit: takeProfit,
            stopLoss: stopLoss,
          );
    return res.success;
  }

  bool _isPendingRow(String orderId) =>
      rawPending.any((o) => o.order.toString() == orderId);

  /// The pending route requires the order's trigger price unchanged; prefer the
  /// live socket row and fall back to the card's own entry price.
  num _pendingTriggerPrice(TradePosition position) {
    final match = rawPending.where((o) => o.order.toString() == position.orderId);
    if (match.isNotEmpty) return match.first.priceOrder;
    return num.tryParse(position.entryPrice.replaceAll(',', '')) ?? 0;
  }

  /// Cancels a pending order.
  Future<void> cancelPending(TradePosition order) async {
    if (busy.value) return;
    busy.value = true;
    try {
      _positionsWs.removePendingOptimistic(order.orderId);
      await _repository.cancelPendingOrder(
        orderId: order.orderId,
        tradingAccount: tradingAccount.value,
      );
    } finally {
      if (!isClosed) busy.value = false;
    }
  }

  /// Applies a date-range filter and reloads history from page 1.
  void applyHistoryFilters({
    required String symbol,
    required HistoryDirection direction,
    required HistoryProfitFilter profitFilter,
  }) {
    historySymbol.value = symbol;
    historyDirection.value = direction;
    historyProfitFilter.value = profitFilter;
  }

  void applyHistoryFilter(HistoryRange range, {DateTime? from, DateTime? to}) {
    historyRange.value = range;
    if (range == HistoryRange.custom) {
      if (from == null || to == null) return;
      customFrom.value = from;
      customTo.value = to;
    }
    loadHistory();
  }

  /// `from`/`to` for the current filter, formatted as `yyyy-MM-dd`.
  (String, String) get _historyDates {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = switch (historyRange.value) {
      HistoryRange.today => today,
      HistoryRange.lastWeek => today.subtract(const Duration(days: 7)),
      HistoryRange.lastMonth => DateTime(today.year, today.month, 1),
      HistoryRange.last3Months => DateTime(today.year, today.month - 2, 1),
      HistoryRange.last6Months => DateTime(today.year, today.month - 5, 1),
      HistoryRange.lastYear => DateTime(today.year - 1, today.month, 1),
      HistoryRange.custom => customFrom.value ?? today,
    };
    final to = historyRange.value == HistoryRange.custom
        ? (customTo.value ?? today)
        : today;
    return (_ymd(from), _ymd(to));
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Loads the FIRST page of closed-trade history for the current filter.
  Future<void> loadHistory() async {
    final gen = ++_historyGen;
    historyLoading.value = true;
    historyLoadingMore.value = false;
    historyError.value = null;
    final page = await _fetchHistoryPage(1, gen);
    if (isClosed || gen != _historyGen) return;
    _historyLoaded = true;
    historyLoading.value = false;
    if (page == null) return;
    history.assignAll(page.entries);
  }

  /// Loads the NEXT page and appends it (infinite scroll).
  Future<void> loadMoreHistory() async {
    if (historyLoading.value || historyLoadingMore.value || !historyHasMore.value) {
      return;
    }
    final gen = _historyGen;
    historyLoadingMore.value = true;
    final page = await _fetchHistoryPage(historyPage.value + 1, gen);
    // A filter change reloaded page 1 meanwhile — this page belongs to the old
    // filter and must not be appended.
    if (isClosed || gen != _historyGen) return;
    historyLoadingMore.value = false;
    if (page == null) return;
    history.addAll(page.entries);
  }

  /// Bumped by every [loadHistory]; responses from an older generation are
  /// dropped so an out-of-order reply never mixes two filters.
  int _historyGen = 0;

  /// Shared fetch: runs the request, stores pagination/summary, and surfaces the
  /// error message. Returns null on failure or when [gen] is stale.
  Future<HistoryPage?> _fetchHistoryPage(int page, int gen) async {
    final (from, to) = _historyDates;
    final res = await _repository.getTradeHistory(
      tradingAccount: tradingAccount.value,
      page: page,
      from: from,
      to: to,
    );
    if (isClosed || gen != _historyGen) return null;
    final data = res.data;
    if (!res.success || data == null) {
      historyError.value = res.message ?? 'state.error_title'.tr;
      return null;
    }
    historyPage.value = data.currentPage;
    historyHasMore.value = data.hasMore;
    historyTotal.value = data.total;
    historyProfit.value = data.profit;
    historySwap.value = data.swap;
    historyCommission.value = data.commission;
    return data;
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
