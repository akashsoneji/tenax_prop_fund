import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/positions_models.dart';

/// One open-position (or pending-order) card: symbol + side pill, volume, open
/// and current price, live PnL, and a close/cancel action. Mirrors the
/// white_label trade-screen row/expanded card. Profit/loss is the ONLY colour
/// that maps to a semantic token (success/danger); everything else is theme.
class PositionCard extends StatelessWidget {
  const PositionCard({
    super.key,
    required this.position,
    required this.onAction,
    required this.busy,
  });

  final TradePosition position;
  final VoidCallback onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBuy = position.isBuy;
    final sideColor = isBuy ? AppColors.success : AppColors.danger;
    final pnlColor = position.profitLoss >= 0 ? AppColors.success : AppColors.danger;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  position.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(color: scheme.onSurface, fontSize: 15),
                ),
              ),
              _SidePill(
                label: (isBuy ? 'trade.buy' : 'trade.sell').tr,
                color: sideColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${'positions.volume'.tr}: ${position.volume.toStringAsFixed(2)}',
            style: AppText.label(color: muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PriceBlock(
                  label: position.isPending
                      ? 'positions.order_price'.tr
                      : 'positions.open_price'.tr,
                  value: position.entryPrice,
                ),
              ),
              Expanded(
                child: _PriceBlock(
                  label: 'positions.current_price'.tr,
                  value: position.currentPrice,
                ),
              ),
              if (!position.isPending)
                Expanded(
                  child: _PriceBlock(
                    label: 'positions.pnl'.tr,
                    value: position.profitLoss.toStringAsFixed(2),
                    valueColor: pnlColor,
                    alignEnd: true,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                (position.isPending ? 'positions.cancel' : 'positions.close').tr,
                style: AppText.subtitle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePill extends StatelessWidget {
  const _SidePill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppColors.alphaHairline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppText.label(color: color, fontSize: 11),
        ),
      );
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label(color: muted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.subtitle(
            color: valueColor ?? scheme.onSurface,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
