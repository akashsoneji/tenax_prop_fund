import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/reward_models.dart';

/// A single line in the "What stands between you and a payout" card. Renders
/// the label on the left, the value on the right, and a thin divider below
/// (except for the last row in the card).
class RequirementRow extends StatelessWidget {
  const RequirementRow({
    super.key,
    required this.requirement,
    required this.showDivider,
  });

  final PayoutRequirement requirement;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = requirement.status.color;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  requirement.label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
              ),
              _StatusPill(text: requirement.value, color: accent),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1.h,
            thickness: 1,
            color: scheme.onSurface.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}