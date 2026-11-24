import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../features/accounts/views/accounts_view.dart';
import '../../../shared/theme/app_colors.dart';


import '../controllers/home_controller.dart';
import 'tabs/home_tab_view.dart';
import 'tabs/markets_tab_view.dart';
import '../../positions/views/positions_view.dart';
import 'tabs/trade_tab_view.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// 5-tab shell shown after successful login. Preserves each tab's state with
/// [IndexedStack]; the trading-app style bottom nav marks the active tab with a
/// top indicator, a filled icon in a tinted pill and a bold brand label.
///
/// Every flavor uses the same tabs. The More directory is reached from the
/// settings icon in the Home header.
class HomeShellView extends StatelessWidget {
  const HomeShellView({super.key});

  static const _tabs = <_HomeTab>[
    _HomeTab(Icons.home_outlined, Icons.home_rounded, 'home.tabs.home'),
    _HomeTab(
      Icons.candlestick_chart_outlined,
      Icons.candlestick_chart,
      'home.tabs.trade',
    ),
    _HomeTab(
      Icons.insert_chart_outlined_rounded,
      Icons.insert_chart_rounded,
      'home.tabs.charts',
    ),
    _HomeTab(
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
      'home.tabs.positions',
    ),
    _HomeTab(
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded,
      'home.tabs.accounts',
    ),
  ];

  /// Built once — the IndexedStack children never change, only the active
  /// index does, so this list must not be rebuilt on every tab switch.
  static const List<Widget> _tabViews = [
    HomeTabView(),
    TradeTabView(),
    MarketsTabView(),
    PositionsView(),
    AccountsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Obx(
        () => IndexedStack(index: c.selectedTab.value, children: _tabViews),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.06)
                  : AppColors.track,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 16.r,
              offset: Offset(0, -4.h),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 6.h),
            child: Obx(
              () => Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _NavItem(
                        tab: _tabs[i],
                        active: c.selectedTab.value == i,
                        onTap: () => c.selectTab(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  const _HomeTab(this.icon, this.activeIcon, this.labelKey);
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final _HomeTab tab;
  final bool active;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = active ? scheme.primary : scheme.onSurfaceVariant;

    return InkResponse(
      onTap: onTap,
      radius: 32.r,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: _duration,
            curve: Curves.easeOutCubic,
            width: active ? 22.w : 0,
            height: 3.h,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(3.r),
              ),
            ),
          ),
          Gap.vXs,
          AnimatedContainer(
            duration: _duration,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: 
              // active
                  // ? scheme.primary.withValues(alpha: 0.12)
                  // : 
                  AppColors.transparent,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              active ? tab.activeIcon : tab.icon,
              size: 22.w,
              color: fg,
            ),
          ),
          Gap.vXxs,
          Text(
            tab.labelKey.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.base(
              fontSize: 11.sp,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
