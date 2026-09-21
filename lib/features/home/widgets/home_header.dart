import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/flavor/flavor.dart';
import '../../../app/flavor/flavor_resolver.dart';
import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
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
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient(scheme),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 14.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Icon(Icons.change_history_rounded,
                color: AppColors.white, size: 20.w),
          ),
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
          if (FlavorResolver.flavor == Flavor.tenax) ...[
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

/// A square glassy header action button with an optional overlaid [badge].
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap, this.badge});

  final IconData icon;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: dark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.trackSoft,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: dark
                ? AppColors.white.withValues(alpha: 0.06)
                : AppColors.border,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, color: scheme.onSurface, size: 21.w),
            ?badge,
          ],
        ),
      ),
    );
  }
}
