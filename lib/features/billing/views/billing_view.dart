import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/billing_controller.dart';
import '../models/billing_models.dart';
import '../widgets/billing_filter_tabs.dart';
import '../widgets/billing_transaction_list.dart';

/// The Billing history screen. Composed of:
///
///  * A pinned purple gradient app bar + a 2x2 summary stat grid on a matching
///    gradient block (Paid / Refunded / Net / Invoices).
///  * Segmented filter tabs (All / Challenge / Add-on / Refund).
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
// Loaded body: full-bleed gradient stat grid + filter tabs + transaction list.
// ---------------------------------------------------------------------------
class _BillingBody extends StatelessWidget {
  const _BillingBody({required this.controller, required this.data});
  final BillingController controller;
  final BillingData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatGridBanner(stats: data.stats),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(
                () => BillingFilterTabs(
                  selected: controller.filter.value,
                  onChanged: controller.setFilter,
                ),
              ),
              SizedBox(height: 18.h),
              Obx(
                () => BillingTransactionList(
                  transactions: controller.filteredTransactions(data),
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroSkeleton(height: 120.h),
          SizedBox(height: 20.h),
          const StatGridSkeleton(),
          SizedBox(height: 20.h),
          const ListSkeleton(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient stat-grid banner (sits under the pinned bar)
// ---------------------------------------------------------------------------
class _StatGridBanner extends StatelessWidget {
  const _StatGridBanner({required this.stats});
  final List<BillingStat> stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.heroGradient(scheme)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 22.h),
        child: _StatGrid(stats: stats),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat grid
// ---------------------------------------------------------------------------

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final List<BillingStat> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCell(stat: stats[0])),
            SizedBox(width: 12.w),
            Expanded(child: _StatCell(stat: stats[1])),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _StatCell(stat: stats[2])),
            SizedBox(width: 12.w),
            Expanded(child: _StatCell(stat: stats[3])),
          ],
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});
  final BillingStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Text(
            stat.label,
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white.withValues(alpha: 0.75),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
