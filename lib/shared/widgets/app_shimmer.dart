import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Shared shimmer skeleton primitives for the whole app. Wrap a screen's
/// loading state in [AppShimmer] and lay out [ShimmerBox] placeholders that
/// match the real content's shape — the sweep is driven by one controller
/// inside the [Shimmer] so it stays cheap.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark
                ? AppColors.white.withValues(alpha: 0.06)
          : AppColors.border,
      highlightColor: isDark
          ? AppColors.white.withValues(alpha: 0.14)
          : AppColors.white,
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

/// A single rounded placeholder block. Only used inside [AppShimmer].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
