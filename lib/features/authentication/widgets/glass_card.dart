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
    this.padding = const EdgeInsets.all(22),
    this.radius = 26,
    this.sigma = 22,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
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

    final overlay = isDark
        ? AppColors.white.withValues(alpha: 0.055)
        : AppColors.white.withValues(alpha: 0.62);
    final sheenTop = isDark
        ? AppColors.white.withValues(alpha: 0.10)
        : AppColors.white.withValues(alpha: 0.55);

    final radius = BorderRadius.circular(widget.radius);

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
            borderRadius: BorderRadius.circular(widget.radius - 1.4),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.sigma,
                sigmaY: widget.sigma,
              ),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius - 1.4),
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
