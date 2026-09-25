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

/// Owns the ONE `/account` socket that streams live equity/margin for the active
/// trading account. Styled like [MarketWatchV2Service]: self-connecting
/// [GetxService] with reconnect/backoff/heartbeat and MessagePack/JSON decode.
///
/// Protocol ported VERBATIM from white_label `account_websocket_service.dart`:
/// - After connect, send `{authID, trading_account}`.
/// - Server pushes an array frame `["ac", account, balance, credit, equity,
///   margin, free_margin, margin_level, profit, swap]` (NEW, len>=10) or the
///   older `["ac", account, balance, equity, margin, free_margin, margin_level,
///   profit, swap]` (no credit). Frames may be a single array or an array of
///   arrays, binary MessagePack or JSON.
///
/// The controller reads [account] (a granular `Obx`) for the summary strip.
class AccountWsService extends GetxService with WidgetsBindingObserver {
  AccountWsService(this._config, this._storage);

  final FlavorConfig _config;
  final FlutterSecureStorage _storage;

  /// Live account snapshot. Starts empty; patched on every `ac` frame that
  /// matches the subscribed account.
  final Rx<AccountInfo> account = AccountInfo.empty().obs;

  final RxBool isConnected = false.obs;

  String _account = '0';

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  bool _manuallyClosed = false;
  bool _connecting = false;

