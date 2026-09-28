import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../symbols/services/market_watch_v2_service.dart';

/// Header strip at the top of the landscape trade rail: the instrument, its
/// live price and the session change, with a tap target to switch symbol.
///
/// Landscape hides the portrait app bar, so without this the user loses sight
/// of WHICH instrument the Buy/Sell buttons below would trade.
class LandscapeRailHeader extends StatelessWidget {
  const LandscapeRailHeader({
    super.key,
    required this.symbol,
    required this.onTap,
  });

  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          symbol,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.expand_more,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _LivePrice(symbol: symbol),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mid price + session change, rebuilt on every tick for this symbol only.
class _LivePrice extends StatelessWidget {
  const _LivePrice({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final quote = Get.find<MarketWatchV2Service>().priceOf(symbol).value;
      final digits = quote.digits.clamp(0, 8);
      final mid = quote.ask > 0 && quote.bid > 0
          ? (quote.ask + quote.bid) / 2
          : quote.ask;
      return Row(
        children: [
          Flexible(
            child: Text(
              mid > 0 ? mid.toStringAsFixed(digits) : '--',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                height: 1.1,
              ),
            ),
          ),
          if (quote.spread > 0) ...[
            const SizedBox(width: 6),
            Text(
              '${'trade.spread'.tr} ${quote.spread.toStringAsFixed(1)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: AppColors.alphaMuted,
                ),
                height: 1.1,
              ),
            ),
          ],
        ],
      );
    });
  }
}
