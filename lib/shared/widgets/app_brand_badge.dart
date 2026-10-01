import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'flavor_logo.dart';

/// Brand mark: a rounded gradient tile carrying the flavor's logo (or a glyph
/// when the flavor has none), with a soft brand glow. Fully theme-driven, so
/// every flavor re-skins it through [AppTheme.brandGradient] and [FlavorLogo].
class AppBrandBadge extends StatelessWidget {
  const AppBrandBadge({
    super.key,
    this.size = 64,
    this.icon = Icons.candlestick_chart_rounded,
  });

  final double size;

  /// Shown only when the active flavor has no logo asset.
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
      clipBehavior: Clip.antiAlias,
      child: FlavorLogo(
        size: size,
        fallback: Icon(icon, color: AppColors.white, size: size * 0.52),
      ),
    );
  }
}
