import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/positions_models.dart';
import '../views/close_position_view.dart';

/// A slim, dense position/pending/history row — ported from the white_label
/// iQuote card. Two compact rows: side chip · symbol · volume ─ P/L, then
/// entry → current with optional TP/SL pills.
///
/// Interactions (open positions & pending only):
/// - Tap  → opens [ClosePositionView] to close / modify (TP·SL, partial close).
/// - Swipe left → quick close/cancel (calls [onAction]).
class PositionCard extends StatelessWidget {
  const PositionCard({
    super.key,
    required this.position,
    required this.busy,
    required this.onAction,
    this.isHistory = false,
  });

  final TradePosition position;
  final bool busy;

  /// Quick close (open) / cancel (pending), triggered by swipe or the × button.
  final VoidCallback onAction;
  final bool isHistory;

  bool _hasPrice(String v) {
    final d = double.tryParse(v);
    return v.isNotEmpty && d != null && d != 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBuy = position.isBuy;
    final isPositive = position.profitLoss >= 0;
    final green = AppColors.success;
    final red = AppColors.danger;
    final sideColor = isBuy ? green : red;
    final actionable = !isHistory;

    final card = Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: sideColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  isBuy ? 'positions.buy'.tr : 'positions.sell'.tr,
                  style: TextStyle(
                    color: sideColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        position.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      position.volume.toString(),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${isPositive ? '' : '-'}\$${position.profitLoss.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPositive ? green : red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Text(
                position.entryPrice,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.sp),
              ),
              SizedBox(width: 4.w),
              Icon(Icons.arrow_forward,
                  color: scheme.onSurfaceVariant, size: 11.sp),
              SizedBox(width: 4.w),
              Text(
                position.currentPrice,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.sp),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_hasPrice(position.takeProfit))
                      _pill('TP', position.takeProfit, green),
                    if (_hasPrice(position.takeProfit) &&
                        _hasPrice(position.stopLoss))
                      SizedBox(width: 6.w),
                    if (_hasPrice(position.stopLoss))
                      _pill('SL', position.stopLoss, red),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!actionable) return card;

    final tappable = InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: busy
          ? null
          : () => Get.to<void>(() => ClosePositionView(position: position)),
      child: card,
    );

    // Swipe left to quick close/cancel.
    return Dismissible(
      key: ValueKey('pos_${position.orderId}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (busy) return false;
        onAction();
        return false; // socket/optimistic removal drives the actual disappear.
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.close_rounded, color: red, size: 22.sp),
      ),
      child: tappable,
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
