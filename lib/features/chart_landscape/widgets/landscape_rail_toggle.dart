import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'landscape_chart_pane.dart';

/// Slim handle on the rail's edge that collapses / expands the trade panel, so
/// the user can hand the full width to the chart without leaving full screen.
class LandscapeRailToggle extends StatelessWidget {
  const LandscapeRailToggle({
    super.key,
    required this.railOpen,
    required this.onTap,
  });

  final bool railOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = railOpen ? 'chart.hide_panel'.tr : 'chart.show_panel'.tr;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: LandscapeChartOverlayScrim(
          radius: 12,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 26,
              height: 56,
              // The rail is on the LEFT now: open collapses it further left,
              // closed expands it out to the right — opposite of when it lived
              // on the right edge.
              child: Icon(
                railOpen ? Icons.chevron_left : Icons.chevron_right,
                size: 18,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
