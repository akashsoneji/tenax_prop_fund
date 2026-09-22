import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_stat_tile.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../controllers/competitions_controller.dart';
import '../models/competition_models.dart';
import '../widgets/competition_leaderboard_card.dart';
import '../widgets/competition_prizes_card.dart';
import '../widgets/competition_register_sheet.dart';
import '../widgets/competition_rules_card.dart';

/// Detail screen for one competition: summary header, prizes, rules and the
/// leaderboard. Reads the already-loaded [CompetitionsData] from the shared
/// [CompetitionsController] (no second controller, no extra fetch) and
/// resolves the competition by the id passed through `Get.arguments`.
class CompetitionDetailView extends GetView<CompetitionsController> {
  const CompetitionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final id = Get.arguments as int?;

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      body: Obx(() {
        final competition = id == null ? null : controller.data.byId(id);
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            PinnedGradientAppBar(
              title: competition?.name ?? 'competitions.title'.tr,
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
              sliver: SliverToBoxAdapter(
                child: competition == null
                    ? const _Missing()
                    : _DetailBody(competition: competition),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DetailBody extends GetView<CompetitionsController> {
  const _DetailBody({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final description = competition.description;
    final dateRange = competition.dateRange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          order: 0,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppPill.status(
                      label: competition.statusLabel.isEmpty
                          ? competition.status.labelKey.tr
                          : competition.statusLabel,
                      color: competition.status.tone(scheme),
                      showDot: true,
                    ),
                    if (dateRange.isNotEmpty) ...[
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          dateRange,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: AppText.label(
                            fontSize: 12.sp,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Text(
                    description,
                    style: AppText.body(
                      fontSize: 13.sp,
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: AppStatTile(
                        label: 'competitions.prize_pool'.tr,
                        value: competition.prizePool,
                        valueFontSize: 15.sp,
                      ),
                    ),
                    Expanded(
                      child: AppStatTile(
                        label: 'competitions.entries'.tr,
                        value: '${competition.entriesCount}',
                        valueFontSize: 15.sp,
                      ),
                    ),
                    Expanded(
                      child: AppStatTile(
                        label: 'competitions.my_score'.tr,
                        value: competition.myScore ?? '—',
                        valueFontSize: 15.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),
        FadeSlideIn(order: 1, child: SectionHeader('competitions.prizes'.tr)),
        FadeSlideIn(
          order: 2,
          child: CompetitionPrizesCard(prizes: competition.prizes),
        ),
        if (competition.rules.isNotEmpty) ...[
          SizedBox(height: 24.h),
          FadeSlideIn(order: 3, child: SectionHeader('competitions.rules'.tr)),
          FadeSlideIn(
            order: 4,
            child: CompetitionRulesCard(rules: competition.rules),
          ),
        ],
        SizedBox(height: 24.h),
        FadeSlideIn(
          order: 5,
          child: SectionHeader('competitions.leaderboard'.tr),
        ),
        FadeSlideIn(
          order: 6,
          child: CompetitionLeaderboardCard(rows: competition.leaderboard),
        ),
        if (competition.canRegister) ...[
          SizedBox(height: 24.h),
          FadeSlideIn(
            order: 7,
            child: Obx(
              () => _DetailCta(
                registered: controller.isRegistered(competition),
                onRegister: () => CompetitionRegisterSheet.show(
                  context,
                  competition: competition,
                  accounts: controller.data.accounts,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailCta extends StatelessWidget {
  const _DetailCta({required this.registered, required this.onRegister});

  final bool registered;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: Material(
        color: registered
            ? scheme.primary.withValues(alpha: 0.14)
            : scheme.primary,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: registered ? null : onRegister,
          borderRadius: BorderRadius.circular(14.r),
          child: Center(
            child: Text(
              registered
                  ? 'competitions.registered'.tr
                  : 'competitions.register'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.title(
                fontSize: 15.sp,
                color: registered ? scheme.primary : scheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the screen is opened without a resolvable competition (e.g. a
/// deep link after the list state was disposed).
class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Center(
        child: Text(
          'competitions.empty'.tr,
          textAlign: TextAlign.center,
          style: AppText.body(
            fontSize: 13.sp,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
