import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

/// The purple gradient card at the top of the Support screen: a compact
/// heading with a single row of four translucent-white contact tiles.
class SupportContactCard extends StatelessWidget {
  const SupportContactCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient(scheme),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 18.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How can we help?',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Reach us any way you like.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white.withValues(alpha: 0.82),
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _ContactTile(
                    icon: Icons.chat, label: 'support.contact_whatsapp'.tr),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ContactTile(
                    icon: Icons.mail_outline, label: 'support.contact_email'.tr),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ContactTile(
                    icon: Icons.help_outline, label: 'support.contact_faq'.tr),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ContactTile(
                  icon: Icons.menu_book_rounded,
                  label: 'support.contact_rules'.tr,
                ),
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
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 60.h,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.white, size: 20.w),
              SizedBox(height: 5.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  color: AppColors.white,
                  fontSize: 10.5.sp,
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
