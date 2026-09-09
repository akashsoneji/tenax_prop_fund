import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/flavor/flavor_resolver.dart';
import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/app_segmented_control.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/key_value_row.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/challenge_controller.dart';
import '../models/challenge_models.dart';
import '../widgets/challenge_bottom_bar.dart';
import '../widgets/challenge_plan_card.dart';

/// Choose a challenge — a mode toggle (Paid / Free trial), and for Paid a
/// step segmented control, a price-card grid and rule cards; for Free trial a
/// single trial summary card. A sticky purple bottom bar shows the current
/// selection and routes to Configure. Loading/error/empty are handled by
/// [DataStateBuilder] on the controller's `DataState<ChallengeData>`; all
/// selection state lives in [ChallengeController].
class ChallengeView extends StatelessWidget {
  const ChallengeView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<ChallengeController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'challenge.title'.tr),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Obx(
                () => DataStateBuilder<ChallengeData>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const _ChallengeSkeleton(),
                  builder: (data) => _ChallengeBody(c: c, data: data),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final data = c.state.valueOrNull;
        if (data == null) return const SizedBox.shrink();
        final isPaid = c.mode.value == ChallengeMode.paid;
        final plan = c.currentPlan(data);
        return ChallengeBottomBar(
          planName: isPaid
              ? '${FlavorResolver.appName} ${c.step.value.label} · ${plan.size}'
              : '${FlavorResolver.appName} Free Trial · \$10K',
          price: isPaid ? plan.price : r'$0',
          strikePrice: isPaid ? plan.original : null,
          actionLabel: 'challenge.configure'.tr,
          onAction: () => Get.toNamed(AppRoutes.configure),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded body: mode toggle + the animated paid/trial switch.
// ---------------------------------------------------------------------------

class _ChallengeBody extends StatelessWidget {
  const _ChallengeBody({required this.c, required this.data});
  final ChallengeController c;
  final ChallengeData data;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSegmentedControl(
            labels: [
              'challenge.paid_challenges'.tr,
              'challenge.free_trial'.tr
            ],
            selected: c.mode.value == ChallengeMode.paid ? 0 : 1,
            onChanged: (i) => c.setMode(
                i == 0 ? ChallengeMode.paid : ChallengeMode.freeTrial),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: AppMotion.base,
            switchInCurve: AppMotion.enter,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SizeTransition(
                sizeFactor: anim,
                child: child,
              ),
            ),
            child: c.mode.value == ChallengeMode.paid
                ? _PaidBody(c: c, data: data, key: const ValueKey('paid'))
                : _TrialBody(c: c, data: data, key: const ValueKey('trial')),
          ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton matching the screen's shape.
// ---------------------------------------------------------------------------

class _ChallengeSkeleton extends StatelessWidget {
  const _ChallengeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        ShimmerBox(height: 44, radius: 14),
        SizedBox(height: 18),
        ShimmerBox(height: 44, radius: 14),
        SizedBox(height: 16),
        StatGridSkeleton(tiles: 6),
        SizedBox(height: 26),
        CardSkeleton(lines: 5),
        SizedBox(height: 26),
        CardSkeleton(lines: 4),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Paid mode body
// ---------------------------------------------------------------------------

class _PaidBody extends StatelessWidget {
  const _PaidBody({required this.c, required this.data, super.key});
  final ChallengeController c;
  final ChallengeData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompareLink(),
        const SizedBox(height: 14),
        AppSegmentedControl(
          labels: ChallengeStep.values.map((s) => s.label).toList(),
          selected: c.step.value.index,
          onChanged: (i) => c.setStep(ChallengeStep.values[i]),
        ),
        const SizedBox(height: 16),
        _PlanGrid(c: c, data: data),
        const SizedBox(height: 26),
        SectionHeader('challenge.challenge_rules'.tr),
        RulesCard(
          children: [
            for (var i = 0; i < data.challengeRules.length; i++)
              KeyValueRow(
                label: data.challengeRules[i].label,
                value: data.challengeRules[i].value,
                showInfo: true,
                showDivider: i != data.challengeRules.length - 1,
              ),
          ],
        ),
        const SizedBox(height: 26),
        SectionHeader('challenge.funded_reward_rules'.tr),
        RulesCard(
          children: [
            for (var i = 0; i < data.fundedRules.length; i++)
              KeyValueRow(
                label: data.fundedRules[i].label,
                value: data.fundedRules[i].value,
                showInfo: true,
                showDivider: i != data.fundedRules.length - 1,
              ),
          ],
        ),
      ],
    );
  }
}

class _CompareLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.surfaceCard(scheme, radius: 14),
      child: Center(
        child: Text(
          'challenge.compare_plans'.tr,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({required this.c, required this.data});
  final ChallengeController c;
  final ChallengeData data;

  @override
  Widget build(BuildContext context) {
    final plans = data.plans;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 116,
      ),
      itemBuilder: (context, i) => ChallengePlanCard(
        plan: plans[i],
        selected: c.selectedPlan.value == i,
        onTap: () => c.selectPlan(i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Free-trial body
// ---------------------------------------------------------------------------

class _TrialBody extends StatelessWidget {
  const _TrialBody({required this.c, required this.data, super.key});
  final ChallengeController c;
  final ChallengeData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'challenge.free_trial_plan'
                          .trParams({'app': FlavorResolver.appName}),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      r'$10K account, free for 7 days',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    r'$0',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    'challenge.no_fee'.tr,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TrialStatGrid(data: data),
          const SizedBox(height: 16),
          AppGradientButton(
            label: 'challenge.start_free_trial'.tr,
            onPressed: () => Get.toNamed(AppRoutes.configure),
          ),
          const SizedBox(height: 12),
          Text(
            'challenge.trial_note'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialStatGrid extends StatelessWidget {
  const _TrialStatGrid({required this.data});
  final ChallengeData data;

  @override
  Widget build(BuildContext context) {
    final rules = data.trialRules;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.9,
      ),
      itemBuilder: (context, i) => _TrialStatTile(rule: rules[i]),
    );
  }
}

class _TrialStatTile extends StatelessWidget {
  const _TrialStatTile({required this.rule});
  final ChallengeRule rule;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.dark
            ? AppColors.white.withValues(alpha: 0.05)
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rule.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rule.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
