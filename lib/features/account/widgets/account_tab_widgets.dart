import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/account_models.dart';

// ---------------------------------------------------------------------------
// Trading overview
// ---------------------------------------------------------------------------

/// Grid of insight metric tiles.
class AccountInsightsGrid extends StatelessWidget {
  const AccountInsightsGrid({super.key, required this.metrics});
  final List<AccountMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10.h,
      crossAxisSpacing: 10.w,
      childAspectRatio: 2.4,
      children: [for (final m in metrics) _MetricTile(metric: m)],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});
  final AccountMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueColor = switch (metric.tone) {
      AccountTone.up => AppColors.success,
      AccountTone.down => AppColors.danger,
      AccountTone.neutral => scheme.onSurface,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5.sp, color: scheme.onSurfaceVariant)),
          SizedBox(height: 3.h),
          Text(metric.value,
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: valueColor)),
        ],
      ),
    );
  }
}

/// One closed-trade row.
class AccountTradeRow extends StatelessWidget {
  const AccountTradeRow({super.key, required this.trade});
  final AccountTrade trade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sideColor = trade.isBuy ? AppColors.success : AppColors.danger;
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 14),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sideColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              trade.isBuy
                  ? Icons.north_east_rounded
                  : Icons.south_east_rounded,
              size: 18.w,
              color: sideColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(trade.symbol,
                        style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface)),
                    SizedBox(width: 8.w),
                    Text('${trade.side.toUpperCase()} · ${trade.volume}',
                        style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant)),
                  ],
                ),
                SizedBox(height: 3.h),
                Text('${trade.openPrice} → ${trade.closePrice} · ${trade.closedAt}',
                    style: TextStyle(
                        fontSize: 11.5.sp, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            trade.profit,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: trade.profitNegative ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Platform
// ---------------------------------------------------------------------------

/// One MT5 download card with a gradient action.
class PlatformDownloadCard extends StatelessWidget {
  const PlatformDownloadCard({
    super.key,
    required this.download,
    required this.onDownload,
  });

  final PlatformDownload download;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(download.label,
                    style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface)),
              ),
              Icon(Icons.download_rounded, size: 18.w, color: scheme.primary),
            ],
          ),
          SizedBox(height: 6.h),
          Text(download.note,
              style: TextStyle(
                  fontSize: 12.sp, color: scheme.onSurfaceVariant)),
          SizedBox(height: 12.h),
          Material(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              onTap: onDownload,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                height: 42.h,
                alignment: Alignment.center,
                child: Text('account.download'.tr,
                    style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reset
// ---------------------------------------------------------------------------

/// The reset "what carries over" list.
class ResetCarryList extends StatelessWidget {
  const ResetCarryList({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <(bool, String)>[
      (true, 'account.reset_keep_tier'.tr),
      (true, 'account.reset_keep_kyc'.tr),
      (false, 'account.reset_clear_balance'.tr),
      (false, 'account.reset_clear_counter'.tr),
    ];
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('account.reset_carries'.tr,
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface)),
          SizedBox(height: 12.h),
          for (final (kept, label) in items)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: (kept ? AppColors.success : AppColors.amber)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      kept ? 'account.reset_kept'.tr : 'account.reset_reset'.tr,
                      style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: kept ? AppColors.success : AppColors.amber),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 13.sp, color: scheme.onSurface)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
