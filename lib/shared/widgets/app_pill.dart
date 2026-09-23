import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A compact rounded pill — the reusable form of the many `_StatusPill`,
/// `_pill` and value-chip shapes scattered across accounts, positions, rewards
/// and account widgets.
///
/// Two shapes in one:
/// - Status pill: a single [label] tinted by [color] (`AppPill.status`), with an
///   optional leading dot.
/// - Value pill: a muted [label] followed by a bold [value] (`AppPill.value`),
///   e.g. `TP 1.2345`.
///
/// It is colour-based, so callers map their own feature tone to [color].
///
/// ```dart
/// AppPill.status(label: 'Passed', color: AppColors.success);
/// AppPill.value(label: 'TP', value: '1.2345', color: AppColors.success);
/// ```
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    required this.color,
    this.value,
    this.showDot = false,
    this.bordered = false,
    this.radius = 999,
    this.fontSize = 12,
    this.fontWeight,
    this.letterSpacing,
    this.dotSize = 6,
    this.dotGap = 6,
    this.padding,
    this.bgAlpha = 0.12,
    this.borderAlpha = 0.30,
    this.bgColor,
    this.dotColor,
    this.labelColor,
    this.leading,
    this.leadingGap = 4,
    this.trailing,
    this.trailingGap = 5,
  });

  /// Status pill: single tinted label with an optional leading dot.
  const AppPill.status({
    Key? key,
    required String label,
    required Color color,
    bool showDot = false,
  }) : this(key: key, label: label, color: color, showDot: showDot);

  /// Value pill: muted label + bold value on a tinted background.
  const AppPill.value({
    Key? key,
    required String label,
    required String value,
    required Color color,
  }) : this(key: key, label: label, value: value, color: color);

  /// The pill text (the caption when [value] is set).
  final String label;

  /// Accent colour driving the text and background tint.
  final Color color;

  /// When set, renders as a `label value` value-pill.
  final String? value;

  /// Show a leading colour dot (status style).
  final bool showDot;

  /// Add a hairline border tinted from [color].
  final bool bordered;

  /// Corner radius in r. Defaults to a full 999 capsule.
  final double radius;

  /// Label font size in sp. Defaults to 12.
  final double fontSize;

  /// Label font weight. Defaults to w700 (w500 when a [value] is present).
  final FontWeight? fontWeight;

  /// Label letter spacing. Defaults to the font's own tracking.
  final double? letterSpacing;

  /// Leading dot diameter in w. Defaults to 6.
  final double dotSize;

  /// Gap between the dot and the label in w. Defaults to 6.
  final double dotGap;

  /// Pill padding. Defaults to 12w / 6h.
  final EdgeInsetsGeometry? padding;

  /// Opacity of the [color] fill behind the label. Defaults to 0.12.
  final double bgAlpha;

  /// Opacity of the [color] border when [bordered] is true. Defaults to 0.30.
  final double borderAlpha;

  /// Explicit fill colour. Overrides the [color] + [bgAlpha] wash when set —
  /// use it when the fill is unrelated to the text tone (e.g. a white
  /// translucent pill on a dark gradient hero).
  final Color? bgColor;

  /// Explicit dot colour. Defaults to [color].
  final Color? dotColor;

  /// Explicit label colour. Defaults to [color].
  final Color? labelColor;

  /// Optional widget rendered before the label (e.g. a leading icon). Rendered
  /// after the dot when [showDot] is also set.
  final Widget? leading;

  /// Gap after [leading] in w. Defaults to 4.
  final double leadingGap;

  /// Optional widget rendered after the label (e.g. a status icon).
  final Widget? trailing;

  /// Gap before [trailing] in w. Defaults to 5.
  final double trailingGap;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty && (value == null || value!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final resolvedLabelColor = labelColor ??
        (value == null ? color : color.withValues(alpha: 0.75));

    return Container(
      padding: padding ??
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(radius.r),
        border: bordered
            ? Border.all(color: color.withValues(alpha: borderAlpha))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: dotSize.w,
              height: dotSize.w,
              decoration: BoxDecoration(
                color: dotColor ?? color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: dotGap.w),
          ],
          if (leading != null) ...[
            leading!,
            SizedBox(width: leadingGap.w),
          ],
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: fontSize.sp,
              fontWeight: fontWeight ??
                  (value == null ? FontWeight.w700 : FontWeight.w500),
              letterSpacing: letterSpacing,
              color: resolvedLabelColor,
            ),
          ),
          if (value != null && value!.isNotEmpty) ...[
            SizedBox(width: 5.w),
            Text(
              value!,
              style: GoogleFonts.beVietnamPro(
                fontSize: fontSize.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
          if (trailing != null) ...[
            SizedBox(width: trailingGap.w),
            trailing!,
          ],
        ],
      ),
    );
  }
}
