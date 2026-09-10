import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/rewards_controller.dart';
import '../models/reward_models.dart';
import '../widgets/info_banner.dart';
import '../widgets/requirement_row.dart';
import '../widgets/request_payout_sheet.dart';
import '../widgets/section_title.dart';
import '../widgets/staggered_grid.dart';
import '../widgets/stat_tile.dart';

/// Full Rewards screen. Composed of:
///
///  * Purple gradient hero header with the back button.
///  * 2x2 stat grid (Withdrawable / Pending / Paid out / Your share).
///  * "Requests" section — the blocking-issues card and the CTA.
///  * KYC name-match reminder banner.
///
/// Loading/error/empty are handled by [DataStateBuilder] on the controller's
/// `DataState<RewardsData>`; the real UI reads the loaded data — swap the
/// repository for the real API later without touching the layout.
class RewardsView extends StatelessWidget {
  const RewardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<RewardsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'rewards.title'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
              child: Obx(
                () => DataStateBuilder<RewardsData>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const _RewardsSkeleton(),
                  builder: (data) => _RewardsBody(controller: c, data: data),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded body.
// ---------------------------------------------------------------------------
class _RewardsBody extends StatelessWidget {
  const _RewardsBody({required this.controller, required this.data});
  final RewardsController controller;
  final RewardsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatGrid(data: data),
        SizedBox(height: 26.h),
        RewardsSectionTitle('rewards.requests'.tr),
        _RequestsCard(controller: controller, data: data),
        SizedBox(height: 18.h),
        _RequestPayoutCta(controller: controller),
        SizedBox(height: 18.h),
        InfoBanner(
          variant: InfoBannerVariant.warning,
          title: 'rewards.name_match_id'.tr,
          body: 'rewards.name_match_id_body'.tr,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton matching the screen's shape.
// ---------------------------------------------------------------------------
class _RewardsSkeleton extends StatelessWidget {
  const _RewardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroSkeleton(height: 120.h),
        SizedBox(height: 26.h),
        const StatGridSkeleton(),
        SizedBox(height: 18.h),
        CardSkeleton(lines: 4, height: 200.h),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2x2 stat grid — animated stagger
// ---------------------------------------------------------------------------
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.data});
  final RewardsData data;

  @override
  Widget build(BuildContext context) {
    final w = data.withdrawable;
    final p = data.pending;
    final paid = data.paidOut;
    final share = data.yourShare;

    return StaggeredGrid(
      children: [
        StatTile(
          label: 'rewards.withdrawable'.tr,
          value: w.amountUsd,
          tone: StatTileTone.green,
          trailingIcon: Icons.tune_rounded,
        ),
        StatTile(
          label: 'rewards.pending'.tr,
          value: p.amountUsd,
          tone: StatTileTone.amber,
          trailingIcon: Icons.tune_rounded,
        ),
        StatTile(
          label: 'rewards.paid_out'.tr,
          value: paid.amountUsd,
          tone: StatTileTone.purple,
          trailingIcon: Icons.tune_rounded,
        ),
        StatTile(
          label: 'rewards.your_share'.tr,
          value: '${share.percent}%',
          tone: StatTileTone.blue,
          trailingIcon: Icons.tune_rounded,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Requests" card — title, requirement rows, blocking-issues banner.
// ---------------------------------------------------------------------------
class _RequestsCard extends StatelessWidget {
  const _RequestsCard({required this.controller, required this.data});
  final RewardsController controller;
  final RewardsData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18.h),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
        decoration: AppTheme.surfaceCard(scheme, radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 6.h, top: 2.h),
              child: Text(
                'rewards.what_stands'.tr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Column(
              children: [
                for (var i = 0; i < data.requirements.length; i++)
                  RequirementRow(
                    requirement: data.requirements[i],
                    showDivider: i != data.requirements.length - 1,
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Builder(builder: (context) {
              final n = controller.blockingCount(data);
              if (n == 0) return const SizedBox.shrink();
              return InfoBanner(
                title: 'rewards.two_things_blocking'.tr.replaceFirst('Two', '$n'),
                body: 'rewards.two_things_blocking_body'.tr,
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA
// ---------------------------------------------------------------------------
class _RequestPayoutCta extends StatelessWidget {
  const _RequestPayoutCta({required this.controller});
  final RewardsController controller;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: const Interval(0.25, 1.0, curve: AppMotion.enter),
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16.h),
            child: child,
          ),
        );
      },
      child: AppGradientButton(
        label: 'rewards.request_payout'.tr,
        icon: Icons.account_balance_wallet_rounded,
        onPressed: () {
          controller.openPayoutSheet();
          _showRequestSheet(context);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet plumbing
// ---------------------------------------------------------------------------
void _showRequestSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => const RequestPayoutSheet(),
  );
}
