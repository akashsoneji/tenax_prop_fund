import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_empty_view.dart';
import '../../../shared/widgets/app_segmented_control.dart';
import '../controllers/positions_controller.dart';
import '../models/positions_models.dart';
import '../widgets/account_summary_grid.dart';
import '../widgets/close_all_sheet.dart';
import '../widgets/history_filter_sheet.dart';
import '../widgets/history_row.dart';
import '../widgets/position_card.dart';
import '../widgets/positions_account_header.dart';

/// The Positions/Trade screen: a live account summary grid, a Market / Pending /
/// History segmented switch, and the matching list (open positions with close,
/// pending orders with cancel, closed-trade history). Ported from the
/// white_label trade screen; the brand colour is tenax purple (`scheme.primary`)
/// and profit/loss maps to [AppColors.success]/[AppColors.danger].
class PositionsView extends GetView<PositionsController> {
  const PositionsView({super.key});

  /// Pulls the next history page once the user is within one screen of the
  /// bottom, so the list keeps filling without a "Load more" tap.
  bool _onScroll(ScrollNotification notification) {
    if (controller.selectedTab.value != PositionsTab.history) return false;
    final metrics = notification.metrics;
    if (metrics.pixels >= metrics.maxScrollExtent - 300) {
      controller.loadMoreHistory();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _PositionsHeader(controller: controller)),
              Obx(
                () => switch (controller.selectedTab.value) {
                  PositionsTab.market => _MarketSliver(controller: controller),
                  PositionsTab.pending => _PendingSliver(controller: controller),
                  PositionsTab.history => _HistorySliver(controller: controller),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Account header, tab switch and the live summary grid. Sits in the same
/// scroll view as the list so it scrolls away with the trades.
class _PositionsHeader extends StatelessWidget {
  const _PositionsHeader({required this.controller});
  final PositionsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: PositionsAccountHeader(controller: controller),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: Obx(
            () => AppSegmentedControl(
              labels: [
                '${'positions.market'.tr} (${controller.openPositions.length})',
                '${'positions.pending'.tr} (${controller.pendingOrders.length})',
                '${'positions.history'.tr} (${controller.history.length})',
              ],
              selected: controller.selectedTab.value.index,
              onChanged: (i) => controller.selectTab(PositionsTab.values[i]),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
          child: Obx(
            () => AccountSummaryGrid(account: controller.account.value),
          ),
        ),
      ],
    );
  }
}

class _MarketSliver extends StatelessWidget {
  const _MarketSliver({required this.controller});
  final PositionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.rawPositions.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyView(messageKey: 'positions.no_open_trade'),
        );
      }
      final items = controller.openPositions;
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverList.builder(
          itemCount: items.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return _CloseAllBar(controller: controller, items: items);
            }
            final position = items[i - 1];
            return Obx(
              () => PositionCard(
                position: position,
                busy: controller.busy.value,
                onAction: () => controller.closePosition(position),
              ),
            );
          },
        ),
      );
    });
  }
}

class _CloseAllBar extends StatelessWidget {
  const _CloseAllBar({required this.controller, required this.items});
  final PositionsController controller;
  final List<TradePosition> items;

  Future<void> _closeAll(BuildContext context) async {
    final group = await showCloseAllSheet(context, positions: items);
    if (group == null) return;
    await controller.closePositions(switch (group) {
      CloseGroup.all => items,
      CloseGroup.profitable =>
        items.where((position) => position.profitLoss > 0).toList(),
      CloseGroup.losing =>
        items.where((position) => position.profitLoss < 0).toList(),
      CloseGroup.long => items.where((position) => position.isBuy).toList(),
      CloseGroup.short => items.where((position) => !position.isBuy).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(
            () => TextButton(
              onPressed: controller.busy.value ? null : () => _closeAll(context),
              child: Text(
                'positions.close_all'.tr,
                style: AppText.subtitle(
                  color: AppColors.danger,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSliver extends StatelessWidget {
  const _PendingSliver({required this.controller});
  final PositionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.rawPending.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyView(messageKey: 'positions.no_pending'),
        );
      }
      final items = controller.pendingOrders;
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => Obx(
            () => PositionCard(
              position: items[i],
              busy: controller.busy.value,
              onAction: () => controller.cancelPending(items[i]),
            ),
          ),
        ),
      );
    });
  }
}

class _HistorySliver extends StatelessWidget {
  const _HistorySliver({required this.controller});
  final PositionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.historyLoading.value) {
        return _HistoryStateSliver(
          controller: controller,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.historyError.value != null) {
        return _HistoryStateSliver(
          controller: controller,
          child: AppEmptyView(
            messageKey: 'positions.history_error',
            onRetry: controller.loadHistory,
          ),
        );
      }
      final items = controller.filteredHistory;
      if (items.isEmpty) {
        return _HistoryStateSliver(
          controller: controller,
          child: const AppEmptyView(messageKey: 'positions.no_history'),
        );
      }
      final loadingMore = controller.historyLoadingMore.value;
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverList.builder(
          itemCount: items.length + 1 + (loadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == 0) return _HistoryFilterBar(controller: controller);
            final index = i - 1;
            if (index >= items.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            return HistoryRow(entry: items[index]);
          },
        ),
      );
    });
  }
}

/// Keeps the history filter bar visible above a loading/error/empty state while
/// still filling the remaining viewport height.
class _HistoryStateSliver extends StatelessWidget {
  const _HistoryStateSliver({required this.controller, required this.child});
  final PositionsController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        children: [
          _HistoryFilterBar(controller: controller),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Shows the active date range + net profit for that range, with the filter
/// button that opens [showHistoryFilterSheet].
/// A single card row above the History list: the active date range as a tappable
/// pill (opens [showHistoryFilterSheet]) plus the trades count and net profit for
/// that range.
class _HistoryFilterBar extends StatelessWidget {
  const _HistoryFilterBar({required this.controller});
  final PositionsController controller;

  Future<void> _openFilter(BuildContext context) async {
    final result = await showHistoryFilterSheet(
      context,
      selected: controller.historyRange.value,
      from: controller.customFrom.value,
      to: controller.customTo.value,
      symbol: controller.historySymbol.value,
      direction: controller.historyDirection.value,
      profitFilter: controller.historyProfitFilter.value,
    );
    if (result == null) return;
    controller.applyHistoryFilter(result.range, from: result.from, to: result.to);
    controller.applyHistoryFilters(
      symbol: result.symbol,
      direction: result.direction,
      profitFilter: result.profitFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      child: Obx(() {
        final profit = controller.filteredHistoryProfit;
        final profitColor = profit >= 0 ? AppColors.success : AppColors.danger;
        return Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: () => _openFilter(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 15.w, color: scheme.primary),
                    SizedBox(width: 6.w),
                    Text(
                      controller.historyRange.value.labelKey.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.subtitle(
                        color: scheme.primary,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16.w,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${controller.filteredHistory.length} ${'positions.trades'.tr}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle(color: muted, fontSize: 12.sp),
                  ),
                  SizedBox(width: 8.w),
                  Container(width: 1.w, height: 12.h, color: muted),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      profit.toStringAsFixed(2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(color: profitColor, fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

