import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/challenge_controller.dart';
import '../models/challenge_models.dart';

/// Compare challenges — a wrap of selectable plan chips, a key-features table
/// for the selected plan (challenge + funded rules), and a sticky "Get plan"
/// CTA that routes to Configure seeded with the chosen plan. Mirrors the web
/// comparison screen, condensed for mobile.
class ChallengeCompareView extends StatelessWidget {
  const ChallengeCompareView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChallengeController>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'challenge.compare_title'.tr),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
            sliver: SliverToBoxAdapter(
              child: Obx(() {
                final data = controller.comparison.value;
                if (data == null) return const _CompareSkeleton();
                if (data.plans.isEmpty) return const SizedBox.shrink();
                return _CompareBody(c: controller, data: data);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareBody extends StatelessWidget {
  const _CompareBody({required this.c, required this.data});
  final ChallengeController c;
  final ChallengeData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final plans = data.plans;
      final index = c.compareSelected.value.clamp(0, plans.length - 1);
      final plan = plans[index];
      final rows = <ChallengeRule>[...plan.challengeRules, ...plan.fundedRules];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'challenge.compare_plans'.tr,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14.sp,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (var i = 0; i < plans.length; i++)
                _PlanChip(
                  label: plans[i].name,
                  selected: i == index,
                  onTap: () => c.selectComparePlan(i),
                ),
            ],
          ),
          SizedBox(height: 18.h),
          _PlanHeaderCard(plan: plan),
          SizedBox(height: 14.h),
          Container(
            decoration: AppTheme.surfaceCard(scheme, radius: 18),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${plan.name} ${'challenge.key_features'.tr}'
                              .toUpperCase(),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11.sp,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < rows.length; i++)
                  _FeatureRow(row: rows[i], last: i == rows.length - 1),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          AppGradientButton(
            label: 'challenge.get_plan'.tr,
            onPressed: () => c.buyComparePlan(plan),
          ),
        ],
      );
    });
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: selected ? scheme.primary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _PlanHeaderCard extends StatelessWidget {
  const _PlanHeaderCard({required this.plan});
  final ChallengePlan plan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'challenge.account'.tr.toUpperCase(),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11.sp,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  plan.size,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (plan.discountLabel.isNotEmpty)
                Text(
                  plan.discountLabel,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              Text(
                plan.price,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.row, required this.last});
  final ChallengeRule row;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.help_outline_rounded,
              size: 15.w, color: scheme.onSurface.withValues(alpha: 0.35)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              row.label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.sp,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: _toneColor(row.tone, scheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _toneColor(String? tone, ColorScheme scheme) {
    switch (tone) {
      case 'up':
        return AppColors.success;
      case 'gold':
        return const Color(0xFFCA8A04);
      case 'muted':
        return scheme.onSurface.withValues(alpha: 0.5);
      default:
        return scheme.onSurface;
    }
  }
}

class _CompareSkeleton extends StatelessWidget {
  const _CompareSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 320.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18.r),
        ),
      );
}
