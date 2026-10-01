import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Visual tone
/// same widget covers "heads-up" (info), "be careful" (warning) and "danger".
enum BannerTone { info, warning, danger }

/// The ONE soft callout banner used across inner screens — a rounded, low-key
/// tinted box with a leading icon, bold title and muted body. Fully
/// theme-driven; drop it at the bottom of a scroll body.
///
/// ```dart
/// const AppInfoBanner(
///   tone: BannerTone.info,
///   title: 'A competition is not an evaluation',
///   body: 'Different rules, a separate account…',
/// )
/// ```
class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.title,
    required this.body,
    this.tone = BannerTone.info,
    this.icon,
    this.margin = EdgeInsets.zero,
  });

  final String title;
  final String body;
  final BannerTone tone;
  final IconData? icon;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accent(scheme);
    final fill = accent.withValues(alpha: scheme.brightness == Brightness.dark ? 0.14 : 0.10);

    return Container(
      margin: margin,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? _defaultIcon, size: 20.w, color: accent),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                Gap.vXs,
                Text(
                  body,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.sp,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _defaultIcon {
    switch (tone) {
      case BannerTone.info:
        return Icons.info_outline_rounded;
      case BannerTone.warning:
        return Icons.warning_amber_rounded;
      case BannerTone.danger:
        return Icons.error_outline_rounded;
    }
  }

  Color _accent(ColorScheme scheme) {
    switch (tone) {
      case BannerTone.info:
        return scheme.primary;
      case BannerTone.warning:
        return AppTheme.accent;
      case BannerTone.danger:
        return AppColors.danger;
    }
  }
}
