import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Visual intent of a toast — drives the accent colour and default icon.
enum AppToastType { success, error, info, warning }

/// A modern, theme-aware toast shown as a floating overlay near the top of the
/// screen (out of the way of the bottom nav). It replaces the stock grey
/// Material `SnackBar`: rounded glass card, a tinted leading icon, an accent
/// rail, a slide+fade entrance and an auto-dismiss progress underline.
///
/// Usage anywhere (no context needed — uses GetX overlay):
/// ```dart
/// AppToast.show('Link copied', type: AppToastType.success);
/// ```
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    String message, {
    AppToastType type = AppToastType.success,
    String? title,
    IconData? icon,
    Duration duration = const Duration(seconds: 2, milliseconds: 400),
  }) {
    // Resolve the ROOT navigator's overlay directly. `Get.overlayContext` is the
    // Overlay's OWN context (so `Overlay.of` on it throws "No Overlay widget
    // found"), and under the bottom-nav shell `Get.context` can sit below a
    // nested navigator. `Get.key.currentState?.overlay` always returns the app's
    // root OverlayState created by GetMaterialApp.
    final overlay = Get.key.currentState?.overlay ??
        (Get.context != null
            ? Overlay.maybeOf(Get.context!, rootOverlay: true)
            : null);
    if (overlay == null) return;

    // Only one toast at a time — replace any in-flight one.
    _dismiss();

    final entry = OverlayEntry(
      builder: (context) => _ToastCard(
        message: message,
        title: title,
        type: type,
        icon: icon,
        duration: duration,
        onDismiss: _dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, _dismiss);
  }

  static void success(String message, {String? title}) =>
      show(message, type: AppToastType.success, title: title);

  static void error(String message, {String? title}) =>
      show(message, type: AppToastType.error, title: title);

  static void info(String message, {String? title}) =>
      show(message, type: AppToastType.info, title: title);

  static void warning(String message, {String? title}) =>
      show(message, type: AppToastType.warning, title: title);

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.title,
    this.icon,
  });

  final String message;
  final String? title;
  final AppToastType type;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.6),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _in, curve: Curves.easeOutBack));

  late final Animation<double> _fade =
      CurvedAnimation(parent: _in, curve: Curves.easeOut);

  @override
  void dispose() {
    _in.dispose();
    _progress.dispose();
    super.dispose();
  }

  Color _accent(ColorScheme scheme) => switch (widget.type) {
        AppToastType.success => AppColors.success,
        AppToastType.error => AppColors.dangerBright,
        AppToastType.warning => AppColors.warning,
        AppToastType.info => scheme.primary,
      };

  IconData _icon() =>
      widget.icon ??
      switch (widget.type) {
        AppToastType.success => Icons.check_circle_rounded,
        AppToastType.error => Icons.error_rounded,
        AppToastType.warning => Icons.warning_amber_rounded,
        AppToastType.info => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final accent = _accent(scheme);
    final media = MediaQuery.of(context);

    return Positioned(
      top: media.padding.top + 12.h,
      left: 16.w,
      right: 16.w,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: AppColors.transparent,
            child: Dismissible(
              key: const ValueKey('app_toast'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: Container(
                decoration: BoxDecoration(
                  color: dark ? AppColors.sheetDark : AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: dark
                        ? AppColors.white.withValues(alpha: 0.08)
                        : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (dark ? AppColors.black : scheme.primary)
                          .withValues(alpha: dark ? 0.45 : 0.16),
                      blurRadius: 24.r,
                      offset: Offset(0, 10.h),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                      child: Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent.withValues(alpha: 0.9),
                                  accent.withValues(alpha: 0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(_icon(),
                                color: AppColors.white, size: 22.w),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.title != null &&
                                    widget.title!.isNotEmpty) ...[
                                  Text(
                                    widget.title!,
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                ],
                                Text(
                                  widget.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: widget.onDismiss,
                            behavior: HitTestBehavior.opaque,
                            child: Icon(
                              Icons.close_rounded,
                              size: 18.w,
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Auto-dismiss progress underline.
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) => LinearProgressIndicator(
                        value: 1 - _progress.value,
                        minHeight: 3.h,
                        backgroundColor: AppColors.transparent,
                        valueColor: AlwaysStoppedAnimation(
                            accent.withValues(alpha: 0.85)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
