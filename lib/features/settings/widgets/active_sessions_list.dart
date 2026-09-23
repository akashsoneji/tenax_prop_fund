import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_text.dart';
import '../models/security_models.dart';

/// Read-only list of the signed-in devices returned by `/settings/security`.
/// The API exposes no revoke route yet, so rows are informational.
class ActiveSessionsList extends StatelessWidget {
  const ActiveSessionsList({super.key, required this.sessions});

  final List<SecuritySession> sessions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < sessions.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 56.w,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            _SessionRow(session: sessions[i]),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final SecuritySession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: session.isCurrent
                  ? scheme.primary.withValues(alpha: 0.16)
                  : scheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(
              Icons.devices_rounded,
              size: 18.sp,
              color: session.isCurrent
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.device.isEmpty
                      ? 'settings.security.unknown_device'.tr
                      : session.device,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppText.title(fontSize: 13.sp, color: scheme.onSurface),
                ),
                SizedBox(height: 2.h),
                Text(
                  _subtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    fontSize: 11.sp,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          if (session.isCurrent) ...[
            SizedBox(width: 10.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'settings.security.this_device'.tr,
                style:
                    AppText.label(fontSize: 10.sp, color: scheme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitle() {
    final ip = session.ipAddress;
    final when = _relative(session.lastActiveAt);
    if (ip.isEmpty) return when;
    if (when.isEmpty) return ip;
    return '$ip · $when';
  }

  String _relative(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at.toLocal());
    if (diff.inMinutes < 1) return 'settings.security.just_now'.tr;
    if (diff.inHours < 1) {
      return 'settings.security.minutes_ago'
          .trParams({'count': '${diff.inMinutes}'});
    }
    if (diff.inDays < 1) {
      return 'settings.security.hours_ago'
          .trParams({'count': '${diff.inHours}'});
    }
    return 'settings.security.days_ago'.trParams({'count': '${diff.inDays}'});
  }
}
