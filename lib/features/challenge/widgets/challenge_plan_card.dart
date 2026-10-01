import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/challenge_models.dart';
import '../../../shared/theme/app_spacing.dart';

/// A selectable account-size price card in the Paid grid. When [selected] it
/// gains a brand-purple border, soft glow and a check mark; otherwise a plain
/// surface card. Height follows its content (no fixed extent).
class ChallengePlanCard extends StatelessWidget {
  const ChallengePlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final ChallengePlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: isDark ? 0.14 : 0.06)
                : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.08),
              width: selected ? 1.5.w : 1.w,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.size,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading(
                        color: scheme.onSurface,
                        fontSize: 17.sp,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: selected ? 1 : 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16.w,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              Gap.vXxs,
              _PriceRow(plan: plan),
              if (plan.discountLabel.isNotEmpty) ...[
                6.verticalSpace,
                _DiscountPill(label: plan.discountLabel),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.plan});
  final ChallengePlan plan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            plan.price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.title(
              color: scheme.primary,
              fontSize: 15.sp,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (plan.original.isNotEmpty) ...[
          6.horizontalSpace,
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Text(
                plan.original,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 12.sp,
                ).copyWith(decoration: TextDecoration.lineThrough),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DiscountPill extends StatelessWidget {
  const _DiscountPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.label(
          color: scheme.primary,
          fontSize: 10.5.sp,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
