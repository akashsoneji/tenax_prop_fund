import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_count_up_text.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../accounts/services/primary_account_service.dart';
import '../models/dashboard_models.dart';
import 'home_bento.dart';

/// Horizontal rail of compact live-account cards — account id, live pulse,
/// animated equity, P/L vs balance and currency.
class HomeLiveAccountsRail extends StatelessWidget {
  const HomeLiveAccountsRail({super.key, required this.accounts});
  final List<DashboardAccount> accounts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: accounts.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (_, i) => SizedBox(
          width: 150.w,
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
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: pnlColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_rounded,
                    size: 13.w, color: pnlColor),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Obx(
                  () => Text(
                    '#${_accountNumber(account)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(color: muted, fontSize: 12.sp),
                  ),
                ),
              ),
              const HomePulseDot(active: true),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppCountUpText(
              value: account.equityMinor.toDouble(),
              formatter: (v) => formatMinorMoney(v.round(), account.currency),
              style: AppText.value(color: scheme.onSurface, fontSize: 16.sp)
                  .copyWith(letterSpacing: -0.5),
            ),
          ),
          Row(
            children: [
              Flexible(
                child: AppPill(
                  label:
                      '$sign${formatMinorMoney(pnlMinor.abs(), account.currency)}',
                  color: pnlColor,
                  fontSize: 10.5,
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  leading: Icon(
                    isProfit
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 11.w,
                    color: pnlColor,
                  ),
                  leadingGap: 2,
                ),
              ),
              SizedBox(width: 6.w),
              _CurrencyChip(currency: account.currency),
            ],
          ),
        ],
      ),
    );
  }
}

/// The MT5 account number for [account]. `/dashboard` usually omits it, so it
/// is looked up by id in the MT5 accounts list (same id space); the raw id is
/// the last resort until that background fetch lands.
String _accountNumber(DashboardAccount account) {
  if (account.login.isNotEmpty) return account.login;
  if (Get.isRegistered<PrimaryAccountService>()) {
    final match = Get.find<PrimaryAccountService>()
        .accounts
        .firstWhereOrNull((a) => a.id == account.id);
    if (match != null && match.login.isNotEmpty) return match.login;
  }
  return '${account.id}';
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
