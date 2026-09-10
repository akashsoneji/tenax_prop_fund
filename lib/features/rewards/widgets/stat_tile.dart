import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';

/// One of the four
/// screen (Withdrawable / Pending / Paid out / Your share).
///
/// Uses a faint tinted background instead of a glass blur so the colour
/// identity of each card (green = withdrawable, amber = pending, etc.) reads
/// even when stacked.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.tone,
    this.trailingIcon,
    this.delayMs = 0,
  });

  final String label;
  final String value;
  final StatTileTone tone;
  final IconData? trailingIcon;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tintBg = _toneBackground(tone, scheme);
    final tintAccent = _toneAccent(tone, scheme);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14.h),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 12.w, 14.h),
        decoration: BoxDecoration(
          color: tintBg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: tintAccent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                if (trailingIcon != null)
                  Container(
                    width: 26.w,
                    height: 26.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tintAccent.withValues(alpha: 0.18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(trailingIcon, size: 14.w, color: tintAccent),
                  ),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              value,
              style: GoogleFonts.beVietnamPro(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: tintAccent,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tint matrix — matches the design without leaking yellow onto CTA surfaces.
  // Brightness-aware so the tile stays readable on a dark scaffold.
  Color _toneBackground(StatTileTone t, ColorScheme scheme) {
    return _toneAccent(t, scheme).withValues(
        alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.12);
  }

  Color _toneAccent(StatTileTone t, ColorScheme scheme) {
    switch (t) {
      case StatTileTone.green:
        return AppColors.success;
      case StatTileTone.amber:
        return AppColors.warningInk;
      case StatTileTone.purple:
        return scheme.primary;
      case StatTileTone.blue:
        return const Color(0xFF1E6FB8);
    }
  }
}

enum StatTileTone { green, amber, purple, blue }
