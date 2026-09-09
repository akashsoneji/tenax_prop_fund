import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/symbol_models.dart';
import '../services/market_watch_v2_service.dart';

/// Compact broker-style favorite card: avatar + identity + spread pill on top,
/// a joined Sell|Buy segment, and a slim High–Low day-range bar with a live
/// marker. Deliberately dense so a long watchlist fits on one screen. Live
/// values come from [MarketWatchV2Service] via granular `Obx`es.
class FavoriteSymbolTile extends StatelessWidget {
  const FavoriteSymbolTile({
    super.key,
    required this.instrument,
    required this.index,
    this.onTap,
  });

  final Instrument instrument;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rx = Get.find<MarketWatchV2Service>().priceOf(instrument.code);

    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: AppTheme.surfaceCard(scheme, radius: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(scheme, rx),
              const SizedBox(height: 8),
              _sellBuy(rx),
              const SizedBox(height: 6),
              _rangeBar(scheme, rx),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Header: avatar + identity + spread pill + drag handle ---------------
  Widget _header(ColorScheme scheme, Rx<MarketPrice> rx) {
    return Row(
      children: [
        _avatar(scheme),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                instrument.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.base(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface),
              ),
              Text(
                instrument.category.isEmpty ? '—' : instrument.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppText.base(fontSize: 10.5, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Obx(() => _spreadPill(scheme, rx.value.spread)),
        ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(Icons.drag_indicator_rounded,
                size: 18,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.55)),
          ),
        ),
      ],
    );
  }

  /// Round monogram from the symbol's first letter, tinted by category.
  Widget _avatar(ColorScheme scheme) {
    final tint = _categoryColor(scheme);
    final initials =
        instrument.code.isEmpty ? '?' : instrument.code.substring(0, 1);
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(initials,
          style: AppText.base(
              fontSize: 13, fontWeight: FontWeight.w800, color: tint)),
    );
  }

  Color _categoryColor(ColorScheme scheme) {
    switch (instrument.category) {
      case InstrumentCategory.metals:
        return const Color(0xFFD4A017);
      case InstrumentCategory.crypto:
        return const Color(0xFFF7931A);
      case InstrumentCategory.indices:
        return const Color(0xFF2E7D32);
      case InstrumentCategory.shares:
        return const Color(0xFF1E88E5);
      default:
        return scheme.primary;
    }
  }

  Widget _spreadPill(ColorScheme scheme, double spread) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${'symbols.spread_label'.tr} ${spread > 0 ? spread.toStringAsFixed(1) : '--'}',
        style: AppText.base(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant),
      ),
    );
  }

  // ---- Sell | Buy joined segment -------------------------------------------
  Widget _sellBuy(Rx<MarketPrice> rx) {
    return Obx(() {
      final p = rx.value;
      final has = p.bid > 0 || p.ask > 0;
      return Row(
        children: [
          Expanded(
            child: _side('trade.sell'.tr, has ? _f(p, p.bid) : '--',
                AppColors.danger, false),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _side('trade.buy'.tr, has ? _f(p, p.ask) : '--',
                AppColors.success, true),
          ),
        ],
      );
    });
  }

  Widget _side(String label, String value, Color color, bool alignEnd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment:
                alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Icon(
                  alignEnd
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 11,
                  color: color.withValues(alpha: 0.85)),
              const SizedBox(width: 3),
              Text(label,
                  style: AppText.base(
                      fontSize: 10, color: color.withValues(alpha: 0.85))),
            ],
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(value,
                style: AppText.base(
                    fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }

  // ---- Slim High–Low range bar with live marker ----------------------------
  Widget _rangeBar(ColorScheme scheme, Rx<MarketPrice> rx) {
    return Obx(() {
      final p = rx.value;
      final low = p.dayLow;
      final high = p.dayHigh;
      final mid = (p.bid > 0 && p.ask > 0)
          ? (p.bid + p.ask) / 2
          : (p.bid > 0 ? p.bid : p.ask);
      double? t;
      if (low != null && high != null && high > low && mid > 0) {
        t = ((mid - low) / (high - low)).clamp(0.0, 1.0);
      }
      return Row(
        children: [
          _edge(scheme, 'symbols.low'.tr, _fn(p, p.dayLow)),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return SizedBox(
                  height: 4,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(colors: [
                            AppColors.danger.withValues(alpha: 0.30),
                            AppColors.success.withValues(alpha: 0.30),
                          ]),
                        ),
                      ),
                      if (t != null)
                        Positioned(
                          left: (w - 8) * t,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: scheme.onSurface,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: scheme.surface, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          _edge(scheme, 'symbols.high'.tr, _fn(p, p.dayHigh)),
        ],
      );
    });
  }

  Widget _edge(ColorScheme scheme, String label, String value) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: AppText.base(fontSize: 10, color: scheme.onSurfaceVariant),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: AppText.base(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface),
          ),
        ],
      ),
    );
  }

  String _f(MarketPrice p, double v) =>
      v > 0 ? v.toStringAsFixed(p.digits.clamp(0, 8)) : '--';

  String _fn(MarketPrice p, double? v) =>
      (v != null && v > 0) ? v.toStringAsFixed(p.digits.clamp(0, 8)) : '--';
}
