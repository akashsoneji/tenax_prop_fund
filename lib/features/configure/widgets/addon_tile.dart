import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/configure_models.dart';

/// A single add-on row on the Configure screen: a leading check circle, the
/// add-on title + description + tag, and the price on the right. Selecting it
/// tints the circle with the brand gradient and highlights the border.
class AddonTile extends StatelessWidget {
  const AddonTile({
    super.key,
    required this.addon,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final Addon addon;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CheckCircle(selected: selected),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon.title.tr,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          addon.description.tr,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5.sp,
                            height: 1.35,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          addon.tagLabel.tr,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    addon.priceLabel,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1.h,
            thickness: 1.h,
            indent: 14.w,
            endIndent: 14.w,
            color: scheme.onSurface.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected ? AppTheme.brandGradient(scheme) : null,
        border: selected
            ? null
            : Border.all(color: scheme.onSurface.withValues(alpha: 0.25), width: 1.5.w),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 15.w, color: AppColors.white)
          : null,
    );
  }
}
