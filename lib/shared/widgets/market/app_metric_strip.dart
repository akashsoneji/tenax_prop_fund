import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../theme/app_text.dart';

/// One label/value pair in an [AppMetricStrip].
class AppMetric {
  const AppMetric(this.label, this.value);

  /// Already translated label (e.g. `'symbols.high'.tr`).
  final String label;
  final String value;
}

/// A row of equal-width label/value metrics (e.g. High / Low / Spread).
/// Wrapped in a [RepaintBoundary] so live values repaint only this strip.
class AppMetricStrip extends StatelessWidget {
  const AppMetricStrip({super.key, required this.metrics});

  /// The market High / Low / Spread strip.
  AppMetricStrip.highLowSpread({
    super.key,
    required String high,
    required String low,
    required String spread,
  }) : metrics = [
          AppMetric('symbols.high'.tr, high),
          AppMetric('symbols.low'.tr, low),
          AppMetric('symbols.spread_label'.tr, spread),
        ];

  final List<AppMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Row(
        children: [
          for (final m in metrics)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.base(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  3.verticalSpace,
                  Text(
                    m.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.base(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
