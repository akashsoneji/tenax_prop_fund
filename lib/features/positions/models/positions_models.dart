// Domain + WebSocket models for the Positions/Trade feature.
//
// The WebSocket frame models ([TradingPosition], [PendingOrder], [AccountInfo],
// [OpenPositionsData], [PendingOrdersData], [WebSocketTradingResponse]) are
// ported VERBATIM from the white_label app
// (`lib/models/websocket_trading_response.dart`) — the `fromJson` keys and field
// names are kept identical so the SAME trade-engine socket frames parse without
// any backend change. [TradePosition] and [HistoryEntry] are the display models
// the view binds to. Only the brand colour differs between the two apps.

/// Order type, ported from white_label `lib/models/order_types.dart`.
enum OrderType {
  buyMarket(0, 'Instant Execution (Buy)', 'buy', isBuy: true, requiresPrice: false),
  sellMarket(1, 'Instant Execution (Sell)', 'sell', isBuy: false, requiresPrice: false),
  buyLimit(2, 'Buy Limit', 'buy_limit', isBuy: true, requiresPrice: true),
  sellLimit(3, 'Sell Limit', 'sell_limit', isBuy: false, requiresPrice: true),
  buyStop(4, 'Buy Stop', 'buy_stop', isBuy: true, requiresPrice: true),
  sellStop(5, 'Sell Stop', 'sell_stop', isBuy: false, requiresPrice: true),
  buyStopLimit(6, 'Buy Stop Limit', 'buy_stop_limit', isBuy: true, requiresPrice: true),
  sellStopLimit(7, 'Sell Stop Limit', 'sell_stop_limit', isBuy: false, requiresPrice: true);

  const OrderType(
    this.value,
    this.displayName,
    this.apiString, {
    required this.isBuy,
    required this.requiresPrice,
  });

  final int value;
  final String displayName;
  final String apiString;
  final bool isBuy;
  final bool requiresPrice;

  factory OrderType.fromValue(int value) => OrderType.values.firstWhere(
        (e) => e.value == value,
        orElse: () => OrderType.buyMarket,
      );

  bool get isBuyOrder => isBuy;
  bool get isSellOrder => !isBuy;
}

/// Formats a price to [decimals] places, guarding against NaN/Infinity so a
/// malformed WS payload can't crash the UI. Mirrors white_label's
/// `PrecisionHelper.formatPrice`.
String formatPrice(double value, {int decimals = 5}) {
  if (value.isNaN || value.isInfinite) return (0.0).toStringAsFixed(decimals);
  return value.toStringAsFixed(decimals);
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  final parsed = v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);
  return (parsed.isNaN || parsed.isInfinite) ? 0.0 : parsed;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

/// Top-level socket envelope. Keys accept both camel and snake case, exactly as
/// white_label parses them.
class WebSocketTradingResponse {
  WebSocketTradingResponse({
    this.openPositions,
    this.pendingOrders,
    required this.realtime,
    required this.serverTimestamp,
  });

  final OpenPositionsData? openPositions;
  final PendingOrdersData? pendingOrders;
  final bool realtime;
  final int serverTimestamp;

  factory WebSocketTradingResponse.fromJson(Map<String, dynamic> json) {
    final openPositionsJson = json['openPositions'] ?? json['open_positions'];
    final pendingOrdersJson = json['pendingOrders'] ?? json['pending_orders'];
    return WebSocketTradingResponse(
      openPositions: openPositionsJson is Map<String, dynamic>
          ? OpenPositionsData.fromJson(openPositionsJson)
          : null,
      pendingOrders: pendingOrdersJson is Map<String, dynamic>
          ? PendingOrdersData.fromJson(pendingOrdersJson)
          : null,
      realtime: json['realtime'] ?? false,
      serverTimestamp: json['server_timestamp'] ?? json['serverTimestamp'] ?? 0,
    );
  }
}

class OpenPositionsData {
  OpenPositionsData({required this.positions, required this.accountinfo});

  final List<TradingPosition> positions;
  final List<AccountInfo> accountinfo;

