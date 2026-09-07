import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../controllers/trading_rules_controller.dart';
import '../models/rules_models.dart';

/// Top-of-screen segmented tab bar for the 4 rules tabs.
///
/// Visually a single rounded pill with a soft brand-purple background and a
/// dark-purple "pill" indicator that animates between segments using
/// [AnimatedAlign] (cheap, no custom AnimationController).
///
/// The bar is horizontally scrollable so long labels ("Everything" etc.) are
/// not clipped on narrow phones.
class RulesSegmentedTabs extends StatelessWidget {
  const RulesSegmentedTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TradingRulesController>();
    final tabs = RulesTab.values;

    return Obx(() {
      final selected = c.selectedTab.value;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.track, // pale lavender track
          borderRadius: BorderRadius.circular(14),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final t in tabs)
                _SegmentChip(
                  label: t.label,
                  isSelected: t == selected,
                  onTap: () => c.selectTab(t),
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
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}