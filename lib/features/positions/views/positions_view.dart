import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_empty_view.dart';
import '../../../shared/widgets/app_segmented_control.dart';
import '../controllers/positions_controller.dart';
import '../widgets/account_summary_grid.dart';
import '../widgets/close_all_sheet.dart';
import '../widgets/history_filter_sheet.dart';
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
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Obx(
                () => AppSegmentedControl(
                  labels: [
                    '${'positions.market'.tr} (${controller.openPositions.length})',
                    '${'positions.pending'.tr} (${controller.pendingOrders.length})',
                    '${'positions.history'.tr} (${controller.history.length})',
                  ],
                  selected: controller.selectedTab.value.index,
                  onChanged: (i) =>
                      controller.selectTab(PositionsTab.values[i]),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Obx(() => AccountSummaryGrid(account: controller.account.value)),
            ),
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
        return const AppEmptyView(messageKey: 'positions.no_open_trade');
      }
      final items = controller.openPositions;
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Obx(
                  () => TextButton(
                    onPressed: controller.busy.value
                        ? null
                        : () async {
                            final group = await showCloseAllSheet(
                              context,
                              positions: items,
                            );
                            if (group == null) return;
                            await controller.closePositions(
                              switch (group) {
                                CloseGroup.all => items,
                                CloseGroup.profitable => items
                                    .where((position) => position.profitLoss > 0)
                                    .toList(),
                                CloseGroup.losing => items
                                    .where((position) => position.profitLoss < 0)
                                    .toList(),
                                CloseGroup.long => items
                                    .where((position) => position.isBuy)
                                    .toList(),
                                CloseGroup.short => items
                                    .where((position) => !position.isBuy)
                                    .toList(),
                              },
                            );
                          },
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
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
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
        return const AppEmptyView(messageKey: 'positions.no_pending');
      }
      final items = controller.pendingOrders;
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
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

class _HistoryList extends StatefulWidget {
  const _HistoryList({required this.controller});
  final PositionsController controller;

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Pulls the next page once the user is within one screen of the bottom, so
  /// the list keeps filling without a "Load more" tap.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      widget.controller.loadMoreHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      children: [
        _HistoryFilterBar(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.historyLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final error = controller.historyError.value;
            if (error != null) {
              return AppEmptyView(
                messageKey: 'positions.history_error',
                onRetry: controller.loadHistory,
              );
            }
            final items = controller.filteredHistory;
            if (items.isEmpty) {
              return const AppEmptyView(messageKey: 'positions.no_history');
            }
            final loadingMore = controller.historyLoadingMore.value;
            return ListView.builder(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: items.length + (loadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= items.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                return HistoryRow(entry: items[i]);
              },
            );
          }),
        ),
      ],
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

