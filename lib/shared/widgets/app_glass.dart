import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

/// Frosted-glass surface: blurs whatever is behind it and lays a translucent,
/// theme-aware gradient + hairline stroke on top. Works as a circle
/// ([shape] = [BoxShape.circle]) or a rounded rect ([borderRadius]).
class AppGlass extends StatelessWidget {
  const AppGlass({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.padding,
    this.tint,
    this.border,
    this.sigma = 16,
  });

  final Widget child;
  final double? width;
  final double? height;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Colour mixed into the glass; defaults to the brand primary.
  final Color? tint;

  /// Overrides the default all-round stroke (e.g. a top-only line for a bar).
  final Border? border;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final accent = tint ?? scheme.primary;
    final highlight = dark
        ? AppColors.white.withValues(alpha: 0.10)
        : scheme.surface.withValues(alpha: 0.72);
    final stroke = dark
        ? AppColors.white.withValues(alpha: 0.14)
        : accent.withValues(alpha: 0.14);
    final isCircle = shape == BoxShape.circle;
    final radius = isCircle ? null : (borderRadius ?? BorderRadius.circular(16.r));

    final glass = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: width,
        height: height,
        padding: padding,
        // Alignment makes a Container expand to its max constraints, so only
        // centre when the size is fixed; otherwise hug the child.
        alignment: width != null && height != null ? Alignment.center : null,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [highlight, accent.withValues(alpha: dark ? 0.10 : 0.08)],
          ),
          border: border ?? Border.all(color: stroke, width: 1.w),
        ),
        child: child,
      ),
    );

    if (isCircle) return ClipOval(child: glass);
    return ClipRRect(borderRadius: radius ?? BorderRadius.zero, child: glass);
  }
}
