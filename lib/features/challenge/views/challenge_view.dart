import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/flavor/flavor_resolver.dart';
import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_empty_view.dart';
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
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
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
          final trial = data.trial;
          final size = (trial?.accountSizeMinor ?? 0) ~/ 100;
          return ChallengeBottomBar(
            planName:
                '${FlavorResolver.appName} Free Trial · \$${_sizeK(size)}',
            price: r'$0',
            actionLabel: 'challenge.start_free_trial'.tr,
            onAction: () {
              if (trial != null) c.startFreeTrial(trial);
            },
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
      final trialEnabled = data.trial?.enabled ?? false;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (trialEnabled) ...[
            AppSegmentedControl(
              labels: [
                'challenge.paid_challenges'.tr,
                'challenge.free_trial'.tr
              ],
              selected: c.mode.value == ChallengeMode.paid ? 0 : 1,
              onChanged: (i) => c.setMode(
                  i == 0 ? ChallengeMode.paid : ChallengeMode.freeTrial),
            ),
            SizedBox(height: 12.h),
          ],
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
        ShimmerBox(height: 40.h, radius: 12.r),
        SizedBox(height: 12.h),
        ShimmerBox(height: 40.h, radius: 12.r),
        SizedBox(height: 12.h),
        const StatGridSkeleton(tiles: 6),
        SizedBox(height: 18.h),
        const CardSkeleton(lines: 5),
        SizedBox(height: 18.h),
        const CardSkeleton(lines: 4),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Paid mode body
// ---------------------------------------------------------------------------

EdgeInsets get _sectionHeaderPadding =>
    EdgeInsets.only(left: 2.w, bottom: 8.h);

class _PaidBody extends StatelessWidget {
  const _PaidBody({required this.c, required this.data, super.key});
  final ChallengeController c;
  final ChallengeData data;

  @override
  Widget build(BuildContext context) {
    final plans = c.plansForStep(data);
    final tabs = c.stepTabs(data);
    final tabKeys = tabs.keys.toList(growable: false);
    final stepTabs = tabs.length > 1
        ? [
            AppSegmentedControl(
              labels: tabs.values.toList(growable: false),
              selected: tabKeys
                  .indexOf(c.activeStep(data))
                  .clamp(0, tabKeys.length - 1),
              onChanged: (i) => c.setStep(tabKeys[i]),
            ),
            SizedBox(height: 12.h),
          ]
        : const <Widget>[];
    if (plans.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...stepTabs,
          const _CompareLink(),
          SizedBox(height: 12.h),
          const AppEmptyView(
            titleKey: 'challenge.no_plans_title',
            messageKey: 'challenge.no_plans_hint',
            icon: Icons.hourglass_empty_rounded,
            boxed: true,
          ),
        ],
      );
    }
    final selectedPlan =
        plans[c.selectedPlan.value.clamp(0, plans.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...stepTabs,
        _PlanGrid(c: c, plans: plans),
        SizedBox(height: 10.h),
        const _CompareLink(),
        SizedBox(height: 18.h),
        _RulesSection(
          title: 'challenge.challenge_rules'.tr,
          rules: selectedPlan.challengeRules,
        ),
        SizedBox(height: 18.h),
        _RulesSection(
          title: 'challenge.funded_reward_rules'.tr,
          rules: selectedPlan.fundedRules,
        ),
        if (data.plans.isNotEmpty)
          for (final box in selectedPlan.ruleBoxes) ...[
            SizedBox(height: 18.h),
            SectionHeader(box.title, padding: _sectionHeaderPadding),
            RulesCard(
              children: [
                for (var i = 0; i < box.rows.length; i++)
                  KeyValueRow(
                    dense: true,
                    label: box.rows[i].label,
                    value: box.rows[i].value,
                    showInfo: box.rows[i].tip.isNotEmpty,
                    showDivider: i != box.rows.length - 1,
                  ),
              ],
            ),
          ],
      ],
    );
  }
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({required this.title, required this.rules});
  final String title;
  final List<ChallengeRule> rules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title, padding: _sectionHeaderPadding),
        RulesCard(
          children: [
            for (var i = 0; i < rules.length; i++)
              KeyValueRow(
                dense: true,
                label: rules[i].label,
                value: rules[i].value,
                showInfo: true,
                showDivider: i != rules.length - 1,
              ),
          ],
        ),
      ],
    );
  }
}

