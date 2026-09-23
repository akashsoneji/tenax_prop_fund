import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../controllers/trading_rules_controller.dart';

/// Top-of-screen segmented tab bar, built from the tabs the rules API returns.
///
/// The bar is horizontally scrollable so long labels are not clipped on narrow
/// phones, and it hides itself while the tab list is still loading.
class RulesSegmentedTabs extends StatelessWidget {
  const RulesSegmentedTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TradingRulesController>();

    return Obx(() {
      final tabs = c.tabs;
      if (tabs.isEmpty) return const SizedBox.shrink();

      final selected = c.selectedTab.value;
      return Container(
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.track, // pale lavender track
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final t in tabs)
                _SegmentChip(
                  label: t.label,
                  isSelected: t.value == selected,
                  onTap: () => c.selectTab(t.value),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.enter,
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
