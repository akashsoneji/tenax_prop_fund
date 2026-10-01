import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../features/accounts/views/accounts_view.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

import '../controllers/home_controller.dart';
import 'tabs/home_tab_view.dart';
import 'tabs/markets_tab_view.dart';
import '../../positions/views/positions_view.dart';
import 'tabs/trade_tab_view.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// 5-tab shell shown after successful login. Preserves each tab's state with
/// [IndexedStack]; bottom nav highlights the active tab in the brand yellow.
///
/// Every flavor uses the same tabs. The More directory is reached from the
/// settings icon in the Home header.
class HomeShellView extends StatelessWidget {
  const HomeShellView({super.key});

  static const _tabs = <_HomeTab>[
    _HomeTab(Icons.home_rounded, 'home.tabs.home'),
    _HomeTab(Icons.swap_horiz_rounded, 'home.tabs.trade'),
    _HomeTab(Icons.show_chart_rounded, 'home.tabs.charts'),
    _HomeTab(Icons.list_alt_rounded, 'home.tabs.positions'),
    _HomeTab(Icons.groups_2_rounded, 'home.tabs.accounts'),
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

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Obx(
        () => IndexedStack(index: c.selectedTab.value, children: _tabViews),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(
                color: scheme.brightness == Brightness.dark
                    ? AppColors.white.withValues(alpha: 0.06)
                    : AppColors.track,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _tabs[i].icon,
                      label: _tabs[i].labelKey.tr,
                      active: c.selectedTab.value == i,
                      onTap: () => c.selectTab(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab {
  final IconData icon;
  final String labelKey;
  const _HomeTab(this.icon, this.labelKey);
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = active
        ? AppColors.black
        : scheme.onSurface.withValues(alpha: 0.55);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: active ? scheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.45),
                    blurRadius: 14.r,
                    offset: Offset(0, 6.h),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22.w, color: fg),
            Gap.vXs,
            Text(
              label,
              style: AppText.base(
                fontSize: 11.sp,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
