import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/account_models.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_card.dart';

// ---------------------------------------------------------------------------
// Trading-overview segmented control
// performance-breakdown pills). Kept generic so both bars reuse it.
// ---------------------------------------------------------------------------
class AccountSegmentedTabs extends StatelessWidget {
  const AccountSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  height: 36.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: i == selectedIndex
                        ? AppTheme.brandGradient(scheme)
                        : null,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.base(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: i == selectedIndex
                          ? AppColors.white
                          : scheme.onSurfaceVariant,
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

/// A horizontally scrollable row of pills used to switch the Analytics
/// performance breakdown (Symbol / Weekday / Hour / Win-loss). Pills size to
/// their text so labels never truncate, and the row scrolls when it overflows.
class AccountPillSelector extends StatelessWidget {
  const AccountPillSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: labels.length,
        separatorBuilder: (_, _) => Gap.hSm,
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected ? AppTheme.brandGradient(scheme) : null,
                color: selected ? null : scheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : scheme.primary.withValues(alpha: 0.10),
                ),
              ),
              child: Text(
                labels[i],
                style: AppText.base(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.white : scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Equity-growth chart card (Analytics). Plots equity + balance as two lines
// with a soft area fill under equity. Pure CustomPainter — no chart package.
// ---------------------------------------------------------------------------
class EquityGrowthCard extends StatelessWidget {
  const EquityGrowthCard({super.key, required this.points});
  final List<AccountEquityPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final change = points.isEmpty
        ? 0.0
        : points.last.equity - points.first.equity;
    final up = change >= 0;
    final changeLabel = '${up ? '+' : '-'}\$${change.abs().toStringAsFixed(2)}';

    return AppCard(
      radius: 18,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'account.equity_growth'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.base(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (points.isNotEmpty)
                Text(
                  changeLabel,
                  style: AppText.base(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: up ? AppColors.success : AppColors.danger,
                  ),
                ),
            ],
          ),
          Gap.vSm,
          Row(
            children: [
              _LegendDot(color: scheme.primary, label: 'account.equity'.tr),
              14.horizontalSpace,
              _LegendDot(color: AppColors.amber, label: 'account.balance'.tr),
            ],
          ),
          14.verticalSpace,
          if (points.length < 2)
            SizedBox(
              height: 160.h,
              child: Center(
                child: Text(
                  'account.no_chart'.tr,
                  style: AppText.base(
                    fontSize: 13.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 170.h,
              width: double.infinity,
              child: CustomPaint(
                painter: _EquityChartPainter(
                  points: points,
                  equityColor: scheme.primary,
                  balanceColor: AppColors.amber,
                ),
              ),
            ),
            Gap.vSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  points.first.label,
                  style: AppText.base(
                    fontSize: 10.5.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  points.last.label,
                  style: AppText.base(
                    fontSize: 10.5.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        6.horizontalSpace,
        Text(
          label,
          style: AppText.base(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EquityChartPainter extends CustomPainter {
  _EquityChartPainter({
    required this.points,
    required this.equityColor,
    required this.balanceColor,
  });

  final List<AccountEquityPoint> points;
  final Color equityColor;
  final Color balanceColor;

  @override
  void paint(Canvas canvas, Size size) {
    var min = double.infinity;
    var max = double.negativeInfinity;
    for (final p in points) {
      min = [min, p.equity, p.balance].reduce((a, b) => a < b ? a : b);
      max = [max, p.equity, p.balance].reduce((a, b) => a > b ? a : b);
    }
    if (min == max) {
      min -= 1;
      max += 1;
    }
    final range = max - min;
    final dx = size.width / (points.length - 1);

    double y(double value) =>
        size.height - ((value - min) / range) * size.height;

    Path lineFor(double Function(AccountEquityPoint) sel) {
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final px = dx * i;
        final py = y(sel(points[i]));
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      return path;
    }

    // Equity area fill.
    final equityPath = lineFor((p) => p.equity);
    final fill = Path.from(equityPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            equityColor.withValues(alpha: 0.22),
            equityColor.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    // Balance line (dashed-feel via lower opacity, thinner).
    canvas.drawPath(
      lineFor((p) => p.balance),
      Paint()
        ..color = balanceColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Equity line on top.
    canvas.drawPath(
      equityPath,
      Paint()
        ..color = equityColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_EquityChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

// ---------------------------------------------------------------------------
// Performance bars (Symbol / Weekday / Hour). One horizontal bar per bucket,
// width proportional to |P/L| against the largest magnitude in the set.
// ---------------------------------------------------------------------------
class PerformanceBarsCard extends StatelessWidget {
  const PerformanceBarsCard({super.key, required this.bars});
  final List<AccountPerfBar> bars;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (bars.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 28.h),
        decoration: AppTheme.surfaceCard(scheme, radius: 18),
        alignment: Alignment.center,
        child: Text(
          'account.no_breakdown'.tr,
          style: AppText.base(fontSize: 13.sp, color: scheme.onSurfaceVariant),
        ),
      );
    }
    final peak = bars
        .map((b) => b.valueMinor.abs())
        .fold<int>(0, (a, b) => a > b ? a : b);

    return AppCard(
      radius: 18,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < bars.length; i++) ...[
            if (i > 0) 14.verticalSpace,
            _PerfBarRow(bar: bars[i], peak: peak),
          ],
        ],
      ),
    );
  }
}

class _PerfBarRow extends StatelessWidget {
  const _PerfBarRow({required this.bar, required this.peak});
  final AccountPerfBar bar;
  final int peak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = bar.negative ? AppColors.danger : AppColors.success;
    final fraction = peak == 0 ? 0.0 : bar.valueMinor.abs() / peak;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                bar.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.base(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Gap.hSm,
            Text(
              bar.amount,
              style: AppText.base(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        6.verticalSpace,
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: Stack(
            children: [
              Container(
                height: 8.h,
                color: scheme.primary.withValues(alpha: 0.06),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Win / loss ratio card (two count bars).
// ---------------------------------------------------------------------------
class WinLossCard extends StatelessWidget {
  const WinLossCard({super.key, required this.won, required this.lost});
  final int won;
  final int lost;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final peak = (won > lost ? won : lost);
    Widget row(String label, int value, Color color) {
      final fraction = peak == 0 ? 0.0 : value / peak;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.base(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                '$value ${'account.trades_count'.tr}',
                style: AppText.base(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          6.verticalSpace,
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: Stack(
              children: [
                Container(
                  height: 8.h,
                  color: scheme.primary.withValues(alpha: 0.06),
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return AppCard(
      radius: 18,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          row('account.won'.tr, won, AppColors.success),
          14.verticalSpace,
          row('account.lost'.tr, lost, AppColors.danger),
        ],
      ),
    );
  }
}
