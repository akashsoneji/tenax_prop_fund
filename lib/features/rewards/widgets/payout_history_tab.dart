import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/payout_history_controller.dart';
import '../models/reward_models.dart';
import 'payout_history_card.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// Rewards → "Payout history" tab body: status filter chips, a total count,
/// one card per payout request and a footer that shows a loader while the
/// next page is fetched (paging is triggered by the parent scroll view).
class PayoutHistoryTab extends StatelessWidget {
  const PayoutHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PayoutHistoryController>();
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterChips(controller: c),
          14.verticalSpace,
          Obx(
            () => DataStateBuilder<List<PayoutHistoryItem>>(
              state: c.state,
              onRetry: c.load,
              emptyIcon: Icons.account_balance_wallet_outlined,
              emptyTitle: 'rewards.history_empty'.tr,
              emptyMessage: 'rewards.history_empty_body'.tr,
              skeleton: const CardSkeleton(lines: 6),
              builder: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CountLabel(total: c.total > 0 ? c.total : items.length),
                  for (final item in items)
                    Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: PayoutHistoryCard(
                        item: item,
                        onCancel: () => _confirmCancel(context, c, item),
                      ),
                    ),
                  _Footer(controller: c),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    PayoutHistoryController c,
    PayoutHistoryItem item,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('rewards.history_cancel_confirm'.tr),
        content: Text('${item.requestId} · ${item.amount}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('rewards.cancel_no'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'rewards.history_cancel'.tr,
              style: AppText.base(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) c.cancel(item);
  }
}

/// Horizontally scrollable status chips (All / Pending / Approved / …).
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.controller});
  final PayoutHistoryController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36.h,
      child: Obx(() {
        final selected = controller.filter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: payoutHistoryFilters.length,
          separatorBuilder: (_, _) => Gap.hSm,
          itemBuilder: (context, i) {
            final value = payoutHistoryFilters[i];
            final isSelected = value == selected;
            return InkWell(
              onTap: () => controller.setFilter(value),
              borderRadius: BorderRadius.circular(20.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  'rewards.payout_filter_$value'.tr,
                  style: AppText.base(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? scheme.onPrimary
                        : scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: 2.w, bottom: 10.h),
      child: Text(
        'rewards.payout_history_count'.trParams({'count': '$total'}),
        style: AppText.base(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Loader while the next page loads; "all caught up" after the last page.
class _Footer extends StatelessWidget {
  const _Footer({required this.controller});
  final PayoutHistoryController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      Widget child = const SizedBox.shrink();
      if (controller.isLoadingMore.value) {
        child = SizedBox(
          width: 22.w,
          height: 22.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      } else if (!controller.hasMore) {
        child = Text(
          'referral.history_end'.tr,
          style: AppText.base(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        );
      }
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(child: child),
      );
    });
  }
}
