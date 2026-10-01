import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// The shared empty / no-data state — the reusable form of the `_EmptyState`,
/// `_EmptyNote`, `_MessageState`, `_NoPlansState`, `_FilterEmpty`,
/// `_EmptyOffers`, `_EmptyReferralsCard` and `_EmptyWatchlist` shapes that were
/// reimplemented per feature.
///
/// [messageKey] and [titleKey] are translation keys — they are resolved with
/// `.tr` here so callers never hold pre-translated text.
///
/// ```dart
/// AppEmptyView(
///   messageKey: 'positions.no_open_positions',
///   onRetry: controller.refresh,
/// );
/// ```
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.messageKey,
    this.titleKey,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
    this.retryKey = 'state.retry',
    this.boxed = false,
  });

  /// Translation key for the muted body line.
  final String messageKey;

  /// Optional translation key for a bold headline above the message.
  final String? titleKey;

  /// Leading glyph above the text.
  final IconData icon;

  /// When set, renders a retry action below the message.
  final VoidCallback? onRetry;

  /// Translation key for the retry action label.
  final String retryKey;

  /// Wrap in a tinted rounded card instead of sitting bare on the background.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 44.w, color: muted),
        Gap.vMd,
        if (titleKey != null) ...[
          Text(
            titleKey!.tr,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.title(color: scheme.onSurface),
          ),
          6.verticalSpace,
        ],
        Text(
          messageKey.tr,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppText.subtitle(color: muted),
        ),
        if (onRetry != null) ...[
          Gap.vMd,
          TextButton(
            onPressed: onRetry,
            child: Text(
              retryKey.tr,
              style: AppText.subtitle(color: scheme.primary),
            ),
          ),
        ],
      ],
    );

    if (!boxed) return Center(child: content);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: content,
    );
  }
}
