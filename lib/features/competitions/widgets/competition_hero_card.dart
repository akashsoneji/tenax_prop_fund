import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/competition_models.dart';

/// The purple gradient hero card at the top of the Competitions screen:
/// title + status pill, date range, a 2×2 stat grid and the register CTA.
/// Uses the brand hero gradient so it matches the other hero surfaces.
class CompetitionHeroCard extends StatelessWidget {
  const CompetitionHeroCard({
    super.key,
    required this.info,
    required this.registered,
    required this.onRegister,
  });

  final CompetitionInfo info;
  final bool registered;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = [
      CompetitionStat('competitions.prize_pool'.tr, info.prizePool),
      CompetitionStat('competitions.accounts'.tr, info.accounts),
      CompetitionStat('competitions.entry'.tr, info.entry),
      CompetitionStat('competitions.your_rank'.tr, info.rank),
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  info.title,
                  style: GoogleFonts.beVietnamPro(
                    color: AppColors.white,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  info.status,
                  style: GoogleFonts.beVietnamPro(
                    color: AppColors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            info.dateRange,
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white.withValues(alpha: 0.75),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(child: _StatTile(stat: stats[0])),
              SizedBox(width: 12.w),
              Expanded(child: _StatTile(stat: stats[1])),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _StatTile(stat: stats[2])),
              SizedBox(width: 12.w),
              Expanded(child: _StatTile(stat: stats[3])),
            ],
          ),
          SizedBox(height: 18.h),
          _RegisterButton(registered: registered, onRegister: onRegister),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});
  final CompetitionStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            stat.label,
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white.withValues(alpha: 0.70),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            stat.value,
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white,
              fontSize: 19.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Yellow accent CTA — the ONE place yellow is used as a fill (a competition
/// register button, per the design), with deep-purple ink for contrast.
/// Flips to a confirmed state once registered so double-taps are inert.
class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.registered, required this.onRegister});
  final bool registered;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: Material(
        color: registered ? AppColors.white.withValues(alpha: 0.18) : AppTheme.accent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: registered ? null : onRegister,
          borderRadius: BorderRadius.circular(14.r),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (registered) ...[
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.white, size: 18.w),
                  SizedBox(width: 8.w),
                ],
                Text(
                  registered
                      ? 'competitions.registered'.tr
                      : 'competitions.register_free'.tr,
                  style: GoogleFonts.beVietnamPro(
                    color: registered ? AppColors.white : AppColors.brandPurple,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
