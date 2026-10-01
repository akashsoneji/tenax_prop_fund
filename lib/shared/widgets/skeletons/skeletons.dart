import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_spacing.dart';
import '../app_shimmer.dart';

export '../app_shimmer.dart' show AppShimmer, ShimmerBox;

/// Reusable shimmer skeleton shapes. Compose these inside a screen's loading
/// placeholder; they are already made of [ShimmerBox] blocks, so wrap the whole
/// composition in a single [AppShimmer] (DataStateBuilder does this for you) —
/// never wrap each block, so one animation drives the entire sweep.

/// A card-shaped placeholder: title line + a few body lines.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, this.lines = 3, this.height});

  final int lines;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      // minHeight (not a fixed height) so the shimmer lines never overflow when
      // a caller passes a height smaller than the composed content.
      constraints: height != null ? BoxConstraints(minHeight: height!) : null,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 140.w, height: 14.h),
          14.verticalSpace,
          for (var i = 0; i < lines; i++) ...[
            ShimmerBox(width: i.isEven ? double.infinity : 200.w, height: 10.h),
            if (i != lines - 1) 10.verticalSpace,
          ],
        ],
      ),
    );
  }
}

/// A big gradient-hero-sized placeholder block.
class HeroSkeleton extends StatelessWidget {
  const HeroSkeleton({super.key, this.height = 150});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(height: height, radius: 22.r);
  }
}

/// A placeholder shaped like the redesigned account card: status rail, header
/// (title + pill), a P&L band, a 2×2 stat grid and two action buttons. Mirrors
/// `AccountListCard` so the loading state reads as the real content.
class AccountCardSkeleton extends StatelessWidget {
  const AccountCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShimmerBox(width: 4.w, radius: 0),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(width: 90.w, height: 9.h),
                              7.verticalSpace,
                              ShimmerBox(width: 150.w, height: 15.h),
                            ],
                          ),
                        ),
                        10.horizontalSpace,
                        ShimmerBox(width: 70.w, height: 22.h, radius: 8.r),
                      ],
                    ),
                    14.verticalSpace,
                    ShimmerBox(height: 58.h, radius: 14.r),
                    Gap.vMd,
                    Row(
                      children: [
                        Expanded(child: ShimmerBox(height: 42.h, radius: 12.r)),
                        10.horizontalSpace,
                        Expanded(child: ShimmerBox(height: 42.h, radius: 12.r)),
                      ],
                    ),
                    10.verticalSpace,
                    Row(
                      children: [
                        Expanded(child: ShimmerBox(height: 42.h, radius: 12.r)),
                        10.horizontalSpace,
                        Expanded(child: ShimmerBox(height: 42.h, radius: 12.r)),
                      ],
                    ),
                    14.verticalSpace,
                    Row(
                      children: [
                        Expanded(child: ShimmerBox(height: 42.h, radius: 12.r)),
                        10.horizontalSpace,
                        Expanded(child: ShimmerBox(height: 42.h, radius: 12.r)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single list row: leading circle + two text lines + trailing block.
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          ShimmerBox(width: 44.w, height: 44.h, radius: 12.r),
          Gap.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 12.h),
                Gap.vSm,
                ShimmerBox(width: 120.w, height: 10.h),
              ],
            ),
          ),
          Gap.hMd,
          ShimmerBox(width: 56.w, height: 18.h, radius: 6.r),
        ],
      ),
    );
  }
}

/// A list of [ListTileSkeleton]s — the default for list screens.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [for (var i = 0; i < rows; i++) const ListTileSkeleton()],
    );
  }
}

/// A 2-column grid of stat placeholders.
class StatGridSkeleton extends StatelessWidget {
  const StatGridSkeleton({super.key, this.tiles = 4});

  final int tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.9,
      children: [for (var i = 0; i < tiles; i++) const _StatTileSkeleton()],
    );
  }
}

class _StatTileSkeleton extends StatelessWidget {
  const _StatTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerBox(width: 70.w, height: 10.h),
          Gap.vMd,
          ShimmerBox(width: 100.w, height: 18.h),
        ],
      ),
    );
  }
}
