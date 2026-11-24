import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/positions_models.dart';
import '../views/close_position_view.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_card.dart';
import 'trade_detail_grid.dart';

/// A slim, dense position/pending/history row — ported from the white_label
/// iQuote card. Two compact rows: side chip · symbol · volume ─ P/L, then
/// entry → current with optional TP/SL pills and a chevron that expands the
/// S/L, T/P, open time, duration, swap and position-ID details.
///
/// Interactions (open positions & pending only):
/// - Tap  → opens [ClosePositionView] to close / modify (TP·SL, partial close).
/// - Chevron → expand / collapse the details (collapsed by default).
/// - Swipe left → quick close/cancel (calls [onAction]).
class PositionCard extends StatefulWidget {
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

  @override
  State<PositionCard> createState() => _PositionCardState();
}

class _PositionCardState extends State<PositionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final position = widget.position;
    final red = AppColors.danger;

    final card = AppCard(
      radius: 12.r,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 8.h),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PositionSummary(
              position: position,
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Divider(height: 1.h, color: scheme.outlineVariant),
              ),
              TradeDetailGrid(
                rows: [
                  ('positions.hist_sl', position.stopLoss,
                      'positions.hist_tp', position.takeProfit),
                  ('positions.hist_open', tradeTime(position.openTime),
                      'positions.hist_duration', tradeDuration(position.openTime)),
                  position.isPending
                      ? ('positions.order_price', position.entryPrice,
                          'positions.hist_id', '#${position.orderId}')
                      : ('positions.hist_swap', position.swap.toStringAsFixed(2),
                          'positions.hist_id', '#${position.orderId}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.isHistory) return card;

    final tappable = InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: widget.busy
          ? null
          : () => Get.to<void>(() => ClosePositionView(position: position)),
      child: card,
    );

    // Swipe left to quick close/cancel.
    return Dismissible(
      key: ValueKey('pos_${position.orderId}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (widget.busy) return false;
        widget.onAction();
        return false; // socket/optimistic removal drives the actual disappear.
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.close_rounded, color: red, size: 22.sp),
      ),
      child: tappable,
    );
  }
}

/// Collapsed two-line summary: side · symbol · volume ─ P/L, then
/// entry → current, TP/SL pills and the expand chevron.
class _PositionSummary extends StatelessWidget {
  const _PositionSummary({
    required this.position,
    required this.expanded,
    required this.onToggle,
  });

  final TradePosition position;
  final bool expanded;
  final VoidCallback onToggle;

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
    final muted = scheme.onSurfaceVariant;
    final hasTp = _hasPrice(position.takeProfit);
    final hasSl = _hasPrice(position.stopLoss);
    // Pending rows show their order type (Buy Limit, Sell Stop…) and have no P&L.
    final sideLabel = position.isPending && position.pendingType.isNotEmpty
        ? position.pendingType
        : (isBuy ? 'positions.buy'.tr : 'positions.sell'.tr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _pill(sideLabel, sideColor),
            Gap.hSm,
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      position.symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.base(
                        color: scheme.onSurface,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Gap.hSm,
                  Text(
                    position.volume.toString(),
                    style: AppText.base(
                      color: muted,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!position.isPending) ...[
              Gap.hSm,
              Text(
                '${isPositive ? '' : '-'}\$${position.profitLoss.abs().toStringAsFixed(2)}',
                style: AppText.base(
                  color: isPositive ? green : red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            SizedBox(width: 24.w),
          ],
        ),
        Gap.vXs,
        Row(
          children: [
            Expanded(
              child: Text(
                '${position.entryPrice} → ${position.currentPrice}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.base(color: muted, fontSize: 11.sp),
              ),
            ),
            Gap.hXs,
            if (hasTp) _pill('TP ${position.takeProfit}', green),
            if (hasTp && hasSl) 6.horizontalSpace,
            if (hasSl) _pill('SL ${position.stopLoss}', red),
            InkResponse(
              onTap: onToggle,
              radius: 18.r,
              child: Padding(
                padding: EdgeInsets.only(left: 4.w),
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, size: 20.w, color: muted),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: AppText.base(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
