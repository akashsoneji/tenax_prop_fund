import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/payout_method.dart';

/// A single payout-method card: bold title + status chip, a muted meta line,
/// a description paragraph and a full-width outlined "Add this method" button.
class PayoutMethodCard extends StatelessWidget {
  const PayoutMethodCard({
    super.key,
    required this.method,
    this.delayMs = 0,
  });

  final PayoutMethod method;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 480 + delayMs),
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16.h),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
        decoration: AppTheme.surfaceCard(scheme, radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    method.name,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  method.isSetUp ? 'Set up' : 'Not set up',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              method.meta,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              method.description,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.sp,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: Text('payout_methods.add_method'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
