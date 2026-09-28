import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chart_landscape_controller.dart';
import '../widgets/landscape_back_pill.dart';
import '../widgets/landscape_chart_pane.dart';
import '../widgets/landscape_rail_toggle.dart';
import '../widgets/landscape_trade_rail.dart';

/// Full-screen landscape trading view: the live chart fills the ENTIRE screen,
/// and the trade ticket is a rail that slides in from the LEFT and overlays
/// it — it never pushes or resizes the chart. No bottom tab bar: this is a
/// pushed route, not a tab, so the chrome disappears by construction.
///
/// The chart pane is a fixed [Positioned.fill] regardless of the rail's state.
/// That is deliberate: the charting library rebuilds its widget whenever the
/// webview's size changes, and that rebuild is what showed up as the chart
/// blanking out every time the rail was toggled. Overlaying instead of
/// resizing means the size never changes, so collapse/expand is instant and
/// the chart is never disturbed.
class ChartLandscapeView extends GetView<ChartLandscapeController> {
  const ChartLandscapeView({super.key, required this.symbols});

  /// Symbols offered by the rail's symbol picker, passed through from the
  /// Charts tab so both orientations list the same instruments.
  final List<String> symbols;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The gesture/hardware back must restore portrait BEFORE the pop, or
      // the user lands on a sideways Charts tab for a frame.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.exit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          // Sized from the REAL viewport rather than ScreenUtil. A nested
          // ScreenUtilInit re-inits a global singleton that the root one
          // (375x812 portrait) owns, and the mismatch scaled every `.w` here
          // to the wrong value — this whole screen and its children use plain
          // literal points instead.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final railWidth = LandscapeTradeRail.widthFor(constraints.maxWidth);
              return Stack(
                children: [
                  // Always full screen, always the SAME size — see class doc.
                  const Positioned.fill(child: LandscapeChartPane()),
                  Positioned(
                    top: 28,
                    right: 12,
                    child: LandscapeBackPill(onTap: controller.exit),
                  ),
                  Obx(() {
                    final open = controller.railOpen.value;
                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      top: 0,
                      bottom: 0,
                      left: open ? 0 : -railWidth,
                      width: railWidth,
                      child: Material(
                        // The rail sits ON TOP of the chart, so it needs its
                        // own elevation to read as a panel rather than a part
                        // of the page underneath it.
                        elevation: 12,
                        shadowColor: Colors.black.withValues(alpha: 0.4),
                        child: LandscapeTradeRail(
                          symbols: symbols,
                          width: railWidth,
                        ),
                      ),
                    );
                  }),
                  Obx(() {
                    final open = controller.railOpen.value;
                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: open ? railWidth : 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: LandscapeRailToggle(
                          railOpen: open,
                          onTap: controller.toggleRail,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
