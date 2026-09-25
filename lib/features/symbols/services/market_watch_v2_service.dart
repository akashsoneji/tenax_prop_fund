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

/// A single live quote for one symbol, patched in place from `marketwatchv2`
/// ticks. Only the fields the feed sends are updated; the rest are preserved.
class MarketPrice {
  const MarketPrice({
    required this.symbol,
    this.bid = 0,
    this.ask = 0,
    this.spread = 0,
    this.digits = 5,
    this.dayHigh,
    this.dayLow,
    this.category,
  });

  final String symbol;
  final double bid;
  final double ask;
  final double spread;
  final int digits;
  final double? dayHigh;
  final double? dayLow;
  final String? category;

  MarketPrice copyWith({
    double? bid,
    double? ask,
    double? spread,
    int? digits,
    double? dayHigh,
    double? dayLow,
    String? category,
  }) =>
      MarketPrice(
        symbol: symbol,
        bid: bid ?? this.bid,
        ask: ask ?? this.ask,
        spread: spread ?? this.spread,
        digits: digits ?? this.digits,
        dayHigh: dayHigh ?? this.dayHigh,
        dayLow: dayLow ?? this.dayLow,
        category: category ?? this.category,
      );
}

/// Owns the ONE `marketwatchv2` WebSocket for the whole app (mirrors the pattern
/// used by [WebSocketManager] for the generic socket). Widgets and controllers
/// never open a socket — they call [subscribeSymbols] and read [priceOf] /
/// [decodedFrames].
///
/// Contract (client → server, JSON text on the same socket):
/// 1. `{"authID":"<token>","trading_account":"0"}` — first frame after connect.
/// 2. `{"action":"subscribe","symbols":["EURUSD",...]}` — start ticks.
/// 3. `{"action":"unsubscribe","symbols":["EURUSD"]}` — stop ticks.
///
/// Server → client: binary MessagePack ticks (see [MessagePackDecoder]) shaped
/// `[symbol, bid, ask, spread, digits, day_high, day_low, category]`, arrays of
/// those, or `{symbol, bid, ask, ...}` maps. All shapes are normalised into the
/// per-symbol [prices] map so a granular `Obx` only rebuilds the affected row.
class MarketWatchV2Service extends GetxService with WidgetsBindingObserver {
  MarketWatchV2Service(this._config, this._storage);

  final FlavorConfig _config;
  final FlutterSecureStorage _storage;

  /// Seeded so the listing shows live data immediately on app open, before the
  /// symbols screen (and its own subscribe call) is ever visited.
  static const List<String> _seedSymbols = ['XAUUSD', 'EURUSD', 'GBPUSD'];

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  bool _manuallyClosed = false;

