import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/positions_models.dart';

/// One closed-trade row
/// price, and net profit coloured green/red.
class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);
    final isBuy = entry.isBuy;
    final sideColor = isBuy ? AppColors.success : AppColors.danger;
    final pnlColor = entry.profit >= 0 ? AppColors.success : AppColors.danger;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title(color: scheme.onSurface, fontSize: 15.sp),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      (isBuy ? 'trade.buy' : 'trade.sell').tr.toUpperCase(),
                      style: AppText.label(color: sideColor, fontSize: 11.sp),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '${'positions.volume'.tr}: ${entry.volume.toStringAsFixed(2)}'
                  '   ${entry.priceOpen} → ${entry.priceClose}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(color: muted),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            entry.profit.toStringAsFixed(2),
            style: AppText.subtitle(color: pnlColor, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
