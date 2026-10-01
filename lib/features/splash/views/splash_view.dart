import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/flavor/flavor_config.dart';
import '../../../app/routes/app_routes.dart';
import '../../../features/authentication/repositories/auth_repository.dart';
import '../../../shared/theme/app_colors.dart';

import '../../../shared/widgets/flavor_logo.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// Brief branded splash. Checks for a persisted session token: if present the
/// user skips straight to home, otherwise they land on get-started.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final hasSession = await Get.find<AuthRepository>().hasSession();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Get.offAllNamed(hasSession ? AppRoutes.home : AppRoutes.getStarted);
  }

  @override
  Widget build(BuildContext context) {
    final config = Get.find<FlavorConfig>();
    final primary = config.primaryColor;
    final primaryHsl = HSLColor.fromColor(primary);
    // Derive a deep top and even-deeper bottom from the flavor's own primary
    // so the splash always carries the selected flavor's brand color.
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryHsl
            .withLightness((primaryHsl.lightness * 0.7).clamp(0.0, 1.0))
            .toColor(),
        primary,
        primaryHsl
            .withLightness((primaryHsl.lightness * 0.5).clamp(0.0, 1.0))
            .toColor(),
      ],
    );
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: FlavorLogo(
                  asset: config.splashLogoAsset,
                  size: 120.w,
                  fallback: Text(
                    'tp',
                    style: AppText.base(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.w800,
                      color: config.secondaryColor,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              20.verticalSpace,
              Text(
                config.appName,
                style: AppText.base(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: 0.4,
                ),
              ),
              Gap.vSm,
              Text(
                'splash.loading'.tr,
                style: AppText.base(
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
