import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/security_controller.dart';
import '../models/security_models.dart';
import 'active_sessions_list.dart';
import 'security_rows.dart';
import 'security_sheets.dart';

/// The Security block of the Settings screen: server-backed toggles, the
/// two-factor state, and the credential actions (password, beneficiary,
/// recovery codes) plus the active session list.
class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SecurityController>();

    return Obx(
      () => DataStateBuilder<SecuritySettings>(
        state: c.state,
        onRetry: c.load,
        skeleton: const _SecuritySkeleton(),
        builder: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => SecurityGroup(
                children: [
                  SecuritySwitchRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'settings.security.login_alerts'.tr,
                    description: 'settings.security.login_alerts_desc'.tr,
                    value: c.loginAlerts.value,
                    onChanged: (v) => c.setPref(loginAlerts: v),
                  ),
                  SecuritySwitchRow(
                    icon: Icons.verified_user_outlined,
                    title: 'settings.security.withdrawal_confirmation'.tr,
                    description:
                        'settings.security.withdrawal_confirmation_desc'.tr,
                    value: c.withdrawalConfirmation.value,
                    onChanged: (v) => c.setPref(withdrawalConfirmation: v),
                  ),
                  SecuritySwitchRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'settings.security.platform_lock'.tr,
                    description: 'settings.security.platform_lock_desc'.tr,
                    value: c.platformLock.value,
                    onChanged: (v) => c.setPref(platformLock: v),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            SecurityGroup(
              children: [
                SecurityActionRow(
                  icon: Icons.shield_moon_outlined,
                  title: 'settings.security.two_factor'.tr,
                  description: _twoFactorCaption(data),
                  trailingLabel: data.twoFactorEnabled
                      ? 'settings.security.on'.tr
                      : 'settings.security.off'.tr,
                  highlighted: data.twoFactorEnabled,
                  onTap: () => data.twoFactorEnabled
                      ? showTwoFactorDisableSheet()
                      : showTwoFactorEnrolSheet(),
                ),
                if (data.twoFactorEnabled)
                  SecurityActionRow(
                    icon: Icons.vpn_key_outlined,
                    title: 'settings.security.recovery_codes'.tr,
                    description: 'settings.security.recovery_codes_desc'.tr,
                    onTap: showRecoveryCodesSheet,
                  ),
                SecurityActionRow(
                  icon: Icons.password_rounded,
                  title: 'settings.security.change_password'.tr,
                  description: 'settings.security.change_password_desc'.tr,
                  onTap: showChangePasswordSheet,
                ),
                SecurityActionRow(
                  icon: Icons.family_restroom_rounded,
                  title: 'settings.security.beneficiary'.tr,
                  description: 'settings.security.beneficiary_desc'.tr,
                  onTap: showBeneficiarySheet,
                ),
              ],
            ),
            if (data.sessions.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text(
                'settings.security.sessions'.tr,
                style: AppText.title(
                  fontSize: 13.sp,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.9),
                ),
              ),
              SizedBox(height: 8.h),
              ActiveSessionsList(sessions: data.sessions),
            ],
          ],
        ),
      ),
    );
  }

  String _twoFactorCaption(SecuritySettings data) {
    if (!data.twoFactorEnabled) {
      return data.twoFactorRequired
          ? 'settings.security.two_factor_required'.tr
          : 'settings.security.two_factor_desc'.tr;
    }
    return 'settings.security.codes_remaining'
        .trParams({'count': '${data.recoveryCodesRemaining}'});
  }
}

class _SecuritySkeleton extends StatelessWidget {
  const _SecuritySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShimmerBox(height: 190.h, radius: 18.r),
        SizedBox(height: 12.h),
        ShimmerBox(height: 190.h, radius: 18.r),
      ],
    );
  }
}
