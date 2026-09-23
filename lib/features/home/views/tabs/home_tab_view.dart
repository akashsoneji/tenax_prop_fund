import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/data_state_builder.dart';
import '../../../../shared/widgets/fade_slide_in.dart';
import '../../../../shared/widgets/skeletons/skeletons.dart';
import '../../controllers/home_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/home_bento.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_sections.dart';

/// The Home (Portfolio) tab — a bento-grid dashboard driven entirely by
/// `HomeController` (GetX). A glass brand header sits above an asymmetric grid:
/// a large gradient equity tile, paired balance/accounts tiles, KPI tiles, a
/// live-account grid, quick actions, risk overview, recent activity/trades and
/// a referral prompt. Live equity ticks arrive over the Pusher socket and patch
/// the controller state, which rebuilds this view through `DataStateBuilder`.
/// Fully theme-token driven (light/dark), localized through `.tr`, staggered
/// in with [FadeSlideIn].
class HomeTabView extends GetView<HomeController> {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: Obx(
                () => DataStateBuilder<DashboardData>(
                  state: controller.state,
                  onRetry: controller.load,
                  skeleton: const _HomeSkeleton(),
                  emptyTitle: 'home.no_dashboard'.tr,
                  emptyMessage: 'home.no_dashboard_body'.tr,
                  emptyActionLabel: 'home.start_challenge'.tr,
                  onEmptyAction: () => Get.toNamed(AppRoutes.challenge),
                  builder: (data) => RefreshIndicator(
                    onRefresh: controller.refreshData,
                    color: scheme.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 24.h),
                      children: _sections(data),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(DashboardData data) {
    final blocks = <Widget>[HomeBento(data: data)];

    if (data.liveAccounts.isNotEmpty) {
      blocks
        ..add(SizedBox(height: 18.h))
        ..add(HomeSectionLabel('home.live_accounts'.tr))
        ..add(SizedBox(height: 10.h))
        ..add(LiveAccountBentoGrid(accounts: data.liveAccounts));
    }

    blocks
      ..add(SizedBox(height: 18.h))
      ..add(HomeSectionLabel('home.quick_actions'.tr,
          actionLabel: 'home.recommended'.tr))
      ..add(SizedBox(height: 12.h))
      ..add(const _QuickActions());

    if (data.health.isNotEmpty) {
      blocks
        ..add(SizedBox(height: 18.h))
        ..add(HomeSectionLabel('home.account_health'.tr,
            actionLabel: data.healthBadge.isEmpty ? null : data.healthBadge))
        ..add(SizedBox(height: 10.h))
        ..add(HomeRiskOverview(items: data.health));
    }

    if (data.activity.isNotEmpty) {
      blocks
        ..add(SizedBox(height: 18.h))
        ..add(HomeSectionLabel('home.recent_activity'.tr,
            actionLabel: 'home.view_all'.tr,
            onAction: () => Get.toNamed(AppRoutes.notifications)))
        ..add(SizedBox(height: 10.h))
        ..add(HomeActivityList(items: data.activity));
    }

    if (data.trades.isNotEmpty) {
      blocks
        ..add(SizedBox(height: 18.h))
        ..add(HomeSectionLabel('home.recent_trades'.tr))
        ..add(SizedBox(height: 10.h))
        ..add(HomeRecentTrades(items: data.trades));
    }

    blocks
      ..add(SizedBox(height: 18.h))
      ..add(const HomeReferralPrompt());

    return [
      for (var i = 0; i < blocks.length; i++)
        FadeSlideIn(order: i, child: blocks[i]),
    ];
  }
}

// ---------------------------------------------------------------------------
// Quick actions: four shortcut tiles (view-local — small + navigation only)
// ---------------------------------------------------------------------------
class _QuickAction {
  const _QuickAction(this.route, this.labelKey, this.icon);
  final String route;
  final String labelKey;
  final IconData icon;
}

const _quickActions = <_QuickAction>[
  _QuickAction(AppRoutes.challenge, 'home.qa.challenge', Icons.add_rounded),
  _QuickAction(
      AppRoutes.profileKyc, 'home.qa.kyc', Icons.verified_user_rounded),
  _QuickAction(AppRoutes.rewards, 'home.qa.reward', Icons.credit_card_rounded),
  _QuickAction(
      AppRoutes.tradingRules, 'home.qa.rules', Icons.description_rounded),
];

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _quickActions.length; i++) ...[
          if (i > 0) SizedBox(width: 12.w),
          Expanded(child: _QuickActionTile(action: _quickActions[i])),
        ],
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => Get.toNamed(action.route),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: AppTheme.surfaceCard(scheme, radius: 16),
          child: Column(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(action.icon, color: scheme.primary, size: 20.w),
              ),
              SizedBox(height: 8.h),
              Text(
                action.labelKey.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
      children: [
        CardSkeleton(lines: 2, height: 150.h),
        SizedBox(height: 16.h),
        const StatGridSkeleton(tiles: 4),
        SizedBox(height: 22.h),
        const CardSkeleton(lines: 3),
        SizedBox(height: 16.h),
        const CardSkeleton(lines: 2),
      ],
    );
  }
}
