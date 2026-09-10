import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

/// The purple gradient card with a 2x2 grid of contact tiles at the top of the
/// Support screen. Each tile is a translucent-white rounded box with a centered
/// white icon + label.
class SupportContactCard extends StatelessWidget {
  const SupportContactCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient(scheme),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 22.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How can we help?',
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Reach us any way you like.',
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white.withValues(alpha: 0.82),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              const Expanded(
                child: _ContactTile(icon: Icons.chat, label: 'WhatsApp'),
              ),
              SizedBox(width: 12.w),
              const Expanded(
                child: _ContactTile(icon: Icons.mail_outline, label: 'Email'),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              const Expanded(
                child: _ContactTile(icon: Icons.help_outline, label: 'FAQ'),
              ),
              SizedBox(width: 12.w),
              const Expanded(
                child: _ContactTile(
                    icon: Icons.menu_book_rounded, label: 'Rules'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          height: 84.h,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.white, size: 26.w),
              SizedBox(height: 8.h),
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  color: AppColors.white,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
