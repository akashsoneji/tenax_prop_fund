import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/notification_models.dart';

/// A single notification row: a tinted status icon, a bold title with a
/// two-line muted subtitle, and a trailing short timestamp.
class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visual = _visualFor(notification.type, scheme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(visual.icon, size: 20, color: visual.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notification.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            notification.time,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
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
