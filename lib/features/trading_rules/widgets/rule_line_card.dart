import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single rule line
/// inside the section card. Text is free-form from the API, so it wraps rather
/// than being clipped.
class RuleLineTile extends StatelessWidget {
  const RuleLineTile({
    super.key,
    required this.number,
    required this.text,
    this.showDivider = true,
  });

  final int number;
  final String text;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.5.sp,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.6,
            thickness: 0.6,
            indent: 16.w,
            endIndent: 16.w,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
