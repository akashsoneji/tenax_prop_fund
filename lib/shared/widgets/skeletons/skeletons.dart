import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 140, height: 14),
          const SizedBox(height: 14),
          for (var i = 0; i < lines; i++) ...[
            ShimmerBox(width: i.isEven ? double.infinity : 200, height: 10),
            if (i != lines - 1) const SizedBox(height: 10),
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
    return ShimmerBox(height: height, radius: 22);
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ShimmerBox(width: 4, radius: 0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(width: 90, height: 9),
                              SizedBox(height: 7),
                              ShimmerBox(width: 150, height: 15),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        ShimmerBox(width: 70, height: 22, radius: 8),
                      ],
                    ),
                    SizedBox(height: 14),
                    ShimmerBox(height: 58, radius: 14),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: ShimmerBox(height: 42, radius: 12)),
                        SizedBox(width: 10),
                        Expanded(child: ShimmerBox(height: 42, radius: 12)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: ShimmerBox(height: 42, radius: 12)),
                        SizedBox(width: 10),
                        Expanded(child: ShimmerBox(height: 42, radius: 12)),
                      ],
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: ShimmerBox(height: 42, radius: 12)),
                        SizedBox(width: 10),
                        Expanded(child: ShimmerBox(height: 42, radius: 12)),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const ShimmerBox(width: 44, height: 44, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 12),
                SizedBox(height: 8),
                ShimmerBox(width: 120, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const ShimmerBox(width: 56, height: 18, radius: 6),
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
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          ShimmerBox(width: 70, height: 10),
          SizedBox(height: 12),
          ShimmerBox(width: 100, height: 18),
        ],
      ),
    );
  }
}