  factory OpenPositionsData.fromJson(Map<String, dynamic> json) => OpenPositionsData(
        positions: (json['positions'] as List?)
                ?.whereType<Map>()
                .map((p) => TradingPosition.fromJson(p.cast<String, dynamic>()))
                .toList() ??
            const [],
        accountinfo: (json['accountinfo'] as List?)
                ?.whereType<Map>()
                .map((a) => AccountInfo.fromJson(a.cast<String, dynamic>()))
                .toList() ??
            const [],
      );
}

class PendingOrdersData {
  PendingOrdersData({required this.pendingOrders});

  final List<PendingOrder> pendingOrders;

  factory PendingOrdersData.fromJson(Map<String, dynamic> json) => PendingOrdersData(
        pendingOrders: (json['pendingOrders'] as List?)
                ?.whereType<Map>()
                .map((o) => PendingOrder.fromJson(o.cast<String, dynamic>()))
                .toList() ??
            const [],
      );
}

/// One open trade, PascalCase keys straight from the `/op` socket.
class TradingPosition {
  TradingPosition({
    required this.mt5Account,
    required this.position,
    required this.action,
    required this.volume,
    required this.priceOpen,
    required this.priceSL,
    required this.priceTP,
    required this.priceCurrent,
    required this.closeTime,
    required this.timeCreate,
    required this.symbol,
    required this.logo,
    required this.profit,
    required this.digits,
    this.swap = 0.0,
  });

  final int mt5Account;
  final int position;
  final String action; // "Buy" or "Sell"
  final String volume;
  final String priceOpen;
  final String priceSL;
  final String priceTP;
  final String priceCurrent;
  final String closeTime;
  final String timeCreate;
  final String symbol;
  final String logo;
  final double profit;
  final int digits;
  final double swap;

  factory TradingPosition.fromJson(Map<String, dynamic> json) => TradingPosition(
        mt5Account: json['MT5Account'] ?? 0,
        position: json['Position'] ?? 0,
        action: json['Action'] ?? '',
        volume: (json['Volume'] ?? '0').toString(),
        priceOpen: (json['PriceOpen'] ?? '0').toString(),
        priceSL: (json['PriceSL'] ?? '0').toString(),
        priceTP: (json['PriceTP'] ?? '0').toString(),
        priceCurrent: (json['PriceCurrent'] ?? '0').toString(),
        closeTime: json['CloseTime'] ?? '',
        timeCreate: json['TimeCreate'] ?? '',
        symbol: json['Symbol'] ?? '',
        logo: json['Logo'] ?? '',
        profit: (json['Profit'] ?? 0.0).toDouble(),
        digits: json['Digits'] ?? 0,
        swap: (json['Swap'] ?? 0.0).toDouble(),
      );

  TradePosition toTradePosition() {
    final displayDigits = digits > 0 ? digits : 5;
    final entry = _toDouble(priceOpen);
    final current = _toDouble(priceCurrent);
    final sl = _toDouble(priceSL);
    final tp = _toDouble(priceTP);
    return TradePosition(
      symbol: symbol,
      flag: logo,
      action: action,
      volume: _toDouble(volume),
      profitLoss: (profit.isNaN || profit.isInfinite) ? 0.0 : profit,
      entryPrice: formatPrice(entry, decimals: displayDigits),
      currentPrice: formatPrice(current, decimals: displayDigits),
      accountId: mt5Account.toString(),
      orderId: position.toString(),
      openTime: timeCreate,
      closeTime: closeTime == '-' ? '' : closeTime,
      time: timeCreate,
      takeProfit: tp == 0.0 ? '' : formatPrice(tp, decimals: displayDigits),
      stopLoss: sl == 0.0 ? '' : formatPrice(sl, decimals: displayDigits),
      mt5Account: mt5Account.toString(),
      swap: (swap.isNaN || swap.isInfinite) ? 0.0 : swap,
      digits: displayDigits,
      isPending: false,
    );
  }
}

/// One pending order, from the `/po` socket. Keys accept Pascal/camel/snake.
class PendingOrder {
  PendingOrder({
    required this.mt5Account,
    required this.order,
    required this.action,
    required this.symbol,
    required this.priceOrder,
    required this.priceCurrent,
    required this.volume,
    required this.priceSL,
    required this.priceTP,
    required this.timeCreate,
    required this.state,
    required this.logo,
    this.digits = 0,
  });

