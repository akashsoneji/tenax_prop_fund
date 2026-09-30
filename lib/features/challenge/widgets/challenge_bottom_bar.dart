import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';

/// The sticky summary bar pinned to the bottom of the Choose-a-challenge
/// and Configure screens: plan name + price on the left, a "Configure"
/// (or custom label) button on the right. [strikePrice] is optional.
class ChallengeBottomBar extends StatelessWidget {
  const ChallengeBottomBar({
    super.key,
    required this.planName,
    required this.price,
    required this.actionLabel,
    required this.onAction,
    this.strikePrice,
    this.loading = false,
  });

  final String planName;
  final String price;
  final String actionLabel;
  final VoidCallback? onAction;
  final String? strikePrice;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 12.w, 10.h),
          child: Row(
            children: [
              Expanded(child: _PriceSummary(bar: this)),
              SizedBox(width: 10.w),
              _ActionButton(
                label: actionLabel,
                loading: loading,
                onTap: loading ? null : onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.bar});
  final ChallengeBottomBar bar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          bar.planName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(
            color: AppColors.white.withValues(alpha: 0.85),
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                bar.price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.value(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 19.sp),
              ),
            ),
            if (bar.strikePrice != null) ...[
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Text(
                  bar.strikePrice!,
                  style: AppText.label(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 12.5.sp,
                  ).copyWith(decoration: TextDecoration.lineThrough),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          child: loading
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: const AlwaysStoppedAnimation(AppColors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppText.title(
                          color: AppColors.white, fontSize: 14.sp),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16.w, color: AppColors.white),
                  ],
                ),
        ),
      ),
    );
  }
}
