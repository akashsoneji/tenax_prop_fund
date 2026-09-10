import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/state/data_state.dart';
import 'app_shimmer.dart';
import 'app_gradient_button.dart';

/// The one widget every data screen uses to render a [DataState].
///
/// It maps the four meaningful states to UI: a shimmer [skeleton] while
/// loading, the real [builder] output on success, an [empty] placeholder, and
/// an error card with a retry button on failure. This keeps loading/empty/error
/// handling identical across all 150+ screens.
class DataStateBuilder<T> extends StatelessWidget {
  const DataStateBuilder({
    super.key,
    required this.state,
    required this.skeleton,
    required this.builder,
    this.onRetry,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle,
    this.emptyMessage,
  });

  final DataState<T> state;

  /// The shimmer placeholder shape for this screen (composed from the
  /// skeletons library). It is wrapped in [AppShimmer] here, so pass the raw
  /// layout without its own shimmer.
  final Widget skeleton;

  /// Builds the real UI once data is available.
  final Widget Function(T data) builder;

  /// Called by the retry button on failure and the empty state.
  final Future<void> Function()? onRetry;

  final IconData emptyIcon;
  final String? emptyTitle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      DataSuccess<T>(:final data) => builder(data),
      DataFailure<T>(:final message) => _ErrorState(
          message: message,
          onRetry: onRetry,
        ),
      DataEmpty<T>() => _EmptyState(
          icon: emptyIcon,
          title: emptyTitle ?? 'state.empty_title'.tr,
          message: emptyMessage ?? 'state.empty_message'.tr,
        ),
      // DataInitial + DataLoading both show the skeleton.
      _ => AppShimmer(child: skeleton),
    };
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48.w, color: scheme.onSurface.withValues(alpha: 0.4)),
            SizedBox(height: 16.h),
            Text(
              'state.error_title'.tr,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.sp,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 20.h),
              SizedBox(
                width: 160.w,
                child: AppGradientButton(
                  label: 'state.retry'.tr,
                  onPressed: onRetry!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48.w, color: scheme.onSurface.withValues(alpha: 0.35)),
            SizedBox(height: 16.h),
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.sp,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
