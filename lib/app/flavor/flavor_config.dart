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
    required this.secondaryColor,
    required this.logoAsset,
    required this.splashLogoAsset,
    required this.featureFlags,
  });

  bool has(String feature) => featureFlags.contains(feature);

  String get assetRoot => 'assets/flavors/${flavor.name}';

  /// Builds the embedded-chart URL for [symbol]. [dark] picks the chart theme so
  /// it matches the app's current brightness.
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

  /// Builds the config from compile-time [String.fromEnvironment] values
  /// injected via `--dart-define` (see `.vscode/launch.json`). Each flavor has
  /// its own default host so every URL (REST, WebSocket, chart) changes with the
  /// flavor; a non-empty `--dart-define` still overrides the flavor default so
  /// staging/QA builds can point anywhere.
  factory FlavorConfig.fromEnvironment({
    required String flavorName,
    required String envName,
    String apiBaseUrl = '',
    String wsUrl = '',
    String chartBaseUrl = '',
  }) {
    final flavor = Flavor.fromName(flavorName);
    final env = appEnvFromName(envName);
    final endpoints = _FlavorEndpoints.of(flavor);

    // Env override wins when provided; otherwise fall back to the flavor host.
    String pick(String override, String fallback) =>
        override.isNotEmpty ? override : fallback;

    switch (flavor) {
      case Flavor.tenax:
        return FlavorConfig(
          flavor: flavor,
          env: env,
          appName: 'Tenax Prop',
          apiBaseUrl: pick(apiBaseUrl, endpoints.api),
          webBaseUrl: endpoints.web,
          wsUrl: pick(wsUrl, endpoints.ws),
          pusherHost: endpoints.pusherHost,
          pusherAppKey: endpoints.pusherAppKey,
          chartBaseUrl: pick(chartBaseUrl, endpoints.chart),
          primaryColor: const Color(0xFF5F259E),
          secondaryColor: const Color(0xFFFDCC29),
          logoAsset: 'assets/flavors/tenax/logo.png',
          splashLogoAsset: 'assets/flavors/tenax/splash.png',
          featureFlags: const {'trading', 'challenges', 'payouts', 'reports'},
        );
      case Flavor.clientA:
        return FlavorConfig(
          flavor: flavor,
          env: env,
          appName: 'Client A',
          apiBaseUrl: pick(apiBaseUrl, endpoints.api),
          webBaseUrl: endpoints.web,
          wsUrl: pick(wsUrl, endpoints.ws),
          pusherHost: endpoints.pusherHost,
          pusherAppKey: endpoints.pusherAppKey,
          chartBaseUrl: pick(chartBaseUrl, endpoints.chart),
          primaryColor: const Color(0xFF1E88E5),
          secondaryColor: const Color(0xFFFFC107),
          logoAsset: 'assets/flavors/clientA/logo.png',
          splashLogoAsset: 'assets/flavors/clientA/splash.png',
          featureFlags: const {'trading', 'challenges', 'payouts'},
        );
      case Flavor.clientB:
        return FlavorConfig(
          flavor: flavor,
          env: env,
          appName: 'Client B',
          apiBaseUrl: pick(apiBaseUrl, endpoints.api),
          webBaseUrl: endpoints.web,
          wsUrl: pick(wsUrl, endpoints.ws),
          pusherHost: endpoints.pusherHost,
          pusherAppKey: endpoints.pusherAppKey,
          chartBaseUrl: pick(chartBaseUrl, endpoints.chart),
          primaryColor: const Color(0xFF2E7D32),
          secondaryColor: const Color(0xFF00E676),
          logoAsset: 'assets/flavors/clientB/logo.png',
          splashLogoAsset: 'assets/flavors/clientB/splash.png',
          featureFlags: const {'trading', 'reports'},
        );
      case Flavor.clientC:
        return FlavorConfig(
          flavor: flavor,
          env: env,
          appName: 'Client C',
          apiBaseUrl: pick(apiBaseUrl, endpoints.api),
          webBaseUrl: endpoints.web,
          wsUrl: pick(wsUrl, endpoints.ws),
          pusherHost: endpoints.pusherHost,
          pusherAppKey: endpoints.pusherAppKey,
          chartBaseUrl: pick(chartBaseUrl, endpoints.chart),
          primaryColor: const Color(0xFF6A1B9A),
          secondaryColor: const Color(0xFFD500F9),
          logoAsset: 'assets/flavors/clientC/logo.png',
          splashLogoAsset: 'assets/flavors/clientC/splash.png',
          featureFlags: const {'trading', 'admin', 'reports'},
        );
    }
  }
}

/// Per-flavor default endpoints, all derived from a single host so REST, the
/// WebSocket engine and the web chart always move together. Override any one at
/// build time with `--dart-define`.
class _FlavorEndpoints {
  const _FlavorEndpoints({
    required this.api,
    required this.web,
    required this.ws,
    required this.chart,
    required this.pusherHost,
    required this.pusherAppKey,
  });

  final String api;
  final String web;
  final String ws;
  final String chart;

  /// Root host of the Pusher realtime engine (e.g. `pipzefunded.com`) — the
  /// APEX host, not the `my.` app host used for REST.
  final String pusherHost;
  final String pusherAppKey;

  /// [host] is the REST/app host; [pusherHost] defaults to it (drop a leading
  /// `my.`) so the realtime engine is reachable at the apex domain.
  factory _FlavorEndpoints.forHost(
    String host, {
    required String pusherAppKey,
    String? pusherHost,
  }) =>
      _FlavorEndpoints(
        api: 'https://$host/api/v1',
        web: 'https://$host',
        ws: 'wss://$host/trade-engine/ws',
        chart: 'https://$host/mobile-chart',
        pusherHost: pusherHost ??
            (host.startsWith('my.') ? host.substring(3) : host),
        pusherAppKey: pusherAppKey,
      );

  static _FlavorEndpoints of(Flavor flavor) {
    switch (flavor) {
      case Flavor.tenax:
        return _FlavorEndpoints.forHost('pipzefunded.com',
            pusherAppKey: 'f31641a17af7835503b4f1e9');
      case Flavor.clientA:
        return _FlavorEndpoints.forHost('my.client-a.com',
            pusherAppKey: 'f31641a17af7835503b4f1e9');
      case Flavor.clientB:
        return _FlavorEndpoints.forHost('my.client-b.com',
            pusherAppKey: 'f31641a17af7835503b4f1e9');
      case Flavor.clientC:
        return _FlavorEndpoints.forHost('my.client-c.com',
            pusherAppKey: 'f31641a17af7835503b4f1e9');
    }
  }
}
