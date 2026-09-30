import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_pill.dart';
import '../models/dashboard_models.dart';
import 'home_bento.dart';

/// One grouped surface holding the focused account's balance, the account
/// count and every KPI tile as a two-column grid split by hairline dividers.
class HomeOverviewPanel extends StatelessWidget {
  const HomeOverviewPanel({super.key, required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focus = data.focus;
    final currency = focus?.currency ?? 'USD';
    final balance = (focus?.balance.isNotEmpty ?? false)
        ? focus!.balance
        : formatMinorMoney(focus?.balanceMinor ?? 0, currency);

    final cells = <Widget>[
      _StatCell(
        icon: Icons.account_balance_wallet_rounded,
        label: 'home.balance'.tr,
        value: balance,
        tone: AppColors.success,
      ),
      _StatCell(
        icon: Icons.layers_rounded,
        label: 'home.your_accounts'.tr,
        value: '${data.accountCount}',
        tone: scheme.primary,
      ),
      for (final kpi in data.kpis) _StatCell.kpi(kpi: kpi, scheme: scheme),
    ];

    final divider = scheme.onSurface.withValues(alpha: 0.07);
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 2) {
      if (i > 0) rows.add(Divider(height: 1, thickness: 1, color: divider));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cells[i]),
            VerticalDivider(width: 1, thickness: 1, color: divider),
            Expanded(
              child: i + 1 < cells.length
                  ? cells[i + 1]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ));
    }

    return Container(
      decoration: AppTheme.surfaceCard(scheme, radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// A single metric cell: tinted icon chip + optional delta pill, bold value,
/// muted label.
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.delta,
    this.valueColor,
  });

  factory _StatCell.kpi({required DashboardKpi kpi, required ColorScheme scheme}) {
    final tone = kpi.isGold
        ? AppColors.amber
        : kpi.isDown
            ? AppColors.dangerBright
            : kpi.isUp
                ? AppColors.success
                : scheme.primary;
    final hint = kpi.hint.trim();
    final isDelta = hint.isNotEmpty &&
        (hint.startsWith('+') || hint.startsWith('-') || hint.startsWith('−'));
    return _StatCell(
      icon: _iconFor(kpi),
      label: hint.isNotEmpty && !isDelta ? '${kpi.label} · ${kpi.hint}' : kpi.label,
      value: kpi.value,
      tone: tone,
      delta: isDelta ? kpi.hint : null,
      valueColor: kpi.isGold ? AppColors.amber : null,
    );
  }

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final String? delta;
  final Color? valueColor;

  static IconData _iconFor(DashboardKpi kpi) {
    final hint = '${kpi.metric} ${kpi.label}'.toLowerCase();
    if (hint.contains('equity')) return Icons.trending_up_rounded;
    if (hint.contains('balance')) return Icons.account_balance_wallet_rounded;
    if (hint.contains('account')) return Icons.layers_rounded;
    if (hint.contains('day')) return Icons.calendar_today_rounded;
    if (hint.contains('profit')) return Icons.show_chart_rounded;
    return Icons.insights_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 12.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16.w, color: tone),
              ),
              const Spacer(),
              if (delta != null)
                Flexible(
                  child: AppPill(
                    label: delta!,
                    color: tone,
                    fontSize: 10.5,
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 1,
              style: AppText.value(
                color: valueColor ?? scheme.onSurface,
                fontSize: 17.sp,
              ).copyWith(letterSpacing: -0.5),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              color: scheme.onSurface.withValues(alpha: 0.58),
              fontSize: 11.5.sp,
            ),
          ),
        ],
      ),
    );
  }
}
