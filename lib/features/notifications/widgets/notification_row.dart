import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/notification_models.dart';

/// A single notification row: a tinted status icon, a bold title with a
/// two-line muted subtitle, and a trailing short timestamp.
class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visual = _visualFor(notification.type, scheme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(visual.icon, size: 20.w, color: visual.color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  notification.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.sp,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                notification.time,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (!notification.read) ...[
                SizedBox(height: 6.h),
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }

  _RowVisual _visualFor(NotificationType type, ColorScheme scheme) {
    switch (type) {
      case NotificationType.warning:
        return const _RowVisual(
          Icons.warning_amber_rounded,
          AppColors.danger,
        );
      case NotificationType.info:
        return const _RowVisual(Icons.error_outline, AppColors.warning);
      case NotificationType.success:
        return const _RowVisual(
          Icons.check_circle_outline,
          AppColors.success,
        );
      case NotificationType.gift:
        return _RowVisual(Icons.card_giftcard, scheme.primary);
    }
  }
}

class _RowVisual {
  const _RowVisual(this.icon, this.color);
  final IconData icon;
  final Color color;
}
