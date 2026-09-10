import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A left-aligned section title
/// ("Prizes", "Challenge rules", "Trading platform"…). Matches the muted-bold
/// look from the designs and is fully theme-driven.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.padding,
    this.trailing,
  });

  final String title;
  final EdgeInsetsGeometry? padding;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding ?? EdgeInsets.only(left: 4.w, bottom: 10.h, top: 2.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.beVietnamPro(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
