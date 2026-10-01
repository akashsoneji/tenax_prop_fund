import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../accounts/models/accounts_models.dart';
import '../../../shared/theme/app_spacing.dart';

/// Profit green, loss red, exact zero neutral.
Color _signColor(String value, ColorScheme scheme) {
  if (value.startsWith('-')) return AppColors.danger;
  if (value == '+\$0.00') return scheme.onSurfaceVariant;
  return AppColors.success;
}

/// One account in the switch sheet: gradient avatar with a status dot, login
/// with a Primary badge and a tinted Total P/L pill, a meta line (phase chip,
/// size, days, leverage, started) and a Balance | Equity | Floating strip.
/// The selected account gets a gradient outline.
class AccountSwitchCard extends StatelessWidget {
  const AccountSwitchCard({
    super.key,
    required this.row,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final AccountRow row;
  final bool selected;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(selected ? 1.5.w : 1.w),
      decoration: BoxDecoration(
        gradient: selected ? AppTheme.heroGradient(scheme) : null,
        color: selected ? null : scheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: selected ? 0.18 : 0.04),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: selected
            ? Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.05),
                scheme.surface,
              )
            : scheme.surface,
        borderRadius: BorderRadius.circular(15.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10.w, 10.h, 12.w, 10.h),
            child: Column(
              children: [
                Row(
                  children: [
                    _Avatar(
                      selected: selected,
                      statusColor: row.tone == AccountTone.down
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                    10.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _titleLine(scheme),
                          3.verticalSpace,
                          _metaLine(scheme),
                        ],
                      ),
                    ),
                  ],
                ),
                Gap.vSm,
                _MoneyStrip(row: row),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _titleLine(ColorScheme scheme) {
    final pnlColor = _signColor(row.pnl, scheme);
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  row.login,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(
                    color: scheme.onSurface,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              if (primary) ...[
                6.horizontalSpace,
                _Chip(
                  label: 'positions.primary'.tr,
                  color: scheme.primary,
                  icon: Icons.star_rounded,
                ),
              ],
            ],
          ),
        ),
        Gap.hSm,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: pnlColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            row.pnl,
            style: AppText.title(color: pnlColor, fontSize: 12.5.sp),
          ),
        ),
      ],
    );
  }

  Widget _metaLine(ColorScheme scheme) {
    final meta = [
      row.accountSize,
      'positions.days_short'.trParams({'days': row.tradingDays}),
      row.leverage,
      if (row.started.isNotEmpty) row.started,
    ].join(' · ');
    return Row(
      children: [
        if (row.phaseLabel.isNotEmpty) ...[
          _Chip(label: row.phaseLabel, color: scheme.primary),
          6.horizontalSpace,
        ],
        Expanded(
          child: Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.subtitle(
              color: scheme.onSurface.withValues(alpha: AppColors.alphaMuted),
              fontSize: 10.sp,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gradient wallet avatar (check when selected) with a status dot.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.selected, required this.statusColor});

  final bool selected;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36.w,
      height: 36.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient(scheme),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected
                    ? Icons.check_rounded
                    : Icons.account_balance_wallet_rounded,
                size: 17.w,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            right: -1.w,
            bottom: -1.w,
            child: Container(
              width: 11.w,
              height: 11.w,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2.w),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 10.w, color: color), Gap.hXxs],
          Text(
            label,
            style: AppText.subtitle(color: color, fontSize: 9.5.sp),
          ),
        ],
      ),
    );
  }
}

/// Balance | Equity | Floating P/L; amounts scale down instead of clipping.
class _MoneyStrip extends StatelessWidget {
  const _MoneyStrip({required this.row});

  final AccountRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = Container(
      width: 1.w,
      height: 22.h,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      color: scheme.onSurface.withValues(alpha: 0.08),
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          _cell(scheme, 'accounts.balance'.tr, row.balance, scheme.onSurface),
          divider,
          _cell(scheme, 'accounts.equity'.tr, row.equity, scheme.onSurface),
          divider,
          _cell(
            scheme,
            'positions.floating_pl'.tr,
            row.floating,
            _signColor(row.floating, scheme),
          ),
        ],
      ),
    );
  }

  Widget _cell(ColorScheme scheme, String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.subtitle(
              color: scheme.onSurface.withValues(alpha: AppColors.alphaMuted),
              fontSize: 9.5.sp,
            ),
          ),
          1.verticalSpace,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 1,
              style: AppText.title(color: color, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}
