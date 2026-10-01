import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'ws_connection.dart';

/// The ONLY owner of WebSocket connections in the app. Feature services never
/// open a socket themselves — they call [open] once with their endpoint and
/// protocol hooks and talk through the returned [WsConnection]. One instance
/// per [name]; asking again returns the same connection, so a socket can never
/// be duplicated.
///
/// Centralises what every socket needs: reconnect on app resume (iOS/Android
/// drop sockets while backgrounded) and orderly shutdown.
class WebSocketManager extends GetxService with WidgetsBindingObserver {
  final Map<String, WsConnection> _connections = {};

  Iterable<WsConnection> get connections => _connections.values;

  WsConnection open({
    required String name,
    required String Function() url,
    required void Function(dynamic message) onMessage,
    WsOnOpen? onOpen,
    void Function()? onClosed,
    Object? Function()? heartbeat,
    Duration heartbeatInterval = const Duration(seconds: 20),
    Future<bool> Function()? connectGate,
  }) {
    return _connections.putIfAbsent(
      name,
      () => WsConnection(
        name: name,
        url: url,
        onMessage: onMessage,
        onOpen: onOpen,
        onClosed: onClosed,
        heartbeat: heartbeat,
        heartbeatInterval: heartbeatInterval,
        connectGate: connectGate,
      ),
    );
  }

  /// Closes and forgets [name] (e.g. a feature-scoped socket being disposed).
  Future<void> release(String name) async {
    await _connections.remove(name)?.close();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    for (final connection in _connections.values) {
      connection.resumeIfDropped();
    }
  }

  @override
  Future<void> onClose() async {
    WidgetsBinding.instance.removeObserver(this);
    await Future.wait(_connections.values.map((c) => c.close()));
    _connections.clear();
    super.onClose();
  }
}
