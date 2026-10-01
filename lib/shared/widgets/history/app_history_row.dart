import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../app_pill.dart';

/// One row in a transaction/request history list: [title] and [subtitle]
/// (usually a date) on the left; [amount], a status pill and an optional
/// cancel link on the right.
///
/// Data-driven: the feature translates its own status into [statusLabel] and
/// [statusColor] (see `AppStatusColors`).
class AppHistoryRow extends StatelessWidget {
  const AppHistoryRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.statusLabel,
    required this.statusColor,
    this.cancelLabel,
    this.onCancel,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String statusLabel;
  final Color statusColor;

  /// Shown as a red link next to the pill when [onCancel] is set.
  final String? cancelLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.base(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                4.verticalSpace,
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.base(
                    fontSize: 12.sp,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          10.horizontalSpace,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                maxLines: 1,
                style: AppText.base(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              6.verticalSpace,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppPill(
                    label: statusLabel,
                    color: statusColor,
                    bgAlpha: 10,
                    fontSize: 11.5,
                  ),
                  if (onCancel != null && cancelLabel != null) ...[
                    6.horizontalSpace,
                    GestureDetector(
                      onTap: onCancel,
                      child: Text(
                        cancelLabel!,
                        style: AppText.base(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
