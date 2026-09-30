import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_count_up_text.dart';
import '../models/dashboard_models.dart';
import 'home_bento.dart';

/// Horizontal rail of live accounts — each card shows the account id,
/// currency, a live pulse, the animated equity and P/L vs balance.
class HomeLiveAccountsRail extends StatelessWidget {
  const HomeLiveAccountsRail({super.key, required this.accounts});
  final List<DashboardAccount> accounts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: accounts.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (_, i) => SizedBox(
          width: 180.w,
          child: _LiveAccountCard(account: accounts[i]),
        ),
      ),
    );
  }
}

class _LiveAccountCard extends StatelessWidget {
  const _LiveAccountCard({required this.account});
  final DashboardAccount account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.58);
    final pnlMinor = account.equityMinor - account.balanceMinor;
    final isProfit = pnlMinor >= 0;
    final pnlColor = isProfit ? AppColors.success : AppColors.danger;
    final sign = isProfit ? '+' : '−';

    return Container(
      decoration: AppTheme.surfaceCard(scheme, radius: 18),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4.w, color: pnlColor),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 11.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${'home.account_hash'.tr}${account.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.subtitle(color: muted, fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      _CurrencyChip(currency: account.currency),
                      const Spacer(),
                      const HomePulseDot(active: true),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AppCountUpText(
                      value: account.equityMinor.toDouble(),
                      formatter: (v) =>
                          formatMinorMoney(v.round(), account.currency),
                      style: AppText.value(
                        color: scheme.onSurface,
                        fontSize: 18.sp,
                      ).copyWith(letterSpacing: -0.6),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isProfit
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13.w,
                        color: pnlColor,
                      ),
                      SizedBox(width: 3.w),
                      Flexible(
                        child: Text(
                          '$sign${formatMinorMoney(pnlMinor.abs(), account.currency)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.title(color: pnlColor, fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          'home.vs_balance'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label(color: muted, fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        currency,
        style: AppText.title(color: scheme.primary, fontSize: 9.5.sp),
      ),
    );
  }
}
