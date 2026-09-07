import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../app/flavor/flavor_config.dart';
import '../logger/app_logger.dart';
import 'websocket_message.dart';
import 'websocket_subscription_manager.dart';

/// The ONLY owner of a WebSocket connection in the app. Widgets and controllers
/// never open sockets — they subscribe to a topic here and listen to [messages]
/// (or the per-topic filtered stream). Handles connect / reconnect with
/// exponential backoff, heartbeat, and automatic resubscription.
class WebSocketManager extends GetxService {
  WebSocketManager(this._config);

  final FlavorConfig _config;
  final SubscriptionManager _subs = SubscriptionManager();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _manuallyClosed = false;

  final _stateController =
      StreamController<WsConnectionState>.broadcast();
  final _messageController = StreamController<WsMessage>.broadcast();

  WsConnectionState _state = WsConnectionState.disconnected;

  Stream<WsConnectionState> get connectionState => _stateController.stream;
  Stream<WsMessage> get messages => _messageController.stream;

  /// Filtered stream for a single topic — controllers use this so only the
  /// widgets bound to that topic rebuild.
  Stream<WsMessage> streamFor(String topic) =>
      _messageController.stream.where((m) => m.topic == topic);

  void _setState(WsConnectionState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  Future<void> connect() async {
    if (_state == WsConnectionState.connected ||
        _state == WsConnectionState.connecting) {
      return;
    }
    _manuallyClosed = false;
    _setState(WsConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_config.wsUrl));
      await _channel!.ready;
      _reconnectAttempts = 0;
      _setState(WsConnectionState.connected);
      _startHeartbeat();
      _resubscribeAll();

      _channelSub = _channel!.stream.listen(
        _onData,
        onError: (Object e) => _onDisconnected(e),
        onDone: () => _onDisconnected('closed'),
        cancelOnError: true,
      );
    } catch (e) {
      _onDisconnected(e);
    }
  }

  void _onData(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      final topic = decoded['topic'] as String? ?? 'unknown';
      if (!_messageController.isClosed) {
        _messageController.add(WsMessage(topic: topic, data: decoded));
      }
    } catch (e) {
      log.w('WS parse failed: $e');
    }
  }

  void subscribe(String topic) {
    if (_subs.add(topic)) {
      _send({'action': 'subscribe', 'topic': topic});
    }
  }

  void unsubscribe(String topic) {
    if (_subs.remove(topic)) {
      _send({'action': 'unsubscribe', 'topic': topic});
    }
  }

  void _resubscribeAll() {
    for (final topic in _subs.activeTopics) {
      _send({'action': 'subscribe', 'topic': topic});
    }
  }

  void _send(Map<String, dynamic> payload) {
    if (_state == WsConnectionState.connected && _channel != null) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) {
      _send({'action': 'ping'});
    });
  }

  void _onDisconnected(Object reason) {
    _heartbeat?.cancel();
    _channelSub?.cancel();
    _channel = null;
    if (_manuallyClosed) {
      _setState(WsConnectionState.disconnected);
      return;
    }
    log.w('WS disconnected: $reason — scheduling reconnect');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _setState(WsConnectionState.reconnecting);
    _reconnectAttempts++;
    // Exponential backoff capped at 30s, with jitter so a fleet of clients
    // doesn't reconnect in lockstep after a server blip. The exponent is
    // clamped so `1 << n` can never overflow on a long outage.
    final exponent = _reconnectAttempts.clamp(1, 5);
    final base = (1 << exponent).clamp(1, 30);
    final jitterMs = Random().nextInt(1000);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: base, milliseconds: jitterMs),
      connect,
    );
  }

  Future<void> disconnect() async {
    _manuallyClosed = true;
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    await _channelSub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(WsConnectionState.disconnected);
  }

  @override
  Future<void> onClose() async {
    // Await the socket teardown BEFORE closing the controllers, so no late
    // `_setState`/message add can fire on an already-closed StreamController.
    await disconnect();
    _subs.clear();
    await _stateController.close();
    await _messageController.close();
    super.onClose();
  }
}
