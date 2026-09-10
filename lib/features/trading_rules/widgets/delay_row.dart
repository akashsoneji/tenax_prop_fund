import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/rules_models.dart';

/// One row in the "Delays a reward" list.
/// orange "consequence" label on the right. Divided rows so the list reads
/// like a settings page.
class DelayRowTile extends StatelessWidget {
  const DelayRowTile({
    super.key,
    required this.row,
    this.showDivider = true,
  });

  final DelayRow row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    row.body,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13.sp,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 140.w),
              child: Text(
                row.consequence,
                textAlign: TextAlign.right,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warningInk, // amber/orange
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}