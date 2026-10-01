import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/data_state_builder.dart';
import '../../../../shared/widgets/fade_slide_in.dart';
import '../../../../shared/widgets/skeletons/skeletons.dart';
import '../../controllers/home_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/home_bento.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_live_accounts.dart';
import '../../widgets/home_quick_actions.dart';
import '../../widgets/home_sections.dart';
import '../../../../shared/theme/app_spacing.dart';

/// The Home (Portfolio) tab, driven entirely by `HomeController` (GetX). Below
/// the brand header: the account card (Floating P/L), an overview panel,
/// quick actions, live accounts, account health, recent trades, recent
/// activity and the referral banner. Live equity ticks arrive over the Pusher
/// socket and patch the controller state, which rebuilds this view through
/// `DataStateBuilder`. Theme-token driven (light/dark), localized through
/// `.tr`, staggered in with [FadeSlideIn].
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
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 28.h),
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
    final sectionGap = 22.verticalSpace;
    final labelGap = 10.verticalSpace;
    final blocks = <Widget>[HomeBento(data: data)];

    blocks
      ..add(sectionGap)
      ..add(
        HomeSectionLabel(
          'home.quick_actions'.tr,
          actionLabel: 'home.recommended'.tr,
        ),
      )
      ..add(labelGap)
      ..add(const HomeQuickActions());

    if (data.liveAccounts.isNotEmpty) {
      blocks
        ..add(sectionGap)
        ..add(HomeSectionLabel('home.live_accounts'.tr))
        ..add(labelGap)
        ..add(HomeLiveAccountsRail(accounts: data.liveAccounts));
    }

    if (data.health.isNotEmpty) {
      blocks
        ..add(sectionGap)
        ..add(
          HomeSectionLabel(
            'home.account_health'.tr,
            actionLabel: data.healthBadge.isEmpty ? null : data.healthBadge,
          ),
        )
        ..add(labelGap)
        ..add(HomeRiskOverview(items: data.health));
    }

    if (data.trades.isNotEmpty) {
      blocks
        ..add(sectionGap)
        ..add(HomeSectionLabel('home.recent_trades'.tr))
        ..add(labelGap)
        ..add(HomeRecentTrades(items: data.trades));
    }

    if (data.activity.isNotEmpty) {
      blocks
        ..add(sectionGap)
        ..add(
          HomeSectionLabel(
            'home.recent_activity'.tr,
            actionLabel: 'home.view_all'.tr,
            onAction: () => Get.toNamed(AppRoutes.notifications),
          ),
        )
        ..add(labelGap)
        ..add(HomeActivityList(items: data.activity));
    }

    blocks
      ..add(sectionGap)
      ..add(const HomeReferralPrompt());

    return [
      for (var i = 0; i < blocks.length; i++)
        FadeSlideIn(order: i, child: blocks[i]),
    ];
  }
}

/// Loading placeholder mirroring the new layout: account card, overview grid,
/// quick-action circles, live-account rail and list cards.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
      children: [
        HeroSkeleton(height: 84.h),
        Gap.vLg,
        const StatGridSkeleton(tiles: 4),
        22.verticalSpace,
        ShimmerBox(width: 130.w, height: 16.h),
        Gap.vMd,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < 4; i++)
              ShimmerBox(width: 50.w, height: 50.w, radius: 25.r),
          ],
        ),
        22.verticalSpace,
        ShimmerBox(width: 130.w, height: 16.h),
        10.verticalSpace,
        Row(
          children: [
            Expanded(
              child: ShimmerBox(height: 112.h, radius: 18.r),
            ),
            10.horizontalSpace,
            Expanded(
              child: ShimmerBox(height: 112.h, radius: 18.r),
            ),
          ],
        ),
        22.verticalSpace,
        CardSkeleton(lines: 3, height: 150.h),
        Gap.vLg,
        CardSkeleton(lines: 3, height: 150.h),
      ],
    );
  }
}
