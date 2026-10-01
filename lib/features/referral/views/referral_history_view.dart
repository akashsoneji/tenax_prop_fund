import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/referral_history_controller.dart';
import '../models/referral_models.dart';
import '../widgets/referral_commission_row.dart';
import '../../../shared/theme/app_text.dart';

/// Referral commission history with infinite scroll: the next page is fetched
/// when a row within the last [ReferralHistoryController.prefetchThreshold]
/// rows is built.
class ReferralHistoryView extends GetView<ReferralHistoryController> {
  const ReferralHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = controller;
    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      body: RefreshIndicator(
        onRefresh: c.refreshData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            PinnedGradientAppBar(title: 'referral.history_title'.tr),
            Obx(() {
              final state = c.state;
              final items = state.valueOrNull;
              if (items == null) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
                    child: DataStateBuilder<List<Referral>>(
                      state: state,
                      onRetry: c.load,
                      emptyIcon: Icons.receipt_long_rounded,
                      emptyTitle: 'referral.history_empty_title'.tr,
                      emptyMessage: 'referral.history_empty_hint'.tr,
                      skeleton: const CardSkeleton(lines: 6),
                      builder: (_) => const SizedBox.shrink(),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                sliver: SliverList.builder(
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _SummaryHeader(
                        total: c.total > 0 ? c.total : items.length,
                      );
                    }
                    final rowIndex = index - 1;
                    c.onRowBuilt(rowIndex);
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _RowCard(referral: items[rowIndex]),
                    );
                  },
                ),
              );
            }),
            SliverToBoxAdapter(child: _ListFooter(controller: c)),
          ],
        ),
      ),
    );
  }
}

/// "N commissions" caption above the list, using the server-side total.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, size: 16.w, color: scheme.primary),
          6.horizontalSpace,
          Expanded(
            child: Text(
              'referral.history_count'.trParams({'count': '$total'}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.base(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Each commission sits in its own card so long lists scan cleanly.
class _RowCard extends StatelessWidget {
  const _RowCard({required this.referral});
  final Referral referral;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = AppTheme.surfaceCard(scheme, radius: 16);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: card.color,
        gradient: card.gradient,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ReferralCommissionRow(referral: referral),
    );
  }
}

/// Loader while the next page is fetched; "You're all caught up" once the
/// last page is in.
class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.controller});
  final ReferralHistoryController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final hasRows = controller.state.valueOrNull?.isNotEmpty ?? false;
      Widget child = const SizedBox.shrink();
      if (controller.isLoadingMore.value) {
        child = SizedBox(
          width: 22.w,
          height: 22.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      } else if (hasRows && !controller.hasMore) {
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
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
        child: Center(child: child),
      );
    });
  }
}
