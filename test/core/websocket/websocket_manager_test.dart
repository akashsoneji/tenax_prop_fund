import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tenax_prop_flutter/core/network/pinned_http_client.dart';
import 'package:tenax_prop_flutter/core/websocket/websocket_manager.dart';

/// Real local WebSocket server so the transport is exercised end-to-end
/// (handshake, frames, server close) without mocks.
class _Server {
  late final HttpServer _http;
  final sockets = <WebSocket>[];
  final received = <String>[];
  int connections = 0;

  String get url => 'ws://127.0.0.1:${_http.port}';

  Future<void> start() async {
    _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _http.transform(WebSocketTransformer()).listen((ws) {
      connections++;
      sockets.add(ws);
      ws.listen((data) => received.add(data as String));
    });
  }

  Future<void> dropAll() async {
    for (final ws in sockets) {
      await ws.close();
    }
    sockets.clear();
  }

  Future<void> stop() => _http.close(force: true);
}

Future<void> _until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('condition not met in time');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late _Server server;
  late WebSocketManager manager;

  // main() loads the pinned roots before any socket opens; do the same here.
  setUpAll(() => PinnedHttpClient.initWithPem(
        File(PinnedHttpClient.rootsAsset).readAsBytesSync(),
      ));

  setUp(() async {
    server = _Server();
    await server.start();
    manager = WebSocketManager();
  });

  tearDown(() async {
    await Future.wait(manager.connections.map((c) => c.close()));
    await server.stop();
  });

  test('open() returns one shared connection per name', () {
    final a = manager.open(name: 'feed', url: () => server.url, onMessage: (_) {});
    final b = manager.open(name: 'feed', url: () => server.url, onMessage: (_) {});
    expect(identical(a, b), isTrue);
    expect(manager.connections, hasLength(1));
  });

  test('sends the auth frame on open and delivers server frames', () async {
    final frames = <dynamic>[];
    final socket = manager.open(
      name: 'feed',
      url: () => server.url,
      onMessage: frames.add,
      onOpen: (c) async {
        c.send({'authID': 't', 'trading_account': '0'});
        return true;
      },
    );

    await socket.connect();
    await _until(() => server.received.isNotEmpty);
    expect(jsonDecode(server.received.single), {'authID': 't', 'trading_account': '0'});
    expect(socket.isConnected.value, isTrue);

    server.sockets.single.add('tick');
    await _until(() => frames.isNotEmpty);
    expect(frames.single, 'tick');
  });

  test('concurrent connect() calls open exactly one socket', () async {
    final socket = manager.open(name: 'feed', url: () => server.url, onMessage: (_) {});
    await Future.wait([socket.connect(), socket.connect(), socket.connect()]);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(server.connections, 1);
  });

  test('connectGate=false skips connecting (no token)', () async {
    final socket = manager.open(
      name: 'feed',
      url: () => server.url,
      onMessage: (_) {},
      connectGate: () async => false,
    );
    await socket.connect();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(server.connections, 0);
    expect(socket.isConnected.value, isFalse);
  });

  test('reconnects after the server drops the socket', () async {
    var closedCalls = 0;
    final socket = manager.open(
      name: 'feed',
      url: () => server.url,
      onMessage: (_) {},
      onClosed: () => closedCalls++,
    );
    await socket.connect();
    await _until(() => server.connections == 1);

    await server.dropAll();
    await _until(() => !socket.isConnected.value);
    expect(closedCalls, 1);
    // First backoff step is 2s + up to 1s jitter.
    await _until(() => server.connections == 2);
    await _until(() => socket.isConnected.value);
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('close() stops reconnecting; restart() opens a fresh socket', () async {
    final socket = manager.open(name: 'feed', url: () => server.url, onMessage: (_) {});
    await socket.connect();
    await _until(() => server.connections == 1);

    socket.restart();
    await _until(() => server.connections == 2);

    await socket.close();
    expect(socket.isConnected.value, isFalse);
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(server.connections, 2);
  }, timeout: const Timeout(Duration(seconds: 10)));
}
