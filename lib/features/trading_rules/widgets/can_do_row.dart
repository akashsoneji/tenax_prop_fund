import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/rules_models.dart';

/// One row in the "What I can do" checklist.
/// amber check / red x) on the left, label, and a right-aligned text
/// ("Yes", "No", "Above 60 seconds", …).
class CanDoRowTile extends StatelessWidget {
  const CanDoRowTile({
    super.key,
    required this.row,
    this.showDivider = true,
  });

  final CanDoRow row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (icon, iconBg, iconFg, value) = switch (row.status) {
      CanDoStatus.yes => (
        Icons.check_rounded,
        const Color(0xFFD7F1DE),
        AppColors.success,
        AppColors.success,
      ),
      CanDoStatus.no => (
        Icons.close_rounded,
        AppColors.danger.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.10),
        AppColors.danger,
        AppColors.danger,
      ),
      CanDoStatus.conditional => (
        Icons.check_rounded,
        const Color(0xFFFFF1D6),
        AppColors.warningInk,
        AppColors.warningInk,
      ),
    };

    final footnote = row.footnote ?? _defaultForStatus(row.status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 8.h),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                    width: 0.6,
                  ),
                )
              : null,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(7.r),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconFg, size: 18.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                row.label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 140.w),
              child: Text(
                footnote,
                textAlign: TextAlign.right,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _defaultForStatus(CanDoStatus s) => switch (s) {
        CanDoStatus.yes => 'trading_rules.yes'.tr,
        CanDoStatus.no => 'common.no'.tr,
        CanDoStatus.conditional => '',
      };
}