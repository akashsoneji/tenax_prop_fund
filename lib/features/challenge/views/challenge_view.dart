import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
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
        if (!isPaid) {
          return ChallengeBottomBar(
            planName: '${FlavorResolver.appName} Free Trial · \$10K',
            price: r'\$0',
            actionLabel: 'challenge.configure'.tr,
            onAction: () => _continueToConfigure(c, data),
          );
        }
        final plans = c.plansForStep(data);
        if (plans.isEmpty) return const SizedBox.shrink();
        final plan = plans[c.selectedPlan.value.clamp(0, plans.length - 1)];
        return ChallengeBottomBar(
          planName: '${plan.name} · ${plan.size}',
          price: plan.price,
          strikePrice: plan.original,
          actionLabel: 'challenge.configure'.tr,
          onAction: () => _continueToConfigure(c, data),
        );
      }),
    );
  }
}

Future<void> _continueToConfigure(
  ChallengeController controller,
  ChallengeData data,
) async {
  final plan = controller.currentPlan(data);
  if (plan.versions.isEmpty) return;
  final version = plan.versions.first;
  controller.loadQuote(planVersionId: version.id);
  Get.toNamed(
    AppRoutes.configure,
    arguments: <String, Object?>{
      'plan': plan,
      'plans': data.plans,
      'addons': data.addons,
      'platforms': data.platforms,
      'paymentMethods': data.paymentMethods,
      'currency': data.currency,
      'quote': controller.quote.value,
    },
  );
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
      c.selectedPlan.value;
      c.step.value;
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
          SizedBox(height: 18.h),
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
      children: [
        ShimmerBox(height: 44.h, radius: 14.r),
        SizedBox(height: 18.h),
        ShimmerBox(height: 44.h, radius: 14.r),
        SizedBox(height: 16.h),
        const StatGridSkeleton(tiles: 6),
        SizedBox(height: 26.h),
        const CardSkeleton(lines: 5),
        SizedBox(height: 26.h),
        const CardSkeleton(lines: 4),
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
    final plans = c.plansForStep(data);
    if (plans.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompareLink(),
          SizedBox(height: 14.h),
          AppSegmentedControl(
            labels: ChallengeStep.values.map((s) => s.label).toList(),
            selected: c.step.value.index,
            onChanged: (i) => c.setStep(ChallengeStep.values[i]),
          ),
          SizedBox(height: 28.h),
          const _NoPlansState(),
        ],
      );
    }
    final selectedPlan = plans[c.selectedPlan.value.clamp(0, plans.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompareLink(),
        SizedBox(height: 14.h),
        AppSegmentedControl(
          labels: ChallengeStep.values.map((s) => s.label).toList(),
          selected: c.step.value.index,
          onChanged: (i) => c.setStep(ChallengeStep.values[i]),
        ),
        SizedBox(height: 16.h),
        _PlanGrid(c: c, data: data),
        SizedBox(height: 26.h),
        SectionHeader('challenge.challenge_rules'.tr),
        RulesCard(
          children: [
            for (var i = 0; i < selectedPlan.challengeRules.length; i++)
              KeyValueRow(
                label: selectedPlan.challengeRules[i].label,
                value: selectedPlan.challengeRules[i].value,
                showInfo: true,
                showDivider: i != selectedPlan.challengeRules.length - 1,
              ),
          ],
        ),
        SizedBox(height: 26.h),
        SectionHeader('challenge.funded_reward_rules'.tr),
        RulesCard(
          children: [
            for (var i = 0; i < selectedPlan.fundedRules.length; i++)
              KeyValueRow(
                label: selectedPlan.fundedRules[i].label,
                value: selectedPlan.fundedRules[i].value,
                showInfo: true,
                showDivider: i != selectedPlan.fundedRules.length - 1,
              ),
          ],
        ),
        if (data.plans.isNotEmpty) ...[
          SizedBox(height: 26.h),
          for (final box in selectedPlan.ruleBoxes) ...[
            SectionHeader(box.title),
            _RuleBoxCard(box: box),
            SizedBox(height: 16.h),
          ],
        ],
      ],
    );
  }
}

class _NoPlansState extends StatelessWidget {
  const _NoPlansState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 18.r),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 42.sp, color: scheme.primary),
          SizedBox(height: 12.h),
          Text(
            'No plans available',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Please choose another challenge type.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13.sp,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleBoxCard extends StatelessWidget {
  const _RuleBoxCard({required this.box});

  final ChallengeRuleBox box;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: AppTheme.surfaceCard(scheme, radius: 16.r),
      child: Column(
        children: [
          for (var i = 0; i < box.rows.length; i++)
            KeyValueRow(
              label: box.rows[i].label,
              value: box.rows[i].value,
              showInfo: box.rows[i].tip.isNotEmpty,
              showDivider: i != box.rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _CompareLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 14.r),
      child: Center(
        child: Text(
          'challenge.compare_plans'.tr,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14.sp,
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
    final plans = c.plansForStep(data);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.w,
        crossAxisSpacing: 12.w,
        mainAxisExtent: 92.h,
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
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18.r),
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
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _trialDescription(data),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13.sp,
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
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    'challenge.no_fee'.tr,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12.sp,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _TrialStatGrid(data: data),
          SizedBox(height: 16.h),
          AppGradientButton(
            label: 'challenge.start_free_trial'.tr,
            onPressed: () => Get.toNamed(AppRoutes.configure),
          ),
          SizedBox(height: 12.h),
          Text(
            'challenge.trial_note'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.sp,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

String _trialDescription(ChallengeData data) {
  final trial = data.trial;
  if (trial == null) return 'challenge.free_trial'.tr;
  final size = trial.accountSizeMinor ~/ 100;
  return '\$$size account, free for ${trial.days} days';
}

class _TrialStatGrid extends StatelessWidget {
  const _TrialStatGrid({required this.data});
  final ChallengeData data;

  @override
  Widget build(BuildContext context) {
          final trial = data.trial;
          final rules = data.trialRules.isNotEmpty
              ? data.trialRules
              : [
                  ChallengeRule('Account size', '\$${(trial?.accountSizeMinor ?? 0) ~/ 100}'),
                  ChallengeRule('Profit target', '${trial?.profitTargetPercent ?? 0}%'),
                  ChallengeRule('Daily loss limit', '${trial?.dailyLossPercent ?? 0}%'),
                  ChallengeRule('Maximum loss', '${trial?.maxLossPercent ?? 0}%'),
                  ChallengeRule('Minimum trading days', '${trial?.minTradingDays ?? 0}'),
                  ChallengeRule('Expires after', '${trial?.days ?? 0} days'),
                ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rules.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.w,
        crossAxisSpacing: 12.w,
        childAspectRatio: 2.0,
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.dark
            ? AppColors.white.withValues(alpha: 0.05)
            : AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rule.label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5.sp,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            rule.value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
