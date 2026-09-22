import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/competition_models.dart';

/// Gradient hero at the top of the Competitions screen. Leads with the
/// combined cash pool from `stats.cash_pool` and summarises how many
/// competitions are open right now.
class CompetitionsHero extends StatelessWidget {
  const CompetitionsHero({
    super.key,
    required this.stats,
    required this.total,
    required this.liveCount,
  });

  final CompetitionsStats stats;
  final int total;
  final int liveCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.24),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: AppColors.white.withValues(alpha: 0.85),
            size: 20.w,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'competitions.cash_pool'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    color: AppColors.white.withValues(alpha: 0.75),
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  stats.cashPool.isEmpty ? '—' : stats.cashPool,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.value(color: AppColors.white, fontSize: 22.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          _HeroStat(label: 'competitions.total'.tr, value: '$total'),
          SizedBox(width: 8.w),
          _HeroStat(label: 'competitions.status.live'.tr, value: '$liveCount'),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.value(color: AppColors.white, fontSize: 15.sp),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              color: AppColors.white.withValues(alpha: 0.70),
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}
