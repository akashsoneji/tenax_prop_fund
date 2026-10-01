import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// A large Buy/Sell price block: muted label above, coloured price below, on a
/// soft tinted background. Wrapped in a [RepaintBoundary] so a live tick
/// repaints only this tile, not the card around it.
class AppPriceTile extends StatelessWidget {
  const AppPriceTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  /// Sell tile: `trade.sell` label, danger colour.
  const AppPriceTile.sell({super.key, required this.value})
      : label = null,
        color = AppColors.danger;

  /// Buy tile: `trade.buy` label, success colour.
  const AppPriceTile.buy({super.key, required this.value})
      : label = null,
        color = AppColors.success;

  /// Null on the [sell]/[buy] constructors, which translate their own label.
  final String? label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = label ??
        (color == AppColors.danger ? 'trade.sell'.tr : 'trade.buy'.tr);
    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.base(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            3.verticalSpace,
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.base(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
