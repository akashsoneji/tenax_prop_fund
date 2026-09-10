import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../logger/app_logger.dart';

/// Connection lifecycle of the Pusher socket, surfaced so the UI can show a
/// "live" indicator.
enum PusherState { disconnected, connecting, connected, reconnecting }

/// A decoded `AccountStateUpdated` frame from the trade engine. Money fields are
/// in minor units (cents); `*_bps` fields are basis points (÷100 = percent).
class AccountStateEvent {
  const AccountStateEvent({
    required this.accountId,
    required this.login,
    required this.currency,
    required this.balanceMinor,
    required this.equityMinor,
    required this.marginMinor,
    required this.freeMarginMinor,
    required this.profitMinor,
    required this.marginLevel,
    required this.hwmEquityMinor,
    required this.dailyLossBps,
    required this.totalLossBps,
    required this.drawdownBps,
    required this.profitBps,
    required this.stale,
  });

  final int accountId;
  final String login;
  final String currency;
  final int balanceMinor;
  final int equityMinor;
  final int marginMinor;
  final int freeMarginMinor;
  final int profitMinor;
  final double marginLevel;
  final int hwmEquityMinor;
  final int dailyLossBps;
  final int totalLossBps;
  final int drawdownBps;
  final int profitBps;
  final bool stale;