  final int mt5Account;
  final int order;
  final String action; // "Buy Limit", "Sell Stop", ...
  final String symbol;
  final double priceOrder;
  final double priceCurrent;
  final double volume;
  final double priceSL;
  final double priceTP;
  final String timeCreate;
  final String state;
  final String logo;
  final int digits;

  factory PendingOrder.fromJson(Map<String, dynamic> json) => PendingOrder(
        mt5Account: _toInt(json['MT5Account'] ?? json['mt5Account'] ?? json['mt5_account']),
        order: _toInt(json['Order'] ?? json['order'] ?? json['order_id']),
        action: json['Action'] ?? json['action'] ?? '',
        symbol: json['Symbol'] ?? json['symbol'] ?? '',
        priceOrder: _toDouble(
            json['PriceOrder'] ?? json['priceOrder'] ?? json['price_order'] ?? json['price']),
        priceCurrent:
            _toDouble(json['PriceCurrent'] ?? json['priceCurrent'] ?? json['price_current']),
        volume: _toDouble(json['Volume'] ?? json['volume']),
        priceSL: _toDouble(json['PriceSL'] ??
            json['priceSL'] ??
            json['price_sl'] ??
            json['stopLoss'] ??
            json['stop_loss']),
        priceTP: _toDouble(json['PriceTP'] ??
            json['priceTP'] ??
            json['price_tp'] ??
            json['takeProfit'] ??
            json['take_profit']),
        timeCreate:
            json['TimeCreate'] ?? json['timeCreate'] ?? json['time_create'] ?? '',
        state: json['State'] ?? json['state'] ?? '',
        logo: json['Logo'] ?? json['logo'] ?? '',
        digits: _toInt(json['Digits'] ?? json['digits']),
      );

  TradePosition toTradePosition() {
    final displayDigits = digits > 0 ? digits : 5;
    return TradePosition(
      symbol: symbol.replaceAll('.c', ''),
      flag: logo,
      action: action.contains('Buy') ? 'Buy' : 'Sell',
      volume: volume,
      profitLoss: 0.0,
      entryPrice: formatPrice(priceOrder, decimals: displayDigits),
      currentPrice: formatPrice(priceCurrent, decimals: displayDigits),
      accountId: mt5Account.toString(),
      orderId: order.toString(),
      openTime: timeCreate,
      closeTime: '',
      time: timeCreate,
      takeProfit: priceTP == 0.0 ? '' : formatPrice(priceTP, decimals: displayDigits),
      stopLoss: priceSL == 0.0 ? '' : formatPrice(priceSL, decimals: displayDigits),
      mt5Account: mt5Account.toString(),
      swap: 0.0,
      digits: displayDigits,
      isPending: true,
      pendingType: action,
    );
  }
}

/// Live account equity/margin, PascalCase keys from the `/account` socket.
class AccountInfo {
  AccountInfo({
    required this.balance,
    required this.credit,
    required this.equity,
    required this.margin,
    required this.marginFree,
    required this.marginLevel,
    required this.profit,
    required this.storage,
    required this.login,
    this.currencyDigits = 2,
  });

  final double balance;
  final double credit;
  final double equity;
  final double margin;
  final double marginFree;
  final double marginLevel;
  final double profit;
  final double storage; // accumulated swap
  final int login;
  final int currencyDigits;

  factory AccountInfo.fromJson(Map<String, dynamic> json) => AccountInfo(
        balance: (json['Balance'] ?? 0.0).toDouble(),
        credit: (json['Credit'] ?? 0.0).toDouble(),
        equity: (json['Equity'] ?? 0.0).toDouble(),
        margin: (json['Margin'] ?? 0.0).toDouble(),
        marginFree: (json['MarginFree'] ?? 0.0).toDouble(),
        marginLevel: (json['MarginLevel'] ?? 0.0).toDouble(),
        profit: (json['Profit'] ?? 0.0).toDouble(),
        storage: (json['Storage'] ?? 0.0).toDouble(),
        login: json['Login'] ?? 0,
        currencyDigits: json['CurrencyDigits'] ?? 2,
      );

