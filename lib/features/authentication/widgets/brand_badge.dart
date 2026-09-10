import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

/// Premium brand mark used at the top of the auth screens: a rounded gradient
/// tile carrying the product glyph, with a soft brand glow. Kept theme-driven
/// so white-label flavors re-skin it automatically via [AppTheme.brandGradient].
class BrandBadge extends StatelessWidget {
  const BrandBadge({
    super.key,
    this.size = 64,
    this.icon = Icons.candlestick_chart_rounded,
  });

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient(scheme),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.45),
            blurRadius: 26.r,
            spreadRadius: -4.r,
            offset: Offset(0, 12.h),
          ),
        ],
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.25),
          width: 1.w,
        ),
      ),
      child: Icon(icon, color: AppColors.white, size: size * 0.52),
    );
  }
}
