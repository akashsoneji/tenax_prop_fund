import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../models/verification_models.dart';

/// A verification step card mirroring the white_label KYC timeline card: a
/// rounded gradient icon box, a "Step N" pill, a Completed/Incomplete status
/// pill and a stack of feature rows (32×32 tinted circle + label).
///
/// Two variants driven by [highlighted]:
/// - `false` → neutral [AppTheme.surfaceCard] (stepper + inactive overview rows)
/// - `true`  → filled brand gradient card with white text (active overview step)
class VerificationStepCard extends StatelessWidget {
  const VerificationStepCard({
    super.key,
    required this.step,
    this.highlighted = false,
    this.showStepLabel = false,
  });

  final VerificationStep step;
  final bool highlighted;

  /// When true renders the "Step N" pill above the title (overview layout).
  final bool showStepLabel;

  IconData get _headerIcon => switch (step.index) {
        1 => Icons.person_outline_rounded,
        2 => Icons.badge_outlined,
        _ => Icons.account_balance_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onCard = highlighted ? AppColors.white : scheme.onSurface;
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
      decoration: highlighted
          ? BoxDecoration(
              gradient: AppTheme.brandGradient(scheme),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20.r,
                  spreadRadius: -6.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            )
          : AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: _headerIcon, highlighted: highlighted),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showStepLabel) ...[
                      _StepPill(
                        label: 'verification.step_short'
                            .trParams({'index': '${step.index}'}),
                        highlighted: highlighted,
                      ),
                      SizedBox(height: 6.h),
                    ],
                    Text(
                      step.title.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: onCard,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _StatusPill(status: step.status, highlighted: highlighted),
            ],
          ),
          SizedBox(height: 14.h),
          for (final b in step.benefits)
            _FeatureRow(label: b.tr, onCard: onCard),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.highlighted});
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 40.w,
      width: 40.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: highlighted ? null : AppTheme.brandGradient(scheme),
        color: highlighted ? AppColors.white.withValues(alpha: 0.2) : null,
        boxShadow: highlighted
            ? null
            : [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.28),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
      ),
      child: Icon(icon, color: AppColors.white, size: 20.w),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.label, required this.highlighted});
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlighted
        ? AppColors.white.withValues(alpha: 0.2)
        : scheme.primary.withValues(alpha: 0.10);
    final fg = highlighted ? AppColors.white : scheme.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.highlighted});
  final VerificationStatus status;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completed = status.isCompleted;
    final Color bg;
    final Color fg;
    if (highlighted) {
      bg = AppColors.white.withValues(alpha: 0.2);
      fg = AppColors.white;
    } else if (completed) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
    } else {
      bg = scheme.onSurface.withValues(alpha: 0.08);
      fg = scheme.onSurface.withValues(alpha: 0.55);
    }
    return AppPill(
      label: completed
          ? 'verification.completed'.tr
          : 'verification.incomplete'.tr,
      color: fg,
      bgColor: bg,
      labelColor: fg,
      radius: 20,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      trailing: Icon(
        completed ? Icons.check_circle_rounded : Icons.remove_circle_outline,
        size: 12.w,
        color: fg,
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label, required this.onCard});
  final String label;
  final Color onCard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final circleBg = onCard == AppColors.white
        ? AppColors.white.withValues(alpha: 0.15)
        : scheme.primary.withValues(alpha: 0.10);
    final iconColor = onCard == AppColors.white ? AppColors.white : scheme.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 32.w,
            width: 32.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleBg,
            ),
            child: Icon(Icons.check_rounded, size: 17.w, color: iconColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: onCard.withValues(alpha: 0.9),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
