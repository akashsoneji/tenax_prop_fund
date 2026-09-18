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

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty && (value == null || value!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 6.w),
          ],
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.sp,
              fontWeight: value == null ? FontWeight.w700 : FontWeight.w500,
              color: value == null
                  ? color
                  : color.withValues(alpha: 0.75),
            ),
          ),
          if (value != null && value!.isNotEmpty) ...[
            SizedBox(width: 5.w),
            Text(
              value!,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
