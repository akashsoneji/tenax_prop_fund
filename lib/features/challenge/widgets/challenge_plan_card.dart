import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/challenge_models.dart';

/// A selectable account-size price card in the Paid grid. When [selected] it
/// gains a brand-purple border + soft glow; otherwise a plain surface card.
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: scheme.brightness == Brightness.dark
              ? AppColors.cardDark
              : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.08),
            width: selected ? 1.6.w : 1.w,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.18),
                    blurRadius: 16.r,
                    offset: Offset(0, 8.h),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.discountLabel,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              plan.size,
              style: GoogleFonts.beVietnamPro(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.price,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                SizedBox(width: 6.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Text(
                    plan.original,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13.sp,
                      decoration: TextDecoration.lineThrough,
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
