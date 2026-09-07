import 'package:flutter/material.dart';
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 14),
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
                    const SizedBox(width: 10),
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
                const SizedBox(height: 12),
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
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                symbol.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'symbols.trade'.tr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_ios, size: 11, color: scheme.primary),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 18,
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
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
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
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceCard(scheme, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 90, height: 16),
                    SizedBox(height: 8),
                    ShimmerBox(width: 140, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 12),
              ShimmerBox(width: 84, height: 34, radius: 10),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 38, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(height: 38, radius: 12)),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ShimmerBox(width: 60, height: 30)),
              Expanded(child: ShimmerBox(width: 60, height: 30)),
              Expanded(child: ShimmerBox(width: 60, height: 30)),
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
            padding: EdgeInsets.only(bottom: i == rows - 1 ? 0 : 14),
            child: const SymbolCardSkeleton(),
          ),
      ],
    );
  }
}

