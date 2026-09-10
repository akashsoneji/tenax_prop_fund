import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/rules_models.dart';

/// Generic intro banner used at the top of each tab (pale-tinted card with
/// an icon + title + body). Different variants pick the icon and the tint.
class RulesInfoBanner extends StatelessWidget {
  const RulesInfoBanner({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.info_outline_rounded,
    this.tone = RuleTone.warning,
    this.index,
  });

  /// Number badge shown to the left of the title (e.g. "Only three things
  /// close an account" — the "!" badge variant in the design). When null,
  /// no badge is shown and the icon takes its place.
  final int? index;
  final String title;
  final String body;
  final IconData icon;
  final RuleTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = tone.background(scheme);
    final accent = tone.accent(scheme);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12.h),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BadgeOrIcon(index: index, icon: icon, accent: accent, tone: tone),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    body,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13.5.sp,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.78),
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

class _BadgeOrIcon extends StatelessWidget {
  const _BadgeOrIcon({
    required this.index,
    required this.icon,
    required this.accent,
    required this.tone,
  });

  final int? index;
  final IconData icon;
  final Color accent;
  final RuleTone tone;

  @override
  Widget build(BuildContext context) {
    if (index != null) {
      // Square rounded badge with the index digit (used by the numbered
      // rule cards, not by intro banners — kept here for reuse).
      return Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        alignment: Alignment.center,
        child: Text(
          '$index',
          style: TextStyle(
              color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16.sp,
          ),
        ),
      );
    }
    return Container(
      width: 28.w,
      height: 28.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.12),
      ),
      child: Icon(icon, color: accent, size: 18.w),
    );
  }
}