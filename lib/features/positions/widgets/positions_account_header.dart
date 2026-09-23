import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../accounts/models/accounts_models.dart';
import '../controllers/positions_controller.dart';

/// The live P&L header above the Positions/Trade tabs, mirroring the
/// white_label vantage trade screen: a big floating P&L figure on the left and
/// a tappable account pill (login + LIVE badge) on the right that opens the
/// account switch sheet.
class PositionsAccountHeader extends StatelessWidget {
  const PositionsAccountHeader({super.key, required this.controller});

  final PositionsController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Obx(() {
        final account = controller.account.value;
        final profit = account.profit;
        final profitColor = profit > 0
            ? AppColors.successBright
            : profit < 0
                ? AppColors.dangerBright
                : Colors.white;
        final login = controller.tradingAccount.value;
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      
                      Flexible(
                        child: Text(
                          'positions.floating_pl'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.subtitle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '\$${profit.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(
                      color: profitColor,
                      fontSize: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            _AccountPill(
              login: login,
              onTap: () => _showSwitchSheet(context),
            ),
          ],
        );
      }),
    );
  }


  void _showSwitchSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'positions.switch_account'.tr,
                textAlign: TextAlign.center,
                style: AppText.title(
                  color: scheme.onSurface,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Flexible(
                child: Obx(() {
                  final rows = controller.accountRows;
                  if (rows.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Text(
                        'positions.account_unavailable'.tr,
                        textAlign: TextAlign.center,
                        style: AppText.subtitle(
                          color: scheme.onSurface
                              .withValues(alpha: AppColors.alphaMuted),
                          fontSize: 13.sp,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8.h),
                    itemBuilder: (_, i) => _AccountSheetRow(
                      row: rows[i],
                      selected:
                          rows[i].login == controller.tradingAccount.value,
                      onTap: () {
                        controller.switchToAccount(rows[i]);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rounded account pill: wallet icon chip + login number + LIVE badge.
class _AccountPill extends StatelessWidget {
  const _AccountPill({required this.login, required this.onTap});

  final String login;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(6.w, 5.h, 8.w, 5.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24.r),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 14.w,
                  color: AppColors.brandPurple,
                ),
              ),
              SizedBox(width: 7.w),
              Text(
                login.isEmpty ? '—' : login,
                style: AppText.title(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 7.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'positions.live'.tr,
                  style: AppText.title(
                    color: AppColors.accent,
                    fontSize: 10.sp,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18.w,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );

  }
}

/// One selectable account row inside the switch sheet.
class _AccountSheetRow extends StatelessWidget {
  const _AccountSheetRow({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final AccountRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.08)
                : scheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.45)
                  : scheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.login,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(
                        color: scheme.onSurface,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${row.planName} · ${row.accountSize}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.subtitle(
                        color: scheme.onSurface
                            .withValues(alpha: AppColors.alphaMuted),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (row.statusLabel.isNotEmpty)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    row.statusLabel,
                    style: AppText.subtitle(
                      color: scheme.primary,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              if (selected) ...[
                SizedBox(width: 8.w),
                Icon(
                  Icons.check_circle_rounded,
                  size: 18.w,
                  color: scheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
