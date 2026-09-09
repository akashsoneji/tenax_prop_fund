import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/positions_models.dart';

/// One closed-trade row in the History tab: symbol + side, volume, open→close
/// price, and net profit coloured green/red.
class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);
    final isBuy = entry.isBuy;
    final sideColor = isBuy ? AppColors.success : AppColors.danger;
    final pnlColor = entry.profit >= 0 ? AppColors.success : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title(color: scheme.onSurface, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (isBuy ? 'trade.buy' : 'trade.sell').tr.toUpperCase(),
                      style: AppText.label(color: sideColor, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${'positions.volume'.tr}: ${entry.volume.toStringAsFixed(2)}'
                  '   ${entry.priceOpen} → ${entry.priceClose}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.profit.toStringAsFixed(2),
            style: AppText.subtitle(color: pnlColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