  /// Bumped by [resetForNewSession]. A connect that was already in flight when
  /// the session changed reads the OLD token, so it checks this before adopting
  /// its channel and aborts when it is stale.
  int _session = 0;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _connect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _channel == null) {
      _reconnectTimer?.cancel();
      _connect();
    }
  }

  /// Re-auth for a new trading account (called on account switch / first
  /// resolve). Clears the stale snapshot so the summary strip doesn't show the
  /// previous account's numbers.
  void switchAccount(String account) {
    if (account.isEmpty || account == _account) return;
    _account = account;
    this.account.value = AccountInfo.empty();
    // Full restart: tear the current socket down and open a fresh one for the
    // new account (mirrors the dashboard set-primary flow), instead of only
    // re-authing on the stale connection.
    _reconnect();
  }

  /// Forgets the bound trading account and the last snapshot, then restarts the
  /// socket with whatever token is currently stored. Called on logout (no token
  /// → the connect attempt is skipped and the socket stays down) and again after
  /// login, so the next user never inherits the previous user's stream.
  void resetForNewSession() {
    _session++;
    _account = '0';
    account.value = AccountInfo.empty();
    _reconnect();
  }

  /// Closes the live socket and immediately opens a new one. A deliberate
  /// restart, so [_manuallyClosed] is cleared by [_connect] and the reconnect
  /// backoff is reset.
  void _reconnect() {
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    isConnected.value = false;
    _connecting = false;
    _reconnectAttempts = 0;
    _connect();
  }


  Future<String?> _authToken() => _storage.read(key: ApiInterceptor.tokenKey);

  Future<void> _connect() async {
    if (_connecting || _channel != null) return;
    final session = _session;
    _connecting = true;
    _manuallyClosed = false;
    try {
      final token = await _authToken();
      if (token == null || token.isEmpty) {
        log.w('account ws: no auth token, skipping connect');
        return;
      }
      if (session != _session) return;
      final channel = WebSocketChannel.connect(Uri.parse(_config.accountWsUrl));
      await channel.ready;
      // The session changed while the handshake was in flight — this socket
      // would auth with the previous user's token, so drop it.
      if (session != _session) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _reconnectAttempts = 0;
      isConnected.value = true;

      _sub = channel.stream.listen(
        _onMessage,
        onError: (Object e) => _onDisconnected(e),
        onDone: () => _onDisconnected('closed'),
        cancelOnError: true,
      );

      _requestData();
      _startHeartbeat();
    } catch (e) {
      _onDisconnected(e);
    } finally {
      _connecting = false;
    }
  }

  void _requestData() async {
    final session = _session;
    final token = await _authToken();
    if (token == null || token.isEmpty || _channel == null) return;
    if (session != _session) return;
    _send({'authID': token, 'trading_account': _account});
  }

  void _send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_channel != null) _send(const {});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _onMessage(dynamic message) {
    try {
      dynamic decoded;
      if (MessagePackDecoder.isBinaryMessage(message)) {
        final bytes = message is Uint8List
            ? message
            : Uint8List.fromList(message as List<int>);
        decoded = MessagePackDecoder.decodeBinary(bytes);
        if (decoded == null) return;
      } else {
        try {
          decoded = jsonDecode(message.toString());
        } catch (_) {
          return;
        }
      }
      _applyDecoded(decoded);
    } catch (e) {
      log.w('account ws parse failed: $e');
    }
  }

  void _applyDecoded(dynamic decoded) {
    if (decoded is! List || decoded.isEmpty) return;
    // Array of arrays (multiple updates) vs a single ["ac", ...] frame.
    if (decoded.first is List) {
      for (final row in decoded) {
        if (row is List) _parseAccountArray(row);
      }
    } else if (decoded.first is String) {
      _parseAccountArray(decoded);
    }
  }

  /// Parses one `["ac", ...]` frame. Detects NEW (with credit) vs OLD format the
  /// same way white_label does: whichever satisfies
  /// `Equity ≈ Balance + Credit + Profit + Swap` best; default NEW when long.
  void _parseAccountArray(List a) {
    if (a.isEmpty || a[0]?.toString().toLowerCase() != 'ac' || a.length < 2) {
      return;
    }
    final acct = a[1].toString();
    if (_account != '0' && acct != _account) return;

    final balance = _at(a, 2);
    var isNewFormat = a.length >= 10;
    if (a.length >= 9) {
      final nDiff =
          (_at(a, 4) - (_at(a, 2) + _at(a, 3) + _at(a, 8) + _at(a, 9))).abs();
      final oDiff = (_at(a, 3) - (_at(a, 2) + _at(a, 7) + _at(a, 8))).abs();
      if (nDiff < oDiff && nDiff < 5.0) {
        isNewFormat = true;
      } else if (oDiff < nDiff && oDiff < 5.0) {
        isNewFormat = false;
      }
    } else {
      isNewFormat = false;
    }

    final double credit, equity, margin, freeMargin, marginLevel, profit, swap;
    if (isNewFormat) {
      credit = _at(a, 3);
      equity = _at(a, 4);
      margin = _at(a, 5);
      freeMargin = _at(a, 6);
      marginLevel = _at(a, 7);
      profit = _at(a, 8);
      swap = _at(a, 9);
    } else {
      credit = 0.0;
      equity = _at(a, 3);
      margin = _at(a, 4);
      freeMargin = _at(a, 5);
      marginLevel = _at(a, 6);
      profit = _at(a, 7);
      swap = _at(a, 8);
    }

    account.value = AccountInfo(
      balance: balance,
      credit: credit,
      equity: equity,
      margin: margin,
      marginFree: freeMargin,
      marginLevel: marginLevel,
      profit: profit,
      storage: swap,
      login: int.tryParse(acct) ?? 0,
    );
  }

  static double _at(List a, int i) {
    if (i >= a.length) return 0.0;
    final v = a[i];
    return v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);
  }

  void _onDisconnected(Object reason) {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    isConnected.value = false;
    _stopHeartbeat();
    if (_manuallyClosed) return;
    log.w('account ws disconnected: $reason — reconnecting');
    _reconnectAttempts++;
    final exponent = _reconnectAttempts.clamp(1, 5);
    final base = (1 << exponent).clamp(1, 30);
    final jitterMs = Random().nextInt(1000);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: base, milliseconds: jitterMs),
      _connect,
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _sub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    super.onClose();
  }
}
