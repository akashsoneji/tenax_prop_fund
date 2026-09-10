import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/positions_models.dart';

/// One open-position
/// and current price, live PnL, and a close/cancel action. Mirrors the
/// white_label trade-screen row/expanded card. Profit/loss is the ONLY colour
/// that maps to a semantic token (success/danger); everything else is theme.
class PositionCard extends StatelessWidget {
  const PositionCard({
    super.key,
    required this.position,
    required this.onAction,
    required this.busy,
  });

  final TradePosition position;
  final VoidCallback onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBuy = position.isBuy;
    final sideColor = isBuy ? AppColors.success : AppColors.danger;
    final pnlColor = position.profitLoss >= 0 ? AppColors.success : AppColors.danger;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  position.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(color: scheme.onSurface, fontSize: 15.sp),
                ),
              ),
              _SidePill(
                label: (isBuy ? 'trade.buy' : 'trade.sell').tr,
                color: sideColor,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '${'positions.volume'.tr}: ${position.volume.toStringAsFixed(2)}',
            style: AppText.label(color: muted),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _PriceBlock(
                  label: position.isPending
                      ? 'positions.order_price'.tr
                      : 'positions.open_price'.tr,
                  value: position.entryPrice,
                ),
              ),
              Expanded(
                child: _PriceBlock(
                  label: 'positions.current_price'.tr,
                  value: position.currentPrice,
                ),
              ),
              if (!position.isPending)
                Expanded(
                  child: _PriceBlock(
                    label: 'positions.pnl'.tr,
                    value: position.profitLoss.toStringAsFixed(2),
                    valueColor: pnlColor,
                    alignEnd: true,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                (position.isPending ? 'positions.cancel' : 'positions.close').tr,
                style: AppText.subtitle(color: AppColors.danger, fontSize: 13.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePill extends StatelessWidget {
  const _SidePill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
      Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppColors.alphaHairline),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppText.label(color: color, fontSize: 11.sp),
        ),
      );
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label(color: muted, fontSize: 11.sp)),
        SizedBox(height: 2.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.subtitle(
            color: valueColor ?? scheme.onSurface,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}
