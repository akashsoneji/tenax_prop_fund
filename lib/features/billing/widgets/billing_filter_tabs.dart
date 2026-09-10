import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/billing_models.dart';

/// The segmented filter control (All / Challenge / Add-on / Refund) above the
/// billing transaction list. The active segment slides a purple pill; theme
/// driven so it adapts to light/dark.
class BillingFilterTabs extends StatelessWidget {
  const BillingFilterTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final BillingFilter selected;
  final ValueChanged<BillingFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trackColor = scheme.brightness == Brightness.dark
        ? AppColors.white.withValues(alpha: 0.06)
        : AppColors.track;
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          for (final f in BillingFilter.values)
            Expanded(child: _Segment(
              filter: f,
              active: f == selected,
              onTap: () => onChanged(f),
            )),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.filter,
    required this.active,
    required this.onTap,
  });

  final BillingFilter filter;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? scheme.primary : AppColors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          filter.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: active
                ? AppColors.white
                : scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
