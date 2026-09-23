import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../app/flavor/flavor_config.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_interceptor.dart';
import '../../../core/websocket/message_pack_decoder.dart';
import '../models/positions_models.dart';

/// Owns the TWO trade sockets for the whole app: `/op` (open positions) and
/// `/po` (pending orders). Styled exactly like [MarketWatchV2Service] — a
/// self-connecting [GetxService] with reconnect/backoff/heartbeat and
/// MessagePack/JSON decode — but driving TWO channels.
///
/// Protocol is ported VERBATIM from the white_label app
/// (`trading_websocket_service.dart`):
/// - After connect, send the auth frame `{authID, trading_account}`.
/// - Server pushes [WebSocketTradingResponse] frames (binary MessagePack or
///   JSON): `/op` carries `openPositions.{positions, accountinfo}`, `/po`
///   carries `pendingOrders.pendingOrders`.
/// - On account switch call [switchAccount]: re-auths both sockets for the new
///   trading account.
///
/// Widgets never open a socket — the controller reads [openPositions] /
/// [pendingOrders] (granular `Obx`) and [isConnected].
class PositionsWsService extends GetxService with WidgetsBindingObserver {
  PositionsWsService(this._config, this._storage);

  final FlavorConfig _config;
  final FlutterSecureStorage _storage;

  /// Live open positions (patched whole on every `/op` frame).
  final RxList<TradingPosition> openPositions = <TradingPosition>[].obs;

  /// Live pending orders (patched whole on every `/po` frame).
  final RxList<PendingOrder> pendingOrders = <PendingOrder>[].obs;

  final RxBool isConnected = false.obs;

  /// The trading account number currently authed on both sockets. `'0'` until
  /// the controller resolves the focused account and calls [switchAccount].
  String _account = '0';

