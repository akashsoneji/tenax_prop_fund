import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../controllers/positions_controller.dart';
import 'account_switch_sheet.dart';

/// Compact floating P/L + account number pill for the Charts ticket header.
/// Same data and switch sheet as [PositionsAccountHeader], sized to sit on one
/// row with the symbol picker so the chart keeps its height.
class ChartAccountBadge extends StatelessWidget {
  const ChartAccountBadge({super.key, required this.controller});

  final PositionsController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(12.r);
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => AccountSwitchSheet.show(context, controller),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          child: Obx(() {
            final profit = controller.account.value.profit;
            final login = controller.tradingAccount.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FloatingPl(profit: profit),
                Container(
                  width: 1.w,
                  height: 26.h,
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  color: scheme.outlineVariant,
                ),
                _AccountLogin(login: login),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _FloatingPl extends StatelessWidget {
  const _FloatingPl({required this.profit});

  final double profit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = profit > 0
        ? AppColors.success
        : profit < 0
            ? AppColors.danger
            : scheme.onSurface;
    final sign = profit > 0 ? '+' : profit < 0 ? '-' : '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'positions.floating_pl'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.subtitle(
            color: scheme.onSurfaceVariant,
            fontSize: 9.sp,
          ),
        ),
        Text(
          '$sign\$${profit.abs().toStringAsFixed(2)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.title(color: color, fontSize: 13.sp),
        ),
      ],
    );
  }
}

class _AccountLogin extends StatelessWidget {
  const _AccountLogin({required this.login});

  final String login;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  'positions.live'.tr,
                  style: AppText.subtitle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
            Text(
              login.isEmpty ? '—' : login,
              maxLines: 1,
              style: AppText.title(color: scheme.onSurface, fontSize: 13.sp),
            ),
          ],
        ),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18.w,
          color: scheme.onSurfaceVariant,
        ),
      ],
    );
  }
}
