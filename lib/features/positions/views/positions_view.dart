import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_segmented_control.dart';
import '../controllers/positions_controller.dart';
import '../widgets/account_summary_grid.dart';
import '../widgets/history_row.dart';
import '../widgets/position_card.dart';

/// The Positions/Trade screen: a live account summary grid, a Market / Pending /
/// History segmented switch, and the matching list (open positions with close,
/// pending orders with cancel, closed-trade history). Ported from the
/// white_label trade screen; the brand colour is tenax purple (`scheme.primary`)
/// and profit/loss maps to [AppColors.success]/[AppColors.danger].
class PositionsView extends GetView<PositionsController> {
  const PositionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Obx(() => AccountSummaryGrid(account: controller.account.value)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => AppSegmentedControl(
                  labels: [
                    'positions.market'.tr,
                    'positions.pending'.tr,
                    'positions.history'.tr,
                  ],
                  selected: controller.selectedTab.value.index,
                  onChanged: (i) =>
                      controller.selectTab(PositionsTab.values[i]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                switch (controller.selectedTab.value) {
                  case PositionsTab.market:
                    return _MarketList(controller: controller);
                  case PositionsTab.pending:
                    return _PendingList(controller: controller);
                  case PositionsTab.history:
                    return _HistoryList(controller: controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketList extends StatelessWidget {
  const _MarketList({required this.controller});
  final PositionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.rawPositions;
      if (rows.isEmpty) {
        return const _EmptyState(messageKey: 'positions.no_open_trade');
      }
      final items = controller.openPositions;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Obx(
                  () => TextButton(
                    onPressed: controller.busy.value ? null : controller.closeAll,
                    child: Text(
                      'positions.close_all'.tr,
                      style: AppText.subtitle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, i) => Obx(
                () => PositionCard(
                  position: items[i],
                  busy: controller.busy.value,
                  onAction: () => controller.closePosition(items[i]),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({required this.controller});
  final PositionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.rawPending;
      if (rows.isEmpty) {
        return const _EmptyState(messageKey: 'positions.no_pending');
      }
      final items = controller.pendingOrders;
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, i) => Obx(
          () => PositionCard(
            position: items[i],
            busy: controller.busy.value,
            onAction: () => controller.cancelPending(items[i]),
          ),
        ),
      );
    });
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.controller});
  final PositionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.historyLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final error = controller.historyError.value;
      if (error != null) {
        return _EmptyState(
          messageKey: 'positions.history_error',
          onRetry: controller.loadHistory,
        );
      }
      final items = controller.history;
      if (items.isEmpty) {
        return const _EmptyState(messageKey: 'positions.no_history');
      }
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, i) => HistoryRow(entry: items[i]),
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.messageKey, this.onRetry});
  final String messageKey;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 44, color: muted),
          const SizedBox(height: 12),
          Text(messageKey.tr, style: AppText.subtitle(color: muted)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text('state.retry'.tr,
                  style: AppText.subtitle(color: scheme.primary)),
            ),
          ],
        ],
      ),
    );
  }
}
