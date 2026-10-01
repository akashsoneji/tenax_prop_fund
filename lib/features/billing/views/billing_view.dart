import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/billing_controller.dart';
import '../models/billing_models.dart';
import '../widgets/billing_filter_dropdown.dart';
import '../widgets/billing_transaction_list.dart';

/// The Billing history screen. Composed of:
///
///  * A pinned purple gradient app bar with a compact stat strip pinned right
///    beneath it (Paid / Refunded / Net / Invoices), so the summary stays
///    visible while the list scrolls.
///  * Type + status filter dropdowns.
///  * The filtered transaction list.
///
/// Fully theme-driven; all data + filter logic come from [BillingController].
class BillingView extends StatelessWidget {
  const BillingView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<BillingController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'billing.title'.tr),
          Obx(() {
            final data = c.state.valueOrNull;
            if (data == null || data.stats.length < 4) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverPersistentHeader(
              pinned: true,
              delegate: _StatStripDelegate(
                stats: data.stats,
                extent: _StatStrip.height,
              ),
            );
          }),
          SliverToBoxAdapter(
            child: Obx(
              () => DataStateBuilder<BillingData>(
                state: c.state,
                onRetry: c.load,
                skeleton: const _BillingSkeleton(),
                builder: (data) => _BillingBody(controller: c, data: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded body: filter dropdowns + transaction list.
// ---------------------------------------------------------------------------
class _BillingBody extends StatelessWidget {
  const _BillingBody({required this.controller, required this.data});
  final BillingController controller;
  final BillingData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => BillingFilterDropdown<BillingFilter>(
                    selected: controller.filter.value,
                    values: BillingFilter.values,
                    labelOf: (f) => f.labelKey.tr,
                    isDefault: (f) => f == BillingFilter.all,
                    onChanged: controller.setFilter,
                    icon: Icons.category_outlined,
                  ),
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Obx(
                  () => BillingFilterDropdown<BillingStatusFilter>(
                    selected: controller.status.value,
                    values: BillingStatusFilter.values,
                    labelOf: (s) => s.labelKey.tr,
                    isDefault: (s) => s == BillingStatusFilter.all,
                    onChanged: controller.setStatus,
                    icon: Icons.tune_rounded,
                  ),
                ),
              ),
            ],
          ),
          18.verticalSpace,
          Obx(
            () => BillingTransactionList(
              transactions: controller.filteredTransactions(data),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton matching the screen's shape.
// ---------------------------------------------------------------------------
class _BillingSkeleton extends StatelessWidget {
  const _BillingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroSkeleton(height: 64.h),
          20.verticalSpace,
          const ListSkeleton(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pinned stat strip (sits flush under the pinned app bar)
// ---------------------------------------------------------------------------
class _StatStripDelegate extends SliverPersistentHeaderDelegate {
  _StatStripDelegate({required this.stats, required this.extent});

  final List<BillingStat> stats;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _StatStrip(stats: stats);
  }

  @override
  bool shouldRebuild(_StatStripDelegate oldDelegate) =>
      oldDelegate.stats != stats || oldDelegate.extent != extent;
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.stats});
  final List<BillingStat> stats;

  static double get height => 78.h;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = Container(
      width: 1,
      height: 28.h,
      color: AppColors.white.withValues(alpha: 0.16),
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.18),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 14.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) divider,
              Expanded(child: _StatCell(stat: stats[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});
  final BillingStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.label.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              fontSize: 10.5.sp,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
          ),
          3.verticalSpace,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.value,
              maxLines: 1,
              style: AppText.value(fontSize: 15.sp, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
