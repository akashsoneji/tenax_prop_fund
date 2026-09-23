import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A tappable selectable chip — the reusable form of the `_TabChip`,
/// `_ChannelChip`, `_RangeChip`, `_CurrencyChip`, `_TradeChip` and `_PresetChip`
/// patterns that were reimplemented per feature.
///
/// Unlike [AppPill] (a stateless status badge) this chip is interactive and
/// renders a distinct selected / unselected state. Colours default to the
/// theme's `primary` on a tinted fill; pass the slots when a screen needs its
/// own exact look.
///
/// ```dart
/// AppChoiceChip(
///   label: 'Today',
///   selected: range == Range.today,
///   onTap: () => controller.setRange(Range.today),
/// )
/// ```
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.leadingGap = 6,
    this.radius = 20,
    this.fontSize = 12.5,
    this.fontWeight = FontWeight.w600,
    this.padding,
    this.selectedColor,
    this.unselectedColor,
    this.selectedFill,
    this.unselectedFill,
    this.bordered = true,
    this.borderColor,
    this.animate = false,
    this.height,
    this.alignment,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Optional widget before the label (e.g. a check icon that reflects
  /// [selected]).
  final Widget? leading;

  /// Gap after [leading] in w. Defaults to 6.
  final double leadingGap;

  /// Corner radius in r. Defaults to 20.
  final double radius;

  /// Label font size in sp. Defaults to 12.5.
  final double fontSize;

  /// Label font weight. Defaults to w600.
  final FontWeight fontWeight;

  /// Chip padding. Defaults to 12w / 7h.
  final EdgeInsetsGeometry? padding;

  /// Label + border colour when selected. Defaults to `scheme.primary`.
  final Color? selectedColor;

  /// Label + border colour when not selected. Defaults to
  /// `scheme.onSurfaceVariant`.
  final Color? unselectedColor;

  /// Fill when selected. Defaults to a 14% [selectedColor] wash.
  final Color? selectedFill;

  /// Fill when not selected. Defaults to a 50% `surfaceContainerHighest` wash.
  final Color? unselectedFill;

  /// Draw a border tinted from the active colour. Defaults to true.
  final bool bordered;

  /// Explicit border colour. Defaults to a 50% wash of the active colour.
  final Color? borderColor;

  /// Animate the selection transition (200ms easeOutCubic).
  final bool animate;

  /// Fixed height. When set the label is centred in the box.
  final double? height;

  /// Explicit content alignment. Set this when the chip is placed in a
  /// parent-sized box and must fill it (the box then expands to its
  /// constraints instead of hugging the label).
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = selected
        ? (selectedColor ?? scheme.primary)
        : (unselectedColor ?? scheme.onSurfaceVariant);
    final fill = selected
        ? (selectedFill ?? scheme.primary.withValues(alpha: 0.14))
        : (unselectedFill ??
            scheme.surfaceContainerHighest.withValues(alpha: 0.5));

    final decoration = BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius.r),
      border: bordered
          ? Border.all(
              color: borderColor ?? activeColor.withValues(alpha: 0.5))
          : null,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: leadingGap.w),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: fontSize.sp,
              fontWeight: fontWeight,
              color: activeColor,
            ),
          ),
        ),
      ],
    );

    final resolvedPadding =
        padding ?? EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius.r),
      child: animate
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: height,
              alignment:
                  alignment ?? (height != null ? Alignment.center : null),
              padding: resolvedPadding,
              decoration: decoration,
              child: content,
            )
          : Container(
              height: height,
              alignment:
                  alignment ?? (height != null ? Alignment.center : null),
              padding: resolvedPadding,
              decoration: decoration,
              child: content,
            ),
    );
  }
}
