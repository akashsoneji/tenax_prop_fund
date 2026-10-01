import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_button.dart';

/// The "Exit Verification" confirmation dialog. Returns `true` from the route
/// when the user chooses to exit, `false`/null when they continue.
class ExitVerificationDialog extends StatelessWidget {
  const ExitVerificationDialog({super.key});

  static Future<bool> show() async {
    final result = await Get.dialog<bool>(const ExitVerificationDialog());
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'verification.exit_title'.tr,
              style: AppText.base(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            Gap.vLg,
            Text(
              'verification.exit_body'.tr,
              textAlign: TextAlign.center,
              style: AppText.base(
                fontSize: 14.5.sp,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            28.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    label: 'verification.exit'.tr,
                    onPressed: () => Get.back(result: true),
                  ),
                ),
                14.horizontalSpace,
                Expanded(
                  child: AppButton(
                    label: 'common.continue_action'.tr,
                    onPressed: () => Get.back(result: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
