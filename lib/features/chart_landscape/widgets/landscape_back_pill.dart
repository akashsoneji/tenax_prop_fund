import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'landscape_chart_pane.dart';

/// Floating "exit full screen" control over the top-left of the chart.
///
/// Deliberately floats rather than sitting in an app bar: landscape gives the
/// chart only ~375pt of height, and a bar would spend 56 of them on one icon.
class LandscapeBackPill extends StatelessWidget {
  const LandscapeBackPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = 'chart.exit_fullscreen'.tr;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: LandscapeChartOverlayScrim(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.close_fullscreen_rounded,
                    size: 14,
                    color: scheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