  final _Channel _op = _Channel('op');
  final _Channel _po = _Channel('po');

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _connectAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_op.channel == null) _connect(_op, _config.openPositionsUrl, _onOpFrame);
      if (_po.channel == null) _connect(_po, _config.pendingOrdersUrl, _onPoFrame);
    }
  }

  /// Re-auth both sockets for [account] (called on account switch / first
  /// resolve). Idempotent: a no-op when the account did not change.
  void switchAccount(String account) {
    if (account.isEmpty || account == _account) return;
    _account = account;
    openPositions.clear();
    pendingOrders.clear();
    // Full restart for the new account (mirrors the dashboard set-primary
    // flow): tear both sockets down and open fresh connections, rather than
    // re-authing on the stale ones.
    _restart(_op, _config.openPositionsUrl, _onOpFrame);
    _restart(_po, _config.pendingOrdersUrl, _onPoFrame);
  }

  /// Disconnects [ch] and immediately reconnects it with a reset backoff.
  void _restart(
    _Channel ch,
    String url,
    void Function(dynamic decoded) onFrame,
  ) {
    ch.disconnect();
    ch.reconnectAttempts = 0;
    _updateConnected();
    _connect(ch, url, onFrame);
  }


  Future<String?> _authToken() => _storage.read(key: ApiInterceptor.tokenKey);

  void _connectAll() {
    _connect(_op, _config.openPositionsUrl, _onOpFrame);
    _connect(_po, _config.pendingOrdersUrl, _onPoFrame);
  }

  Future<void> _connect(
    _Channel ch,
    String url,
    void Function(dynamic decoded) onFrame,
  ) async {
    if (ch.connecting || ch.channel != null) return;
    ch.connecting = true;
    ch.manuallyClosed = false;
    try {
      final token = await _authToken();
      if (token == null || token.isEmpty) {
        log.w('positions/${ch.name}: no auth token, skipping connect');
        return;
      }
      final channel = WebSocketChannel.connect(Uri.parse(url));
      await channel.ready;
      ch.channel = channel;
      ch.reconnectAttempts = 0;
      _updateConnected();

      ch.sub = channel.stream.listen(
        (message) => _onMessage(message, onFrame),
        onError: (Object e) => _onDisconnected(ch, url, onFrame, e),
        onDone: () => _onDisconnected(ch, url, onFrame, 'closed'),
        cancelOnError: true,
      );

      // Auth frame first — same shape as white_label (self-hosted form).
      ch.send({'authID': token, 'trading_account': _account});
      ch.startHeartbeat();
    } catch (e) {
      _onDisconnected(ch, url, onFrame, e);
    } finally {
      ch.connecting = false;
    }
  }

  void _onMessage(dynamic message, void Function(dynamic decoded) onFrame) {
    try {
      dynamic decoded;
      if (MessagePackDecoder.isBinaryMessage(message)) {
        final bytes = message is Uint8List
            ? message
            : Uint8List.fromList(message as List<int>);
        decoded = MessagePackDecoder.decodeBinary(bytes);
        if (decoded == null) {
          try {
            decoded = jsonDecode(message.toString());
          } catch (_) {
            return;
          }
        }
      } else {
        try {
          decoded = jsonDecode(message.toString());
        } catch (_) {
          return;
        }
      }
      onFrame(decoded);
    } catch (e) {
      log.w('positions parse failed: $e');
    }
  }

  void _onOpFrame(dynamic decoded) {
    // Format A — Map envelope: `{ openPositions: { positions: [...] } }` (full snapshot).
    if (decoded is Map) {
      final map = decoded.cast<String, dynamic>();
      final op = map['openPositions'] ?? map['open_positions'];
      if (op is Map) {
        final data = OpenPositionsData.fromJson(op.cast<String, dynamic>());
        openPositions.assignAll(data.positions);
        return;
      }
      // Full snapshot chunk: `{ type: '..._init', chunk: [[...], ...] }`.
      final chunk = map['chunk'];
      if (chunk is List) {
        final parsed = <TradingPosition>[];
        for (final row in chunk) {
          final p = _positionFromOpArray(row);
          if (p != null) parsed.add(p);
        }
        openPositions.assignAll(parsed);
      }
      // Any other Map (authenticated / subscribed / errors) — nothing to do.
      return;
    }
    // Format B — prefixed array(s). A batch is a list-of-lists
    // (`[["a","op",...], ["u","op",...]]`); a single tick is a bare row whose
    // first element is the string tag (`["u","op",...]`). Differentiate on the
    // first element so a bare row is applied whole, not field-by-field.
    if (decoded is List && decoded.isNotEmpty) {
      if (decoded.first is List) {
        for (final row in decoded) {
          _applyOpRow(row);
        }
      } else {
        _applyOpRow(decoded);
      }
    }
  }

  /// Applies one `/op` row: `["a"|"u","op", id, acct, symbol, side, vol, open,
  /// current, profit, swap, sl, tp, serverType, timeCreate, digits, ...]` upserts,
  /// `["r","op", id]` / `["r", acct, id]` removes.
  void _applyOpRow(dynamic row) {
    if (row is! List || row.isEmpty) return;
    final tag = row[0].toString();
    if (tag == 'r') {
      // Remove: id is the last scalar element.
      final id = row.last.toString();
      openPositions.removeWhere((p) => p.position.toString() == id);
      return;
    }
    final position = _positionFromOpArray(row);
    if (position == null) return;
    final idx =
        openPositions.indexWhere((p) => p.position == position.position);
    if (idx >= 0) {
      openPositions[idx] = position;
    } else {
      openPositions.add(position);
    }
  }

  /// Parses a prefixed `/op` array into a [TradingPosition]. Tolerant of the
  /// 8/10/12/17-element variants the trade-engine emits; missing fields default.
  TradingPosition? _positionFromOpArray(dynamic row) {
    if (row is! List) return null;
    // Skip the `["a","op", ...]` prefix when present; some frames are bare.
    final hasPrefix = row.isNotEmpty && row[0] is String;
    final f = hasPrefix && row.length > 2 && row[1].toString() == 'op'
        ? row.sublist(2)
        : row;
    if (f.length < 8) return null;
    double toD(int i) =>
        i < f.length ? (double.tryParse(f[i].toString()) ?? 0.0) : 0.0;
    int toI(int i) => i < f.length ? (int.tryParse(f[i].toString()) ?? 0) : 0;

    // Stripped layout (prefix `["a","op"]` already removed):
    // [0]positionId [1]mt5Account [2]symbol [3]side(0=Buy,1=Sell) [4]volume
    // [5]priceOpen [6]priceCurrent [7]profit [8]swap [9]SL [10]TP
    // [11]serverType("sh") [12]timeCreate(unix s) [13]digits [14]contractSize.
    final side = toI(3);
    final swap = toD(8);
    final sl = toD(9);
    final tp = toD(10);
    final timeCreate = toI(12);
    final digits = f.length > 13 ? toI(13) : 5;
    return TradingPosition(
      mt5Account: toI(1),
      position: toI(0),
      action: side == 0 ? 'Buy' : 'Sell',
      volume: f.length > 4 ? f[4].toString() : '0',
      priceOpen: f.length > 5 ? f[5].toString() : '0',
      priceSL: sl == 0.0 ? '0' : sl.toString(),
      priceTP: tp == 0.0 ? '0' : tp.toString(),
      priceCurrent: f.length > 6 ? f[6].toString() : '0',
      closeTime: '',
      timeCreate: timeCreate > 0
          ? DateTime.fromMillisecondsSinceEpoch(timeCreate * 1000, isUtc: true)
              .toIso8601String()
          : '',
      symbol: f.length > 2 ? f[2].toString() : '',
      logo: '',
      profit: toD(7),
      digits: digits > 0 ? digits : 5,
      swap: swap,
    );
  }

  void _onPoFrame(dynamic decoded) {
    // Format A — Map envelope: `{ pendingOrders: { pendingOrders: [...] } }`.
    if (decoded is Map) {
      final map = decoded.cast<String, dynamic>();
      final po = map['pendingOrders'] ?? map['pending_orders'];
      if (po is Map) {
        final data = PendingOrdersData.fromJson(po.cast<String, dynamic>());
        pendingOrders.assignAll(data.pendingOrders);
        return;
      }
      // Full snapshot chunk: `{ type: 'pending_orders_init', chunk: [[...]] }`.
      final chunk = map['chunk'];
      if (chunk is List) {
        final parsed = <PendingOrder>[];
        for (final row in chunk) {
          final order = _pendingFromPoArray(row);
          if (order != null) parsed.add(order);
        }
        pendingOrders.assignAll(parsed);
      }
      return;
    }
    // Format B — prefixed array(s), the shape the self-hosted engine streams:
    // `[["a","po", ...], ["u","po", ...]]` or a single bare row.
    if (decoded is List && decoded.isNotEmpty) {
      if (decoded.first is List) {
        for (final row in decoded) {
          _applyPoRow(row);
        }
      } else {
        _applyPoRow(decoded);
      }
    }
  }

  /// Applies one `/po` row: `["a"|"u","po", ...]` upserts, `["r","po", id]`
  /// removes the cancelled/filled order.
  void _applyPoRow(dynamic row) {
    if (row is! List || row.isEmpty) return;
    if (row[0].toString() == 'r') {
      final id = row.last.toString();
      pendingOrders.removeWhere((o) => o.order.toString() == id);
      return;
    }
    final order = _pendingFromPoArray(row);
    if (order == null) return;
    final idx = pendingOrders.indexWhere((o) => o.order == order.order);
    if (idx >= 0) {
      pendingOrders[idx] = order;
    } else {
      pendingOrders.add(order);
    }
  }

  /// Parses a prefixed `/po` array into a [PendingOrder]. Stripped layout:
  /// [0]orderId [1]mt5Account [2]symbol [3]type(0=buy_limit,1=sell_limit,
  /// 2=buy_stop,3=sell_stop) [4]volume [5]priceOrder [6]priceCurrent [7]SL
  /// [8]TP [9]serverType [10]timeCreate(unix s) [11]state [12]digits.
  PendingOrder? _pendingFromPoArray(dynamic row) {
    if (row is! List) return null;
    final hasPrefix = row.isNotEmpty && row[0] is String;
    final f = hasPrefix && row.length > 2 && row[1].toString() == 'po'
        ? row.sublist(2)
        : row;
    if (f.length < 7) return null;
    double toD(int i) =>
        i < f.length ? (double.tryParse(f[i].toString()) ?? 0.0) : 0.0;
    int toI(int i) => i < f.length ? (int.tryParse(f[i].toString()) ?? 0) : 0;

    final timeCreate = toI(10);
    final digits = f.length > 12 ? toI(12) : 5;
    return PendingOrder(
      mt5Account: toI(1),
      order: toI(0),
      action: _pendingActionOf(toI(3)),
      symbol: f.length > 2 ? f[2].toString() : '',
      priceOrder: toD(5),
      priceCurrent: toD(6),
      volume: toD(4),
      priceSL: toD(7),
      priceTP: toD(8),
      timeCreate: timeCreate > 0
          ? DateTime.fromMillisecondsSinceEpoch(timeCreate * 1000, isUtc: true)
              .toIso8601String()
          : '',
      state: f.length > 11 ? f[11].toString() : '',
      logo: '',
      digits: digits > 0 ? digits : 5,
    );
  }

  /// Maps the numeric pending type the engine sends to the label
  /// [PendingOrder.toTradePosition] expects (it only checks for "Buy").
  String _pendingActionOf(int type) {
    switch (type) {
      case 1:
        return 'Sell Limit';
      case 2:
        return 'Buy Stop';
      case 3:
        return 'Sell Stop';
      default:
        return 'Buy Limit';
    }
  }

  /// Optimistically drop a position id from the open list (used right after a
  /// close request so the row disappears before the next socket frame).
  void removePositionOptimistic(String orderId) {
    openPositions.removeWhere((p) => p.position.toString() == orderId);
  }

  void removePendingOptimistic(String orderId) {
    pendingOrders.removeWhere((o) => o.order.toString() == orderId);
  }

  void _onDisconnected(
    _Channel ch,
    String url,
    void Function(dynamic decoded) onFrame,
    Object reason,
  ) {
    ch.sub?.cancel();
    ch.sub = null;
    ch.channel = null;
    ch.stopHeartbeat();
    _updateConnected();
    if (ch.manuallyClosed) return;
    log.w('positions/${ch.name} disconnected: $reason — reconnecting');
    ch.reconnectAttempts++;
    final exponent = ch.reconnectAttempts.clamp(1, 5);
    final base = (1 << exponent).clamp(1, 30);
    final jitterMs = Random().nextInt(1000);
    ch.reconnectTimer?.cancel();
    ch.reconnectTimer = Timer(
      Duration(seconds: base, milliseconds: jitterMs),
      () => _connect(ch, url, onFrame),
    );
  }

  void _updateConnected() {
    isConnected.value = _op.channel != null || _po.channel != null;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _op.disconnect();
    _po.disconnect();
    super.onClose();
  }
}

/// Per-socket connection state so [PositionsWsService] can drive `/op` and `/po`
/// independently with identical reconnect/heartbeat logic.
class _Channel {
  _Channel(this.name);

  final String name;
  WebSocketChannel? channel;
  StreamSubscription<dynamic>? sub;
  Timer? reconnectTimer;
  Timer? heartbeatTimer;
  int reconnectAttempts = 0;
  bool connecting = false;
  bool manuallyClosed = false;

  void send(Map<String, dynamic> payload) {
    channel?.sink.add(jsonEncode(payload));
  }

  void startHeartbeat() {
    heartbeatTimer?.cancel();
    heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (channel != null) send(const {});
    });
  }

  void stopHeartbeat() {
    heartbeatTimer?.cancel();
    heartbeatTimer = null;
  }

  void disconnect() {
    manuallyClosed = true;
    reconnectTimer?.cancel();
    stopHeartbeat();
    sub?.cancel();
    sub = null;
    try {
      channel?.sink.close();
    } catch (_) {}
    channel = null;
  }
}
