import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_text.dart';

/// Compact empty state for an inline history list: inbox icon, bold [title]
/// and a muted [message] on a soft tinted panel. For a full-screen empty
/// state use `AppEmptyView` instead.
class AppHistoryEmpty extends StatelessWidget {
  const AppHistoryEmpty({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  /// Already translated.
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 26.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36.w, color: scheme.onSurfaceVariant),
          10.verticalSpace,
          Text(
            title,
            style: AppText.base(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          4.verticalSpace,
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.base(fontSize: 12.sp, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
