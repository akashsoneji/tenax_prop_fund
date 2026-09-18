import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A small metric tile: optional leading icon, a muted label and a bold value.
///
/// This is the single reusable form of the `_MetricCell` / `_StatTile` /
/// `_Metric` patterns that were reimplemented across the account, accounts and
/// positions features. It is color-based (not coupled to any feature enum): a
/// caller maps its own tone to [valueColor], so both `AccountTone` variants and
/// plain success/danger P&L colouring reuse the same tile.
///
/// ```dart
/// AppStatTile(
///   icon: Icons.trending_up_rounded,
///   label: 'Equity',
///   value: '\$12,480.00',
///   valueColor: AppColors.success,
///   boxed: true,
/// )
/// ```
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.iconTint,
    this.boxed = false,
    this.center = false,
    this.valueFontSize = 16,
  });

  /// Muted caption above/below the value.
  final String label;

  /// The bold headline figure.
  final String value;

  /// Optional leading metric icon (tinted with [iconTint] or `scheme.primary`).
  final IconData? icon;

  /// Colour of the value text — map your feature tone to this. Defaults to
  /// `scheme.onSurface`.
  final Color? valueColor;

  /// Colour of the leading icon. Defaults to `scheme.primary`.
  final Color? iconTint;

  /// Wrap the tile in a soft rounded surface box (grid-cell style).
  final bool boxed;

  /// Centre the contents horizontally (grid-cell style). Left-aligned by default.
  final bool center;

  /// Value font size in sp. Defaults to 16.
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18.w, color: iconTint ?? scheme.primary),
          SizedBox(height: 6.h),
        ],
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface.withValues(alpha: 0.60),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.beVietnamPro(
            fontSize: valueFontSize.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ?? scheme.onSurface,
          ),
        ),
      ],
    );

    if (!boxed) return content;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: content,
    );
  }
}
