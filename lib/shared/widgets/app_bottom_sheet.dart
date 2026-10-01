import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// The app's standard bottom sheet: grabber, optional title + subtitle, a
/// keyboard-safe scrollable body and an optional pinned bottom [action].
///
/// Defaults match the most common sheet in the app (22.r top radius, 20.w side
/// padding, 38×4 grabber, 17sp title / 12sp subtitle). Open it with
/// [AppBottomSheet.show].
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.action,
    this.minHeightFactor,
    this.padding,
  });

  final List<Widget> children;
  final String? title;
  final String? subtitle;

  /// Pinned below the scrolling body (e.g. the sheet's primary button).
  final Widget? action;

  /// Minimum height as a fraction of the screen (e.g. `0.6` for forms, so they
  /// fill the space above the keyboard). Null = hug the content.
  final double? minHeightFactor;

  /// Overrides the default `fromLTRB(20.w, 10.h, 20.w, 32.h)`.
  final EdgeInsetsGeometry? padding;

  /// Opens [sheet] the standard way: scroll-controlled (so tall content and
  /// the keyboard work), safe-area aware.
  static Future<T?> show<T>(Widget sheet) => Get.bottomSheet<T>(
        sheet,
        isScrollControlled: true,
        ignoreSafeArea: false,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final factor = minHeightFactor;
    // No viewInsets padding here: Get.bottomSheet already lifts the sheet by
    // the keyboard height, and adding it again double-shifts the sheet up
    // under the status bar and clips the fields.
    return Container(
      constraints: factor == null
          ? null
          : BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * factor),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      padding: padding ?? EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSheetGrabber(),
                  Gap.vLg,
                  if (title != null) ...[
                    Text(
                      title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(fontSize: 17.sp, color: scheme.onSurface),
                    ),
                    6.verticalSpace,
                  ],
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: AppText.body(
                        fontSize: 12.sp,
                        height: 1.4,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  if (title != null || subtitle != null) 18.verticalSpace,
                  ...children,
                ],
              ),
            ),
          ),
          if (action != null) ...[Gap.vLg, action!],
        ],
      ),
    );
  }
}

/// The small rounded handle at the top of every sheet.
class AppSheetGrabber extends StatelessWidget {
  const AppSheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 38.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }
}
