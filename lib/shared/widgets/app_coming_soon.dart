import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Centered "coming soon" state for a screen or tab that isn't built yet.
/// [title] is shown as-is — pass an already translated string (`'x.y'.tr`).
class AppComingSoon extends StatelessWidget {
  const AppComingSoon({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64.w, color: scheme.primary),
            16.verticalSpace,
            Text(title, style: text.headlineSmall),
            8.verticalSpace,
            Text(
              'placeholder.coming_soon'.tr,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
