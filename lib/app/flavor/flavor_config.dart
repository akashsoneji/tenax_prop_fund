import 'dart:convert';

import 'package:flutter/material.dart';

import 'config_cipher.dart';
import 'flavor.dart';

/// Single source of truth for everything that varies per white-label client:
/// branding, endpoints, feature flags. Business logic never reads this for
/// branching — only presentation and networking do.
class FlavorConfig {
  final Flavor flavor;
  final AppEnv env;
  final String appName;
  final String apiBaseUrl;

  /// Root web host (e.g. `https://pipzefunded.com`) used for the Inertia
  /// portal endpoints the mobile app reuses (e.g. `GET /app/accounts`). Distinct
  /// from [apiBaseUrl], which carries the `/api/v1` suffix.
  final String webBaseUrl;

  final String wsUrl;

  /// Pusher/Soketi realtime endpoint used by the Home dashboard live equity
  /// feed. Built from a root host + app key (see [pusherWsUrl]); distinct from
  /// [wsUrl] (the generic trade-engine socket).
  final String pusherHost;
  final String pusherAppKey;

  /// Base URL of the embeddable web chart (opened in a WebView). The concrete
  /// per-symbol URL is built with [chartUrl].
  final String chartBaseUrl;
  final Color primaryColor;

  /// Brand color used as `primary` in dark mode. Null means [primaryColor] is
  /// used in both themes; set it when the light brand color would disappear on
  /// a dark surface (e.g. a navy brand).
  final Color? darkPrimaryColor;
  final Color secondaryColor;
  final String logoAsset;
  final String splashLogoAsset;
  final Set<String> featureFlags;

  /// Base64 SHA-256 of the certificates allowed to sign this flavor (Play App
  /// Signing key + upload key). Empty means tamper detection is not enforced.
  final List<String> signingCertHashes;

  /// Apple team that signs the iOS app; needed by the runtime protection.
  final String iosTeamId;

  /// Address that receives the runtime-protection security reports.
  final String securityWatcherMail;

  const FlavorConfig({
    required this.flavor,
    required this.env,
    required this.appName,
    required this.apiBaseUrl,
    required this.webBaseUrl,
    required this.wsUrl,
    required this.pusherHost,
    required this.pusherAppKey,
    required this.chartBaseUrl,
    required this.primaryColor,
    this.darkPrimaryColor,
    required this.secondaryColor,
    required this.logoAsset,
    required this.splashLogoAsset,
    required this.featureFlags,
    this.signingCertHashes = const [],
    this.iosTeamId = '',
    this.securityWatcherMail = '',
  });

  bool has(String feature) => featureFlags.contains(feature);

  String get assetRoot =>
      'assets/flavors/${const String.fromEnvironment('FLAVOR', defaultValue: 'tenax')}';

  /// Builds the embedded-chart URL for [symbol]. [dark] picks the chart theme so
  /// it matches the app's current brightness. The remote chart page self-feeds
  /// (own candle history + pricing socket), so only symbol + theme are passed.
  String chartUrl(String symbol, {bool dark = true}) {
    final query = Uri(queryParameters: {
      'symbol': symbol,
      'theme': dark ? 'dark' : 'light',
    }).query;
    return '$chartBaseUrl?$query';
  }

  /// Builds the Pusher realtime WebSocket URL for the Home dashboard live feed:
  /// `wss://{pusherHost}/app/{pusherAppKey}?protocol=7&client=js&version=8.6.0&flash=false`.
  String get pusherWsUrl =>
      'wss://$pusherHost/app/$pusherAppKey?protocol=7&client=js&version=8.6.0&flash=false';

  /// Per-symbol market-watch feed: `{wsUrl}/marketwatchv2` (binary MessagePack
  /// ticks). For tenax this resolves to
  /// `wss://pipzefunded.com/trade-engine/ws/marketwatchv2`.
  String get marketWatchV2Url {
    final base = wsUrl.endsWith('/') ? wsUrl.substring(0, wsUrl.length - 1) : wsUrl;
    return '$base/marketwatchv2';
  }

  String get _wsBase =>
      wsUrl.endsWith('/') ? wsUrl.substring(0, wsUrl.length - 1) : wsUrl;

  /// Open-positions socket: `{wsUrl}/op` (mirrors white_label's `/ws/op`).
  /// For tenax: `wss://pipzefunded.com/trade-engine/ws/op`.
  String get openPositionsUrl => '$_wsBase/op';

  /// Pending-orders socket: `{wsUrl}/po` (white_label `/ws/po`).
  String get pendingOrdersUrl => '$_wsBase/po';

  /// Account equity/margin socket: `{wsUrl}/account` (white_label `/ws/account`).
  String get accountWsUrl => '$_wsBase/account';

