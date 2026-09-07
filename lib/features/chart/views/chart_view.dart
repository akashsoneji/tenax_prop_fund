import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/flavor/flavor_config.dart';
import '../widgets/chart_in_app_webview.dart';

/// Full-screen embedded web chart for a single symbol. The URL is built from
/// the active flavor's `chartBaseUrl`, so pointing a white-label build at a
/// different host automatically changes where the chart loads from. The theme
/// query param follows the app's current brightness.
///
/// Arguments (via `Get.toNamed(AppRoutes.chart, arguments: {...})`):
///   • `symbol`  (String, required) — e.g. `XAUUSD`.
///   • `title`   (String, optional) — app-bar title; defaults to the symbol.
class ChartView extends StatelessWidget {
  const ChartView({super.key});

  String get _symbol {
    final args = Get.arguments;
    if (args is Map && args['symbol'] is String) return args['symbol'] as String;
    return 'XAUUSD';
  }

  String get _title {
    final args = Get.arguments;
    if (args is Map && args['title'] is String) return args['title'] as String;
    return _symbol;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final config = Get.find<FlavorConfig>();
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ChartInAppWebView(
        url: config.chartUrl(_symbol, dark: dark),
        symbol: _symbol,
      ),
    );
  }
}
