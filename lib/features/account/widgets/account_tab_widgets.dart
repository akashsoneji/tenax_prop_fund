import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/account_models.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_card.dart';

// ---------------------------------------------------------------------------
// Trading overview
// ---------------------------------------------------------------------------

/// Detailed-stats card — metrics laid out as compact two-column rows
/// (label muted on the left, value bold/toned on the right), mirroring the web
/// "Detailed stats" table. Rows are split by hairline dividers.
class AccountInsightsGrid extends StatelessWidget {
  const AccountInsightsGrid({super.key, required this.metrics});
  final List<AccountMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (metrics.isEmpty) return const SizedBox.shrink();

    // Pair metrics up: [0,1] [2,3] … so each row shows two cells.
    final rows = <List<AccountMetric>>[];
    for (var i = 0; i < metrics.length; i += 2) {
      rows.add(metrics.sublist(i, (i + 2).clamp(0, metrics.length)));
    }

    return AppCard(
      radius: 16,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0)
              Divider(
                height: 1.h,
                thickness: 1.h,
                color: scheme.primary.withValues(alpha: 0.06),
              ),
            Row(
              children: [
                Expanded(child: _MetricCell(metric: rows[r][0])),
                Container(
                  width: 1.w,
                  height: 34.h,
                  color: scheme.primary.withValues(alpha: 0.06),
                ),
                Expanded(
                  child: rows[r].length > 1
                      ? _MetricCell(metric: rows[r][1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric});
  final AccountMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueColor = switch (metric.tone) {
      AccountTone.up => AppColors.success,
      AccountTone.down => AppColors.danger,
      AccountTone.neutral => scheme.onSurface,
    };
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.base(
                fontSize: 12.5.sp,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Gap.hSm,
          Text(
            metric.value,
            style: AppText.base(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
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
    return AppCard(
      radius: 14,
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 10.h),
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
              trade.isBuy ? Icons.north_east_rounded : Icons.south_east_rounded,
              size: 18.w,
              color: sideColor,
            ),
          ),
          Gap.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      trade.symbol,
                      style: AppText.base(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Gap.hSm,
                    Text(
                      '${trade.side.toUpperCase()} · ${trade.volume}',
                      style: AppText.base(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                3.verticalSpace,
                Text(
                  '${trade.openPrice} → ${trade.closePrice} · ${trade.closedAt}',
                  style: AppText.base(
                    fontSize: 11.5.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trade.profit,
            style: AppText.base(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: trade.profitNegative
                  ? AppColors.danger
                  : AppColors.success,
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
    return AppCard(
      radius: 16,
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  download.label,
                  style: AppText.base(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.download_rounded, size: 18.w, color: scheme.primary),
            ],
          ),
          6.verticalSpace,
          Text(
            download.note,
            style: AppText.base(
              fontSize: 12.sp,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Gap.vMd,
          Material(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              onTap: onDownload,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                height: 42.h,
                alignment: Alignment.center,
                child: Text(
                  'account.download'.tr,
                  style: AppText.base(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
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
    return AppCard(
      radius: 16,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'account.reset_carries'.tr,
            style: AppText.base(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          Gap.vMd,
          for (final (kept, label) in items)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: (kept ? AppColors.success : AppColors.amber)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      kept ? 'account.reset_kept'.tr : 'account.reset_reset'.tr,
                      style: AppText.base(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: kept ? AppColors.success : AppColors.amber,
                      ),
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.base(
                        fontSize: 13.sp,
                        color: scheme.onSurface,
                      ),
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
