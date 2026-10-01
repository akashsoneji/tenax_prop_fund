import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A reusable list row:
/// optional subtitle in the middle, and an optional trailing widget (meta text,
/// a badge) followed by an optional chevron. Used by the Downloads, Economic
/// calendar and similar directory-style screens.
///
/// Fully theme-driven; the icon box tint defaults to the primary colour.
class IconLeadingRow extends StatelessWidget {
  const IconLeadingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.showDivider = false,
    this.iconTint,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showDivider;
  final Color? iconTint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = iconTint ?? scheme.primary;
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return Column(
      children: [
        Material(
      color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 20.w, color: tint),
                  ),
                  Gap.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        if (hasSubtitle) ...[
                          Gap.vXxs,
                          Text(
                            subtitle!,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12.5.sp,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    Gap.hSm,
                    trailing!,
                  ],
                  if (showChevron) ...[
                    Gap.hXs,
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1.h,
            thickness: 1,
            indent: 66.w,
            endIndent: 14.w,
            color: scheme.onSurface.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}
