import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../app_shimmer.dart';
import 'app_metric_strip.dart';
import 'app_price_tile.dart';

/// One tappable market card: symbol header + "Trade" chip, then a live section
/// (usually Sell/Buy [AppPriceTile]s and an [AppMetricStrip]).
///
/// The card itself is static — it never listens to anything. The feature
/// passes [quote], typically `Obx(() => …)` over just that symbol's price, so a
/// tick rebuilds only the quote section, never the header or the whole list.
class AppSymbolCard extends StatelessWidget {
  const AppSymbolCard({
    super.key,
    required this.code,
    required this.subtitle,
    required this.quote,
    this.onTap,
  });

  final String code;
  final String subtitle;

  /// The live part of the card. Keep the reactive wrapper (`Obx`) inside it.
  final Widget quote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          padding: EdgeInsets.all(16.w),
          decoration: AppTheme.surfaceCard(scheme, radius: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(code: code, subtitle: subtitle),
              14.verticalSpace,
              quote,
            ],
          ),
        ),
      ),
    );
  }
}

/// Sell/Buy tiles above a High/Low/Spread strip — the standard [AppSymbolCard]
/// quote. Takes plain formatted strings; wrap it in the feature's `Obx`.
class AppSymbolQuote extends StatelessWidget {
  const AppSymbolQuote({
    super.key,
    required this.bid,
    required this.ask,
    required this.high,
    required this.low,
    required this.spread,
  });

  final String bid;
  final String ask;
  final String high;
  final String low;
  final String spread;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: AppPriceTile.sell(value: bid)),
            10.horizontalSpace,
            Expanded(child: AppPriceTile.buy(value: ask)),
          ],
        ),
        12.verticalSpace,
        AppMetricStrip.highLowSpread(high: high, low: low, spread: spread),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.code, required this.subtitle});

  final String code;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.base(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              2.verticalSpace,
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.base(
                  fontSize: 12.5.sp,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        10.horizontalSpace,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'symbols.trade'.tr,
                style: AppText.base(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              2.horizontalSpace,
              Icon(Icons.arrow_forward_ios, size: 11.w, color: scheme.primary),
            ],
          ),
        ),
      ],
    );
  }
}

/// Loading placeholder with [AppSymbolCard]'s exact layout so the loading →
/// loaded swap has no jump. Wrap the whole list in ONE [AppShimmer].
class AppSymbolCardSkeleton extends StatelessWidget {
  const AppSymbolCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: AppTheme.surfaceCard(scheme, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 90.w, height: 16.h),
                    8.verticalSpace,
                    ShimmerBox(width: 140.w, height: 11.h),
                  ],
                ),
              ),
              12.horizontalSpace,
              ShimmerBox(width: 84.w, height: 34.h, radius: 10.r),
            ],
          ),
          14.verticalSpace,
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 38.h, radius: 12.r)),
              10.horizontalSpace,
              Expanded(child: ShimmerBox(height: 38.h, radius: 12.r)),
            ],
          ),
          14.verticalSpace,
          Row(
            children: [
              Expanded(child: ShimmerBox(width: 60.w, height: 30.h)),
              Expanded(child: ShimmerBox(width: 60.w, height: 30.h)),
              Expanded(child: ShimmerBox(width: 60.w, height: 30.h)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A column of [AppSymbolCardSkeleton]s spaced like the real list. Pass as a
/// `DataStateBuilder.skeleton` (which supplies the single [AppShimmer]).
class AppSymbolListSkeleton extends StatelessWidget {
  const AppSymbolListSkeleton({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == rows - 1 ? 0 : 14.h),
            child: const AppSymbolCardSkeleton(),
          ),
      ],
    );
  }
}
