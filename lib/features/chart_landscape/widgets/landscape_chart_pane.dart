import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chart/widgets/chart_in_app_webview.dart';
import '../controllers/chart_landscape_controller.dart';

/// The chart half of the landscape split view.
///
/// It shows the SAME warm webview instance the Markets tab handed over, so the
/// chart is already painted when this screen opens.
///
/// Like the portrait chart this is NOT wrapped in an `Obx`: a reactive builder
/// rebuilds the `ChartInAppWebView` element on every notification, and the
/// platform treats that as a fresh load. The symbol is watched explicitly and
/// pushed down as a prop instead, so the webview applies it in place via JS.
class LandscapeChartPane extends StatefulWidget {
  const LandscapeChartPane({super.key});

  @override
  State<LandscapeChartPane> createState() => _LandscapeChartPaneState();
}

class _LandscapeChartPaneState extends State<LandscapeChartPane> {
  final _controller = Get.find<ChartLandscapeController>();

  late String _symbol = _controller.symbol;
  late bool _ready = _controller.rotationSettled.value;

  final _subs = <Worker>[];

  @override
  void initState() {
    super.initState();
    _subs.add(
      ever<bool>(_controller.rotationSettled, (settled) {
        if (!mounted || settled == _ready) return;
        setState(() => _ready = settled);
      }),
    );
    _subs.add(
      ever<String>(_controller.selectedSymbol, (next) {
        if (!mounted || next.isEmpty || next == _symbol) return;
        setState(() => _symbol = next);
      }),
    );
  }

  @override
  void dispose() {
    for (final worker in _subs) {
      worker.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      // Held back until the device has actually rotated: attaching while the
      // window is still portrait-shaped makes the chart lay out at the wrong
      // size and rebuild when the rotation lands.
      child: _ready
          ? ChartInAppWebView(
              url: _controller.urlFor(_symbol),
              symbol: _symbol,
            )
          : const SizedBox.expand(),
    );
  }
}

/// Thin rounded scrim used behind the floating controls that sit over the
/// chart, so an icon stays legible on both a light and a dark candle body.
class LandscapeChartOverlayScrim extends StatelessWidget {
  const LandscapeChartOverlayScrim({
    super.key,
    required this.child,
    this.radius,
  });

  final Widget child;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(radius ?? 20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}
