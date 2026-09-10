import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/rules_models.dart';

/// Single numbered rule card
///
/// Layout:
///   * Numbered badge on the left (accent color from [ClosingRule.tone])
///   * Title, body, and a brand-red highlight line on the right
///
/// Cards animate in with a slight stagger when the tab is first shown.
class ClosingRuleCard extends StatelessWidget {
  const ClosingRuleCard({super.key, required this.rule, this.index = 0});

  final ClosingRule rule;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = rule.tone.background(scheme);
    final accent = rule.tone.accent(scheme);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14.h),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              alignment: Alignment.center,
              child: Text(
                '${rule.index}',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    rule.body,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13.5.sp,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    rule.highlight,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}