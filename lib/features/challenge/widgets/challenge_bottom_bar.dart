import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

/// The sticky purple summary bar pinned to the bottom of the Choose-a-challenge
/// and Configure screens: plan name + price on the left, a light "Configure"
/// (or custom label) button on the right. [strikePrice] is optional.
class ChallengeBottomBar extends StatelessWidget {
  const ChallengeBottomBar({
    super.key,
    required this.planName,
    required this.price,
    required this.actionLabel,
    required this.onAction,
    this.strikePrice,
    this.loading = false,
  });

  final String planName;
  final String price;
  final String actionLabel;
  final VoidCallback? onAction;
  final String? strikePrice;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        // gradient:  AppTheme.brandGradient(scheme),
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
          ),
        ],
        ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 14.h, 14.w, 14.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      planName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.accent,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (strikePrice != null) ...[
                          SizedBox(width: 8.w),
                          Padding(
                            padding: EdgeInsets.only(bottom: 3.h),
                            child: Text(
                              strikePrice!,
                              style: GoogleFonts.beVietnamPro(
                                color: AppColors.white.withValues(alpha: 0.6),
                                fontSize: 14.sp,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Material(
                color: AppColors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  onTap: loading ? null : onAction,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 22.w, vertical: 12.h),
                    child: loading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2.w,
                              valueColor:
                                  const AlwaysStoppedAnimation(AppColors.white),
                            ),
                          )
                        : Text(
                            actionLabel,
                            style: GoogleFonts.beVietnamPro(
                              color: AppColors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
