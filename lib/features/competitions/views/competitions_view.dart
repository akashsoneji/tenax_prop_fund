import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/competitions_controller.dart';
import '../models/competition_models.dart';
import '../widgets/competition_card.dart';
import '../widgets/competition_register_sheet.dart';
import '../widgets/competition_status_tabs.dart';
import '../widgets/competitions_hero.dart';

/// Competitions screen — cash-pool hero, a status filter and one card per
/// competition from `GET /growth/competitions`. Loading/error/empty come from
/// [DataStateBuilder] on the controller's `DataState<CompetitionsData>`.
class CompetitionsView extends GetView<CompetitionsController> {
  const CompetitionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            PinnedGradientAppBar(title: 'competitions.title'.tr),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
              sliver: SliverToBoxAdapter(
                child: Obx(
                  () => DataStateBuilder<CompetitionsData>(
                    state: controller.state,
                    onRetry: controller.load,
                    skeleton: const _CompetitionsSkeleton(),
                    builder: (data) => _CompetitionsBody(data: data),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded body: hero, status tabs and the filtered competition list.
// ---------------------------------------------------------------------------
class _CompetitionsBody extends GetView<CompetitionsController> {
  const _CompetitionsBody({required this.data});

  final CompetitionsData data;

  @override
  Widget build(BuildContext context) {
    final liveCount = data.filter(CompetitionStatus.live.key).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          order: 0,
          child: CompetitionsHero(
            stats: data.stats,
            total: data.competitions.length,
            liveCount: liveCount,
          ),
        ),
        SizedBox(height: 20.h),
        FadeSlideIn(
          order: 1,
          child: Obx(
            () => CompetitionStatusTabs(
              selected: controller.statusFilter.value,
              onSelected: controller.setStatusFilter,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Obx(() {
          final visible = controller.visible;
          if (visible.isEmpty) return const _FilterEmpty();
          return ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            separatorBuilder: (_, _) => SizedBox(height: 14.h),
            itemBuilder: (context, index) {
              final competition = visible[index];
              return FadeSlideIn(
                order: index + 2,
                child: Obx(
                  () => CompetitionCard(
                    competition: competition,
                    registered: controller.isRegistered(competition),
                    registering: controller.isRegistering(competition),
                    onRegister: () => CompetitionRegisterSheet.show(
                      context,
                      competition: competition,
                      accounts: data.accounts,
                    ),
                    onTap: () => Get.toNamed(
                      AppRoutes.competitionDetail,
                      arguments: competition.id,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

/// Shown when the active status tab has no competitions (the screen-level
/// empty state is handled by [DataStateBuilder]).
class _FilterEmpty extends StatelessWidget {
  const _FilterEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 34.w,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(height: 12.h),
          Text(
            'competitions.empty'.tr,
            textAlign: TextAlign.center,
            style: AppText.body(
              fontSize: 13.sp,
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
class _CompetitionsSkeleton extends StatelessWidget {
  const _CompetitionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroSkeleton(height: 74.h),
        SizedBox(height: 20.h),
        ShimmerBox(width: 240.w, height: 40.h),
        SizedBox(height: 16.h),
        CardSkeleton(lines: 3, height: 190.h),
        SizedBox(height: 14.h),
        CardSkeleton(lines: 3, height: 190.h),
        SizedBox(height: 14.h),
        CardSkeleton(lines: 3, height: 190.h),
      ],
    );
  }
}
