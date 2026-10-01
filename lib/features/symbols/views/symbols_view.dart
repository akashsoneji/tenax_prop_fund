import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../chart/services/chart_preload_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../positions/controllers/positions_controller.dart';
import '../../positions/widgets/positions_account_header.dart';
import '../services/favorites_service.dart';
import '../services/market_watch_v2_service.dart';
import '../widgets/favorite_symbol_tile.dart';
import '../widgets/instrument_search_sheet.dart';
import '../../../shared/theme/app_spacing.dart';

/// The "Symbols & specs" screen — a single compact watchlist of the user's
/// favorited instruments with live Sell/Buy. Rows can be reordered by dragging
/// the handle and removed by swiping left. Add more via the search sheet (the
/// app-bar search icon). An empty watchlist shows a prompt to add instruments.
class SymbolsView extends StatelessWidget {
  const SymbolsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'symbols.title'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title(
                          color: scheme.onSurface,
                          fontSize: 22.sp,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: InstrumentSearchSheet.open,
                      icon: Icon(Icons.search, color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            if (Get.isRegistered<PositionsController>())
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: PositionsAccountHeader(
                    controller: Get.find<PositionsController>(),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: _FavoritesSection()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Favorites watchlist: the user's favorited instruments with live prices.
// Reorder by dragging the handle, remove by swiping left. Reacts to add/remove
// via Obx on the service. Shows an empty prompt when the watchlist is empty.
// ---------------------------------------------------------------------------
class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection();

  void _openInMarkets(String code) {
    Get.find<MarketWatchV2Service>().selectSymbol(code);
    Get.find<ChartPreloadService>().saveSymbol(code);
    Get.find<HomeController>().selectTab(2);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final favorites = Get.find<FavoritesService>();
    return Obx(() {
      final items = favorites.favorites.toList();
      if (items.isEmpty) return const _EmptyWatchlist();
      return Padding(
        padding: EdgeInsets.fromLTRB(4.w, 18.h, 8.w, 24.h),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          onReorderItem: favorites.reorder,
          itemBuilder: (context, i) {
            final item = items[i];
            return Padding(
              key: ValueKey(item.code),
              padding: EdgeInsets.only(
                bottom: i == items.length - 1 ? 0 : 10.h,
              ),
              child: Dismissible(
                key: ValueKey('dismiss_${item.code}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => favorites.remove(item.code),
                background: _removeBackground(scheme),
                child: FavoriteSymbolTile(
                  instrument: item,
                  index: i,
                  onTap: () => _openInMarkets(item.code),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  /// Red swipe-behind panel with a trash icon, shown while dragging a favorite
  /// row left to remove it.
  Widget _removeBackground(ColorScheme scheme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.w),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
    );
  }
}

/// Shown when the watchlist has no instruments: a prompt that opens the search
/// sheet so the user can add some.
class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(32.w, 80.h, 32.w, 32.h),
      child: Column(
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 56.w,
            color: scheme.onSurfaceVariant,
          ),
          Gap.vLg,
          Text(
            'symbols.watchlist_empty_title'.tr,
            textAlign: TextAlign.center,
            style: AppText.title(color: scheme.onSurface, fontSize: 16.sp),
          ),
          Gap.vSm,
          Text(
            'symbols.watchlist_empty_hint'.tr,
            textAlign: TextAlign.center,
            style: AppText.base(
              fontSize: 13.sp,
              color: scheme.onSurfaceVariant,
            ),
          ),
          20.verticalSpace,
          FilledButton.icon(
            onPressed: InstrumentSearchSheet.open,
            icon: Icon(Icons.add_rounded, size: 20.w),
            label: Text('symbols.add_instrument'.tr),
          ),
        ],
      ),
    );
  }
}
