import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../logger/app_logger.dart';

/// Called right after the socket handshake completes, before any frame is
/// read. Send the auth/subscribe frames here. Return `false` to abort (e.g. no
/// auth token) — the socket is closed and NOT retried until [WsConnection.restart].
typedef WsOnOpen = Future<bool> Function(WsConnection connection);

/// One logical socket owned by [WebSocketManager]. Holds the transport only —
/// connect, stale-attempt guarding, reconnect with backoff, heartbeat, send —
/// so feature services keep just their protocol (auth frame + decode).
class WsConnection {
  WsConnection({
    required this.name,
    required this.url,
    required this.onMessage,
    this.onOpen,
    this.onClosed,
    this.heartbeat,
    this.heartbeatInterval = const Duration(seconds: 20),
    this.connectGate,
  });

  final String name;

  /// Read on every attempt so a config change applies on the next reconnect.
  final String Function() url;
  final void Function(dynamic message) onMessage;
  final WsOnOpen? onOpen;

  /// Fired whenever the live socket is dropped (error, server close, restart).
  final void Function()? onClosed;

  /// Frame sent every [heartbeatInterval] while connected; null = no heartbeat.
  final Object? Function()? heartbeat;
  final Duration heartbeatInterval;

  /// Checked before every attempt; returning false skips the connect quietly
  /// (used for "no auth token yet").
  final Future<bool> Function()? connectGate;

  final RxBool isConnected = false.obs;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  bool _connecting = false;
  bool _closed = false;

  /// Bumped on every restart/close; an in-flight connect whose value no longer
  /// matches is stale and must leave the socket state alone.
  int _attempt = 0;

  bool get hasChannel => _channel != null;

  /// Opens the socket if it isn't open or opening. Safe to call repeatedly.
  Future<void> connect() async {
    // Flip the guard synchronously, before the first await: several callers
    // (init, resume, subscribe) can hit this in the same microtask.
    if (_connecting || _channel != null) return;
    final attempt = ++_attempt;
    bool isStale() => attempt != _attempt;
    _connecting = true;
    _closed = false;
    try {
      final gate = connectGate;
      if (gate != null && !await gate()) return;
      if (isStale()) return;

      final channel = WebSocketChannel.connect(Uri.parse(url()));
      await channel.ready;
      // Restarted or closed while the handshake was in flight — drop it.
      if (isStale()) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _sub = channel.stream.listen(
        onMessage,
        onError: (Object e) => _onDisconnected(e),
        onDone: () => _onDisconnected('closed'),
        cancelOnError: true,
      );

      final open = onOpen;
      if (open != null && !await open(this)) {
        _teardown();
        return;
      }
      if (isStale()) return;
      _reconnectAttempts = 0;
      isConnected.value = true;
      _startHeartbeat();
    } catch (e) {
      if (attempt == _attempt) _onDisconnected(e);
    } finally {
      if (attempt == _attempt) _connecting = false;
    }
  }

  /// Sends a JSON-encoded [payload] if the socket is open; dropped otherwise.
  void send(Object payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  /// Marks the connection live without waiting for [connect] to finish — for
  /// protocols (Pusher) that only count as connected after a server event.
  void markConnected() {
    _reconnectAttempts = 0;
    isConnected.value = true;
    _startHeartbeat();
  }

  /// Closes the current socket and immediately opens a fresh one with a reset
  /// backoff (account switch, login/logout).
  void restart() {
    _attempt++;
    _connecting = false;
    _reconnectAttempts = 0;
    _teardown();
    connect();
  }

  /// Closes the socket for good; no reconnect until [connect] is called again.
  Future<void> close() async {
    _closed = true;
    _attempt++;
    _connecting = false;
    final channel = _channel;
    _teardown();
    try {
      await channel?.sink.close();
    } catch (e) {
      log.w('ws/$name sink close failed: $e');
    }
  }

  void _teardown() {
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (e) {
      log.w('ws/$name sink close failed: $e');
    }
    final hadChannel = _channel != null;
    _channel = null;
    isConnected.value = false;
    if (hadChannel) onClosed?.call();
  }

  void _onDisconnected(Object reason) {
    _sub?.cancel();
    _sub = null;
    final hadChannel = _channel != null;
    _channel = null;
    isConnected.value = false;
    _stopHeartbeat();
    if (hadChannel) onClosed?.call();
    if (_closed) return;
    log.w('ws/$name disconnected: $reason — reconnecting');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    // Exponential backoff capped at 30s, with jitter so a fleet of clients
    // doesn't reconnect in lockstep after a server blip.
    final exponent = _reconnectAttempts.clamp(1, 5);
    final base = (1 << exponent).clamp(1, 30);
    final jitterMs = Random().nextInt(1000);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: base, milliseconds: jitterMs),
      connect,
    );
  }

  /// Reconnect immediately if the socket died while the app was backgrounded.
  void resumeIfDropped() {
    if (_closed || _channel != null) return;
    _reconnectTimer?.cancel();
    connect();
  }

  void _startHeartbeat() {
    final frame = heartbeat;
    if (frame == null) return;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (_channel == null) return;
      final payload = frame();
      if (payload != null) send(payload);
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}
