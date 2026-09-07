import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logger/app_logger.dart';

/// Attaches the auth token (from secure storage) to every outgoing request.
/// Token is never stored in Dart source or plain prefs.
///
/// The token is cached in memory after the first read so we do NOT hit the
/// iOS Keychain / Android Keystore (a platform-channel round trip) on every
/// single request. Call [ApiInterceptor.updateCachedToken] on login/logout to
/// keep the cache in sync with secure storage.
///
/// In debug builds it also prints every request/response/error (full URL,
/// bearer token, body, status) to the console so network issues are visible in
/// the debug panel. This logging is compiled out in release/profile via
/// [kDebugMode].
class ApiInterceptor extends Interceptor {
  ApiInterceptor(this._storage);

  final FlutterSecureStorage _storage;
  static const tokenKey = 'auth_token';

  /// In-memory copy of the token. `null` means "not yet loaded from storage".
  static String? _cachedToken;
  static bool _loaded = false;

  /// Keep the in-memory cache in sync when the token changes (login writes the
  /// new token, logout passes `null`). Callers still persist to secure storage.
  static void updateCachedToken(String? token) {
    _cachedToken = token;
    _loaded = true;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_loaded) {
      _cachedToken = await _storage.read(key: tokenKey);
      _loaded = true;
    }
    final token = _cachedToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (kDebugMode) {
      final url = '${options.baseUrl}${options.path}';
      log.i(
        '➡️ ${options.method} $url\n'
        'Token: ${token == null || token.isEmpty ? '(none)' : token}\n'
        'Query: ${options.queryParameters}\n'
        'Body: ${_pretty(options.data)}',
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final url =
          '${response.requestOptions.baseUrl}${response.requestOptions.path}';
      log.i(
        '✅ ${response.statusCode} ${response.requestOptions.method} $url\n'
        'Response: ${_pretty(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final url =
          '${err.requestOptions.baseUrl}${err.requestOptions.path}';
      log.e(
        '⛔ ${err.response?.statusCode ?? '-'} '
        '${err.requestOptions.method} $url\n'
        'Type: ${err.type}\n'
        'Message: ${err.message}\n'
        'Response: ${_pretty(err.response?.data)}',
      );
    }
    handler.next(err);
  }

  static String _pretty(dynamic data) {
    if (data == null) return '(empty)';
    try {
      if (data is String) return data;
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
