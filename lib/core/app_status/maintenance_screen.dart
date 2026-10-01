import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import 'app_status_controller.dart';
import '../../shared/theme/app_spacing.dart';

/// Full-screen widget shown by [AppStatusOverlay] while the backend reports
/// `is_under_maintenance = true`. Scroll-safe (landscape + small phones),
/// uses the app-wide hero gradient so it reads as part of the brand system.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppStatusController>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: scheme.surface,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 480,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeroIcon(gradient: AppTheme.heroGradient(scheme)),
                        28.verticalSpace,
                        _StatusPill(),
                        Gap.vLg,
                        Text(
                          'app_status.maintenance_title'.tr,
                          style: textTheme.titleLarge?.copyWith(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        10.verticalSpace,
                        Text(
                          'app_status.maintenance_message'.tr,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 15.sp,
                            height: 1.5,
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Gap.vXxl,
                        _RetryButton(
                          controller: controller,
                          gradient: AppTheme.heroGradient(scheme),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Big brand-gradient wrench badge with a soft glow + faint outer halo.
class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.gradient});

  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160.w,
      height: 160.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft outer halo
          Container(
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.08),
            ),
          ),
          // Inner ring
          Container(
            width: 128.w,
            height: 128.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandPurple.withValues(alpha: 0.12),
            ),
          ),
          // Gradient badge
          Container(
            width: 96.w,
            height: 96.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPurple.withValues(alpha: 0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              Icons.build_rounded,
              size: 44.w,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle animated "In progress" chip under the hero icon.
class _StatusPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.brandPurple.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: AppColors.brandPurple.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: AppColors.brandPurple),
          Gap.hSm,
          Text(
            'app_status.in_progress'.tr,
            style: textTheme.labelMedium?.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slow pulse dot — tiny motion hint so the screen doesn't look frozen.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        return SizedBox(
          width: 10.w,
          height: 10.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 10.w * (1 + t * 0.6),
                height: 10.w * (1 + t * 0.6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.25 * (1 - t)),
                ),
              ),
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Retry CTA — gradient fill with brand glow. Shows a spinner while the
/// controller is re-checking the backend.
class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.controller,
    required this.gradient,
    required this.isDark,
  });

  final AppStatusController controller;
  final LinearGradient gradient;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final loading = controller.isChecking.value;
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPurple
                    .withValues(alpha: isDark ? 0.5 : 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: InkWell(
            onTap: loading ? null : controller.checkStatus,
            child: SizedBox(
              width: double.infinity,
              height: 44.h,
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 20.w,
                            color: Colors.white,
                          ),
                          Gap.hSm,
                          Text(
                            'app_status.retry'.tr,
                            style: textTheme.labelLarge?.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
