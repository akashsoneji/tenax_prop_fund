import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_text.dart';

/// Shared chrome for the security bottom sheets: grabber, title, subtitle and a
/// keyboard-safe scrollable body.
class SecuritySheetScaffold extends StatelessWidget {
  const SecuritySheetScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // No viewInsets padding here: Get.bottomSheet already lifts the sheet by
    // the keyboard height, and adding it again double-shifts the sheet up
    // under the status bar and clips the fields.
    return Container(
      // Taller floor so the form fills the space above the keyboard instead of
      // hugging it; the route's max height still caps it on small screens.
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 32.h),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.title(fontSize: 17.sp, color: scheme.onSurface),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              style: AppText.body(
                fontSize: 12.sp,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 18.h),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Opens [child] as the app's standard security sheet.
Future<T?> showSecuritySheet<T>(Widget child) => Get.bottomSheet<T>(
      child,
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
