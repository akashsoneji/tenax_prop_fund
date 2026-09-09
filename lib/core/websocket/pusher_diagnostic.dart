import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../app/flavor/flavor_config.dart';
import '../logger/app_logger.dart';
import '../network/api_interceptor.dart';

/// Standalone, throwaway diagnostic that walks the ENTIRE Reverb/Pusher private
/// channel handshake exactly as the backend described it and dumps every
/// request and response to the debug console, so you can confirm each step
/// works end to end before trusting [PusherClient].
///
/// Steps performed (each logged):
///   1. connect      -> `wss://{host}/app/{key}?protocol=7&client=js&version=8.6.0`
///   2. established   -> read `socket_id` from `pusher:connection_established`
///   3. auth          -> POST `/broadcasting/auth` (web host) with Bearer token,
///                       body `socket_id=…&channel_name=…`, read back `auth`
///   4. subscribe     -> send `pusher:subscribe` with the `auth` signature
///   5. events        -> log `subscription_succeeded` + every `AccountStateUpdated`
///
/// Usage (e.g. from a debug button or `main` after login):
/// ```dart
/// final diag = PusherDiagnostic(
///   config: Get.find<FlavorConfig>(),
///   storage: Get.find<FlutterSecureStorage>(),
/// );
/// await diag.run(accountId: 14, userId: 14);
/// // ...later
/// await diag.dispose();
/// ```
class PusherDiagnostic {
  PusherDiagnostic({
    required FlavorConfig config,
    required this._storage,
  })  : _config = config,
        _auth = Dio(
          BaseOptions(
            baseUrl: config.webBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

  final FlavorConfig _config;
  final FlutterSecureStorage _storage;
  final Dio _auth;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _heartbeat;
  String? _socketId;
  final _established = Completer<void>();

  /// Broadcasting-auth path lives on the WEB host (`webBaseUrl`) under `/api`
  /// (sanctum-guarded). The bare `/broadcasting/auth` route is web-session only
  /// and returns 403 for a bearer token.
  static const _broadcastingAuthPath = '/api/broadcasting/auth';

  /// Runs the full handshake for the given [accountId]. If [userId] is also
  /// passed, it additionally subscribes to the per-user "all accounts" channel
  /// so you can see both channel shapes side by side.
  Future<void> run({required int accountId, int? userId}) async {
    _banner('STEP 1 — CONNECT');
    final url = _config.pusherWsUrl;
    log.i('➡️  WS connect: $url');

    _channel = WebSocketChannel.connect(Uri.parse(url));
    await _channel!.ready;
    _sub = _channel!.stream.listen(
      _onFrame,
      onError: (Object e) => log.e('⛔ WS error: $e'),
      onDone: () => log.w('🔌 WS closed (code=${_channel?.closeCode})'),
    );
    log.i('✅ Socket opened, waiting for pusher:connection_established…');

    // Wait for step 2 (socket_id) before we can auth + subscribe.
    await _established.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => log.e('⛔ Timed out waiting for connection_established'),
    );
    if (_socketId == null) return;

    await _subscribePrivate('private-account.$accountId');
    if (userId != null) {
      await _subscribePrivate('private-trader.$userId.accounts');
    }
  }

  // ── Step 2: connection_established / ping ────────────────────────────────
  void _onFrame(dynamic raw) {
    if (raw is! String) return;
    log.i('⬅️  WS frame RAW: $raw');

    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      log.w('Frame not JSON: $e');
      return;
    }

    final event = frame['event'] as String?;
    final data = _decode(frame['data']);

    switch (event) {
      case 'pusher:connection_established':
        _socketId = data?['socket_id']?.toString();
        _banner('STEP 2 — ESTABLISHED');
        log.i('✅ socket_id = $_socketId');
        _startHeartbeat();
        if (!_established.isCompleted) _established.complete();
        return;
      case 'pusher_internal:subscription_succeeded':
        _banner('STEP 5 — SUBSCRIPTION SUCCEEDED');
        log.i('✅ channel = ${frame['channel']}  data = $data');
        return;
      case 'AccountStateUpdated':
        _banner('EVENT — AccountStateUpdated');
        log.i('📈 channel = ${frame['channel']}');
        log.i('📈 payload = ${_pretty(data)}');
        return;
      case 'pusher:error':
        log.e('⛔ pusher:error = ${_pretty(data)}');
        return;
      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': const {}});
        return;
      default:
        log.d('ℹ️  Unhandled event: $event');
        return;
    }
  }

  // ── Step 3 + 4: auth signature, then subscribe ───────────────────────────
  Future<void> _subscribePrivate(String channel) async {
    final auth = await _fetchAuth(channel);
    if (auth == null) {
      log.e('⛔ No auth signature for $channel — cannot subscribe');
      return;
    }
    _banner('STEP 4 — SUBSCRIBE');
    final payload = {
      'event': 'pusher:subscribe',
      'data': {'channel': channel, 'auth': auth},
    };
    log.i('➡️  ${jsonEncode(payload)}');
    _send(payload);
  }

  Future<String?> _fetchAuth(String channel) async {
    _banner('STEP 3 — BROADCASTING AUTH');
    final token = await _storage.read(key: ApiInterceptor.tokenKey);
    final body = {'socket_id': _socketId, 'channel_name': channel};

    log.i('➡️  POST ${_config.webBaseUrl}$_broadcastingAuthPath');
    log.i('    Authorization: Bearer ${_mask(token)}');
    log.i('    Body: socket_id=$_socketId&channel_name=$channel');

    try {
      final res = await _auth.post<dynamic>(
        _broadcastingAuthPath,
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      log.i('✅ ${res.statusCode} auth response: ${_pretty(res.data)}');
      final decoded = res.data is String
          ? jsonDecode(res.data as String) as Map<String, dynamic>
          : (res.data as Map).cast<String, dynamic>();
      return decoded['auth']?.toString();
    } on DioException catch (e) {
      log.e('⛔ ${e.response?.statusCode} auth failed: '
          '${_pretty(e.response?.data)}');
      return null;
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      _send({'event': 'pusher:ping', 'data': const {}});
    });
  }

  void _send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  /// Pusher's `data` field is a double-encoded JSON string; tolerate a raw Map.
  Map<String, dynamic>? _decode(dynamic data) {
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

  String _mask(String? token) {
    if (token == null || token.isEmpty) return '(none)';
    return token.length <= 12 ? token : '${token.substring(0, 12)}…';
  }

  String _pretty(dynamic data) {
    if (data == null) return '(empty)';
    try {
      if (data is String) return data;
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  void _banner(String title) {
    if (kDebugMode) log.i('──────── $title ────────');
  }

  Future<void> dispose() async {
    _heartbeat?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }
}
