import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/flavor/flavor_config.dart';
import 'api_endpoints.dart';
import 'api_interceptor.dart';
import 'pinned_http_client.dart';

/// Thin Dio wrapper. The only place that owns an HTTP client. Controllers must
/// never instantiate Dio — they go through repositories, which use this.
class ApiClient {
  ApiClient(FlavorConfig config, FlutterSecureStorage storage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            contentType: 'application/json',
          ),
        ),
        _web = Dio(
          BaseOptions(
            baseUrl: config.webBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ),
        webBaseUrl = config.webBaseUrl {
    final interceptor = ApiInterceptor(storage);
    for (final client in [_dio, _web]) {
      client.httpClientAdapter =
          IOHttpClientAdapter(createHttpClient: PinnedHttpClient.create);
      client.interceptors.add(interceptor);
    }
  }

  final Dio _dio;

  /// Dedicated client for the Inertia portal host (root domain, no `/api/v1`).
  /// Kept separate so [getInertiaProps] can use RELATIVE paths without the REST
  /// `baseUrl` being prepended to an absolute URL.
  final Dio _web;

  /// Root web host (no `/api/v1`) for Inertia portal endpoints — see
  /// [getInertiaProps].
  final String webBaseUrl;

  /// The Inertia asset version last seen from the server. Sent as
  /// `X-Inertia-Version` so the portal returns JSON instead of a 409 reload.
  /// Starts empty; bootstrapped from the HTML page on the first version
  /// mismatch, then reused for every subsequent call.
  String _inertiaVersion = '';

  Dio get raw => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) =>
      _dio.get<T>(
        path,
        queryParameters: query,
        options: headers == null ? null : Options(headers: headers),
      );

  /// GETs an absolute [url] as an Inertia XHR and returns the decoded `props`
  /// map. The portal's web routes (e.g. `/app/accounts`) reply with the full
  /// HTML document for a normal browser request, but with a JSON page object
  /// `{component, props, url, version}` when the `X-Inertia` header is present.
  /// The bearer token is still attached by [ApiInterceptor]. Used where a
  /// dedicated mobile REST endpoint does not exist yet.
  Future<Map<String, dynamic>> getInertiaProps(String url) async {
    // Callers may pass an absolute URL (built from webBaseUrl) or a relative
    // `/app/...` path. Strip the web host so the request goes through the web
    // Dio's baseUrl exactly once (never glued onto the REST `/api/v1` base).
    final path = url.startsWith(webBaseUrl) ? url.substring(webBaseUrl.length) : url;

    final res = await _web.get<dynamic>(
      path,
      options: Options(
        headers: {
          'X-Inertia': 'true',
          'X-Requested-With': 'XMLHttpRequest',
          'X-Inertia-Version': _inertiaVersion,
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
        // 409 is Inertia's asset-version mismatch, not a real error — handle it
        // ourselves instead of letting Dio throw.
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    // Asset-version mismatch: the server wants us to reload with the current
    // version. Bootstrap it from the full HTML page (which embeds the page
    // object in `data-page`), cache the version, and use those props directly.
    if (res.statusCode == 409) {
      return _bootstrapFromHtml(path);
    }

    final props = _propsFrom(res.data);
    if (props != null) return props;

    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
      error: 'Unexpected Inertia response',
    );
  }

  /// Fetches the full HTML document for [path] (a normal browser GET, no
  /// `X-Inertia` header), extracts the Inertia page object embedded in the
  /// root element's `data-page` attribute, caches its `version` for subsequent
  /// XHR calls, and returns its `props`.
  Future<Map<String, dynamic>> _bootstrapFromHtml(String path) async {
    final res = await _web.get<dynamic>(
      path,
      options: Options(
        headers: {'Accept': 'text/html'},
        responseType: ResponseType.plain,
      ),
    );
    final html = res.data?.toString() ?? '';
    final page = _pageFromHtml(html);
    if (page == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: 'Could not read Inertia page from HTML',
      );
    }
    final version = page['version'];
    if (version is String) _inertiaVersion = version;
    final props = page['props'];
    if (props is Map<String, dynamic>) return props;
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
      error: 'Inertia page has no props',
    );
  }

  /// Extracts and decodes the `data-page="{...}"` JSON blob from an Inertia
  /// HTML document.
  Map<String, dynamic>? _pageFromHtml(String html) {
    final match = RegExp('data-page="([^"]*)"').firstMatch(html);
    if (match == null) return null;
    // The attribute value is HTML-entity encoded (Blade `e()` output).
    final decoded = match
        .group(1)!
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    final page = jsonDecode(decoded);
    return page is Map<String, dynamic> ? page : null;
  }

  /// Pulls `props` out of an Inertia JSON page object, capturing its `version`
  /// along the way so later calls send a matching `X-Inertia-Version`.
  Map<String, dynamic>? _propsFrom(dynamic body) {
    if (body is String && body.isNotEmpty) {
      final decoded = jsonDecode(body);
      return _propsFrom(decoded);
    }
    if (body is Map<String, dynamic>) {
      final version = body['version'];
      if (version is String) _inertiaVersion = version;
      final props = body['props'];
      if (props is Map<String, dynamic>) return props;
    }
    return null;
  }


  /// Resolves a private/presence Pusher channel auth signature.
  ///
  /// POSTs `socket_id` + `channel_name` (form-encoded) to `/broadcasting/auth`
  /// on the WEB host (NOT `/api/v1`). The bearer token is attached by
  /// [ApiInterceptor], which also logs the request/response in debug builds.
  /// Returns the `auth` string the client must echo back in `pusher:subscribe`,
  /// or `null` if the server did not authorise the channel.
  Future<String?> broadcastingAuth(String socketId, String channel) async {
    final res = await _web.post<dynamic>(
      ApiEndpoints.broadcastingAuth,
      data: {'socket_id': socketId, 'channel_name': channel},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Accept': 'application/json'},
      ),
    );
    final body = res.data is String
        ? jsonDecode(res.data as String)
        : res.data;
    if (body is Map && body['auth'] != null) return body['auth'].toString();
    return null;
  }

  /// [headers] overrides what the interceptor would add — used by the
  /// two-factor login step, which must authenticate with the challenge token
  /// instead of the (not yet existing) session token.
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, String>? headers,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        options: headers == null ? null : Options(headers: headers),
      );

  /// POST to the WEB host (root domain, no `/api/v1`). Used for the trade
  /// endpoints which live under `/api/user/trade/...`, not the mobile REST base.
  Future<Response<T>> postWeb<T>(String path, {Object? data}) => _web.post<T>(
        path,
        data: data,
        options: Options(headers: {'Accept': 'application/json'}),
      );

  /// GET from the WEB host (root domain, no `/api/v1`) — trade history etc.
  Future<Response<T>> getWeb<T>(String path, {Map<String, dynamic>? query}) =>
      _web.get<T>(
        path,
        queryParameters: query,
        options: Options(headers: {'Accept': 'application/json'}),
      );

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _dio.delete<T>(path, data: data);
}
