import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_pill.dart';
import '../models/accounts_models.dart';

/// One account card, redesigned compact for mobile. A tone-coloured status rail
/// runs down the left edge; the header pairs the plan eyebrow + login with a
/// status pill and the P&L figure inline; a single divided stat row carries
/// Balance / Equity / Days / Leverage; a slim footer holds Trade / Dashboard.
/// Fully theme-driven (light/dark).
class AccountListCard extends StatelessWidget {
  const AccountListCard({
    super.key,
    required this.account,
    required this.onTrade,
    required this.onDashboard,
  });

  final AccountRow account;
  final VoidCallback onTrade;
  final VoidCallback onDashboard;

  Color _toneColor(ColorScheme scheme) => switch (account.tone) {
        AccountTone.up => AppColors.success,
        AccountTone.down => AppColors.danger,
        AccountTone.neutral => scheme.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final tone = _toneColor(scheme);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.10)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.06),
              blurRadius: 14.r,
              offset: Offset(0, 6.h),
            ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tone status rail.
            Container(width: 3.w, color: tone),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(11.w, 10.h, 11.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(account: account),
                    SizedBox(height: 9.h),
                    _PnlRow(account: account),
                    SizedBox(height: 9.h),
                    _StatStrip(account: account),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(child: _TradeButton(onTap: onTrade)),
                        SizedBox(width: 8.w),
                        Expanded(child: _DashboardButton(onTap: onDashboard)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: plan eyebrow + login on the left, status pill on the right.
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({required this.account});
  final AccountRow account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.planName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 3.h),
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: account.login,
                      style: TextStyle(color: scheme.primary),
                    ),
                    TextSpan(text: '  ·  ${account.accountSize}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        _StatusPill(label: account.statusLabel, tone: account.tone),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compact P&L row: tinted pill leading with the number that matters, plus the
// floating note trailing when present. Shorter than the old boxed band.
// ---------------------------------------------------------------------------
class _PnlRow extends StatelessWidget {
  const _PnlRow({required this.account});
  final AccountRow account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = account.pnlNegative ? AppColors.danger : AppColors.success;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(
            account.pnlNegative
                ? Icons.trending_down_rounded
                : Icons.trending_up_rounded,
            size: 16.w,
            color: color,
          ),
          SizedBox(width: 7.w),
          Text(
            'accounts.total_pl'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            account.pnl.isEmpty ? '—' : account.pnl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (account.floatingNote.isNotEmpty) ...[
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                account.floatingNote,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single divided stat row: Balance · Equity · Days · Leverage. Replaces the
// tall 2×2 grid so the card stays short.
// ---------------------------------------------------------------------------
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.account});
  final AccountRow account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.white.withValues(alpha: 0.04)
            : AppColors.trackSoft,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: 'accounts.balance'.tr,
              value: account.balance,
            ),
          ),
          const _CellDivider(),
          Expanded(
            child: _StatCell(
              label: 'accounts.equity'.tr,
              value: account.equity,
            ),
          ),
          const _CellDivider(),
          Expanded(
            child: _StatCell(
              label: 'accounts.trading_days'.tr,
              value: account.tradingDays,
            ),
          ),
          const _CellDivider(),
          Expanded(
            child: _StatCell(
              label: 'accounts.leverage'.tr,
              value: account.leverage,
            ),
          ),
        ],
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 1.w,
      height: 26.h,
      color: scheme.onSurfaceVariant.withValues(alpha: 0.14),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                height: 1.1,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeButton extends StatelessWidget {
  const _TradeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(11.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11.r),
        child: Container(
          height: 36.h,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up_rounded,
                  size: 16.w, color: AppColors.black),
              SizedBox(width: 6.w),
              Text(
                'accounts.trade'.tr,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardButton extends StatelessWidget {
  const _DashboardButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient(scheme),
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11.r),
          child: Container(
            height: 36.h,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dashboard_rounded,
                    size: 15.w, color: AppColors.white),
                SizedBox(width: 6.w),
                Text(
                  'accounts.dashboard'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.tone});
  final String label;
  final AccountTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      AccountTone.up => AppColors.success,
      AccountTone.down => AppColors.danger,
      AccountTone.neutral => scheme.onSurfaceVariant,
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return AppPill(
      label: label,
      color: color,
      showDot: true,
      dotSize: 5,
      dotGap: 5,
      bordered: true,
      radius: 7,
      fontSize: 10.5,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
    );
  }
}
