import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

/// The big brand-gradient result banner
/// Yellow headline value + white subtitle, matching the design. Animates its
/// scale/opacity in whenever the [headline] changes so a recompute feels live.
class CalcResultCard extends StatelessWidget {
  const CalcResultCard({
    super.key,
    required this.headline,
    required this.subtitle,
  });

  /// The large accent-yellow value, e.g. "3.33 lots" or "+$0".
  final String headline;

  /// The white helper line under it, e.g. "Risking $1,000 · $33 per pip".
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 26.h, horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 22.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: AppMotion.base,
            switchInCurve: AppMotion.bounce,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              headline,
              key: ValueKey(headline),
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 30.sp,
                fontWeight: FontWeight.w800,
                color: scheme.secondary,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tone of the helper banner shown under the result card.
enum CalcNoteTone { success, info }

/// Soft rounded note under the result card — a green check when the trade is
/// inside limits, or a purple info icon for a neutral tip.
class CalcNoteBanner extends StatelessWidget {
  const CalcNoteBanner({
    super.key,
    required this.text,
    this.tone = CalcNoteTone.info,
  });

  final String text;
  final CalcNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final success = tone == CalcNoteTone.success;
    final icon = success
        ? Icons.check_circle_rounded
        : Icons.info_outline_rounded;
    final iconColor = success ? AppColors.success : scheme.primary;
    final bg = success
        ? AppColors.success.withValues(alpha: 0.08)
        : scheme.primary.withValues(alpha: 0.06);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.w, color: iconColor),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14.sp,
                color: scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
