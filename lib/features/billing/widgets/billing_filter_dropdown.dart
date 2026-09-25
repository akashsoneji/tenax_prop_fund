import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';

/// A polished, reusable filter chip that opens a themed popup menu. Used for
/// both the transaction `type` and `status` filters that map to the query
/// params on `GET /finance/transactions`. Highlights in the brand colour when a
/// non-default option is selected. Labels are resolved via `.tr` by the caller
/// through [labelOf].
class BillingFilterDropdown<T> extends StatelessWidget {
  const BillingFilterDropdown({
    super.key,
    required this.selected,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    required this.isDefault,
    this.icon = Icons.tune_rounded,
  });

  final T selected;
  final List<T> values;

  /// Localized label for a value.
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  /// Whether the given value is the neutral "All" option (drives the highlight).
  final bool Function(T value) isDefault;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = !isDefault(selected);
    final borderColor = isActive
        ? scheme.primary.withValues(alpha: 0.5)
        : scheme.onSurface.withValues(alpha: 0.12);
    final fg = isActive ? scheme.primary : scheme.onSurface;

    return PopupMenuButton<T>(
      initialValue: selected,
      onSelected: onChanged,
      color: scheme.surface,
      elevation: 3,
      offset: Offset(0, 46.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
      ),
      itemBuilder: (context) => [
        for (final v in values)
          PopupMenuItem<T>(
            value: v,
            height: 44.h,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labelOf(v),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13.sp,
                      fontWeight:
                          v == selected ? FontWeight.w700 : FontWeight.w500,
                      color: v == selected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ),
                if (v == selected)
                  Icon(Icons.check_rounded, size: 18.w, color: scheme.primary),
              ],
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.08)
              : AppColors.transparent,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.w, color: fg),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                labelOf(selected),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18.w, color: fg),
          ],
        ),
      ),
    );
  }
}
