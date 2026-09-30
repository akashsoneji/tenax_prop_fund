import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/positions_controller.dart';
import 'account_switch_card.dart';

/// Bottom sheet listing every trading account (primary first) with live
/// balance / equity / P&L. Re-fetches the list each time it opens.
class AccountSwitchSheet extends StatelessWidget {
  const AccountSwitchSheet({super.key, required this.controller});

  final PositionsController controller;

  static void show(BuildContext context, PositionsController controller) {
    controller.refreshAccountRows();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => AccountSwitchSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            _SheetHeader(controller: controller),
            SizedBox(height: 12.h),
            Flexible(child: Obx(() => _list(context, scheme))),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, ColorScheme scheme) {
    // Snapshot every reactive value here: ListView builds items lazily during
    // layout, and reading the live RxList there can index into a list the
    // background refresh has just replaced.
    final rows = controller.accountRows.toList();
    final selectedLogin = controller.tradingAccount.value;
    final primaryId = controller.primaryAccountId;
    final loading = controller.isRefreshingAccounts.value;

    if (rows.isEmpty) {
      if (loading) return const _SheetSkeleton();
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Text(
          'positions.account_unavailable'.tr,
          textAlign: TextAlign.center,
          style: AppText.subtitle(
            color: scheme.onSurface.withValues(alpha: AppColors.alphaMuted),
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
      itemBuilder: (_, i) {
        final row = rows[i];
        return AccountSwitchCard(
          row: row,
          selected: row.login == selectedLogin,
          primary: row.id == primaryId,
          onTap: () {
            controller.switchToAccount(row);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

/// Title + hint on the left; spinner while refreshing, else account count.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.controller});

  final PositionsController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'positions.switch_account'.tr,
                style: AppText.title(color: scheme.onSurface, fontSize: 17.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                'positions.switch_account_hint'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.subtitle(
                  color:
                      scheme.onSurface.withValues(alpha: AppColors.alphaMuted),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Obx(() {
          if (controller.isRefreshingAccounts.value) {
            return SizedBox(
              width: 16.w,
              height: 16.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                color: scheme.primary,
              ),
            );
          }
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '${controller.accountRows.length}',
              style: AppText.title(color: scheme.primary, fontSize: 12.sp),
            ),
          );
        }),
      ],
    );
  }
}

class _SheetSkeleton extends StatelessWidget {
  const _SheetSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            ShimmerBox(height: 96.h, radius: 16.r),
            if (i < 2) SizedBox(height: 8.h),
          ],
        ],
      ),
    );
  }
}
