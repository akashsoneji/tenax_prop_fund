import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Floating control that opens the landscape full-screen chart. Sits over the
/// top-right of any chart surface, translucent so it reads on both a light and
/// a dark candle body without hiding price action behind an opaque bar.
class ChartFullscreenButton extends StatelessWidget {
  const ChartFullscreenButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = 'chart.fullscreen'.tr;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: scheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.open_in_full,
                size: 17.w,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