  /// Bumped by [resetForNewSession]. A connect that was already in flight when
  /// the session changed reads the OLD token, so it checks this before adopting
  /// its channel and aborts when it is stale.
  int _session = 0;
  bool _connecting = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _desired.addAll(_seedSymbols);
    for (final s in _seedSymbols) {
      priceOf(s);
    }
    _connect();
  }

  /// Reconnect the moment the app returns to the foreground: iOS and Android
  /// both suspend/kill open sockets while backgrounded, so on resume we force a
  /// fresh connect (which replays [_desired]) if the socket is gone.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _channel == null) {
      _reconnectTimer?.cancel();
      _connect();
    }
  }

  /// Symbols the caller wants ticks for. Resent verbatim after every reconnect
  /// so the server-side subscription always matches the client's intent.
  final Set<String> _desired = <String>{};

  /// Live quote per (normalised) symbol. Read via [priceOf] and bind with `Obx`.
  final RxMap<String, Rx<MarketPrice>> prices = <String, Rx<MarketPrice>>{}.obs;

  /// Raw decoded frames, for callers that want the whole payload rather than the
  /// per-symbol map (e.g. a debug console).
  final StreamController<dynamic> _decodedBroadcast =
      StreamController<dynamic>.broadcast();
  Stream<dynamic> get decodedFrames => _decodedBroadcast.stream;

  final RxBool isConnected = false.obs;

  /// The symbol the user last tapped in the Trade list. The Markets tab watches
  /// this to load that symbol's chart + trade ticket. Seeded to the first seed
  /// symbol so both tabs agree before the user taps anything.
  final RxString selectedSymbol = _seedSymbols.first.obs;

  /// Sets the active symbol app-wide and makes sure it is subscribed for ticks.
  void selectSymbol(String symbol) {
    final key = normalizeSymbol(symbol);
    if (key.isEmpty) return;
    selectedSymbol.value = key;
    subscribeSymbols([key]);
  }

  /// Strips a broker suffix (`EURUSD.c` → `EURUSD`) and upper-cases, so both the
  /// client subscription and the server tick key resolve to the same symbol.
  static String normalizeSymbol(String raw) {
    var s = raw.trim();
    if (s.contains('.')) s = s.substring(0, s.lastIndexOf('.'));
    return s.toUpperCase();
  }

  /// Reactive quote for [symbol], created (empty) on first access so a widget can
  /// bind before the first tick arrives.
  Rx<MarketPrice> priceOf(String symbol) {
    final key = normalizeSymbol(symbol);
    return prices.putIfAbsent(
      key,
      () => Rx<MarketPrice>(MarketPrice(symbol: key)),
    );
  }

  Future<String?> _authToken() =>
      _storage.read(key: ApiInterceptor.tokenKey);

  /// Restarts the socket so it re-auths with whatever token is currently stored.
  /// Called on logout (no token → connect is skipped and the socket stays down)
  /// and again after login, so ticks are never served on the previous user's
  /// authenticated connection. Desired subscriptions are kept: they are the
  /// device's watchlist, not per-user session state.
  void resetForNewSession() {
    _session++;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connecting = false;
    isConnected.value = false;
    _reconnectAttempts = 0;
    _connect();
  }

  Future<void> _connect() async {
    // Re-entrancy guard MUST flip synchronously, before the first await:
    // onInit, lifecycle-resume and subscribeSymbols can all call _connect in
    // the same microtask, and if the flag were set after `await _authToken()`
    // every caller would pass the guard and open a duplicate socket.
    if (_connecting || _channel != null) return;
    final session = _session;
    _connecting = true;
    _manuallyClosed = false;

    try {
      final token = await _authToken();
      if (token == null || token.isEmpty) {
        log.w('marketwatchv2: no auth token, skipping connect');
        return;
      }
      if (session != _session) return;

      final channel = WebSocketChannel.connect(Uri.parse(_config.marketWatchV2Url));
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

      // 1. Auth frame first. trading_account is '0' until account wiring lands.
      _send({'authID': token, 'trading_account': '0'});
      // 2. Restore any symbols requested before the socket was ready.
      _resubscribeAll();
      _startHeartbeat();
    } catch (e) {
      _onDisconnected(e);
    } finally {
      _connecting = false;
    }
  }

  void _send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode(payload));
  }

  /// Application-level keep-alive: a periodic ping stops idle NATs / proxies
  /// from silently dropping the socket while the user sits on one screen.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_channel != null) _send({'action': 'ping'});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _resubscribeAll() {
    if (_desired.isEmpty) return;
    _send({'action': 'subscribe', 'symbols': _desired.toList()});
  }

  /// Opens the socket (if needed) and starts ticks for [symbols].
  Future<void> subscribeSymbols(List<String> symbols) async {
    final clean =
        symbols.map(normalizeSymbol).where((s) => s.isNotEmpty).toSet();
    if (clean.isEmpty) return;
    _desired.addAll(clean);
    for (final s in clean) {
      priceOf(s);
    }

    if (_channel == null) {
      await _connect();
      return;
    }
    _send({'action': 'subscribe', 'symbols': clean.toList()});
  }

  /// Stops ticks for [symbols] (keeps the socket open for the rest).
  void unsubscribeSymbols(List<String> symbols) {
    final clean =
        symbols.map(normalizeSymbol).where((s) => s.isNotEmpty).toSet();
    if (clean.isEmpty) return;
    _desired.removeAll(clean);
    _send({'action': 'unsubscribe', 'symbols': clean.toList()});
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
      if (!_decodedBroadcast.isClosed) _decodedBroadcast.add(decoded);
    } catch (e) {
      log.w('marketwatchv2 parse failed: $e');
    }
  }

  void _applyDecoded(dynamic decoded) {
    if (decoded is Map) {
      _applyTickMap(decoded);
      return;
    }
    if (decoded is List && decoded.isNotEmpty) {
      if (decoded.first is List) {
        for (final row in decoded) {
          if (row is List) _applyTickRow(row);
        }
      } else if (decoded.first is Map) {
        for (final row in decoded) {
          if (row is Map) _applyTickMap(row);
        }
      } else if (decoded.first is String) {
        _applyTickRow(decoded);
      }
    }
  }

  /// Array tick: `[symbol, bid, ask, spread, digits, day_high, day_low, category]`.
  void _applyTickRow(List row) {
    if (row.length < 3) return;
    final symbol = normalizeSymbol(row[0].toString());
    if (symbol.isEmpty) return;

    final rx = priceOf(symbol);
    final cur = rx.value;
    rx.value = cur.copyWith(
      bid: _d(row[1]) ?? cur.bid,
      ask: _d(row[2]) ?? cur.ask,
      spread: row.length > 3 ? _d(row[3]) : null,
      digits: row.length > 4 ? _i(row[4]) : null,
      dayHigh: row.length > 5 ? _d(row[5]) : null,
      dayLow: row.length > 6 ? _d(row[6]) : null,
      category: row.length > 7 ? row[7]?.toString() : null,
    );
  }

  /// Map tick: `{symbol/s, bid/b, ask/a, spread, digits, day_high, day_low}`.
  void _applyTickMap(Map raw) {
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (raw[k] != null) return raw[k];
      }
      return null;
    }

    final symRaw = pick(['symbol', 'Symbol', 's', 'name']);
    if (symRaw == null) return;
    final symbol = normalizeSymbol(symRaw.toString());
    if (symbol.isEmpty) return;

    final rx = priceOf(symbol);
    final cur = rx.value;
    rx.value = cur.copyWith(
      bid: _d(pick(['bid', 'Bid', 'b'])) ?? cur.bid,
      ask: _d(pick(['ask', 'Ask', 'a'])) ?? cur.ask,
      spread: _d(pick(['spread', 'spread_points', 'spreadPoints'])),
      digits: _i(pick(['digits', 'Digits', 'd'])),
      dayHigh: _d(pick(['day_high', 'dayHigh', 'high'])),
      dayLow: _d(pick(['day_low', 'dayLow', 'low'])),
      category: pick(['category', 'Category', 'group'])?.toString(),
    );
  }

  static double? _d(dynamic v) =>
      v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

  static int? _i(dynamic v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

  void _onDisconnected(Object reason) {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    isConnected.value = false;
    _stopHeartbeat();
    if (_manuallyClosed) return;
    log.w('marketwatchv2 disconnected: $reason — scheduling reconnect');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    // Exponential backoff capped at 30s with jitter so many clients don't
    // reconnect in lockstep after a server blip.
    final exponent = _reconnectAttempts.clamp(1, 5);
    final base = (1 << exponent).clamp(1, 30);
    final jitterMs = Random().nextInt(1000);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: base, milliseconds: jitterMs),
      _connect,
    );
  }

  Future<void> disconnect() async {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    isConnected.value = false;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    if (!_decodedBroadcast.isClosed) _decodedBroadcast.close();
    super.onClose();
  }
}