  static AccountInfo empty() => AccountInfo(
        balance: 0,
        credit: 0,
        equity: 0,
        margin: 0,
        marginFree: 0,
        marginLevel: 0,
        profit: 0,
        storage: 0,
        login: 0,
      );
}

/// Display model the position/pending cards bind to.
class TradePosition {
  TradePosition({
    required this.symbol,
    required this.flag,
    required this.action,
    required this.volume,
    required this.profitLoss,
    required this.entryPrice,
    required this.currentPrice,
    required this.accountId,
    required this.orderId,
    required this.openTime,
    required this.closeTime,
    required this.time,
    required this.takeProfit,
    required this.stopLoss,
    required this.mt5Account,
    required this.swap,
    required this.digits,
    this.isPending = false,
    this.pendingType = '',
  });

  final String symbol;
  final String flag; // logo url
  final String action; // "Buy" / "Sell"
  final double volume;
  final double profitLoss;
  final String entryPrice;
  final String currentPrice;
  final String accountId;
  final String orderId;
  final String openTime;
  final String closeTime;
  final String time;
  final String takeProfit;
  final String stopLoss;
  final String mt5Account;
  final double swap;
  final int digits;
  final bool isPending;
  final String pendingType;

  bool get isBuy => action.toLowerCase().contains('buy');
}

/// One closed trade for the History tab, from the REST `tradehistory` endpoint.
class HistoryEntry {
  HistoryEntry({
    required this.mt5Account,
    required this.positionId,
    required this.action,
    required this.symbol,
    required this.volume,
    required this.priceOpen,
    required this.priceClose,
    required this.profit,
    required this.commission,
    required this.swap,
    required this.openTime,
    required this.closeTime,
    required this.duration,
  });

  final int mt5Account;
  final int positionId;
  final String action; // normalized Buy / Sell
  final String symbol;
  final double volume;
  final String priceOpen;
  final String priceClose;
  final double profit;
  final double commission;
  final double swap;
  final String openTime;
  final String closeTime;
  final String duration;

  bool get isBuy => action.toLowerCase().contains('buy');

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawType = (json['trade_type'] ?? json['action'] ?? '').toString();
    final lower = rawType.toLowerCase().trim();
    final normalized = (lower.contains('buy') || lower == '0')
        ? 'Buy'
        : (lower.contains('sell') || lower == '1')
            ? 'Sell'
            : rawType;
    return HistoryEntry(
      mt5Account: _toInt(json['mt5_account'] ?? json['login']),
      positionId: _toInt(
          json['trade_position_id'] ?? json['position_id'] ?? json['deal_id']),
      action: normalized,
      symbol: (json['trade_symbol'] ?? json['symbol'] ?? '').toString(),
      volume: _toDouble(json['trade_volume'] ?? json['volume'] ?? json['lots']),
      priceOpen:
          (json['trade_price_order'] ?? json['price_open'] ?? json['price'] ?? '0')
              .toString(),
      priceClose: (json['trade_price_close'] ??
              json['price_close'] ??
              json['close_price'] ??
              '0')
          .toString(),
      profit: _toDouble(json['trade_profit'] ?? json['profit']),
      commission: _toDouble(json['trade_commission'] ?? json['commission']),
      swap: _toDouble(json['swap']),
      openTime:
          (json['trade_open_time'] ?? json['open_time'] ?? json['time'] ?? '')
              .toString(),
      closeTime: (json['trade_close_time'] ?? json['close_time'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
    );
  }
}

/// Parses the `tradehistory` REST `data` payload, which may be a flat list or a
/// nested `{data: [...]}` object (white_label supports both).
List<HistoryEntry> parseHistory(dynamic data) {
  List<dynamic>? rows;
  if (data is List) {
    rows = data;
  } else if (data is Map) {
    final inner = data['data'];
    if (inner is List) rows = inner;
  }
  return [
    for (final r in rows ?? const [])
      if (r is Map) HistoryEntry.fromJson(r.cast<String, dynamic>()),
  ];
}
