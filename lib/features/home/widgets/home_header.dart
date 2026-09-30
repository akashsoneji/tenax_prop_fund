import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/flavor/flavor_resolver.dart';
import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_glass.dart';
import '../../../shared/widgets/flavor_logo.dart';
import '../controllers/home_controller.dart';

/// The Home top bar: brand mark, app name + welcome line, and glassy action
/// buttons (settings on the tenax flavor, plus the notification bell with an
/// unread dot). Pure UI — reads live state straight off [HomeController].
class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 12.w, 8.h),
      child: Row(
        children: [
          _HeaderLogo(scheme: scheme),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  FlavorResolver.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
                Obx(() {
                  final name = controller.userName.value.trim();
                  final text = name.isEmpty
                      ? 'home.welcome_back'.tr
                      : '${'home.welcome_back'.tr}, $name';
                  return Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface.withValues(alpha: 0.55)),
                  );
                }),
              ],
            ),
          ),
          if (FlavorResolver.usesTenaxDesign) ...[
            SizedBox(width: 10.w),
            _HeaderButton(
              icon: Icons.settings_outlined,
              onTap: () => Get.toNamed(AppRoutes.more),
            ),
          ],
          SizedBox(width: 10.w),
          _HeaderButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => Get.toNamed(AppRoutes.notifications),
            badge: Obx(() {
              if (controller.unreadCount.value == 0) {
                return const SizedBox.shrink();
              }
              final dark = scheme.brightness == Brightness.dark;
              return Positioned(
                right: 9.w,
                top: 9.h,
                child: Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(
                    color: AppColors.dangerBright,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: dark ? scheme.surface : AppColors.white,
                        width: 1.5.w),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Round flavor logo. Dark mode wraps it in a frosted-glass ring; light mode
/// shows the bare circle with the brand glow.
class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final logo = ClipOval(
      child: FlavorLogo(
        size: 32.w,
        fallback: Container(
          width: 32.w,
          height: 32.w,
          decoration:
              BoxDecoration(gradient: AppTheme.brandGradient(scheme)),
          child: Icon(Icons.change_history_rounded,
              color: AppColors.white, size: 18.w),
        ),
      ),
    );
    if (scheme.brightness == Brightness.dark) {
      return AppGlass(
        width: 38.w,
        height: 38.w,
        shape: BoxShape.circle,
        padding: EdgeInsets.all(3.w),
        child: logo,
      );
    }
    return Container(
      width: 38.w,
      height: 38.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: logo,
    );
  }
}

/// Header action button with an optional [badge]: a frosted-glass circle in
/// dark mode, the original soft square in light mode.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap, this.badge});

  final IconData icon;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final iconWidget = Icon(icon, color: scheme.onSurface, size: 20.w);
    final surface = dark
        ? AppGlass(
            width: 38.w,
            height: 38.w,
            shape: BoxShape.circle,
            child: iconWidget,
          )
        : Container(
            width: 38.w,
            height: 38.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.trackSoft,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: iconWidget,
          );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [surface, ?badge],
      ),
    );
  }
}

