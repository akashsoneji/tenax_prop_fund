import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_shimmer.dart';
import '../models/symbol_models.dart';
import '../services/market_watch_v2_service.dart';

/// One tappable market-watch card. Shows ONLY what a trader glances at: the
/// symbol, live Sell (bid) / Buy (ask) prices, and a High / Low / Spread strip.
/// Tapping anywhere opens the symbol in the Markets chart + trade ticket via
/// [onTap]. All live values come from [MarketWatchV2Service] through a granular
/// `Obx` so only this card repaints when its symbol ticks.
class SymbolCard extends StatelessWidget {
  const SymbolCard({super.key, required this.symbol, this.onTap});

  final SymbolSpec symbol;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final service = Get.find<MarketWatchV2Service>();
    final rx = service.priceOf(symbol.code);

    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          padding: EdgeInsets.all(16.w),
          decoration: AppTheme.surfaceCard(scheme, radius: 18),
          child: Obx(() {
            final price = rx.value;
            final digits = price.digits.clamp(0, 8);
            final hasData = price.bid > 0 || price.ask > 0;
            String fmt(double v) => v > 0 ? v.toStringAsFixed(digits) : '--';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(scheme),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _PriceTile(
                        label: 'trade.sell'.tr,
                        value: hasData ? fmt(price.bid) : '--',
                        color: AppColors.danger,
                        scheme: scheme,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _PriceTile(
                        label: 'trade.buy'.tr,
                        value: hasData ? fmt(price.ask) : '--',
                        color: AppColors.success,
                        scheme: scheme,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _MetricStrip(
                  high: fmt(price.dayHigh ?? 0),
                  low: fmt(price.dayLow ?? 0),
                  spread: hasData ? price.spread.toStringAsFixed(1) : '--',
                  scheme: scheme,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                symbol.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                symbol.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.5.sp,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
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
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              SizedBox(width: 2.w),
              Icon(Icons.arrow_forward_ios, size: 11.w, color: scheme.primary),
            ],
          ),
        ),
      ],
    );
  }
}

/// A large Buy/Sell price block: muted label above, coloured price below, on a
/// soft tinted background.
class _PriceTile extends StatelessWidget {
  const _PriceTile({
    required this.label,
    required this.value,
    required this.color,
    required this.scheme,
  });

  final String label;
  final String value;
  final Color color;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// The High / Low / Spread strip under the price tiles.
class _MetricStrip extends StatelessWidget {
  const _MetricStrip({
    required this.high,
    required this.low,
    required this.spread,
    required this.scheme,
  });

  final String high;
  final String low;
  final String spread;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _metric('symbols.high'.tr, high)),
        Expanded(child: _metric('symbols.low'.tr, low)),
        Expanded(child: _metric('symbols.spread_label'.tr, spread)),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.beVietnamPro(
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Loading placeholder that mirrors [SymbolCard]'s exact layout (header +
/// quote pills + 2x4 spec grid) so the loading → loaded swap has no jump.
/// Wrap the whole list in ONE [AppShimmer] (see [SymbolListSkeleton]).
class SymbolCardSkeleton extends StatelessWidget {
  const SymbolCardSkeleton({super.key});

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
                    SizedBox(height: 8.h),
                    ShimmerBox(width: 140.w, height: 11.h),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              ShimmerBox(width: 84.w, height: 34.h, radius: 10.r),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 38.h, radius: 12.r)),
              SizedBox(width: 10.w),
              Expanded(child: ShimmerBox(height: 38.h, radius: 12.r)),
            ],
          ),
          SizedBox(height: 14.h),
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

/// A list of [SymbolCardSkeleton]s spaced like the real list. Pass this as the
/// `DataStateBuilder.skeleton` (which supplies the single [AppShimmer] sweep),
/// so this returns the raw layout WITHOUT its own shimmer wrapper.
class SymbolListSkeleton extends StatelessWidget {
  const SymbolListSkeleton({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == rows - 1 ? 0 : 14.h),
            child: const SymbolCardSkeleton(),
          ),
      ],
    );
  }
}

