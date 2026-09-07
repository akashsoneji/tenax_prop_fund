import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_theme.dart';

/// The rounded purple gradient banner at the top of each stepper page:
/// "To open your trading account…" on the left and a big circled step number
/// on the right. Mirrors the design's hero pill.
class VerificationHeroBanner extends StatelessWidget {
  const VerificationHeroBanner({
    super.key,
    required this.stepNumber,
    required this.stepLabel,
  });

  /// Two-digit label, e.g. "01".
  final String stepNumber;

  /// e.g. "Step 1 >".
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient(scheme),
        borderRadius: AppTheme.heroPillRadius(),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'verification.hero_body'.tr,
                  style: GoogleFonts.beVietnamPro(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  stepLabel,
                  style: GoogleFonts.beVietnamPro(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.14),
              border:
                  Border.all(color: AppColors.white.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: GoogleFonts.beVietnamPro(
                color: AppColors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
