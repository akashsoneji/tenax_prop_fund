import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A small metric tile: optional leading icon, a muted label and a bold value.
///
/// This is the single reusable form of the `_MetricCell` / `_StatCell` /
/// `_Metric` / `_HeroMiniStat` patterns that were reimplemented across the
/// account, accounts, positions and billing features. It is colour-based (not
/// coupled to any feature enum): a caller maps its own tone to [valueColor], so
/// both `AccountTone` variants and plain success/danger P&L colouring reuse the
/// same tile.
///
/// The layout knobs exist so an existing screen can adopt this widget WITHOUT
/// its design changing — [iconInline], [bordered], [labelFontSize] and
/// [valueFontSize] each exist because a real call site needed that exact shape.
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
    this.iconInline = false,
    this.valueColor,
    this.labelColor,
    this.iconTint,
    this.boxed = false,
    this.bordered = false,
    this.center = false,
    this.valueFontSize = 16,
    this.valueFontWeight = FontWeight.w700,
    this.labelFontSize = 12,
    this.labelFontWeight = FontWeight.w500,
    this.iconSize,
    this.gap = 4,
    this.boxColor,
    this.borderColor,
    this.boxPadding,
    this.boxRadius = 12,
  });

  /// Muted caption above the value.
  final String label;

  /// The bold headline figure.
  final String value;

  /// Optional metric icon (tinted with [iconTint] or `scheme.primary`).
  final IconData? icon;

  /// Render the icon on the same row as the label instead of above it.
  final bool iconInline;

  /// Colour of the value text — map your feature tone to this. Defaults to
  /// `scheme.onSurface`.
  final Color? valueColor;

  /// Colour of the label text. Defaults to a muted `scheme.onSurface`.
  final Color? labelColor;

  /// Colour of the icon. Defaults to `scheme.primary`.
  final Color? iconTint;

  /// Wrap the tile in a soft rounded surface box (grid-cell style).
  final bool boxed;

  /// Add a hairline border to the box. Only meaningful when [boxed] is true.
  final bool bordered;

  /// Centre the contents horizontally (grid-cell style). Left-aligned by default.
  final bool center;

  /// Value font size in sp. Defaults to 16.
  final double valueFontSize;

  /// Value font weight. Defaults to w700.
  final FontWeight valueFontWeight;

  /// Label font size in sp. Defaults to 12.
  final double labelFontSize;

  /// Label font weight. Defaults to w500.
  final FontWeight labelFontWeight;

  /// Icon size in w. Defaults to 18 stacked, 14 inline.
  final double? iconSize;

  /// Vertical gap between label and value, in h. Defaults to 4.
  final double gap;

  /// Box fill. Defaults to a 4% `scheme.onSurface` wash.
  final Color? boxColor;

  /// Box border colour. Only used when [bordered] is true.
  final Color? borderColor;

  /// Box padding. Defaults to 12w / 10h.
  final EdgeInsetsGeometry? boxPadding;

  /// Box corner radius in r. Defaults to 12.
  final double boxRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedLabelColor =
        labelColor ?? scheme.onSurface.withValues(alpha: 0.60);
    final resolvedIconTint = iconTint ?? scheme.primary;
    final align = center ? TextAlign.center : TextAlign.start;

    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: GoogleFonts.beVietnamPro(
        fontSize: labelFontSize.sp,
        fontWeight: labelFontWeight,
        color: resolvedLabelColor,
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (icon != null && iconInline)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: (iconSize ?? 14).w, color: resolvedIconTint),
              SizedBox(width: 4.w),
              Flexible(child: labelText),
            ],
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: (iconSize ?? 18).w, color: resolvedIconTint),
            SizedBox(height: 6.h),
          ],
          labelText,
        ],
        SizedBox(height: gap.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: GoogleFonts.beVietnamPro(
            fontSize: valueFontSize.sp,
            fontWeight: valueFontWeight,
            color: valueColor ?? scheme.onSurface,
          ),
        ),
      ],
    );

    if (!boxed) return content;

    return Container(
      padding: boxPadding ??
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: boxColor ?? scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(boxRadius.r),
        border: bordered
            ? Border.all(
                color: borderColor ??
                    scheme.onSurface.withValues(alpha: 0.12),
              )
            : null,
      ),
      child: content,
    );
  }
}
