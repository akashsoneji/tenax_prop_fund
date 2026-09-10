import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/account_models.dart';

// ---------------------------------------------------------------------------
// Trading overview
// ---------------------------------------------------------------------------

/// Detailed-stats card — metrics laid out as compact two-column rows
/// (label muted on the left, value bold/toned on the right), mirroring the web
/// "Detailed stats" table. Rows are split by hairline dividers.
class AccountInsightsGrid extends StatelessWidget {
  const AccountInsightsGrid({super.key, required this.metrics});
  final List<AccountMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (metrics.isEmpty) return const SizedBox.shrink();

    // Pair metrics up: [0,1] [2,3] … so each row shows two cells.
    final rows = <List<AccountMetric>>[];
    for (var i = 0; i < metrics.length; i += 2) {
      rows.add(metrics.sublist(i, (i + 2).clamp(0, metrics.length)));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.primary.withValues(alpha: 0.06),
              ),
            Row(
              children: [
                Expanded(child: _MetricCell(metric: rows[r][0])),
                Container(
                  width: 1,
                  height: 34,
                  color: scheme.primary.withValues(alpha: 0.06),
                ),
                Expanded(
                  child: rows[r].length > 1
                      ? _MetricCell(metric: rows[r][1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric});
  final AccountMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueColor = switch (metric.tone) {
      AccountTone.up => AppColors.success,
      AccountTone.down => AppColors.danger,
      AccountTone.neutral => scheme.onSurface,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            metric.value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// One closed-trade row.
class AccountTradeRow extends StatelessWidget {
  const AccountTradeRow({super.key, required this.trade});
  final AccountTrade trade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sideColor = trade.isBuy ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.surfaceCard(scheme, radius: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sideColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              trade.isBuy
                  ? Icons.north_east_rounded
                  : Icons.south_east_rounded,
              size: 18,
              color: sideColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(trade.symbol,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface)),
                    const SizedBox(width: 8),
                    Text('${trade.side.toUpperCase()} · ${trade.volume}',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${trade.openPrice} → ${trade.closePrice} · ${trade.closedAt}',
                    style: TextStyle(
                        fontSize: 11.5, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            trade.profit,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: trade.profitNegative ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Platform
// ---------------------------------------------------------------------------

/// One MT5 download card with a gradient action.
class PlatformDownloadCard extends StatelessWidget {
  const PlatformDownloadCard({
    super.key,
    required this.download,
    required this.onDownload,
  });

  final PlatformDownload download;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(download.label,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface)),
              ),
              Icon(Icons.download_rounded, size: 18, color: scheme.primary),
            ],
          ),
          const SizedBox(height: 6),
          Text(download.note,
              style: TextStyle(
                  fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Material(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onDownload,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                child: Text('account.download'.tr,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reset
// ---------------------------------------------------------------------------

/// The reset "what carries over" list.
class ResetCarryList extends StatelessWidget {
  const ResetCarryList({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <(bool, String)>[
      (true, 'account.reset_keep_tier'.tr),
      (true, 'account.reset_keep_kyc'.tr),
      (false, 'account.reset_clear_balance'.tr),
      (false, 'account.reset_clear_counter'.tr),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('account.reset_carries'.tr,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface)),
          const SizedBox(height: 12),
          for (final (kept, label) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (kept ? AppColors.success : AppColors.amber)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      kept ? 'account.reset_kept'.tr : 'account.reset_reset'.tr,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kept ? AppColors.success : AppColors.amber),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurface)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
