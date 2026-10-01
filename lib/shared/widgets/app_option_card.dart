import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// A selectable option card: bold [title] + a [status] label on the right, a
/// muted [meta] line, a [description] paragraph and a full-width outlined
/// [actionLabel] button. Fades/slides in, staggered by [delayMs].
///
/// Data-driven (plain strings), so any feature can map its own model onto it —
/// e.g. a payout method, a payment method, a plan.
class AppOptionCard extends StatelessWidget {
  const AppOptionCard({
    super.key,
    required this.title,
    required this.status,
    required this.meta,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.statusColor,
    this.delayMs = 0,
  });

  final String title;

  /// Short state label shown top-right (e.g. "Set up" / "Not set up").
  final String status;

  /// Defaults to the theme's primary colour.
  final Color? statusColor;
  final String meta;
  final String description;
  final String actionLabel;
  final VoidCallback? onAction;

  /// Extra entrance delay for staggering cards in a list.
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 480 + delayMs),
      curve: AppMotion.enter,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - t) * 16.h), child: child),
      ),
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
                    title,
                    style: AppText.base(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                8.horizontalSpace,
                Text(
                  status,
                  style: AppText.base(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: statusColor ?? scheme.primary,
                  ),
                ),
              ],
            ),
            6.verticalSpace,
            Text(
              meta,
              style: AppText.base(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
            10.verticalSpace,
            Text(
              description,
              style: AppText.base(
                fontSize: 13.sp,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
            14.verticalSpace,
            AppButton.outlined(label: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}
