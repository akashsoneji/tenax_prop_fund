import 'package:flutter/material.dart';

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

  /// Builds the config purely from compile-time defines supplied by
  /// `--dart-define-from-file=config/flavors/<flavor>.json`.
  ///
  /// No client's host, name, colors or asset paths live in Dart source: only
  /// the JSON file passed at build time is compiled in, so decompiling one
  /// client's app never reveals another client's data.
  factory FlavorConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const webBaseUrl = String.fromEnvironment('WEB_BASE_URL');
    const wsUrl = String.fromEnvironment('WS_URL');
    const chartBaseUrl = String.fromEnvironment('CHART_BASE_URL');
    const pusherHost = String.fromEnvironment('PUSHER_HOST');
    const pusherAppKey = String.fromEnvironment('PUSHER_APP_KEY');
    const appName = String.fromEnvironment('APP_NAME');
    const primaryHex = String.fromEnvironment('PRIMARY_COLOR');
    const darkPrimaryHex = String.fromEnvironment('DARK_PRIMARY_COLOR');
    const secondaryHex = String.fromEnvironment('SECONDARY_COLOR');
    const logoAsset = String.fromEnvironment('LOGO_ASSET');
    const splashLogoAsset = String.fromEnvironment('SPLASH_LOGO_ASSET');
    const featureFlags = String.fromEnvironment('FEATURE_FLAGS');

    const required = {
      'API_BASE_URL': apiBaseUrl,
      'WEB_BASE_URL': webBaseUrl,
      'WS_URL': wsUrl,
      'CHART_BASE_URL': chartBaseUrl,
      'PUSHER_HOST': pusherHost,
      'PUSHER_APP_KEY': pusherAppKey,
      'APP_NAME': appName,
      'PRIMARY_COLOR': primaryHex,
      'SECONDARY_COLOR': secondaryHex,
    };
    final missing = [
      for (final entry in required.entries)
        if (entry.value.isEmpty) entry.key,
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing flavor defines: ${missing.join(', ')}. Build with '
        '--dart-define-from-file=config/flavors/<flavor>.json',
      );
    }

    return FlavorConfig(
      flavor: Flavor.fromName(
        const String.fromEnvironment('FLAVOR', defaultValue: 'tenax'),
      ),
      env: appEnvFromName(
        const String.fromEnvironment('ENV', defaultValue: 'development'),
      ),
      appName: appName,
      apiBaseUrl: apiBaseUrl,
      webBaseUrl: webBaseUrl,
      wsUrl: wsUrl,
      pusherHost: pusherHost,
      pusherAppKey: pusherAppKey,
      chartBaseUrl: chartBaseUrl,
      primaryColor: _parseColor(primaryHex),
      darkPrimaryColor:
          darkPrimaryHex.isEmpty ? null : _parseColor(darkPrimaryHex),
      secondaryColor: _parseColor(secondaryHex),
      logoAsset: logoAsset,
      splashLogoAsset: splashLogoAsset,
      featureFlags: {
        for (final flag in featureFlags.split(','))
          if (flag.trim().isNotEmpty) flag.trim(),
      },
    );
  }

  /// Parses `AARRGGBB` / `RRGGBB` hex (optional leading `#`).
  static Color _parseColor(String hex) {
    final digits = hex.replaceFirst('#', '');
    final argb = digits.length == 6 ? 'FF$digits' : digits;
    return Color(int.parse(argb, radix: 16));
  }
}
