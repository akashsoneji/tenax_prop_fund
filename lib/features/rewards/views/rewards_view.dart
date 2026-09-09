import 'package:flutter/material.dart';
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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
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
        const SizedBox(height: 26),
        RewardsSectionTitle('rewards.requests'.tr),
        _RequestsCard(controller: controller, data: data),
        const SizedBox(height: 18),
        _RequestPayoutCta(controller: controller),
        const SizedBox(height: 18),
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
      children: const [
        HeroSkeleton(height: 120),
        SizedBox(height: 26),
        StatGridSkeleton(),
        SizedBox(height: 18),
        CardSkeleton(lines: 4, height: 200),
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
            offset: Offset(0, (1 - t) * 18),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: AppTheme.surfaceCard(scheme, radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 2),
              child: Text(
                'rewards.what_stands'.tr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Column(
              children: [
                for (var i = 0; i < data.requirements.length; i++)
                  RequirementRow(
                    requirement: data.requirements[i],
                    showDivider: i != data.requirements.length - 1,
                  ),
              ],
            ),
            const SizedBox(height: 6),
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
            offset: Offset(0, (1 - t) * 16),
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
