import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

/// Purple gradient hero header
/// button. Mirrors the Rewards hero so the two screens feel like a family.
class RulesHeroHeader extends StatelessWidget {
  const RulesHeroHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.heroGradient(scheme)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 22.h),
          child: Row(
            children: [
              IconButton(
                onPressed: Navigator.of(context).maybePop,
                icon: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
      color: AppColors.white.withValues(alpha: 0.14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                    size: 18.w,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                title,
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}