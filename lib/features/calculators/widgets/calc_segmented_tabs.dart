import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

/// Pill-style segmented control
/// Generic over any label list; the selected segment paints solid primary
/// with contrasting text, the rest sit on a muted track. Theme-driven.
class CalcSegmentedTabs extends StatelessWidget {
  const CalcSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track = scheme.brightness == Brightness.dark
        ? AppColors.white.withValues(alpha: 0.06)
        : AppColors.track;

    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _Segment(
                label: labels[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        height: 40.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : AppColors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: selected
                ? scheme.onPrimary
                : scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

/// Two-option Buy/Sell (or any pair) toggle used in the profit/loss tab.
class CalcTwoWayToggle extends StatelessWidget {
  const CalcTwoWayToggle({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onChanged,
  });

  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CalcSegmentedTabs(
      labels: [leftLabel, rightLabel],
      selectedIndex: leftSelected ? 0 : 1,
      onSelected: (i) => onChanged(i == 0),
    );
  }
}
