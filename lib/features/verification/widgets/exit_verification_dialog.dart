import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/app_gradient_button.dart';

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'verification.exit_title'.tr,
              style: GoogleFonts.beVietnamPro(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'verification.exit_body'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14.5,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: true),
                    child: Text('verification.exit'.tr),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppGradientButton(
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
