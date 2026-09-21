import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_colors.dart';

/// Frosted-glass card
/// `BackdropFilter` (sigma=20) behind a translucent surface so it reads as
/// "glass on a gradient" without depending on any platform view.
///
/// The border is a slowly-rotating brand-tinted gradient hairline that gives
/// the card a premium, "lit-from-within" edge without a heavy glow.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.sigma = 22,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double? radius;
  final double sigma;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode the glass must be a real dark scrim, not a near-transparent
    // white film — otherwise the amber mesh blobs behind it bleed through and
    // wash out the fields, killing text contrast. Base it on the dark surface.
    final overlay = isDark
        ? scheme.surface.withValues(alpha: 0.72)
        : AppColors.white.withValues(alpha: 0.62);
    final sheenTop = isDark
        ? scheme.surface.withValues(alpha: 0.58)
        : AppColors.white.withValues(alpha: 0.55);

    final radiusValue = widget.radius ?? 26.r;
    final pad = widget.padding ?? EdgeInsets.all(22.w);
    final radius = BorderRadius.circular(radiusValue);

    return AnimatedBuilder(
      animation: _spin,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.all(1.4.w),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: SweepGradient(
              transform: GradientRotation(_spin.value * 6.28318),
              colors: [
                scheme.primary.withValues(alpha: isDark ? 0.55 : 0.45),
                scheme.secondary.withValues(alpha: isDark ? 0.45 : 0.35),
                AppColors.white.withValues(alpha: isDark ? 0.16 : 0.5),
                scheme.primary.withValues(alpha: isDark ? 0.55 : 0.45),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.16),
                blurRadius: 34.r,
                spreadRadius: -6.r,
                offset: Offset(0, 18.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radiusValue - 1.4.w),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.sigma,
                sigmaY: widget.sigma,
              ),
              child: Container(
                padding: pad,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radiusValue - 1.4.w),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [sheenTop, overlay],
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
