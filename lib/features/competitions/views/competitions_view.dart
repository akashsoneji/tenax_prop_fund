import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_info_banner.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/key_value_row.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/competitions_controller.dart';
import '../models/competition_models.dart';
import '../widgets/competition_hero_card.dart';

/// Competitions screen — gradient hero card with the active competition,
/// a Prizes card, a Competition-rules card and a closing info banner.
/// Loading/error/empty are handled by [DataStateBuilder] on the controller's
/// `DataState<CompetitionInfo>`; the real UI reads the loaded data through
/// [Obx] for the register CTA switch.
class CompetitionsView extends StatelessWidget {
  const CompetitionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<CompetitionsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'competitions.title'.tr),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
            sliver: SliverToBoxAdapter(
              child: Obx(
                () => DataStateBuilder<CompetitionInfo>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const _CompetitionsSkeleton(),
                  builder: (info) => _CompetitionsBody(controller: c, info: info),
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
// Loaded body: hero card, prizes, rules and the closing info banner.
// ---------------------------------------------------------------------------
class _CompetitionsBody extends StatelessWidget {
  const _CompetitionsBody({required this.controller, required this.info});
  final CompetitionsController controller;
  final CompetitionInfo info;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          order: 0,
          child: Obx(
            () => CompetitionHeroCard(
              info: info,
              registered: controller.registered.value,
              onRegister: controller.register,
            ),
          ),
        ),
        SizedBox(height: 26.h),
        FadeSlideIn(
          order: 1,
          child: SectionHeader('competitions.prizes'.tr),
        ),
        FadeSlideIn(
          order: 2,
          child: RulesCard(
            children: [
              for (var i = 0; i < info.prizes.length; i++)
                KeyValueRow(
                  label: info.prizes[i].place,
                  value: info.prizes[i].reward,
                  showDivider: i != info.prizes.length - 1,
                ),
            ],
          ),
        ),
        SizedBox(height: 26.h),
        FadeSlideIn(
          order: 3,
          child: SectionHeader('competitions.rules_differ'.tr),
        ),
        FadeSlideIn(
          order: 4,
          child: RulesCard(
            children: [
              for (var i = 0; i < info.rules.length; i++)
                KeyValueRow(
                  label: info.rules[i].label,
                  value: info.rules[i].value,
                  showDivider: i != info.rules.length - 1,
                ),
            ],
          ),
        ),
        SizedBox(height: 22.h),
        FadeSlideIn(
          order: 5,
          child: AppInfoBanner(
            tone: BannerTone.warning,
            title: 'competitions.not_evaluation'.tr,
            body: 'competitions.not_evaluation_body'.tr,
          ),
        ),
      ],
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
        HeroSkeleton(height: 300.h),
        SizedBox(height: 26.h),
        ShimmerBox(width: 140.w, height: 16.h),
        SizedBox(height: 14.h),
        CardSkeleton(lines: 5, height: 200.h),
        SizedBox(height: 26.h),
        ShimmerBox(width: 140.w, height: 16.h),
        SizedBox(height: 14.h),
        CardSkeleton(lines: 5, height: 200.h),
      ],
    );
  }
}
