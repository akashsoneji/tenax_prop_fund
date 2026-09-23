import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_stat_tile.dart';
import '../models/positions_models.dart';

/// The 6-cell account summary grid
/// Balance / Credit / Equity / Margin / Free Margin / Margin Level, each an
/// icon + label + live value. Mirrors white_label's trade-screen metric strip.
class AccountSummaryGrid extends StatelessWidget {
  const AccountSummaryGrid({super.key, required this.account});

  final AccountInfo account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cells = <_Metric>[
      _Metric('positions.balance'.tr, account.balance, Icons.account_balance_wallet_outlined),
      _Metric('positions.credit'.tr, account.credit, Icons.card_giftcard_outlined),
      _Metric('positions.equity'.tr, account.equity, Icons.trending_up_rounded),
      _Metric('positions.margin'.tr, account.margin, Icons.pie_chart_outline_rounded),
      _Metric('positions.free_margin'.tr, account.marginFree, Icons.savings_outlined),
      _Metric('positions.margin_level'.tr, account.marginLevel,
          Icons.speed_rounded, isPercent: true),
    ];
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: AppTheme.surfaceCard(scheme, radius: 18.r),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.55,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        children: [for (final c in cells) _MetricCell(metric: c)],
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, {this.isPercent = false});
  final String label;
  final double value;
  final IconData icon;
  final bool isPercent;
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric});
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppStatTile(
      icon: metric.icon,
      iconInline: true,
      label: metric.label,
      value: metric.isPercent
          ? '${metric.value.toStringAsFixed(2)}%'
          : metric.value.toStringAsFixed(2),
      labelColor: scheme.onSurface.withValues(alpha: AppColors.alphaMuted),
      labelFontSize: 11,
      valueFontSize: 14,
      valueFontWeight: FontWeight.w600,
      gap: 2,
    );
  }
}
