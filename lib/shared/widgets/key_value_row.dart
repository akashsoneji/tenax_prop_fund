import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// A key/value row used inside grouped "rules" cards across the app
/// (Challenge rules, Competition rules, Configure summary…). Label on the
/// left, value right-aligned, optional trailing info icon and an optional
/// hairline divider below.
///
/// The value may be emphasised (bold + primary/danger colour) via [emphasize]
/// and [valueColor]. Fully theme-driven.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.showInfo = false,
    this.onInfo,
    this.showDivider = true,
    this.emphasize = false,
    this.valueColor,
    this.dense = false,
  });

  final String label;
  final String value;
  final bool showInfo;
  final VoidCallback? onInfo;
  final bool showDivider;
  final bool emphasize;
  final Color? valueColor;

  /// Tighter padding and a smaller font for long rule lists.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fontSize = dense ? 13.sp : 14.sp;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 14.w : 16.w,
            vertical: dense ? 10.h : 14.h,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: fontSize,
                    color: scheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Both sides are Expanded (tight): a loose label would leave its
              // unused share after the value, so the value's right edge would
              // drift with label length.
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: fontSize,
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
                    color: valueColor ?? scheme.onSurface,
                  ),
                ),
              ),
              if (showInfo) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: onInfo,
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: dense ? 15.w : 17.w,
                    color: scheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1.h,
            thickness: 1,
            indent: dense ? 14.w : 16.w,
            endIndent: dense ? 14.w : 16.w,
            color: scheme.onSurface.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

/// Wraps a list of [KeyValueRow]s (or any rows) in the standard surface card.
class RulesCard extends StatelessWidget {
  const RulesCard({super.key, required this.children, this.margin = EdgeInsets.zero});

  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.surfaceCard(scheme, radius: 16.r),
      child: Column(children: children),
    );
  }
}
