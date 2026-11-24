import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../shared/theme/app_spacing.dart';
import 'app_shield.dart';

/// Takes over the whole viewport once [AppShield] reports a critical threat.
/// Stacked above every route (like the maintenance overlay) and renders
/// nothing while the device is clean.
class SecurityBlockOverlay extends StatelessWidget {
  const SecurityBlockOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final shield = Get.find<AppShield>();
    return Obx(() {
      final threat = shield.blockedBy.value;
      if (threat == null) return const SizedBox.shrink();
      return Positioned.fill(child: _SecurityBlockedScreen(threat: threat));
    });
  }
}

class _SecurityBlockedScreen extends StatelessWidget {
  const _SecurityBlockedScreen({required this.threat});

  final SecurityThreat threat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Absorbs every tap so nothing underneath stays usable.
    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88.w,
                  height: 88.w,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.gpp_bad_rounded,
                    size: 44.sp,
                    color: scheme.onErrorContainer,
                  ),
                ),
                Gap.vLg,
                Text(
                  'security.blocked_title'.tr,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                10.verticalSpace,
                Text(
                  'security.blocked_message'.tr,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 15.sp,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                Gap.vLg,
                Text(
                  'security.reason_${threat.name}'.tr,
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 14.sp,
                    color: scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
