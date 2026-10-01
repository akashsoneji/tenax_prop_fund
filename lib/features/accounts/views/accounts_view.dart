import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/accounts_controller.dart';
import '../models/accounts_models.dart';
import '../widgets/account_center_hero.dart';
import '../widgets/account_list_card.dart';
import '../widgets/accounts_search_bar.dart';
import '../widgets/accounts_status_tabs.dart';
import '../../../shared/theme/app_spacing.dart';

/// "Account Center" screen — a mobile-native take on the web `/app/accounts`
/// page: gradient hero with stat cards + CTAs, status tabs with count badges,
/// a search + plan filter toolbar, and the filtered account list. Loading /
/// error / empty are handled by [DataStateBuilder] over the controller's
/// `DataState<AccountsData>`; the tab / search / plan switches read the loaded
/// data through [Obx].
class AccountsView extends StatelessWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<AccountsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: scheme.primary,
          onRefresh: c.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: Text(
                    'accounts.app_bar'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(
                      color: scheme.onSurface,
                      fontSize: 22.sp,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
                  child: Obx(
                    () => DataStateBuilder<AccountsData>(
                      state: c.state,
                      onRetry: c.load,
                      skeleton: const _AccountsSkeleton(),
                      emptyActionLabel: 'accounts.start_challenge'.tr,
                      onEmptyAction: () => Get.toNamed(AppRoutes.challenge),
                      builder: (data) =>
                          _AccountsBody(controller: c, data: data),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded body: hero + tabs + toolbar + list.
// ---------------------------------------------------------------------------
class _AccountsBody extends StatelessWidget {
  const _AccountsBody({required this.controller, required this.data});
  final AccountsController controller;
  final AccountsData data;

  @override
  Widget build(BuildContext context) {
    final labels = {for (final tab in AccountTab.values) tab: tab.labelKey.tr};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountCenterHero(
          ownedTotal: data.ownedTotal,
          active: data.counts.active,
          funded: data.counts.funded,
          provisioning: data.provisioning,
          trialEnabled: data.trialEnabled,
          onFreeTrial: () => Get.toNamed(AppRoutes.challenge),
          onStartChallenge: () => Get.toNamed(AppRoutes.challenge),
        ),
        14.verticalSpace,
        Obx(
          () => AccountsStatusTabs(
            labels: labels,
            counts: data.counts,
            selected: controller.selectedTab.value,
            onChanged: controller.selectTab,
          ),
        ),
        Gap.vMd,
        AccountsSearchBar(
          hintText: 'accounts.search_hint'.tr,
          allPlansLabel: 'accounts.all_plans'.tr,
          planOptions: data.planOptions,
          selectedPlan: controller.planFilter.value,
          onQueryChanged: controller.setQuery,
          onPlanChanged: controller.setPlanFilter,
        ),
        14.verticalSpace,
        Obx(() {
          final rows = controller.visibleAccounts(data);
          if (rows.isEmpty) return const _NoMatches();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++)
                _Entrance(
                  index: i,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: AccountListCard(
                      account: rows[i],
                      onTrade: () => controller.tradeWithAccount(rows[i]),
                      onDashboard: () => Get.toNamed(
                        AppRoutes.account,
                        arguments: {'id': rows[i].id},
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty result of the current filters (distinct from no accounts at all).
// ---------------------------------------------------------------------------
class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 36.h),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 44.w,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          Gap.vMd,
          Text(
            'accounts.no_matches'.tr,
            style: AppText.base(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
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
class _AccountsSkeleton extends StatelessWidget {
  const _AccountsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroSkeleton(height: 160.h),
        14.verticalSpace,
        ShimmerBox(height: 34.h, radius: 18.r),
        Gap.vMd,
        ShimmerBox(height: 42.h, radius: 12.r),
        14.verticalSpace,
        const AccountCardSkeleton(),
        10.verticalSpace,
        const AccountCardSkeleton(),
        10.verticalSpace,
        const AccountCardSkeleton(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Subtle staggered fade/slide entrance mirroring rewards_view.dart.
// ---------------------------------------------------------------------------
class _Entrance extends StatelessWidget {
  const _Entrance({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: Interval(
        (index * 0.08).clamp(0.0, 0.6),
        1.0,
        curve: AppMotion.enter,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
