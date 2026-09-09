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
    _reauth();
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

  void _reauth() async {
    final token = await _authToken();
    if (token == null || token.isEmpty) return;
    final frame = {'authID': token, 'trading_account': _account};
    if (_op.channel != null) {
      _op.send(frame);
    } else {
      _connect(_op, _config.openPositionsUrl, _onOpFrame);
    }
    if (_po.channel != null) {
      _po.send(frame);
    } else {
      _connect(_po, _config.pendingOrdersUrl, _onPoFrame);
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
    if (decoded is! Map) return;
    final map = decoded.cast<String, dynamic>();
    // Control messages (authenticated / errors) have a `type` and no positions.
    final op = map['openPositions'] ?? map['open_positions'];
    if (op is! Map) return;
    final data = OpenPositionsData.fromJson(op.cast<String, dynamic>());
    openPositions.assignAll(data.positions);
  }

  void _onPoFrame(dynamic decoded) {
    if (decoded is! Map) return;
    final map = decoded.cast<String, dynamic>();
    final po = map['pendingOrders'] ?? map['pending_orders'];
    if (po is! Map) return;
    final data = PendingOrdersData.fromJson(po.cast<String, dynamic>());
    pendingOrders.assignAll(data.pendingOrders);
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
      if (channel != null) send({'action': 'ping'});
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
