import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/positions_models.dart';
import 'trade_detail_grid.dart';

/// One closed trade. Collapsed it shows symbol, side + volume, open → close
/// price, close time and net profit; tapping expands the S/L, T/P, open/close
/// time, swap, commission, position ID and duration grid.
class HistoryRow extends StatefulWidget {
  const HistoryRow({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  State<HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<HistoryRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: 16.r,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 10.w, 12.h),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                _HistorySummary(entry: widget.entry, expanded: _expanded),
                if (_expanded) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Divider(height: 1.h, color: scheme.outlineVariant),
                  ),
                  _HistoryDetails(entry: widget.entry),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.entry, required this.expanded});

  final HistoryEntry entry;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);
    final sideColor = entry.isBuy ? AppColors.success : AppColors.danger;
    final pnlColor = entry.profit >= 0 ? AppColors.success : AppColors.danger;
    final sideLabel = (entry.isBuy ? 'trade.buy' : 'trade.sell').tr.toLowerCase();
    final profitText = entry.profit < 0
        ? '-\$${entry.profit.abs().toStringAsFixed(2)}'
        : '\$${entry.profit.toStringAsFixed(2)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: entry.symbol,
                  style: AppText.title(color: scheme.onSurface, fontSize: 15.sp),
                  children: [
                    TextSpan(
                      text: ' $sideLabel ${entry.volume.toStringAsFixed(2)}',
                      style: AppText.subtitle(color: sideColor, fontSize: 14.sp),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                '${entry.priceOpen} → ${entry.priceClose}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(color: muted, fontSize: 12.sp),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              entry.closeTime.replaceAll('-', '.'),
              maxLines: 1,
              style: AppText.label(color: muted, fontSize: 12.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              profitText,
              maxLines: 1,
              style: AppText.subtitle(color: pnlColor, fontSize: 14.sp),
            ),
          ],
        ),
        SizedBox(width: 4.w),
        AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(Icons.keyboard_arrow_down, size: 20.w, color: muted),
        ),
      ],
    );
  }
}

class _HistoryDetails extends StatelessWidget {
  const _HistoryDetails({required this.entry});

  final HistoryEntry entry;

  String get _duration {
    if (entry.duration.isNotEmpty) return entry.duration;
    final close = DateTime.tryParse(entry.closeTime);
    if (close == null) return '-';
    return tradeDuration(entry.openTime, to: close);
  }

  @override
  Widget build(BuildContext context) {
    return TradeDetailGrid(
      rows: [
        ('positions.hist_sl', entry.stopLoss.toStringAsFixed(2),
            'positions.hist_tp', entry.takeProfit.toStringAsFixed(2)),
        ('positions.hist_open', entry.openTime,
            'positions.hist_close', entry.closeTime),
        ('positions.hist_swap', entry.swap.toStringAsFixed(2),
            'positions.hist_commission', entry.commission.toStringAsFixed(2)),
        ('positions.hist_id', '#${entry.positionId}',
            'positions.hist_duration', _duration),
      ],
    );
  }
}