  /// Builds the config from compile-time defines.
  ///
  /// Release builds (`build.sh`) pass only `CFG_BLOB` + `CFG_KEY` from
  /// `tool/encode_flavor_config.dart`, so the client's URLs and keys are not
  /// readable strings in the binary. Debug runs from `launch.json` pass the
  /// plain `config/flavors/<flavor>.json` keys instead.
  ///
  /// No client's host, name, colors or asset paths live in Dart source: only
  /// the JSON file passed at build time is compiled in, so decompiling one
  /// client's app never reveals another client's data.
  factory FlavorConfig.fromEnvironment() {
    const blob = String.fromEnvironment('CFG_BLOB');
    const key = String.fromEnvironment('CFG_KEY');
    final values = blob.isEmpty ? _plainDefines : _decodeDefines(blob, key);
    return FlavorConfig.fromValues(
      values,
      flavorName: const String.fromEnvironment('FLAVOR', defaultValue: 'tenax'),
      envName: const String.fromEnvironment('ENV', defaultValue: 'development'),
    );
  }

  factory FlavorConfig.fromValues(
    Map<String, String> values, {
    required String flavorName,
    required String envName,
  }) {
    String read(String name) => values[name]?.trim() ?? '';

    const required = [
      'API_BASE_URL',
      'WEB_BASE_URL',
      'WS_URL',
      'CHART_BASE_URL',
      'PUSHER_HOST',
      'PUSHER_APP_KEY',
      'APP_NAME',
      'PRIMARY_COLOR',
      'SECONDARY_COLOR',
    ];
    final missing = [
      for (final name in required)
        if (read(name).isEmpty) name,
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing flavor defines: ${missing.join(', ')}. Build with '
        '--dart-define-from-file=config/flavors/<flavor>.json',
      );
    }

    List<String> csv(String name) => [
          for (final part in read(name).split(','))
            if (part.trim().isNotEmpty) part.trim(),
        ];
    final darkPrimaryHex = read('DARK_PRIMARY_COLOR');

    return FlavorConfig(
      flavor: Flavor.fromName(flavorName),
      env: appEnvFromName(envName),
      appName: read('APP_NAME'),
      apiBaseUrl: read('API_BASE_URL'),
      webBaseUrl: read('WEB_BASE_URL'),
      wsUrl: read('WS_URL'),
      pusherHost: read('PUSHER_HOST'),
      pusherAppKey: read('PUSHER_APP_KEY'),
      chartBaseUrl: read('CHART_BASE_URL'),
      primaryColor: _parseColor(read('PRIMARY_COLOR')),
      darkPrimaryColor:
          darkPrimaryHex.isEmpty ? null : _parseColor(darkPrimaryHex),
      secondaryColor: _parseColor(read('SECONDARY_COLOR')),
      logoAsset: read('LOGO_ASSET'),
      splashLogoAsset: read('SPLASH_LOGO_ASSET'),
      featureFlags: csv('FEATURE_FLAGS').toSet(),
      signingCertHashes: csv('SIGNING_CERT_HASHES'),
      iosTeamId: read('IOS_TEAM_ID'),
      securityWatcherMail: read('SECURITY_WATCHER_MAIL'),
    );
  }

  static const _plainDefines = <String, String>{
    'API_BASE_URL': String.fromEnvironment('API_BASE_URL'),
    'WEB_BASE_URL': String.fromEnvironment('WEB_BASE_URL'),
    'WS_URL': String.fromEnvironment('WS_URL'),
    'CHART_BASE_URL': String.fromEnvironment('CHART_BASE_URL'),
    'PUSHER_HOST': String.fromEnvironment('PUSHER_HOST'),
    'PUSHER_APP_KEY': String.fromEnvironment('PUSHER_APP_KEY'),
    'APP_NAME': String.fromEnvironment('APP_NAME'),
    'PRIMARY_COLOR': String.fromEnvironment('PRIMARY_COLOR'),
    'DARK_PRIMARY_COLOR': String.fromEnvironment('DARK_PRIMARY_COLOR'),
    'SECONDARY_COLOR': String.fromEnvironment('SECONDARY_COLOR'),
    'LOGO_ASSET': String.fromEnvironment('LOGO_ASSET'),
    'SPLASH_LOGO_ASSET': String.fromEnvironment('SPLASH_LOGO_ASSET'),
    'FEATURE_FLAGS': String.fromEnvironment('FEATURE_FLAGS'),
    'SIGNING_CERT_HASHES': String.fromEnvironment('SIGNING_CERT_HASHES'),
    'IOS_TEAM_ID': String.fromEnvironment('IOS_TEAM_ID'),
    'SECURITY_WATCHER_MAIL': String.fromEnvironment('SECURITY_WATCHER_MAIL'),
  };

  static Map<String, String> _decodeDefines(String blob, String key) {
    final decoded =
        jsonDecode(ConfigCipher.decode(blob, key)) as Map<String, dynamic>;
    return decoded.map((name, value) => MapEntry(name, '$value'));
  }

  /// Parses `AARRGGBB` / `RRGGBB` hex (optional leading `#`).
  static Color _parseColor(String hex) {
    final digits = hex.replaceFirst('#', '');
    final argb = digits.length == 6 ? 'FF$digits' : digits;
    return Color(int.parse(argb, radix: 16));
  }
}
