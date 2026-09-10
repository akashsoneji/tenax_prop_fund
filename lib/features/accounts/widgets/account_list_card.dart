import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/accounts_models.dart';

/// One account card, redesigned for mobile. A tone-coloured status rail runs
/// down the left edge; the header pairs the plan eyebrow + login with a status
/// pill; a tinted P&L band leads with the number that matters; a 2×2 stat grid
/// carries Balance / Equity / Days / Leverage; the footer holds the Trade /
/// Dashboard actions. Fully theme-driven (light/dark).
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
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.10)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.06),
              blurRadius: 16.r,
              offset: Offset(0, 8.h),
            ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tone status rail.
            Container(width: 4.w, color: tone),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(account: account, tone: tone),
                    SizedBox(height: 14.h),
                    _PnlBand(account: account),
                    SizedBox(height: 12.h),
                    _StatGrid(account: account),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(child: _TradeButton(onTap: onTrade)),
                        SizedBox(width: 10.w),
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
  const _Header({required this.account, required this.tone});
  final AccountRow account;
  final Color tone;

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
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 5.h),
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16.sp,
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
        SizedBox(width: 10.w),
        _StatusPill(label: account.statusLabel, tone: account.tone),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// P&L band: the headline figure on a tinted surface, with floating note.
// ---------------------------------------------------------------------------
class _PnlBand extends StatelessWidget {
  const _PnlBand({required this.account});
  final AccountRow account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = account.pnlNegative ? AppColors.danger : AppColors.success;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              account.pnlNegative
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
              size: 19.w,
              color: color,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'accounts.total_pl'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  account.pnl.isEmpty ? '—' : account.pnl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          if (account.floatingNote.isNotEmpty) ...[
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                account.floatingNote,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10.5.sp,
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
// 2×2 stat grid: Balance · Equity · Trading days · Leverage.
// ---------------------------------------------------------------------------
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.account});
  final AccountRow account;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.account_balance_wallet_rounded,
                label: 'accounts.balance'.tr,
                value: account.balance,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _StatTile(
                icon: Icons.show_chart_rounded,
                label: 'accounts.equity'.tr,
                value: account.equity,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.event_available_rounded,
                label: 'accounts.trading_days'.tr,
                value: account.tradingDays,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _StatTile(
                icon: Icons.tune_rounded,
                label: 'accounts.leverage'.tr,
                value: account.leverage,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.white.withValues(alpha: 0.04)
            : AppColors.trackSoft,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.w, color: scheme.primary),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value.isEmpty ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
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
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 42.h,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up_rounded,
                  size: 17.w, color: AppColors.black),
              SizedBox(width: 6.w),
              Text(
                'accounts.trade'.tr,
                style: TextStyle(
                  fontSize: 13.5.sp,
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
    return Ink(
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient(scheme),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 42.h,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'accounts.dashboard'.tr,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.arrow_forward_rounded,
                  size: 16.w, color: AppColors.white),
            ],
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