  factory AccountStateEvent.fromJson(Map<String, dynamic> json) {
    final state = (json['state'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AccountStateEvent(
      accountId: (json['account_id'] as num?)?.toInt() ?? 0,
      login: state['login']?.toString() ?? '',
      currency: state['currency'] as String? ?? 'USD',
      balanceMinor: (state['balance_minor'] as num?)?.toInt() ?? 0,
      equityMinor: (state['equity_minor'] as num?)?.toInt() ?? 0,
      marginMinor: (state['margin_minor'] as num?)?.toInt() ?? 0,
      freeMarginMinor: (state['free_margin_minor'] as num?)?.toInt() ?? 0,
      profitMinor: (state['profit_minor'] as num?)?.toInt() ?? 0,
      marginLevel: (state['margin_level'] as num?)?.toDouble() ?? 0,
      hwmEquityMinor: (state['hwm_equity_minor'] as num?)?.toInt() ?? 0,
      dailyLossBps: (state['daily_loss_bps'] as num?)?.toInt() ?? 0,
      totalLossBps: (state['total_loss_bps'] as num?)?.toInt() ?? 0,
      drawdownBps: (state['drawdown_bps'] as num?)?.toInt() ?? 0,
      profitBps: (state['profit_bps'] as num?)?.toInt() ?? 0,
      stale: state['stale'] as bool? ?? false,
    );
  }
}

/// Resolves the private-channel auth signature for a Pusher subscription.
///
/// Private channels (`private-…`) require the server to sign `socketId:channel`.
/// The concrete endpoint is not wired yet, so the default returns `null` and we
/// attempt the subscription unsigned. Swap this for a real implementation
/// (POST `{socket_id, channel_name}` to the broadcasting-auth endpoint with the
/// bearer token, read back `data.auth`) once the path is known.
typedef PusherAuthResolver = Future<String?> Function(
    String socketId, String channel);

/// A minimal Pusher/Soketi protocol client dedicated to the Home dashboard's
/// live account feed. It is deliberately NOT the generic [WebSocketManager]:
/// the wire format (`{event, channel, data}` where `data` is a stringified JSON
/// blob) and the handshake (`pusher:connection_established` → `pusher:subscribe`
/// → `pusher:ping/pong`) are Pusher-specific.
///
/// The client owns exactly one socket, reconnects with exponential backoff,
/// resubscribes on reconnect, and exposes a broadcast [accountStates] stream of
/// decoded [AccountStateEvent]s plus a [states] stream for the connection badge.
class PusherClient {
  PusherClient(this._url, {this.authResolver});

  final String _url;

  /// Resolves the private-channel auth signature. Left null until the
  /// broadcasting-auth endpoint is wired; subscriptions are attempted unsigned.
  final PusherAuthResolver? authResolver;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _manuallyClosed = false;
  String? _socketId;

  final _channels = <String>{};

  final _stateController = StreamController<PusherState>.broadcast();
  final _accountController = StreamController<AccountStateEvent>.broadcast();

  PusherState _state = PusherState.disconnected;

  Stream<PusherState> get states => _stateController.stream;
  Stream<AccountStateEvent> get accountStates => _accountController.stream;
  bool get isConnected => _state == PusherState.connected;

  void _setState(PusherState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  Future<void> connect() async {
    if (_state == PusherState.connected || _state == PusherState.connecting) {
      return;
    }
    _manuallyClosed = false;
    _setState(PusherState.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      await _channel!.ready;
      _channelSub = _channel!.stream.listen(
        _onData,
        onError: (Object e) => _onDisconnected(e),
        onDone: () => _onDisconnected('closed'),
        cancelOnError: true,
      );
      // Connection is only "established" once the server sends its socket_id;
      // until then we stay in `connecting`.
    } catch (e) {
      _onDisconnected(e);
    }
  }

  /// Subscribes to a channel (resolving auth first for `private-`/`presence-`
  /// channels). Safe to call before the socket is connected — the channel is
  /// remembered and (re)subscribed once `pusher:connection_established` lands.
  Future<void> subscribe(String channel) async {
    _channels.add(channel);
    await _sendSubscribe(channel);
  }

  void unsubscribe(String channel) {
    _channels.remove(channel);
    _send({
      'event': 'pusher:unsubscribe',
      'data': {'channel': channel},
    });
  }

  Future<void> _sendSubscribe(String channel) async {
    if (_state != PusherState.connected) return;
    final data = <String, dynamic>{'channel': channel};
    final needsAuth =
        channel.startsWith('private-') || channel.startsWith('presence-');
    if (needsAuth && _socketId != null && authResolver != null) {
      try {
        final auth = await authResolver!(_socketId!, channel);
        if (auth != null) data['auth'] = auth;
      } catch (e) {
        log.w('Pusher auth failed for $channel: $e');
      }
    }
    _send({'event': 'pusher:subscribe', 'data': data});
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      log.w('Pusher frame parse failed: $e');
      return;
    }

    final event = frame['event'] as String?;
    switch (event) {
      case 'pusher:connection_established':
        _onEstablished(frame['data']);
        return;
      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': {}});
        return;
      case 'pusher:error':
        log.w('Pusher error: ${frame['data']}');
        return;
      default:
        // Laravel/Reverb broadcasts the event as `AccountStateUpdated`, but a
        // custom broadcastAs or class-name broadcast can arrive namespaced
        // (`.AccountStateUpdated`, `App\\Events\\AccountStateUpdated`). Match on
        // the trailing segment so the tick is never silently dropped.
        if (event != null && _isAccountStateEvent(event)) {
          _onAccountState(frame['data']);
        }
        // pusher_internal:subscription_succeeded and others — ignored.
        return;
    }
  }

  /// True when [event] is an `AccountStateUpdated` broadcast, tolerating a
  /// leading `.` (Laravel `broadcastAs`) or a `App\Events\`/`\` class prefix.
  bool _isAccountStateEvent(String event) {
    final name = event.split(RegExp(r'[\\.]')).last;
    return name == 'AccountStateUpdated';
  }

  void _onEstablished(dynamic data) {
    final decoded = _decodeData(data);
    _socketId = decoded?['socket_id']?.toString();
    _reconnectAttempts = 0;
    _setState(PusherState.connected);
    _startHeartbeat();
    // (Re)subscribe every remembered channel now that we have a socket_id.
    for (final channel in _channels) {
      _sendSubscribe(channel);
    }
  }

  void _onAccountState(dynamic data) {
    final decoded = _decodeData(data);
    if (decoded == null) return;
    try {
      final event = AccountStateEvent.fromJson(decoded);
      if (!_accountController.isClosed) _accountController.add(event);
    } catch (e) {
      log.w('AccountStateUpdated decode failed: $e');
    }
  }

  /// Pusher's `data` field is a JSON STRING (double-encoded); decode it. It can
  /// occasionally arrive already as a Map, so tolerate both.
  Map<String, dynamic>? _decodeData(dynamic data) {
    if (data is Map) return data.cast<String, dynamic>();
    if (data is String && data.isNotEmpty) {
      try {
        final v = jsonDecode(data);
        if (v is Map) return v.cast<String, dynamic>();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Timer? _heartbeat;
  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      _send({'event': 'pusher:ping', 'data': {}});
    });
  }

  void _send(Map<String, dynamic> payload) {
    if (_state == PusherState.connected && _channel != null) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void _onDisconnected(Object reason) {
    _heartbeat?.cancel();
    _channelSub?.cancel();
    _channel = null;
    _socketId = null;
    if (_manuallyClosed) {
      _setState(PusherState.disconnected);
      return;
    }
    log.w('Pusher disconnected: $reason — scheduling reconnect');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _setState(PusherState.reconnecting);
    _reconnectAttempts++;
    final exponent = _reconnectAttempts.clamp(1, 5);
    final base = (1 << exponent).clamp(1, 30);
    final jitterMs = Random().nextInt(1000);
    _reconnectTimer?.cancel();
    _reconnectTimer =
        Timer(Duration(seconds: base, milliseconds: jitterMs), connect);
  }

  Future<void> disconnect() async {
    _manuallyClosed = true;
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    await _channelSub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _socketId = null;
    _setState(PusherState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    _channels.clear();
    await _stateController.close();
    await _accountController.close();
  }
}