class _CompareLink extends StatelessWidget {
  const _CompareLink();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          Get.find<ChallengeController>().loadComparison();
          Get.toNamed(AppRoutes.challengeCompare);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare_arrows_rounded,
                  size: 18.w, color: scheme.primary),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  'challenge.compare_plans'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(color: scheme.primary, fontSize: 13.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column plan grid whose rows size to their content, so cards stay
/// compact instead of being forced to a fixed height.
class _PlanGrid extends StatelessWidget {
  const _PlanGrid({required this.c, required this.plans});
  final ChallengeController c;
  final List<ChallengePlan> plans;

  @override
  Widget build(BuildContext context) {
    final rowCount = (plans.length + 1) ~/ 2;
    return Column(
      children: [
        for (var row = 0; row < rowCount; row++) ...[
          if (row > 0) SizedBox(height: 10.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _cell(row * 2)),
                SizedBox(width: 10.w),
                Expanded(
                  child: row * 2 + 1 < plans.length
                      ? _cell(row * 2 + 1)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _cell(int i) => ChallengePlanCard(
        plan: plans[i],
        selected: c.selectedPlan.value == i,
        onTap: () => c.selectPlan(i),
      );
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
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TrialHeader(data: data),
          SizedBox(height: 12.h),
          _TrialStatGrid(data: data),
          SizedBox(height: 14.h),
          Obx(
            () => AppGradientButton(
              label: 'challenge.start_free_trial'.tr,
              loading: c.isStartingTrial.value,
              onPressed: () {
                final trial = data.trial;
                if (trial != null) c.startFreeTrial(trial);
              },
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'challenge.trial_note'.tr,
            textAlign: TextAlign.center,
            style: AppText.label(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontSize: 11.5.sp,
            ).copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _TrialHeader extends StatelessWidget {
  const _TrialHeader({required this.data});
  final ChallengeData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'challenge.free_trial_plan'
                    .trParams({'app': FlavorResolver.appName}),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.heading(color: scheme.onSurface, fontSize: 16.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                _trialDescription(data),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12.5.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              r'$0',
              style: AppText.value(color: scheme.primary, fontSize: 19.sp),
            ),
            Text(
              'challenge.no_fee'.tr,
              style: AppText.label(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _trialDescription(ChallengeData data) {
  final trial = data.trial;
  if (trial == null) return 'challenge.free_trial'.tr;
  final size = trial.accountSizeMinor ~/ 100;
  return 'challenge.trial_description'.trParams({
    'size': '\$${_sizeK(size)}',
    'days': '${trial.days}',
  });
}

/// Formats a whole-dollar amount as a compact `$5K`-style label.
String _sizeK(int dollars) {
  if (dollars >= 1000) {
    final k = dollars / 1000;
    return '${k == k.roundToDouble() ? k.toStringAsFixed(0) : k}K';
  }
  return '$dollars';
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
            ChallengeRule('challenge.rule_account_size'.tr,
                '\$${(trial?.accountSizeMinor ?? 0) ~/ 100}'),
            ChallengeRule('challenge.rule_profit_target'.tr,
                '${trial?.profitTargetPercent ?? 0}%'),
            ChallengeRule('challenge.rule_daily_loss'.tr,
                '${trial?.dailyLossPercent ?? 0}%'),
            ChallengeRule('challenge.rule_max_loss'.tr,
                '${trial?.maxLossPercent ?? 0}%'),
            ChallengeRule('challenge.rule_min_days'.tr,
                '${trial?.minTradingDays ?? 0}'),
            ChallengeRule(
              'challenge.rule_expires_after'.tr,
              'challenge.days_count'.trParams({'days': '${trial?.days ?? 0}'}),
            ),
          ];
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rules.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        mainAxisExtent: 56.h,
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontSize: 11.5.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            rule.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.value(color: scheme.onSurface, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
